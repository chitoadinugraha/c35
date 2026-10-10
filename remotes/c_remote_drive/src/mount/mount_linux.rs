#[cfg(target_os = "linux")]
mod linux_impl {
    use std::collections::HashMap;
    use std::ffi::OsStr;
    use std::fs::{self, File};
    use std::io::{Read, Seek, SeekFrom, Write};
    use std::path::{Path, PathBuf};
    use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
    use std::sync::{mpsc, Mutex};
    use std::time::{Duration, SystemTime};

    use fuser::{
        FileAttr, FileType, Filesystem, MountOption, ReplyAttr, ReplyCreate, ReplyData, ReplyDirectory,
        ReplyEmpty, ReplyEntry, ReplyOpen, ReplyStatfs, ReplyWrite, Request,
    };
    use tracing::{info, warn};

    use crate::vfs::VfsDriveManager;
    use crate::vfs_winfsp::QuotaSnapshot;

    const ROOT_INO: u64 = 1;
    const TTL: Duration = Duration::from_secs(1);

    pub struct LinuxMountGuard {
        mount_point: PathBuf,
        thread: Option<std::thread::JoinHandle<()>>,
    }

    impl LinuxMountGuard {
        pub fn unmount(self) {
            let mp = self.mount_point.to_string_lossy().to_string();
            let _ = std::process::Command::new("fusermount").args(["-u", &mp]).status();
            if let Some(t) = self.thread {
                let _ = t.join();
            }
        }
    }

    pub struct LinuxMount;

    impl super::super::DriveMount for LinuxMount {
        type Handle = LinuxMountGuard;

        fn mount(vfs: &VfsDriveManager, quota: Option<QuotaSnapshot>) -> anyhow::Result<LinuxMountGuard> {
            mount(vfs, quota)
        }

        fn unmount(handle: LinuxMountGuard) {
            handle.unmount();
        }
    }

    pub fn linux_mount_point() -> PathBuf {
        let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".into());
        PathBuf::from(home).join("Alien AI")
    }

    pub fn try_unmount_mount_point() {
        let mp = linux_mount_point();
        if mp.exists() {
            let s = mp.to_string_lossy().to_string();
            let _ = std::process::Command::new("fusermount").args(["-u", &s]).status();
        }
    }

    pub fn mount(vfs: &VfsDriveManager, quota: Option<QuotaSnapshot>) -> anyhow::Result<LinuxMountGuard> {
        vfs.prepare_layout()?;
        write_mount_directory_metadata(vfs)?;
        let quota = quota.unwrap_or(QuotaSnapshot {
            used_bytes: 0,
            limit_bytes: 1024 * 1024 * 1024,
        });
        let mount_point = linux_mount_point();
        fs::create_dir_all(&mount_point)?;
        if is_fuse_mounted(&mount_point) {
            info!("Alien AI Drive already mounted at {:?}", mount_point);
            return Ok(LinuxMountGuard { mount_point, thread: None });
        }
        let fs = AlienDriveFs::new(vfs.backing_dir.clone(), quota.limit_bytes, quota.used_bytes);
        let session = fuser::Session::new(
            fs,
            &mount_point,
            &[
                MountOption::FSName("AlienAI".into()),
                MountOption::AutoUnmount,
                MountOption::DefaultPermissions,
            ],
        )?;
        let running = AtomicBool::new(true);
        let (err_tx, err_rx) = mpsc::channel();
        let thread = std::thread::Builder::new()
            .name("alienai-fuse".into())
            .spawn(move || {
                if let Err(e) = session.run() {
                    if running.load(Ordering::Relaxed) {
                        let _ = err_tx.send(e);
                    }
                }
            })?;
        std::thread::sleep(Duration::from_millis(200));
        if let Ok(e) = err_rx.try_recv() {
            anyhow::bail!("FUSE mount failed: {e}");
        }
        if !is_fuse_mounted(&mount_point) {
            running.store(false, Ordering::Relaxed);
            let _ = std::process::Command::new("fusermount")
                .args(["-u", mount_point.to_string_lossy().as_ref()])
                .status();
            anyhow::bail!("Alien AI Drive FUSE mount did not become active at {:?}", mount_point);
        }
        info!(
            "Alien AI Drive mounted at {:?} ({} GB quota)",
            mount_point,
            quota.limit_bytes / (1024 * 1024 * 1024)
        );
        Ok(LinuxMountGuard { mount_point, thread: Some(thread) })
    }

