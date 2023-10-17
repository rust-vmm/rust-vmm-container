#!/usr/bin/env bash
set -ex

# Install rustup and a fixed version of Rust.
curl https://sh.rustup.rs -sSf | sh -s -- \
  -y --default-toolchain "$RUST_TOOLCHAIN" \
  --profile minimal --component clippy,rustfmt

# Install nightly (needed for fuzzing)
rustup install --profile=minimal nightly
rustup component add miri rust-src --toolchain nightly
rustup component add llvm-tools-preview  # needed for coverage

# Install other rust targets.
rustup target add $(uname -m)-unknown-linux-musl
