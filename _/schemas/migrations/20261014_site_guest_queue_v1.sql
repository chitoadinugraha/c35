-- Guest queue CSA parity: runs + ticket lifecycle (track_token, fields, board).

CREATE TABLE IF NOT EXISTS site.queue_run (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    run_id              BIGINT NOT NULL,
    queue_id            BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    next_number         INT NOT NULL DEFAULT 1,
    serving_number      INT NOT NULL DEFAULT 0,
    status              VARCHAR(16) NOT NULL DEFAULT 'open',
    reset_reason        VARCHAR(32) NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_ts           TIMESTAMPTZ,

    PRIMARY KEY (site_iid, run_id),
    FOREIGN KEY (site_iid, queue_id) REFERENCES site.queue (site_iid, queue_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_site_queue_run_open
    ON site.queue_run (site_iid, queue_id)
    WHERE status = 'open' AND closed_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_site_queue_run_queue
    ON site.queue_run (site_iid, queue_id, created_ts DESC);

ALTER TABLE site.queue
    ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS fields JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS take_online BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS reset_policy JSONB NOT NULL DEFAULT '{"mode":"daily","at":"00:00","timezone":"Asia/Jakarta"}'::jsonb,
    ADD COLUMN IF NOT EXISTS sort_order INT NOT NULL DEFAULT 0;

ALTER TABLE site.queue_ticket
    ADD COLUMN IF NOT EXISTS run_id BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS track_token VARCHAR(64) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS display_label TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS answers JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS called_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS done_at TIMESTAMPTZ;

CREATE UNIQUE INDEX IF NOT EXISTS idx_site_queue_ticket_track_token
    ON site.queue_ticket (track_token)
    WHERE track_token <> '' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_site_queue_ticket_run_status
    ON site.queue_ticket (site_iid, queue_id, run_id, status)
    WHERE deleted_ts IS NULL;

-- Backfill: one open run per active queue; attach tickets; seed counters from queue row.
INSERT INTO site.queue_run (
    site_iid, run_id, queue_id, owner_iid,
    next_number, serving_number, status, reset_reason,
    created_ts, updated_ts
)
SELECT
    q.site_iid,
    q.queue_id * 1000000 + 1,
    q.queue_id,
    q.owner_iid,
    GREATEST(q.last_ticket_no + 1, 1),
    GREATEST(q.serving_ticket_no, 0),
    'open',
    'migration',
    COALESCE(q.created_ts, NOW()),
    NOW()
FROM site.queue q
WHERE q.deleted_ts IS NULL
ON CONFLICT (site_iid, run_id) DO NOTHING;

UPDATE site.queue_ticket t
SET run_id = t.queue_id * 1000000 + 1
WHERE t.deleted_ts IS NULL
  AND t.run_id = 0
  AND EXISTS (
      SELECT 1 FROM site.queue_run r
      WHERE r.site_iid = t.site_iid
        AND r.queue_id = t.queue_id
        AND r.status = 'open'
  );

UPDATE site.queue_ticket t
SET display_label = CASE
        WHEN COALESCE(q.prefix, '') = '' THEN LPAD(t.ticket_no::text, 3, '0')
        ELSE TRIM(q.prefix) || '-' || LPAD(t.ticket_no::text, 3, '0')
    END
FROM site.queue q
WHERE q.site_iid = t.site_iid
  AND q.queue_id = t.queue_id
  AND t.deleted_ts IS NULL
  AND t.display_label = '';

UPDATE site.queue_ticket t
SET track_token = 'qt_' || t.ticket_id::text
WHERE t.deleted_ts IS NULL
  AND (t.track_token = '' OR t.track_token IS NULL);
