use c35_proto::{MentionItem, ReqMentionSearch, ResMentionList, ResMentionSearch};
use c35_store::missing_table;
use serde_json::Value;
use sqlx::{PgPool, Row};
use tracing::warn;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MentionRef {
    Catalog(String),
    Iid(i64),
}

#[derive(Debug, Clone)]
pub struct MentionResolved {
    pub item: MentionItem,
    pub identity_iid: Option<i64>,
    pub identity_kind: Option<String>,
}

pub fn mention_ref_parse(raw: &str) -> Option<MentionRef> {
    let s = raw.trim();
    if s.is_empty() {
        return None;
    }
    if let Some(id) = s.strip_prefix("catalog:") {
        return (!id.is_empty()).then(|| MentionRef::Catalog(id.to_string()));
    }
    if let Some(id) = s.strip_prefix("iid:") {
        return id.parse::<i64>().ok().filter(|i| *i > 0).map(MentionRef::Iid);
    }
    if let Some(id) = s.strip_prefix("device:") {
        return id.parse::<i64>().ok().filter(|i| *i > 0).map(MentionRef::Iid);
    }
    if let Some(id) = s.strip_prefix("site:") {
        return id.parse::<i64>().ok().filter(|i| *i > 0).map(MentionRef::Iid);
    }
    if let Ok(iid) = s.parse::<i64>() {
        if iid > 0 {
            return Some(MentionRef::Iid(iid));
        }
    }
    Some(MentionRef::Catalog(s.to_string()))
}

pub fn mention_ref_catalog(id: &str) -> String {
    format!("catalog:{id}")
}

pub fn mention_ref_iid(iid: i64) -> String {
    format!("iid:{iid}")
}

fn identity_topic(kind: &str) -> &'static str {
    match kind {
        "remote" | "iot" => "device",
        "site" => "web.builder",
        "bot" => "bot",
        _ => "general",
    }
}

fn meta_online(meta: &Value) -> bool {
    meta.get("online").and_then(|v| v.as_bool()).unwrap_or(false)
}

async fn catalog_rows(pool: &PgPool) -> Vec<MentionItem> {
    let rows = sqlx::query_as::<_, (String, Option<String>, String, String, i32, String, String)>(
        "SELECT id, topic_id, icon, color, sort, label_key, caption_key \
         FROM ai.mention WHERE enabled = true ORDER BY sort ASC, id ASC",
    )
    .fetch_all(pool)
    .await;
    match rows {
        Ok(rows) => rows
            .into_iter()
            .map(|(id, topic_id, icon, color, sort, label_key, caption_key)| {
                let label = label_key.clone();
                MentionItem {
                    id: mention_ref_catalog(&id),
                    topic_id: topic_id.unwrap_or_default(),
                    inst_id: String::new(),
                    icon,
                    color,
                    sort,
                    label_key: label_key.clone(),
                    caption_key,
                    search_terms: vec![id.clone(), label_key.to_lowercase()],
                    enabled: true,
                    title: label.clone(),
                    scope_label: String::new(),
                    label,
                    scope_ref: String::new(),
                    kind: "catalog".into(),
                }
            })
            .collect(),
        Err(e) if missing_table(&e) => {
            warn!(error = %e, "mention catalog rows: ai.mention missing");
            vec![]
        }
        Err(e) => {
            warn!(error = %e, "mention catalog rows failed");
            vec![]
        }
    }
}

