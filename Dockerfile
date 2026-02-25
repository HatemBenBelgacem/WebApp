# Stage 1: Build
FROM rust:1-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN cargo install dioxus-cli --version 0.6.0

WORKDIR /usr/src/app
# Kopiere alle Dateien in das Arbeitsverzeichnis
COPY . .

# Build für Fullstack (erzeugt Binary und WASM-Assets im /dist Ordner)
RUN dx build --release --platform fullstack

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiere das Binary (Name muss mit 'name' in Cargo.toml übereinstimmen)
COPY --from=builder /usr/src/app/target/release/web-app /app/server

# Kopiere die Web-Assets
COPY --from=builder /usr/src/app/dist /app/dist

ENV PORT=8080
EXPOSE 8080

CMD ["/app/server"]