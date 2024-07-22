#!/usr/bin/env bash
set -ex

# This script is a temporory solution for enabling RISC-V CIs, and is expected
# to be remove when an Ubuntu LTS image is available on `riscv64` platform.

ARCH=$(uname -m)

apt-get update

# DEBIAN_FRONTEND is set for tzdata.
DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    curl gcc musl-tools git python3 python3-pip shellcheck \
    libssl-dev tzdata cmake g++ pkg-config jq libcurl4-openssl-dev libelf-dev \
    libdw-dev binutils-dev libiberty-dev make \
    cpio bc flex bison wget xz-utils fakeroot \
    autoconf autoconf-archive automake libtool \
    libclang-dev iproute2 \
    libasound2t64 libasound2-dev \
    libepoxy0 libepoxy-dev \
    debhelper-compat libdbus-1-dev libglib2.0-dev meson ninja-build dbus

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

# Turn off externally managed check
mv /usr/lib/python3.12/EXTERNALLY-MANAGED /usr/lib/python3.12/EXTERNALLY-MANAGED.bak
pip3 install --no-cache-dir pytest pexpect boto3 pytest-timeout && apt purge -y python3-pip

# Install rustup and a fixed version of Rust.
curl https://sh.rustup.rs -sSf | sh -s -- \
  -y --default-toolchain "$RUST_TOOLCHAIN" \
  --profile minimal --component clippy,rustfmt

# Install cargo tools.
# Use `git` executable to avoid OOM on arm64:
# https://github.com/rust-lang/cargo/issues/10583#issuecomment-1129997984
cargo --config "net.git-fetch-with-cli = true" \
    install critcmp cargo-audit cargo-fuzz
rm -rf /root/.cargo/registry/

# Install nightly (needed for fuzzing)
rustup install --profile=minimal nightly
rustup component add miri rust-src --toolchain nightly
rustup component add llvm-tools-preview  # needed for coverage

cargo install cargo-llvm-cov

# dbus-daemon expects this folder
mkdir /run/dbus
