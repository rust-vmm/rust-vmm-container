FROM ubuntu:24.04

ARG RUST_TOOLCHAIN
ENV RUST_TOOLCHAIN=${RUST_TOOLCHAIN}
# Adding rust binaries to PATH.
ENV PATH="$PATH:/root/.cargo/bin"

COPY build_container.sh /opt/src/scripts/build_container.sh
RUN /opt/src/scripts/build_container.sh
