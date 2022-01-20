# rust-vmm-container

**`rustvmm/dev`** is a container with all dependencies used for running
`rust-vmm` integration and performance tests.

The container is available on Docker Hub and has support for `x86_64` and
`aarch64` platforms.

For the latest available tag, please check the `rustvmm/dev` builds available
on [Docker Hub](https://hub.docker.com/r/rustvmm/dev/tags). Alternatively, you
can check out the Bash expression below.

```bash
DOCKERHUB="https://registry.hub.docker.com/v1/repositories/rustvmm/dev/tags"

VERSION=$(wget -c -q $DOCKERHUB -O -  \
  | tr -d '[]" '                      \
  | tr '}' '\n'                       \
  | awk -F: '{print $3}'              \
  | grep -v "_"                       \
  | cut -c 2-                         \
  | sort -n                           \
  | tail -1                           )

docker pull rustvmm/dev:$VERSION
```

Depending on which platform you're running the command from, docker will pull
either `rustvmm/dev:vX_aarch64` or `rustvmm/dev:vX_x86_64`.

For now rust is installed only for the root user.

## Using the Container

The container is currently used for running the integration tests for the
[kvm-ioctls](https://github.com/rust-vmm/kvm-ioctls) crate.

Example of running cargo build on the kvm-ioctls crate:

```bash
> git clone git@github.com:rust-vmm/kvm-ioctls.git
> cd kvm-ioctls/
> docker run --volume $(pwd):/kvm-ioctls \
         rustvmm/dev:v15 \
         /bin/bash -c "cd /kvm-ioctls && cargo build --release"
 Downloading crates ...
  Downloaded libc v0.2.48
  Downloaded kvm-bindings v0.1.1
   Compiling libc v0.2.48
   Compiling kvm-bindings v0.1.1
   Compiling kvm-ioctls v0.0.1 (/kvm-ioctls)
    Finished release [optimized] target(s) in 5.63s
```

## Available Tools

The container currently has the Rust toolchain version 1.58.1 and Python3.8.

Python packages:

- [`boto3`](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html#)
- [`pip3`](https://pip.pypa.io/en/stable/)
- [`pytest`](https://docs.pytest.org/en/latest/)
- [`pytest-timeout`](https://pypi.org/project/pytest-timeout/)
- [`pexpect`](https://pypi.org/project/pexpect/)

Cargo plugins:

- [`cargo-audit`](https://github.com/RustSec/cargo-audit)
- [`cargo-kcov`](https://github.com/kennytm/cargo-kcov)
- [`cargo-license`](https://github.com/onur/cargo-license)
- [`clippy`](https://github.com/rust-lang/rust-clippy)
- [`critcmp`](https://github.com/BurntSushi/critcmp)
- [`rustfmt`](https://github.com/rust-lang/rustfmt)

Rust targets on `x86_64`:

- `x86_64-unknown-linux-gnu`
- `x86_64-unknown-linux-musl`

Rust targets on `aarch64`:

- `aarch64-unknown-linux-gnu`
- `aarch64-unknown-linux-musl`

Miscellaneous utilities:

- `bc`
- `bison`
- `cpio`
- `debootstrap`
- `flex`
- `git`
- `wget`
- `shellcheck`

## Publishing a New Version
On an `aarch64` platform:

```bash
> cd rust-vmm-dev-container
> ./docker.sh build
> ./docker.sh publish
```

You will need to redo all steps on an `x86_64` platform so the containers are
kept in sync (same package versions on both `x86_64` and `aarch64`).

Now that the tags `v4_x86_64` and `v4_aarch64` are pushed to Docker Hub, we can
go ahead and also create a new version tag that points to these two builds
using
[docker manifest](https://docs.docker.com/engine/reference/commandline/manifest/).

```bash
./docker.sh manifest
```

If it is the first time you are creating a docker manifest, most likely it will
fail with: ```docker manifest is only supported when experimental cli features
are enabled```. Checkout
[this article](https://medium.com/@mauridb/docker-multi-architecture-images-365a44c26be6)
to understand why and how to fix it.
