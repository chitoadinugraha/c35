mod access;
mod bg;
mod chunk;
mod config;
mod csv;
mod google_asset_check;
mod google_sheet;
mod google_url;
mod prompt;
mod retrieve;
mod store;
mod store_due;
mod sync;

pub use access::{
    config_access_mode, config_normalize_access_mode, config_write_allowed, data_source_bot_gsheet_write_allowed,
    ACCESS_MODE_READ_ONLY, ACCESS_MODE_READ_WRITE,
};
pub use chunk::{chunk_content_hash, snapshot_hash, sheet_csv_chunk_rows, ChunkSpec};
pub use config::{
    data_source_bg_batch, data_source_bg_enabled, data_source_bg_max_concurrent, data_source_bg_tick_sec,
    data_source_retrieve_limit, data_source_retrieve_timeout, data_source_sync_ttl_sec, SOURCE_KIND_GOOGLE_SHEET,
    DATA_SOURCE_SMALL_ROW_LIMIT,
};
pub use csv::{parse_csv, parse_csv_line};
pub use google_asset_check::{data_source_check_run, AssetCheckResult, SheetTabInfo};
pub use google_sheet::{
    config_merge_sheet_url, google_sheet_config_from_row, google_sheet_metadata, google_sheet_read_csv,
    google_sheet_write_append, google_sheet_write_update, parse_sheet_url, sheet_tab_name, GoogleSheetConfig,
    ParsedSheetUrl,
};
pub use google_url::{
    config_merge_doc_url, config_merge_slide_url, SOURCE_KIND_GOOGLE_DOC, SOURCE_KIND_GOOGLE_SLIDE,
};
pub use prompt::{data_source_prompt_for_bot, data_source_prompt_merge};
pub use retrieve::data_source_chunk_retrieve;
pub use store::{
    chunk_candidates_fts, chunk_candidates_recent, chunks_delete_for_source, chunks_full_text, data_source_get,
    data_source_list_for_bot, data_source_put, data_source_soft_delete, sync_invalidate_row,
    sync_row_get, sync_row_count, sync_touch, sync_upsert_error, sync_upsert_ok, DataSourceRow, DataSourceSyncRow,
};
pub use bg::data_source_bg_spawn;
pub use store_due::sync_due_claim_batch;
pub use sync::{data_source_sync_if_stale, data_source_sync_invalidate, data_source_sync_run};
