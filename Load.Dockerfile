FROM rust:1.73-bullseye AS chef
RUN cargo install cargo-chef
FROM chef AS planner

RUN mkdir /rust
COPY Cargo.toml /rust
COPY das_api /rust/das_api
COPY digital_asset_types /rust/digital_asset_types
COPY metaplex-rpc-proxy /rust/metaplex-rpc-proxy
COPY migration /rust/migration
COPY nft_ingester /rust/nft_ingester
COPY tools /rust/tools

WORKDIR /rust/tools/load_generation
RUN cargo chef prepare --recipe-path /rust/tools/load_generation/recipe.json

FROM chef AS builder
RUN apt-get update -y && \
    apt-get install -y build-essential make git

RUN mkdir /rust
COPY Cargo.toml /rust
COPY das_api /rust/das_api
COPY digital_asset_types /rust/digital_asset_types
COPY metaplex-rpc-proxy /rust/metaplex-rpc-proxy
COPY migration /rust/migration
COPY nft_ingester /rust/nft_ingester
COPY tools /rust/tools

WORKDIR /rust/tools/load_generation
COPY --from=planner /rust/tools/load_generation/recipe.json recipe.json

# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json --target-dir /rust/target

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
