# syntax=docker/dockerfile:1.7
FROM public.ecr.aws/docker/library/rust:1.88-bookworm AS build
WORKDIR /build

COPY Cargo.toml Cargo.lock ./
RUN mkdir src \
    && printf 'fn main() {}\n' > src/main.rs \
    && cargo build --release --locked \
    && rm -rf src target/release/deps/c35_proxy_cf_warp* target/release/c35_proxy_cf_warp*

COPY src ./src
ENV RUSTFLAGS="-C strip=symbols"
RUN mkdir -p /out \
    && cargo build --release --locked \
    && install -m 0755 target/release/c35_proxy_cf_warp /out/c35_proxy_cf_warp

FROM gcr.io/distroless/cc-debian12:nonroot
WORKDIR /app
COPY --from=build /out/c35_proxy_cf_warp /app/c35_proxy_cf_warp
ENV C35_PROXY_CF_ADDR=0.0.0.0:8080
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app/c35_proxy_cf_warp"]
