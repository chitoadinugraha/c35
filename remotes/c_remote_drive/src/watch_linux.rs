#[cfg(target_os = "linux")]
mod linux_impl {
    use std::path::{Path, PathBuf};
    use std::sync::mpsc;
    use std::time::Duration;

    use inotify::{EventMask, Inotify, WatchDescriptor, WatchMask};
    use tracing::{info, warn};

    use crate::sync_wake;
    use crate::vfs::VfsDriveManager;

    pub fn start_drive_watcher(backing_dir: PathBuf) {
        std::thread::Builder::new()
            .name("alienai-drive-watch".into())
            .spawn(move || watch_supervisor(backing_dir))
            .ok();
    }

    fn watch_supervisor(root: PathBuf) {
        let (signal_tx, signal_rx) = mpsc::channel::<()>();
        let root_watch = root.clone();
        std::thread::Builder::new()
            .name("alienai-drive-watch-io".into())
            .spawn(move || {
                if let Err(e) = watch_loop(&root_watch, move || {
                    let _ = signal_tx.send(());
                }) {
                    warn!("Drive FS watcher exited: {e:#}");
                }
            })
            .ok();
        info!("Drive FS watcher started on {:?}", root);
        while signal_rx.recv().is_ok() {
            while signal_rx.recv_timeout(Duration::from_millis(400)).is_ok() {}
            sync_wake::wake_sync();
        }
    }

    fn watch_loop(root: &PathBuf, mut on_change: impl FnMut() + Send + 'static) -> anyhow::Result<()> {
        let mut inotify = Inotify::init()?;
        let root_wd = inotify.watches().add(root, WatchMask::MODIFY | WatchMask::CREATE | WatchMask::DELETE)?;
        let mut dir_watches: Vec<(WatchDescriptor, PathBuf)> = vec![(root_wd, root.clone())];
        register_tree(&mut inotify, root, &mut dir_watches)?;

        let mut buffer = [0u8; 4096];
        loop {
            let events = inotify.read_events_blocking(&mut buffer)?;
            let mut saw_user_change = false;
            for event in events {
                if event.mask.contains(EventMask::ISDIR) {
                    if event.mask.contains(EventMask::CREATE) {
                        if let Some(name) = event.name {
                            let sub = root.join(name);
                            if sub.is_dir() {
                                if let Ok(wd) = inotify
                                    .watches()
                                    .add(&sub, WatchMask::MODIFY | WatchMask::CREATE | WatchMask::DELETE)
                                {
                                    dir_watches.push((wd, sub));
                                }
                            }
                        }
                    }
                    continue;
                }
                if let Some(name) = event.name {
                    let rel = PathBuf::from(name);
                    if !VfsDriveManager::is_internal_path(&rel) {
                        let rel_s = rel.to_string_lossy().replace('\\', "/");
                        sync_wake::pending_push(&rel_s);
                        saw_user_change = true;
                    }
                }
            }
            if saw_user_change {
                on_change();
            }
        }
    }

    fn register_tree(
        inotify: &mut Inotify,
        dir: &Path,
        watches: &mut Vec<(WatchDescriptor, PathBuf)>,
    ) -> anyhow::Result<()> {
        for ent in std::fs::read_dir(dir)?.flatten() {
            let path = ent.path();
            if !path.is_dir() {
                continue;
            }
            let rel = path.strip_prefix(dir).unwrap_or(&path);
            if VfsDriveManager::is_internal_path(rel) {
                continue;
            }
            if let Ok(wd) = inotify
                .watches()
                .add(&path, WatchMask::MODIFY | WatchMask::CREATE | WatchMask::DELETE)
            {
                watches.push((wd, path.clone()));
            }
            register_tree(inotify, &path, watches)?;
        }
        Ok(())
    }
}

#[cfg(target_os = "linux")]
pub use linux_impl::*;

#[cfg(not(target_os = "linux"))]
pub fn start_drive_watcher(_backing_dir: std::path::PathBuf) {}