    fn write_mount_directory_metadata(vfs: &VfsDriveManager) -> anyhow::Result<()> {
        let icon = vfs.system_dir().join("alienai.ico");
        let desktop = format!(
            "[Desktop Entry]\nType=Directory\nName=Alien AI\nIcon={}\n",
            icon.to_string_lossy()
        );
        fs::write(vfs.backing_dir.join(".directory"), desktop)?;
        Ok(())
    }

    fn is_fuse_mounted(path: &Path) -> bool {
        fs::read_to_string("/proc/mounts")
            .map(|s| {
                let needle = path.to_string_lossy();
                s.lines().any(|line| {
                    let parts: Vec<&str> = line.split_whitespace().collect();
                    parts.len() >= 2 && parts[1] == needle
                })
            })
            .unwrap_or(false)
    }

    struct AlienDriveFs {
        backing_dir: PathBuf,
        quota_total: u64,
        quota_used: u64,
        paths: Mutex<HashMap<u64, PathBuf>>,
        next_ino: AtomicU64,
        open_files: Mutex<HashMap<u64, File>>,
        next_fh: AtomicU64,
    }

    impl AlienDriveFs {
        fn new(backing_dir: PathBuf, quota_total: u64, quota_used: u64) -> Self {
            let mut paths = HashMap::new();
            paths.insert(ROOT_INO, backing_dir.clone());
            Self {
                backing_dir,
                quota_total,
                quota_used,
                paths: Mutex::new(paths),
                next_ino: AtomicU64::new(2),
                open_files: Mutex::new(HashMap::new()),
                next_fh: AtomicU64::new(1),
            }
        }

        fn path_for(&self, ino: u64) -> Option<PathBuf> {
            self.paths.lock().unwrap().get(&ino).cloned()
        }

        fn assign_ino(&self, path: PathBuf) -> u64 {
            let mut paths = self.paths.lock().unwrap();
            for (ino, p) in paths.iter() {
                if p == &path {
                    return *ino;
                }
            }
            let ino = self.next_ino.fetch_add(1, Ordering::Relaxed);
            paths.insert(ino, path);
            ino
        }

        fn resolve_child(&self, parent: u64, name: &OsStr) -> Option<PathBuf> {
            let name = name.to_string_lossy();
            if name == "." {
                return self.path_for(parent);
            }
            if name == ".." {
                return None;
            }
            let parent_path = self.path_for(parent)?;
            let rel = parent_path.strip_prefix(&self.backing_dir).unwrap_or(Path::new(""));
            let child_rel = if rel.as_os_str().is_empty() {
                PathBuf::from(name.as_ref())
            } else {
                rel.join(name.as_ref())
            };
            if VfsDriveManager::is_internal_path(&child_rel) {
                return None;
            }
            Some(self.backing_dir.join(&child_rel))
        }

        fn file_attr(path: &Path, ino: u64) -> Result<FileAttr, std::io::Error> {
            let meta = fs::metadata(path)?;
            let kind = if meta.is_dir() {
                FileType::Directory
            } else {
                FileType::RegularFile
            };
            let mtime = meta.modified().unwrap_or(SystemTime::UNIX_EPOCH);
            let ctime = meta.created().unwrap_or(mtime);
            Ok(FileAttr {
                ino,
                size: meta.len(),
                blocks: (meta.len() + 511) / 512,
                atime: mtime,
                mtime,
                ctime,
                crtime: ctime,
                kind,
                perm: if meta.is_dir() { 0o755 } else { 0o644 },
                nlink: 1,
                uid: unsafe { libc::getuid() },
                gid: unsafe { libc::getgid() },
                rdev: 0,
                blksize: 4096,
                flags: 0,
            })
        }
    }

    impl Filesystem for AlienDriveFs {
        fn lookup(&mut self, _req: &Request, parent: u64, name: &OsStr, reply: ReplyEntry) {
            let path = match self.resolve_child(parent, name) {
                Some(p) => p,
                None => return reply.error(libc::ENOENT),
            };
            if !path.exists() {
                return reply.error(libc::ENOENT);
            }
            let ino = self.assign_ino(path.clone());
            match Self::file_attr(&path, ino) {
                Ok(attr) => reply.entry(&TTL, &attr, 0),
                Err(_) => reply.error(libc::ENOENT),
            }
        }

