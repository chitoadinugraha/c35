//! One-shot: ensure site_assistant bot + site.config.assistant_bot_iid for every active site.config row.
use anyhow::Result;
use c35_mod_site::site_assistant_ensure_bot;
use c35_store::pool_connect;
use sqlx::Row;

#[tokio::main]
async fn main() -> Result<()> {
    let pool = pool_connect().await?;
    let rows = sqlx::query(
        r#"
        SELECT sc.site_iid, sc.owner_iid
        FROM site.config sc
        INNER JOIN ai.identity i
          ON i.id = sc.site_iid AND i.kind = 'site' AND i.deleted_ts IS NULL
        WHERE sc.deleted_ts IS NULL
          AND (sc.assistant_bot_iid IS NULL OR sc.assistant_bot_iid = 0)
        ORDER BY sc.site_iid
        "#,
    )
    .fetch_all(&pool)
    .await?;
    for row in rows {
        let site_iid: i64 = row.get("site_iid");
        let owner_iid: i64 = row.get("owner_iid");
        let bot_iid = site_assistant_ensure_bot(&pool, owner_iid, site_iid).await?;
        println!(
            "ok site_iid={} owner_iid={} assistant_bot_iid={}",
            site_iid,
            owner_iid,
            bot_iid
        );
    }
    Ok(())
}
