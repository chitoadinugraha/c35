-- ==============================================================================
-- c35 — Transaction / POS schema (LOCKED 2026-09-21)
-- Database: c35 (YugabyteDB YSQL)
-- Schema: site
--
-- Port: id.alienai tx.proto (normalized child tables).
-- site_iid replaces aid. Money = BIGINT minor units.
-- UI: id.alienai transaksi editor; Sites page UITable list + ledger detail.
-- Apply after: identity.sql, site.sql (site schema must exist)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- COA category seed (platform catalog → default account codes per site)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_coa_category (
    slug            VARCHAR(32) PRIMARY KEY,
    label_id        TEXT NOT NULL,
    label_en        TEXT,
    acc_group       VARCHAR(16) NOT NULL,
    account_code    VARCHAR(16) NOT NULL,
    sort_order      INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_tx_coa_acc_group CHECK (acc_group IN ('revenue', 'expense'))
);

INSERT INTO site.tx_coa_category (slug, label_id, label_en, acc_group, account_code, sort_order) VALUES
    ('service',         'Jasa',                   'Service income',       'revenue',  '4201', 10),
    ('other_income',    'Pemasukan lain',         'Other income',         'revenue',  '4202', 20),
    ('interest_income', 'Bunga',                  'Interest income',      'revenue',  '4203', 30),
    ('refund_in',       'Pengembalian dana masuk','Refund received',     'revenue',  '4204', 40),
    ('supplies',        'Bahan / persediaan',     'Supplies',             'expense',  '6101', 10),
    ('rent',            'Sewa',                   'Rent',                 'expense',  '6102', 20),
    ('salary',          'Gaji',                   'Salary',               'expense',  '6103', 30),
    ('utilities',       'Listrik / air',          'Utilities',            'expense',  '6104', 40),
    ('transport',       'Transportasi',           'Transport',            'expense',  '6105', 50),
    ('marketing',       'Marketing',              'Marketing',            'expense',  '6106', 60),
    ('maintenance',     'Perawatan',              'Maintenance',          'expense',  '6107', 70),
    ('other_expense',   'Pengeluaran lain',       'Other expense',        'expense',  '6108', 80)
ON CONFLICT (slug) DO NOTHING;

