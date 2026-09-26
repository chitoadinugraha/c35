# syntax=docker/dockerfile:1.7
# Build from c35 repo root:
#   docker build --platform linux/arm64 -f _/deployments/Dockerfile -t c35-server .

ARG RUST_CHEF_IMAGE=hsg.ocir.io/axr8wqrrukgm/c35-rust-chef:1.89-bookworm
FROM ${RUST_CHEF_IMAGE} AS rust-build
WORKDIR /app

COPY servers/Cargo.toml servers/Cargo.lock /app/servers/
COPY servers/crates /app/servers/crates
COPY servers/server_ai/Cargo.toml /app/servers/server_ai/Cargo.toml
COPY servers/fetcher/Cargo.toml /app/servers/fetcher/
COPY servers/node_stats/Cargo.toml /app/servers/node_stats/
COPY servers/channel_whatsapp_device/Cargo.toml /app/servers/channel_whatsapp_device/
COPY _/deployments/docker/workspace-stub.sh /usr/local/bin/workspace-stub.sh
COPY _/schemas /app/_/schemas

RUN sed -i 's/\r$//' /usr/local/bin/workspace-stub.sh \
    && chmod +x /usr/local/bin/workspace-stub.sh \
    && sh /usr/local/bin/workspace-stub.sh fetcher node_stats channel_whatsapp_device \
    && mkdir -p /app/servers/server_ai/src \
    && printf '%s\n' 'fn main() {}' > /app/servers/server_ai/src/main.rs

ENV CARGO_TARGET_DIR=/app/target
ENV CARGO_BUILD_JOBS=3
ENV RUSTFLAGS="-C debuginfo=0"
ENV CARGO_PROFILE_RELEASE_LTO=false
ENV CARGO_PROFILE_RELEASE_CODEGEN_UNITS=4
ENV CARGO_PROFILE_RELEASE_INCREMENTAL=false

WORKDIR /app/servers
RUN --mount=type=cache,target=/usr/local/cargo/registry,id=c35-server-cargo-registry,sharing=locked \
    --mount=type=cache,target=/usr/local/cargo/git,id=c35-server-cargo-git,sharing=locked \
    --mount=type=cache,target=/app/target,id=c35-server-rust-target-v11,sharing=locked \
    cargo build --release -p server_ai --manifest-path Cargo.toml

COPY servers/server_ai /app/servers/server_ai

RUN --mount=type=cache,target=/usr/local/cargo/registry,id=c35-server-cargo-registry,sharing=locked \
    --mount=type=cache,target=/usr/local/cargo/git,id=c35-server-cargo-git,sharing=locked \
    --mount=type=cache,target=/app/target,id=c35-server-rust-target-v11,sharing=locked \
    rm -f /app/target/release/server_ai \
    && find /app/target/release/deps -maxdepth 1 -name 'server_ai-*' -delete \
    && cargo build --release -p server_ai --manifest-path Cargo.toml \
    && cp /app/target/release/server_ai /app/server_ai \
    && test "$(wc -c < /app/server_ai)" -gt 10000000 \
    && sha256sum /app/server_ai > /app/server_ai.sha

FROM oven/bun:1.2-slim AS bun-build
WORKDIR /app/scripts/presentation
COPY scripts/presentation/package.json /app/scripts/presentation/
RUN --mount=type=cache,target=/root/.bun/install/cache,id=c35-server-bun-cache,sharing=locked \
    bun install
COPY scripts/presentation /app/scripts/presentation
RUN bun build --compile --minify render_pptx.ts --outfile /app/render_pptx

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV LISTEN=0.0.0.0:8080
ENV YB_DATABASE=c35
ENV CAS_DIR=/data/cas
ENV PPTX_RENDER_BIN=/app/render_pptx
ENV RUST_LOG=info,server_ai=debug

RUN mkdir -p /data/cas

COPY --from=rust-build /app/server_ai /app/server_ai
COPY --from=rust-build /app/server_ai.sha /app/server_ai.sha
COPY --from=bun-build /app/render_pptx /app/render_pptx
COPY clients/web /app/clients/web

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/livez || exit 1

ENTRYPOINT ["/app/server_ai"]
