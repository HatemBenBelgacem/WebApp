# Stage 1: Build
FROM rust:1-slim-bookworm AS builder

RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Installiere Dioxus CLI über binstall (vermeidet Kompilierfehler)
RUN curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
RUN cargo binstall -y dioxus-cli --version 0.6.0

WORKDIR /usr/src/app
COPY . .

# KORREKTUR: Nutze --platform server statt fullstack
# Dieser Befehl baut das Backend-Binary UND die Web-Assets (WASM)
RUN dx build --release --platform server

# Stage 2: Runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Kopiere das Binary (Name web-app aus deiner Cargo.toml)
COPY --from=builder /usr/src/app/target/release/web-app /app/server

# Kopiere die Web-Assets (Dioxus legt diese in /dist ab)
COPY --from=builder /usr/src/app/dist /app/dist

ENV PORT=8080
EXPOSE 8080

CMD ["/app/server"]