use c35_proto::{
    ReqSkillCatalogInstall, ReqSkillCatalogList, ReqSkillCatalogSearch, ReqSkillCatalogSubmit,
    ReqSkillList, ReqSkillPut, ReqSkillRunReport, ResSkillCatalogInstall, ResSkillCatalogList,
    ResSkillCatalogSearch, ResSkillCatalogSubmit, ResSkillList, ResSkillPut, ResSkillRunReport,
    Skill, SkillCatalog, SkillStep,
};
use c35_store::snowflake_id;
use sqlx::{PgPool, Row};

use crate::seed;

fn scope_db(scope: i32) -> &'static str {
    match scope {
        2 => "device",
        3 => "team",
        4 => "global",
        _ => "user",
    }
}

fn scope_pb(raw: &str) -> i32 {
    match raw {
        "device" => 2,
        "team" => 3,
        "global" => 4,
        _ => 1,
    }
}

fn source_pb(raw: &str) -> i32 {
    match raw {
        "catalog" => 2,
        "import" => 3,
        "ai_explore" => 4,
        _ => 1,
    }
}

fn source_db(source: i32) -> &'static str {
    match source {
        2 => "catalog",
        3 => "import",
        4 => "ai_explore",
        _ => "taught",
    }
}

fn hash_body(body_md: &str) -> String {
    blake3::hash(body_md.as_bytes()).to_hex().to_string()
}

fn skill_from_row(row: &sqlx::postgres::PgRow) -> Skill {
    Skill {
        id: row.get("id"),
        owner_iid: row.get("owner_iid"),
        scope: scope_pb(row.get::<String, _>("scope").as_str()),
        device_iid: row.get("device_iid"),
        team_iid: row.get("team_iid"),
        title: row.get("title"),
        hash_blake3: row.get("hash_blake3"),
        body_md: row.get("body_md"),
        source: source_pb(row.get::<String, _>("source").as_str()),
        catalog_id: row.get("catalog_id"),
        catalog_variant_id: row.get("catalog_variant_id"),
        catalog_release_id: row.get("catalog_release_id"),
        author_name: row.get("author_name"),
        tags_json: row.get::<serde_json::Value, _>("tags_json").to_string(),
        phrases_json: row.get::<serde_json::Value, _>("phrases_json").to_string(),
        auto_run: row.get("auto_run"),
        surface: row.get("surface"),
        target_app: row.get("target_app"),
        url_pattern: row.get("url_pattern"),
        // Phase 7: circuit-breaker + auto-submit fields
        patch_epoch: row.try_get("patch_epoch").unwrap_or(0),
        patch_count: row.try_get("patch_count").unwrap_or(0),
        consecutive_ok: row.try_get("consecutive_ok").unwrap_or(0),
        detected_app_version: row.try_get("detected_app_version").unwrap_or_default(),
        auto_submit: row.try_get("auto_submit").unwrap_or(false),
        last_patched_ts_ms: row
            .try_get::<Option<chrono::DateTime<chrono::Utc>>, _>("last_patched_ts")
            .ok()
            .flatten()
            .map(|t| t.timestamp_millis())
            .unwrap_or(0),
        created_ts_ms: row
            .get::<chrono::DateTime<chrono::Utc>, _>("created_ts")
            .timestamp_millis(),
        updated_ts_ms: row
            .get::<chrono::DateTime<chrono::Utc>, _>("updated_ts")
            .timestamp_millis(),
        deleted_ts_ms: row
            .get::<Option<chrono::DateTime<chrono::Utc>>, _>("deleted_ts")
            .map(|t| t.timestamp_millis())
            .unwrap_or(0),
        ..Default::default()
    }
}

fn catalog_from_row(row: &sqlx::postgres::PgRow) -> SkillCatalog {
    SkillCatalog {
        id: row.get("id"),
        author_iid: row.get("author_iid"),
        author_name: row.get("author_name"),
        slug: row.get("slug"),
        title: row.get("title"),
        summary: row.get("summary"),
        body_md: row.get("body_md"),
        tags_json: row.get("tags_json"),
        install_count: row.get("install_count"),
        rating: row.try_get::<f64, _>("rating").unwrap_or(5.0),
        is_verified: row.get("is_verified"),
        status: row.get("status"),
        price_usd: row.try_get::<f64, _>("price_usd").unwrap_or(0.0),
        price_idr: row.try_get::<f64, _>("price_idr").unwrap_or(0.0),
        billing_period: row.get("billing_period"),
    }
}

