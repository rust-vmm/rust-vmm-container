#!/usr/bin/env bash
set -e
ARCH=$(uname -m)
GIT_COMMIT=$(git rev-parse HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
IMAGE_NAME=rustvmm/dev
REGISTRY=index.docker.io

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

# Builds the tag for the newest versions. It needs the last published version number.
# Returns a valid docker tag.
build_tag(){
  new_tag=$(print_next_version)_$ARCH
  echo "$new_tag"
}

# Build a new docker version.
build(){
  new_tag=$(build_tag)
  docker build -t "$new_tag" \
        --load \
        --build-arg GIT_BRANCH="${GIT_BRANCH}" \
        --build-arg GIT_COMMIT="${GIT_COMMIT}" \
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
  *)
   echo "Command $1 not supported. Try with 'publish', 'build', 'manifest' or 'print-next-version'. ";
   ;;
esac
