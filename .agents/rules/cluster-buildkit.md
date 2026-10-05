# Cluster Buildkit (arm64) — no local Docker

Mirrored for Antigravity from [`.cursor/rules/cluster-buildkit.mdc`](../../.cursor/rules/cluster-buildkit.mdc).

Same hard rule: **never** local `docker build` / `-LocalBuild` for cluster arm64 images; use publish scripts + cluster Buildkit only.

GCP static egress (`linux/amd64` only) may use `publish_gcp_static_egress.ps1`. Never compile on `c-personal`. After any publish, end with a Publish summary from `.cache/publish-perf/latest.json`. Remote-agent changes that ship: `publish_remote_agent.ps1`.
