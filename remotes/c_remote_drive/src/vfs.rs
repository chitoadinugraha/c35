use std::fs;
use std::path::{Path, PathBuf};
use tracing::{info, warn};

/// Visible seed folders from an older layout. We do **not** create them:
/// a fresh A:\ is an empty user cloud disk (browser profile lives outside the mount).
const SEED_VISIBLE: &[&str] = &["Downloads", "Reports", "Projects"];
const DRIVE_ICO_BYTES: &[u8] = include_bytes!("../resources/alien_rounded.ico");

pub struct VfsDriveManager {
    pub drive_letter: String,
    pub backing_dir: PathBuf,
}

impl VfsDriveManager {
    pub fn new(drive_letter: &str) -> Self {
        let user_profile = std::env::var("USERPROFILE")
            .or_else(|_| std::env::var("HOME"))
            .unwrap_or_else(|_| "C:\\AlienData".into());
        Self::with_backing_dir(drive_letter, PathBuf::from(user_profile).join(".alienai").join("drive_a"))
    }

    pub fn with_backing_dir(drive_letter: &str, backing_dir: PathBuf) -> Self {
        Self { drive_letter: drive_letter.to_string(), backing_dir }
    }

    pub fn is_sync_skipped(rel: &Path) -> bool {
        Self::path_has_reserved_name(rel) || rel == Path::new(".directory")
    }

    /// Paths that must never appear on A:\ or participate in cloud sync.
    pub fn is_internal_path(rel: &Path) -> bool {
        if rel == Path::new(".directory") {
            return false;
        }
        Self::path_has_reserved_name(rel)
            || rel.components().any(|c| {
                c.as_os_str().to_string_lossy().starts_with('.')
            })
    }

    /// Browser / agent runtime data — stored beside drive_a, never mounted on A:\.
    pub fn system_dir(&self) -> PathBuf {
        self.backing_dir
            .parent()
            .map(|p| p.join("system"))
            .unwrap_or_else(|| self.backing_dir.join(".system"))
    }

    fn path_has_reserved_name(rel: &Path) -> bool {
        rel.components().any(|c| {
            let name = c.as_os_str().to_string_lossy();
            name.eq_ignore_ascii_case("System") || name.eq_ignore_ascii_case("autorun.inf")
        })
    }

    pub fn initialize(&self) -> anyhow::Result<()> {
        self.prepare_layout()?;
        #[cfg(target_os = "windows")]
        {
            self.mount_subst();
            let icon_dest = self.system_dir().join("alienai.ico");
            if icon_dest.exists() {
                self.configure_windows_drive_icons(&icon_dest);
            }
        }
        Ok(())
    }

    pub fn is_mounted(&self) -> bool {
        let drive_root = format!("{}\\", self.drive_letter.trim_end_matches('\\'));
        Path::new(&drive_root).exists()
    }

    #[cfg(target_os = "windows")]
    pub fn unmount_subst(&self) {
        let drive = self.drive_letter.trim_end_matches('\\');
        info!("Unmounting virtual drive {}", drive);
        match c_remote_core::win_powershell::program_status("subst", &[drive, "/d"]) {
            Ok(s) if s.success() => info!("Unmounted virtual drive {}", drive),
            Ok(s) => warn!("subst /d exited with status {:?}", s),
            Err(e) => warn!("Failed to execute subst /d: {}", e),
        }
    }

    #[cfg(not(target_os = "windows"))]
    pub fn unmount_subst(&self) {}

    #[cfg(target_os = "windows")]
    pub fn mount_subst(&self) {
        let drive = self.drive_letter.trim_end_matches('\\');
        let drive_root = format!("{}\\", drive);
        if Path::new(&drive_root).exists() {
            info!("Drive {} is already active on system", drive_root);
            return;
        }
        info!("Mounting {} -> {:?}", drive, self.backing_dir);
        let backing = self.backing_dir.to_string_lossy();
        match c_remote_core::win_powershell::program_status("subst", &[drive, backing.as_ref()]) {
            Ok(s) if s.success() => info!("Successfully mounted Virtual Drive {}", drive),
            Ok(s) => warn!("subst exited with status {:?}", s),
            Err(e) => warn!("Failed to execute subst command: {}", e),
        }
    }

