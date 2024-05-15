#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)

apt-get update

# DEBIAN_FRONTEND is set for tzdata.
DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    curl gcc musl-tools git python3 python3-pip shellcheck \
    libssl-dev tzdata cmake g++ pkg-config jq libcurl4-openssl-dev libelf-dev \
    libdw-dev binutils-dev libiberty-dev make \
    cpio bc flex bison wget xz-utils fakeroot \
    autoconf autoconf-archive automake libtool \
    libclang-dev iproute2 \
    libasound2 libasound2-dev \
    debhelper-compat libdbus-1-dev libglib2.0-dev meson ninja-build dbus \

# Needed for x86_64 to cross compile RISC-V code
if [ "$ARCH" = "x86_64" ]; then
DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    autotools-dev libmpc-dev libmpfr-dev libgmp-dev gawk build-essential \
    texinfo gperf patchutils zlib1g-dev libexpat-dev libslirp-dev \
    qemu-user-static
fi

# cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*

# help musl-gcc find linux headers
pushd /usr/include/$ARCH-linux-musl 
ln -s ../$ARCH-linux-gnu/asm asm 
ln -s ../linux linux 
ln -s ../asm-generic asm-generic
popd

pip3 install --no-cache-dir pytest pexpect boto3 pytest-timeout && apt purge -y python3-pip

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
rustup target add $ARCH-unknown-linux-musl $ARCH-unknown-none
# For riscv64 cross-compilation
rustup target add riscv64gc-unknown-linux-gnu

cargo install cargo-llvm-cov

# Install libgpiod and libpipewire (required by vhost-device crate)
pushd /opt
git clone --depth 1 --branch v2.0 https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/
pushd libgpiod
./autogen.sh --prefix=/usr && make && make install
popd
rm -rf libgpiod
wget https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/0.3.71/pipewire-0.3.71.tar.gz
tar xzvf pipewire-0.3.71.tar.gz
pushd pipewire-0.3.71
meson setup builddir --prefix="/usr" -Dbuildtype=release \
    -Dauto_features=disabled -Ddocs=disabled -Dtests=disabled \
    -Dexamples=disabled -Dinstalled_tests=disabled -Dsession-managers=[] && \
meson compile -C builddir && \
meson install -C builddir
popd
rm -rf pipewire-0.3.71
rm pipewire-0.3.71.tar.gz
popd

# Install RISC-V GNU Compiler Toolchain for riscv cross-compilation
if [ "$ARCH" = "x86_64" ]; then
pushd /opt
git clone https://github.com/riscv/riscv-gnu-toolchain
pushd riscv-gnu-toolchain
mkdir /opt/riscv
./configure --prefix=/opt/riscv
make linux
popd
rm -rf riscv-gnu-toolchain
popd
fi

# dbus-daemon expects this folder
mkdir /run/dbus
