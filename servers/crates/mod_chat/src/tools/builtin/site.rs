use anyhow::{anyhow, bail, Result};
use c35_mod_site::{
    product_icon_ensure, site_capabilities_get, site_config_put, site_contact_upsert,
    site_grant_delete, site_grant_put, site_grantee_resolve, site_granted_iids, site_handle_put,
    site_link_delete, site_link_upsert, site_object_upsert, site_preview_token_issue,
    site_publish_from_draft, site_slug_ensure_unique, site_slug_generate,
};
use c35_proto::{ReqSiteConfigPut, ReqSiteHandlePut, ReqSiteLinkDelete, SiteContact, SiteLink, SiteObject};
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::{Postgres, Row, Transaction};

use crate::mention_context::{json_device_iid_field, site_iid_resolve as mention_site_iid_resolve};
use crate::site_product_match::{product_match_classify, ProductHit, ProductMatch};
use crate::site_resolve::site_grant_owner;
use crate::site_scope::site_scope_pick;
use crate::site_validate::validate_sitedoc;
use crate::tool;
use crate::tools::ToolContext;

fn site_iid_resolve(ctx: &ToolContext, args: &Value) -> Result<i64> {
    let args_site = json_device_iid_field(args, "site_iid");
    mention_site_iid_resolve(
        &ctx.mention,
        ctx.site_iid,
        (args_site > 0).then_some(args_site),
    )
}

fn doc_json_parse(args: &Value) -> Result<Value> {
    if let Some(raw) = args.get("doc_json").and_then(|v| v.as_str()) {
        return serde_json::from_str(raw).map_err(|e| anyhow!("invalid doc_json: {e}"));
    }
    if let Some(doc) = args.get("doc") {
        return Ok(doc.clone());
    }
    Err(anyhow!("doc_json or doc is required"))
}

pub async fn site_draft_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let doc = doc_json_parse(args)?;
    validate_sitedoc(&doc)?;
    let doc_str = serde_json::to_string(&doc)?;
    sqlx::query(
        r#"
        INSERT INTO site.draft (site_iid, owner_iid, doc_json, created_ts, updated_ts)
        VALUES ($1, $2, $3::jsonb, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
            doc_json = EXCLUDED.doc_json,
            owner_iid = EXCLUDED.owner_iid,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(&doc_str)
    .execute(&ctx.pool)
    .await?;
    Ok(json!({ "ok": true, "site_iid": site_iid }))
}

const SITE_CAPABILITY_KEYS: &[&str] = &["commerce", "booking", "queue", "attendance"];

fn site_capabilities_merge(args: &Value, existing: Value) -> Result<Value> {
    let mut caps = if existing.as_object().is_some() {
        existing
    } else {
        json!({})
    };
    let obj = caps
        .as_object_mut()
        .ok_or_else(|| anyhow!("capabilities_json must be an object"))?;
    let mut touched = false;
    if let Some(patch) = args.get("capabilities_json") {
        let patch_obj = patch
            .as_object()
            .ok_or_else(|| anyhow!("capabilities_json must be an object"))?;
        for (k, v) in patch_obj {
            obj.insert(k.clone(), v.clone());
        }
        touched = true;
    }
    for key in SITE_CAPABILITY_KEYS {
        if let Some(v) = args.get(*key).and_then(|v| v.as_bool()) {
            obj.insert(key.to_string(), json!(v));
            touched = true;
        }
    }
    if !touched {
        bail!(
            "capabilities_json or at least one of commerce, booking, queue, attendance is required"
        );
    }
    Ok(caps)
}

pub async fn site_config_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let existing = site_capabilities_get(&ctx.pool, site_iid).await;
    let caps = site_capabilities_merge(args, existing)?;
    let caps_str = serde_json::to_string(&caps)?;
    let res = site_config_put(
        &ctx.pool,
        ctx.owner_iid,
        ReqSiteConfigPut {
            site_iid,
            capabilities_json: caps_str,
        },
        None,
    )
    .await?;
    let config = res
        .config
        .ok_or_else(|| anyhow!("site.config.put returned no config"))?;
    let saved: Value = serde_json::from_str(&config.capabilities_json)
        .unwrap_or_else(|_| json!({}));
    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "capabilities_json": saved,
        "message": "Site capabilities updated"
    }))
}

pub async fn site_publish_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let draft_row = sqlx::query_scalar::<_, Value>(
        "SELECT doc_json FROM site.draft WHERE site_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(&ctx.pool)
    .await?
    .ok_or_else(|| anyhow!("no draft for site"))?;
    validate_sitedoc(&draft_row)?;
    let result = site_publish_from_draft(&ctx.pool, ctx.owner_iid, site_iid).await?;
    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "version_id": result.version_id,
        "render_hash": result.render_hash,
    }))
}

async fn product_embed_put_tx(
    tx: &mut Transaction<'_, Postgres>,
    site_iid: i64,
    product_id: i64,
    embeds: &[Value],
) -> Result<()> {
    for embed in embeds {
        let embed_id = embed
            .get("embed_id")
            .and_then(|v| v.as_i64())
            .filter(|i| *i > 0)
            .unwrap_or_else(snowflake_id);
        let label = embed.get("label").and_then(|v| v.as_str()).unwrap_or("").trim();
        sqlx::query(
            r#"
            INSERT INTO site.product_embed (site_iid, embed_id, product_id, label, created_ts, updated_ts)
            VALUES ($1, $2, $3, $4, NOW(), NOW())
            ON CONFLICT (site_iid, embed_id) DO UPDATE SET
                product_id = EXCLUDED.product_id,
                label = EXCLUDED.label,
                updated_ts = NOW(),
                deleted_ts = NULL
            "#,
        )
        .bind(site_iid)
        .bind(embed_id)
        .bind(product_id)
        .bind(label)
        .execute(&mut **tx)
        .await?;
    }
    Ok(())
}

pub async fn site_product_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let product_id = args
        .get("product_id")
        .and_then(|v| v.as_i64())
        .filter(|i| *i > 0)
        .unwrap_or_else(snowflake_id);
    let name = args.get("name").and_then(|v| v.as_str()).unwrap_or("").trim();
    if name.is_empty() {
        bail!("name is required");
    }
    let desc = args.get("desc").and_then(|v| v.as_str()).unwrap_or("");
    let unit = args.get("unit").and_then(|v| v.as_str()).unwrap_or("");
    let sku = args.get("sku").and_then(|v| v.as_str()).unwrap_or("");
    let price = args.get("price").and_then(|v| v.as_i64()).unwrap_or(0);
    let pic = args.get("pic").and_then(|v| v.as_str()).unwrap_or("");
    let category = args.get("category").and_then(|v| v.as_str()).unwrap_or("");
    let can_sell = args.get("can_sell").and_then(|v| v.as_bool()).unwrap_or(true);
    let track_stock = args.get("track_stock").and_then(|v| v.as_bool()).unwrap_or(false);
    let stock_qty = args.get("stock_qty").and_then(|v| v.as_i64()).unwrap_or(0) as i32;
    let is_archived = args.get("is_archived").and_then(|v| v.as_bool()).unwrap_or(false);
    let product_json = args
        .get("product_json")
        .map(|v| v.to_string())
        .unwrap_or_else(|| "{}".into());
    let search_text = format!("{name} {sku} {category}").trim().to_string();
    let embeds = args
        .get("embeds")
        .and_then(|v| v.as_array())
        .cloned()
        .unwrap_or_default();
    let mut tx = ctx.pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO site.product (
            site_iid, product_id, owner_iid, name, "desc", unit, sku, price, pic, category,
            can_sell, track_stock, stock_qty, is_archived, product_json, search_text,
            created_ts, updated_ts
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15::jsonb, $16, NOW(), NOW())
        ON CONFLICT (site_iid, product_id) DO UPDATE SET
            name = EXCLUDED.name,
            "desc" = EXCLUDED.desc,
            unit = EXCLUDED.unit,
            sku = EXCLUDED.sku,
            price = EXCLUDED.price,
            pic = EXCLUDED.pic,
            category = EXCLUDED.category,
            can_sell = EXCLUDED.can_sell,
            track_stock = EXCLUDED.track_stock,
            stock_qty = EXCLUDED.stock_qty,
            is_archived = EXCLUDED.is_archived,
            product_json = EXCLUDED.product_json,
            search_text = EXCLUDED.search_text,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .bind(owner_iid)
    .bind(name)
    .bind(desc)
    .bind(unit)
    .bind(sku)
    .bind(price)
    .bind(pic)
    .bind(category)
    .bind(can_sell)
    .bind(track_stock)
    .bind(stock_qty)
    .bind(is_archived)
    .bind(&product_json)
    .bind(&search_text)
    .execute(&mut *tx)
    .await?;
    if !embeds.is_empty() {
        product_embed_put_tx(&mut tx, site_iid, product_id, &embeds).await?;
    }
    tx.commit().await?;
    let icon = if pic.trim().is_empty() {
        product_icon_ensure(&ctx.pool, name).await
    } else {
        String::new()
    };
    Ok(json!({ "ok": true, "site_iid": site_iid, "product_id": product_id, "icon": icon }))
}

