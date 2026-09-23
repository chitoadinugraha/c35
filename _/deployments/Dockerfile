# syntax=docker/dockerfile:1.7
# Build from c35 repo root:
#   docker build --platform linux/arm64 -f _/deployments/Dockerfile -t c35-server .

FROM rust:1.88-bookworm AS rust-build

WORKDIR /app

COPY servers/Cargo.toml servers/Cargo.lock /app/servers/
COPY servers/crates /app/servers/crates
COPY servers/fetcher /app/servers/fetcher
COPY servers/server_ai /app/servers/server_ai
COPY servers/channel_whatsapp_device /app/servers/channel_whatsapp_device
COPY _/schemas /app/_/schemas

ENV CARGO_TARGET_DIR=/app/target
ENV CARGO_BUILD_JOBS=1
ENV RUSTFLAGS="-C debuginfo=0"
ENV CARGO_PROFILE_RELEASE_LTO=false
ENV CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16

RUN --mount=type=cache,target=/usr/local/cargo/registry,id=c35-server-cargo-registry,sharing=locked \
    --mount=type=cache,target=/usr/local/cargo/git,id=c35-server-cargo-git,sharing=locked \
    --mount=type=cache,target=/app/target,id=c35-server-rust-target,sharing=locked \
    cargo build --release -p server_ai --manifest-path servers/Cargo.toml \
    && cp /app/target/release/server_ai /app/server_ai \
    && sha256sum /app/server_ai > /app/server_ai.sha

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV LISTEN=0.0.0.0:8080
ENV YB_DATABASE=c35
ENV CAS_DIR=/data/cas
ENV RUST_LOG=info,server_ai=debug

RUN mkdir -p /data/cas

COPY --from=rust-build /app/server_ai /app/server_ai
COPY --from=rust-build /app/server_ai.sha /app/server_ai.sha

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/livez || exit 1

ENTRYPOINT ["/app/server_ai"]
