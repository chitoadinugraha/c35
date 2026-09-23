use std::collections::HashMap;

use anyhow::{Context, Result};
use c35_proto::{HintAction, HintCatalog, HintItem};
use c35_store::missing_table;
use chrono::Utc;
use prost::Message;
use serde_json::json;
use sqlx::{PgPool, Row};
use tracing::warn;

struct HintRow {
    id: String,
    label_key: String,
    icon: String,
    action: String,
    send_text_key: String,
    inst_id: String,
    sort: i32,
}

struct SiteRow {
    site_iid: i64,
    alien_id: String,
    name: String,
    pic: String,
    capabilities_json: serde_json::Value,
}

pub async fn hint_bundle_get(
    pool: &PgPool,
    user_iid: i64,
    locale: &str,
    since_ms: i64,
) -> Result<HintCatalog> {
    let lang = locale_lang(locale);
    let row = sqlx::query(
        "SELECT updated_ts_ms, compiled_locale, body FROM ai.hint_bundle WHERE user_iid = $1",
    )
    .bind(user_iid)
    .fetch_optional(pool)
    .await;

    match row {
        Ok(Some(r)) => {
            let updated_ts_ms: i64 = r.get("updated_ts_ms");
            let compiled_locale: String = r.get("compiled_locale");
            let body: Vec<u8> = r.get("body");
            if compiled_locale == lang && updated_ts_ms > 0 && since_ms >= updated_ts_ms {
                return Ok(HintCatalog {
                    updated_ts_ms,
                    items: vec![],
                });
            }
            if compiled_locale == lang && !body.is_empty() {
                return HintCatalog::decode(body.as_slice()).context("hint_bundle decode");
            }
        }
        Ok(None) => {}
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "hint_bundle_get: ai.hint_bundle missing");
        }
        Err(e) => return Err(e.into()),
    }
    hint_bundle_compile(pool, user_iid, locale).await
}

pub async fn hint_bundle_compile(pool: &PgPool, user_iid: i64, locale: &str) -> Result<HintCatalog> {
    let lang = locale_lang(locale);
    let en = translation_get(pool, "en", &["hint"]).await;
    let tr_map = if lang == "en" {
        en.clone()
    } else {
        translation_get(pool, &lang, &["hint"]).await
    };
    let tr = |key: &str| -> String {
        tr_map
            .get(key)
            .or_else(|| en.get(key))
            .cloned()
            .unwrap_or_else(|| key.to_string())
    };

    let catalog_rows = hint_catalog_rows(pool).await?;
    let mut items: Vec<HintItem> = catalog_rows
        .iter()
        .map(|r| catalog_leaf_item(r, &tr))
        .collect();

    let sites = site_rows(pool, user_iid).await?;
    let (top, rest) = if sites.len() > 3 {
        sites.split_at(3)
    } else {
        (sites.as_slice(), &[][..])
    };
    for (idx, site) in top.iter().enumerate() {
        items.push(site_hint_item(site, &tr, 30 + idx as i32));
    }
    if !rest.is_empty() {
        items.push(HintItem {
            id: "hint.sites.more".into(),
            label: tr("hint.sites.more.label"),
            icon: "mdi:dots-horizontal".into(),
            sort: 90,
            action: None,
            items: rest
                .iter()
                .enumerate()
                .map(|(idx, site)| site_hint_item(site, &tr, idx as i32))
                .collect(),
        });
    }

    let updated_ts_ms = Utc::now().timestamp_millis();
    let catalog = HintCatalog {
        updated_ts_ms,
        items,
    };
    let body = catalog.encode_to_vec();
    if let Err(e) = sqlx::query(
        r#"
        INSERT INTO ai.hint_bundle (user_iid, updated_ts_ms, compiled_locale, body, created_ts, updated_ts)
        VALUES ($1, $2, $3, $4, NOW(), NOW())
        ON CONFLICT (user_iid) DO UPDATE SET
            updated_ts_ms = EXCLUDED.updated_ts_ms,
            compiled_locale = EXCLUDED.compiled_locale,
            body = EXCLUDED.body,
            updated_ts = NOW()
        "#,
    )
    .bind(user_iid)
    .bind(updated_ts_ms)
    .bind(&lang)
    .bind(&body)
    .execute(pool)
    .await
    {
        if !missing_table(&e) {
            return Err(e.into());
        }
        warn!(error = %e, "hint_bundle_compile: ai.hint_bundle missing");
    }
    Ok(catalog)
}

fn locale_lang(locale: &str) -> String {
    let s = locale.trim();
    if s.is_empty() {
        return "en".into();
    }
    let lower = s.to_lowercase();
    if lower.starts_with("id") {
        "id".into()
    } else {
        "en".into()
    }
}

async fn translation_get(pool: &PgPool, lang: &str, categories: &[&str]) -> HashMap<String, String> {
    let cats: Vec<String> = categories.iter().map(|s| s.to_string()).collect();
    let rows = sqlx::query_as::<_, (String, String)>(
        "SELECT key, text FROM ai.translation WHERE lang = $1 AND category = ANY($2) ORDER BY key ASC",
    )
    .bind(lang)
    .bind(&cats)
    .fetch_all(pool)
    .await;
    match rows {
        Ok(rows) => rows.into_iter().collect(),
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "translation_get: ai.translation missing");
            HashMap::new()
        }
        Err(e) => {
            warn!(error = %e, lang = %lang, "translation_get failed");
            HashMap::new()
        }
    }
}

