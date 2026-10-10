-- ==============================================================================
-- c35 — Per-user / per-site assistant instructions (scope_instruction)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS ai.scope_instruction (
    id              BIGINT PRIMARY KEY,
    owner_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    scope_kind      VARCHAR(16) NOT NULL,
    scope_iid       BIGINT NOT NULL REFERENCES ai.identity(id),
    mode            VARCHAR(16) NOT NULL DEFAULT 'disabled',
    body            TEXT NOT NULL DEFAULT '',
    created_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts      TIMESTAMPTZ,

    CONSTRAINT chk_scope_instruction_kind CHECK (scope_kind IN ('user', 'site')),
    CONSTRAINT chk_scope_instruction_mode CHECK (mode IN ('always', 'auto', 'disabled'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_scope_instruction_scope
    ON ai.scope_instruction (scope_kind, scope_iid)
    WHERE deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_scope_instruction_owner
    ON ai.scope_instruction (owner_iid)
    WHERE deleted_ts IS NULL;