async fn skill_steps(pool: &PgPool, skill_id: i64) -> Vec<SkillStep> {
    let rows = sqlx::query(
        r#"
        SELECT id, skill_id, owner_iid, ord, kind, label, ax_target_json::text,
               screenshot_hash, comment, secret_id, tape_local_only_json::text,
               created_ts, updated_ts, deleted_ts
        FROM ai.skill_step
        WHERE skill_id = $1 AND deleted_ts IS NULL
        ORDER BY ord ASC
        "#,
    )
    .bind(skill_id)
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    rows.iter()
        .map(|row| SkillStep {
            id: row.get("id"),
            skill_id: row.get("skill_id"),
            owner_iid: row.get("owner_iid"),
            ord: row.get("ord"),
            kind: row.get("kind"),
            label: row.get("label"),
            ax_target_json: row.get("ax_target_json"),
            screenshot_hash: row.get("screenshot_hash"),
            comment: row.get("comment"),
            secret_id: row.get("secret_id"),
            tape_local_only_json: row.get("tape_local_only_json"),
            created_ts_ms: row
                .get::<chrono::DateTime<chrono::Utc>, _>("created_ts")
                .timestamp_millis(),
            updated_ts_ms: row
                .get::<chrono::DateTime<chrono::Utc>, _>("updated_ts")
                .timestamp_millis(),
            deleted_ts_ms: row
                .get::<Option<chrono::DateTime<chrono::Utc>>, _>("deleted_ts")
                .map(|t| t.timestamp_millis())
                .unwrap_or(0),
        })
        .collect()
}

pub async fn skill_list_rpc(pool: &PgPool, caller_iid: i64, req: ReqSkillList) -> ResSkillList {
    let scope = scope_db(req.scope);
    let rows = sqlx::query(
        r#"
        SELECT id, owner_iid, scope, device_iid, team_iid, title, hash_blake3, body_md,
               source, catalog_id, catalog_variant_id, catalog_release_id, author_name,
               tags_json, phrases_json, auto_run, surface, target_app, url_pattern,
               patch_epoch, patch_count, consecutive_ok, detected_app_version, auto_submit,
               last_patched_ts, created_ts, updated_ts, deleted_ts
        FROM ai.skill
        WHERE owner_iid = $1
          AND deleted_ts IS NULL
          AND ($2::text = '' OR scope = $2)
          AND ($3::bigint = 0 OR device_iid = $3)
          AND ($4::bigint = 0 OR team_iid = $4)
          AND ($5::bigint = 0 OR updated_ts > to_timestamp($5::double precision / 1000.0))
        ORDER BY updated_ts DESC
        "#,
    )
    .bind(caller_iid)
    .bind(scope)
    .bind(req.device_iid)
    .bind(req.team_iid)
    .bind(req.since_ms)
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    let mut skills = Vec::with_capacity(rows.len());
    for row in &rows {
        let mut skill = skill_from_row(row);
        skill.steps = skill_steps(pool, skill.id).await;
        skills.push(skill);
    }
    ResSkillList { skills }
}

