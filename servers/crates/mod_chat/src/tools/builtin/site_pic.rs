use anyhow::{anyhow, bail, Result};
use serde_json::{json, Map, Value};
use sqlx::Row;

use crate::mention_context::{json_device_iid_field, site_iid_resolve as mention_site_iid_resolve};
use crate::site_product_match::{product_match_classify, ProductHit, ProductMatch};
use crate::site_resolve::site_grant_owner;
use crate::tool;
use crate::tools::asset_image::asset_image_generate;
use crate::tools::ToolContext;

/// Where a generated site picture is stored.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SitePicSlot {
    Icon,
    Product,
    ProductExtra,
}

impl SitePicSlot {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Icon => "icon",
            Self::Product => "product",
            Self::ProductExtra => "product_extra",
        }
    }
}

pub fn site_pic_parse_slot(raw: &str) -> Option<SitePicSlot> {
    match raw.trim().to_ascii_lowercase().as_str() {
        "icon" => Some(SitePicSlot::Icon),
        "product" => Some(SitePicSlot::Product),
        "product_extra" => Some(SitePicSlot::ProductExtra),
        _ => None,
    }
}

fn mentions_extra_photo(user_text: &str, args_text: &str) -> bool {
    let user = user_text.to_lowercase();
    let args = args_text.to_lowercase();
    user.contains("foto tambahan")
        || user.contains("more photos")
        || args.contains("foto tambahan")
        || args.contains("more photos")
}

/// Slot when the model omitted `slot`.
/// Extra-photo wording wins, then a product query or a single product match, else the site icon.
pub fn site_pic_choose_slot(
    slot_arg: &str,
    user_text: &str,
    args_text: &str,
    product_query: &str,
    one_product: bool,
) -> SitePicSlot {
    if let Some(slot) = site_pic_parse_slot(slot_arg) {
        return slot;
    }
    if mentions_extra_photo(user_text, args_text) {
        return SitePicSlot::ProductExtra;
    }
    if !product_query.trim().is_empty() || one_product {
        return SitePicSlot::Product;
    }
    SitePicSlot::Icon
}

/// English scene prompt. Empty when the trimmed name is empty.
pub fn site_pic_default_prompt(slot: SitePicSlot, name: &str, desc: &str) -> String {
    let name = name.trim();
    if name.is_empty() {
        return String::new();
    }
    let desc = desc.trim();
    match slot {
        SitePicSlot::Product | SitePicSlot::ProductExtra => {
            if desc.is_empty() {
                format!(
                    "Photorealistic product photo of {name}, studio lighting, centered, plain background, no text, no logo, no watermark"
                )
            } else {
                format!(
                    "Photorealistic product photo of {name}, {desc}, studio lighting, centered, plain background, no text, no logo, no watermark"
                )
            }
        }
        SitePicSlot::Icon => {
            if desc.is_empty() {
                format!(
                    "Simple app icon of {name}, flat graphic mark, centered, plain background, no text, no letters, no watermark"
                )
            } else {
                format!(
                    "Simple app icon of {name}, {desc}, flat graphic mark, centered, plain background, no text, no letters, no watermark"
                )
            }
        }
    }
}

/// Model `prompt` wins. Otherwise the slot template (possibly empty).
pub fn site_pic_resolve_prompt(given: &str, slot: SitePicSlot, name: &str, desc: &str) -> String {
    let given = given.trim();
    if !given.is_empty() {
        return given.to_string();
    }
    site_pic_default_prompt(slot, name, desc)
}

pub fn site_pic_storage_path(hash: &str) -> String {
    format!("/fs/{hash}")
}

/// Append `path` to `product_json.pics`. Skip the primary pic and duplicates.
pub fn site_pic_append_extra(product_json: &Value, primary_pic: &str, path: &str) -> Value {
    let mut map: Map<String, Value> = match product_json {
        Value::Object(obj) => obj.clone(),
        _ => Map::new(),
    };
    let mut pics: Vec<String> = map
        .get("pics")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str())
                .map(str::trim)
                .filter(|s| !s.is_empty() && *s != primary_pic)
                .map(str::to_string)
                .collect()
        })
        .unwrap_or_default();
    if !path.is_empty() && path != primary_pic && !pics.iter().any(|p| p == path) {
        pics.push(path.to_string());
    }
    map.insert(
        "pics".to_string(),
        Value::Array(pics.into_iter().map(Value::String).collect()),
    );
    Value::Object(map)
}

fn site_iid_resolve(ctx: &ToolContext, args: &Value) -> Result<i64> {
    let args_site = json_device_iid_field(args, "site_iid");
    mention_site_iid_resolve(
        &ctx.mention,
        ctx.site_iid,
        (args_site > 0).then_some(args_site),
    )
}

