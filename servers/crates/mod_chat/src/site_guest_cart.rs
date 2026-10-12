//! Server-side guest cart session (keyed by site_iid + visitor_id).

use std::sync::OnceLock;

use dashmap::DashMap;
use serde_json::{json, Value};

const MAX_LINES: usize = 64;

fn cart_store() -> &'static DashMap<String, Value> {
    static STORE: OnceLock<DashMap<String, Value>> = OnceLock::new();
    STORE.get_or_init(DashMap::new)
}

pub fn cart_session_key(site_iid: i64, visitor_id: &str) -> String {
    format!("{}:{}", site_iid, visitor_id.trim())
}

pub fn guest_cart_get(site_iid: i64, visitor_id: &str) -> Value {
    let key = cart_session_key(site_iid, visitor_id);
    cart_store()
        .get(&key)
        .map(|v| v.clone())
        .unwrap_or_else(|| json!({ "lines": [] }))
}

pub fn guest_cart_patch(site_iid: i64, visitor_id: &str, patch: &Value) -> Value {
    let key = cart_session_key(site_iid, visitor_id);
    let merge = patch.get("merge").and_then(|v| v.as_bool()).unwrap_or(false);
    let incoming = patch
        .get("lines")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    let mut lines: Vec<Value> = if merge {
        guest_cart_get(site_iid, visitor_id)
            .get("lines")
            .and_then(|v| v.as_array())
            .cloned()
            .unwrap_or_default()
    } else {
        Vec::new()
    };
    for line in incoming {
        if lines.len() >= MAX_LINES {
            break;
        }
        lines.push(line);
    }
    let cart = json!({ "lines": lines });
    cart_store().insert(key, cart.clone());
    cart
}

pub async fn guest_cart_get_exec(site_iid: i64, visitor_id: &str) -> Result<Value, String> {
    if site_iid <= 0 {
        return Err("site_iid required".into());
    }
    if visitor_id.trim().is_empty() {
        return Err("visitor_id required".into());
    }
    Ok(guest_cart_get(site_iid, visitor_id))
}

pub async fn guest_cart_patch_exec(
    site_iid: i64,
    visitor_id: &str,
    args: &Value,
) -> Result<Value, String> {
    if site_iid <= 0 {
        return Err("site_iid required".into());
    }
    if visitor_id.trim().is_empty() {
        return Err("visitor_id required".into());
    }
    Ok(guest_cart_patch(site_iid, visitor_id, args))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn guest_cart_patch_replaces_by_default() {
        let site = 99001_i64;
        let visitor = "v-test-replace";
        guest_cart_patch(
            site,
            visitor,
            &json!({ "lines": [{ "product_id": 1, "qty": 2 }] }),
        );
        let cart = guest_cart_patch(
            site,
            visitor,
            &json!({ "lines": [{ "product_id": 3, "qty": 1 }] }),
        );
        let lines = cart.get("lines").and_then(|v| v.as_array()).unwrap();
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0].get("product_id").and_then(|v| v.as_i64()), Some(3));
    }

    #[test]
    fn guest_cart_patch_merge_appends() {
        let site = 99002_i64;
        let visitor = "v-test-merge";
        guest_cart_patch(
            site,
            visitor,
            &json!({ "lines": [{ "product_id": 1, "qty": 1 }] }),
        );
        let cart = guest_cart_patch(
            site,
            visitor,
            &json!({
                "merge": true,
                "lines": [{ "product_id": 2, "qty": 1 }]
            }),
        );
        let lines = cart.get("lines").and_then(|v| v.as_array()).unwrap();
        assert_eq!(lines.len(), 2);
    }
}