pub async fn skill_put_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSkillPut,
) -> Result<ResSkillPut, String> {
    let doc = req.skill.ok_or_else(|| "skill required".to_string())?;
    let scope = scope_db(doc.scope);
    if scope == "device" && doc.device_iid == 0 {
        return Err("device_iid required for device scope".into());
    }
    let id = if doc.id > 0 { doc.id } else { snowflake_id() };
    let hash = if doc.hash_blake3.is_empty() {
        hash_body(&doc.body_md)
    } else {
        doc.hash_blake3.clone()
    };
    let source = source_db(doc.source);

    if doc.id > 0 {
        let owner: Option<i64> = sqlx::query_scalar(
            "SELECT owner_iid FROM ai.skill WHERE id = $1 AND deleted_ts IS NULL",
        )
        .bind(id)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        if owner != Some(caller_iid) {
            return Err("forbidden".into());
        }

        // Phase 7: patch_epoch monotonicity guard — prevents infinite update loops
        if doc.patch_epoch > 0 {
            let existing_epoch: Option<i32> = sqlx::query_scalar(
                "SELECT patch_epoch FROM ai.skill WHERE id = $1 AND deleted_ts IS NULL",
            )
            .bind(id)
            .fetch_optional(pool)
            .await
            .map_err(|e| e.to_string())?;
            if let Some(ep) = existing_epoch {
                if ep >= doc.patch_epoch {
                    return Err(format!(
                        "stale_write: patch_epoch must advance (existing={ep}, incoming={})",
                        doc.patch_epoch
                    ));
                }
            }
        }
    }

    // auto_submit defaults TRUE only for new ai_explore skills
    let auto_submit = if doc.id == 0 && source == "ai_explore" {
        true
    } else {
        doc.auto_submit
    };

    let last_patched_ts: Option<chrono::DateTime<chrono::Utc>> = if doc.last_patched_ts_ms > 0 {
        chrono::DateTime::from_timestamp_millis(doc.last_patched_ts_ms)
    } else {
        None
    };

    sqlx::query(
        r#"
        INSERT INTO ai.skill (
            id, owner_iid, scope, device_iid, team_iid, title, hash_blake3, body_md,
            source, catalog_id, catalog_variant_id, catalog_release_id, author_name,
            tags_json, phrases_json, auto_run, surface, target_app, url_pattern,
            patch_epoch, patch_count, consecutive_ok, detected_app_version, auto_submit,
            last_patched_ts, created_ts, updated_ts
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8,
            $9, $10, $11, $12, $13,
            $14::jsonb, $15::jsonb, $16, $17, $18, $19,
            $20, $21, $22, $23, $24,
            $25, NOW(), NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            title = EXCLUDED.title,
            hash_blake3 = EXCLUDED.hash_blake3,
            body_md = EXCLUDED.body_md,
            tags_json = EXCLUDED.tags_json,
            phrases_json = EXCLUDED.phrases_json,
            auto_run = EXCLUDED.auto_run,
            surface = EXCLUDED.surface,
            target_app = EXCLUDED.target_app,
            url_pattern = EXCLUDED.url_pattern,
            patch_epoch = EXCLUDED.patch_epoch,
            patch_count = EXCLUDED.patch_count,
            consecutive_ok = EXCLUDED.consecutive_ok,
            detected_app_version = EXCLUDED.detected_app_version,
            auto_submit = EXCLUDED.auto_submit,
            last_patched_ts = EXCLUDED.last_patched_ts,
            updated_ts = NOW()
        "#,
    )
    .bind(id)
    .bind(caller_iid)
    .bind(scope)
    .bind(doc.device_iid)
    .bind(doc.team_iid)
    .bind(doc.title.trim())
    .bind(&hash)
    .bind(&doc.body_md)
    .bind(source)
    .bind(doc.catalog_id)
    .bind(doc.catalog_variant_id)
    .bind(doc.catalog_release_id)
    .bind(doc.author_name.trim())
    .bind(if doc.tags_json.trim().is_empty() { "[]" } else { doc.tags_json.trim() })
    .bind(if doc.phrases_json.trim().is_empty() { "[]" } else { doc.phrases_json.trim() })
    .bind(doc.auto_run)
    .bind(doc.surface.trim())
    .bind(doc.target_app.trim())
    .bind(doc.url_pattern.trim())
    .bind(doc.patch_epoch)
    .bind(doc.patch_count)
    .bind(doc.consecutive_ok)
    .bind(doc.detected_app_version.trim())
    .bind(auto_submit)
    .bind(last_patched_ts)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, scope, device_iid, team_iid, title, hash_blake3, body_md,
               source, catalog_id, catalog_variant_id, catalog_release_id, author_name,
               tags_json, phrases_json, auto_run, surface, target_app, url_pattern,
               patch_epoch, patch_count, consecutive_ok, detected_app_version, auto_submit,
               last_patched_ts, created_ts, updated_ts, deleted_ts
        FROM ai.skill WHERE id = $1
        "#,
    )
    .bind(id)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;

    let mut skill = skill_from_row(&row);
    skill.steps = skill_steps(pool, skill.id).await;
    Ok(ResSkillPut { skill: Some(skill) })
}

pub async fn skill_catalog_list_rpc(
    pool: &PgPool,
    _caller_iid: i64,
    req: ReqSkillCatalogList,
) -> ResSkillCatalogList {
    seed::skill_catalog_ensure_seed(pool).await;
    let q = req.q.trim().to_lowercase();
    let limit = if req.limit <= 0 { 50 } else { req.limit.min(100) };
    let rows = if q.is_empty() {
        sqlx::query(
            r#"
            SELECT id, author_iid, author_name, slug, title, summary, body_md, tags_json::text,
                   install_count, rating, is_verified, status, price_usd, price_idr, billing_period
            FROM ai.skill_catalog
            WHERE deleted_ts IS NULL AND status = 'published'
            ORDER BY install_count DESC, title ASC
            LIMIT $1
            "#,
        )
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default()
    } else {
        sqlx::query(
            r#"
            SELECT id, author_iid, author_name, slug, title, summary, body_md, tags_json::text,
                   install_count, rating, is_verified, status, price_usd, price_idr, billing_period
            FROM ai.skill_catalog
            WHERE deleted_ts IS NULL AND status = 'published'
              AND (LOWER(title) LIKE $1 OR LOWER(summary) LIKE $1 OR LOWER(slug) LIKE $1
                   OR LOWER(tags_json::text) LIKE $1 OR LOWER(source) LIKE $1 OR LOWER(author_name) LIKE $1)
            ORDER BY install_count DESC, title ASC
            LIMIT $2
            "#,
        )
        .bind(format!("%{q}%"))
        .bind(limit)
        .fetch_all(pool)
        .await
        .unwrap_or_default()
    };

    let catalogs = rows.iter().map(|row| catalog_from_row(row)).collect();
    ResSkillCatalogList { catalogs }
}

