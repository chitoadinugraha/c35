use super::{query_def_get, query_def_list};

const SEED_QUERY_IDS: &[&str] = &[
    "product.list",
    "product.stock_status",
    "product.stock",
    "tx.sales_summary",
    "tx.profit_summary",
    "tx.top_products",
    "tx.product_compare",
];

#[test]
fn query_registry_has_seed_queries() {
    for id in SEED_QUERY_IDS {
        let def = query_def_get(id).unwrap_or_else(|| panic!("{id} registered"));
        assert_eq!(def.id(), *id);
        assert!(def.site_scoped());
    }
}

#[test]
fn query_registry_unknown_id() {
    assert!(query_def_get("tx.unknown").is_none());
}

#[test]
fn query_def_list_includes_seed_queries() {
    let ids: Vec<_> = query_def_list().into_iter().map(|(id, _)| id).collect();
    for id in SEED_QUERY_IDS {
        assert!(ids.contains(id), "missing {id}");
    }
    assert_eq!(ids.len(), SEED_QUERY_IDS.len());
}

#[test]
fn query_registry_labels_non_empty() {
    for (id, label) in query_def_list() {
        assert!(!label.is_empty(), "empty label for {id}");
    }
}
