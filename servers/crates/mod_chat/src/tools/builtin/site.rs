use anyhow::{anyhow, bail, Result};
use c35_mod_site::{site_contact_upsert, site_object_upsert, site_publish_from_draft};
use c35_proto::{SiteContact, SiteObject};
use c35_store::snowflake_id;
use serde_json::{json, Value};
use sqlx::{Postgres, Transaction};

use crate::mention_context::site_iid_resolve as mention_site_iid_resolve;
use crate::site_resolve::site_grant_owner;
use crate::site_validate::validate_sitedoc;
use crate::tool;
use crate::tools::ToolContext;

fn site_iid_resolve(ctx: &ToolContext, args: &Value) -> Result<i64> {
    mention_site_iid_resolve(
        &ctx.mention,
        ctx.site_iid,
        args.get("site_iid").and_then(|v| v.as_i64()),
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
    Ok(json!({ "ok": true, "site_iid": site_iid, "product_id": product_id }))
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
    struct: SiteProductPutTool,
    name: "site.product_put",
    aliases: ["site_product_put"],
    description: "Upsert a product row in site.product catalog (typed fields only — no checkout JSON).",
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
        price: (integer, "Price in smallest currency unit", optional),
        pic: (string, "Image URL or /fs/{hash}", optional),
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
