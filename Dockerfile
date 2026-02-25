# Stage 1: Build
FROM rust:1-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# WebAssembly Target für das Frontend hinzufügen
RUN rustup target add wasm32-unknown-unknown

# Dioxus CLI installieren
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
RUN cargo binstall -y dioxus-cli --version 0.6.0

WORKDIR /usr/src/app
COPY . .

# WICHTIG: Wir bauen erst das Web-Frontend und dann den Server, 
# um sicherzugehen, dass der 'dist' Ordner existiert.
RUN dx build --release --platform web
RUN dx build --release --platform server

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiere das Binary aus dem Release-Ordner
COPY --from=builder /usr/src/app/target/release/web-app /app/server

# Kopiere den nun existierenden dist-Ordner (Frontend-Assets)
COPY --from=builder /usr/src/app/dist /app/dist

# Railway Umgebung
ENV PORT=8080
EXPOSE 8080

# Starte den Server
CMD ["/app/server"]