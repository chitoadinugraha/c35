-- ==============================================================================
-- c35 — Consumption schema (LOCKED 2026-09-20)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: ai
--
-- Personal health tracker on user identity only.
-- Port: id.alienai nutrition model + cs_agent meal logging shape.
-- Query by day: snowflake id range on owner_iid.
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS ai;

-- ------------------------------------------------------------------------------
-- Consumption (meal / snack log)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.consumption (
    id                  BIGINT PRIMARY KEY,                     -- snowflake; encodes logged day
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    note                TEXT NOT NULL DEFAULT '',
    photo_hash          VARCHAR(64) NOT NULL DEFAULT '',        -- blake3 of primary photo
    meal_fingerprint    VARCHAR(64) NOT NULL DEFAULT '',
    meal_type           VARCHAR(32) NOT NULL DEFAULT 'other',   -- breakfast | lunch | …
    pics_json           JSONB NOT NULL DEFAULT '[]',
    logged_ts           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_archived         BOOLEAN NOT NULL DEFAULT FALSE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    CONSTRAINT chk_consumption_meal_type CHECK (
        meal_type IN (
            'other', 'breakfast', 'lunch', 'dinner',
            'snack', 'dessert', 'late_night'
        )
    )
);

CREATE INDEX IF NOT EXISTS idx_consumption_owner_sync
    ON ai.consumption (owner_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_consumption_owner_day
    ON ai.consumption (owner_iid, id DESC)
    WHERE deleted_ts IS NULL AND is_archived = FALSE;
CREATE INDEX IF NOT EXISTS idx_consumption_photo
    ON ai.consumption (owner_iid, photo_hash)
    WHERE photo_hash <> '' AND deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Consumption item (denormalized nutrition per line)
-- Values are totals for qty (qty × per-serving), same as id.alienai u_consume_item.
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.consumption_item (
    consumption_id      BIGINT NOT NULL REFERENCES ai.consumption(id) ON DELETE CASCADE,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    idx                 SMALLINT NOT NULL DEFAULT 0,

    name                TEXT NOT NULL DEFAULT '',
    name_id             TEXT NOT NULL DEFAULT '',
    qty                 REAL NOT NULL DEFAULT 1,
    pic                 TEXT NOT NULL DEFAULT '',
    obj_id              BIGINT NOT NULL DEFAULT 0,              -- references ai.object_normalizer(id)

    calories            INT NOT NULL DEFAULT 0,                  -- kcal
    protein             INT NOT NULL DEFAULT 0,                  -- g
    fat                 INT NOT NULL DEFAULT 0,                  -- g
    carbs               INT NOT NULL DEFAULT 0,                  -- g
    fiber               INT NOT NULL DEFAULT 0,                  -- g
    sugar               INT NOT NULL DEFAULT 0,                  -- g
    sodium              INT NOT NULL DEFAULT 0,                  -- mg
    potassium           INT NOT NULL DEFAULT 0,                  -- mg
    vitamin_a           INT NOT NULL DEFAULT 0,                  -- IU
    vitamin_c           INT NOT NULL DEFAULT 0,                  -- mg
    vitamin_d           INT NOT NULL DEFAULT 0,                  -- IU
    vitamin_e           INT NOT NULL DEFAULT 0,                  -- IU
    vitamin_k           INT NOT NULL DEFAULT 0,                  -- mcg
    calcium             INT NOT NULL DEFAULT 0,                  -- mg
    iron                INT NOT NULL DEFAULT 0,                  -- mg
    magnesium           INT NOT NULL DEFAULT 0,                  -- mg
    phosphorus          INT NOT NULL DEFAULT 0,                  -- mg
    zinc                INT NOT NULL DEFAULT 0,                  -- mg
    copper              INT NOT NULL DEFAULT 0,                  -- mcg

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (consumption_id, idx)
);

ALTER TABLE ai.consumption_item ADD COLUMN IF NOT EXISTS obj_id BIGINT NOT NULL DEFAULT 0;
-- cholesterol, purines: mg per serving
ALTER TABLE ai.consumption_item ADD COLUMN IF NOT EXISTS cholesterol INT NOT NULL DEFAULT 0;
ALTER TABLE ai.consumption_item ADD COLUMN IF NOT EXISTS purines INT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_consumption_item_owner
    ON ai.consumption_item (owner_iid, consumption_id);
CREATE INDEX IF NOT EXISTS idx_consumption_item_obj
    ON ai.consumption_item (owner_iid, obj_id)
    WHERE obj_id > 0 AND deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Water intake (daily rollup)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.consumption_water (
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    day_id              VARCHAR(10) NOT NULL,                   -- YYYY-MM-DD in user tz
    ml                  INT NOT NULL DEFAULT 0,
    goal_ml             INT NOT NULL DEFAULT 0,                 -- 0 = client default (2000)
    entry_count         INT NOT NULL DEFAULT 0,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (owner_iid, day_id)
);

CREATE INDEX IF NOT EXISTS idx_consumption_water_sync
    ON ai.consumption_water (owner_iid, updated_ts);

-- ------------------------------------------------------------------------------
-- Preferences (goals)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ai.consumption_prefs (
    owner_iid           BIGINT PRIMARY KEY REFERENCES ai.identity(id),
    calorie_goal_kcal   INT NOT NULL DEFAULT 2000,
    water_goal_ml       INT NOT NULL DEFAULT 2000,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ
);

-- Seed: prefs for automated tester (owner_iid 33000)
INSERT INTO ai.consumption_prefs (owner_iid, calorie_goal_kcal, water_goal_ml, updated_ts)
VALUES (33000, 2000, 2000, NOW())
ON CONFLICT (owner_iid) DO UPDATE SET
    calorie_goal_kcal = EXCLUDED.calorie_goal_kcal,
    water_goal_ml = EXCLUDED.water_goal_ml,
    updated_ts = NOW(),
    deleted_ts = NULL;
