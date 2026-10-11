use std::collections::HashMap;
use std::path::Path;

#[cfg(target_os = "linux")]
use std::fs;
use anyhow::Result;
#[cfg(target_os = "linux")]
use anyhow::Context;

use crate::sample::{IoSample, NetSample};

/// Linux `statvfs` filesystem id — dedupe bind mounts on the same superblock.
#[derive(Clone, Copy, Debug, Hash, PartialEq, Eq)]
pub struct FsId(pub [i32; 2]);

pub fn stat_bytes(path: &str) -> Result<(u64, u64)> {
    stat_bytes_with_fsid(path).map(|(u, t, _)| (u, t))
}

pub fn stat_bytes_with_fsid(path: &str) -> Result<(u64, u64, FsId)> {
    #[cfg(unix)]
    {
        stat_bytes_unix(path)
    }
    #[cfg(not(unix))]
    {
        let _ = path;
        Ok((0, 0, FsId([0, 0])))
    }
}

#[cfg(unix)]
fn stat_bytes_unix(path: &str) -> Result<(u64, u64, FsId)> {
    use std::ffi::CString;
    let c_path = CString::new(path).with_context(|| format!("path {path}"))?;
    let mut st = std::mem::MaybeUninit::<libc::statvfs>::uninit();
    let rc = unsafe { libc::statvfs(c_path.as_ptr(), st.as_mut_ptr()) };
    if rc != 0 {
        return Err(std::io::Error::last_os_error()).with_context(|| format!("statvfs {path}"));
    }
    let st = unsafe { st.assume_init() };
    let block_size = st.f_frsize as u64;
    let total = st.f_blocks as u64 * block_size;
    let free = st.f_bfree as u64 * block_size;
    let fsid = fsid_from_statvfs(&st);
    Ok((total.saturating_sub(free), total, fsid))
}

#[cfg(unix)]
fn fsid_from_statvfs(st: &libc::statvfs) -> FsId {
    let mut words = [0i32; 2];
    let src = &st.f_fsid as *const _ as *const u8;
    let dst = words.as_mut_ptr() as *mut u8;
    let n = std::mem::size_of_val(&st.f_fsid).min(8);
    unsafe {
        std::ptr::copy_nonoverlapping(src, dst, n);
    }
    FsId(words)
}

pub fn disk_io_by_device(host_prefix: &str, device_names: &[String]) -> HashMap<String, IoSample> {
    #[cfg(target_os = "linux")]
    {
        let diskstats = format!("{host_prefix}/proc/diskstats");
        let io_by_name = parse_diskstats_by_name(&diskstats).unwrap_or_default();
        device_names
            .iter()
            .map(|name| {
                let io = io_by_name.get(name).cloned().unwrap_or_default();
                (name.clone(), io)
            })
            .collect()
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = (host_prefix, device_names);
        HashMap::new()
    }
}

pub fn disk_io_by_mount(host_prefix: &str, mounts: &[String]) -> HashMap<String, IoSample> {
    #[cfg(target_os = "linux")]
    {
        disk_io_linux(host_prefix, mounts)
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = (host_prefix, mounts);
        HashMap::new()
    }
}

#[cfg(target_os = "linux")]
fn disk_io_linux(host_prefix: &str, mounts: &[String]) -> HashMap<String, IoSample> {
    let diskstats = format!("{host_prefix}/proc/diskstats");
    let dev_by_mount = read_host_mountinfo(host_prefix)
        .map(|text| parse_mount_devices_text(&text))
        .unwrap_or_default();
    let io_by_dev = parse_diskstats(&diskstats).unwrap_or_default();
    mounts
        .iter()
        .map(|mount| {
            let io = dev_by_mount
                .get(mount)
                .and_then(|dev| io_by_dev.get(dev))
                .cloned()
                .unwrap_or_default();
            (mount.clone(), io)
        })
        .collect()
}

