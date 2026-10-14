//! Guest member portal — `site.customer` rows (shopper Alien user per site).

use anyhow::{anyhow, Result};
use c35_proto::SiteContact;
use sqlx::{PgPool, Row};

use crate::site_contact::site_contact_upsert;
use crate::site_publish::site_published;

pub async fn site_member_portal_enabled(pool: &PgPool, site_iid: i64) -> bool {
    let caps = crate::site_config::site_capabilities_get(pool, site_iid).await;
    crate::site_config::site_member_portal_enabled(&caps)
}

pub async fn site_customer_upsert(pool: &PgPool, site_iid: i64, user_iid: i64) -> Result<i64> {
    if site_iid <= 0 || user_iid <= 0 {
        return Err(anyhow!("site_iid and user_iid required"));
    }
    if !site_published(pool, site_iid).await? {
        return Err(anyhow!("site not published"));
    }
    let owner_iid: i64 = sqlx::query_scalar(
        r#"SELECT owner_iid FROM ai.identity WHERE id = $1 AND kind = 'site' AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("site not found"))?;

    let existing: Option<i64> = sqlx::query_scalar(
        r#"SELECT contact_id FROM site.customer WHERE site_iid = $1 AND user_iid = $2 AND deleted_ts IS NULL"#,
    )
    .bind(site_iid)
    .bind(user_iid)
    .fetch_optional(pool)
    .await?;

    let contact_id = if let Some(cid) = existing {
        if cid > 0 {
            cid
        } else {
            site_customer_contact_create(pool, owner_iid, site_iid, user_iid).await?
        }
    } else {
        let cid = site_customer_contact_create(pool, owner_iid, site_iid, user_iid).await?;
        sqlx::query(
            r#"
            INSERT INTO site.customer (site_iid, user_iid, contact_id, created_ts, updated_ts)
            VALUES ($1, $2, $3, NOW(), NOW())
            ON CONFLICT (site_iid, user_iid) DO UPDATE SET
              contact_id = EXCLUDED.contact_id, updated_ts = NOW(), deleted_ts = NULL
            "#,
        )
        .bind(site_iid)
        .bind(user_iid)
        .bind(cid)
        .execute(pool)
        .await?;
        cid
    };

    Ok(contact_id)
}

async fn site_customer_contact_create(
    pool: &PgPool,
    owner_iid: i64,
    site_iid: i64,
    user_iid: i64,
) -> Result<i64> {
    let row = sqlx::query(
        r#"
        SELECT i.name, COALESCE(p.identifier, '') AS email
        FROM ai.identity i
        LEFT JOIN LATERAL (
            SELECT identifier FROM ai.identity_provider p
            WHERE p.identity_iid = i.id AND p.kind = 'email' AND p.deleted_ts IS NULL
              AND btrim(p.identifier) <> ''
            ORDER BY p.is_primary DESC, p.updated_ts DESC LIMIT 1
        ) p ON TRUE
        WHERE i.id = $1 AND i.deleted_ts IS NULL
        "#,
    )
    .bind(user_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("user not found"))?;

    let name: String = row.get("name");
    let email: String = row.get("email");

    if !email.trim().is_empty() {
        let matched: Option<i64> = sqlx::query_scalar(
            r#"
            SELECT contact_id FROM site.contact
            WHERE site_iid = $1 AND deleted_ts IS NULL AND lower(email) = lower($2)
            ORDER BY updated_ts DESC LIMIT 1
            "#,
        )
        .bind(site_iid)
        .bind(email.trim())
        .fetch_optional(pool)
        .await?;
        if let Some(cid) = matched {
            return Ok(cid);
        }
    }

    let contact = SiteContact {
        site_iid,
        contact_id: 0,
        name: name.trim().to_string(),
        email: email.trim().to_string(),
        meta_json: serde_json::json!({
            "source": "member_portal",
            "linked_user_iid": user_iid,
        })
        .to_string(),
        ..Default::default()
    };
    site_contact_upsert(pool, owner_iid, site_iid, &contact, None).await
}

pub struct SiteCustomerProfile {
    pub user_iid: i64,
    pub display_name: String,
    pub pic: String,
    pub email: String,
    pub contact_id: i64,
}

pub async fn site_customer_profile(
    pool: &PgPool,
    site_iid: i64,
    user_iid: i64,
) -> Result<SiteCustomerProfile> {
    let contact_id = site_customer_upsert(pool, site_iid, user_iid).await?;
    let row = sqlx::query(
        r#"
        SELECT i.name, COALESCE(i.pic, '') AS pic, COALESCE(p.identifier, '') AS email
        FROM ai.identity i
        LEFT JOIN LATERAL (
            SELECT identifier FROM ai.identity_provider p
            WHERE p.identity_iid = i.id AND p.kind = 'email' AND p.deleted_ts IS NULL
              AND btrim(p.identifier) <> ''
            ORDER BY p.is_primary DESC, p.updated_ts DESC LIMIT 1
        ) p ON TRUE
        WHERE i.id = $1 AND i.deleted_ts IS NULL
        "#,
    )
    .bind(user_iid)
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| anyhow!("user not found"))?;

    Ok(SiteCustomerProfile {
        user_iid,
        display_name: row.get::<String, _>("name"),
        pic: row.get("pic"),
        email: row.get("email"),
        contact_id,
    })
}
