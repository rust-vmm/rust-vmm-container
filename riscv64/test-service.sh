#!/usr/bin/env bash
set -e

## This script is executed by QEMU RISC-V guest during systemd boot (see test.service)
## This script does the following things:
## 1) mount the repo to be tested at $REPO_MOUNT_POINT
## 2) find pre-cross-compiled test binaries under $REPO_MOUNT_POINT/target/riscv64gc-unknown-linux-gnu/debug/deps/*
## 3) Run each of those found test binaries

## QEMU virtfs mount_tag
REPO_MOUNT_TAG=test
## Where to mount the repo to be tested, the repo shall be pre-cross-compiled in host machine
REPO_MOUNT_POINT=/workdir

## $1: The exit code (in decimal) that you want QEMU to exit with
exit_qemu_with_code() {
	local exit_code=$1
	local exit_code_in_hex=$(printf "0x%x" $exit_code)
	local encoded_exit_code=$(printf "0x%x" $(( ($exit_code_in_hex << 16) + 0x3333)))
	echo "Exiting QEMU with exit code $exit_code..."
	## Trigger QEMU exit by writing to SiFive Test MMIO device at 0x100000
	busybox devmem 0x100000 w $encoded_exit_code
}

trap 'exit_qemu_with_code $?' 0

echo "Mounting repo to be tested..."
mkdir -p $REPO_MOUNT_POINT
mount -t 9p -o rw,trans=virtio,version=9p2000.L,posixacl,cache=mmap,msize=512000 $REPO_MOUNT_TAG $REPO_MOUNT_POINT
mount | grep 9p

echo "Searching for cross-compiled test binaries..."
IFS=$'\n'
test_bin=($(find $REPO_MOUNT_POINT/target/riscv64gc-unknown-linux-gnu/debug/deps/* -perm /+x))
unset IFS

echo "List of cross-compiled test binaries found..."
printf "%s\n" "${test_bin[@]}"

echo "Running the cross-compiled test binaries..."
for (( i = 0; i < ${#test_bin[@]} ; i++ )); do
	echo "*****************************************"
	echo "Running: $(basename ${test_bin[$i]})"
	echo "*****************************************"
	eval "${test_bin[$i]}"
done
