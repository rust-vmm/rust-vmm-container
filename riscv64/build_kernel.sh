#!/usr/bin/env bash
set -ex

apt-get update

KERNEL_TAG=v6.10
OUTPUT=/output
mkdir $OUTPUT

DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    git python3 python3-pip ninja-build build-essential pkg-config curl bc jq \
    libslirp-dev libfdt-dev libglib2.0-dev libssl-dev libpixman-1-dev \
    flex bison gcc-riscv64-linux-gnu

git clone --depth 1 --branch $KERNEL_TAG https://github.com/torvalds/linux.git
pushd linux
# Enable kvm module instead of inserting manually
sed -i "s|^CONFIG_KVM=.*|CONFIG_KVM=y|g" arch/riscv/configs/defconfig
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- defconfig && \
make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- -j$(nproc)
mv arch/riscv/boot/Image $OUTPUT
popd
