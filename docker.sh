#!/usr/bin/env bash
set -e
source "$(dirname "$0")/docker.env"
ARCH=$(uname -m)

next_version() {
    echo "$(git show -s --format=%h)"
}

print_next_version() {
  echo "${IMAGE_NAME}:g$(next_version)"
}

print_registry() {
  echo ${REGISTRY}
}

print_image_name() {
  echo ${IMAGE_NAME}
}

print_rust_toolchain() {
  echo ${RUST_TOOLCHAIN}
}

# Builds the tag for the newest versions. It needs the last published version number.
# Returns a valid docker tag.
build_tag(){
  if [ "$ARCH" == "riscv64" ]; then
    new_tag=$(print_next_version)-riscv
  else
    new_tag=$(print_next_version)_$ARCH
  fi
  echo "$new_tag"
}

# Build a new docker version.
build(){
  new_tag=$(build_tag)
  docker build -t "$new_tag" \
        --load \
        --build-arg GIT_BRANCH="${GIT_BRANCH}" \
        --build-arg GIT_COMMIT="${GIT_COMMIT}" \
        --build-arg RUST_TOOLCHAIN="${RUST_TOOLCHAIN}" \
        -f Dockerfile .
  echo "Build completed for $new_tag"
}

# Creates and pushes a manifest for a new version
manifest(){
  new_tag=$(print_next_version)
  docker manifest create \
        $new_tag \
        "${new_tag}_x86_64" \
        "${new_tag}_aarch64"
  echo "Manifest successfully created"
  docker manifest push $new_tag
  echo "Manifest successfully pushed on DockerHub: ${DOCKERHUB_LINK}"
}

publish(){
    new_tag=$(build_tag)
    echo "Publishing $new_tag on dockerhub"
  	docker push "$new_tag"
  	echo "Successfully published $new_tag on DockerHub: ${DOCKERHUB_LINK}"
}

case $1 in
  "build")
    build;
    ;;
  "publish")
    publish;
    ;;
  "manifest")
    manifest;
    ;;
  "print-registry")
    print_registry;
    ;;
  "print-image-name")
    print_image_name;
    ;;
  "print-next-version")
    print_next_version;
    ;;
    "print-rust-toolchain")
    print_rust_toolchain;
    ;;
  *)
   echo "Command $1 not supported. Try with 'publish', 'build', 'manifest' or 'print-next-version'. ";
   ;;
esac
