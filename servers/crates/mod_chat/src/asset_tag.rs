use std::collections::HashMap;

use anyhow::{anyhow, Result};
use c35_proto::{AssetTagHint, ReqAssetTagList, ResAssetTagList};
use sqlx::{PgPool, Row};

pub fn tag_normalize(raw: &str) -> String {
    let t = raw.trim().to_lowercase();
    let no_hash = t.strip_prefix('#').unwrap_or(&t);
    no_hash
        .chars()
        .filter(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || *c == '_' || *c == '-')
        .collect()
}

pub fn tags_normalize(raw: &[String]) -> Result<Vec<String>> {
    let mut out = Vec::new();
    for item in raw {
        let tag = tag_normalize(item);
        if tag.is_empty() {
            continue;
        }
        if tag.len() > 32 {
            return Err(anyhow!("tag too long"));
        }
        if !out.contains(&tag) {
            out.push(tag);
        }
    }
    Ok(out)
}

pub async fn asset_tag_list(pool: &PgPool, owner_iid: i64, req: ReqAssetTagList) -> Result<ResAssetTagList> {
    let kind = req.kind.trim();
    if kind.is_empty() {
        return Err(anyhow!("kind required"));
    }
    let prefix = tag_normalize(&req.prefix);
    let limit = if req.limit <= 0 { 20 } else { req.limit.min(100) };
    let rows = sqlx::query(
        r#"
        SELECT tag, COUNT(*)::INT AS count
        FROM ai.asset_tag
        WHERE owner_iid = $1 AND kind = $2 AND deleted_ts IS NULL
          AND ($3 = '' OR tag LIKE $3 || '%')
        GROUP BY tag
        ORDER BY count DESC, tag ASC
        LIMIT $4
        "#,
    )
    .bind(owner_iid)
    .bind(kind)
    .bind(prefix)
    .bind(limit)
    .fetch_all(pool)
    .await?;
    let hints = rows
        .into_iter()
        .map(|r| AssetTagHint {
            tag: r.get("tag"),
            count: r.get("count"),
        })
        .collect();
    Ok(ResAssetTagList { hints })
}

pub async fn asset_tags_map(pool: &PgPool, owner_iid: i64, kind: &str, asset_ids: &[i64]) -> Result<HashMap<i64, Vec<String>>> {
    if asset_ids.is_empty() {
        return Ok(HashMap::new());
    }
    let rows = sqlx::query(
        r#"
        SELECT asset_id, tag
        FROM ai.asset_tag
        WHERE owner_iid = $1 AND kind = $2 AND asset_id = ANY($3) AND deleted_ts IS NULL
        ORDER BY asset_id, tag
        "#,
    )
    .bind(owner_iid)
    .bind(kind)
    .bind(asset_ids)
    .fetch_all(pool)
    .await?;
    let mut out: HashMap<i64, Vec<String>> = HashMap::new();
    for r in rows {
        let asset_id: i64 = r.get("asset_id");
        let tag: String = r.get("tag");
        out.entry(asset_id).or_default().push(tag);
    }
    Ok(out)
}

pub async fn asset_tags_replace(pool: &PgPool, owner_iid: i64, kind: &str, asset_id: i64, tags: &[String]) -> Result<()> {
    let tags = tags_normalize(tags)?;
    let mut tx = pool.begin().await?;
    sqlx::query(
        r#"
        UPDATE ai.asset_tag
        SET deleted_ts = NOW(), updated_ts = NOW()
        WHERE owner_iid = $1 AND kind = $2 AND asset_id = $3 AND deleted_ts IS NULL
        "#,
    )
    .bind(owner_iid)
    .bind(kind)
    .bind(asset_id)
    .execute(&mut *tx)
    .await?;
    for tag in tags {
        sqlx::query(
            r#"
            INSERT INTO ai.asset_tag (owner_iid, kind, asset_id, tag)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (owner_iid, kind, asset_id, tag)
            DO UPDATE SET deleted_ts = NULL, updated_ts = NOW()
            "#,
        )
        .bind(owner_iid)
        .bind(kind)
        .bind(asset_id)
        .bind(tag)
        .execute(&mut *tx)
        .await?;
    }
    tx.commit().await?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tag_normalize_strips_hash_and_invalid() {
        assert_eq!(tag_normalize("#Work-1"), "work-1");
        assert_eq!(tag_normalize("  #HELLO!  "), "hello");
    }

    #[test]
    fn tags_normalize_dedupes() {
        assert_eq!(tags_normalize(&["#work".into(), "work".into(), "home".into()]).unwrap(), vec!["work", "home"]);
    }
}
