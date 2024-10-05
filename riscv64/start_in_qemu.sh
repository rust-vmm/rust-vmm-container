#!/usr/bin/env bash
set -ex

# Minimum resources needed
MIN_CORES=4
MIN_MEM=6
DIVISOR=5

# Try to use 1/${DIVISOR} of resources for qemu-system
TOTAL_CORES=$(nproc)
ONE_FIFTH_CORES=$(( TOTAL_CORES / DIVISOR ))
CORES=$(( ONE_FIFTH_CORES > MIN_CORES ? ONE_FIFTH_CORES : MIN_CORES ))

TOTAL_MEM=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo) / 1024 / 1024 ))
ONE_FIFTH_MEM=$(( TOTAL_MEM / DIVISOR ))
MEM=$(( ONE_FIFTH_MEM > MIN_MEM ? ONE_FIFTH_MEM : MIN_MEM ))G

$QEMU_DIR/bin/qemu-system-riscv64 \
    -M virt,aclint=on,aia=aplic-imsic -nographic \
    -smp $CORES -m $MEM \
    -bios $OPENSBI_DIR/fw_jump.elf \
    -kernel $KERNEL_DIR/Image \
    -device virtio-net-device,netdev=usernet -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
    -virtfs local,path=$ROOTFS_DIR,mount_tag=rootfs,security_model=none,id=rootfs \
    -append "root=rootfs rw rootfstype=9p rootflags=trans=virtio,cache=mmap,msize=512000 console=ttyS0 earlycon=sbi nokaslr rdinit=/sbin/init" 2>&1 &

# Copy WORKDIR to ROOTFS_DIR
cp -a $WORKDIR $ROOTFS_DIR/root

HOST=riscv-qemu

echo "Testing SSH connectivity to $HOST..."
while ! ssh -o ConnectTimeout=1 -q $HOST exit; do
  sleep 10s
  echo "$HOST is not ready..."
done

# Issue command
COMMAND=$@
echo "$HOST is ready, forwarding command: $COMMAND"
ssh $HOST "export PATH=\"\$PATH:/root/.cargo/bin\" && cd workdir && $COMMAND"
