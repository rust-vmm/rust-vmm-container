#!/usr/bin/env bash
set -e

## This script is executed by the host inside Docker to run QEMU RISC-V guest
OUTPUT_DIR=/opt/bin
OPENSBI_FW_JUMP_ELF=$OUTPUT_DIR/fw_jump.elf
LINUX_IMAGE=$OUTPUT_DIR/Image
ROOTFS_DIR=/rootfs
## The repo to be tested (the repo passed in by Docker host, will be passed to QEMU guest at the same path)
REPO_MOUNT_POINT=/workdir

echo "Running QEMU..."
qemu-system-riscv64 \
	-M virt -nographic \
	-smp 6 -cpu rv64,h=true \
	-m 6G \
	-bios $OPENSBI_FW_JUMP_ELF \
	-kernel $LINUX_IMAGE \
	-device virtio-net-device,netdev=usernet -netdev user,id=usernet\
	-virtfs local,path=$ROOTFS_DIR,mount_tag=rootfs,security_model=none,id=rootfs \
	-append "root=rootfs rw rootfstype=9p rootflags=trans=virtio,cache=mmap,msize=512000 console=ttyS0 earlycon=sbi nokaslr rdinit=/sbin/init" \
	-virtfs local,path=$REPO_MOUNT_POINT,mount_tag=test,security_model=mapped,id=test
