# rust-vmm-container

**`rustvmm/dev`** is a container with all dependencies used for running
`rust-vmm` integration and performance tests. The container is available on
Docker Hub and has support for `x86_64` `aarch64` and `riscv64` platforms.

The latest available tag is `latest` for `x86_64` and `aarch64` and
`latest-riscv` for `riscv64`. If you want `git sha1` lables or previously used
`vN` counter labels, please check the `rustvmm/dev` builds available on 
[Docker Hub](https://hub.docker.com/r/rustvmm/dev/tags).

Note: we used counter tagging `vN` for `rustvmm/dev` until `v49`, but now we
switch to `git sha1` tagging. Details are recorded in #121.

## Know Issues

For now rust is installed only for the root user.

## Using the Container

The container is currently used for running the integration tests for the
majority of rust-vmm crates.

Example of running cargo build on the kvm crate:

```bash
> git clone https://github.com/rust-vmm/kvm.git
> cd kvm
# latest for x86_64 and aarch64, latest-riscv for riscv64
> docker run --volume $(pwd):/kvm \
         rustvmm/dev:latest \
         /bin/bash -c "cd /kvm && cargo build --release"
 Downloading crates ...
  Downloaded bitflags v1.3.2
  Downloaded vmm-sys-util v0.12.1
   Compiling libc v0.2.169
   Compiling bitflags v1.3.2
   Compiling kvm-ioctls v0.20.0 (/kvm/kvm-ioctls)
   Compiling bitflags v2.8.0
   Compiling vmm-sys-util v0.12.1
   Compiling kvm-bindings v0.11.0 (/kvm/kvm-bindings)
    Finished `release` profile [optimized] target(s) in 6.34s
```

For Windows users (ensure Docker Desktop is in Linux containers mode):
```powershell
> git clone https://github.com/rust-vmm/kvm.git
> cd kvm
> docker run --volume "${PWD}:/kvm" `
    rustvmm/dev:latest `
    /bin/bash -c "cd /kvm && cargo build --release"
```
## Testing Changes locally with the Container Image

When we modify the container to install new dependencies, we may need to 
test the new dependencies locally, before publishing the PR.
To do this, first build the rust-vmm container locally by running the commands

```bash
> cd rust-vmm-container
> ./docker.sh build
```

This command will build a new docker image with tag g$(git show -s --format=%h),
and alias it as latest. For local testing of changes to the container, you can
thus either run rustvmm/dev:latest, or use the explicit tag output by
`./docker.sh build`.

Example of this output is `Build completed for rustvmm/dev:g0c21d2c_x86_64`

Example of how to test the container on your localhost with tag
`g0c21d2c_x86_64`:

```bash
> docker run --device=/dev/kvm -it --rm \
--volume $(pwd):/path/to/workdir --workdir /path/to/workdir \
--privileged rustvmm/dev:g0c21d2c_x86_64
```
The `--workdir /workdir` option ensures that when the container starts,
the working directory inside the container is set to `/workdir`
Since you've mounted the host's current directory ($(pwd)) to `/workdir` in
the container, any files in the current working directory on the host will be
accessible in the `/workdir` directory inside the container.

For Windows (ensure Docker Desktop is in Linux containers mode):
```powershell
> cd rust-vmm-container
> .\docker.ps1 build

# Example output: Build completed for rustvmm/dev:gb607c2b_x86_64

# Test the container using the tag from the build output
> docker run -it --rm `
    --volume "${PWD}:/path/to/workdir" `
    --workdir /path/to/workdir `
    rustvmm/dev:gb607c2b_x86_64
```

Note: Unlike Linux, Windows doesn't have direct access to KVM, so the `--device=/dev/kvm` and `--privileged` flags are not needed.

Note: If you want to build a Windows container instead, you can switch Docker Desktop to "Windows containers" mode and run:
```powershell
> cd rust-vmm-container
> .\docker.ps1 build   # This will automatically use Dockerfile.windows.x86_64
```

## Publishing a New Version

A new container version is published for each PR merged to main that adds
changes to the [Dockerfile](Dockerfile) or the related scripts. Publishing the
container happens automatically through the
[.github/workflows](.github/workflows) and no manual intervention is required.

You can check the progress of a commit being published to Docker Hub by looking
at the GitHub commit history, and clicking on the status check of the relevant
commit.

![alt](img/container_build.png)

### Manual Publish

If for any reason the GitHub workflow is not working and a new container
version was not automatically pushed when merging the Dockerfile changes to
the main branch, you can follow the steps below for a manual publish.

The rust-vmm organization on Docker Hub is free and thus has only 3 members
that are allowed to publish containers:
- [Andreea Florescu](https://github.com/andreeaflorescu)
- [Laura Loghin](https://github.com/lauralt)
- and the rust-vmm bot account

On an `aarch64` platform:

```bash
> cd rust-vmm-dev-container
> ./docker.sh build
> ./docker.sh publish
```

On Windows (ensure Docker Desktop is in Linux containers mode):

```powershell
> cd rust-vmm-container
> .\docker.ps1 build
> .\docker.ps1 publish


# To check if Docker is in Linux containers mode:
> docker version --format '{{.Server.Os}}'  # Should output 'linux'
```

You will need to redo all steps on an `x86_64` platform so the containers are
kept in sync (same package versions on both `x86_64` and `aarch64`).

Now that the tags `g0c21d2c_x86_64` and `g0c21d2c_aarch64` are pushed to Docker
Hub, we can go ahead and also create a new version tag that points to these two
builds using
[docker manifest](https://docs.docker.com/engine/reference/commandline/manifest/).

```bash
./docker.sh manifest
```

If it is the first time you are creating a docker manifest, most likely it will
fail with: ```docker manifest is only supported when experimental cli features
are enabled```. Checkout
[this article](https://medium.com/@mauridb/docker-multi-architecture-images-365a44c26be6)
to understand why and how to fix it.
