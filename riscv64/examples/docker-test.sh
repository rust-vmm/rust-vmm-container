#!/usr/bin/env bash

REPO_DIR=/tmp/linux-loader
REPO_MOUNT_POINT=/workdir
IMAGE_TAG=$(ARCH=riscv64 ../../docker.sh print-next-version)_riscv64

## CI: build-gnu-riscv64
echo "build-gnu-riscv64"
docker run -it --rm \
	-v $REPO_DIR:$REPO_MOUNT_POINT \
	--workdir $REPO_MOUNT_POINT \
	$IMAGE_TAG \
	sh -c -e \
	"trap 'chown -R $(id -u):$(id -u) $REPO_MOUNT_POINT' 0; \
	RUSTFLAGS=\"-D warnings\" \
	cargo build --release --target=riscv64gc-unknown-linux-gnu \
	--config target.riscv64gc-unknown-linux-gnu.linker=\\\"riscv64-linux-gnu-gcc\\\""

## CI: unittests-gnu-riscv64
echo "unittests-gnu-riscv64"
docker run -it --rm \
	-v $REPO_DIR:$REPO_MOUNT_POINT \
	--workdir $REPO_MOUNT_POINT \
	$IMAGE_TAG \
	sh -c -e \
	"trap 'chown -R $(id -u):$(id -u) $REPO_MOUNT_POINT' 0; \
	cargo test --no-run \
	--target=riscv64gc-unknown-linux-gnu \
	--config target.riscv64gc-unknown-linux-gnu.linker=\\\"riscv64-linux-gnu-gcc\\\" \
	&& qemu.sh"
