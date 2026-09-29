use anyhow::{anyhow, Result};
use c35_proto::{
    ReqSiteContactList, ReqSiteContactPut, ResSiteContactList, ResSiteContactPut, SiteContact,
    sync_push,
};
use sqlx::PgPool;
use tokio::sync::mpsc;

use crate::grant::site_grant_check;
use crate::rows::contact_from_row;
use crate::sync_push::site_sync_push;
use c35_proto::WsRes;
use c35_store::snowflake_id;

pub async fn site_contact_list(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteContactList,
) -> Result<ResSiteContactList> {
    let _ = site_grant_check(pool, caller_iid, req.site_iid, false).await?;
    let q = req.q.trim();
    let rows = if q.is_empty() {
        sqlx::query(
            r#"
            SELECT site_iid, contact_id, name, phone, email, address, note,
                   meta_json, is_archived, created_ts, updated_ts, deleted_ts
            FROM site.contact
            WHERE site_iid = $1 AND deleted_ts IS NULL
            ORDER BY name
            "#,
        )
        .bind(req.site_iid)
        .fetch_all(pool)
        .await?
    } else {
        sqlx::query(
            r#"
            SELECT site_iid, contact_id, name, phone, email, address, note,
                   meta_json, is_archived, created_ts, updated_ts, deleted_ts
            FROM site.contact
            WHERE site_iid = $1 AND deleted_ts IS NULL
              AND (name ILIKE $2 OR phone ILIKE $2 OR email ILIKE $2)
            ORDER BY name
            "#,
        )
        .bind(req.site_iid)
        .bind(format!("%{}%", q))
        .fetch_all(pool)
        .await?
    };
    Ok(ResSiteContactList {
        contacts: rows.iter().map(contact_from_row).collect(),
    })
}

pub async fn site_contact_upsert(
    pool: &PgPool,
    owner_iid: i64,
    site_iid: i64,
    contact: &SiteContact,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<i64> {
    let contact_id = if contact.contact_id > 0 {
        contact.contact_id
    } else {
        snowflake_id()
    };
    let meta_json: serde_json::Value = if contact.meta_json.is_empty() {
        serde_json::json!({})
    } else {
        serde_json::from_str(&contact.meta_json).unwrap_or(serde_json::json!({}))
    };
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        INSERT INTO site.contact (
            site_iid, contact_id, owner_iid, name, phone, email, address, note,
            meta_json, is_archived, created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())
        ON CONFLICT (site_iid, contact_id) DO UPDATE SET
          name = EXCLUDED.name, phone = EXCLUDED.phone, email = EXCLUDED.email,
          address = EXCLUDED.address, note = EXCLUDED.note, meta_json = EXCLUDED.meta_json,
          is_archived = EXCLUDED.is_archived, updated_ts = NOW(), deleted_ts = NULL
        "#,
    )
    .bind(site_iid)
    .bind(contact_id)
    .bind(owner_iid)
    .bind(&contact.name)
    .bind(&contact.phone)
    .bind(&contact.email)
    .bind(&contact.address)
    .bind(&contact.note)
    .bind(meta_json)
    .bind(contact.is_archived)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    if let Some(tx) = out_tx {
        site_sync_push(
            tx,
            sync_push::Body::SiteContact(SiteContact {
                site_iid,
                contact_id,
                ..contact.clone()
            }),
        );
    }
    Ok(contact_id)
}

pub async fn site_contact_put(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSiteContactPut,
    out_tx: Option<&mpsc::UnboundedSender<WsRes>>,
) -> Result<ResSiteContactPut> {
    let contact = req
        .contact
        .ok_or_else(|| anyhow!("contact required"))?;
    let site_iid = req.site_iid;
    let owner_iid = site_grant_check(pool, caller_iid, site_iid, true).await?;
    let contact_id =
        site_contact_upsert(pool, owner_iid, site_iid, &contact, out_tx).await?;
    Ok(ResSiteContactPut { contact_id })
}

pub async fn guest_contact_put(
    pool: &PgPool,
    req: c35_proto::ReqSiteGuestContactPut,
) -> Result<c35_proto::ResSiteGuestContactPut> {
    let site_iid = req.site_iid;
    let name = req.name.trim();
    let contact_val = req.contact_val.trim();
    let message = req.message.trim();

    if site_iid == 0 {
        return Ok(c35_proto::ResSiteGuestContactPut {
            ok: false,
            contact_id: 0,
            error: "site_iid is required".into(),
        });
    }
    if name.is_empty() && contact_val.is_empty() && message.is_empty() {
        return Ok(c35_proto::ResSiteGuestContactPut {
            ok: false,
            contact_id: 0,
            error: "name or contact info is required".into(),
        });
    }

    let owner_iid: Option<i64> = sqlx::query_scalar("SELECT owner_iid FROM ai.identity WHERE id = $1 AND deleted_ts IS NULL")
        .bind(site_iid)
        .fetch_optional(pool)
        .await?;
    let owner_iid = owner_iid.unwrap_or(site_iid);

    let is_email = contact_val.contains('@');
    let phone = if is_email { "" } else { contact_val };
    let email = if is_email { contact_val } else { "" };
    let contact_id = snowflake_id();
    let meta = serde_json::json!({
        "source": "guest_form",
        "raw_contact": contact_val,
        "message": message,
    });

    sqlx::query(
        r#"
        INSERT INTO site.contact (
            site_iid, contact_id, owner_iid, name, phone, email, address, note,
            meta_json, is_archived, created_ts, updated_ts
        ) VALUES ($1, $2, $3, $4, $5, $6, '', $7, $8, FALSE, NOW(), NOW())
        "#,
    )
    .bind(site_iid)
    .bind(contact_id)
    .bind(owner_iid)
    .bind(if name.is_empty() { "Guest Lead" } else { name })
    .bind(phone)
    .bind(email)
    .bind(message)
    .bind(meta)
    .execute(pool)
    .await?;

    Ok(c35_proto::ResSiteGuestContactPut {
        ok: true,
        contact_id,
        error: String::new(),
    })
}

