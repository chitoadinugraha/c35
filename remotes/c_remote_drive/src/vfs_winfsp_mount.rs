#[cfg(target_os = "windows")]
mod win_impl {
    use std::ffi::c_void;
    use std::fs::{self, File};
    use std::io::{Read, Seek, SeekFrom, Write};
    use std::os::windows::fs::MetadataExt;
    use std::path::{Path, PathBuf};
    use std::sync::{Arc, Mutex};
    use tracing::info;
    use widestring::U16CStr;
    use windows::Win32::Storage::FileSystem::FILE_ATTRIBUTE_DIRECTORY;
    use winfsp::filesystem::{
        DirBuffer, DirInfo, DirMarker, FileInfo, FileSecurity, FileSystemContext, OpenFileInfo, VolumeInfo, WideNameInfo,
    };
    use winfsp::host::{FileSystemHost, FineGuard, VolumeParams};
    use winfsp_sys::{FILE_ACCESS_RIGHTS, FILE_FLAGS_AND_ATTRIBUTES};

    use crate::vfs::VfsDriveManager;

    pub struct FileHandle {
        pub path: PathBuf,
        pub is_dir: bool,
        pub file: Mutex<Option<File>>,
        pub dir_buffer: DirBuffer,
    }

    pub struct AlienVfsContext {
        pub backing_dir: PathBuf,
        pub quota_total: u64,
        pub quota_used: u64,
    }

    impl AlienVfsContext {
        pub fn new(backing_dir: PathBuf, quota_total_bytes: u64, quota_used_bytes: u64) -> Self {
            Self { backing_dir, quota_total: quota_total_bytes, quota_used: quota_used_bytes }
        }

        fn to_backing_path(&self, file_name: &U16CStr) -> PathBuf {
            let rel_str = file_name.to_string_lossy();
            let clean = rel_str.trim_start_matches('\\').trim_start_matches('/');
            if clean.is_empty() { self.backing_dir.clone() } else { self.backing_dir.join(clean) }
        }

        fn rel_path_from_name(file_name: &U16CStr) -> PathBuf {
            let rel_str = file_name.to_string_lossy();
            let clean = rel_str.trim_start_matches('\\').trim_start_matches('/');
            PathBuf::from(clean.replace('\\', "/"))
        }

        fn is_denied_user_path(file_name: &U16CStr) -> bool {
            let rel = Self::rel_path_from_name(file_name);
            !rel.as_os_str().is_empty() && VfsDriveManager::is_internal_path(&rel)
        }

        fn fill_file_info(&self, path: &Path, file_info: &mut FileInfo) -> bool {
            if let Ok(meta) = fs::metadata(path) {
                file_info.file_attributes = meta.file_attributes();
                if meta.is_dir() && file_info.file_attributes & FILE_ATTRIBUTE_DIRECTORY.0 == 0 {
                    file_info.file_attributes |= FILE_ATTRIBUTE_DIRECTORY.0;
                }
                file_info.file_size = meta.len();
                file_info.allocation_size = (meta.len() + 4095) & !4095;
                file_info.creation_time = meta.creation_time();
                file_info.last_access_time = meta.last_access_time();
                file_info.last_write_time = meta.last_write_time();
                file_info.change_time = meta.last_write_time();
                true
            } else {
                false
            }
        }

        fn new_handle(path: PathBuf, is_dir: bool, file: Option<File>) -> Arc<FileHandle> {
            Arc::new(FileHandle { path, is_dir, file: Mutex::new(file), dir_buffer: DirBuffer::new() })
        }
    }

    impl FileSystemContext for AlienVfsContext {
        type FileContext = Arc<FileHandle>;

        fn get_security_by_name(
            &self,
            file_name: &U16CStr,
            _security_descriptor: Option<&mut [c_void]>,
            _reparse_point_resolver: impl FnOnce(&U16CStr) -> Option<FileSecurity>,
        ) -> winfsp::Result<FileSecurity> {
            if Self::is_denied_user_path(file_name) {
                return Err(std::io::Error::from(std::io::ErrorKind::PermissionDenied).into());
            }
            let path = self.to_backing_path(file_name);
            if path.exists() {
                let attrs = fs::metadata(&path).map(|m| m.file_attributes()).unwrap_or(0);
                Ok(FileSecurity { reparse: false, sz_security_descriptor: 0, attributes: attrs })
            } else {
                Err(std::io::Error::from(std::io::ErrorKind::NotFound).into())
            }
        }

