# Cluster Buildkit (arm64) — no local Docker

Mirrored for Antigravity from [`.cursor/rules/cluster-buildkit.mdc`](../../.cursor/rules/cluster-buildkit.mdc).

Same hard rule: **never** local `docker build` / `-LocalBuild` for cluster arm64 images; use publish scripts + cluster Buildkit only.
