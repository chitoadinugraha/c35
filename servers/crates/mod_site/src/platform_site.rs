//! Reserved platform site `alienai` (owner 99000) and public home JSON.

use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use serde_json::{json, Value};
use sqlx::{PgPool, Row};

use crate::guest_product::pic_url;
use c35_store::snowflake_id;

pub const PLATFORM_SITE_ALIEN_ID: &str = "alienai";
pub const PLATFORM_SITE_OWNER_IID: i64 = 99000;
pub const PLATFORM_HOME_POST_CAP: usize = 12;

pub fn platform_site_alien_id_is(raw: &str) -> bool {
    raw.trim().eq_ignore_ascii_case(PLATFORM_SITE_ALIEN_ID)
}

/// `site_handle_put`: lock the platform handle, and refuse giving it to any other site.
pub fn platform_site_handle_assign_check(current_alien_id: &str, new_alien_id: &str) -> Result<()> {
    if platform_site_alien_id_is(current_alien_id) {
        bail!("platform site handle is locked");
    }
    if platform_site_alien_id_is(new_alien_id) {
        bail!("handle is reserved");
    }
    Ok(())
}

/// `identity_put` create/update. `existing_alien_id` is `None` on create.
/// Empty `requested` keeps the current handle (identity_put no-op) and is allowed.
pub fn platform_site_identity_put_check(
    requested_alien_id: &str,
    existing_alien_id: Option<&str>,
) -> Result<()> {
    let requested_platform = platform_site_alien_id_is(requested_alien_id);
    let existing_platform = existing_alien_id.is_some_and(platform_site_alien_id_is);
    if existing_platform && !requested_alien_id.is_empty() && !requested_platform {
        bail!("platform site handle is locked");
    }
    if requested_platform && !existing_platform {
        bail!("handle is reserved");
    }
    Ok(())
}

#[derive(Clone, Debug)]
pub struct PlatformHomePost {
    pub post_id: i64,
    pub title: String,
    pub caption: String,
    pub body: String,
    pub thumb: String,
    pub created_ts: String,
    pub on_storefront: bool,
}

#[derive(Clone, Debug)]
pub struct PlatformHomeContact {
    pub contact_id: i64,
    pub name: String,
    pub pic: String,
    pub url: String,
    pub featured: String,
    pub archived: bool,
}

#[derive(Clone, Debug)]
pub struct PlatformHomeLink {
    pub link_id: i64,
    pub label: String,
    pub url: String,
    pub icon: String,
    pub active: bool,
}

pub fn platform_home_empty() -> Value {
    json!({
        "alien_id": PLATFORM_SITE_ALIEN_ID,
        "posts": [],
        "partners": [],
        "clients": [],
        "links": [],
    })
}

/// Group live rows into the public home document. Preserves input order.
pub fn platform_home_assemble(
    posts: &[PlatformHomePost],
    contacts: &[PlatformHomeContact],
    links: &[PlatformHomeLink],
) -> Value {
    let posts: Vec<Value> = posts
        .iter()
        .filter(|p| p.on_storefront)
        .take(PLATFORM_HOME_POST_CAP)
        .map(|p| {
            json!({
                "post_id": p.post_id,
                "title": p.title,
                "caption": p.caption,
                "body": p.body,
                "thumb": p.thumb,
                "created_ts": p.created_ts,
            })
        })
        .collect();

    let mut partners = Vec::new();
    let mut clients = Vec::new();
    for c in contacts {
        if c.archived {
            continue;
        }
        let item = json!({
            "contact_id": c.contact_id,
            "name": c.name,
            "pic": c.pic,
            "url": c.url,
        });
        match c.featured.as_str() {
            "partners" => partners.push(item),
            "clients" => clients.push(item),
            _ => {}
        }
    }

    let links: Vec<Value> = links
        .iter()
        .filter(|l| l.active)
        .map(|l| {
            json!({
                "link_id": l.link_id,
                "label": l.label,
                "url": l.url,
                "icon": l.icon,
            })
        })
        .collect();

    json!({
        "alien_id": PLATFORM_SITE_ALIEN_ID,
        "posts": posts,
        "partners": partners,
        "clients": clients,
        "links": links,
    })
}

async fn upsert_owner_grant(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    site_iid: i64,
) -> Result<()> {
    sqlx::query(
        r#"
        INSERT INTO ai.identity_grant (id, resource_iid, grantee_iid, role, permissions, is_pinned, meta, created_ts, updated_ts)
        VALUES ($1, $2, $3, 'owner', '{}', false, '{}', NOW(), NOW())
        ON CONFLICT (resource_iid, grantee_iid) DO UPDATE SET
            role = 'owner',
            deleted_ts = NULL,
            updated_ts = NOW()
        "#,
    )
    .bind(snowflake_id())
    .bind(site_iid)
    .bind(PLATFORM_SITE_OWNER_IID)
    .execute(&mut **tx)
    .await?;
    Ok(())
}