pub async fn site_contact_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let name = args.get("name").and_then(|v| v.as_str()).unwrap_or("").trim();
    if name.is_empty() {
        bail!("name is required");
    }
    let contact = SiteContact {
        site_iid,
        contact_id: args.get("contact_id").and_then(|v| v.as_i64()).unwrap_or(0),
        name: name.to_string(),
        phone: args.get("phone").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        email: args.get("email").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        address: args.get("address").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        note: args.get("note").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        is_archived: args.get("is_archived").and_then(|v| v.as_bool()).unwrap_or(false),
        ..Default::default()
    };
    let contact_id = site_contact_upsert(&ctx.pool, owner_iid, site_iid, &contact, None).await?;
    Ok(json!({ "ok": true, "site_iid": site_iid, "contact_id": contact_id }))
}

pub async fn site_link_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let label = args.get("label").and_then(|v| v.as_str()).unwrap_or("").trim();
    let url = args.get("url").and_then(|v| v.as_str()).unwrap_or("").trim();
    if label.is_empty() || url.is_empty() {
        bail!("label and url are required");
    }
    let link = SiteLink {
        site_iid,
        link_id: args.get("link_id").and_then(|v| v.as_i64()).unwrap_or(0),
        sort_order: args.get("sort_order").and_then(|v| v.as_i64()).unwrap_or(0) as i32,
        label: label.to_string(),
        url: url.to_string(),
        icon: args.get("icon").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        is_pinned: args.get("is_pinned").and_then(|v| v.as_bool()).unwrap_or(false),
        active: args.get("active").and_then(|v| v.as_bool()).unwrap_or(true),
        ..Default::default()
    };
    let link_id = site_link_upsert(&ctx.pool, owner_iid, site_iid, &link, None).await?;
    Ok(json!({ "ok": true, "site_iid": site_iid, "link_id": link_id }))
}

pub async fn site_link_delete_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let link_id = args
        .get("link_id")
        .and_then(|v| v.as_i64())
        .filter(|i| *i > 0)
        .ok_or_else(|| anyhow!("link_id is required"))?;
    let res = site_link_delete(
        &ctx.pool,
        ctx.owner_iid,
        ReqSiteLinkDelete { site_iid, link_id },
        None,
    )
    .await?;
    Ok(json!({
        "ok": res.ok,
        "deleted": res.ok,
        "site_iid": site_iid,
        "link_id": res.link_id,
    }))
}

pub async fn site_object_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let name = args.get("name").and_then(|v| v.as_str()).unwrap_or("").trim();
    if name.is_empty() {
        bail!("name is required");
    }
    let obj = SiteObject {
        site_iid,
        id: args.get("id").and_then(|v| v.as_i64()).unwrap_or(0),
        client_id: args.get("client_id").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        name: name.to_string(),
        code: args.get("code").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        kind: args.get("kind").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        product_id: args.get("product_id").and_then(|v| v.as_i64()).unwrap_or(0),
        can_order: args.get("can_order").and_then(|v| v.as_bool()).unwrap_or(false),
        can_be_reserved: args.get("can_be_reserved").and_then(|v| v.as_bool()).unwrap_or(false),
        is_active: args.get("is_active").and_then(|v| v.as_bool()).unwrap_or(true),
        desc: args.get("desc").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        pic: args.get("pic").and_then(|v| v.as_str()).unwrap_or("").to_string(),
        ..Default::default()
    };
    let id = site_object_upsert(&ctx.pool, owner_iid, site_iid, &obj, None).await?;
    Ok(json!({ "ok": true, "site_iid": site_iid, "id": id }))
}

fn grantee_iid_from_args(args: &Value) -> i64 {
    match args.get("grantee_iid") {
        Some(Value::String(s)) => s.trim().parse().unwrap_or(0),
        Some(Value::Number(n)) => n.as_i64().unwrap_or(0),
        _ => 0,
    }
}

pub async fn site_grant_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let grantee_iid = site_grantee_resolve(
        &ctx.pool,
        grantee_iid_from_args(args),
        args.get("grantee_alien_id").and_then(|v| v.as_str()).unwrap_or(""),
    )
    .await?;
    let role = args
        .get("role")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("role is required (staff or manage)"))?;
    site_grant_put(&ctx.pool, ctx.owner_iid, site_iid, grantee_iid, role).await?;
    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "grantee_iid": grantee_iid,
        "role": role,
        "message": "Site staff grant updated"
    }))
}

pub async fn site_grant_delete_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let grantee_iid = site_grantee_resolve(
        &ctx.pool,
        grantee_iid_from_args(args),
        args.get("grantee_alien_id").and_then(|v| v.as_str()).unwrap_or(""),
    )
    .await?;
    site_grant_delete(&ctx.pool, ctx.owner_iid, site_iid, grantee_iid).await?;
    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "grantee_iid": grantee_iid,
        "message": "Site staff grant removed"
    }))
}

tool! {
    struct: SiteDraftPutTool,
    name: "site.draft_put",
    aliases: ["site_draft_put"],
    description: "Update a site's draft SiteDoc (pages, blocks, theme). Validates block types and props.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.draft_put.calling",
    ui_done_key: "tool.site.draft_put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        doc_json: (string, "SiteDoc JSON string with pages, theme, meta", optional),
        doc: (object, "SiteDoc object (alternative to doc_json)", optional),
    },
    execute: |args, ctx| {
        site_draft_put_exec(ctx, &args).await
    }
}