/// Phase 7: Ranked catalog search — used by agent dispatcher and Flutter catalog browser.
/// Score = (installs*0.3) + (rating*6.0) + (success_rate*30.0).
pub async fn skill_catalog_search_rpc(
    pool: &PgPool,
    _caller_iid: i64,
    req: ReqSkillCatalogSearch,
) -> ResSkillCatalogSearch {
    let q = req.q.trim().to_lowercase();
    let limit = if req.limit <= 0 { 10 } else { req.limit.min(20) };
    let offset = req.offset.max(0);

    let rows = sqlx::query(
        r#"
        SELECT sc.id, sc.author_iid, sc.author_name, sc.slug, sc.title, sc.summary,
               sc.body_md, sc.tags_json::text, sc.install_count, sc.rating,
               sc.is_verified, sc.status, sc.price_usd, sc.price_idr, sc.billing_period,
               (
                   sc.install_count::float * 0.3
                   + sc.rating::float * 6.0
                   + CASE WHEN (COALESCE(scr.success_count,0) + COALESCE(scr.fail_count,0)) > 0
                       THEN (COALESCE(scr.success_count,0)::float /
                             (COALESCE(scr.success_count,0) + COALESCE(scr.fail_count,0))::float) * 30.0
                       ELSE 15.0 END
               ) AS score
        FROM ai.skill_catalog sc
        LEFT JOIN LATERAL (
            SELECT scv.id AS variant_id
            FROM ai.skill_catalog_variant scv
            WHERE scv.catalog_id = sc.id AND scv.deleted_ts IS NULL
            ORDER BY scv.priority DESC, scv.id ASC
            LIMIT 1
        ) best_v ON TRUE
        LEFT JOIN LATERAL (
            SELECT scr2.success_count, scr2.fail_count
            FROM ai.skill_catalog_release scr2
            WHERE scr2.variant_id = best_v.variant_id
              AND scr2.is_current = TRUE AND scr2.deleted_ts IS NULL
            LIMIT 1
        ) scr ON TRUE
        WHERE sc.deleted_ts IS NULL
          AND sc.status IN ('published', 'pending_review')
          AND ($1::text = '' OR LOWER(sc.title) LIKE $1
               OR LOWER(sc.summary) LIKE $1 OR LOWER(sc.tags_json::text) LIKE $1
               OR LOWER(sc.author_name) LIKE $1)
        ORDER BY score DESC, sc.install_count DESC
        LIMIT $2 OFFSET $3
        "#,
    )
    .bind(if q.is_empty() { String::new() } else { format!("%{q}%") })
    .bind(limit)
    .bind(offset)
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    let total = rows.len() as i32;
    let catalogs = rows.iter().map(|row| catalog_from_row(row)).collect();
    ResSkillCatalogSearch { catalogs, total }
}



