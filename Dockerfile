FROM ubuntu:18.04
ARG RUST_TOOLCHAIN="1.46"

# Adding rust binaries to PATH.
ENV PATH="$PATH:/root/.cargo/bin"

RUN apt-get update

RUN apt-get -y install gcc

# Installing rustup.
RUN apt-get -y install curl
# Install a fixed version of rust.
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain "$RUST_TOOLCHAIN"
# Install the nightly so that we can run cargo fmt on code examples.
RUN rustup toolchain install nightly

# Installing rust tools used by the rust-vmm CI.
RUN if [ $(uname -m) = "x86_64" ]; then rustup component add rustfmt; fi
RUN if [ $(uname -m) = "x86_64" ]; then rustup component add clippy; fi
RUN cargo install cargo-kcov

# Installing other rust targets.
RUN rustup target add $(uname -m)-unknown-linux-musl

# Installing kcov dependencies.
RUN apt-get -y install libssl-dev
RUN apt-get -y install cmake g++ pkg-config jq
RUN apt-get -y install libcurl4-openssl-dev libelf-dev libdw-dev binutils-dev libiberty-dev

# Installing kcov.
# For some strange reason, the command requires python3 to be installed.
RUN apt-get -y install python3
RUN cargo kcov --print-install-kcov-sh | sh

# Installing python3.6 & pytest.
RUN apt-get -y install python3.6
RUN apt-get -y install python3-pip
RUN pip3 install pytest pexpect
RUN pip3 install boto3
RUN pip3 install pytest-timeout

# Install git.
RUN apt-get -y install git
# Install critcmp.
RUN cargo install critcmp

# Install cargo audit and cargo license.
# cargo audit needs openssl.
RUN apt-get -y install libssl-dev
RUN cargo install cargo-audit
RUN cargo install cargo-license

# Install utilities to build kernels.
RUN apt-get -y install cpio bc flex bison wget

# Install debootstrap to build rootfs images.
RUN apt-get -y install debootstrap

# Install shell check
RUN apt-get -y --no-install-recommends install shellcheck