tool! {
    struct: SitePublishTool,
    name: "site.publish",
    aliases: ["site_publish"],
    description: "Publish the current site draft — snapshot to site.publish and compile guest HTML.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.publish.calling",
    ui_done_key: "tool.site.publish.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
    },
    execute: |args, ctx| {
        site_publish_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteConfigPutTool,
    name: "site.config.put",
    aliases: ["site_config_put", "site.config_put"],
    description: "Update site.config capabilities_json (enable or disable POS/commerce, booking, queue, attendance). Merges into existing flags when individual booleans are passed.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.config.put.calling",
    ui_done_key: "tool.site.config.put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from active @site when omitted)", optional),
        capabilities_json: (object, "Partial or full capabilities object e.g. {\"commerce\": true, \"booking\": false}", optional),
        commerce: (boolean, "Enable POS / product catalog and transactions (commerce capability)", optional),
        booking: (boolean, "Enable booking / reservations", optional),
        queue: (boolean, "Enable queue / antrian", optional),
        attendance: (boolean, "Enable attendance tracking", optional),
    },
    execute: |args, ctx| {
        site_config_put_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteProductPutTool,
    name: "site.product_put",
    aliases: ["site_product_put"],
    description: "Upsert a product row in site.product catalog (typed fields only — no checkout JSON). When pic is empty, the server assigns the shared default product icon from the product name.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.product_put.calling",
    ui_done_key: "tool.site.product_put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        product_id: (integer, "Existing product ID; omit to create", optional),
        name: (string, "Product name", required),
        desc: (string, "Product description", optional),
        unit: (string, "Unit of measure", optional),
        sku: (string, "SKU", optional),
        price: (integer, "Price in IDR rupiah as an integer. 10000 means Rp 10.000. Pass the scaled amount, not a menu-board shorthand like 10.", optional),
        pic: (string, "Image URL or /fs/{hash}. Omit to use the default product icon from the name.", optional),
        category: (string, "Category label", optional),
        can_sell: (boolean, "Available for sale", optional),
        track_stock: (boolean, "Track inventory", optional),
        stock_qty: (integer, "Stock quantity when track_stock", optional),
        is_archived: (boolean, "Archive product", optional),
        embeds: (array, "Optional product_embed rows [{embed_id, label}]", optional),
    },
    execute: |args, ctx| {
        site_product_put_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteContactPutTool,
    name: "site.contact_put",
    aliases: ["site_contact_put"],
    description: "Upsert a contact row in site.contact CRM table.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.contact_put.calling",
    ui_done_key: "tool.site.contact_put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        contact_id: (integer, "Existing contact ID; omit to create", optional),
        name: (string, "Contact name", required),
        phone: (string, "Phone number", optional),
        email: (string, "Email address", optional),
        address: (string, "Postal address", optional),
        note: (string, "Internal note", optional),
        is_archived: (boolean, "Archive contact", optional),
    },
    execute: |args, ctx| {
        site_contact_put_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteLinkPutTool,
    name: "site.link.put",
    aliases: ["site_link_put"],
    description: "Upsert a hub link row in site.link (label, url, sort order, pin).",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.link.put.calling",
    ui_done_key: "tool.site.link.put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        link_id: (integer, "Existing link ID; omit to create", optional),
        label: (string, "Link label", required),
        url: (string, "Target URL", required),
        icon: (string, "Optional icon (emoji, iconify://, or URL)", optional),
        sort_order: (integer, "Display order (lower first)", optional),
        is_pinned: (boolean, "Pin link in hub", optional),
        active: (boolean, "Show on guest hub when true", optional),
    },
    execute: |args, ctx| {
        site_link_put_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteLinkDeleteTool,
    name: "site.link.delete",
    aliases: ["site_link_delete", "site.link_delete"],
    description: "Soft-delete a hub link row in site.link (sets deleted_ts).",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.link.delete.calling",
    ui_done_key: "tool.site.link.delete.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        link_id: (integer, "Link ID to delete", required),
    },
    execute: |args, ctx| {
        site_link_delete_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteObjectPutTool,
    name: "site.object_put",
    aliases: ["site_object_put"],
    description: "Upsert an object row in site.object (tables, rooms, units).",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.object_put.calling",
    ui_done_key: "tool.site.object_put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        id: (integer, "Existing object ID; omit to create", optional),
        client_id: (string, "Client-side reference id", optional),
        name: (string, "Object name", required),
        code: (string, "Short code", optional),
        kind: (string, "Object kind (table, room, unit, …)", optional),
        product_id: (integer, "Linked product ID", optional),
        can_order: (boolean, "Allow guest orders", optional),
        can_be_reserved: (boolean, "Allow reservations", optional),
        is_active: (boolean, "Active flag", optional),
        desc: (string, "Description", optional),
        pic: (string, "Image URL or /fs/{hash}", optional),
    },
    execute: |args, ctx| {
        site_object_put_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteGrantPutTool,
    name: "site.grant.put",
    aliases: ["site_grant_put", "site.staff.grant"],
    description: "Grant or update site staff access (identity_grant on site_iid). Roles: staff (read/edit data) or manage (includes staff management). Caller must be site owner or manage.",
    topics: ["web.builder"],
    rag_phrases: ["add staff", "invite staff", "site staff", "grant manage", "tambah staff", "akses staff"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.grant.put.calling",
    ui_done_key: "tool.site.grant.put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        grantee_iid: (integer, "User identity ID to grant", optional),
        grantee_alien_id: (string, "User alien_id or numeric id when grantee_iid omitted", optional),
        role: (string, "staff or manage", required),
    },
    execute: |args, ctx| {
        site_grant_put_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteGrantDeleteTool,
    name: "site.grant.delete",
    aliases: ["site_grant_delete"],
    description: "Revoke site staff access for a user (soft-delete identity_grant). Caller must be site owner or manage. Cannot remove the site owner.",
    topics: ["web.builder"],
    rag_phrases: ["remove staff", "revoke access", "hapus staff", "cabut akses"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.grant.delete.calling",
    ui_done_key: "tool.site.grant.delete.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        grantee_iid: (integer, "User identity ID to revoke", optional),
        grantee_alien_id: (string, "User alien_id or numeric id when grantee_iid omitted", optional),
    },
    execute: |args, ctx| {
        site_grant_delete_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteProductDeleteTool,
    name: "site.product.delete",
    aliases: ["site_product_delete", "site.product_delete"],
    description: "Soft-delete a catalog product (sets deleted_ts and archives). Lookup by product_id or product name.",
    topics: ["web.builder", "site.commerce"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.product.delete.calling",
    ui_done_key: "tool.site.product.delete.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        product_id: (integer, "Product ID; if omitted, resolved from name", optional),
        name: (string, "Product name to look up if product_id is not passed", optional),
        q: (string, "Alias of name", optional),
    },
    execute: |args, ctx| {
        site_product_delete_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteContactDeleteTool,
    name: "site.contact.delete",
    aliases: ["site_contact_delete", "site.contact_delete"],
    description: "Soft-delete a contact row in site.contact (sets deleted_ts).",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.contact.delete.calling",
    ui_done_key: "tool.site.contact.delete.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        contact_id: (integer, "Contact ID to delete", required),
    },
    execute: |args, ctx| {
        site_contact_delete_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteObjectDeleteTool,
    name: "site.object.delete",
    aliases: ["site_object_delete", "site.object_delete"],
    description: "Soft-delete an object row in site.object (tables, rooms, units).",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.object.delete.calling",
    ui_done_key: "tool.site.object.delete.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        id: (integer, "Object row ID to delete", required),
    },
    execute: |args, ctx| {
        site_object_delete_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteProductEmbedPutTool,
    name: "site.product_embed.put",
    aliases: ["site_product_embed_put", "site.product_embed_put"],
    description: "Upsert site.product_embed alt-label rows for semantic search on a product.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.product_embed.put.calling",
    ui_done_key: "tool.site.product_embed.put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        product_id: (integer, "Parent product ID", required),
        embeds: (array, "Product embed rows [{embed_id, label}]", required),
    },
    execute: |args, ctx| {
        site_product_embed_put_exec(ctx, &args).await
    }
}

fn arg_text<'a>(args: &'a Value, key: &str) -> Option<&'a str> {
    args.get(key).and_then(|v| v.as_str()).map(str::trim).filter(|s| !s.is_empty())
}

async fn site_product_id_resolve_on_site(
    pool: &sqlx::PgPool,
    site_iid: i64,
    args: &Value,
) -> Result<i64> {
    let product_id_opt = args.get("product_id").and_then(|v| v.as_i64()).filter(|i| *i > 0);
    let name_opt = arg_text(args, "name").or_else(|| arg_text(args, "q"));
    match product_id_opt {
        Some(id) => Ok(id),
        None => {
            let name_query = name_opt.ok_or_else(|| {
                anyhow!("product_id or name is required to identify the product")
            })?;
            sqlx::query_scalar::<_, i64>(
                r#"
                SELECT product_id
                FROM site.product
                WHERE site_iid = $1 AND deleted_ts IS NULL
                  AND (name ILIKE $2 OR sku ILIKE $2)
                ORDER BY CASE WHEN name ILIKE $2 THEN 0 ELSE 1 END, sort_order, product_id
                LIMIT 1
                "#,
            )
            .bind(site_iid)
            .bind(name_query)
            .fetch_optional(pool)
            .await?
            .ok_or_else(|| anyhow!("product '{name_query}' not found at site {site_iid}"))
        }
    }
}

pub async fn site_product_delete_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let _owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let product_id = site_product_id_resolve_on_site(&ctx.pool, site_iid, args).await?;
    let row = sqlx::query(
        r#"
        UPDATE site.product
        SET deleted_ts = NOW(), is_archived = TRUE, updated_ts = NOW()
        WHERE site_iid = $1 AND product_id = $2 AND deleted_ts IS NULL
        RETURNING product_id, name
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .fetch_optional(&ctx.pool)
    .await?
    .ok_or_else(|| anyhow!("product {product_id} not found or already deleted"))?;
    let p_id: i64 = row.get("product_id");
    let p_name: String = row.get("name");
    Ok(json!({
        "ok": true,
        "deleted": true,
        "site_iid": site_iid,
        "product_id": p_id,
        "name": p_name,
    }))
}