    /// User files live on A:\. Browser profile + drive metadata live under ~/.alienai/system (not mounted).
    pub fn prepare_layout(&self) -> anyhow::Result<()> {
        info!("Initializing VFS backing cache directory: {:?}", self.backing_dir);
        fs::create_dir_all(&self.backing_dir)?;

        self.migrate_legacy_system_dir();
        let sys_dir = self.system_dir();
        fs::create_dir_all(sys_dir.join("Chrome").join("win_64"))?;
        fs::create_dir_all(sys_dir.join("Chrome").join("win_arm"))?;
        fs::create_dir_all(sys_dir.join("Common"))?;

        self.prune_empty_seed_dirs();
        self.remove_legacy_drive_artifacts();
        self.copy_icon(&sys_dir.join("alienai.ico"));
        self.write_autorun();
        self.hide_system_files(&sys_dir);
        Ok(())
    }

    fn migrate_legacy_system_dir(&self) {
        let legacy = self.backing_dir.join("System");
        if !legacy.is_dir() {
            return;
        }
        let dest = self.system_dir();
        if let Err(e) = fs::create_dir_all(&dest) {
            warn!("Could not create system dir {:?}: {e}", dest);
            return;
        }
        if dir_is_empty(&dest) {
            if fs::rename(&legacy, &dest).is_ok() {
                info!("Moved browser profile out of A:\\ to {:?}", dest);
                return;
            }
        }
        if let Err(e) = fs::remove_dir_all(&legacy) {
            warn!("Could not remove legacy A:\\System folder: {e}");
        } else {
            info!("Removed legacy A:\\System folder (profile now at {:?})", dest);
        }
    }

    fn prune_empty_seed_dirs(&self) {
        for name in SEED_VISIBLE {
            let dir = self.backing_dir.join(name);
            if dir.is_dir() && dir_is_empty(&dir) {
                match fs::remove_dir(&dir) {
                    Ok(()) => info!("Removed empty A:\\{name} (not shown until a file exists)"),
                    Err(e) => warn!("Could not remove empty A:\\{name}: {e}"),
                }
            }
        }
    }

    fn remove_legacy_drive_artifacts(&self) {
        let legacy_manifest = self.backing_dir.join(".alienai_sync_manifest.json");
        if legacy_manifest.is_file() {
            let _ = fs::remove_file(legacy_manifest);
        }
        let legacy_system = self.backing_dir.join("System");
        if legacy_system.is_dir() {
            let _ = fs::remove_dir_all(&legacy_system);
        }
        for name in SEED_VISIBLE {
            let dir = self.backing_dir.join(name);
            if dir.is_dir() && dir_is_empty(&dir) {
                let _ = fs::remove_dir(&dir);
            }
        }
    }

    fn copy_icon(&self, icon_dest: &Path) {
        let needs_write = match fs::read(icon_dest) {
            Ok(existing) => existing != DRIVE_ICO_BYTES,
            Err(_) => true,
        };
        if needs_write {
            if let Some(parent) = icon_dest.parent() {
                let _ = fs::create_dir_all(parent);
            }
            if fs::write(icon_dest, DRIVE_ICO_BYTES).is_ok() {
                info!("Wrote VFS drive icon to {:?}", icon_dest);
                return;
            }
            if let Ok(local) = std::env::var("LOCALAPPDATA") {
                let local_ico = PathBuf::from(local).join("AlienAI").join("alien_rounded.ico");
                if local_ico.exists() && fs::copy(&local_ico, icon_dest).is_ok() {
                    info!("Copied VFS drive icon from {:?}", local_ico);
                    return;
                }
            }
            warn!("VFS drive icon missing at {:?}; skipping icon copy", icon_dest);
        }
    }

    fn write_autorun(&self) {
        let autorun_path = self.backing_dir.join("autorun.inf");
        let _ = fs::write(&autorun_path, "[autorun]\r\nlabel=Alien AI\r\n");
        #[cfg(target_os = "windows")]
        {
            let path = autorun_path.to_str().unwrap_or_default();
            let _ = c_remote_core::win_powershell::program_status("attrib", &["+h", "+s", path]);
        }
    }

    fn hide_system_files(&self, sys_dir: &Path) {
        #[cfg(target_os = "windows")]
        {
            let path = sys_dir.to_str().unwrap_or_default();
            let _ = c_remote_core::win_powershell::program_status("attrib", &["+h", "+s", path]);
        }
        #[cfg(not(target_os = "windows"))]
        {
            let _ = sys_dir;
        }
    }

