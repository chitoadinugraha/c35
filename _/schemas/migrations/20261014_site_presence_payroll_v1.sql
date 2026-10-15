-- Optional staff attendance + payroll compensation (c35 grantee_iid model)

CREATE TABLE IF NOT EXISTS site.presence_record (
    record_id           BIGINT PRIMARY KEY,
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    grantee_iid         BIGINT NOT NULL REFERENCES ai.identity(id),
    shift_id            TEXT NOT NULL DEFAULT '',
    kind                VARCHAR(16) NOT NULL,
    at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    session_id          TEXT NOT NULL DEFAULT '',
    work_duration_min   INT,
    attendance_method   VARCHAR(32) NOT NULL DEFAULT 'button',
    status              VARCHAR(16) NOT NULL DEFAULT 'verified',
    reason              TEXT NOT NULL DEFAULT '',
    lat                 DOUBLE PRECISION,
    lng                 DOUBLE PRECISION,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_site_presence_record_kind CHECK (kind IN ('clock_in', 'clock_out', 'leave')),
    CONSTRAINT chk_site_presence_record_status CHECK (status IN ('verified', 'flagged', 'rejected'))
);

CREATE INDEX IF NOT EXISTS idx_site_presence_record_site_grantee_at
    ON site.presence_record (site_iid, grantee_iid, at DESC);

CREATE INDEX IF NOT EXISTS idx_site_presence_record_session
    ON site.presence_record (site_iid, session_id)
    WHERE session_id <> '';

CREATE TABLE IF NOT EXISTS site.payroll_compensation (
    comp_id             BIGINT PRIMARY KEY,
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    grantee_iid         BIGINT NOT NULL REFERENCES ai.identity(id),
    pay_basis           VARCHAR(16) NOT NULL,
    amount              BIGINT NOT NULL DEFAULT 0,
    shift_id            TEXT NOT NULL DEFAULT '',
    effective_from      DATE NOT NULL DEFAULT CURRENT_DATE,
    label               TEXT NOT NULL DEFAULT '',
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,
    CONSTRAINT chk_site_payroll_comp_basis CHECK (pay_basis IN ('monthly', 'hourly')),
    CONSTRAINT chk_site_payroll_comp_amount CHECK (amount >= 0)
);

CREATE INDEX IF NOT EXISTS idx_site_payroll_comp_site_grantee
    ON site.payroll_compensation (site_iid, grantee_iid)
    WHERE deleted_ts IS NULL AND is_active = TRUE;
