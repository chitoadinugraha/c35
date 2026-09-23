use sqlx::PgPool;

pub async fn skill_catalog_ensure_seed(pool: &PgPool) {
    let seeds = [
        (
            1001i64,
            "web-scraper-digest",
            "Web Scraper & Digest",
            "Extract and synthesize key takeaways and statistics from any URL or web query.",
            "## Web Scraper & Digest (OpenSkill)\n\nWhen asked to summarize or research a webpage:\n1. Use web search or visit to retrieve the source.\n2. Extract facts, quotes, and quantitative metrics.\n3. Format output as an Executive Summary followed by Key Findings.",
            "OpenSkill Foundation",
            r#"["web", "research", "openskill"]"#,
            "openskill",
            "https://github.com/openskill/web-scraper",
            42i32,
            5.0f64,
            true,
        ),
        (
            1002i64,
            "competitor-intelligence",
            "Competitor Intelligence",
            "Analyze competitor product features, pricing models, and market positioning.",
            "## Competitor Intelligence (OpenSkill)\n\n1. Search competitor website and product announcements.\n2. Compare feature sets and pricing tiers.\n3. Present results in a structured Markdown comparison matrix.",
            "Alien AI Official",
            r#"["business", "marketing", "openskill"]"#,
            "openskill",
            "https://github.com/openskill/competitor-intel",
            28,
            4.9,
            true,
        ),
        (
            1003i64,
            "daily-standup-logger",
            "Daily Standup Logger",
            "Converts daily work notes and accomplishments into crisp, clean standup reports.",
            "## Daily Standup Logger\n\nWhen user describes their day's tasks, format into:\n- **Yesterday's Accomplishments**\n- **Today's Priorities**\n- **Blockers & Dependencies**",
            "Community Contributor",
            r#"["productivity", "notes", "community"]"#,
            "community",
            "",
            19,
            4.8,
            false,
        ),
    ];

    for s in seeds {
        let _ = sqlx::query(
            r#"
            INSERT INTO ai.skill_catalog (
                id, author_iid, author_name, slug, title, summary, body_md, tags_json,
                source, source_url, install_count, rating, is_verified, status,
                price_usd, price_idr, billing_period, created_ts, updated_ts
            ) VALUES (
                $1, 0, $2, $3, $4, $5, $6, $7::jsonb,
                $8, $9, $10, $11, $12, 'published',
                0, 0, 'free', NOW(), NOW()
            )
            ON CONFLICT (id) DO UPDATE SET
                title = EXCLUDED.title,
                summary = EXCLUDED.summary,
                body_md = EXCLUDED.body_md,
                tags_json = EXCLUDED.tags_json,
                source = EXCLUDED.source,
                updated_ts = NOW()
            "#,
        )
        .bind(s.0)
        .bind(s.5)
        .bind(s.1)
        .bind(s.2)
        .bind(s.3)
        .bind(s.4)
        .bind(s.6)
        .bind(s.7)
        .bind(s.8)
        .bind(s.9)
        .bind(s.10)
        .bind(s.11)
        .execute(pool)
        .await;
    }
}
