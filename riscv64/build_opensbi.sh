#!/usr/bin/env bash
set -ex

apt-get update

OPENSBI_TAG=v1.3.1
OUTPUT=/output
mkdir $OUTPUT

DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    git python3 python3-pip ninja-build build-essential pkg-config curl bc jq \
    libslirp-dev libfdt-dev libglib2.0-dev libssl-dev libpixman-1-dev \
    flex bison gcc-riscv64-linux-gnu

git clone --depth 1 --branch $OPENSBI_TAG https://github.com/riscv-software-src/opensbi.git
pushd opensbi
make -j$(nproc) PLATFORM=generic CROSS_COMPILE=riscv64-linux-gnu-
mv build/platform/generic/firmware/fw_jump.elf $OUTPUT
popd
