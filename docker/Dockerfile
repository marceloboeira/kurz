# TODO use args for common paths and version management
########################################
############ Rust Build  ###############
########################################
FROM ekidd/rust-musl-builder:nightly-2019-06-08 AS rust-build

# Re-own home
# https://github.com/emk/rust-musl-builder#making-static-releases-with-travis-ci-and-github
RUN sudo chown -R rust:rust /home

# Install and cache dependencies layers
# Rather than copying everything every time, re-use cached dependency layers
# to install/build deps only when Cargo.* files change.
RUN USER=root cargo new /home/kurz --bin

WORKDIR /home/kurz
COPY api/Cargo.lock ./Cargo.lock
COPY api/Cargo.toml ./Cargo.toml
RUN cargo build --bins --release --target x86_64-unknown-linux-musl

# Load real sources
RUN rm src/*.rs
COPY api/src ./src

# Rebuild with real sources
RUN rm ./target/x86_64-unknown-linux-musl/release/deps/kurz*
RUN cargo build --bins --release --target x86_64-unknown-linux-musl

########################################
############ Elm Build  ################
########################################
# TODO: use alpine + elm
FROM codesimple/elm:0.19 AS elm-build

WORKDIR /home/kurz
COPY ui/ .
RUN elm make src/Application.elm --output dist/assets/application.js --optimize

########################################
########## Release Image ###############
########################################
FROM alpine:3.9.4

WORKDIR /home

# Copy Rust artifacts
COPY --from=rust-build /home/kurz/target/x86_64-unknown-linux-musl/release/kurz .

# Copy Elm artifacts
COPY --from=elm-build /home/kurz/dist/ ui/

EXPOSE 8000
CMD ["./kurz"]
