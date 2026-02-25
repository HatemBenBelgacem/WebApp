# Stage 1: Build
FROM rust:1-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN rustup target add wasm32-unknown-unknown

# 1. Installiere binstall
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

# 2. Installiere Dioxus CLI
RUN cargo binstall -y dioxus-cli --version 0.6.0

# 3. WICHTIG: Installiere die passende wasm-bindgen-cli Version
# Dies behebt den "schema version mismatch" Fehler
RUN cargo binstall -y wasm-bindgen-cli --version 0.2.113

WORKDIR /usr/src/app
COPY . .

# Bevor wir bauen, stellen wir sicher, dass die Abhängigkeiten frisch sind
RUN cargo update

# Build für Fullstack
RUN dx build --release --platform web
RUN dx build --release --platform server

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiere das Binary und die Web-Assets
COPY --from=builder /usr/src/app/target/release/web-app /app/server
COPY --from=builder /usr/src/app/dist /app/dist

ENV PORT=8080
EXPOSE 8080

CMD ["/app/server"]