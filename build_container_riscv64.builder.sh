#!/usr/bin/env bash
set -ex

export ARCH=riscv
export CROSS_COMPILE=riscv64-linux-gnu-

#--------------------
# Version tags
#--------------------
QEMU_TAG=v8.1.2
OPENSBI_TAG=v1.3.1
LINUX_TAG=v6.5

#--------------------
# Directory paths
#--------------------
## Directory path where git clones repos to
DIR_PREFIX=/opt/build
mkdir -p $DIR_PREFIX
## Build output path (to store output of make)
OUTPUT_DIR=/opt/bin
mkdir -p $OUTPUT_DIR
## Build install path (to store output of make install)
INSTALL_DIR=/opt/install

## Repo paths
QEMU_DIR=$DIR_PREFIX/qemu
OPENSBI_DIR=$DIR_PREFIX/opensbi
LINUX_DIR=$DIR_PREFIX/linux

#--------------------
# Prerequisites
#--------------------
PACKAGE_LIST="git python3 python3-pip build-essential pkg-config libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev ninja-build gcc-riscv64-linux-gnu libssl-dev wget curl bc flex bison libslirp-dev"
apt-get update
apt-get -y install $PACKAGE_LIST

cd $DIR_PREFIX
git clone --depth 1 --branch $QEMU_TAG https://gitlab.com/qemu-project/qemu.git
git clone --depth 1 --branch $OPENSBI_TAG https://github.com/riscv-software-src/opensbi.git
git clone --depth 1 --branch $LINUX_TAG https://github.com/torvalds/linux.git

#--------------------
# QEMU
#--------------------
cd $QEMU_DIR
./configure --target-list="riscv64-softmmu" --enable-slirp --prefix=$INSTALL_DIR/usr/local && \
	make -j$(nproc) && \
	make install

#--------------------
# OpenSBI
#--------------------
cd $OPENSBI_DIR
make -j$(nproc) PLATFORM=generic
mv $OPENSBI_DIR/build/platform/generic/firmware/fw_jump.elf $OUTPUT_DIR

#--------------------
# Linux
#--------------------
cd $LINUX_DIR
sed -i "s|^CONFIG_KVM=.*|CONFIG_KVM=y|g" $LINUX_DIR/arch/riscv/configs/defconfig
make defconfig && make -j$(nproc)
mv $LINUX_DIR/arch/riscv/boot/Image $OUTPUT_DIR

#--------------------
# Cleanup
#--------------------
rm -rf $QEMU_DIR
rm -rf $OPENSBI_DIR
rm -rf $LINUX_DIR
apt-get -y remove $PACKAGE_LIST
