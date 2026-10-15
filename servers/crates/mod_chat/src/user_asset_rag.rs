//! Threshold RAG for user-owned sites and bots (prompt hint + trace).

use std::time::{Duration, Instant};

use anyhow::Result;
use c35_mod_billing::billing_embed_cost_usd;
use c35_mod_llm::{
    embed_cache_get_many_touch, embed_cache_key, embed_cached, embed_model_tag, EMBED_MODEL,
    EMBED_TASK_DOCUMENT, EMBED_TASK_QUERY,
};
use reqwest::Client;
use sqlx::{PgPool, Row};
use tracing::warn;

use crate::site_resolve::SiteContext;
use crate::tool_rag::cosine_similarity;

pub const USER_ASSET_SIM_FLOOR: f32 = 0.50;
pub const USER_ASSET_SIM_GAP: f32 = 0.05;
pub const USER_ASSET_SCOPE_SIM_MIN: f32 = 0.55;
pub const USER_ASSET_TOP_K: usize = 5;
pub const USER_ASSET_INJECT_MAX: usize = 3;
const USER_ASSET_CANDIDATE_CAP: i64 = 48;
/// Max site/bot rows to vector-score per turn (avoids dozens of parallel doc embeds).
const USER_ASSET_EMBED_CANDIDATE_CAP: usize = 10;
const EMBED_DIMS: i32 = crate::memory::RETRIEVAL_EMBED_DIMS;
const EMBED_TIMEOUT: Duration = Duration::from_millis(400);

/// Skip user-asset RAG when the turn already names a site or does not need asset hints.
pub fn user_asset_turn_skip(query_text: &str, mention_ids: &[String]) -> bool {
    if crate::memory::is_trivial_query(query_text) {
        return true;
    }
    // Check if query is asking about personal memory/identity or general knowledge
    let lower = query_text.trim().to_lowercase();
    const PERSONAL_OR_TIME_PHRASES: &[&str] = &[
        "siapa nama saya",
        "nama saya",
        "nama aku",
        "siapa saya",
        "siapa aku",
        "tentang saya",
        "tentang diriku",
        "apa yang kamu ingat",
        "ingatan kamu",
        "sekarang jam berapa",
        "jam berapa",
        "hari apa",
        "tanggal berapa",
    ];
    if PERSONAL_OR_TIME_PHRASES.iter().any(|p| lower.contains(p)) {
        return true;
    }

    mention_ids.iter().any(|raw| {
        matches!(
            crate::mention_registry::mention_ref_parse(raw),
            Some(crate::mention_registry::MentionRef::Iid(_))
        )
    })
}

#[derive(Clone, Debug, serde::Serialize)]
pub struct UserAssetTraceEntry {
    pub kind: String,
    pub asset_iid: i64,
    pub name: String,
    pub alien_id: String,
    pub sim: f32,
    pub injected: bool,
}

#[derive(Clone, Debug, Default, serde::Serialize)]
pub struct UserAssetRetrieveTrace {
    pub duration_ms: i64,
    pub embed_ms: i64,
    pub embed_cached: bool,
    pub embed_skipped: bool,
    pub embed_token_in: i32,
    pub embed_cost_usd: f64,
    pub embed_model: String,
    pub injected: bool,
    pub block_chars: usize,
    pub sites: Vec<UserAssetTraceEntry>,
    pub bots: Vec<UserAssetTraceEntry>,
}

pub struct UserAssetRetrieveResult {
    pub block: String,
    pub trace: UserAssetRetrieveTrace,
    pub scope_site: Option<SiteContext>,
}

impl Default for UserAssetRetrieveResult {
    fn default() -> Self {
        Self {
            block: String::new(),
            trace: UserAssetRetrieveTrace::default(),
            scope_site: None,
        }
    }
}

#[derive(Clone)]
struct AssetCandidate {
    kind: &'static str,
    iid: i64,
    name: String,
    alien_id: String,
    embed_text: String,
}

fn asset_embed_text(kind: &str, name: &str, alien_id: &str, iid: i64) -> String {
    let mut parts = vec![kind.to_string(), name.trim().to_string()];
    if !alien_id.trim().is_empty() {
        parts.push(alien_id.trim().to_string());
    }
    parts.push(iid.to_string());
    parts.join("\n")
}