-- ------------------------------------------------------------------------------
-- Tx header — PK (site_iid, tx_id) like id.alienai (aid, tx_id)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx (
    site_iid            BIGINT NOT NULL REFERENCES ai.identity(id),
    tx_id               BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),

    ty                  VARCHAR(32) NOT NULL,
    state               VARCHAR(32) NOT NULL,
    input_mode          VARCHAR(32) NOT NULL DEFAULT 'normal',
    input_source        VARCHAR(32) NOT NULL DEFAULT 'manual',

    is_archived         BOOLEAN NOT NULL DEFAULT FALSE,
    "desc"              TEXT NOT NULL DEFAULT '',
    time_ts             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by_iid      BIGINT REFERENCES ai.identity(id),
    cancel_reason       TEXT,

    subject_contact_id  BIGINT NOT NULL DEFAULT 0,
    subject_name        TEXT NOT NULL DEFAULT '',
    subject_phone       TEXT NOT NULL DEFAULT '',
    subject_address     TEXT NOT NULL DEFAULT '',
    cashier_name        TEXT NOT NULL DEFAULT '',

    store_id            BIGINT NOT NULL DEFAULT 0,
    store_tgt_id        BIGINT NOT NULL DEFAULT 0,
    delivery_state      VARCHAR(32) NOT NULL DEFAULT '',
    obj_id              BIGINT NOT NULL DEFAULT 0,
    promo_code          TEXT NOT NULL DEFAULT '',

    is_paid             BOOLEAN NOT NULL DEFAULT FALSE,
    is_task_assigned    BOOLEAN NOT NULL DEFAULT FALSE,
    order_pay_at        VARCHAR(32) NOT NULL DEFAULT '',

    items_count         BIGINT NOT NULL DEFAULT 0,
    items_qty           BIGINT NOT NULL DEFAULT 0,
    items_total         BIGINT NOT NULL DEFAULT 0,

    debt_total          BIGINT NOT NULL DEFAULT 0,
    debt_paid           BIGINT NOT NULL DEFAULT 0,
    debt_unpaid         BIGINT NOT NULL DEFAULT 0,

    total_taxes         BIGINT NOT NULL DEFAULT 0,
    total_discounts     BIGINT NOT NULL DEFAULT 0,
    total_interest      BIGINT NOT NULL DEFAULT 0,
    total_paid          BIGINT NOT NULL DEFAULT 0,
    total_unpaid        BIGINT NOT NULL DEFAULT 0,
    total               BIGINT NOT NULL DEFAULT 0,

    stock_line_count    INT NOT NULL DEFAULT 0,
    stock_qty_in        INT NOT NULL DEFAULT 0,
    stock_qty_out       INT NOT NULL DEFAULT 0,

    acc_line_count      INT NOT NULL DEFAULT 0,
    acc_sum             BIGINT NOT NULL DEFAULT 0,
    acc_balanced        BOOLEAN NOT NULL DEFAULT FALSE,
    has_manual_lines    BOOLEAN NOT NULL DEFAULT FALSE,
    generated_count     INT NOT NULL DEFAULT 0,
    manual_count        INT NOT NULL DEFAULT 0,

    tx_data_json        JSONB NOT NULL DEFAULT '{}',            -- proofs, prompt, delivery, promos

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id),

    CONSTRAINT chk_tx_ty CHECK (ty IN (
        'sale', 'purchase', 'transfer', 'adjustment',
        'return_sale', 'return_purchase', 'reservation', 'ship',
        'payment', 'receipt', 'debt_payable', 'debt_receivable', 'inventory'
    )),
    CONSTRAINT chk_tx_state CHECK (state IN (
        'ok', 'draft', 'pending', 'waiting_payment', 'cancelled'
    )),
    CONSTRAINT chk_tx_input_mode CHECK (input_mode IN (
        'normal', 'accounting', 'sell', 'purchase'
    )),
    CONSTRAINT chk_tx_input_source CHECK (input_source IN (
        'manual', 'web', 'ai', 'api'
    ))
);

CREATE INDEX IF NOT EXISTS idx_tx_site_sync
    ON site.tx (site_iid, updated_ts);
CREATE INDEX IF NOT EXISTS idx_tx_site_time
    ON site.tx (site_iid, time_ts DESC)
    WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_site_state
    ON site.tx (site_iid, state)
    WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_site_debt_open
    ON site.tx (site_iid, ty)
    WHERE debt_unpaid > 0 AND deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_owner_time_ok
    ON site.tx (owner_iid, time_ts DESC)
    INCLUDE (total)
    WHERE deleted_ts IS NULL AND state = 'ok';

-- ------------------------------------------------------------------------------
-- Tx item
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_item (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    item_id             BIGINT NOT NULL,
    owner_iid           BIGINT NOT NULL REFERENCES ai.identity(id),
    obj_id              BIGINT NOT NULL DEFAULT 0,              -- references ai.object_normalizer(id)

    product_id          BIGINT NOT NULL DEFAULT 0,
    product_rev         BIGINT NOT NULL DEFAULT 0,
    price               BIGINT NOT NULL DEFAULT 0,
    qty                 INT NOT NULL DEFAULT 0,
    note                TEXT NOT NULL DEFAULT '',

    batch_number        TEXT NOT NULL DEFAULT '',
    serial_number       TEXT NOT NULL DEFAULT '',
    lot_number          TEXT NOT NULL DEFAULT '',
    expiry_date         VARCHAR(10) NOT NULL DEFAULT '',
    assign_task         BOOLEAN NOT NULL DEFAULT FALSE,
    fulfillment_state   VARCHAR(32) NOT NULL DEFAULT '',

    total_qty           INT NOT NULL DEFAULT 0,
    total_price         BIGINT NOT NULL DEFAULT 0,
    total_discount      BIGINT NOT NULL DEFAULT 0,
    total_tax           BIGINT NOT NULL DEFAULT 0,
    total_net           BIGINT NOT NULL DEFAULT 0,
    total_paid          BIGINT NOT NULL DEFAULT 0,
    total_unpaid        BIGINT NOT NULL DEFAULT 0,
    total_interest      BIGINT NOT NULL DEFAULT 0,
    allocated_qty       INT NOT NULL DEFAULT 0,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, item_id),
    FOREIGN KEY (site_iid, tx_id) REFERENCES site.tx (site_iid, tx_id) ON DELETE CASCADE
);

