FROM ubuntu:22.04
ARG RUST_TOOLCHAIN
ARG GIT_COMMIT
ARG GIT_BRANCH

# Adding rust binaries to PATH.
ENV PATH="$PATH:/root/.cargo/bin"

# Install all required packages in one go to optimize the image
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#run
# DEBIAN_FRONTEND is set for tzdata.
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    curl gcc git python3 python3-pip shellcheck \
    # kcov dependencies
    libssl-dev tzdata cmake g++ pkg-config jq libcurl4-openssl-dev libelf-dev \
    libdw-dev binutils-dev libiberty-dev make \
    # utilities to build kernels
    cpio bc flex bison wget xz-utils fakeroot \
    # utilities to build usersapce packages
    autoconf autoconf-archive automake libtool \
    # bindgen dependency
    libclang-dev \
    # debootstrap to build rootfs images
    debootstrap \
    # iproute2 for creating tap device
    iproute2 \
    # cleanup
    && rm -rf /var/lib/apt/lists/*

# Install pytest and boto3.
RUN pip3 install pytest pexpect boto3 pytest-timeout

# Install rustup and a fixed version of Rust.
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain "$RUST_TOOLCHAIN"

# Install nightly (needed for fuzzing)
RUN rustup install nightly

# Install libfuzzer
RUN cargo install cargo-fuzz

# Install other rust targets.
RUN rustup target add $(uname -m)-unknown-linux-musl

# Install cargo tools.
RUN cargo install cargo-kcov critcmp cargo-audit cargo-license

# Install kcov.
RUN cargo kcov --print-install-kcov-sh | sh

# Install libgpiod (required by vhost-device crate)
RUN cd /opt/ && \
    git clone --depth 1 --branch v2.0 https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/ && \
    cd libgpiod && ./autogen.sh --prefix=/usr && make && make install; \
    cd

RUN echo "{\"rev\":\"$GIT_COMMIT\",\"branch\":\"${GIT_BRANCH}\"}" > /buildinfo.json
