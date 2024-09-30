#!/usr/bin/env bash
set -ex

apt-get update

DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    openssh-client libslirp-dev libfdt-dev libglib2.0-dev libssl-dev \
    libpixman-1-dev netcat

# Modify fstab to mount `tmpfs` during boot
# See: https://wiki.qemu.org/Documentation/9p_root_fs#Let's_start_the_Installation
echo 'tmpfs /tmp tmpfs rw,nosuid,nodev,size=524288k,nr_inodes=204800 0 0' >> $ROOTFS_DIR/etc/fstab

# Setup container ssh config
yes "" | ssh-keygen -P ""
cat /root/.ssh/id_rsa.pub > $ROOTFS_DIR/root/.ssh/authorized_keys
cat > /root/.ssh/config << EOF
Host riscv-qemu
    HostName localhost
    User root
    Port 2222
    StrictHostKeyChecking no
EOF

# Set `nameserver` to `10.0.2.3` as QEMU User Networking documented.
# See: https://wiki.qemu.org/Documentation/Networking
echo 'nameserver 10.0.2.3' > $ROOTFS_DIR/etc/resolv.conf
