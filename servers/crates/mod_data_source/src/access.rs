//! Per-binding read vs write (Google Sheets tools).

use serde_json::Value;

use crate::config::SOURCE_KIND_GOOGLE_SHEET;
use crate::store::DataSourceRow;

pub const ACCESS_MODE_READ_WRITE: &str = "read_write";
pub const ACCESS_MODE_READ_ONLY: &str = "read_only";

pub fn config_access_mode(config: &Value) -> &str {
    config
        .get("access_mode")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or(ACCESS_MODE_READ_WRITE)
}

pub fn config_write_allowed(config: &Value) -> bool {
    config_access_mode(config) != ACCESS_MODE_READ_ONLY
}

pub fn config_normalize_access_mode(config: &mut Value, source_kind: &str) {
    let mode = match source_kind {
        SOURCE_KIND_GOOGLE_SHEET => {
            if config_write_allowed(config) {
                ACCESS_MODE_READ_WRITE
            } else {
                ACCESS_MODE_READ_ONLY
            }
        }
        _ => ACCESS_MODE_READ_ONLY,
    };
    if let Some(obj) = config.as_object_mut() {
        obj.insert("access_mode".into(), Value::String(mode.into()));
    }
}

pub fn data_source_bot_gsheet_write_allowed(rows: &[DataSourceRow]) -> bool {
    rows.iter()
        .filter(|r| r.source_kind == SOURCE_KIND_GOOGLE_SHEET)
        .any(|r| config_write_allowed(&r.config))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn access_mode_defaults_read_write() {
        assert!(config_write_allowed(&json!({})));
    }

    #[test]
    fn access_mode_read_only() {
        assert!(!config_write_allowed(&json!({"access_mode": "read_only"})));
    }
}
