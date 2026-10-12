-- Guest visitor analytics (v1 rollups + v2 path/link tables)
-- Plan: _/specs/plans/2026-10-12-site-visitor-analytics-multitask.md

CREATE TABLE IF NOT EXISTS site.analytics_day (
    site_iid              BIGINT NOT NULL REFERENCES ai.identity(id),
    day_bucket            DATE NOT NULL,
    page_views            BIGINT NOT NULL DEFAULT 0,
    unique_visitors       INT NOT NULL DEFAULT 0,
    active_duration_ms    BIGINT NOT NULL DEFAULT 0,
    visitor_slots         JSONB NOT NULL DEFAULT '[]',
    created_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (site_iid, day_bucket)
);

CREATE INDEX IF NOT EXISTS idx_site_analytics_day_updated
    ON site.analytics_day (site_iid, updated_ts DESC);

CREATE TABLE IF NOT EXISTS site.analytics_visitor_day (
    site_iid              BIGINT NOT NULL REFERENCES ai.identity(id),
    day_bucket            DATE NOT NULL,
    visitor_key           TEXT NOT NULL,
    session_key           TEXT NOT NULL DEFAULT '',
    page_views            INT NOT NULL DEFAULT 0,
    active_duration_ms    BIGINT NOT NULL DEFAULT 0,
    last_path             TEXT NOT NULL DEFAULT '',
    last_seen_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    referrer_host         TEXT NOT NULL DEFAULT '',
    created_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (site_iid, day_bucket, visitor_key)
);

CREATE INDEX IF NOT EXISTS idx_site_analytics_visitor_day_seen
    ON site.analytics_visitor_day (site_iid, day_bucket, last_seen_ts DESC);

CREATE TABLE IF NOT EXISTS site.analytics_path_day (
    site_iid              BIGINT NOT NULL REFERENCES ai.identity(id),
    day_bucket            DATE NOT NULL,
    path                  TEXT NOT NULL,
    views                 INT NOT NULL DEFAULT 0,
    updated_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (site_iid, day_bucket, path)
);

CREATE TABLE IF NOT EXISTS site.analytics_link_day (
    site_iid              BIGINT NOT NULL REFERENCES ai.identity(id),
    day_bucket            DATE NOT NULL,
    link_id               BIGINT NOT NULL,
    clicks                INT NOT NULL DEFAULT 0,
    updated_ts            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (site_iid, day_bucket, link_id)
);