/// Phase 7: Safe auto-submit to Alien AI Public Skill Library.
/// Deduplicates by body hash. Handles: new entry, improvement vote, new version release.
/// New entries start as 'pending_review' and auto-approve after 3 other-user successes.
pub async fn skill_catalog_submit_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSkillCatalogSubmit,
) -> Result<ResSkillCatalogSubmit, String> {
    if req.skill_id == 0 {
        return Err("skill_id required".into());
    }

    let skill_row = sqlx::query(
        r#"
        SELECT id, owner_iid, title, body_md, target_app, url_pattern,
               surface, tags_json::text, detected_app_version
        FROM ai.skill
        WHERE id = $1 AND deleted_ts IS NULL
        "#,
    )
    .bind(req.skill_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "skill not found".to_string())?;

    let owner_iid: i64 = skill_row.get("owner_iid");
    if owner_iid != caller_iid {
        return Err("forbidden".into());
    }

    let body_md: String = skill_row.get("body_md");
    let computed_hash = hash_body(&body_md);
    let title: String = skill_row.get("title");
    let target_app: String = skill_row.get("target_app");
    let url_pattern: String = skill_row.get("url_pattern");
    let surface: String = skill_row.get("surface");
    let tags_json: String = skill_row.get("tags_json");
    let detected_app_version: String = skill_row.try_get("detected_app_version").unwrap_or_default();

    // Rate limit: 1 submit per hour per user per title
    let recent: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.skill_catalog
        WHERE author_iid = $1 AND LOWER(title) = LOWER($2)
          AND created_ts > NOW() - INTERVAL '1 hour' AND deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(caller_iid)
    .bind(&title)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    if recent.is_some() {
        return Ok(ResSkillCatalogSubmit {
            catalog_id: recent.unwrap_or(0),
            status: "rate_limited".to_string(),
            message: "Already submitted recently. Wait 1 hour before resubmitting.".to_string(),
        });
    }

    // Dedup: identical body hash already in catalog?
    let existing_by_hash: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT sc.id FROM ai.skill_catalog sc
        JOIN ai.skill_catalog_variant scv ON scv.catalog_id = sc.id AND scv.deleted_ts IS NULL
        JOIN ai.skill_catalog_release scr ON scr.variant_id = scv.id AND scr.deleted_ts IS NULL
        WHERE scr.hash_blake3 = $1 AND sc.deleted_ts IS NULL
        LIMIT 1
        "#,
    )
    .bind(&computed_hash)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;

    if let Some(cat_id) = existing_by_hash {
        let _ = sqlx::query(
            r#"
            UPDATE ai.skill_catalog
            SET contributor_iids_json =
                CASE WHEN contributor_iids_json @> $2::jsonb THEN contributor_iids_json
                     ELSE contributor_iids_json || $2::jsonb END,
                updated_ts = NOW()
            WHERE id = $1
            "#,
        )
        .bind(cat_id)
        .bind(serde_json::json!([caller_iid]).to_string())
        .execute(pool)
        .await;
        return Ok(ResSkillCatalogSubmit {
            catalog_id: cat_id,
            status: "already_published".to_string(),
            message: "This skill is already in the Alien AI Public Skill Library.".to_string(),
        });
    }

    // New version for an existing catalog entry
    if (req.submit_action == "new_version" || req.submit_action == "improvement")
        && req.existing_catalog_id > 0
    {
        let variant_id: Option<i64> = sqlx::query_scalar(
            r#"
            SELECT id FROM ai.skill_catalog_variant
            WHERE catalog_id = $1 AND deleted_ts IS NULL
            ORDER BY priority DESC, id ASC LIMIT 1
            "#,
        )
        .bind(req.existing_catalog_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;

        if let Some(vid) = variant_id {
            let _ = sqlx::query(
                "UPDATE ai.skill_catalog_release SET is_current = FALSE, updated_ts = NOW() WHERE variant_id = $1"
            )
            .bind(vid)
            .execute(pool)
            .await;

            let last_semver: Option<String> = sqlx::query_scalar(
                "SELECT semver FROM ai.skill_catalog_release WHERE variant_id = $1 ORDER BY published_ts DESC LIMIT 1"
            )
            .bind(vid)
            .fetch_optional(pool)
            .await
            .unwrap_or(None);
            let next_semver = bump_semver_patch(last_semver.as_deref().unwrap_or("1.0.0"));

            let release_id = snowflake_id();
            sqlx::query(
                r#"
                INSERT INTO ai.skill_catalog_release
                    (id, variant_id, semver, body_md, hash_blake3, is_current,
                     success_count, fail_count, published_ts, created_ts, updated_ts)
                VALUES ($1, $2, $3, $4, $5, TRUE, 0, 0, NOW(), NOW(), NOW())
                "#,
            )
            .bind(release_id)
            .bind(vid)
            .bind(next_semver)
            .bind(&body_md)
            .bind(&computed_hash)
            .execute(pool)
            .await
            .map_err(|e| e.to_string())?;

            let _ = sqlx::query(
                r#"
                UPDATE ai.skill_catalog
                SET contributor_iids_json =
                    CASE WHEN contributor_iids_json @> $2::jsonb THEN contributor_iids_json
                         ELSE contributor_iids_json || $2::jsonb END,
                    status = 'pending_review', updated_ts = NOW()
                WHERE id = $1
                "#,
            )
            .bind(req.existing_catalog_id)
            .bind(serde_json::json!([caller_iid]).to_string())
            .execute(pool)
            .await;

            return Ok(ResSkillCatalogSubmit {
                catalog_id: req.existing_catalog_id,
                status: "pending_review".to_string(),
                message: "New version submitted to Alien AI Public Skill Library — pending review.".to_string(),
            });
        }
    }

    // Create new catalog entry
    let slug = make_unique_slug(pool, &title).await?;
    let catalog_id = snowflake_id();
    let variant_id = snowflake_id();
    let release_id = snowflake_id();

    sqlx::query(
        r#"
        INSERT INTO ai.skill_catalog (
            id, author_iid, author_name, slug, title, summary, body_md,
            tags_json, source, source_url, install_count, rating, is_verified, status,
            price_usd, price_idr, billing_period, contributor_iids_json, created_ts, updated_ts
        ) VALUES (
            $1, $2, '', $3, $4, $5, $6,
            $7::jsonb, 'community', '', 0, 5.0, FALSE, 'pending_review',
            0, 0, 'free', $8::jsonb, NOW(), NOW()
        )
        "#,
    )
    .bind(catalog_id)
    .bind(caller_iid)
    .bind(&slug)
    .bind(&title)
    .bind(title.trim())
    .bind(&body_md)
    .bind(if tags_json.trim().is_empty() { "[]" } else { tags_json.trim() })
    .bind(serde_json::json!([caller_iid]).to_string())
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    sqlx::query(
        r#"
        INSERT INTO ai.skill_catalog_variant (
            id, catalog_id, variant_key, platform, surface, target_app, url_pattern,
            phrases_json, priority, target_app_version_min, target_app_version_max,
            created_ts, updated_ts
        ) VALUES (
            $1, $2, 'default', 'any', $3, $4, $5,
            '[]'::jsonb, 0, $6, $6, NOW(), NOW()
        )
        "#,
    )
    .bind(variant_id)
    .bind(catalog_id)
    .bind(&surface)
    .bind(&target_app)
    .bind(&url_pattern)
    .bind(&detected_app_version)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    sqlx::query(
        r#"
        INSERT INTO ai.skill_catalog_release (
            id, variant_id, semver, body_md, hash_blake3, is_current,
            success_count, fail_count, published_ts, created_ts, updated_ts
        ) VALUES ($1, $2, '1.0.0', $3, $4, TRUE, 0, 0, NOW(), NOW(), NOW())
        "#,
    )
    .bind(release_id)
    .bind(variant_id)
    .bind(&body_md)
    .bind(&computed_hash)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    Ok(ResSkillCatalogSubmit {
        catalog_id,
        status: "pending_review".to_string(),
        message: "Submitted to Alien AI Public Skill Library — pending review. Auto-publishes after 3 successful runs by other users.".to_string(),
    })
}

