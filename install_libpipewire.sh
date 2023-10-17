#!/usr/bin/env bash
set -ex

# Install libpipewire (required by vhost-device crate)
pushd /opt
wget https://gitlab.freedesktop.org/pipewire/pipewire/-/archive/0.3.71/pipewire-0.3.71.tar.gz
tar xzvf pipewire-0.3.71.tar.gz
pushd pipewire-0.3.71
meson setup builddir && \
meson configure builddir -Dprefix=/usr && \
meson compile -C builddir && \
meson install -C builddir
popd
rm -rf pipewire-0.3.71
rm pipewire-0.3.71.tar.gz
popd
