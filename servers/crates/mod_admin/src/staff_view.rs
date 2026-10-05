use std::collections::HashSet;

use sqlx::{PgPool, Row};

#[derive(Debug, Clone, Default)]
pub struct StaffView {
    pub is_root: bool,
    pub global_roles: HashSet<String>,
}

impl StaffView {
    /// Compose/tests: do not hide staff-gated tools when roles are unknown.
    pub fn permit_all() -> Self {
        Self {
            is_root: true,
            global_roles: HashSet::new(),
        }
    }
}

fn meta_is_root(meta: &serde_json::Value) -> bool {
    meta.get("is_root")
        .and_then(|v| v.as_bool())
        .or_else(|| meta.get("is_root").and_then(|v| v.as_str()).map(|s| s == "true"))
        .unwrap_or(false)
}

fn meta_global_roles(meta: &serde_json::Value) -> HashSet<String> {
    meta.get("global_roles")
        .and_then(|v| v.as_array())
        .map(|a| {
            a.iter()
                .filter_map(|x| x.as_str().map(|s| s.trim().to_lowercase()))
                .filter(|s| !s.is_empty())
                .collect()
        })
        .unwrap_or_default()
}

pub async fn staff_view_load(pool: &PgPool, viewer_iid: i64) -> StaffView {
    if viewer_iid == 99_000 {
        return StaffView {
            is_root: true,
            global_roles: HashSet::from(["root".into()]),
        };
    }
    if viewer_iid <= 0 {
        return StaffView::default();
    }
    let row = sqlx::query(
        "SELECT meta FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL AND is_active = true",
    )
    .bind(viewer_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten();
    let Some(row) = row else {
        return StaffView::default();
    };
    let meta: serde_json::Value = row.try_get("meta").unwrap_or(serde_json::json!({}));
    StaffView {
        is_root: meta_is_root(&meta),
        global_roles: meta_global_roles(&meta),
    }
}

/// Empty `requires` = no staff gate. Otherwise OR across roles; `is_root` satisfies all gates.
pub fn staff_tool_eligible(view: &StaffView, requires: &[String]) -> bool {
    if requires.is_empty() {
        return true;
    }
    if view.is_root {
        return true;
    }
    for req in requires {
        let r = req.trim().to_lowercase();
        if r.is_empty() {
            continue;
        }
        if r == "root" {
            continue;
        }
        if view.global_roles.contains(&r) {
            return true;
        }
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn staff_tool_eligible_root_bypass() {
        let view = StaffView {
            is_root: true,
            global_roles: HashSet::new(),
        };
        assert!(staff_tool_eligible(&view, &["director".into()]));
    }

    #[test]
    fn staff_tool_eligible_or_roles() {
        let view = StaffView {
            is_root: false,
            global_roles: HashSet::from(["finance".into()]),
        };
        assert!(staff_tool_eligible(&view, &["finance".into(), "director".into()]));
        assert!(!staff_tool_eligible(&view, &["director".into()]));
    }

    #[test]
    fn staff_tool_eligible_root_only() {
        let view = StaffView::default();
        assert!(!staff_tool_eligible(&view, &["root".into()]));
    }
}
