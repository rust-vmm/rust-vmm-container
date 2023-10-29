#!/usr/bin/env bash

REPO_DIR=/tmp/linux-loader
REPO_MOUNT_POINT=/workdir
IMAGE_TAG=$(ARCH=riscv64 ../../docker.sh print-next-version)_riscv64

docker run -it -v $REPO_DIR:$REPO_MOUNT_POINT --workdir $REPO_MOUNT_POINT $IMAGE_TAG bash