async fn asset_candidates_load(pool: &PgPool, owner_iid: i64) -> Result<Vec<AssetCandidate>> {
    let rows = sqlx::query(
        r#"
        SELECT i.id, i.kind, COALESCE(i.alien_id, '') AS alien_id, COALESCE(i.name, '') AS name,
               i.owner_iid, g.role
        FROM ai.identity i
        LEFT JOIN ai.identity_grant g
          ON g.resource_iid = i.id AND g.grantee_iid = $1 AND g.deleted_ts IS NULL
        WHERE i.deleted_ts IS NULL
          AND i.kind = ANY(ARRAY['site', 'bot']::text[])
          AND (i.owner_iid = $1 OR (g.grantee_iid = $1 AND g.role IS NOT NULL AND g.role <> 'guest'))
        ORDER BY i.kind ASC, i.updated_ts DESC NULLS LAST
        LIMIT $2
        "#,
    )
    .bind(owner_iid)
    .bind(USER_ASSET_CANDIDATE_CAP)
    .fetch_all(pool)
    .await?;
    Ok(rows
        .into_iter()
        .filter_map(|r| {
            let kind: String = r.get("kind");
            if kind != "site" && kind != "bot" {
                return None;
            }
            let iid: i64 = r.get("id");
            let name: String = r.get("name");
            let alien_id: String = r.get("alien_id");
            let embed_text = asset_embed_text(&kind, &name, &alien_id, iid);
            Some(AssetCandidate {
                kind: if kind == "site" { "site" } else { "bot" },
                iid,
                name,
                alien_id,
                embed_text,
            })
        })
        .collect())
}

fn lexical_asset_sim(query: &str, cand: &AssetCandidate) -> f32 {
    let q = crate::site_resolve::normalize_compact(query);
    if q.len() < 3 {
        return 0.0;
    }
    let name_c = crate::site_resolve::normalize_compact(&cand.name);
    let alien_c = crate::site_resolve::normalize_compact(&cand.alien_id);
    let mut best = 0.0f32;
    if !name_c.is_empty() {
        if q.contains(&name_c) || name_c.contains(&q) {
            let ratio = (name_c.len().min(q.len()) as f32) / (name_c.len().max(q.len()) as f32);
            best = best.max(0.55 + 0.35 * ratio);
        }
    }
    if !alien_c.is_empty() && (q.contains(&alien_c) || alien_c.contains(&q)) {
        best = best.max(0.60);
    }
    best
}

fn rank_and_build(
    scored: Vec<(AssetCandidate, f32)>,
    inject_max: usize,
) -> (String, Vec<UserAssetTraceEntry>, Vec<UserAssetTraceEntry>, Option<SiteContext>) {
    let mut scored = scored;
    scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

    let mut site_trace: Vec<UserAssetTraceEntry> = Vec::new();
    let mut bot_trace: Vec<UserAssetTraceEntry> = Vec::new();
    let mut site_injected = 0usize;
    let mut bot_injected = 0usize;

    for (cand, sim) in &scored {
        let injected = *sim >= USER_ASSET_SIM_FLOOR
            && ((cand.kind == "site" && site_injected < inject_max)
                || (cand.kind == "bot" && bot_injected < inject_max));
        let entry = UserAssetTraceEntry {
            kind: cand.kind.to_string(),
            asset_iid: cand.iid,
            name: cand.name.clone(),
            alien_id: cand.alien_id.clone(),
            sim: *sim,
            injected,
        };
        if cand.kind == "site" {
            site_trace.push(entry);
            if injected {
                site_injected += 1;
            }
        } else {
            bot_trace.push(entry);
            if injected {
                bot_injected += 1;
            }
        }
    }

    let mut block = String::new();
    let site_lines: Vec<String> = site_trace
        .iter()
        .filter(|e| e.injected)
        .map(|e| format!("- {} (site_iid={}, alien_id={})", e.name, e.asset_iid, e.alien_id))
        .collect();
    if !site_lines.is_empty() {
        block.push_str("[USER SITES]\n");
        block.push_str(&site_lines.join("\n"));
    }
    let bot_lines: Vec<String> = bot_trace
        .iter()
        .filter(|e| e.injected)
        .map(|e| format!("- {} (bot_iid={}, alien_id={})", e.name, e.asset_iid, e.alien_id))
        .collect();
    if !bot_lines.is_empty() {
        if !block.is_empty() {
            block.push_str("\n\n");
        }
        block.push_str("[USER BOTS]\n");
        block.push_str(&bot_lines.join("\n"));
    }

    let scope_site = pick_scope_site(&site_trace);
    (block, site_trace, bot_trace, scope_site)
}