#[cfg(target_os = "linux")]
pub fn parse_mount_devices(path: &str) -> Result<HashMap<String, (u64, u64)>> {
    let text = fs::read_to_string(path).with_context(|| format!("read {path}"))?;
    Ok(parse_mount_devices_text(&text))
}

pub fn parse_mount_devices_text(text: &str) -> HashMap<String, (u64, u64)> {
    let mut out = HashMap::new();
    for line in text.lines() {
        let left = line.split(" - ").next().unwrap_or(line);
        let parts: Vec<&str> = left.split_whitespace().collect();
        if parts.len() < 5 {
            continue;
        }
        let Some((maj, min)) = parse_dev(parts[2]) else {
            continue;
        };
        out.insert(parts[4].to_string(), (maj, min));
    }
    out
}

/// Map block major:minor to kernel device short name (e.g. `sda1`) from mountinfo source.
pub fn parse_mount_block_dev_names(text: &str) -> HashMap<(u64, u64), String> {
    let mut out = HashMap::new();
    for line in text.lines() {
        let (left, right) = match line.split_once(" - ") {
            Some(pair) => pair,
            None => continue,
        };
        let parts: Vec<&str> = left.split_whitespace().collect();
        if parts.len() < 5 {
            continue;
        }
        let Some((maj, min)) = parse_dev(parts[2]) else {
            continue;
        };
        let fs_parts: Vec<&str> = right.split_whitespace().collect();
        if fs_parts.len() < 2 {
            continue;
        }
        let source = fs_parts[1];
        let name = source
            .strip_prefix("/dev/")
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .unwrap_or(source);
        if name.is_empty() || name.starts_with("mapper/") {
            continue;
        }
        let short = name.rsplit('/').next().unwrap_or(name).to_string();
        out.insert((maj, min), short);
    }
    out
}

fn parse_dev(raw: &str) -> Option<(u64, u64)> {
    let (maj, min) = raw.split_once(':')?;
    Some((maj.parse().ok()?, min.parse().ok()?))
}

#[cfg(target_os = "linux")]
fn parse_diskstats(path: &str) -> Result<HashMap<(u64, u64), IoSample>> {
    let text = fs::read_to_string(path).with_context(|| format!("read {path}"))?;
    Ok(parse_diskstats_text(&text))
}

#[cfg(target_os = "linux")]
fn parse_diskstats_by_name(path: &str) -> Result<HashMap<String, IoSample>> {
    let text = fs::read_to_string(path).with_context(|| format!("read {path}"))?;
    let mut out = HashMap::new();
    for line in text.lines() {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() < 14 {
            continue;
        }
        let name = parts[2].to_string();
        let sectors_read: u64 = parts[5].parse().unwrap_or(0);
        let sectors_written: u64 = parts[9].parse().unwrap_or(0);
        out.insert(
            name,
            IoSample {
                read_bytes: sectors_read * 512,
                write_bytes: sectors_written * 512,
            },
        );
    }
    Ok(out)
}

#[cfg(target_os = "linux")]
fn parse_diskstats_text(text: &str) -> HashMap<(u64, u64), IoSample> {
    let mut out = HashMap::new();
    for line in text.lines() {
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() < 14 {
            continue;
        }
        let maj: u64 = parts[0].parse().unwrap_or(0);
        let min: u64 = parts[1].parse().unwrap_or(0);
        let sectors_read: u64 = parts[5].parse().unwrap_or(0);
        let sectors_written: u64 = parts[9].parse().unwrap_or(0);
        out.insert(
            (maj, min),
            IoSample {
                read_bytes: sectors_read * 512,
                write_bytes: sectors_written * 512,
            },
        );
    }
    out
}

#[derive(Clone, Copy, Debug, Default)]
pub struct CpuSample {
    pub idle: u64,
    pub total: u64,
}

pub fn cpu_sample(host_prefix: &str) -> CpuSample {
    #[cfg(target_os = "linux")]
    {
        cpu_sample_linux(host_prefix).unwrap_or_default()
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = host_prefix;
        CpuSample::default()
    }
}

