#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)
RUST_TOOLCHAIN="1.85.0"

apt-get update

# DEBIAN_FRONTEND is set for tzdata.
DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    curl gcc musl-tools git python3 python3-pip shellcheck rsync \
    libssl-dev tzdata cmake g++ pkg-config jq libcurl4-openssl-dev libelf-dev \
    libdw-dev binutils-dev libiberty-dev make \
    cpio bc flex bison wget xz-utils fakeroot \
    cmake cmake-data \
    build-essential libjsoncpp25 librhash0 make \
    autoconf autoconf-archive automake libtool \
    libclang-dev iproute2 \
    libasound2t64 libasound2-dev \
    libepoxy0 libepoxy-dev \
    libdrm2 libdrm-dev \
    libgbm1 libgbm-dev libgles2 \
    libglm-dev libstb-dev libc6-dev \
    debhelper-compat libdbus-1-dev libglib2.0-dev meson ninja-build dbus \
    libvirglrenderer1 libvirglrenderer-dev pipewire libpipewire-0.3-dev \
    podman

# `riscv64` specific dependencies
if [ "$ARCH" == "riscv64" ]; then
    DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
        openssh-server systemd init ifupdown busybox udev isc-dhcp-client
fi

# apt dependencies not available on `riscv64`
if [ "$ARCH" != "riscv64" ]; then
    DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
        binutils-aarch64-linux-gnu
fi

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

# help musl-gcc find linux headers
# Skip on `riscv64` for now
if [ "$ARCH" != "riscv64" ]; then
    pushd /usr/include/$ARCH-linux-musl 
    ln -s ../$ARCH-linux-gnu/asm asm 
    ln -s ../linux linux 
    ln -s ../asm-generic asm-generic
    popd
fi

# Allow pip to install packages system wide
rm /usr/lib/python3.*/EXTERNALLY-MANAGED
pip3 install --no-cache-dir pytest pexpect boto3 pytest-timeout
apt purge -y python3-pip

# Install rustup and a fixed version of Rust.
curl https://sh.rustup.rs -sSf | sh -s -- \
  -y --default-toolchain "$RUST_TOOLCHAIN" \
  --profile minimal --component clippy,rustfmt

# Install cargo tools.
# Use `git` executable to avoid OOM on arm64:
# https://github.com/rust-lang/cargo/issues/10583#issuecomment-1129997984
cargo --config "net.git-fetch-with-cli = true" \
    install critcmp cargo-audit cargo-fuzz
rm -rf /root/.cargo/registry/

# Install nightly (needed for fuzzing)
rustup install --profile=minimal nightly
rustup component add miri rust-src --toolchain nightly
rustup component add llvm-tools-preview  # needed for coverage

# Install other rust targets.
# Skip on `riscv64` for now
if [ "$ARCH" != "riscv64" ]; then
    rustup target add $ARCH-unknown-linux-musl $ARCH-unknown-none
fi

cargo install cargo-llvm-cov

# Install some dependencies required by vhost-device crates but not available
# in Ubuntu repos.
# Some of these do not support riscv64, since vhost-device crates do not
# support riscv64 too, let's skip them for now.
if [ "$ARCH" != "riscv64" ]; then
    pushd /opt

    # required by vhost-device-gpu
    git clone --depth 1 --branch v0.1.2-aemu-release \
        https://android.googlesource.com/platform/hardware/google/aemu
    pushd aemu
    cmake -DAEMU_COMMON_GEN_PKGCONFIG=ON \
        -DAEMU_COMMON_BUILD_CONFIG=gfxstream \
        -DENABLE_VKCEREAL_TESTS=OFF -B build
    cmake --build build -j
    cmake --install build
    popd
    rm -rf aemu

    # required by vhost-device-gpu
    git clone --depth 1 --branch v0.1.2-gfxstream-release \
        https://android.googlesource.com/platform/hardware/google/gfxstream
    pushd gfxstream
    meson setup host-build/
    meson install -C host-build/
    popd
    rm -rf gfxstream

    # required by vhost-device-gpio
    git clone --depth 1 --branch v2.0 \
        https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/
    pushd libgpiod
    ./autogen.sh --prefix=/usr && make && make install
    popd
    rm -rf libgpiod

    # we can leave /opt at this point
    popd

    # configure dynamic linker run-time bindings after installing new libraries
    ldconfig
fi

# dbus-daemon expects this folder
mkdir -p /run/dbus

# `riscv64` specific, which setup the rootfs for `riscv64` VM to execute actual
# RISC-V tests through prepared ssh server.
if [ "$ARCH" == "riscv64" ]; then
    # Set passwd for debugging
    echo 'root:rustvmm' | chpasswd
    # Allow root login
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config
    # Enable ssh
    systemctl enable ssh
    mkdir -p /root/.ssh
    # Setup network
    echo $'auto lo\niface lo inet loopback\n\nauto eth0\niface eth0 inet dhcp\n' > /etc/network/interfaces
fi
