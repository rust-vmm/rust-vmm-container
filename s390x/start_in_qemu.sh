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

qemu-system-s390x \
    -M s390-ccw-virtio \
    -cpu qemu \
    -nographic \
    -smp $CORES -m $MEM \
    -fsdev local,path=$ROOTFS_DIR,security_model=none,id=rootfs \
    -device virtio-9p-ccw,fsdev=rootfs,mount_tag=rootfs \
    -device virtio-net-ccw,netdev=usernet \
    -netdev user,id=usernet,hostfwd=tcp::2222-:22 \
    -kernel $ROOTFS_DIR/boot/vmlinuz \
    -initrd $ROOTFS_DIR/boot/initrd.img \
    -append "root=rootfs rw rootfstype=9p rootflags=trans=virtio,cache=mmap,msize=512000 console=ttyS0 nokaslr" 2>&1 &

# Copy WORKDIR to ROOTFS_DIR
cp -a $WORKDIR $ROOTFS_DIR/root

HOST=s390x-qemu

echo "Testing SSH connectivity to $HOST..."
while ! ssh -o ConnectTimeout=1 -q $HOST exit; do
  sleep 10s
  echo "$HOST is not ready..."
done

# Issue command
COMMAND=$@
echo "$HOST is ready, forwarding command: $COMMAND"
ssh $HOST "export PATH=\"\$PATH:/root/.cargo/bin\" && cd workdir && $COMMAND"