#[cfg(target_os = "linux")]
fn cpu_sample_linux(host_prefix: &str) -> Result<CpuSample> {
    let path = format!("{host_prefix}/proc/stat");
    let text = fs::read_to_string(&path).with_context(|| format!("read {path}"))?;
    let line = text.lines().next().context("empty /proc/stat")?;
    let parts: Vec<&str> = line.split_whitespace().collect();
    if parts.len() < 5 || parts[0] != "cpu" {
        anyhow::bail!("unexpected /proc/stat line");
    }
    let nums: Vec<u64> = parts[1..]
        .iter()
        .filter_map(|s| s.parse().ok())
        .collect();
    let idle = nums.get(3).copied().unwrap_or(0) + nums.get(4).copied().unwrap_or(0);
    let total: u64 = nums.iter().sum();
    Ok(CpuSample { idle, total })
}

pub fn cpu_pct(prev: CpuSample, cur: CpuSample) -> f64 {
    let total_delta = cur.total.saturating_sub(prev.total);
    let idle_delta = cur.idle.saturating_sub(prev.idle);
    if total_delta == 0 {
        return 0.0;
    }
    (1.0 - idle_delta as f64 / total_delta as f64) * 100.0
}

pub fn mem_bytes(host_prefix: &str) -> (u64, u64) {
    #[cfg(target_os = "linux")]
    {
        mem_bytes_linux(host_prefix).unwrap_or((0, 0))
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = host_prefix;
        (0, 0)
    }
}

#[cfg(target_os = "linux")]
fn mem_bytes_linux(host_prefix: &str) -> Result<(u64, u64)> {
    let path = format!("{host_prefix}/proc/meminfo");
    let text = fs::read_to_string(&path).with_context(|| format!("read {path}"))?;
    let mut total = 0u64;
    let mut available = 0u64;
    for line in text.lines() {
        if let Some(v) = line.strip_prefix("MemTotal:") {
            total = parse_kib(v)?;
        } else if let Some(v) = line.strip_prefix("MemAvailable:") {
            available = parse_kib(v)?;
        }
    }
    if available == 0 {
        for line in text.lines() {
            if let Some(v) = line.strip_prefix("MemFree:") {
                available = parse_kib(v)?;
                break;
            }
        }
    }
    Ok((total.saturating_sub(available), total))
}

pub fn swap_bytes(host_prefix: &str) -> (u64, u64) {
    #[cfg(target_os = "linux")]
    {
        swap_bytes_linux(host_prefix).unwrap_or((0, 0))
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = host_prefix;
        (0, 0)
    }
}

#[cfg(target_os = "linux")]
fn swap_bytes_linux(host_prefix: &str) -> Result<(u64, u64)> {
    let path = format!("{host_prefix}/proc/meminfo");
    let text = fs::read_to_string(&path).with_context(|| format!("read {path}"))?;
    let mut total = 0u64;
    let mut free = 0u64;
    for line in text.lines() {
        if let Some(v) = line.strip_prefix("SwapTotal:") {
            total = parse_kib(v)?;
        } else if let Some(v) = line.strip_prefix("SwapFree:") {
            free = parse_kib(v)?;
        }
    }
    Ok((total.saturating_sub(free), total))
}

#[cfg(target_os = "linux")]
fn parse_kib(raw: &str) -> Result<u64> {
    let kb: u64 = raw
        .trim()
        .trim_end_matches(" kB")
        .trim()
        .parse()
        .context("parse meminfo kB")?;
    Ok(kb * 1024)
}

pub fn primary_net_iface(host_prefix: &str) -> String {
    #[cfg(target_os = "linux")]
    {
        primary_net_iface_linux(host_prefix).unwrap_or_else(|_| "net".into())
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = host_prefix;
        "net".into()
    }
}