pub async fn site_contact_delete_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let _owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let contact_id = args
        .get("contact_id")
        .and_then(|v| v.as_i64())
        .filter(|i| *i > 0)
        .ok_or_else(|| anyhow!("contact_id is required"))?;
    let row = sqlx::query(
        r#"
        UPDATE site.contact
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE site_iid = $1 AND contact_id = $2 AND deleted_ts IS NULL
        RETURNING contact_id, name
        "#,
    )
    .bind(site_iid)
    .bind(contact_id)
    .fetch_optional(&ctx.pool)
    .await?
    .ok_or_else(|| anyhow!("contact {contact_id} not found or already deleted"))?;
    Ok(json!({
        "ok": true,
        "deleted": true,
        "site_iid": site_iid,
        "contact_id": row.get::<i64, _>("contact_id"),
        "name": row.get::<String, _>("name"),
    }))
}

pub async fn site_object_delete_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let _owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let id = args
        .get("id")
        .and_then(|v| v.as_i64())
        .filter(|i| *i > 0)
        .ok_or_else(|| anyhow!("id is required"))?;
    let row = sqlx::query(
        r#"
        UPDATE site.object
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE site_iid = $1 AND id = $2 AND deleted_ts IS NULL
        RETURNING id, name
        "#,
    )
    .bind(site_iid)
    .bind(id)
    .fetch_optional(&ctx.pool)
    .await?
    .ok_or_else(|| anyhow!("object {id} not found or already deleted"))?;
    Ok(json!({
        "ok": true,
        "deleted": true,
        "site_iid": site_iid,
        "id": row.get::<i64, _>("id"),
        "name": row.get::<String, _>("name"),
    }))
}

pub async fn site_product_embed_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let _owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let product_id = args
        .get("product_id")
        .and_then(|v| v.as_i64())
        .filter(|i| *i > 0)
        .ok_or_else(|| anyhow!("product_id is required"))?;
    let exists: bool = sqlx::query_scalar(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM site.product
            WHERE site_iid = $1 AND product_id = $2 AND deleted_ts IS NULL
        )
        "#,
    )
    .bind(site_iid)
    .bind(product_id)
    .fetch_one(&ctx.pool)
    .await?;
    if !exists {
        bail!("product {product_id} not found at site {site_iid}");
    }
    let embeds = args
        .get("embeds")
        .and_then(|v| v.as_array())
        .cloned()
        .filter(|a| !a.is_empty())
        .ok_or_else(|| anyhow!("embeds array is required (at least one {{embed_id, label}})"))?;
    let mut tx = ctx.pool.begin().await?;
    product_embed_put_tx(&mut tx, site_iid, product_id, &embeds).await?;
    tx.commit().await?;
    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "product_id": product_id,
        "embed_count": embeds.len(),
    }))
}

struct ProductPatchRow {
    site_iid: i64,
    product_id: i64,
    name: String,
    price: i64,
    site_name: String,
}

pub async fn site_product_patch_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    if let Ok(site_iid) = site_iid_resolve(ctx, args) {
        return site_product_patch_on_site(ctx, site_iid, args).await;
    }
    site_product_patch_scoped(ctx, args).await
}

async fn site_product_patch_on_site(ctx: &ToolContext, site_iid: i64, args: &Value) -> Result<Value> {
    let _owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let product_id_opt = args.get("product_id").and_then(|v| v.as_i64()).filter(|i| *i > 0);
    let name_opt = arg_text(args, "name").or_else(|| arg_text(args, "q"));

    if product_id_opt.is_none() && name_opt.is_none() {
        bail!("product_id or name is required to identify the product to update");
    }

    let target_product_id: i64 = match product_id_opt {
        Some(id) => id,
        None => {
            let name_query = name_opt.unwrap();
            sqlx::query_scalar::<_, i64>(
                r#"
                SELECT product_id
                FROM site.product
                WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = false
                  AND (name ILIKE $2 OR sku ILIKE $2)
                ORDER BY CASE WHEN name ILIKE $2 THEN 0 ELSE 1 END, sort_order, product_id
                LIMIT 1
                "#,
            )
            .bind(site_iid)
            .bind(name_query)
            .fetch_optional(&ctx.pool)
            .await?
            .ok_or_else(|| anyhow!("product '{name_query}' not found at site {site_iid}"))?
        }
    };

    site_product_patch_write(ctx, site_iid, target_product_id, args).await
}

async fn site_product_patch_scoped(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let q = arg_text(args, "name")
        .or_else(|| arg_text(args, "q"))
        .ok_or_else(|| anyhow!("name or q is required to identify the product"))?;
    let mentioned = ctx.mention.site_iids();
    let granted = if mentioned.is_empty() {
        site_granted_iids(&ctx.pool, ctx.owner_iid).await?
    } else {
        Vec::new()
    };
    let site_iids = site_scope_pick(&mentioned, &granted, &[]).map_err(|e| anyhow!(e))?;
    let rows = sqlx::query(
        r#"
        SELECT p.site_iid, p.product_id, p.name, p.price, i.name AS site_name
        FROM site.product p
        JOIN ai.identity i ON i.id = p.site_iid
        WHERE p.site_iid = ANY($1)
          AND p.deleted_ts IS NULL AND p.is_archived = false
          AND (p.name ILIKE ('%' || $2 || '%') OR p.sku ILIKE ('%' || $2 || '%'))
        ORDER BY p.site_iid, p.product_id
        LIMIT 20
        "#,
    )
    .bind(&site_iids)
    .bind(q)
    .fetch_all(&ctx.pool)
    .await?;
    let found: Vec<ProductPatchRow> = rows
        .iter()
        .map(|r| ProductPatchRow {
            site_iid: r.get("site_iid"),
            product_id: r.get("product_id"),
            name: r.get("name"),
            price: r.get("price"),
            site_name: r.get("site_name"),
        })
        .collect();
    let hits = found
        .iter()
        .map(|r| ProductHit {
            site_iid: r.site_iid,
            product_id: r.product_id,
            name: r.name.clone(),
            price: r.price,
        })
        .collect();
    match product_match_classify(hits) {
        ProductMatch::None => bail!("product not found"),
        ProductMatch::Many(_) => Ok(json!({
            "ok": false,
            "ambiguous": true,
            "matches": found.iter().map(|r| json!({
                "site_iid": r.site_iid,
                "site_name": r.site_name,
                "product_id": r.product_id,
                "name": r.name,
                "price": r.price,
            })).collect::<Vec<_>>(),
        })),
        ProductMatch::One(hit) => {
            let _owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, hit.site_iid).await?;
            site_product_patch_write(ctx, hit.site_iid, hit.product_id, args).await
        }
    }
}

