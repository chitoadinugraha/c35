mod quota;
mod store;

pub use quota::{
    drive_storage_limit_bytes, drive_storage_limit_bytes_from_plan_slug, DriveQuotaExceeded,
};
pub use store::{
    drive_changes_list, drive_file_delete, drive_file_put, drive_normalize_path,
    drive_path_updated_ts_ms, drive_storage_snapshot, drive_storage_used_bytes, drive_sync_cursor_ms,
    drive_tree_list, DriveChangeEntry, DriveChangesPage, DriveFileEntry, DriveFileOpResponse,
    DrivePutError, DriveStorageSnapshot, DriveUploadResponse,
};

/// Agent WS + NATS payload to wake drive sync on paired devices.
pub fn drive_sync_nudge_bytes(since_ms: i64) -> Vec<u8> {
    format!("c35.drive:{{\"since_ms\":{}}}", since_ms.max(0)).into_bytes()
}

pub fn drive_sync_nats_subject(owner_iid: i64) -> String {
    format!("c35.user.{owner_iid}.drive-sync")
}
