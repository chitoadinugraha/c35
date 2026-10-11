# Captcha solver (cluster)

White-label captcha solving for **automated** browser/task flows. Provider is cluster-only (`C35_2CAPTCHA_API_KEY`); users see `captcha.solve`, not vendor branding.

## Flow

1. Active `prompt_run` or in-flight `task_run` / browser task for the same `req_id`.
2. `captcha.solve` mints `device.egress.lease` with page host + `2captcha.com` / `api.2captcha.com`.
3. Cluster submits to 2Captcha `in.php` / `res.php` with `proxy=` credentials from the lease (IP-aligned with the paired device).
4. Tool returns `token` (+ `wholesale_usd` for billing). Optional follow-up: `browser.captcha.apply` on Playwright (separate tool).

## Tool: `captcha.solve`

| Param | Notes |
|-------|--------|
| `device_iid` | Paired device for egress |
| `kind` | `recaptcha_v2`, `recaptcha_v3`, `hcaptcha`, `image` |
| `sitekey`, `page_url` | Widget captchas |
| `image_b64` | Image kind |
| `action`, `min_score` | reCAPTCHA v3 |

## Egress allowlist

`captcha_egress_hosts(page_url)` in `mod_device` sets lease `allow_hosts_json` (non-empty; not default ipify-only list).

Default bundle: `2captcha.com`, `api.2captcha.com`, plus host from `page_url`.

## Billing

Wholesale per kind in `c35_mod_captcha::billing` (2Captcha list prices, dated in source). Retail: `billing_to_retail_usd` (**× 1.50**). Successful solves return `wholesale_usd` on the tool result; fallback line item `captcha.solve` uses v2 wholesale in `billing_tool_cost_usd`.

## Env

| Key | Purpose |
|-----|---------|
| `C35_2CAPTCHA_API_KEY` | API key (required) |
| `C35_2CAPTCHA_IN_URL` / `C35_2CAPTCHA_RES_URL` | Optional overrides (tests) |
| `C35_EGRESS_PROXY_PUBLIC_URL` | Lease `proxy_url` (default `https://proxy.alienai.id:443`) |

## Errors

`not_configured`, `forbidden_context`, `egress_lease_failed`, `egress_proxy_failed`, `invalid_args`, `submit_failed`, `poll_failed`, `timeout`, `provider_error`.

## Phases (out of scope here)

Per-tenant keys, desktop `computer_use`, extension + AI OCR fallback — see multitask plan.