async fn site_product_patch_write(
    ctx: &ToolContext,
    site_iid: i64,
    target_product_id: i64,
    args: &Value,
) -> Result<Value> {
    let price = args.get("price").and_then(|v| v.as_i64());
    let cost_price = args.get("cost_price").and_then(|v| v.as_i64());
    let stock_qty = args.get("stock_qty").and_then(|v| v.as_i64()).map(|n| n as i32);
    let stock_delta = args.get("stock_delta").and_then(|v| v.as_i64()).map(|n| n as i32);
    let track_stock = args.get("track_stock").and_then(|v| v.as_bool());
    let can_sell = args.get("can_sell").and_then(|v| v.as_bool());
    let can_reserve = args.get("can_reserve").and_then(|v| v.as_bool());
    let is_archived = args.get("is_archived").and_then(|v| v.as_bool());
    let soft_delete = args.get("deleted").and_then(|v| v.as_bool()).unwrap_or(false);
    let new_name = arg_text(args, "new_name");

    let row = sqlx::query(
        r#"
        UPDATE site.product SET
            name = COALESCE($3, name),
            price = COALESCE($4, price),
            cost_price = COALESCE($5, cost_price),
            stock_qty = CASE
                WHEN $6::int IS NOT NULL THEN stock_qty + $6
                WHEN $7::int IS NOT NULL THEN $7
                ELSE stock_qty
            END,
            track_stock = COALESCE($8, track_stock),
            can_sell = COALESCE($9, can_sell),
            can_reserve = COALESCE($10, can_reserve),
            is_archived = CASE WHEN $12 THEN TRUE ELSE COALESCE($11, is_archived) END,
            deleted_ts = CASE WHEN $12 THEN NOW() ELSE deleted_ts END,
            updated_ts = NOW()
        WHERE site_iid = $1 AND product_id = $2 AND ($12 = FALSE OR deleted_ts IS NULL)
        RETURNING product_id, name, price, cost_price, stock_qty, track_stock, can_sell, can_reserve
        "#,
    )
    .bind(site_iid)
    .bind(target_product_id)
    .bind(new_name)
    .bind(price)
    .bind(cost_price)
    .bind(stock_delta)
    .bind(stock_qty)
    .bind(track_stock)
    .bind(can_sell)
    .bind(can_reserve)
    .bind(is_archived)
    .bind(soft_delete)
    .fetch_one(&ctx.pool)
    .await?;

    let p_id: i64 = row.get("product_id");
    let p_name: String = row.get("name");
    let p_price: i64 = row.get("price");
    let p_cost_price: i64 = row.get("cost_price");
    let p_stock_qty: i32 = row.get("stock_qty");
    let p_track_stock: bool = row.get("track_stock");
    let p_can_sell: bool = row.get("can_sell");
    let p_can_reserve: bool = row.get("can_reserve");

    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "product_id": p_id,
        "name": p_name,
        "price": p_price,
        "cost_price": p_cost_price,
        "stock_qty": p_stock_qty,
        "track_stock": p_track_stock,
        "can_sell": p_can_sell,
        "can_reserve": p_can_reserve,
    }))
}

tool! {
    struct: SiteProductPatchTool,
    name: "site.product.patch",
    aliases: ["site_product_patch", "site.product_patch"],
    description: "Safely update specific product fields (price, cost_price, stock_qty, stock_delta, can_sell) without overwriting other catalog details. Lookup by product_id or name. When site_iid is omitted and several sites match, returns ambiguous and does not write.",
    topics: ["site.commerce", "web.builder"],
    ui_calling_key: "tool.site.product.patch.calling",
    ui_done_key: "tool.site.product.patch.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        product_id: (integer, "Product ID; if omitted, resolved from name", optional),
        name: (string, "Product name to look up if product_id is not passed", optional),
        q: (string, "Alias of name", optional),
        new_name: (string, "Rename product to new name", optional),
        price: (integer, "New retail price in minor units (e.g. 54000 for 54k IDR)", optional),
        cost_price: (integer, "New cost/purchase price (for margin tracking)", optional),
        stock_qty: (integer, "Set absolute stock quantity", optional),
        stock_delta: (integer, "Add/subtract stock quantity (e.g. +10 or -5)", optional),
        track_stock: (boolean, "Enable/disable stock tracking", optional),
        can_sell: (boolean, "Available for sale", optional),
        can_reserve: (boolean, "Allow reservation/booking", optional),
        is_archived: (boolean, "Archive/unarchive product", optional),
        deleted: (boolean, "Soft-delete product (sets deleted_ts and archives)", optional),
    },
    execute: |args, ctx| {
        site_product_patch_exec(ctx, &args).await
    }
}

pub async fn site_draft_get_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let row = sqlx::query_scalar::<_, Value>(
        "SELECT doc_json FROM site.draft WHERE site_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(&ctx.pool)
    .await?;

    match row {
        Some(doc) => Ok(json!({ "ok": true, "site_iid": site_iid, "doc": doc })),
        None => Ok(json!({ "ok": false, "site_iid": site_iid, "error": "No draft found for site" })),
    }
}

tool! {
    struct: SiteDraftGetTool,
    name: "site.draft_get",
    aliases: ["site_draft_get", "site.draft.get"],
    description: "Read the site's current draft SiteDoc (pages, blocks, theme, meta) for inspection.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.draft_get.calling",
    ui_done_key: "tool.site.draft_get.done",
    readonly: true,
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
    },
    execute: |args, ctx| {
        site_draft_get_exec(ctx, &args).await
    }
}

pub async fn site_domain_put_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let hostname = args
        .get("hostname")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .ok_or_else(|| anyhow!("hostname is required"))?;

    let is_primary = args.get("is_primary").and_then(|v| v.as_bool()).unwrap_or(false);
    let id = args.get("id").and_then(|v| v.as_i64()).unwrap_or(0);

    let domain = c35_proto::SiteDomain {
        id,
        site_iid,
        hostname: hostname.to_string(),
        is_primary,
        ..Default::default()
    };

    let res = c35_mod_site::site_domain_put(
        &ctx.pool,
        owner_iid,
        c35_proto::ReqSiteDomainPut {
            site_iid,
            domain: Some(domain),
        },
        None,
    )
    .await?;

    let cname_target = c35_mod_site::domain_cname_target();
    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "domain_id": res.id,
        "hostname": hostname,
        "cname_target": cname_target,
        "instructions": format!("Point a CNAME record for '{}' to '{}' (or A record to the platform origin IP), then run site.domain_verify.", hostname, cname_target),
    }))
}

tool! {
    struct: SiteDomainPutTool,
    name: "site.domain_put",
    aliases: ["site_domain_put", "site.domain.put"],
    description: "Attach a custom domain hostname to a site and get DNS CNAME instructions.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.domain_put.calling",
    ui_done_key: "tool.site.domain_put.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        hostname: (string, "Custom domain hostname (e.g. store.example.com or example.com)"),
        is_primary: (boolean, "Set as primary domain for canonical redirects", optional),
        id: (integer, "Existing domain row ID if updating", optional),
    },
    execute: |args, ctx| {
        site_domain_put_exec(ctx, &args).await
    }
}

pub async fn site_domain_verify_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;

    let domain_id = if let Some(id) = args.get("domain_id").and_then(|v| v.as_i64()).filter(|i| *i > 0) {
        id
    } else if let Some(hostname) = args.get("hostname").and_then(|v| v.as_str()).map(str::trim).filter(|s| !s.is_empty()) {
        let id: i64 = sqlx::query_scalar(
            "SELECT id FROM site.domain WHERE site_iid = $1 AND hostname = $2 AND deleted_ts IS NULL",
        )
        .bind(site_iid)
        .bind(hostname)
        .fetch_optional(&ctx.pool)
        .await?
        .ok_or_else(|| anyhow!("Domain '{}' not found for this site", hostname))?;
        id
    } else {
        let id: i64 = sqlx::query_scalar(
            "SELECT id FROM site.domain WHERE site_iid = $1 AND deleted_ts IS NULL ORDER BY is_primary DESC, id ASC LIMIT 1",
        )
        .bind(site_iid)
        .fetch_optional(&ctx.pool)
        .await?
        .ok_or_else(|| anyhow!("No domain configured for this site"))?;
        id
    };

    let force_tls = args.get("force_tls").and_then(|v| v.as_bool()).unwrap_or(false);
    let res = c35_mod_site::site_domain_verify(
        &ctx.pool,
        owner_iid,
        c35_proto::ReqSiteDomainVerify {
            site_iid,
            domain_id,
            force_tls,
        },
        None,
    )
    .await?;

    Ok(json!({
        "ok": res.dns_verified,
        "site_iid": site_iid,
        "domain_id": domain_id,
        "dns_verified": res.dns_verified,
        "error": res.error,
        "tls_status": res.tls_status,
    }))
}

tool! {
    struct: SiteDomainVerifyTool,
    name: "site.domain_verify",
    aliases: ["site_domain_verify", "site.domain.verify"],
    description: "Verify DNS configuration and TLS certificate status for a site's custom domain.",
    topics: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.domain_verify.calling",
    ui_done_key: "tool.site.domain_verify.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from @alien_id when omitted)", optional),
        domain_id: (integer, "Domain row ID to verify", optional),
        hostname: (string, "Domain hostname to verify (alternative to domain_id)", optional),
        force_tls: (boolean, "Re-trigger TLS certificate provisioning if DNS is already verified", optional),
    },
    execute: |args, ctx| {
        site_domain_verify_exec(ctx, &args).await
    }
}

