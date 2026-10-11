use c35_proto::SiteQueryRow;
use serde_json::{json, Value};

pub fn site_query_llm_compact(query_id: &str, rows: &[SiteQueryRow], result_json: &str) -> Value {
    let sites: Vec<Value> = rows
        .iter()
        .map(|r| {
            json!({
                "site_iid": r.site_iid,
                "site_name": r.site_name,
                "cells": r.cells,
            })
        })
        .collect();
    let meta = serde_json::from_str::<Value>(result_json).unwrap_or(json!({}));
    json!({
        "query_id": query_id,
        "sites": sites,
        "meta": meta,
    })
}
