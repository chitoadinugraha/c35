-- Ephemeral Google OAuth state (multi-replica safe; not user data).
CREATE TABLE IF NOT EXISTS ai.oauth_pending (
    state         TEXT PRIMARY KEY,
    client_id     TEXT NOT NULL,
    return_path   TEXT NOT NULL,
    origin        TEXT NOT NULL,
    expires_at    TIMESTAMPTZ NOT NULL,
    created_ts    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_oauth_pending_expires ON ai.oauth_pending (expires_at);
CREATE TABLE IF NOT EXISTS ai.oauth_result (
    client_id     TEXT PRIMARY KEY,
    oauth_state   TEXT NOT NULL,
    return_path   TEXT NOT NULL,
    origin        TEXT NOT NULL,
    ready         BOOLEAN NOT NULL DEFAULT TRUE,
    ok            BOOLEAN NOT NULL DEFAULT FALSE,
    uid           BIGINT,
    token         TEXT,
    name          TEXT,
    email         TEXT,
    pic           TEXT,
    handle        TEXT,
    expires_at    TIMESTAMPTZ NOT NULL,
    created_ts    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_oauth_result_state ON ai.oauth_result (oauth_state);
CREATE INDEX IF NOT EXISTS idx_oauth_result_expires ON ai.oauth_result (expires_at);