    #[cfg(target_os = "windows")]
    pub fn configure_windows_drive_icons(&self, icon_path: &Path) {
        let drive_clean = self.drive_letter.trim_end_matches(':').trim_end_matches('\\');
        let icon_str = icon_path.to_str().unwrap_or_default().replace('\\', "\\\\");
        let has_icon = icon_path.exists();
        let icon_cmds = if has_icon {
            format!(
                "New-Item -Path \"$regPath\\DefaultIcon\" -Force | Out-Null; \
                 New-Item -Path \"$expPath\\DefaultIcon\" -Force | Out-Null; \
                 Set-ItemProperty -Path \"$regPath\\DefaultIcon\" -Name '(Default)' -Value '{icon},0'; \
                 Set-ItemProperty -Path \"$expPath\\DefaultIcon\" -Name '(Default)' -Value '{icon},0';",
                icon = icon_str
            )
        } else {
            String::new()
        };
        let ps_script = format!(
            "$regPath = 'HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\DriveIcons\\{d}'; \
             $expPath = 'HKCU:\\Software\\Classes\\Applications\\explorer.exe\\Drives\\{d}'; \
             New-Item -Path \"$regPath\\DefaultLabel\" -Force | Out-Null; \
             New-Item -Path \"$expPath\\DefaultLabel\" -Force | Out-Null; \
             Set-ItemProperty -Path \"$regPath\\DefaultLabel\" -Name '(Default)' -Value 'Alien AI'; \
             Set-ItemProperty -Path \"$expPath\\DefaultLabel\" -Name '(Default)' -Value 'Alien AI'; \
             {icon_cmds} \
             try {{ \
                 Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class ShellNotify {{ [DllImport(\"shell32.dll\")] public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2); }}' -ErrorAction SilentlyContinue; \
                 [ShellNotify]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero); \
             }} catch {{}}",
            d = drive_clean,
        );
        let _ = c_remote_core::win_powershell::command_status(&ps_script);
    }

    pub fn get_chrome_profile_dir(&self) -> PathBuf {
        let arch = std::env::consts::ARCH;
        let sys_dir = self.system_dir();
        if arch.contains("arm") || arch.contains("aarch64") {
            sys_dir.join("Chrome").join("win_arm")
        } else {
            sys_dir.join("Chrome").join("win_64")
        }
    }
}

fn dir_is_empty(dir: &Path) -> bool {
    fs::read_dir(dir).map(|mut it| it.next().is_none()).unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn layout_matches_cs_hidden_system_without_seed_folders() {
        let tmp = tempfile::tempdir().unwrap();
        let backing = tmp.path().join("drive_a");
        let vfs = VfsDriveManager::with_backing_dir("A:", backing.clone());
        vfs.prepare_layout().unwrap();
        let sys = backing.parent().unwrap().join("system");
        assert!(sys.join("Chrome").join("win_64").is_dir());
        assert!(sys.join("Chrome").join("win_arm").is_dir());
        assert!(sys.join("Common").is_dir());
        assert!(!backing.join("System").exists());
        assert!(backing.join("autorun.inf").is_file());
        assert!(!backing.join("Downloads").exists());
        assert!(!backing.join("Reports").exists());
        assert!(!backing.join("Projects").exists());
    }

    #[test]
    fn layout_prunes_empty_downloads_reports() {
        let tmp = tempfile::tempdir().unwrap();
        let backing = tmp.path().join("drive_a");
        fs::create_dir_all(backing.join("Downloads")).unwrap();
        fs::create_dir_all(backing.join("Reports")).unwrap();
        fs::create_dir_all(backing.join("Projects")).unwrap();
        fs::write(backing.join("Downloads").join("keep.txt"), b"x").unwrap();
        let vfs = VfsDriveManager::with_backing_dir("A:", backing.clone());
        vfs.prepare_layout().unwrap();
        assert!(backing.join("Downloads").join("keep.txt").is_file());
        assert!(!backing.join("Reports").exists());
        assert!(!backing.join("Projects").exists());
    }

    #[test]
    fn sync_skips_system_and_autorun() {
        assert!(VfsDriveManager::is_sync_skipped(Path::new("System/Chrome/win_64")));
        assert!(VfsDriveManager::is_sync_skipped(Path::new("autorun.inf")));
        assert!(!VfsDriveManager::is_sync_skipped(Path::new("Downloads/a.pdf")));
        assert!(!VfsDriveManager::is_sync_skipped(Path::new("notes.txt")));
    }

    #[test]
    fn internal_paths_skip_dotfiles_and_manifest() {
        assert!(VfsDriveManager::is_internal_path(Path::new(".alienai_sync_manifest.json")));
        assert!(VfsDriveManager::is_internal_path(Path::new(".hidden")));
        assert!(VfsDriveManager::is_internal_path(Path::new("System/Chrome/win_64")));
        assert!(VfsDriveManager::is_internal_path(Path::new("autorun.inf")));
        assert!(!VfsDriveManager::is_internal_path(Path::new("notes.txt")));
    }

}
