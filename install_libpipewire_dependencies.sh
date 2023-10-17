#!/usr/bin/env bash
set -ex

DEBIAN_FRONTEND="noninteractive" apt-get install --no-install-recommends -y \
    libasound2 libasound2-dev \
    debhelper-compat findutils libavcodec-dev libavfilter-dev libavformat-dev \
    libdbus-1-dev libbluetooth-dev libglib2.0-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev libsbc-dev libsdl2-dev libudev-dev \
    libva-dev libv4l-dev libx11-dev meson ninja-build python3-docutils systemd