async fn hint_catalog_rows(pool: &PgPool) -> Result<Vec<HintRow>> {
    let rows = sqlx::query(
        r#"
        SELECT id, label_key, icon, action, send_text_key, inst_id, sort
        FROM ai.hint
        WHERE enabled = true AND deleted_ts IS NULL AND scope = 'role:personal_assistant'
        ORDER BY sort ASC, id ASC
        "#,
    )
    .fetch_all(pool)
    .await;
    match rows {
        Ok(rows) => Ok(rows
            .iter()
            .map(|r| HintRow {
                id: r.get("id"),
                label_key: r.get("label_key"),
                icon: r.get("icon"),
                action: r.get("action"),
                send_text_key: r.get("send_text_key"),
                inst_id: r
                    .try_get::<Option<String>, _>("inst_id")
                    .ok()
                    .flatten()
                    .unwrap_or_default(),
                sort: r.get("sort"),
            })
            .collect()),
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "hint_catalog_rows: ai.hint missing");
            Ok(vec![])
        }
        Err(e) => Err(e.into()),
    }
}

fn catalog_leaf_item(r: &HintRow, tr: &dyn Fn(&str) -> String) -> HintItem {
    let send_text = tr(&r.send_text_key);
    let payload_json = if r.action == "send_text" {
        json!({
            "text": send_text,
            "inst_id": r.inst_id,
        })
        .to_string()
    } else if r.action == "pick_image" || r.action == "pick_file" {
        json!({
            "text": send_text,
            "inst_id": r.inst_id,
        })
        .to_string()
    } else if !r.inst_id.is_empty() {
        json!({ "inst_id": r.inst_id }).to_string()
    } else {
        String::new()
    };
    HintItem {
        id: r.id.clone(),
        label: tr(&r.label_key),
        icon: r.icon.clone(),
        sort: r.sort,
        action: Some(HintAction {
            kind: r.action.clone(),
            payload_json,
        }),
        items: vec![],
    }
}

async fn site_rows(pool: &PgPool, user_iid: i64) -> Result<Vec<SiteRow>> {
    let rows = sqlx::query(
        r#"
        SELECT i.id AS site_iid, i.alien_id, i.name, i.pic,
               COALESCE(c.capabilities_json, '{}'::jsonb) AS capabilities_json
        FROM ai.identity i
        LEFT JOIN site.config c ON c.site_iid = i.id AND c.deleted_ts IS NULL
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        LEFT JOIN ai.user_asset_touch t
          ON t.user_iid = $1 AND t.asset_iid = i.id AND t.deleted_ts IS NULL
        WHERE i.kind = 'site' AND i.deleted_ts IS NULL
          AND (i.owner_iid = $1 OR g.grantee_iid IS NOT NULL)
          AND COALESCE((g.meta->>'archived_ts_ms')::bigint, 0) = 0
        ORDER BY COALESCE(g.is_pinned, false) DESC,
                 t.last_accessed_ts DESC NULLS LAST,
                 i.name ASC
        "#,
    )
    .bind(user_iid)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .iter()
        .map(|r| SiteRow {
            site_iid: r.get("site_iid"),
            alien_id: r
                .try_get::<Option<String>, _>("alien_id")
                .ok()
                .flatten()
                .unwrap_or_default(),
            name: r.get("name"),
            pic: r
                .try_get::<Option<String>, _>("pic")
                .ok()
                .flatten()
                .unwrap_or_default(),
            capabilities_json: r.get("capabilities_json"),
        })
        .collect())
}

fn capability_enabled(caps: &serde_json::Value, key: &str) -> bool {
    caps.get(key).and_then(|v| v.as_bool()).unwrap_or(false)
}

fn site_visit_url(alien_id: &str, site_iid: i64) -> String {
    if !alien_id.is_empty() {
        format!("https://alienai.id/{alien_id}")
    } else {
        format!("https://alienai.id/{site_iid}")
    }
}

fn site_hint_item(site: &SiteRow, tr: &dyn Fn(&str) -> String, sort: i32) -> HintItem {
    let icon = if site.pic.is_empty() {
        "mdi:store".into()
    } else {
        site.pic.clone()
    };
    let mut children = vec![HintItem {
        id: format!("hint.site.{}.visit", site.site_iid),
        label: tr("hint.site.visit.label"),
        icon: String::new(),
        sort: 1,
        action: Some(HintAction {
            kind: "open_url".into(),
            payload_json: json!({
                "url": site_visit_url(&site.alien_id, site.site_iid),
                "site_iid": site.site_iid.to_string(),
                "asset_kind": "site",
            })
            .to_string(),
        }),
        items: vec![],
    }];
    if capability_enabled(&site.capabilities_json, "commerce") {
        children.push(HintItem {
            id: format!("hint.site.{}.pos", site.site_iid),
            label: tr("hint.site.pos.label"),
            icon: String::new(),
            sort: 2,
            action: Some(HintAction {
                kind: "navigate".into(),
                payload_json: json!({
                    "route": "site.pos",
                    "site_iid": site.site_iid.to_string(),
                    "asset_kind": "site",
                })
                .to_string(),
            }),
            items: vec![],
        });
    }
    HintItem {
        id: format!("hint.site:{}", site.site_iid),
        label: site.name.clone(),
        icon,
        sort,
        action: None,
        items: children,
    }
}
