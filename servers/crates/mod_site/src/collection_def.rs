use c35_proto::{
    ColDef, ColType, ReqCollectionDefList, ResCollectionDefList, SubTableDef, TableDef,
};
use sqlx::PgPool;

fn col(key: &str, label: &str, col_type: ColType, readonly: bool) -> ColDef {
    ColDef {
        key: key.into(),
        label: label.into(),
        r#type: col_type as i32,
        readonly,
        required: false,
        ref_collection: String::new(),
        inline_editable: !readonly,
    }
}

fn col_req(key: &str, label: &str, col_type: ColType) -> ColDef {
    let mut c = col(key, label, col_type, false);
    c.required = true;
    c
}

fn col_ref(key: &str, label: &str, ref_collection: &str) -> ColDef {
    ColDef {
        key: key.into(),
        label: label.into(),
        r#type: ColType::Ref as i32,
        readonly: false,
        required: false,
        ref_collection: ref_collection.into(),
        inline_editable: true,
    }
}

fn product_table() -> TableDef {
    TableDef {
        collection: "site.product".into(),
        label: "Products".into(),
        columns: vec![
            col_req("product_id", "ID", ColType::Int),
            col_req("name", "Name", ColType::Text),
            col("desc", "Description", ColType::Text, false),
            col("sku", "SKU", ColType::Text, false),
            col("unit", "Unit", ColType::Text, false),
            col("price", "Price", ColType::Money, false),
            col("pic", "Image", ColType::Pic, false),
            col("category", "Category", ColType::Text, false),
            col("stock_qty", "Stock", ColType::Int, false),
            col("can_sell", "Sell", ColType::Bool, false),
            col("can_reserve", "Reserve", ColType::Bool, false),
            col("track_stock", "Track stock", ColType::Bool, false),
            col("is_archived", "Archived", ColType::Bool, false),
            col("product_json", "Extra", ColType::Json, false),
            col("updated_ts_ms", "Updated", ColType::Ts, true),
        ],
        subtables: vec![SubTableDef {
            collection: "site.product_embed".into(),
            label: "Alt labels".into(),
            fk_keys: vec!["site_iid".into(), "product_id".into()],
            sync_name: "site_product_embed".into(),
        }],
        sync_name: "site_product".into(),
        site_scoped: true,
        primary_key: "site_iid,product_id".into(),
    }
}

fn contact_table() -> TableDef {
    TableDef {
        collection: "site.contact".into(),
        label: "Contacts".into(),
        columns: vec![
            col_req("contact_id", "ID", ColType::Int),
            col_req("name", "Name", ColType::Text),
            col("phone", "Phone", ColType::Text, false),
            col("email", "Email", ColType::Text, false),
            col("address", "Address", ColType::Text, false),
            col("note", "Note", ColType::Text, false),
            col("meta_json", "Meta", ColType::Json, false),
            col("is_archived", "Archived", ColType::Bool, false),
            col("updated_ts_ms", "Updated", ColType::Ts, true),
        ],
        subtables: vec![],
        sync_name: "site_contact".into(),
        site_scoped: true,
        primary_key: "site_iid,contact_id".into(),
    }
}

fn object_table() -> TableDef {
    TableDef {
        collection: "site.object".into(),
        label: "Objects".into(),
        columns: vec![
            col_req("id", "ID", ColType::Int),
            col("client_id", "Client ID", ColType::Text, false),
            col_req("name", "Name", ColType::Text),
            col("code", "Code", ColType::Text, false),
            col("kind", "Kind", ColType::Text, false),
            col_ref("product_id", "Product", "site.product"),
            col("can_order", "Order", ColType::Bool, false),
            col("can_be_reserved", "Reserve", ColType::Bool, false),
            col("is_active", "Active", ColType::Bool, false),
            col("desc", "Description", ColType::Text, false),
            col("pic", "Image", ColType::Pic, false),
            col("meta_json", "Meta", ColType::Json, false),
            col("updated_ts_ms", "Updated", ColType::Ts, true),
        ],
        subtables: vec![],
        sync_name: "site_object".into(),
        site_scoped: true,
        primary_key: "site_iid,id".into(),
    }
}

