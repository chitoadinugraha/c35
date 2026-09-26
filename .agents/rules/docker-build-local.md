# Docker builds (GCP amd64 local; cluster arm64 via buildkit)

Mirrored from [`.cursor/rules/docker-build-local.mdc`](../../.cursor/rules/docker-build-local.mdc).

- Do not `docker build` on GCP `c-personal` — pull pre-built amd64 images only.
- Cluster arm64: buildkit (`cluster-buildkit.mdc`).
- GCP proxy: `.\_\scripts\deploy\publish_gcp_static_egress.ps1` → `linux/amd64` local buildx.