fn resolve_target_page_mut<'a>(
    pages: &'a mut [Value],
    target_path: Option<&str>,
) -> Result<&'a mut Value> {
    let target_idx = if let Some(tp) = target_path.map(str::trim).filter(|s| !s.is_empty()) {
        let norm = if tp.starts_with('/') {
            tp.to_string()
        } else {
            format!("/{tp}")
        };
        pages.iter().position(|p| p.get("path").and_then(|v| v.as_str()) == Some(&norm))
    } else {
        None
    };

    let idx = target_idx.unwrap_or(0);
    pages.get_mut(idx).ok_or_else(|| anyhow!("at least one page required"))
}

fn apply_site_patch(
    doc: &mut Value,
    page_path: Option<&str>,
    action: &str,
    block_id: &str,
    after_block_id: &str,
    block: Option<&Value>,
    props: Option<&Value>,
    theme: Option<&Value>,
    meta: Option<&Value>,
) -> Result<String> {
    match action {
        "patch_theme" => {
            let t = theme.ok_or_else(|| anyhow!("theme object required for patch_theme"))?;
            let t_obj = t.as_object().ok_or_else(|| anyhow!("theme must be an object"))?;
            let doc_obj = doc.as_object_mut().ok_or_else(|| anyhow!("doc must be an object"))?;
            if !doc_obj.contains_key("theme") || !doc_obj["theme"].is_object() {
                doc_obj.insert("theme".into(), json!({}));
            }
            if let Some(target) = doc_obj.get_mut("theme").and_then(|v| v.as_object_mut()) {
                for (k, v) in t_obj {
                    target.insert(k.clone(), v.clone());
                }
            }
            Ok("Theme updated".to_string())
        }
        "patch_meta" => {
            let m = meta.ok_or_else(|| anyhow!("meta object required for patch_meta"))?;
            let m_obj = m.as_object().ok_or_else(|| anyhow!("meta must be an object"))?;
            let doc_obj = doc.as_object_mut().ok_or_else(|| anyhow!("doc must be an object"))?;
            if !doc_obj.contains_key("meta") || !doc_obj["meta"].is_object() {
                doc_obj.insert("meta".into(), json!({}));
            }
            if let Some(target) = doc_obj.get_mut("meta").and_then(|v| v.as_object_mut()) {
                for (k, v) in m_obj {
                    target.insert(k.clone(), v.clone());
                }
            }
            Ok("Metadata updated".to_string())
        }
        "delete_block" => {
            if block_id.trim().is_empty() {
                bail!("block_id is required for delete_block");
            }
            let pages = doc.get_mut("pages").and_then(|v| v.as_array_mut()).ok_or_else(|| anyhow!("doc.pages required"))?;
            let page = resolve_target_page_mut(pages, page_path)?;
            let blocks = page.get_mut("blocks").and_then(|v| v.as_array_mut()).ok_or_else(|| anyhow!("page.blocks required"))?;
            if blocks.len() <= 1 {
                bail!("cannot delete the only remaining block on the page");
            }
            let pos = blocks.iter().position(|b| {
                b.get("id").and_then(|v| v.as_str()).map(|s| s == block_id).unwrap_or(false)
            });
            match pos {
                Some(idx) => {
                    blocks.remove(idx);
                    Ok(format!("Block '{block_id}' deleted"))
                }
                None => bail!("Block '{block_id}' not found"),
            }
        }
        "insert_block" => {
            let new_block = block.ok_or_else(|| anyhow!("block object required for insert_block"))?;
            let pages = doc.get_mut("pages").and_then(|v| v.as_array_mut()).ok_or_else(|| anyhow!("doc.pages required"))?;
            let page = resolve_target_page_mut(pages, page_path)?;
            let blocks = page.get_mut("blocks").and_then(|v| v.as_array_mut()).ok_or_else(|| anyhow!("page.blocks required"))?;

            if !after_block_id.trim().is_empty() {
                let pos = blocks.iter().position(|b| {
                    b.get("id").and_then(|v| v.as_str()).map(|s| s == after_block_id).unwrap_or(false)
                });
                if let Some(idx) = pos {
                    blocks.insert(idx + 1, new_block.clone());
                    return Ok(format!("Block inserted after '{after_block_id}'"));
                }
            }
            blocks.push(new_block.clone());
            Ok("Block inserted".to_string())
        }
        _ => {
            // default: "update_block"
            let pages = doc.get_mut("pages").and_then(|v| v.as_array_mut()).ok_or_else(|| anyhow!("doc.pages required"))?;
            let page = resolve_target_page_mut(pages, page_path)?;
            let blocks = page.get_mut("blocks").and_then(|v| v.as_array_mut()).ok_or_else(|| anyhow!("page.blocks required"))?;

            let effective_id = if block_id.trim().is_empty() && blocks.len() == 1 {
                blocks[0].get("id").and_then(|v| v.as_str()).unwrap_or("").to_string()
            } else {
                block_id.trim().to_string()
            };

            if effective_id.is_empty() {
                bail!("block_id is required to update a block");
            }

            let pos = blocks.iter().position(|b| {
                b.get("id").and_then(|v| v.as_str()).map(|s| s == effective_id).unwrap_or(false)
            });

            match pos {
                Some(idx) => {
                    if let Some(nb) = block {
                        blocks[idx] = nb.clone();
                    } else if let Some(p) = props {
                        let p_obj = p.as_object().ok_or_else(|| anyhow!("props must be an object"))?;
                        let existing = &mut blocks[idx];
                        if !existing.as_object().unwrap().contains_key("props") {
                            existing.as_object_mut().unwrap().insert("props".into(), json!({}));
                        }
                        if let Some(target_props) = existing.get_mut("props").and_then(|v| v.as_object_mut()) {
                            for (k, v) in p_obj {
                                target_props.insert(k.clone(), v.clone());
                            }
                        }
                    } else {
                        bail!("either 'block' or 'props' is required to update a block");
                    }
                    Ok(format!("Block '{effective_id}' updated"))
                }
                None => bail!("Block '{effective_id}' not found in page blocks"),
            }
        }
    }
}