fn pick_scope_site(site_trace: &[UserAssetTraceEntry]) -> Option<SiteContext> {
    let ranked: Vec<&UserAssetTraceEntry> = site_trace
        .iter()
        .filter(|e| e.sim >= USER_ASSET_SCOPE_SIM_MIN)
        .collect();
    if ranked.is_empty() {
        return None;
    }
    if ranked.len() == 1 {
        let e = ranked[0];
        return Some(SiteContext {
            site_iid: e.asset_iid,
            alien_id: e.alien_id.clone(),
            name: e.name.clone(),
        });
    }
    let top = ranked[0].sim;
    let second = ranked[1].sim;
    if top - second >= USER_ASSET_SIM_GAP {
        let e = ranked[0];
        return Some(SiteContext {
            site_iid: e.asset_iid,
            alien_id: e.alien_id.clone(),
            name: e.name.clone(),
        });
    }
    None
}

pub async fn user_asset_retrieve(
    pool: &PgPool,
    http: &Client,
    owner_iid: i64,
    query_text: &str,
    query_embed: Option<Vec<f32>>,
) -> UserAssetRetrieveResult {
    let t0 = Instant::now();
    let mut trace = UserAssetRetrieveTrace::default();
    let q_full = query_text.trim();
    if q_full.len() < 3 {
        trace.duration_ms = t0.elapsed().as_millis() as i64;
        return UserAssetRetrieveResult::default();
    }
    let q_phrase = crate::site_resolve::utterance_site_phrase(q_full);
    let q = if q_phrase.len() >= 3 {
        q_phrase
    } else {
        q_full.to_string()
    };

    let candidates = match asset_candidates_load(pool, owner_iid).await {
        Ok(c) => c,
        Err(e) => {
            warn!("[c35:user_asset] load failed owner_iid={owner_iid}: {e:#}");
            trace.duration_ms = t0.elapsed().as_millis() as i64;
            return UserAssetRetrieveResult::default();
        }
    };
    if candidates.is_empty() {
        trace.duration_ms = t0.elapsed().as_millis() as i64;
        return UserAssetRetrieveResult::default();
    }

    let mut scored: Vec<(AssetCandidate, f32)> = candidates
        .into_iter()
        .map(|c| {
            let sim = lexical_asset_sim(&q, &c);
            (c, sim)
        })
        .collect();

    let needs_embed = scored.iter().all(|(_, s)| *s < USER_ASSET_SIM_FLOOR)
        || scored
            .iter()
            .filter(|(_, s)| *s >= USER_ASSET_SIM_FLOOR)
            .count()
            > USER_ASSET_INJECT_MAX;

    if needs_embed {
        scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        if scored.len() > USER_ASSET_EMBED_CANDIDATE_CAP {
            scored.truncate(USER_ASSET_EMBED_CANDIDATE_CAP);
        }

        let embed_t0 = Instant::now();
        let model = embed_model_tag(EMBED_MODEL, EMBED_DIMS);
        trace.embed_model = model.clone();
        let query_vec = if let Some(pre) = query_embed {
            trace.embed_cached = true;
            trace.embed_ms = embed_t0.elapsed().as_millis() as i64;
            Some(pre)
        } else {
            match tokio::time::timeout(
                EMBED_TIMEOUT,
                embed_cached(pool, http, &q, EMBED_TASK_QUERY, EMBED_DIMS),
            )
            .await
            {
                Ok(Ok(r)) => {
                    trace.embed_cached = r.cached;
                    trace.embed_ms = embed_t0.elapsed().as_millis() as i64;
                    trace.embed_token_in = r.token_in;
                    trace.embed_cost_usd = billing_embed_cost_usd(&model, r.token_in);
                    Some(r.embedding)
                }
                _ => {
                    trace.embed_skipped = true;
                    None
                }
            }
        };

        if let Some(q_vec) = query_vec {
            let texts: Vec<String> = scored.iter().map(|(c, _)| c.embed_text.clone()).collect();
            let keys: Vec<String> = texts
                .iter()
                .map(|t| embed_cache_key(t, EMBED_TASK_DOCUMENT, EMBED_DIMS))
                .collect();
            let cached_batch = embed_cache_get_many_touch(pool, &model, &keys)
                .await
                .unwrap_or_default();

            let doc_futs = scored.iter().enumerate().map(|(i, (cand, _))| {
                let cached_opt = cached_batch.get(i).cloned().flatten();
                let text = cand.embed_text.clone();
                let pool = pool.clone();
                let http = http.clone();
                async move {
                    if let Some(vec) = cached_opt {
                        return (vec, 0, true);
                    }
                    // Non-blocking for turn latency: spawn background prewarm so future turns hit cache instantly
                    tokio::spawn(async move {
                        let _ = embed_cached(&pool, &http, &text, EMBED_TASK_DOCUMENT, EMBED_DIMS).await;
                    });
                    (Vec::new(), 0, false)
                }
            });
            let doc_results = futures_util::future::join_all(doc_futs).await;
            for ((_, lex), (doc, token_in, _)) in scored.iter_mut().zip(doc_results) {
                if token_in > 0 {
                    trace.embed_token_in += token_in;
                    trace.embed_cost_usd += billing_embed_cost_usd(&model, token_in);
                }
                if !doc.is_empty() {
                    let sim = cosine_similarity(&q_vec, &doc);
                    *lex = lex.max(sim);
                }
            }
        }
    }

    scored.retain(|(_, s)| *s > 0.0);
    scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
    if scored.len() > USER_ASSET_TOP_K {
        scored.truncate(USER_ASSET_TOP_K);
    }

    let (block, sites, bots, scope_site) = rank_and_build(scored, USER_ASSET_INJECT_MAX);
    trace.sites = sites;
    trace.bots = bots;
    trace.block_chars = block.len();
    trace.injected = !block.is_empty();
    trace.duration_ms = t0.elapsed().as_millis() as i64;

    UserAssetRetrieveResult {
        block,
        trace,
        scope_site,
    }
}