        fn getattr(&mut self, _req: &Request, ino: u64, reply: ReplyAttr) {
            let path = match self.path_for(ino) {
                Some(p) => p,
                None => return reply.error(libc::ENOENT),
            };
            match Self::file_attr(&path, ino) {
                Ok(attr) => reply.attr(&TTL, &attr),
                Err(e) => reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            }
        }

        fn read(
            &mut self,
            _req: &Request,
            _ino: u64,
            fh: u64,
            offset: i64,
            size: u32,
            _flags: i32,
            _lock_owner: Option<u64>,
            reply: ReplyData,
        ) {
            let mut files = self.open_files.lock().unwrap();
            let file = match files.get_mut(&fh) {
                Some(f) => f,
                None => return reply.error(libc::EBADF),
            };
            if file.seek(SeekFrom::Start(offset as u64)).is_err() {
                return reply.error(libc::EIO);
            }
            let mut buf = vec![0u8; size as usize];
            match file.read(&mut buf) {
                Ok(0) => reply.data(&[]),
                Ok(n) => {
                    buf.truncate(n);
                    reply.data(&buf);
                }
                Err(e) => reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            }
        }

        fn write(
            &mut self,
            _req: &Request,
            ino: u64,
            fh: u64,
            offset: i64,
            data: &[u8],
            _write_flags: u32,
            _flags: i32,
            _lock_owner: Option<u64>,
            reply: ReplyWrite,
        ) {
            let path = self.path_for(ino);
            let mut files = self.open_files.lock().unwrap();
            let file = match files.get_mut(&fh) {
                Some(f) => f,
                None => return reply.error(libc::EBADF),
            };
            if file.seek(SeekFrom::Start(offset as u64)).is_err() {
                return reply.error(libc::EIO);
            }
            match file.write_all(data) {
                Ok(()) => {
                    if let Some(p) = path {
                        if let Ok(meta) = fs::metadata(&p) {
                            let _ = file.set_len(meta.len());
                        }
                    }
                    reply.written(data.len() as u32);
                }
                Err(e) => reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            }
        }

        fn open(&mut self, _req: &Request, ino: u64, flags: i32, reply: ReplyOpen) {
            let path = match self.path_for(ino) {
                Some(p) => p,
                None => return reply.error(libc::ENOENT),
            };
            if path.is_dir() {
                return reply.error(libc::EISDIR);
            }
            let write = (flags & libc::O_WRONLY) != 0 || (flags & libc::O_RDWR) != 0;
            let file = match fs::OpenOptions::new().read(true).write(write).open(&path) {
                Ok(f) => f,
                Err(e) => return reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            };
            let fh = self.next_fh.fetch_add(1, Ordering::Relaxed);
            self.open_files.lock().unwrap().insert(fh, file);
            reply.opened(fh, 0);
        }

        fn release(
            &mut self,
            _req: &Request,
            _ino: u64,
            fh: u64,
            _flags: i32,
            _lock_owner: Option<u64>,
            _flush: bool,
            reply: ReplyEmpty,
        ) {
            self.open_files.lock().unwrap().remove(&fh);
            reply.ok();
        }

        fn readdir(&mut self, _req: &Request, ino: u64, _fh: u64, offset: i64, mut reply: ReplyDirectory) {
            let dir = match self.path_for(ino) {
                Some(p) => p,
                None => return reply.error(libc::ENOENT),
            };
            if !dir.is_dir() {
                return reply.error(libc::ENOTDIR);
            }
            let mut entries: Vec<(u64, FileType, String)> = vec![
                (ino, FileType::Directory, ".".into()),
                (ino, FileType::Directory, "..".into()),
            ];
            if let Ok(rd) = fs::read_dir(&dir) {
                for ent in rd.flatten() {
                    let name = ent.file_name().to_string_lossy().to_string();
                    let rel = dir.strip_prefix(&self.backing_dir).unwrap_or(Path::new(""));
                    let child_rel = if rel.as_os_str().is_empty() {
                        PathBuf::from(&name)
                    } else {
                        rel.join(&name)
                    };
                    if VfsDriveManager::is_internal_path(&child_rel) {
                        continue;
                    }
                    let path = ent.path();
                    let kind = if path.is_dir() {
                        FileType::Directory
                    } else {
                        FileType::RegularFile
                    };
                    let child_ino = self.assign_ino(path);
                    entries.push((child_ino, kind, name));
                }
            }
            entries.sort_by(|a, b| a.2.to_ascii_lowercase().cmp(&b.2.to_ascii_lowercase()));
            for (idx, (child_ino, kind, name)) in entries.into_iter().enumerate() {
                let off = (idx + 1) as i64;
                if off <= offset {
                    continue;
                }
                if reply.add(child_ino, off, kind, name) {
                    break;
                }
            }
            reply.ok();
        }

