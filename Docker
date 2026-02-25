# Stage 1: Build
FROM rust:1-slim-bookworm AS builder

# System-Abhängigkeiten für Compilation
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Dioxus CLI installieren (v0.6 passend zur Cargo.toml)
RUN cargo install dioxus-cli --version 0.6.0

WORKDIR /usr/src/app
COPY . .

# Build für Fullstack
# Erstellt das Binary (server) und den dist-Ordner (client/assets)
RUN dx build --release --platform fullstack

# Stage 2: Runtime
FROM debian:bookworm-slim

# SSL-Zertifikate für HTTPS/Datenbank-Verbindungen
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiere das Server-Binary (Name aus deiner Cargo.toml)
COPY --from=builder /usr/src/app/target/release/web-app /app/server

# Kopiere den dist-Ordner (enthält WASM und Assets)
COPY --from=builder /usr/src/app/dist /app/dist

# Railway nutzt dynamische Ports
ENV PORT=8080
EXPOSE 8080

# Starte den Server
CMD ["/app/server"]