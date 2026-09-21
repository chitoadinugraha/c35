# syntax=docker/dockerfile:1.7
# Build from repo root:
#   docker build --platform linux/arm64 -f channels/cs_channel_whatsapp/Dockerfile -t cs-channel-whatsapp .

FROM rust:1.89-bookworm AS rust-build

WORKDIR /app

COPY channels/cs_channel_whatsapp/Cargo.toml channels/cs_channel_whatsapp/Cargo.lock* ./channels/cs_channel_whatsapp/
COPY channels/cs_channel_whatsapp/src ./channels/cs_channel_whatsapp/src

WORKDIR /app/channels/cs_channel_whatsapp

RUN --mount=type=cache,target=/usr/local/cargo/registry,id=cs-wa-cargo-registry,sharing=locked \
    --mount=type=cache,target=/usr/local/cargo/git,id=cs-wa-cargo-git,sharing=locked \
    --mount=type=cache,target=/app/channels/cs_channel_whatsapp/target,id=cs-wa-rust-target,sharing=locked \
    cargo build --release \
    && cp /app/channels/cs_channel_whatsapp/target/release/cs_channel_whatsapp /app/cs_channel_whatsapp

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV PORT=8080
ENV WA_SESSIONS_DIR=/app/sessions
ENV NATS_CA=/app/certs/nats-ca.crt
ENV RUST_LOG=info,cs_channel_whatsapp=debug,whatsapp_rust=debug

COPY --from=rust-build /app/cs_channel_whatsapp /app/cs_channel_whatsapp
COPY _/certs/nats-ca.crt /app/certs/nats-ca.crt

RUN mkdir -p /app/sessions

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/healthz || exit 1

CMD ["/app/cs_channel_whatsapp"]