/// Create the platform site when missing. Does not take `alienai` from another owner.
pub async fn platform_site_ensure(pool: &PgPool) -> Result<()> {
    let row = sqlx::query(
        r#"
        SELECT id, owner_iid
        FROM ai.identity
        WHERE kind = 'site'
          AND lower(alien_id) = lower($1)
          AND deleted_ts IS NULL
        "#,
    )
    .bind(PLATFORM_SITE_ALIEN_ID)
    .fetch_optional(pool)
    .await?;

    if let Some(row) = row {
        let site_iid: i64 = row.get("id");
        let owner_iid: Option<i64> = row.get("owner_iid");
        if owner_iid != Some(PLATFORM_SITE_OWNER_IID) {
            let owner = owner_iid.unwrap_or(0);
            bail!("platform site handle alienai is owned by {owner}; not stealing");
        }
        let mut tx = pool.begin().await?;
        upsert_owner_grant(&mut tx, site_iid).await?;
        tx.commit().await?;
        return Ok(());
    }

    let owner_exists: bool = sqlx::query_scalar(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM ai.identity
            WHERE id = $1 AND kind = 'user' AND deleted_ts IS NULL
        )
        "#,
    )
    .bind(PLATFORM_SITE_OWNER_IID)
    .fetch_one(pool)
    .await?;
    if !owner_exists {
        bail!("platform site owner 99000 not found");
    }

    let site_iid = snowflake_id();
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO ai.identity (id, kind, type, alien_id, name, owner_iid, meta, created_ts, updated_ts)
        VALUES ($1, 'site', 'web', $2, 'Alien AI', $3, '{}', NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(PLATFORM_SITE_ALIEN_ID)
    .bind(PLATFORM_SITE_OWNER_IID)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO site.config (site_iid, owner_iid, tz, created_ts, updated_ts)
        VALUES ($1, $2, 'Asia/Jakarta', NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(PLATFORM_SITE_OWNER_IID)
    .execute(&mut *tx)
    .await?;
    sqlx::query(
        r#"
        INSERT INTO site.draft (site_iid, owner_iid, doc_json, created_ts, updated_ts)
        VALUES ($1, $2, $3, NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(PLATFORM_SITE_OWNER_IID)
    .bind(json!({"pages": [], "theme": {}, "meta": {}}))
    .execute(&mut *tx)
    .await?;
    upsert_owner_grant(&mut tx, site_iid).await?;
    tx.commit().await?;
    Ok(())
}

fn contact_url(meta: &Value) -> String {
    meta.get("url")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string()
}

fn contact_pic(meta: &Value) -> String {
    let raw = meta
        .get("pic")
        .or_else(|| meta.get("avatar"))
        .and_then(|v| v.as_str())
        .unwrap_or("");
    pic_url(raw)
}

pub async fn platform_home_payload(pool: &PgPool) -> Result<Value> {
    let site_iid: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.identity
        WHERE kind = 'site'
          AND lower(alien_id) = lower($1)
          AND owner_iid = $2
          AND deleted_ts IS NULL
        "#,
    )
    .bind(PLATFORM_SITE_ALIEN_ID)
    .bind(PLATFORM_SITE_OWNER_IID)
    .fetch_optional(pool)
    .await?;
    let Some(site_iid) = site_iid else {
        return Ok(platform_home_empty());
    };

    let post_rows = sqlx::query(
        r#"
        SELECT post_id, title, caption, body, thumb, created_ts
        FROM site.post
        WHERE site_iid = $1
          AND deleted_ts IS NULL
          AND on_storefront = TRUE
        ORDER BY sort_order, post_id DESC
        LIMIT $2
        "#,
    )
    .bind(site_iid)
    .bind(PLATFORM_HOME_POST_CAP as i32)
    .fetch_all(pool)
    .await?;
    let posts = post_rows
        .iter()
        .map(|r| {
            let created: DateTime<Utc> = r.get("created_ts");
            PlatformHomePost {
                post_id: r.get("post_id"),
                title: r.get("title"),
                caption: r.get("caption"),
                body: r.get("body"),
                thumb: pic_url(&r.get::<String, _>("thumb")),
                created_ts: created.to_rfc3339(),
                on_storefront: true,
            }
        })
        .collect::<Vec<_>>();

    let contact_rows = sqlx::query(
        r#"
        SELECT contact_id, name, meta_json
        FROM site.contact
        WHERE site_iid = $1
          AND deleted_ts IS NULL
          AND is_archived = FALSE
          AND meta_json->>'featured' IN ('partners', 'clients')
        ORDER BY name
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    let contacts = contact_rows
        .iter()
        .map(|r| {
            let meta: Value = r.get("meta_json");
            let featured = meta
                .get("featured")
                .and_then(|v| v.as_str())
                .unwrap_or("")
                .to_string();
            PlatformHomeContact {
                contact_id: r.get("contact_id"),
                name: r.get("name"),
                pic: contact_pic(&meta),
                url: contact_url(&meta),
                featured,
                archived: false,
            }
        })
        .collect::<Vec<_>>();

    let link_rows = sqlx::query(
        r#"
        SELECT link_id, label, url, icon
        FROM site.link
        WHERE site_iid = $1
          AND deleted_ts IS NULL
          AND active = TRUE
        ORDER BY sort_order, link_id
        "#,
    )
    .bind(site_iid)
    .fetch_all(pool)
    .await?;
    let links = link_rows
        .iter()
        .map(|r| PlatformHomeLink {
            link_id: r.get("link_id"),
            label: r.get("label"),
            url: r.get("url"),
            icon: r.get("icon"),
            active: true,
        })
        .collect::<Vec<_>>();

    Ok(platform_home_assemble(&posts, &contacts, &links))
}