fn arg_text(args: &Value, key: &str) -> String {
    args.get(key)
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .trim()
        .to_string()
}

fn provider_arg(raw: &str) -> String {
    match raw.trim().to_ascii_lowercase().as_str() {
        "auto" | "gemini" | "grok" => raw.trim().to_ascii_lowercase(),
        _ => String::new(),
    }
}

struct ProductPicRow {
    product_id: i64,
    name: String,
    desc: String,
    pic: String,
    product_json: Value,
}

fn product_name_mentioned(name: &str, user_text: &str) -> bool {
    let name = name.trim();
    if name.chars().count() < 2 {
        return false;
    }
    user_text.to_lowercase().contains(&name.to_lowercase())
}

/// Drop a shorter catalog name when a longer matched name already contains it.
fn narrow_specific_names(rows: Vec<ProductPicRow>) -> Vec<ProductPicRow> {
    let lowered: Vec<String> = rows.iter().map(|r| r.name.trim().to_lowercase()).collect();
    rows.into_iter()
        .enumerate()
        .filter(|(i, _)| {
            let name = lowered[*i].as_str();
            if name.is_empty() {
                return false;
            }
            !lowered.iter().enumerate().any(|(j, other)| {
                j != *i && other.chars().count() > name.chars().count() && other.contains(name)
            })
        })
        .map(|(_, row)| row)
        .collect()
}

fn row_from_sql(row: &sqlx::postgres::PgRow) -> ProductPicRow {
    ProductPicRow {
        product_id: row.get("product_id"),
        name: row.get("name"),
        desc: row.get("desc"),
        pic: row.get("pic"),
        product_json: row.get("product_json"),
    }
}

