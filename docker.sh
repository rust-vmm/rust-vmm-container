#!/usr/bin/env bash
set -e
ARCH=${ARCH:-$(uname -m)}
GIT_COMMIT=$(git rev-parse HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# Due to the workaround to support RISC-V CI (as explained in README.md),
# for riscv64, ARCH=riscv64 needs to be specified because of dedicated Dockerfile.riscv64 and Docker Hub repository.
case $ARCH in
  riscv | riscv64)
    DOCKER_TAG=rustvmm/dev_riscv64
    ;;
  *)
    DOCKER_TAG=rustvmm/dev
    ;;
esac

# Get the latest published version. Returns a number.
# If latest is v100, returns 100.
# This works as long as we have less than 100 tags because we set the page size to 100,
# once we have more than that this script needs to be updated.
latest(){
  curl -L -s "https://registry.hub.docker.com/v2/repositories/${DOCKER_TAG}/tags?page_size=100"| \
    jq '."results"[]["name"]' |  sed 's/"//g' | cut -c 2- | grep -E "^[0-9]+$" | sort -n | tail -1
}

next_version() {
    latest_version=$(latest)
    new_version=$((latest_version + 1))
    echo "$new_version"
}

print_next_version() {
  echo "${DOCKER_TAG}:v$(next_version)"
}

# Builds the tag for the newest versions. It needs the last published version number.
# Returns a valid docker tag.
build_tag(){
  new_version=$(next_version)
  case $ARCH in
    riscv | riscv64)
      new_tag=${DOCKER_TAG}:v${new_version}_riscv64
      ;;
    *)
      new_tag=${DOCKER_TAG}:v${new_version}_$ARCH
      ;;
  esac
  echo "$new_tag"
}

# Build a new docker version.
# It will build a new docker image with tag latest version + 1
# and will alias it with "latest" tag.
build(){
  new_tag=$(build_tag)
  case $ARCH in
    riscv | riscv64)
      dockerfile=Dockerfile.riscv64
      ;;
    *)
      dockerfile=Dockerfile
      ;;
  esac
  echo "docker build"
  docker build -t "$new_tag" \
        --build-arg GIT_BRANCH="${GIT_BRANCH}" \
        --build-arg GIT_COMMIT="${GIT_COMMIT}" \
        -f $dockerfile .
  echo "Build completed for $new_tag"
}

# Creates and pushes a manifest for a new version
manifest(){
  latest_version=$(latest)
  new_version=$((latest_version + 1))
  new_tag=${DOCKER_TAG}:v${new_version}
  case $ARCH in
    riscv | riscv64)
      docker manifest create \
            $new_tag \
            "${new_tag}_riscv64"
      ;;
    *)
      docker manifest create \
            $new_tag \
            "${new_tag}_x86_64" \
            "${new_tag}_aarch64"
      ;;
  esac
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
  "print-next-version")
    print_next_version;
    ;;
  *)
   echo "Command $1 not supported. Try with 'publish', 'build', 'manifest' or 'print-next-version'. ";
   ;;
esac
