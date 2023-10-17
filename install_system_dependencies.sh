#!/usr/bin/env bash
set -ex

apt-get update

# DEBIAN_FRONTEND is set for tzdata.
DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    curl gcc git python3 python3-pip shellcheck \
    libssl-dev tzdata cmake g++ pkg-config jq libcurl4-openssl-dev libelf-dev \
    libdw-dev binutils-dev libiberty-dev make \
    cpio bc flex bison wget xz-utils fakeroot \
    autoconf autoconf-archive automake libtool \
    libclang-dev iproute2 \
    libasound2 libasound2-dev

pip3 install --no-cache-dir pytest pexpect boto3 pytest-timeout && apt purge -y python3-pip