async fn load_products(
    pool: &sqlx::PgPool,
    site_iid: i64,
    product_query: &str,
    user_text: &str,
) -> Result<Vec<ProductPicRow>> {
    let query = product_query.trim();
    if !query.is_empty() {
        let rows = sqlx::query(
            r#"
            SELECT product_id, name, "desc", pic, product_json
            FROM site.product
            WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = false
              AND (name ILIKE ('%' || $2 || '%') OR sku ILIKE ('%' || $2 || '%'))
            ORDER BY CASE WHEN name ILIKE $2 THEN 0 ELSE 1 END, sort_order, product_id
            LIMIT 20
            "#,
        )
        .bind(site_iid)
        .bind(query)
        .fetch_all(pool)
        .await?;
        return Ok(rows.iter().map(row_from_sql).collect());
    }
    let rows = sqlx::query(
        r#"
        SELECT product_id, name, "desc", pic, product_json
        FROM site.product
        WHERE site_iid = $1 AND deleted_ts IS NULL AND is_archived = false
        ORDER BY sort_order, product_id
        LIMIT 200
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    let mentioned: Vec<ProductPicRow> = rows
        .iter()
        .map(row_from_sql)
        .filter(|r| product_name_mentioned(&r.name, user_text))
        .collect();
    Ok(narrow_specific_names(mentioned))
}

fn classify_rows(rows: &[ProductPicRow]) -> ProductMatch {
    let hits = rows
        .iter()
        .map(|r| ProductHit {
            site_iid: 0,
            product_id: r.product_id,
            name: r.name.clone(),
            price: 0,
        })
        .collect();
    product_match_classify(hits)
}

async fn site_icon_subject(pool: &sqlx::PgPool, site_iid: i64) -> Result<(String, String)> {
    let name: String = sqlx::query_scalar(
        "SELECT COALESCE(name, '') FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .unwrap_or_default();
    let tagline: String = sqlx::query_scalar(
        r#"
        SELECT COALESCE(NULLIF(btrim(doc_json->'meta'->>'tagline'), ''), '')
        FROM site.draft
        WHERE site_iid = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .unwrap_or_default();
    Ok((name, tagline))
}

fn ambiguous_json(site_iid: i64, slot: SitePicSlot, rows: &[ProductPicRow]) -> Value {
    json!({
        "ok": false,
        "ambiguous": true,
        "slot": slot.as_str(),
        "site_iid": site_iid,
        "matches": rows.iter().map(|r| json!({
            "product_id": r.product_id,
            "name": r.name,
        })).collect::<Vec<_>>(),
    })
}

pub async fn site_pic_generate_exec(ctx: &ToolContext, args: &Value) -> Result<Value> {
    let site_iid = site_iid_resolve(ctx, args)?;
    let _owner = site_grant_owner(&ctx.pool, ctx.owner_iid, site_iid).await?;

    let given_prompt = arg_text(args, "prompt");
    let slot_arg = arg_text(args, "slot");
    let product_query = arg_text(args, "product_query");
    let provider = provider_arg(&arg_text(args, "provider"));
    let args_text = args.to_string();

    let explicit = site_pic_parse_slot(&slot_arg);
    let rows = if explicit == Some(SitePicSlot::Icon) {
        Vec::new()
    } else {
        load_products(&ctx.pool, site_iid, &product_query, &ctx.user_text).await?
    };
    let classified = classify_rows(&rows);
    let one_product = matches!(classified, ProductMatch::One(_));
    let slot = site_pic_choose_slot(
        &slot_arg,
        &ctx.user_text,
        &args_text,
        &product_query,
        one_product,
    );

    let (product_id, name, desc, primary_pic, product_json) = match slot {
        SitePicSlot::Icon => {
            let (name, desc) = site_icon_subject(&ctx.pool, site_iid).await?;
            (0_i64, name, desc, String::new(), Value::Null)
        }
        SitePicSlot::Product | SitePicSlot::ProductExtra => match &classified {
            ProductMatch::None => bail!("product not found"),
            ProductMatch::Many(_) => return Ok(ambiguous_json(site_iid, slot, &rows)),
            ProductMatch::One(hit) => {
                let row = rows
                    .iter()
                    .find(|r| r.product_id == hit.product_id)
                    .ok_or_else(|| anyhow!("product not found"))?;
                (
                    row.product_id,
                    row.name.clone(),
                    row.desc.clone(),
                    row.pic.clone(),
                    row.product_json.clone(),
                )
            }
        },
    };

    let prompt = site_pic_resolve_prompt(&given_prompt, slot, &name, &desc);
    if prompt.trim().is_empty() {
        bail!("image prompt cannot be empty");
    }

    let image = asset_image_generate(
        &ctx.pool,
        ctx.owner_iid,
        &ctx.http_client,
        &prompt,
        &provider,
    )
    .await?;
    let pic = site_pic_storage_path(&image.hash);

    match slot {
        SitePicSlot::Icon => {
            let updated = sqlx::query(
                "UPDATE ai.identity SET pic = $1, updated_ts = NOW() WHERE id = $2 AND deleted_ts IS NULL",
            )
            .bind(&pic)
            .bind(site_iid)
            .execute(&ctx.pool)
            .await?;
            if updated.rows_affected() == 0 {
                bail!("site not found");
            }
        }
        SitePicSlot::Product => {
            let updated = sqlx::query(
                r#"
                UPDATE site.product
                SET pic = $1, updated_ts = NOW()
                WHERE site_iid = $2 AND product_id = $3 AND deleted_ts IS NULL
                "#,
            )
            .bind(&pic)
            .bind(site_iid)
            .bind(product_id)
            .execute(&ctx.pool)
            .await?;
            if updated.rows_affected() == 0 {
                bail!("product not found");
            }
        }
        SitePicSlot::ProductExtra => {
            let next = site_pic_append_extra(&product_json, &primary_pic, &pic);
            let updated = sqlx::query(
                r#"
                UPDATE site.product
                SET product_json = $1::jsonb, updated_ts = NOW()
                WHERE site_iid = $2 AND product_id = $3 AND deleted_ts IS NULL
                "#,
            )
            .bind(next.to_string())
            .bind(site_iid)
            .bind(product_id)
            .execute(&ctx.pool)
            .await?;
            if updated.rows_affected() == 0 {
                bail!("product not found");
            }
        }
    }

    Ok(json!({
        "ok": true,
        "slot": slot.as_str(),
        "site_iid": site_iid,
        "product_id": product_id,
        "hash": image.hash,
        "url": image.url,
        "pic": pic,
    }))
}

tool! {
    struct: SitePicGenerateTool,
    name: "site.pic.generate",
    aliases: ["site_pic_generate", "site.pic_generate"],
    description: "Generate a square picture and save it on the mentioned site. Slot icon sets the site icon. Slot product replaces the product photo. Slot product_extra appends an extra product photo. Pass an English visual prompt, or omit prompt to build one from the site or product name and description.",
    topics: ["site", "image"],
    ui_calling_key: "tool.site.pic.generate.calling",
    ui_done_key: "tool.site.pic.generate.done",
    parameters: {
        prompt: (string, "English visual prompt. When empty, built from the site or product name and description.", optional),
        slot: (string, "icon, product, or product_extra. Empty: extra-photo wording, else a product match, else the site icon.", optional),
        product_query: (string, "Product name or sku to match when the slot is product or product_extra.", optional),
        provider: (string, "Image provider: auto, gemini, or grok. Empty follows the user generation.image preference.", optional),
    },
    execute: |args, ctx| {
        site_pic_generate_exec(ctx, &args).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const PRODUCT_NAME: &str =
        "Photorealistic product photo of es teh, studio lighting, centered, plain background, no text, no logo, no watermark";
    const PRODUCT_DESC: &str =
        "Photorealistic product photo of es teh, teh manis dalam gelas plastik, studio lighting, centered, plain background, no text, no logo, no watermark";
    const ICON_NAME: &str =
        "Simple app icon of testing, flat graphic mark, centered, plain background, no text, no letters, no watermark";
    const ICON_DESC: &str =
        "Simple app icon of testing, warung teh, flat graphic mark, centered, plain background, no text, no letters, no watermark";

    #[test]
    fn site_pic_prompt_product_name_only() {
        assert_eq!(
            site_pic_default_prompt(SitePicSlot::Product, "es teh", ""),
            PRODUCT_NAME
        );
    }

    #[test]
    fn site_pic_prompt_product_name_and_desc() {
        assert_eq!(
            site_pic_default_prompt(
                SitePicSlot::Product,
                "es teh",
                "teh manis dalam gelas plastik"
            ),
            PRODUCT_DESC
        );
    }

    #[test]
    fn site_pic_prompt_product_extra_matches_product() {
        assert_eq!(
            site_pic_default_prompt(SitePicSlot::ProductExtra, "es teh", ""),
            PRODUCT_NAME
        );
        assert_eq!(
            site_pic_default_prompt(
                SitePicSlot::ProductExtra,
                "es teh",
                "teh manis dalam gelas plastik"
            ),
            PRODUCT_DESC
        );
    }

    #[test]
    fn site_pic_prompt_icon_name_only() {
        assert_eq!(
            site_pic_default_prompt(SitePicSlot::Icon, "testing", ""),
            ICON_NAME
        );
    }

    #[test]
    fn site_pic_prompt_icon_name_and_desc() {
        assert_eq!(
            site_pic_default_prompt(SitePicSlot::Icon, "testing", "warung teh"),
            ICON_DESC
        );
    }

    #[test]
    fn site_pic_prompt_empty_name() {
        assert_eq!(
            site_pic_default_prompt(SitePicSlot::Product, "   ", "x"),
            ""
        );
        assert_eq!(site_pic_default_prompt(SitePicSlot::Icon, "", "x"), "");
    }

    #[test]
    fn site_pic_prompt_whitespace_desc_is_empty() {
        assert_eq!(
            site_pic_default_prompt(SitePicSlot::Product, "es teh", "   "),
            PRODUCT_NAME
        );
        assert_eq!(
            site_pic_default_prompt(SitePicSlot::Icon, "testing", " \n "),
            ICON_NAME
        );
    }

    #[test]
    fn site_pic_prompt_given_skips_template() {
        assert_eq!(
            site_pic_resolve_prompt("a red cup", SitePicSlot::Product, "es teh", ""),
            "a red cup"
        );
        assert_eq!(
            site_pic_resolve_prompt("  ", SitePicSlot::Product, "es teh", ""),
            PRODUCT_NAME
        );
    }

    #[test]
    fn site_pic_slot_empty_text_no_product_is_icon() {
        assert_eq!(
            site_pic_choose_slot("", "buatkan gambar untuk", "", "", false),
            SitePicSlot::Icon
        );
    }

    #[test]
    fn site_pic_slot_product_query_is_product() {
        assert_eq!(
            site_pic_choose_slot("", "buatkan gambar", "", "es teh", false),
            SitePicSlot::Product
        );
    }

    #[test]
    fn site_pic_slot_foto_tambahan_is_product_extra() {
        assert_eq!(
            site_pic_choose_slot("", "tambah foto tambahan es teh", "", "es teh", true),
            SitePicSlot::ProductExtra
        );
    }

    #[test]
    fn site_pic_append_extra_skips_primary_and_dupes() {
        let start = json!({"pics": ["/fs/a", "/fs/primary"], "sku": "x"});
        let once = site_pic_append_extra(&start, "/fs/primary", "/fs/b");
        assert_eq!(once["pics"], json!(["/fs/a", "/fs/b"]));
        assert_eq!(once["sku"], "x");
        let twice = site_pic_append_extra(&once, "/fs/primary", "/fs/b");
        assert_eq!(twice["pics"], json!(["/fs/a", "/fs/b"]));
        let same = site_pic_append_extra(&once, "/fs/primary", "/fs/primary");
        assert_eq!(same["pics"], json!(["/fs/a", "/fs/b"]));
    }
}
