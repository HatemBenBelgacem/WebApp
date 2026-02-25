# Stage 1: Build Phase
FROM rust:1-slim-bookworm AS builder

# 1. System-Abhängigkeiten
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. WASM-Target hinzufügen
RUN rustup target add wasm32-unknown-unknown

# 3. cargo-binstall für schnelle Installationen nutzen
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

# 4. Dioxus CLI installieren
RUN cargo binstall -y dioxus-cli --version 0.6.0

# 5. WICHTIG: wasm-bindgen-cli exakt in Version 0.2.113 installieren
# Dies überschreibt die interne Version des CLI und löst den Fehler
RUN cargo binstall -y wasm-bindgen-cli --version 0.2.113

WORKDIR /usr/src/app
COPY . .

# 6. Sicherstellen, dass die Lock-Datei die richtige Version nutzt
RUN cargo update -p wasm-bindgen --precise 0.2.113

# 7. Build-Befehle (getrennt für maximale Kontrolle)
RUN dx build --release --platform web
RUN dx build --release --platform server

# Stage 2: Runtime Phase
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiere das Server-Binary (Name web-app aus deiner Cargo.toml)
COPY --from=builder /usr/src/app/target/release/web-app /app/server

# Kopiere die Web-Assets (WASM, JS, CSS)
COPY --from=builder /usr/src/app/dist /app/dist

# Railway nutzt dynamische Ports
ENV PORT=8080
EXPOSE 8080

# Starte den kombinierten Fullstack-Server
CMD ["/app/server"]