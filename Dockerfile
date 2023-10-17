# syntax=docker/dockerfile:1
FROM ubuntu:22.04 as system-deps
COPY install_system_dependencies.sh /opt/src/scripts/install_system_dependencies.sh
RUN /opt/src/scripts/install_system_dependencies.sh

FROM system-deps as rust
ARG RUST_TOOLCHAIN="1.72.0"
# Adding rust binaries to PATH.
ENV PATH="$PATH:/root/.cargo/bin"
COPY install_rust_toolchains.sh /opt/src/scripts/install_rust_toolchains.sh
RUN /opt/src/scripts/install_rust_toolchains.sh

FROM rust as cargo
COPY --from=rust /root/.rustup /root/.rustup
ENV PATH="$PATH:/root/.cargo/bin"
COPY install_cargo_tools.sh /opt/src/scripts/install_cargo_tools.sh
RUN /opt/src/scripts/install_cargo_tools.sh

FROM system-deps as libgpiod
COPY install_libgpiod.sh /opt/src/scripts/install_libgpiod.sh
RUN /opt/src/scripts/install_libgpiod.sh

# Build and install libpipewire.

FROM system-deps as pipewire-deps
COPY install_libpipewire_dependencies.sh /opt/src/scripts/install_libpipewire_dependencies.sh
RUN /opt/src/scripts/install_libpipewire_dependencies.sh

FROM pipewire-deps as libpipewire
COPY install_libpipewire.sh /opt/src/scripts/install_libpipewire.sh
RUN /opt/src/scripts/install_libpipewire.sh

# This is the final build stage, whatever files/environment it has are carried
# over to the image. All files etc. from previous stages that aren't explicitly
# copied over will be lost.
FROM ubuntu:22.04 as copy-final-artifacts
ENV PATH="$PATH:/root/.cargo/bin"
COPY --from=system-deps /usr /usr
COPY --from=system-deps /etc /etc
COPY --from=libgpiod /usr /usr
COPY --from=libpipewire /usr /usr
COPY --from=rust /root/.rustup /root/.rustup
COPY --from=cargo /root/.cargo /root/.cargo
