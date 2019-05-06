# rust-vmm-dev-container

**rust-vmm-dev** is a container with all dependencies used for running
rust-vmm integration tests.

The container is available on Docker Hub and has support for x86_64 and
aarch64 platforms.
Pull the latest version by running:

```bash
docker pull fandree/rust-vmm-dev
```

Depending on which platform you're running the command from, docker will pull
either `rust-vmm-dev:aarch64` or `rust-vmm-dev:x86_64`.

For now rust is installed only for the root user.

### Using the Container

The container is currently used for running the integration tests for the
[kvm-ioctls](https://github.com/rust-vmm/kvm-ioctls) crate.

Example of running cargo build on the kvm-ioctls crate:

```bash
> git clone git@github.com:rust-vmm/kvm-ioctls.git
> cd kvm-ioctls/
> docker run --volume $(pwd):/kvm-ioctls \
         fandree/rust-vmm-dev \
         /bin/bash -c "cd /kvm-ioctls && cargo build --release"
 Downloading crates ...
  Downloaded libc v0.2.48
  Downloaded kvm-bindings v0.1.1
   Compiling libc v0.2.48
   Compiling kvm-bindings v0.1.1
   Compiling kvm-ioctls v0.0.1 (/kvm-ioctls)
    Finished release [optimized] target(s) in 5.63s
```

### Available Tools

The container currently has the Rust toolchain version 1.33.0 and Python3.6.

Python packages:
- [pip3](https://pip.pypa.io/en/stable/)
- [pytest](https://docs.pytest.org/en/latest/)

Cargo plugins:
- [rustfmt](https://github.com/rust-lang/rustfmt)
- [cargo-kcov](https://github.com/kennytm/cargo-kcov)
- [clippy](https://github.com/rust-lang/rust-clippy) - only available on
  x86_64. For details check this issue:
  https://github.com/rust-lang/rust-clippy/issues/3682

Rust targets on x86_64:
- x86_64-unknown-linux-gnu
- x86_64-unknown-linux-musl

Rust targets on aarch64:
- aarch64-unknown-linux-gnu
- aarch64-unknown-linux-musl

### Publishing a New Version

On an aarch64 platform:

```bash
> cd rust-vmm-dev-container
> # Build a container image for aarch64
> docker build -t rust-vmm-dev:aarch64 -f Dockerfile.aarch64 .
> docker images
REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
fandree/rust-vmm-dev   aarch64             f3fd02dfb213        21 hours ago        1.13GB
fandree/rust-vmm-dev   latest              f3fd02dfb213        21 hours ago        1.13GB
ubuntu                 18.04               0926e73e5245        3 weeks ago         80.4MB
>
> docker tag f3fd02dfb213 fandree/rust-vmm-dev:aarch64
> docker push fandree/rust-vmm-dev
```

You will need to redo all steps on a x86_64 platform so the containers are kept
in sync (same package versions on both x86_64 and aarch64).

```bash
> docker build -t rust-vmm-dev:x86_64 -f Dockerfile.x86_64 .
> docker tag XXXXXXXX fandree/rust-vmm-dev:x86_64
> docker push fandree/rust-vmm-dev
```

Now that new versions of the tags `x86_64` and `aarch64` are pushed to Docker
Hub, we can go ahead and also update the latest tag using
[docker manifest](https://docs.docker.com/engine/reference/commandline/manifest/).

```bash
docker manifest create \
        fandree/rust-vmm-dev:latest \
        fandree/rust-vmm-dev:x86_64 \
        fandree/rust-vmm-dev:aarch64
docker manifest push fandree/rust-vmm-dev:latest
```

If it is the first time you are creating a docker manifest, most likely it will
fail with: ```docker manifest is only supported when experimental cli features
are enabled```. Checkout
[this article](https://medium.com/@mauridb/docker-multi-architecture-images-365a44c26be6)
to understand why and how to fix it.