#[cfg(target_os = "linux")]
fn primary_net_iface_linux(host_prefix: &str) -> Result<String> {
    let path = format!("{host_prefix}/proc/net/dev");
    let text = fs::read_to_string(&path).with_context(|| format!("read {path}"))?;
    let mut best: Option<(u64, String)> = None;
    for line in text.lines().skip(2) {
        let mut parts = line.split_whitespace();
        let Some(name) = parts.next() else {
            continue;
        };
        let name = name.trim_end_matches(':');
        if !is_candidate_iface(name) {
            continue;
        }
        let recv: u64 = parts.next().and_then(|s| s.parse().ok()).unwrap_or(0);
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let sent: u64 = parts.next().and_then(|s| s.parse().ok()).unwrap_or(0);
        let total = recv.saturating_add(sent);
        if best.as_ref().map(|b| total > b.0).unwrap_or(true) {
            best = Some((total, name.to_string()));
        }
    }
    Ok(best.map(|(_, n)| n).unwrap_or_else(|| "net".into()))
}

fn is_candidate_iface(name: &str) -> bool {
    if name == "lo" {
        return false;
    }
    let n = name.to_lowercase();
    if n.starts_with("veth")
        || n.starts_with("cali")
        || n.starts_with("flannel")
        || n.starts_with("cilium")
        || n.starts_with("kube")
        || n.starts_with("docker")
        || n.starts_with("tun")
        || n.starts_with("tailscale")
    {
        return false;
    }
    true
}

pub fn net_totals(host_prefix: &str) -> NetSample {
    #[cfg(target_os = "linux")]
    {
        net_totals_linux(host_prefix).unwrap_or_default()
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = host_prefix;
        NetSample::default()
    }
}

#[cfg(target_os = "linux")]
fn net_totals_linux(host_prefix: &str) -> Result<NetSample> {
    let path = format!("{host_prefix}/proc/net/dev");
    let text = fs::read_to_string(&path).with_context(|| format!("read {path}"))?;
    let mut in_bytes = 0u64;
    let mut out_bytes = 0u64;
    for line in text.lines().skip(2) {
        let mut parts = line.split_whitespace();
        let Some(name) = parts.next() else {
            continue;
        };
        let name = name.trim_end_matches(':');
        if name == "lo" {
            continue;
        }
        let recv: u64 = parts.next().and_then(|s| s.parse().ok()).unwrap_or(0);
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let _ = parts.next();
        let sent: u64 = parts.next().and_then(|s| s.parse().ok()).unwrap_or(0);
        in_bytes = in_bytes.saturating_add(recv);
        out_bytes = out_bytes.saturating_add(sent);
    }
    Ok(NetSample { in_bytes, out_bytes })
}

pub fn cpu_cores(host_prefix: &str) -> i32 {
    #[cfg(target_os = "linux")]
    {
        let path = format!("{host_prefix}/proc/cpuinfo");
        fs::read_to_string(&path)
            .map(|text| text.lines().filter(|l| l.starts_with("processor")).count() as i32)
            .unwrap_or(1)
            .max(1)
    }
    #[cfg(not(target_os = "linux"))]
    {
        let _ = host_prefix;
        1
    }
}

pub fn now_ms() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_millis() as i64)
        .unwrap_or(0)
}

pub fn host_path(host_prefix: &str, mount: &str) -> String {
    if mount == "/" {
        host_prefix.to_string()
    } else {
        format!("{host_prefix}{mount}")
    }
}

/// Host root mount table (not the stats container's namespace).
#[cfg(target_os = "linux")]
pub fn read_host_mountinfo(host_prefix: &str) -> Result<String> {
    let pid1 = format!("{host_prefix}/proc/1/mountinfo");
    if Path::new(&pid1).exists() {
        return fs::read_to_string(&pid1).with_context(|| format!("read {pid1}"));
    }
    let self_mi = format!("{host_prefix}/proc/self/mountinfo");
    fs::read_to_string(&self_mi).with_context(|| format!("read {self_mi}"))
}

#[cfg(not(target_os = "linux"))]
pub fn read_host_mountinfo(host_prefix: &str) -> Result<String> {
    let _ = host_prefix;
    Ok(String::new())
}

pub fn exists(path: &str) -> bool {
    Path::new(path).exists()
}