pub async fn site_create_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let name = args.get("name").and_then(|v| v.as_str()).unwrap_or("").trim();
    if name.is_empty() {
        bail!("name is required to create a site");
    }
    let tagline = args.get("tagline").and_then(|v| v.as_str()).unwrap_or("").trim();
    let theme_name = args.get("theme").and_then(|v| v.as_str()).unwrap_or("dark").trim();
    let logo_url = args
        .get("logo_url")
        .or_else(|| args.get("pic"))
        .or_else(|| args.get("logo"))
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("");
    let requested_alien_id = args.get("alien_id").and_then(|v| v.as_str()).map(str::trim).filter(|s| !s.is_empty());
    let template = args
        .get("template")
        .and_then(|v| v.as_str())
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .unwrap_or("hub");

    let site_iid = snowflake_id();
    let alien_id = match requested_alien_id {
        Some(req) => {
            let base_slug = site_slug_generate(req);
            site_slug_ensure_unique(&ctx.pool, &base_slug, None).await?
        }
        None => site_iid.to_string(),
    };
    let owner_iid = ctx.owner_iid;

    let mut tx = ctx.pool.begin().await?;

    // 1. ai.identity
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, alien_id, name, pic, owner_iid, locale, tz, created_ts, updated_ts)
        VALUES ($1, 'site', 'web', $2, $3, NULLIF($4, ''), $5, 'en_US', 'UTC', NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(&alien_id)
    .bind(name)
    .bind(logo_url)
    .bind(owner_iid)
    .execute(&mut *tx)
    .await?;

    // 2. ai.identity_grant
    let grant_id = snowflake_id();
    sqlx::query(
        r#"
        INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, permissions, is_pinned, created_ts, updated_ts)
        VALUES ($1, $2, $3, 'owner', '{}', true, NOW(), NOW())
        ON CONFLICT (resource_iid, grantee_iid) DO NOTHING
        "#,
    )
    .bind(grant_id)
    .bind(site_iid)
    .bind(owner_iid)
    .execute(&mut *tx)
    .await?;

    // 3. site.config
    let cap_json = serde_json::json!({
        "commerce": true,
        "booking": false,
        "queue": false,
        "attendance": false
    });
    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, capabilities_json, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
            owner_iid = EXCLUDED.owner_iid,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(&cap_json)
    .execute(&mut *tx)
    .await?;

    // 4. Initial SiteDoc
    let accent_color = match theme_name.to_lowercase().as_str() {
        "emerald" => "#10B981",
        "indigo" | "midnight" => "#6366F1",
        "sunset" => "#EC4899",
        _ => "#F97316",
    };

    let subtitle = if tagline.is_empty() {
        format!("Selamat datang di {name}")
    } else {
        tagline.to_string()
    };
    let blocks = if template.eq_ignore_ascii_case("landing") {
        json!([
            {
                "id": "hero1",
                "type": "hero",
                "props": {
                    "title": name,
                    "subtitle": subtitle,
                    "cta_label": "Kunjungi",
                    "cta_href": "#contact",
                    "pic": logo_url
                }
            },
            {
                "id": "features1",
                "type": "markdown",
                "props": {
                    "content": format!("### Tentang {name}\nKualitas dan pelayanan terbaik untuk Anda.")
                }
            },
            {
                "id": "contact1",
                "type": "contact_form",
                "props": {
                    "title": "Hubungi Kami",
                    "submit_label": "Kirim Pesan"
                }
            }
        ])
    } else {
        json!([
            {
                "id": "hub1",
                "type": "hub_profile",
                "props": {
                    "title": name,
                    "subtitle": subtitle,
                    "pic": logo_url
                }
            },
            {
                "id": "links1",
                "type": "links",
                "props": {
                    "title": "Link",
                    "links": []
                }
            },
            {
                "id": "social1",
                "type": "social_feed",
                "props": {
                    "title": "Update",
                    "limit": 10
                }
            },
            {
                "id": "grid1",
                "type": "product_grid",
                "props": {
                    "filter": "all",
                    "page_size": 12
                }
            }
        ])
    };
    let initial_doc = json!({
        "pages": [
            {
                "path": "/",
                "title": name,
                "blocks": blocks
            }
        ],
        "theme": {
            "accent": accent_color,
            "layout": if template.eq_ignore_ascii_case("landing") { "clean" } else { "hub" }
        },
        "meta": {
            "seo_title": name,
            "seo_desc": tagline
        }
    });

    validate_sitedoc(&initial_doc)?;
    let doc_str = serde_json::to_string(&initial_doc)?;

    sqlx::query(
        r#"
        INSERT INTO site.draft (site_iid, owner_iid, doc_json, created_ts, updated_ts)
        VALUES ($1, $2, $3::jsonb, NOW(), NOW())
        ON CONFLICT (site_iid) DO UPDATE SET
            doc_json = EXCLUDED.doc_json,
            owner_iid = EXCLUDED.owner_iid,
            updated_ts = NOW(),
            deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(owner_iid)
    .bind(&doc_str)
    .execute(&mut *tx)
    .await?;

    tx.commit().await?;

    let (preview_token, preview_expires_ts_ms) =
        site_preview_token_issue(&ctx.pool, owner_iid, site_iid, 3600).await?;
    let preview_url = format!(
        "https://alienai.id/{alien_id}?draft=1&ptoken={}",
        urlencoding::encode(&preview_token)
    );
    let url = format!("alienai.id/{alien_id}");

    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "alien_id": alien_id,
        "name": name,
        "url": url,
        "preview_token": preview_token,
        "preview_expires_ts_ms": preview_expires_ts_ms,
        "preview_url": preview_url,
        "block": {
            "kind": "site.preview",
            "collapsed": false,
            "body": {
                "site_iid": site_iid,
                "alien_id": alien_id,
                "name": name,
                "url": url,
                "preview_token": preview_token,
                "preview_expires_ts_ms": preview_expires_ts_ms,
                "preview_url": preview_url,
                "theme": theme_name,
                "doc": initial_doc
            }
        }
    }))
}

pub async fn site_patch_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let owner_iid = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;
    let action = args.get("action").and_then(|v| v.as_str()).unwrap_or("update_block").trim().to_lowercase();
    let page_path = args.get("page_path").or_else(|| args.get("path")).and_then(|v| v.as_str());
    let block_id = args.get("block_id").and_then(|v| v.as_str()).unwrap_or("").trim();
    let after_block_id = args.get("after_block_id").and_then(|v| v.as_str()).unwrap_or("").trim();
    let block = args.get("block");
    let props = args.get("props");
    let theme = args.get("theme");
    let meta = args.get("meta");

    let draft_row = sqlx::query_scalar::<_, Value>(
        "SELECT doc_json FROM site.draft WHERE site_iid = $1 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(&ctx.pool)
    .await?
    .ok_or_else(|| anyhow!("No draft found for site {site_iid}"))?;

    let mut doc = draft_row;
    let summary = apply_site_patch(
        &mut doc,
        page_path,
        &action,
        block_id,
        after_block_id,
        block,
        props,
        theme,
        meta,
    )?;

    validate_sitedoc(&doc)?;
    let doc_str = serde_json::to_string(&doc)?;

    sqlx::query(
        "UPDATE site.draft SET doc_json = $1::jsonb, updated_ts = NOW() WHERE site_iid = $2 AND owner_iid = $3",
    )
    .bind(&doc_str)
    .bind(site_iid)
    .bind(owner_iid)
    .execute(&ctx.pool)
    .await?;

    let ident_row = sqlx::query("SELECT alien_id, name FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(site_iid)
        .fetch_optional(&ctx.pool)
        .await?;
    let alien_id = ident_row
        .as_ref()
        .and_then(|r| r.get::<Option<String>, _>("alien_id"))
        .unwrap_or_default();
    let name = ident_row
        .as_ref()
        .map(|r| r.get::<String, _>("name"))
        .unwrap_or_else(|| "Site".to_string());

    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "alien_id": alien_id,
        "action": action,
        "summary": summary,
        "block": {
            "kind": "site.preview",
            "collapsed": false,
            "body": {
                "site_iid": site_iid,
                "alien_id": alien_id,
                "name": name,
                "url": format!("alienai.id/{alien_id}"),
                "doc": doc
            }
        }
    }))
}

pub async fn site_handle_update_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let new_alien_id_raw = args
        .get("new_alien_id")
        .or_else(|| args.get("alien_id"))
        .or_else(|| args.get("handle"))
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim();
    if new_alien_id_raw.is_empty() {
        bail!("new_alien_id is required");
    }
    let res = site_handle_put(
        &ctx.pool,
        ctx.owner_iid,
        ReqSiteHandlePut {
            site_iid,
            new_alien_id: new_alien_id_raw.to_string(),
        },
    )
    .await?;
    let unique_slug = res.alien_id;
    let url = res.url;
    Ok(json!({
        "ok": true,
        "site_iid": site_iid,
        "alien_id": unique_slug,
        "url": url,
        "message": format!("Site handle updated to @{unique_slug} (URL: {url})")
    }))
}

tool! {
    struct: SiteCreateTool,
    name: "site.create",
    aliases: ["site_create", "site.new"],
    description: "Create a new website identity, draft, and live preview block. Default public path is the site numeric ID (alienai.id/{id}); pass alien_id for a custom handle/slug.",
    topics: ["web.builder"],
    always: ["web.builder"],
    ui_calling_key: "tool.site.create.calling",
    ui_done_key: "tool.site.create.done",
    parameters: {
        name: (string, "Brand or website name", required),
        alien_id: (string, "Optional custom handle/slug for URL (alienai.id/handle)", optional, default = ""),
        tagline: (string, "Short tagline or business description", optional, default = ""),
        theme: (string, "Visual theme: 'dark' (default), 'emerald', 'indigo', or 'sunset'", optional, default = "dark"),
        logo_url: (string, "Logo image URL or /fs/{hash} from user upload; sets site pic + hero image", optional, default = ""),
        template: (string, "Layout template: 'hub' (default) or 'landing' (hero page)", optional, default = "hub"),
    },
    execute: |args, ctx| {
        site_create_exec(ctx, &args).await
    }
}