        fn open(
            &self,
            file_name: &U16CStr,
            _create_options: u32,
            _granted_access: u32,
            file_info: &mut OpenFileInfo,
        ) -> winfsp::Result<Self::FileContext> {
            if Self::is_denied_user_path(file_name) {
                return Err(std::io::Error::from(std::io::ErrorKind::PermissionDenied).into());
            }
            let path = self.to_backing_path(file_name);
            if !path.exists() {
                return Err(std::io::Error::from(std::io::ErrorKind::NotFound).into());
            }
            let is_dir = path.is_dir();
            self.fill_file_info(&path, file_info.as_mut());
            let file = if !is_dir {
                fs::OpenOptions::new().read(true).write(true).open(&path).ok()
            } else {
                None
            };
            Ok(Self::new_handle(path, is_dir, file))
        }

        fn create(
            &self,
            file_name: &U16CStr,
            create_options: u32,
            _granted_access: FILE_ACCESS_RIGHTS,
            _file_attributes: FILE_FLAGS_AND_ATTRIBUTES,
            _security_descriptor: Option<&[c_void]>,
            _allocation_size: u64,
            _extra_buffer: Option<&[u8]>,
            _extra_buffer_is_reparse_point: bool,
            file_info: &mut OpenFileInfo,
        ) -> winfsp::Result<Self::FileContext> {
            if Self::is_denied_user_path(file_name) {
                return Err(std::io::Error::from(std::io::ErrorKind::PermissionDenied).into());
            }
            let path = self.to_backing_path(file_name);
            let is_dir = (create_options & 0x00000001) != 0;
            if is_dir {
                fs::create_dir_all(&path)?;
                self.fill_file_info(&path, file_info.as_mut());
                Ok(Self::new_handle(path, true, None))
            } else {
                if let Some(parent) = path.parent() {
                    let _ = fs::create_dir_all(parent);
                }
                let file = fs::OpenOptions::new().read(true).write(true).create(true).truncate(true).open(&path)?;
                self.fill_file_info(&path, file_info.as_mut());
                Ok(Self::new_handle(path, false, Some(file)))
            }
        }

        fn overwrite(
            &self,
            context: &Self::FileContext,
            _file_attributes: FILE_FLAGS_AND_ATTRIBUTES,
            _replace_file_attributes: bool,
            _allocation_size: u64,
            _extra_buffer: Option<&[u8]>,
            file_info: &mut FileInfo,
        ) -> winfsp::Result<()> {
            let mut file = context.file.lock().unwrap();
            if let Some(ref mut f) = *file {
                f.set_len(0)?;
                self.fill_file_info(&context.path, file_info);
                Ok(())
            } else {
                Err(std::io::Error::from(std::io::ErrorKind::InvalidInput).into())
            }
        }

        fn cleanup(&self, context: &Self::FileContext, _file_name: Option<&U16CStr>, _flags: u32) {
            let mut file = context.file.lock().unwrap();
            *file = None;
        }

        fn close(&self, _context: Self::FileContext) {}

        fn get_file_info(&self, context: &Self::FileContext, file_info: &mut FileInfo) -> winfsp::Result<()> {
            if self.fill_file_info(&context.path, file_info) { Ok(()) } else { Err(std::io::Error::from(std::io::ErrorKind::NotFound).into()) }
        }

        fn read(&self, context: &Self::FileContext, buffer: &mut [u8], offset: u64) -> winfsp::Result<u32> {
            let mut file = context.file.lock().unwrap();
            if let Some(ref mut f) = *file {
                let _ = f.seek(SeekFrom::Start(offset));
                Ok(f.read(buffer)? as u32)
            } else {
                Err(std::io::Error::from(std::io::ErrorKind::InvalidInput).into())
            }
        }

