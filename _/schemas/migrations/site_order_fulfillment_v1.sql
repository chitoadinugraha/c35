-- Opt-in kitchen / order processing capability for existing commerce sites.
-- New sites set order_fulfillment explicitly in the create wizard (default false).

UPDATE site.config
SET capabilities_json = capabilities_json || '{"order_fulfillment": true}'::jsonb,
    updated_ts = NOW()
WHERE deleted_ts IS NULL
  AND COALESCE((capabilities_json->>'commerce')::boolean, true) = true
  AND NOT (capabilities_json ? 'order_fulfillment');
