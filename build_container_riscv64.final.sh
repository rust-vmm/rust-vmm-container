#!/usr/bin/env bash
set -ex

#--------------------
# Version tag
#--------------------
RUST_TOOLCHAIN="1.72.0"
export PATH="$PATH:/root/.cargo/bin"

#--------------------
# Prerequisites
#--------------------
apt-get update
apt-get -y install curl libglib2.0-dev libfdt-dev libpixman-1-dev libslirp-dev gcc gcc-riscv64-linux-gnu

curl https://sh.rustup.rs -sSf | sh -s -- \
	    -y --default-toolchain "$RUST_TOOLCHAIN" \
	    --profile minimal --component clippy,rustfmt
rustup target add riscv64gc-unknown-linux-gnu
