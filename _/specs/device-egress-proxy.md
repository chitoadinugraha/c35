# Device egress proxy (`proxy.alienai.id`)

HTTP **CONNECT** on **`proxy.alienai.id`** (port **8443** in `server_ai`, TLS at ingress). Authenticated with **short-lived lease** (`device.egress.lease` invoke): username = `lease_id`, password = one-time secret.

Traffic is relayed over the paired agent **`/v1/agent/ws`** session; the agent opens TCP to the CONNECT target. Default host allowlist: `api.ipify.org`, `ifconfig.me`, `httpbin.org`.

Env: `C35_EGRESS_PROXY_ENABLED=1`, `C35_EGRESS_PROXY_ADDR`, `C35_EGRESS_PROXY_PUBLIC_URL`.

Smoke: `.\_\scripts\dev\test_device_egress_proxy.ps1 -DeviceIid <id>` with `C35_SERVER_URL` and `C35_JWT`.

Captcha solver uses the same lease path in a follow-up plan.
