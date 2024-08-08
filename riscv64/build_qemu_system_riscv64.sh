#!/usr/bin/env bash
set -ex

apt-get update

QEMU_TAG=v9.0.2
OUTPUT=/output
mkdir $OUTPUT

DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    git python3 python3-pip ninja-build build-essential pkg-config curl bc jq \
    libslirp-dev libfdt-dev libglib2.0-dev libssl-dev libpixman-1-dev \
    flex bison

git clone --depth 1 --branch $QEMU_TAG https://gitlab.com/qemu-project/qemu.git
pushd qemu
./configure --target-list=riscv64-softmmu --prefix=$OUTPUT && \
	make -j$(nproc) && make install
popd
