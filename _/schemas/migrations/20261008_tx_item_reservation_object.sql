ALTER TABLE site.tx_item_reservation ADD COLUMN IF NOT EXISTS site_object_id BIGINT NOT NULL DEFAULT 0;
