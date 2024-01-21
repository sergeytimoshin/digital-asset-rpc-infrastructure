FROM rust:1.73-bullseye
COPY init.sql /init.sql
COPY Cargo.toml /Cargo.toml
COPY migration /migration
ENV INIT_FILE_PATH=/init.sql
COPY digital_asset_types /digital_asset_types
COPY das_api /das_api
COPY metaplex-rpc-proxy /metaplex-rpc-proxy
COPY nft_ingester /nft_ingester
COPY tools/acc_forwarder tools/acc_forwarder
COPY tools/txn_forwarder tools/txn_forwarder
COPY tools/bgtask_creator tools/bgtask_creator
COPY tools/fetch_trees tools/fetch_trees
COPY tools/load_generation tools/load_generation
COPY tools/tree-status tools/tree-status
WORKDIR /migration
RUN cargo build --release
WORKDIR /target/release
CMD /target/release/migration up -n 100