/// Phase 7: Agent reports skill execution result for success-rate tracking and auto-approval.
/// Looks up catalog_release_id from skill_id, then increments success/fail counters.
/// Auto-approves catalog entries that accumulate >= 3 successes from other users.
pub async fn skill_run_report_rpc(
    pool: &PgPool,
    _caller_iid: i64,
    req: ReqSkillRunReport,
) -> Result<ResSkillRunReport, String> {
    if req.skill_id == 0 {
        return Ok(ResSkillRunReport {
            accepted: false,
            message: "skill_id required".to_string(),
        });
    }

    // Look up the catalog_release_id for this skill
    let catalog_release_id: Option<i64> = sqlx::query_scalar(
        "SELECT catalog_release_id FROM ai.skill WHERE id = $1 AND deleted_ts IS NULL",
    )
    .bind(req.skill_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;

    let release_id = match catalog_release_id {
        Some(id) if id > 0 => id,
        _ => {
            return Ok(ResSkillRunReport {
                accepted: true,
                message: "local skill, no catalog tracking".to_string(),
            });
        }
    };

    if req.success {
        sqlx::query(
            "UPDATE ai.skill_catalog_release SET success_count = success_count + 1, updated_ts = NOW() WHERE id = $1"
        )
        .bind(release_id)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;

        // Auto-approve: pending_review → published when success_count >= 3
        let _ = sqlx::query(
            r#"
            UPDATE ai.skill_catalog sc
            SET status = 'published', updated_ts = NOW()
            FROM ai.skill_catalog_variant scv
            JOIN ai.skill_catalog_release scr ON scr.variant_id = scv.id
            WHERE scv.catalog_id = sc.id
              AND scr.id = $1
              AND sc.status = 'pending_review'
              AND scr.success_count >= 3
            "#,
        )
        .bind(release_id)
        .execute(pool)
        .await;
    } else {
        sqlx::query(
            "UPDATE ai.skill_catalog_release SET fail_count = fail_count + 1, updated_ts = NOW() WHERE id = $1"
        )
        .bind(release_id)
        .execute(pool)
        .await
        .map_err(|e| e.to_string())?;
    }

    Ok(ResSkillRunReport {
        accepted: true,
        message: if req.success {
            "reported success".to_string()
        } else {
            format!("reported failure: {}", req.error)
        },
    })
}


pub async fn skill_catalog_install_rpc(
    pool: &PgPool,
    caller_iid: i64,
    req: ReqSkillCatalogInstall,
) -> Result<ResSkillCatalogInstall, String> {
    if req.catalog_id == 0 {
        return Err("catalog_id required".into());
    }
    let scope = scope_db(req.scope);
    if scope == "device" && req.device_iid == 0 {
        return Err("device_iid required for device scope".into());
    }

    let catalog = sqlx::query(
        r#"
        SELECT id, author_iid, author_name, title, summary, body_md, tags_json::text,
               price_usd, price_idr, billing_period
        FROM ai.skill_catalog
        WHERE id = $1 AND deleted_ts IS NULL AND status = 'published'
        "#,
    )
    .bind(req.catalog_id)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?
    .ok_or_else(|| "catalog not found".to_string())?;

    let price_idr: f64 = catalog.try_get::<f64, _>("price_idr").unwrap_or(0.0);
    let price_usd: f64 = catalog.try_get::<f64, _>("price_usd").unwrap_or(0.0);

    let existing: Option<i64> = sqlx::query_scalar(
        r#"
        SELECT id FROM ai.skill
        WHERE owner_iid = $1 AND catalog_id = $2 AND deleted_ts IS NULL
          AND ($3::bigint = 0 OR device_iid = $3)
        LIMIT 1
        "#,
    )
    .bind(caller_iid)
    .bind(req.catalog_id)
    .bind(req.device_iid)
    .fetch_optional(pool)
    .await
    .map_err(|e| e.to_string())?;
    if existing.is_some() {
        return Err("skill already installed".into());
    }

    charge_install(pool, caller_iid, price_idr, price_usd).await?;

    let variant_id = if req.variant_id > 0 {
        req.variant_id
    } else {
        sqlx::query_scalar(
            r#"
            SELECT id FROM ai.skill_catalog_variant
            WHERE catalog_id = $1 AND deleted_ts IS NULL
            ORDER BY priority DESC, id ASC
            LIMIT 1
            "#,
        )
        .bind(req.catalog_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?
        .unwrap_or(0)
    };

    let release = if req.release_id > 0 {
        sqlx::query(
            r#"
            SELECT id, body_md, hash_blake3
            FROM ai.skill_catalog_release
            WHERE id = $1 AND deleted_ts IS NULL
            "#,
        )
        .bind(req.release_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?
    } else if variant_id > 0 {
        sqlx::query(
            r#"
            SELECT id, body_md, hash_blake3
            FROM ai.skill_catalog_release
            WHERE variant_id = $1 AND is_current = TRUE AND deleted_ts IS NULL
            ORDER BY published_ts DESC
            LIMIT 1
            "#,
        )
        .bind(variant_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?
    } else {
        None
    };

    let body_md = release
        .as_ref()
        .map(|r| r.get::<String, _>("body_md"))
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| catalog.get::<String, _>("body_md"));
    let release_id = release.as_ref().map(|r| r.get::<i64, _>("id")).unwrap_or(0);
    let hash = release
        .as_ref()
        .map(|r| r.get::<String, _>("hash_blake3"))
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| hash_body(&body_md));

    let skill_id = snowflake_id();
    let title = catalog.get::<String, _>("title");
    let author_name = catalog.get::<String, _>("author_name");
    let tags_json = catalog.get::<String, _>("tags_json");

    sqlx::query(
        r#"
        INSERT INTO ai.skill (
            id, owner_iid, scope, device_iid, team_iid, title, hash_blake3, body_md,
            source, catalog_id, catalog_variant_id, catalog_release_id, author_name,
            tags_json, phrases_json, auto_run, auto_submit, created_ts, updated_ts
        ) VALUES (
            $1, $2, $3, $4, 0, $5, $6, $7,
            'catalog', $8, $9, $10, $11,
            $12::jsonb, '[]'::jsonb, TRUE, FALSE, NOW(), NOW()
        )
        "#,
    )
    .bind(skill_id)
    .bind(caller_iid)
    .bind(scope)
    .bind(req.device_iid)
    .bind(&title)
    .bind(&hash)
    .bind(&body_md)
    .bind(req.catalog_id)
    .bind(variant_id)
    .bind(release_id)
    .bind(&author_name)
    .bind(if tags_json.trim().is_empty() { "[]" } else { tags_json.trim() })
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    sqlx::query(
        "UPDATE ai.skill_catalog SET install_count = install_count + 1, updated_ts = NOW() WHERE id = $1",
    )
    .bind(req.catalog_id)
    .execute(pool)
    .await
    .map_err(|e| e.to_string())?;

    let row = sqlx::query(
        r#"
        SELECT id, owner_iid, scope, device_iid, team_iid, title, hash_blake3, body_md,
               source, catalog_id, catalog_variant_id, catalog_release_id, author_name,
               tags_json, phrases_json, auto_run, surface, target_app, url_pattern,
               patch_epoch, patch_count, consecutive_ok, detected_app_version, auto_submit,
               last_patched_ts, created_ts, updated_ts, deleted_ts
        FROM ai.skill WHERE id = $1
        "#,
    )
    .bind(skill_id)
    .fetch_one(pool)
    .await
    .map_err(|e| e.to_string())?;

    let skill = skill_from_row(&row);
    Ok(ResSkillCatalogInstall { skill: Some(skill) })
}

// ── helpers ──────────────────────────────────────────────────────────────────

async fn charge_install(pool: &PgPool, buyer_iid: i64, price_idr: f64, price_usd: f64) -> Result<(), String> {
    if price_idr <= 0.0 && price_usd <= 0.0 {
        return Ok(());
    }
    let mut tx = pool.begin().await.map_err(|e| e.to_string())?;
    let account = sqlx::query(
        r#"SELECT id, balance_idr, balance_usd FROM ai.billing_account
           WHERE owner_iid = $1 AND deleted_ts IS NULL LIMIT 1 FOR UPDATE"#,
    )
    .bind(buyer_iid)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|e| e.to_string())?;
    let Some(account) = account else {
        return Err("billing account not found".into());
    };
    let account_id: i64 = account.get("id");
    let balance_idr: f64 = account.get("balance_idr");
    let balance_usd: f64 = account.get("balance_usd");
    let charge_idr = price_idr.round();
    let charge_usd = price_usd;
    if charge_idr > 0.0 {
        if balance_idr + 0.001 < charge_idr {
            return Err("insufficient balance".into());
        }
        sqlx::query("UPDATE ai.billing_account SET balance_idr = balance_idr - $2, updated_ts = NOW() WHERE id = $1")
            .bind(account_id)
            .bind(charge_idr)
            .execute(&mut *tx)
            .await
            .map_err(|e| e.to_string())?;
    } else if charge_usd > 0.0 {
        if balance_usd + 0.000001 < charge_usd {
            return Err("insufficient balance".into());
        }
        sqlx::query("UPDATE ai.billing_account SET balance_usd = balance_usd - $2, updated_ts = NOW() WHERE id = $1")
            .bind(account_id)
            .bind(charge_usd)
            .execute(&mut *tx)
            .await
            .map_err(|e| e.to_string())?;
    }
    tx.commit().await.map_err(|e| e.to_string())?;
    Ok(())
}

fn bump_semver_patch(semver: &str) -> String {
    let parts: Vec<&str> = semver.splitn(3, '.').collect();
    if parts.len() == 3 {
        if let Ok(patch) = parts[2].parse::<u32>() {
            return format!("{}.{}.{}", parts[0], parts[1], patch + 1);
        }
    }
    "1.0.1".to_string()
}

async fn make_unique_slug(pool: &PgPool, title: &str) -> Result<String, String> {
    let base: String = title
        .to_lowercase()
        .chars()
        .map(|c| if c.is_alphanumeric() { c } else { '-' })
        .collect::<String>()
        .split('-')
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join("-");
    let base = if base.len() > 80 { base[..80].to_string() } else { base };

    for i in 0u32..=99 {
        let candidate = if i == 0 { base.clone() } else { format!("{base}-{i}") };
        let taken: Option<i64> = sqlx::query_scalar(
            "SELECT id FROM ai.skill_catalog WHERE LOWER(slug) = LOWER($1) AND deleted_ts IS NULL LIMIT 1",
        )
        .bind(&candidate)
        .fetch_optional(pool)
        .await
        .map_err(|e| e.to_string())?;
        if taken.is_none() {
            return Ok(candidate);
        }
    }
    Err("could not generate unique slug".into())
}