        fn write(
            &self,
            context: &Self::FileContext,
            buffer: &[u8],
            offset: u64,
            _write_to_end_of_file: bool,
            _constrained_io: bool,
            file_info: &mut FileInfo,
        ) -> winfsp::Result<u32> {
            let mut file = context.file.lock().unwrap();
            if let Some(ref mut f) = *file {
                let _ = f.seek(SeekFrom::Start(offset));
                f.write_all(buffer)?;
                self.fill_file_info(&context.path, file_info);
                Ok(buffer.len() as u32)
            } else {
                Err(std::io::Error::from(std::io::ErrorKind::InvalidInput).into())
            }
        }

        fn read_directory(
            &self,
            context: &Self::FileContext,
            _pattern: Option<&U16CStr>,
            marker: DirMarker,
            buffer: &mut [u8],
        ) -> winfsp::Result<u32> {
            if !context.is_dir {
                return Err(std::io::Error::from(std::io::ErrorKind::InvalidInput).into());
            }
            // Fill the DirBuffer only on the first page (marker == None).
            // Refilling on continuation pages appends duplicate entries and breaks Explorer.
            if marker.is_none() {
                if let Ok(lock) = context.dir_buffer.acquire(true, Some(4096)) {
                    let mut dir_info = DirInfo::<255>::new();
                    let mut paths: Vec<PathBuf> = fs::read_dir(&context.path)
                        .map(|rd| rd.flatten().map(|e| e.path()).collect())
                        .unwrap_or_default();
                    paths.sort_by(|a, b| {
                        let an = a.file_name().map(|s| s.to_string_lossy().to_ascii_lowercase()).unwrap_or_default();
                        let bn = b.file_name().map(|s| s.to_string_lossy().to_ascii_lowercase()).unwrap_or_default();
                        an.cmp(&bn)
                    });
                    for path in paths {
                        let rel = path.strip_prefix(&self.backing_dir).unwrap_or(&path);
                        if VfsDriveManager::is_internal_path(rel) {
                            continue;
                        }
                        let name = path.file_name().unwrap_or_default();
                        let mut fi = FileInfo::default();
                        if !self.fill_file_info(&path, &mut fi) {
                            continue;
                        }
                        dir_info.reset();
                        *dir_info.file_info_mut() = fi;
                        if dir_info.set_name(name).is_err() {
                            continue;
                        }
                        if lock.write(&mut dir_info).is_err() {
                            break;
                        }
                    }
                }
            }
            Ok(context.dir_buffer.read(marker, buffer))
        }

        fn get_volume_info(&self, out_volume_info: &mut VolumeInfo) -> winfsp::Result<()> {
            out_volume_info.total_size = self.quota_total;
            out_volume_info.free_size = self.quota_total.saturating_sub(self.quota_used);
            out_volume_info.set_volume_label("Alien AI");
            Ok(())
        }
    }

    pub fn start_winfsp_volume(
        drive_letter: &str,
        backing_dir: PathBuf,
        quota_total: u64,
        quota_used: u64,
    ) -> anyhow::Result<FileSystemHost<AlienVfsContext, FineGuard>> {
        let clean_drive = drive_letter.trim_end_matches('\\');
        let context = AlienVfsContext::new(backing_dir, quota_total, quota_used);
        let mut volume_params = VolumeParams::new();
        volume_params.sector_size(4096);
        volume_params.sectors_per_allocation_unit(1);
        volume_params.filesystem_name("AlienVFS");
        volume_params.case_preserved_names(true);
        volume_params.unicode_on_disk(true);
        volume_params.persistent_acls(true);
        volume_params.post_cleanup_when_modified_only(true);
        volume_params.pass_query_directory_pattern(true);
        volume_params.flush_and_purge_on_cleanup(true);
        volume_params.file_info_timeout(1000);
        let mut host: FileSystemHost<AlienVfsContext, FineGuard> = FileSystemHost::new(volume_params, context)?;
        let _ = std::process::Command::new("subst").args([clean_drive, "/d"]).status();
        info!("Mounting WinFsp virtual volume to {clean_drive} ...");
        host.mount(clean_drive)?;
        host.start()?;
        info!(
            "Alien AI ({clean_drive}) mounted via WinFsp — {} GB total, {} GB free",
            quota_total / (1024 * 1024 * 1024),
            quota_total.saturating_sub(quota_used) / (1024 * 1024 * 1024)
        );
        Ok(host)
    }
}

#[cfg(target_os = "windows")]
pub use win_impl::*;
