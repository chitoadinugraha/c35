use std::collections::HashMap;
use std::fs;
use std::path::Path;

use anyhow::Result;

use crate::host::{exists, host_path, parse_mount_devices_text, stat_bytes};

#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct DeviceMountInfo {
    pub mount: String,
    pub is_boot: bool,
}

pub fn device_mounts_from_mountinfo(
    text: &str,
    resolve_dev: impl Fn(u64, u64) -> String,
) -> HashMap<String, DeviceMountInfo> {
    build_device_mount_map(&parse_mount_devices_text(text), resolve_dev)
}

fn build_device_mount_map(
    dev_by_mount: &HashMap<String, (u64, u64)>,
    resolve_dev: impl Fn(u64, u64) -> String,
) -> HashMap<String, DeviceMountInfo> {
    let mut device_mounts: HashMap<String, DeviceMountInfo> = HashMap::new();
    for (mount, (maj, min)) in dev_by_mount {
        let dev_name = resolve_dev(*maj, *min);
        if dev_name.is_empty() {
            continue;
        }
        let disk = whole_disk_name(&dev_name);
        let is_boot = mount == "/";
        match device_mounts.get_mut(&disk) {
            None => {
                device_mounts.insert(
                    disk,
                    DeviceMountInfo {
                        mount: mount.clone(),
                        is_boot,
                    },
                );
            }
            Some(existing) => {
                existing.is_boot |= is_boot;
                if mount.len() > existing.mount.len() {
                    existing.mount = mount.clone();
                }
            }
        }
    }
    device_mounts
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BlockDevice {
    pub name: String,
    pub mount: String,
    pub is_boot: bool,
    pub used_bytes: u64,
    pub total_bytes: u64,
    pub label: String,
}

pub fn block_devices(host_prefix: &str) -> Vec<BlockDevice> {
    #[cfg(target_os = "linux")]
    {
        block_devices_linux(host_prefix).unwrap_or_default()
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = host_prefix;
        Vec::new()
    }
}

#[cfg(target_os = "linux")]
fn block_devices_linux(host_prefix: &str) -> Result<Vec<BlockDevice>> {
    let block_dir = format!("{host_prefix}/sys/block");
    let mountinfo = fs::read_to_string(format!("{host_prefix}/proc/self/mountinfo"))?;
    let dev_by_mount = parse_mount_devices_text(&mountinfo);
    let resolve = |maj: u64, min: u64| resolve_block_dev(host_prefix, maj, min);
    let mount_map = build_device_mount_map(&dev_by_mount, resolve);
    let disk_mounts = disk_mount_paths(&dev_by_mount, resolve);

    let mut names: Vec<String> = fs::read_dir(&block_dir)?
        .filter_map(|e| e.ok())
        .map(|e| e.file_name().to_string_lossy().to_string())
        .filter(|n| is_whole_disk(n))
        .collect();
    names.sort();

    Ok(names
        .into_iter()
        .map(|name| {
            let mounts = disk_mounts.get(&name).cloned().unwrap_or_default();
            block_device_from_parts(host_prefix, &name, &mount_map, &mounts)
        })
        .collect())
}

fn disk_mount_paths(
    dev_by_mount: &HashMap<String, (u64, u64)>,
    resolve_dev: impl Fn(u64, u64) -> String,
) -> HashMap<String, Vec<String>> {
    let mut out: HashMap<String, Vec<String>> = HashMap::new();
    for (mount, (maj, min)) in dev_by_mount {
        let dev_name = resolve_dev(*maj, *min);
        if dev_name.is_empty() {
            continue;
        }
        let disk = whole_disk_name(&dev_name);
        out.entry(disk).or_default().push(mount.clone());
    }
    out
}

fn block_device_from_parts(
    host_prefix: &str,
    name: &str,
    mount_map: &HashMap<String, DeviceMountInfo>,
    disk_mounts: &[String],
) -> BlockDevice {
    let info = mount_map.get(name).cloned().unwrap_or_default();
    let mount = info.mount;
    let is_boot = info.is_boot;
    let label = device_label(&mount, is_boot);
    let (used_bytes, total_bytes) = device_bytes(host_prefix, name, disk_mounts);
    BlockDevice {
        name: name.to_string(),
        mount,
        is_boot,
        used_bytes,
        total_bytes,
        label,
    }
}

pub fn is_whole_disk(name: &str) -> bool {
    if name.starts_with("nvme") {
        return name.contains('n') && !name.contains('p');
    }
    if name.starts_with("sd") {
        return !name
            .chars()
            .last()
            .map(|c| c.is_ascii_digit())
            .unwrap_or(false);
    }
    false
}

pub fn whole_disk_name(dev: &str) -> String {
    if dev.starts_with("nvme") {
        if let Some(pos) = dev.rfind('p') {
            let suffix = &dev[pos + 1..];
            if !suffix.is_empty() && suffix.chars().all(|c| c.is_ascii_digit()) {
                return dev[..pos].to_string();
            }
        }
        return dev.to_string();
    }
    if dev.starts_with("sd") {
        let stem = dev.trim_end_matches(|c: char| c.is_ascii_digit());
        return if stem.is_empty() {
            dev.to_string()
        } else {
            stem.to_string()
        };
    }
    dev.to_string()
}

fn device_label(mount: &str, is_boot: bool) -> String {
    if is_boot {
        return "boot".into();
    }
    if mount.is_empty() {
        return String::new();
    }
    Path::new(mount)
        .file_name()
        .map(|s| s.to_string_lossy().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| mount.trim_start_matches('/').into())
}

fn device_bytes(host_prefix: &str, name: &str, mounts: &[String]) -> (u64, u64) {
    let total = sysfs_size(host_prefix, name).1;
    let mut used = 0u64;
    let mut seen = std::collections::HashSet::new();
    for mount in mounts {
        if !seen.insert(mount.as_str()) {
            continue;
        }
        let path = host_path(host_prefix, mount);
        if !exists(&path) {
            continue;
        }
        let (u, _) = stat_bytes(&path).unwrap_or((0, 0));
        used = used.saturating_add(u);
    }
    if total > 0 {
        return (used.min(total), total);
    }
    if mounts.len() == 1 {
        let path = host_path(host_prefix, &mounts[0]);
        if exists(&path) {
            return stat_bytes(&path).unwrap_or((0, 0));
        }
    }
    (used, total)
}

fn sysfs_size(host_prefix: &str, name: &str) -> (u64, u64) {
    let path = format!("{host_prefix}/sys/block/{name}/size");
    let sectors = fs::read_to_string(&path)
        .ok()
        .and_then(|s| s.trim().parse::<u64>().ok())
        .unwrap_or(0);
    (0, sectors * 512)
}

#[cfg(target_os = "linux")]
fn resolve_block_dev(host_prefix: &str, maj: u64, min: u64) -> String {
    let path = format!("{host_prefix}/sys/dev/block/{}:{}", maj, min);
    fs::read_link(&path)
        .ok()
        .and_then(|target| target.file_name().map(|s| s.to_string_lossy().to_string()))
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    const MOUNTINFO_BOOT: &str = r"19 34 8:1 / / rw,relatime - ext4 /dev/sda1 rw
20 19 8:1 / /var/lib/docker rw,relatime - ext4 /dev/sda1 rw
30 19 8:16 / /data rw,relatime - ext4 /dev/sdb rw";

    fn dev_resolver(maj: u64, min: u64) -> String {
        match (maj, min) {
            (8, 1) => "sda1".into(),
            (8, 16) => "sdb".into(),
            _ => String::new(),
        }
    }

    #[test]
    fn boot_device_marked() {
        let mount_map = device_mounts_from_mountinfo(MOUNTINFO_BOOT, dev_resolver);
        let dev_by_mount = parse_mount_devices_text(MOUNTINFO_BOOT);
        let disk_mounts = disk_mount_paths(&dev_by_mount, dev_resolver);
        let devices = ["sda", "sdb"]
            .iter()
            .map(|name| {
                let mounts = disk_mounts.get(*name).cloned().unwrap_or_default();
                block_device_from_parts("", name, &mount_map, &mounts)
            })
            .collect::<Vec<_>>();
        assert!(devices.iter().any(|d| d.is_boot && d.name == "sda"));
        let boot = devices.iter().find(|d| d.name == "sda").unwrap();
        assert_eq!(boot.mount, "/var/lib/docker");
        assert_eq!(boot.label, "boot");
        let data = devices.iter().find(|d| d.name == "sdb").unwrap();
        assert!(!data.is_boot);
        assert_eq!(data.mount, "/data");
        assert_eq!(data.label, "data");
    }

    #[test]
    fn whole_disk_filters_partitions() {
        assert!(is_whole_disk("sda"));
        assert!(!is_whole_disk("sda1"));
        assert!(is_whole_disk("nvme0n1"));
        assert!(!is_whole_disk("nvme0n1p1"));
        assert_eq!(whole_disk_name("sda1"), "sda");
        assert_eq!(whole_disk_name("nvme0n1p2"), "nvme0n1");
    }
}