async fn identity_rows(pool: &PgPool, caller_iid: i64) -> Vec<MentionItem> {
    let rows = sqlx::query(
        r#"
        SELECT i.id, i.kind, i.type, COALESCE(i.alien_id, '') AS alien_id,
               COALESCE(i.name, '') AS name, COALESCE(i.meta, '{}'::jsonb) AS meta
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.deleted_ts IS NULL
          AND i.kind = ANY(ARRAY['remote', 'iot', 'site', 'bot']::text[])
          AND (i.owner_iid = $1 OR g.grantee_iid = $1)
        ORDER BY i.kind ASC, i.name ASC, i.id ASC
        "#,
    )
    .bind(caller_iid)
    .fetch_all(pool)
    .await;
    match rows {
        Ok(rows) => rows
            .iter()
            .map(|r| {
                let iid: i64 = r.get("id");
                let kind: String = r.get("kind");
                let alien_id: String = r.get("alien_id");
                let name: String = r.get("name");
                let meta: Value = r.get("meta");
                let title = if name.is_empty() {
                    if alien_id.is_empty() {
                        format!("{} {}", kind, iid)
                    } else {
                        alien_id.clone()
                    }
                } else {
                    name.clone()
                };
                let caption = match kind.as_str() {
                    "remote" | "iot" => {
                        if meta_online(&meta) {
                            "Online agent"
                        } else {
                            "Offline"
                        }
                    }
                    "site" => "Website",
                    "bot" => "Bot",
                    _ => "",
                };
                let color = match kind.as_str() {
                    "remote" | "iot" => {
                        if meta_online(&meta) {
                            "#22c55e"
                        } else {
                            "#94a3b8"
                        }
                    }
                    "site" => "#34d399",
                    "bot" => "#a78bfa",
                    _ => "#71717a",
                };
                let icon = match kind.as_str() {
                    "remote" | "iot" => "computer",
                    "site" => "web",
                    "bot" => "smart_toy",
                    _ => "alternate_email",
                };
                let mut terms = vec![title.to_lowercase()];
                if !alien_id.is_empty() {
                    terms.push(alien_id.to_lowercase());
                }
                terms.push(iid.to_string());
                MentionItem {
                    id: mention_ref_iid(iid),
                    topic_id: identity_topic(&kind).into(),
                    inst_id: String::new(),
                    icon: icon.into(),
                    color: color.into(),
                    sort: match kind.as_str() {
                        "remote" | "iot" => 50,
                        "site" => 40,
                        "bot" => 45,
                        _ => 60,
                    },
                    label_key: title.clone(),
                    caption_key: caption.into(),
                    search_terms: terms,
                    enabled: true,
                    title: title.clone(),
                    scope_label: String::new(),
                    label: title,
                    scope_ref: String::new(),
                    kind: "identity".into(),
                }
            })
            .collect(),
        Err(e) => {
            warn!(error = %e, "mention identity rows failed");
            vec![]
        }
    }
}

pub async fn mention_snapshot(pool: &PgPool, caller_iid: i64) -> (i64, Vec<MentionItem>) {
    let catalog = catalog_rows(pool).await;
    let identities = identity_rows(pool, caller_iid).await;
    let mut items = catalog;
    items.extend(identities);
    let rev = chrono::Utc::now().timestamp_millis();
    (rev, items)
}

pub async fn mention_list_rpc(pool: &PgPool, caller_iid: i64) -> ResMentionList {
    let (rev, mentions) = mention_snapshot(pool, caller_iid).await;
    ResMentionList { mentions, rev }
}

fn mention_search_score(item: &MentionItem, q: &str) -> i32 {
    let q = q.to_lowercase();
    if q.is_empty() {
        return 0;
    }
    if item.id.to_lowercase().contains(&q) {
        return 100;
    }
    if item.label.to_lowercase().contains(&q) {
        return 90;
    }
    if item.title.to_lowercase().contains(&q) {
        return 85;
    }
    if item.scope_label.to_lowercase().contains(&q) {
        return 80;
    }
    for t in &item.search_terms {
        if t.to_lowercase().contains(&q) {
            return 70;
        }
    }
    0
}

pub async fn mention_search_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqMentionSearch,
) -> ResMentionSearch {
    let limit = req.limit.clamp(1, 50) as usize;
    let q = req.q.trim();
    let (_, items) = mention_snapshot(pool, caller_iid).await;
    let kinds: Vec<String> = req
        .kinds
        .iter()
        .map(|k| k.trim().to_lowercase())
        .filter(|k| !k.is_empty())
        .collect();
    let mut scored: Vec<(i32, MentionItem)> = items
        .into_iter()
        .filter(|item| kinds.is_empty() || kinds.iter().any(|k| item.kind == *k))
        .map(|item| (mention_search_score(&item, q), item))
        .filter(|(score, _)| q.is_empty() || *score > 0)
        .collect();
    scored.sort_by(|a, b| b.0.cmp(&a.0).then_with(|| a.1.label.cmp(&b.1.label)));
    ResMentionSearch {
        mentions: scored.into_iter().take(limit).map(|(_, item)| item).collect(),
    }
}

