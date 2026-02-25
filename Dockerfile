# Stage 1: Build
FROM rust:1-slim-bookworm AS builder

# 1. System-Abhängigkeiten installieren
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. WICHTIG: WebAssembly Target hinzufügen
# Ohne dies kann der 'dist' Ordner für das Frontend nicht erstellt werden.
RUN rustup target add wasm32-unknown-unknown

# 3. Dioxus CLI über binstall installieren (schneller & stabiler)
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
RUN cargo binstall -y dioxus-cli --version 0.6.0

WORKDIR /usr/src/app
COPY . .

# 4. Fullstack Build ausführen
# Erzeugt das Server-Binary in target/release/ und die Web-Assets in dist/
RUN dx build --release --platform server

# Stage 2: Runtime (Schlankes Image für Railway)
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 5. Kopiere das Binary (Name 'web-app' laut deiner Cargo.toml)
COPY --from=builder /usr/src/app/target/release/web-app /app/server

# 6. Kopiere den jetzt existierenden dist-Ordner
COPY --from=builder /usr/src/app/dist /app/dist

# Railway Port-Konfiguration
ENV PORT=8080
EXPOSE 8080

# Startet den Fullstack-Server
CMD ["/app/server"]