ALTER TABLE site.tx_item ADD COLUMN IF NOT EXISTS owner_iid BIGINT NOT NULL DEFAULT 0;
ALTER TABLE site.tx_item ADD COLUMN IF NOT EXISTS obj_id BIGINT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_tx_item_tx
    ON site.tx_item (site_iid, tx_id);
CREATE INDEX IF NOT EXISTS idx_tx_item_owner_obj
    ON site.tx_item (owner_iid, obj_id)
    INCLUDE (qty, total_price)
    WHERE deleted_ts IS NULL;
CREATE INDEX IF NOT EXISTS idx_tx_item_obj
    ON site.tx_item (obj_id)
    WHERE obj_id > 0 AND deleted_ts IS NULL;

-- ------------------------------------------------------------------------------
-- Tx item reservation (booking lines)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_item_reservation (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    item_id             BIGINT NOT NULL,
    res_id              BIGINT NOT NULL,

    product_id          BIGINT NOT NULL DEFAULT 0,
    qty                 INT NOT NULL DEFAULT 0,
    duration_qty        INT NOT NULL DEFAULT 0,
    note                TEXT NOT NULL DEFAULT '',
    start_ts            TIMESTAMPTZ,
    end_ts              TIMESTAMPTZ,
    state               VARCHAR(32) NOT NULL DEFAULT 'pending',
    is_no_show          BOOLEAN NOT NULL DEFAULT FALSE,
    is_unavailable      BOOLEAN NOT NULL DEFAULT FALSE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, item_id, res_id),
    FOREIGN KEY (site_iid, tx_id, item_id)
        REFERENCES site.tx_item (site_iid, tx_id, item_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------------------------
-- Tx item source (stock allocation / BOM)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_item_source (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    item_id             BIGINT NOT NULL,
    src_id              BIGINT NOT NULL,

    obj_id              BIGINT NOT NULL DEFAULT 0,
    product_id          BIGINT NOT NULL DEFAULT 0,
    qty                 INT NOT NULL DEFAULT 0,
    note                TEXT NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, item_id, src_id),
    FOREIGN KEY (site_iid, tx_id, item_id)
        REFERENCES site.tx_item (site_iid, tx_id, item_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------------------------
-- Tx payment
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_payment (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    payment_id          BIGINT NOT NULL,

    method              VARCHAR(32) NOT NULL DEFAULT 'cash',
    ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    amount              BIGINT NOT NULL DEFAULT 0,
    note                TEXT NOT NULL DEFAULT '',
    from_wallet         TEXT NOT NULL DEFAULT '',
    to_wallet           TEXT NOT NULL DEFAULT '',
    debt_interest       BIGINT NOT NULL DEFAULT 0,
    payment_json        JSONB NOT NULL DEFAULT '{}',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, payment_id),
    FOREIGN KEY (site_iid, tx_id) REFERENCES site.tx (site_iid, tx_id) ON DELETE CASCADE,

    CONSTRAINT chk_tx_payment_method CHECK (method IN (
        'cash', 'card', 'transfer', 'qris', 'debt', 'wallet'
    ))
);

-- ------------------------------------------------------------------------------
-- Tx installment + debt payment
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_installment (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    payment_id          BIGINT NOT NULL,
    inst_id             BIGINT NOT NULL,

    due_ts              TIMESTAMPTZ,
    amount              BIGINT NOT NULL DEFAULT 0,
    note                TEXT NOT NULL DEFAULT '',
    is_paid             BOOLEAN NOT NULL DEFAULT FALSE,
    is_overdue          BOOLEAN NOT NULL DEFAULT FALSE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, payment_id, inst_id),
    FOREIGN KEY (site_iid, tx_id, payment_id)
        REFERENCES site.tx_payment (site_iid, tx_id, payment_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS site.tx_debt_payment (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    payment_id          BIGINT NOT NULL,
    inst_id             BIGINT NOT NULL,
    pay_id              BIGINT NOT NULL,

    ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    method              VARCHAR(32) NOT NULL DEFAULT 'cash',
    amount              BIGINT NOT NULL DEFAULT 0,
    note                TEXT NOT NULL DEFAULT '',
    overdue_interest    BIGINT NOT NULL DEFAULT 0,
    payment_json        JSONB NOT NULL DEFAULT '{}',
    is_paid             BOOLEAN NOT NULL DEFAULT FALSE,
    is_overdue          BOOLEAN NOT NULL DEFAULT FALSE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, payment_id, inst_id, pay_id),
    FOREIGN KEY (site_iid, tx_id, payment_id, inst_id)
        REFERENCES site.tx_installment (site_iid, tx_id, payment_id, inst_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------------------------
-- Tx accounting lines (GL)
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_acc (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    acc_id              BIGINT NOT NULL,

    acc_code            VARCHAR(32) NOT NULL DEFAULT '',
    ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    side                VARCHAR(8) NOT NULL,                     -- debit | credit
    amount              BIGINT NOT NULL DEFAULT 0 CHECK (amount >= 0),
    note                TEXT NOT NULL DEFAULT '',
    is_tx_generated     BOOLEAN NOT NULL DEFAULT FALSE,

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, acc_id),
    FOREIGN KEY (site_iid, tx_id) REFERENCES site.tx (site_iid, tx_id) ON DELETE CASCADE,
    CONSTRAINT chk_tx_acc_side CHECK (side IN ('debit', 'credit'))
);

-- ------------------------------------------------------------------------------
-- Tx stock movement
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_stock (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    stock_id            BIGINT NOT NULL,

    product_id          BIGINT NOT NULL DEFAULT 0,
    ts                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    obj_from_id         BIGINT NOT NULL DEFAULT 0,
    obj_to_id           BIGINT NOT NULL DEFAULT 0,
    qty                 INT NOT NULL DEFAULT 0,
    qty_signed          INT NOT NULL DEFAULT 0,
    direction           VARCHAR(32) NOT NULL DEFAULT '',
    note                TEXT NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, stock_id),
    FOREIGN KEY (site_iid, tx_id) REFERENCES site.tx (site_iid, tx_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------------------------
-- Tx tax / discount lines
-- ------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS site.tx_tax (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    tax_id              BIGINT NOT NULL,

    tax_type            VARCHAR(32) NOT NULL DEFAULT '',
    amount              BIGINT NOT NULL DEFAULT 0,
    note                TEXT NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, tax_id),
    FOREIGN KEY (site_iid, tx_id) REFERENCES site.tx (site_iid, tx_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS site.tx_discount (
    site_iid            BIGINT NOT NULL,
    tx_id               BIGINT NOT NULL,
    discount_id         BIGINT NOT NULL,

    discount_type       VARCHAR(32) NOT NULL DEFAULT '',
    amount              BIGINT NOT NULL DEFAULT 0,
    note                TEXT NOT NULL DEFAULT '',

    created_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_ts          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_ts          TIMESTAMPTZ,

    PRIMARY KEY (site_iid, tx_id, discount_id),
    FOREIGN KEY (site_iid, tx_id) REFERENCES site.tx (site_iid, tx_id) ON DELETE CASCADE
);