pub async fn live_mention_ids_from_text(
    pool: &PgPool,
    http: &Client,
    owner_iid: i64,
    text: &str,
) -> Option<(Vec<String>, String)> {
    let trimmed = text.trim();
    if trimmed.len() < 3 {
        return None;
    }
    if let Some(ctx) = crate::site_resolve::site_context_resolve(pool, owner_iid, trimmed, &[])
        .await
        .ok()
        .flatten()
    {
        let label = if ctx.name.is_empty() {
            ctx.alien_id.clone()
        } else {
            ctx.name.clone()
        };
        return Some((vec![format!("iid:{}", ctx.site_iid)], label));
    }
    let assets = user_asset_retrieve(pool, http, owner_iid, trimmed, None).await;
    if let Some(ctx) = assets.scope_site {
        let label = if ctx.name.is_empty() {
            ctx.alien_id.clone()
        } else {
            ctx.name.clone()
        };
        return Some((vec![format!("iid:{}", ctx.site_iid)], label));
    }
    assets
        .trace
        .sites
        .iter()
        .find(|e| e.injected)
        .map(|e| (vec![format!("iid:{}", e.asset_iid)], e.name.clone()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn utterance_site_phrase_extracts_di_tail() {
        assert_eq!(
            crate::site_resolve::utterance_site_phrase("Berapa harga es teh di Gucicha"),
            "gucicha"
        );
    }

    #[test]
    fn user_asset_turn_skip_trivial_and_iid_mention() {
        assert!(user_asset_turn_skip("halo", &[]));
        assert!(user_asset_turn_skip("ok", &[]));
        assert!(user_asset_turn_skip("siapa nama saya?", &[]));
        assert!(user_asset_turn_skip("nama saya siapa", &[]));
        assert!(user_asset_turn_skip("sekarang jam berapa", &[]));
        assert!(!user_asset_turn_skip("berapa harga es teh", &[]));
        assert!(user_asset_turn_skip(
            "berapa stok",
            &["iid:12345".to_string()]
        ));
    }

    #[test]
    fn lexical_match_fuzzy_site_name() {
        let cand = AssetCandidate {
            kind: "site",
            iid: 1,
            name: "Guci Cha".into(),
            alien_id: "guci-cha".into(),
            embed_text: String::new(),
        };
        let sim = lexical_asset_sim("berapa harga es teh di Gucicha", &cand);
        assert!(sim >= USER_ASSET_SIM_FLOOR);
    }
}