tool! {
    struct: SitePatchTool,
    name: "site.patch",
    aliases: ["site_patch", "site.block_patch"],
    description: "Apply a targeted edit or patch to the site draft (update, insert, or delete a block, or update theme/metadata) without regenerating the entire website.",
    topics: ["web.builder"],
    always: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.patch.calling",
    ui_done_key: "tool.site.patch.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from active @site when omitted)", optional),
        action: (string, "Patch action: 'update_block' (default), 'insert_block', 'delete_block', 'patch_theme', or 'patch_meta'", optional, default = "update_block"),
        block_id: (string, "Target block ID to update or delete (e.g. 'hero1', 'features1')", optional, default = ""),
        after_block_id: (string, "Block ID after which to insert a new block (for 'insert_block')", optional, default = ""),
        block: (object, "Block JSON object containing 'id', 'type', and 'props' (for update_block or insert_block)", optional),
        props: (object, "Shortcut block props object to merge into existing block (for update_block)", optional),
        theme: (object, "Theme settings object e.g. {'accent': '#10B981', 'layout': 'clean'}", optional),
        meta: (object, "Metadata settings object e.g. {'seo_title': '...', 'seo_desc': '...'}", optional),
    },
    execute: |args, ctx| {
        site_patch_exec(ctx, &args).await
    }
}

tool! {
    struct: SiteHandleUpdateTool,
    name: "site.handle.update",
    aliases: ["site_handle_update", "site.handle_update", "site.alien_id_update"],
    description: "Update the public URL handle/slug (alien_id) of a site (e.g. alienai.id/new-handle). Ask for user confirmation before changing if site is already active.",
    topics: ["web.builder"],
    always: ["web.builder"],
    requires_kinds: ["site"],
    ui_calling_key: "tool.site.handle.update.calling",
    ui_done_key: "tool.site.handle.update.done",
    parameters: {
        site_iid: (integer, "Site identity ID (resolved from active @site when omitted)", optional),
        new_alien_id: (string, "New unique slug/handle for the site URL", required),
    },
    execute: |args, ctx| {
        site_handle_update_exec(ctx, &args).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tools::Tool;

    #[test]
    fn test_site_create_definition() {
        let tool = SiteCreateTool;
        let def = tool.definition();
        assert_eq!(def.name, "site.create");
        assert!(def.aliases.contains(&"site_create".to_string()));
        assert!(def.requires_kinds.is_empty());
        assert_eq!(def.parameters["properties"]["name"]["type"], "string");
    }

    #[test]
    fn test_site_patch_definition() {
        let tool = SitePatchTool;
        let def = tool.definition();
        assert_eq!(def.name, "site.patch");
        assert!(def.aliases.contains(&"site_patch".to_string()));
        assert_eq!(def.requires_kinds, vec!["site".to_string()]);
    }

    #[test]
    fn test_site_config_put_definition() {
        let tool = SiteConfigPutTool;
        let def = tool.definition();
        assert_eq!(def.name, "site.config.put");
        assert!(def.aliases.contains(&"site_config_put".to_string()));
        assert_eq!(def.requires_kinds, vec!["site".to_string()]);
        assert_eq!(def.topics, vec!["web.builder".to_string()]);
    }

    #[test]
    fn test_site_product_delete_definition() {
        let tool = SiteProductDeleteTool;
        let def = tool.definition();
        assert_eq!(def.name, "site.product.delete");
        assert!(def.aliases.contains(&"site_product_delete".to_string()));
        assert_eq!(def.requires_kinds, vec!["site".to_string()]);
        assert!(def.topics.contains(&"web.builder".to_string()));
    }

    #[test]
    fn test_site_product_patch_definition() {
        let tool = SiteProductPatchTool;
        let def = tool.definition();
        assert_eq!(def.name, "site.product.patch");
        assert!(def.parameters["properties"].get("deleted").is_some());
    }

    #[test]
    fn test_site_contact_delete_definition() {
        let tool = SiteContactDeleteTool;
        let def = tool.definition();
        assert_eq!(def.name, "site.contact.delete");
        assert_eq!(def.requires_kinds, vec!["site".to_string()]);
    }

    #[test]
    fn test_site_object_delete_definition() {
        let tool = SiteObjectDeleteTool;
        let def = tool.definition();
        assert_eq!(def.name, "site.object.delete");
        assert_eq!(def.requires_kinds, vec!["site".to_string()]);
    }

    #[test]
    fn test_site_product_embed_put_definition() {
        let tool = SiteProductEmbedPutTool;
        let def = tool.definition();
        assert_eq!(def.name, "site.product_embed.put");
        assert!(def.aliases.contains(&"site_product_embed_put".to_string()));
        assert_eq!(def.requires_kinds, vec!["site".to_string()]);
        assert_eq!(def.topics, vec!["web.builder".to_string()]);
    }

    #[test]
    fn test_site_capabilities_merge_flags() {
        let args = json!({ "commerce": true, "queue": false });
        let merged = site_capabilities_merge(&args, json!({ "booking": true })).unwrap();
        assert_eq!(merged["commerce"], true);
        assert_eq!(merged["booking"], true);
        assert_eq!(merged["queue"], false);
    }

    #[test]
    fn test_apply_site_patch_update_and_insert() {
        let mut doc = json!({
            "pages": [{
                "path": "/",
                "title": "Test",
                "blocks": [
                    {
                        "id": "hero1",
                        "type": "hero",
                        "props": { "title": "Old Title", "subtitle": "Old Sub" }
                    },
                    {
                        "id": "contact1",
                        "type": "contact_form",
                        "props": { "title": "Contact Us" }
                    }
                ]
            }],
            "theme": { "accent": "#F97316" }
        });

        // 1. Update block props
        let res = apply_site_patch(
            &mut doc,
            None,
            "update_block",
            "hero1",
            "",
            None,
            Some(&json!({ "title": "New Title" })),
            None,
            None,
        );
        assert!(res.is_ok());
        assert_eq!(doc["pages"][0]["blocks"][0]["props"]["title"], "New Title");
        assert_eq!(doc["pages"][0]["blocks"][0]["props"]["subtitle"], "Old Sub");

        // 2. Insert block after hero1
        let new_block = json!({
            "id": "feat1",
            "type": "markdown",
            "props": { "content": "Hello Markdown" }
        });
        let res = apply_site_patch(
            &mut doc,
            None,
            "insert_block",
            "",
            "hero1",
            Some(&new_block),
            None,
            None,
            None,
        );
        assert!(res.is_ok());
        assert_eq!(doc["pages"][0]["blocks"].as_array().unwrap().len(), 3);
        assert_eq!(doc["pages"][0]["blocks"][1]["id"], "feat1");

        // 3. Patch theme
        let res = apply_site_patch(
            &mut doc,
            None,
            "patch_theme",
            "",
            "",
            None,
            None,
            Some(&json!({ "accent": "#10B981" })),
            None,
        );
        assert!(res.is_ok());
        assert_eq!(doc["theme"]["accent"], "#10B981");

        // 4. Delete block
        let res = apply_site_patch(
            &mut doc,
            None,
            "delete_block",
            "feat1",
            "",
            None,
            None,
            None,
            None,
        );
        assert!(res.is_ok());
        assert_eq!(doc["pages"][0]["blocks"].as_array().unwrap().len(), 2);
    }

    #[test]
    fn test_apply_site_patch_multi_page() {
        let mut doc = json!({
            "pages": [
                {
                    "path": "/",
                    "title": "Home",
                    "blocks": [
                        { "id": "h1", "type": "hero", "props": { "title": "Home Page" } }
                    ]
                },
                {
                    "path": "/about",
                    "title": "About",
                    "blocks": [
                        { "id": "a1", "type": "markdown", "props": { "content": "About us" } }
                    ]
                }
            ]
        });

        let res = apply_site_patch(
            &mut doc,
            Some("/about"),
            "update_block",
            "a1",
            "",
            None,
            Some(&json!({ "content": "Updated about us" })),
            None,
            None,
        );
        assert!(res.is_ok());
        assert_eq!(doc["pages"][1]["blocks"][0]["props"]["content"], "Updated about us");
        assert_eq!(doc["pages"][0]["blocks"][0]["props"]["title"], "Home Page");
    }
}