fn domain_table() -> TableDef {
    TableDef {
        collection: "site.domain".into(),
        label: "Domains".into(),
        columns: vec![
            col_req("id", "ID", ColType::Int),
            col_req("hostname", "Hostname", ColType::Text),
            col("is_primary", "Primary", ColType::Bool, false),
            col("tls_status", "TLS", ColType::Text, true),
            col("verified_ts_ms", "Verified", ColType::Ts, true),
            col("updated_ts_ms", "Updated", ColType::Ts, true),
        ],
        subtables: vec![],
        sync_name: "site_domain".into(),
        site_scoped: true,
        primary_key: "site_iid,id".into(),
    }
}

fn all_tables() -> Vec<TableDef> {
    vec![product_table(), contact_table(), object_table(), domain_table()]
}

async fn site_capabilities(pool: &PgPool, site_iid: i64) -> serde_json::Value {
    sqlx::query_scalar::<_, serde_json::Value>(
        "SELECT capabilities_json FROM site.config WHERE site_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await
    .ok()
    .flatten()
    .unwrap_or_else(|| serde_json::json!({}))
}

fn capability_enabled(caps: &serde_json::Value, key: &str) -> bool {
    caps.get(key).and_then(|v| v.as_bool()).unwrap_or(true)
}

fn filter_by_capabilities(tables: Vec<TableDef>, caps: &serde_json::Value) -> Vec<TableDef> {
    tables
        .into_iter()
        .filter(|t| match t.collection.as_str() {
            "site.product" => capability_enabled(caps, "commerce"),
            "site.object" => capability_enabled(caps, "booking"),
            _ => true,
        })
        .collect()
}

pub fn collection_def_list_static(req: ReqCollectionDefList) -> ResCollectionDefList {
    let tables = if req.site_iid > 0 {
        all_tables()
    } else {
        all_tables()
    };
    ResCollectionDefList { tables }
}

pub async fn collection_def_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqCollectionDefList,
) -> ResCollectionDefList {
    collection_def_list_rpc(pool, caller_iid, req).await
}

pub async fn collection_def_list_rpc(
    pool: &PgPool,
    _caller_iid: i64,
    req: ReqCollectionDefList,
) -> ResCollectionDefList {
    if req.site_iid <= 0 {
        return collection_def_list_static(req);
    }
    let caps = site_capabilities(pool, req.site_iid).await;
    ResCollectionDefList {
        tables: filter_by_capabilities(all_tables(), &caps),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn collection_def_list_has_four_tables() {
        let res = collection_def_list_static(ReqCollectionDefList { site_iid: 0 });
        assert_eq!(res.tables.len(), 4);
        let collections: Vec<&str> = res.tables.iter().map(|t| t.collection.as_str()).collect();
        assert!(collections.contains(&"site.product"));
        assert!(collections.contains(&"site.contact"));
        assert!(collections.contains(&"site.object"));
        assert!(collections.contains(&"site.domain"));
    }

    #[test]
    fn product_table_has_embed_subtable() {
        let res = collection_def_list_static(ReqCollectionDefList { site_iid: 0 });
        let product = res
            .tables
            .iter()
            .find(|t| t.collection == "site.product")
            .expect("site.product");
        assert_eq!(product.sync_name, "site_product");
        assert_eq!(product.subtables.len(), 1);
        assert_eq!(product.subtables[0].collection, "site.product_embed");
        assert_eq!(product.subtables[0].sync_name, "site_product_embed");
        assert!(product.subtables[0].fk_keys.contains(&"product_id".to_string()));
    }

    #[test]
    fn product_columns_include_money_and_pic() {
        let res = collection_def_list_static(ReqCollectionDefList { site_iid: 0 });
        let product = res.tables.iter().find(|t| t.collection == "site.product").unwrap();
        let price = product.columns.iter().find(|c| c.key == "price").unwrap();
        assert_eq!(price.r#type, ColType::Money as i32);
        let pic = product.columns.iter().find(|c| c.key == "pic").unwrap();
        assert_eq!(pic.r#type, ColType::Pic as i32);
    }
}
