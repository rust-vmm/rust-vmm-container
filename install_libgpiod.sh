#!/usr/bin/env bash
set -ex

# Install libgpiod (required by vhost-device crate)
pushd /opt
git clone --depth 1 --branch v2.0 https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/
pushd libgpiod
./autogen.sh --prefix=/usr && make && make install
popd
rm -rf libgpiod
popd
