FROM rust:1.73-bullseye AS chef
RUN cargo install cargo-chef
FROM chef AS planner
#COPY tools/load_generation /rust/tools/load_generation/
COPY Cargo.toml /rust/Cargo.toml
COPY digital_asset_types /rust/digital_asset_types
COPY das_api /rust/das_api/
COPY metaplex-rpc-proxy /rust/metaplex-rpc-proxy
COPY migration /rust/migration
COPY nft_ingester /rust/nft_ingester/
COPY tools /rust/tools
WORKDIR /rust/tools/load_generation
RUN cargo chef prepare --recipe-path recipe.json
FROM chef AS builder
RUN apt-get update -y && \
    apt-get install -y build-essential make git
COPY tools/load_generation /rust/tools/load_generation
RUN mkdir -p /rust/tools/load_generation
WORKDIR /rust/tools/load_generation
COPY --from=planner /rust/tools/load_generation/recipe.json recipe.json
COPY --from=planner /rust/Cargo.toml /rust/Cargo.toml
COPY --from=planner /rust/das_api /rust/das_api
COPY --from=planner /rust/digital_asset_types /rust/digital_asset_types
COPY --from=planner /rust/metaplex-rpc-proxy /rust/metaplex-rpc-proxy
COPY --from=planner /rust/migration /rust/migration
COPY --from=planner /rust/nft_ingester /rust/nft_ingester
COPY --from=planner /rust/tools /rust/tools
# Build dependencies - this is the caching Docker layer!
COPY tools/load_generation/Cargo.toml .
# RUN cargo chef cook --release --recipe-path recipe.json
COPY tools/load_generation .
# Build application
RUN cargo build --release
FROM rust:1.73-slim-bullseye
ARG APP=/usr/src/app
RUN apt update \
    && apt install -y curl ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*
ENV TZ=Etc/UTC \
    APP_USER=appuser
RUN groupadd $APP_USER \
    && useradd -g $APP_USER $APP_USER \
    && mkdir -p ${APP}
COPY --from=builder /rust/target/release/load_generation ${APP}
RUN chown -R $APP_USER:$APP_USER ${APP}
USER $APP_USER
WORKDIR ${APP}
CMD /usr/src/app/load_generation