async fn identity_resolve(pool: &PgPool, caller_iid: i64, iid: i64) -> Option<MentionResolved> {
    let row = sqlx::query(
        r#"
        SELECT i.id, i.kind, COALESCE(i.name, '') AS name, COALESCE(i.alien_id, '') AS alien_id,
               i.owner_iid, g.role
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $2 AND g.deleted_ts IS NULL
        WHERE i.id = $1 AND i.deleted_ts IS NULL
          AND i.kind = ANY(ARRAY['remote', 'iot', 'site', 'bot']::text[])
        "#,
    )
    .bind(iid)
    .bind(caller_iid)
    .fetch_optional(pool)
    .await;
    let row = match row {
        Ok(Some(r)) => r,
        _ => return None,
    };
    let owner_iid: i64 = row.get("owner_iid");
    let role: Option<String> = row.try_get("role").ok().flatten();
    let allowed = owner_iid == caller_iid || role.as_deref().is_some_and(|r| r != "guest");
    if !allowed {
        return None;
    }
    let kind: String = row.get("kind");
    let rows = identity_rows(pool, caller_iid).await;
    rows.into_iter()
        .find(|item| item.id == mention_ref_iid(iid))
        .map(|item| MentionResolved {
            item,
            identity_iid: Some(iid),
            identity_kind: Some(kind),
        })
}

async fn catalog_resolve(pool: &PgPool, id: &str) -> Option<MentionResolved> {
    catalog_rows(pool)
        .await
        .into_iter()
        .find(|item| item.id == mention_ref_catalog(id) || item.id == id)
        .map(|item| MentionResolved {
            item,
            identity_iid: None,
            identity_kind: None,
        })
}

pub async fn mention_resolve_one(
    pool: &PgPool,
    caller_iid: i64,
    raw: &str,
) -> Option<MentionResolved> {
    match mention_ref_parse(raw)? {
        MentionRef::Iid(iid) => identity_resolve(pool, caller_iid, iid).await,
        MentionRef::Catalog(id) => catalog_resolve(pool, &id).await,
    }
}

pub async fn mention_resolve_all(
    pool: &PgPool,
    caller_iid: i64,
    refs: &[String],
) -> Vec<MentionResolved> {
    let mut out = Vec::new();
    for raw in refs {
        if let Some(r) = mention_resolve_one(pool, caller_iid, raw).await {
            if !out.iter().any(|x: &MentionResolved| x.item.id == r.item.id) {
                out.push(r);
            }
        }
    }
    out
}

pub fn mention_prompt_block(resolved: &[MentionResolved]) -> String {
    if resolved.is_empty() {
        return String::new();
    }
    let lines: Vec<String> = resolved
        .iter()
        .map(|r| {
            if let Some(iid) = r.identity_iid {
                let kind = r
                    .item
                    .topic_id
                    .clone();
                format!(
                    "- {} (ref={}, iid={}, topic={})",
                    r.item.label, r.item.id, iid, kind
                )
            } else {
                format!("- {} (ref={}, topic={})", r.item.label, r.item.id, r.item.topic_id)
            }
        })
        .collect();
    format!("[MENTION TARGETS]\n{}", lines.join("\n"))
}

pub fn mention_device_iids(resolved: &[MentionResolved]) -> Vec<i64> {
    resolved
        .iter()
        .filter(|r| {
            r.item.topic_id == "device" && r.identity_iid.is_some_and(|i| i > 0)
        })
        .filter_map(|r| r.identity_iid)
        .collect()
}

pub fn mention_has_device(resolved: &[MentionResolved]) -> bool {
    !mention_device_iids(resolved).is_empty()
}

pub fn mention_force_tools(resolved: &[MentionResolved]) -> Vec<String> {
    let mut out = Vec::new();
    if mention_has_device(resolved) {
        for t in ["device.screenshot", "device.input", "device.command"] {
            out.push(t.to_string());
        }
    }
    for r in resolved {
        if r.item.topic_id == "web.builder" {
            for t in ["site.draft_put", "site.publish", "site.product_put"] {
                if !out.iter().any(|x| x == t) {
                    out.push(t.to_string());
                }
            }
        }
    }
    out
}

pub fn mention_active_topic(resolved: &[MentionResolved], explicit: &str) -> String {
    let explicit = explicit.trim();
    if !explicit.is_empty() {
        return explicit.to_string();
    }
    if mention_has_device(resolved) {
        return "device".into();
    }
    for r in resolved {
        if !r.item.topic_id.is_empty() && r.item.topic_id != "general" {
            return r.item.topic_id.clone();
        }
    }
    "general".into()
}
