#!/bin/bash

current_dir="$(dirname $(readlink -f "$0"))"
cd $current_dir/../..

ARCH=riscv64 ./docker.sh build
