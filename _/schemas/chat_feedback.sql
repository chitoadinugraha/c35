-- c35 chat answer feedback. Not a chat_msg row. Never packed into prompt history.

CREATE TABLE IF NOT EXISTS ai.chat_feedback_reason (
    id          SMALLINT PRIMARY KEY,
    slug        VARCHAR(32) NOT NULL,
    vote        VARCHAR(8) NOT NULL,
    label_en    TEXT NOT NULL,
    label_id    TEXT NOT NULL,
    sort        INT NOT NULL,
    active      BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_chat_feedback_reason_slug UNIQUE (slug),
    CONSTRAINT chk_chat_feedback_reason_vote CHECK (vote IN ('good', 'bad'))
);

INSERT INTO ai.chat_feedback_reason (id, slug, vote, label_en, label_id, sort) VALUES
    (1,  'accurate',     'good', 'Correct',                  'Benar',                          10),
    (2,  'helpful',      'good', 'Solved the request',       'Menyelesaikan permintaan',       20),
    (3,  'followed',     'good', 'Followed instructions',    'Mengikuti instruksi',            30),
    (4,  'right_tool',   'good', 'Right tool or data',       'Tool atau data yang tepat',      40),
    (5,  'clear',        'good', 'Clear',                    'Jelas',                          50),
    (6,  'wrong',        'bad',  'Wrong answer',             'Jawaban salah',                  10),
    (7,  'incomplete',   'bad',  'Incomplete',               'Kurang atau tidak selesai',      20),
    (8,  'ignored',      'bad',  'Ignored instructions',     'Tidak mengikuti instruksi',      30),
    (9,  'wrong_tool',   'bad',  'Wrong or missing tool',    'Tool salah atau tidak dipanggil', 40),
    (10, 'hallucinated', 'bad',  'Made up data',             'Mengarang data',                 50),
    (11, 'bad_format',   'bad',  'Broken layout',            'Tampilan rusak',                 60),
    (12, 'other',        'bad',  'Other',                    'Lainnya',                        70)
ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    vote = EXCLUDED.vote,
    label_en = EXCLUDED.label_en,
    label_id = EXCLUDED.label_id,
    sort = EXCLUDED.sort;

CREATE TABLE IF NOT EXISTS ai.chat_msg_feedback (
    id          BIGINT PRIMARY KEY,
    msg_id      BIGINT NOT NULL REFERENCES ai.chat_msg(id) ON DELETE CASCADE,
    chat_id     BIGINT NOT NULL REFERENCES ai.chat(id) ON DELETE CASCADE,
    owner_iid   BIGINT NOT NULL REFERENCES ai.identity(id),
    rater_iid   BIGINT NOT NULL REFERENCES ai.identity(id),
    req_id      VARCHAR(64) NOT NULL DEFAULT '',
    vote        VARCHAR(8) NOT NULL,
    reason_id   SMALLINT NOT NULL REFERENCES ai.chat_feedback_reason(id),
    comment     TEXT NOT NULL DEFAULT '',
    created_ts  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts  TIMESTAMPTZ,
    CONSTRAINT chk_chat_msg_feedback_vote CHECK (vote IN ('good', 'bad'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_msg_feedback_msg_rater
    ON ai.chat_msg_feedback (msg_id, rater_iid);

CREATE INDEX IF NOT EXISTS idx_chat_msg_feedback_chat
    ON ai.chat_msg_feedback (chat_id, msg_id)
    WHERE deleted_ts IS NULL;

CREATE TABLE IF NOT EXISTS ai.chat_feedback_post (
    id           BIGINT PRIMARY KEY,
    feedback_id  BIGINT NOT NULL REFERENCES ai.chat_msg_feedback(id) ON DELETE CASCADE,
    author_iid   BIGINT NULL REFERENCES ai.identity(id),
    author_role  VARCHAR(16) NOT NULL,
    text         TEXT NOT NULL,
    created_ts   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts   TIMESTAMPTZ,
    CONSTRAINT chk_chat_feedback_post_role CHECK (author_role IN ('system', 'user', 'staff'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_chat_feedback_post_system
    ON ai.chat_feedback_post (feedback_id)
    WHERE author_role = 'system' AND deleted_ts IS NULL;

CREATE INDEX IF NOT EXISTS idx_chat_feedback_post_feedback
    ON ai.chat_feedback_post (feedback_id, created_ts)
    WHERE deleted_ts IS NULL;