        fn mkdir(
            &mut self,
            _req: &Request,
            parent: u64,
            name: &OsStr,
            _mode: u32,
            _umask: u32,
            reply: ReplyEntry,
        ) {
            let path = match self.resolve_child(parent, name) {
                Some(p) => p,
                None => return reply.error(libc::ENOENT),
            };
            if fs::create_dir(&path).is_err() {
                return reply.error(libc::EIO);
            }
            let ino = self.assign_ino(path.clone());
            match Self::file_attr(&path, ino) {
                Ok(attr) => reply.entry(&TTL, &attr, 0),
                Err(e) => reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            }
        }

        fn create(
            &mut self,
            _req: &Request,
            parent: u64,
            name: &OsStr,
            _mode: u32,
            _umask: u32,
            flags: i32,
            reply: ReplyCreate,
        ) {
            let path = match self.resolve_child(parent, name) {
                Some(p) => p,
                None => return reply.error(libc::ENOENT),
            };
            if let Some(parent) = path.parent() {
                let _ = fs::create_dir_all(parent);
            }
            let write = (flags & libc::O_WRONLY) != 0 || (flags & libc::O_RDWR) != 0;
            let file = match fs::OpenOptions::new()
                .read(true)
                .write(write)
                .create(true)
                .truncate((flags & libc::O_TRUNC) != 0)
                .open(&path)
            {
                Ok(f) => f,
                Err(e) => return reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            };
            let ino = self.assign_ino(path.clone());
            let fh = self.next_fh.fetch_add(1, Ordering::Relaxed);
            self.open_files.lock().unwrap().insert(fh, file);
            match Self::file_attr(&path, ino) {
                Ok(attr) => reply.created(&TTL, &attr, 0, fh, 0),
                Err(e) => reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            }
        }

        fn unlink(&mut self, _req: &Request, parent: u64, name: &OsStr, reply: ReplyEmpty) {
            let path = match self.resolve_child(parent, name) {
                Some(p) => p,
                None => return reply.error(libc::ENOENT),
            };
            match fs::remove_file(&path) {
                Ok(()) => reply.ok(),
                Err(e) => reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            }
        }

        fn rmdir(&mut self, _req: &Request, parent: u64, name: &OsStr, reply: ReplyEmpty) {
            let path = match self.resolve_child(parent, name) {
                Some(p) => p,
                None => return reply.error(libc::ENOENT),
            };
            match fs::remove_dir(&path) {
                Ok(()) => reply.ok(),
                Err(e) => reply.error(e.raw_os_error().unwrap_or(libc::EIO)),
            }
        }

        fn statfs(&mut self, _req: &Request, _ino: u64, reply: ReplyStatfs) {
            let block_size = 4096u32;
            let total_blocks = self.quota_total / block_size as u64;
            let used_blocks = self.quota_used / block_size as u64;
            let free = total_blocks.saturating_sub(used_blocks);
            reply.statfs(total_blocks, free, free, 1, 1, block_size, 255, block_size);
        }
    }
}

#[cfg(target_os = "linux")]
pub use linux_impl::*;

#[cfg(not(target_os = "linux"))]
mod stub {
    use crate::vfs::VfsDriveManager;
    use crate::vfs_winfsp::QuotaSnapshot;

    pub struct LinuxMountGuard;

    impl LinuxMountGuard {
        pub fn unmount(self) {}
    }

    pub fn linux_mount_point() -> std::path::PathBuf {
        std::path::PathBuf::from("/Alien AI")
    }

    pub fn try_unmount_mount_point() {}

    pub fn mount(_vfs: &VfsDriveManager, _quota: Option<QuotaSnapshot>) -> anyhow::Result<LinuxMountGuard> {
        anyhow::bail!("Alien AI Drive FUSE mount is only supported on Linux")
    }
}

#[cfg(not(target_os = "linux"))]
pub use stub::*;
