#!/usr/bin/env bash
set -ex

apt-get update

# DEBIAN_FRONTEND is set for tzdata.
DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    curl gcc git python3 python3-pip shellcheck \
    libssl-dev tzdata cmake g++ pkg-config jq libcurl4-openssl-dev libelf-dev \
    libdw-dev binutils-dev libiberty-dev make \
    cpio bc flex bison wget xz-utils fakeroot \
    autoconf autoconf-archive automake libtool \
    iproute2

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

pip3 install --no-cache-dir pytest pexpect boto3 pytest-timeout && apt purge -y python3-pip

# Install rustup and a fixed version of Rust.
curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain "$RUST_TOOLCHAIN"

# Install cargo tools.
cargo install cargo-kcov critcmp cargo-audit cargo-fuzz && rm -rf /root/.cargo/registry/

# Install nightly (needed for fuzzing)
rustup install --profile=minimal nightly

# Install other rust targets.
rustup target add $(uname -m)-unknown-linux-musl

# Install kcov.
cargo kcov --print-install-kcov-sh | sh

# Install libgpiod (required by vhost-device crate)
pushd /opt
git clone --depth 1 --branch v2.0 https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/
pushd libgpiod
./autogen.sh --prefix=/usr && make && make install
popd
rm -rf libgpiod
popd
