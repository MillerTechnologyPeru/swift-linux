# Building images

## Sources

Buildroot and the two `BR2_EXTERNAL` trees the build consumes are submodules,
so a checkout pins the revisions it was tested against:

| Path | Repository | Provides |
|---|---|---|
| `buildroot/` | [MillerTechnologyPeru/buildroot](https://github.com/MillerTechnologyPeru/buildroot) | the Buildroot fork |
| `swift/` | [buildroot-swift](https://github.com/MillerTechnologyPeru/buildroot-swift) | the Swift toolchain and runtime packages |
| `ports/` | [buildroot-ports](https://github.com/MillerTechnologyPeru/buildroot-ports) | apps, games and the GUI libraries they need |

```sh
git clone --recurse-submodules https://github.com/MillerTechnologyPeru/swift-linux.git
# or, in an existing clone:
make submodules
```

`external/` stays in this repo for what is specific to Swift Linux itself:
the initramfs, board firmware, and the storage/automount daemons. Anything
reusable belongs in `ports/` - add it there rather than here.

## Configuration model

Images are described by **text defconfig fragments** under `sdk/defconfig/`,
assembled by `generate-config.sh` per profile (`sdk`, `app-sdk`, `image`,
`lib32`). Fragments can pull in shared fragments with an `include` directive:

```
include sdk/defconfig/gpu/virgl.config
include sdk/defconfig/frontend/gmenu2x.config
```

Includes are expanded once (cycle-safe), so hardware families share config
instead of duplicating it. Examples:

- `sdk/defconfig/gpu/{virgl,freedreno}.config` — GPU **capabilities**; a board
  includes the one for its GPU.
- `sdk/board/qualcomm-sm8250/common.config` — a **hardware-family** fragment;
  each SM8250 device board includes it and adds only its device tree name.
- `sdk/defconfig/frontend/*.config` — the image's **frontend** (session +
  launcher); the image profile includes the EmulationStation default and a
  board overrides it by including another (emitted later, so its negations
  win). `--frontend <name>` (or `FRONTEND=<name>` for `build-images.sh`)
  overrides it for one build without editing the board, which is how the
  `minimal` frontend — sway and foot, none of the emulator stack — is used to
  check that a board boots before spending the time on a full image. See
  `sdk/defconfig/frontend/README.md`.

## The Makefile (per-target verbs)

Every board/arch with a `sdk/board/<t>/board.config` is discovered
automatically and gets the same verbs:

```sh
make list                        # available targets
make x86_64-build                # build the image
make arm64-config                # (re)configure Buildroot only
make x86_64-pkg PKG=mesa3d       # rebuild one package
make retroid-pocket-5-defconfig  # generate a defconfig only
make x86_64-clean                # remove that target's output
make x86_64-refresh DAYS=7       # dirclean local packages changed recently
make arm64-seed                  # pre-populate a fresh output with a
                                 # prebuilt toolchain
```

`<t>-seed` fetches a prebuilt Buildroot `output/<arch>` from the
`toolchain-latest` release, which `build-toolchain.yml` builds from source per
architecture. Without it an empty tree makes Buildroot build gcc, glibc and
host-swift itself - hours before any package of this repo's own compiles. With
it, the next `<t>-config` applies this repo's defconfig on top and only the
difference builds.

The asset ships as split `.tar.zst` parts (release assets cap at 2 GiB, an
output tree does not); `make <t>-seed` concatenates them for you, and needs the
`gh` CLI and `zstd`. It refuses to unpack over an existing output directory:
Buildroot stamps absolute paths into a tree, so mixing two configurations there
is worse than starting over. Seed once per architecture and keep the tree -
`<t>-clean` throws that toolchain away with it.

Adding a board is dropping a `board.config`; no Makefile edits.

### Where builds run

On this host by default. Buildroot needs the usual build prerequisites plus a
host compiler new enough for the tree's host tools (mesa's Intel shader
compiler wants GCC 13+, for example), and a seeded or already-built
`output/<arch>`.

If the host cannot satisfy the prerequisites, `CONTAINER=1` runs the identical
build inside `colemancda/buildroot-swift:latest` - the plain base image
(Debian 13 with the Swift toolchain and every Buildroot host dependency, no
Buildroot tree or prebuilt output baked in; not the retired per-arch images,
whose GCC 12 could no longer build the host tools). Everything mutable stays
on host mounts: the repo and `output/` at their own paths, the ccache over
Buildroot's default cache location, and the per-target output *also* at the
container root (`O=/<target>`), so the absolute paths Buildroot embeds - and
ccache hashes - do not depend on where the repo is checked out.

CI is the exception, and only historically: `build-images.yml` and
`build-swift-sdk.yml` still start from the published
`colemancda/buildroot-swift` per-arch images, while `build-toolchain.yml` is the
from-source replacement whose release assets `<t>-seed` consumes. All of them
run on the self-hosted runner - see [Continuous integration](#continuous-integration).

### Accelerators

- `PARALLEL_BUILD=1` — per-package build dirs + a parallel top-level build.
- `CCACHE=1` — compiler cache under `CCACHE_DIR`. Pass it (and the other knobs)
  in the environment - `CCACHE=1 make x86_64-build` - not as a make argument: in
  Buildroot `CCACHE` holds the path to the ccache binary, and a command-line
  variable would override it and break `HOSTCC`. The Makefile refuses that form
  rather than letting it corrupt the build.
- Downloads live in Buildroot's own `buildroot/dl`, which is already shared
  across every per-arch output; set `DL_DIR` to relocate it.

These carry over to `build-images.sh`, which builds x86_64 + arm64 (with their
32-bit companions) in parallel.

## Continuous integration

All three workflows run on a **self-hosted x86 runner**, not on GitHub's pool:

```
runs-on: [self-hosted, Linux, X64]
```

A hosted runner cannot finish this work. `build-toolchain.yml` builds
`host-swift` from source - hours of LLVM and Swift on four cores - against a
hard six-hour job limit, and throws its disk away afterwards, so every run
starts cold. The self-hosted machine has none of those limits, and, more
importantly, **its disk persists between runs**: an output tree built last week
is still there this week, so a rebuild is incremental.

### What the machine must provide

- **Docker.** Every heavy job runs in a `colemancda/buildroot-swift` container.
- **A writable `/mnt` with room to spare**, on a large filesystem. All the state
  below lives there, and the jobs bind-mount it with `--volume /mnt:/mnt`. Each
  job checks free space up front and fails in seconds rather than at hour six -
  100 GB for the toolchain jobs, 50 GB for the rest.
- **`jq`, `gh` and `tar` installed on the host**, for the two jobs that run
  outside a container (`combined-swift-sdk`, `config-check`). Those used to come
  free with `ubuntu-latest`. `combined-swift-sdk` checks and names what is
  missing.

### The host-tool dependency graph

`build-toolchain.yml` runs **one job per host tool** rather than one opaque
multi-hour build, so each gets its own log, its own red mark, and can be re-run
without paying for the others. The order comes from Buildroot's own graph — read
out of `make show-info` on a configured tree — split by one question: *does the
tool depend on the target architecture?*

```
  shared tree /mnt/br/shared            per-arch tree /mnt/br/output/<arch>
  (built once, all arches use it)       (four of each, one per architecture)

  host-base ─┐                          host-gcc ──> host-rust ──> host-go ─┐
   cmake     │                           binutils     rustc         go-src  │
   ninja     │                           gcc-initial  rust-bin      +5-stage│
   meson     │                           glibc        (target std)  bootstrap
   python3   │                           gcc-final                          │
   pkgconf   │                                                              │
             ▼                                                              ▼
          host-jdk ──> host-dotnet ──> host-swift ────────────────────> toolchain
           openjdk-bin   mono           (no deps at all)                  publish
                         monolite
```

**Architecture-independent**, so built once and shared:

| job | builds | why it is shareable |
|---|---|---|
| `host-base` | cmake, ninja, meson, python3, pkgconf — and the 21-package closure under them (m4/autoconf/automake/libtool, expat, libffi, zlib, python's build backends) | plain host tools; nothing in their config mentions the target |
| `host-jdk` | `host-openjdk-bin` | a prebuilt download; the boot JDK the target `openjdk` bootstraps from, never installed on target |
| `host-dotnet` | `host-mono` (pulls `host-monolite`, `host-gettext`) | the bootstrap C#/CLR compiler for the target `mono` that Unity and XNA/FNA ports need. Buildroot only offers mono when `BR2_HOSTARCH` is x86 — which this runner is, and an arm builder would not be |
| `host-swift` | `host-swift` | declares **no dependencies at all** — it clones and builds its own LLVM through `build-script`, and the preset targets `--host-target linux-x86_64` whatever Buildroot is aiming at |

**Target-dependent**, so built per architecture — with the evidence, because
each of these looks shareable until you read its `.mk`:

| job | builds | what makes it per-arch |
|---|---|---|
| `host-gcc` | `make toolchain`: binutils, gcc-initial, glibc, gcc-final | this *is* the cross compiler — `gcc.mk` configures `--target=$(GNU_TARGET_NAME)` |
| `host-rust` | `host-rustc` → `host-rust-bin` | `rust-bin.mk` adds `rust-std-$(RUSTC_TARGET_NAME)` to `EXTRA_DOWNLOADS` — the standard library for the target triple. Consumed by ruffle |
| `host-go` | `host-go` → `host-go-src` + a five-stage bootstrap | `go.mk` sets `GO_GOARCH` from the target arch |

Two consequences worth knowing:

- **The stages are barriers, and that is deliberate.** The four shared jobs write
  to one tree, so they are a linear chain; two of them at once would race on its
  stamps. The per-arch stages fan out over four *different* trees, so their jobs
  are safe to run concurrently — the ordering between stages is what `needs:`
  buys. On a single runner everything serializes anyway; the graph makes that a
  guarantee rather than an accident of runner count.
- **A host package does not have to be selected to be buildable.** Buildroot
  registers make targets for every package it parses, so `make host-rustc` works
  in an `sdk`-configured tree even though the `sdk` profile does not select
  Rust. That is what lets these jobs build the full host-tool set without
  widening the profile the workflow publishes.

Not built: `host-llvm`, `host-clang` and `host-mesa3d`. `host-llvm` is per-target
too (`LLVM_DEFAULT_TARGET_TRIPLE`), they cost hours per architecture, and they
belong to the image profile's graphics stack — nothing in the `sdk` profile this
workflow publishes consumes them. They would be three more jobs in the per-arch
chain.

The prelude every one of these twenty jobs shares — apt prerequisites, the disk
guard, the submodule checkout, `defconfig`, and the memory-bounded `-j` — lives
once in the `.github/actions/br-setup` composite action, which exports `BR_B`,
`BR_O`, `BR_EXT` and `BR_JOBS` for the `make` step that follows.

### What lives on the runner's disk

```
/mnt/br/dl/                  Buildroot downloads, shared by every workflow
/mnt/br/ccache/<arch>/       per-arch ccache, shared by every workflow
/mnt/br/ccache/host-shared/  ccache for the shared host-tool tree
/mnt/br/shared/              the once-built arch-independent host tools
                             (base, JDK, .NET, Swift)
/mnt/br/output/<arch>/       the per-arch Buildroot output trees
/mnt/br/pkg/<arch>/          scratch staging for the release tarball; removed after
```

This replaces the `actions/cache` restore/save steps the workflows used to
carry: uploading a multi-gigabyte ccache to GitHub and downloading it again next
run is pointless when the same disk is still there, and it no longer has to fit
the 10 GB repo-wide cache budget that forced `--max-size=1.5G`. The workflows
now set `CCACHE_MAX_SIZE: 20G` (one `env:` at the top of each file).

To force something to rebuild from scratch:

```sh
rm -rf /mnt/br/output/<arch>          # one architecture's gcc/rust/go + toolchain
rm -rf /mnt/br/shared                 # every shared host tool; ~8 hours to replace
ccache -d /mnt/br/ccache/<arch> -C    # clear one architecture's ccache
```

To rebuild a single tool, delete its build directory rather than the tree:
`rm -rf /mnt/br/shared/build/host-mono-*` and re-run that job.

`host-swift` is built once and only republished when `SWIFT_VERSION` changes;
`gh workflow run build-toolchain.yml -f force_republish=true` overrides that.

### Two things not to break

**The workflows have no `pull_request` or `push` trigger, and must not gain
one.** This repository is public. A self-hosted runner executes whatever the
workflow says on a real machine, so a fork PR that could trigger a workflow
would be arbitrary code execution on it. `schedule` and `workflow_dispatch` can
only be fired from the default branch by someone with write access.

**Container jobs hand the workspace back on the way out.** They run as root and
leave root-owned files in `$GITHUB_WORKSPACE`, which - unlike a hosted VM -
survives the job. The next run's `actions/checkout` runs as the runner user and
cannot `git clean` them, so every container job ends with a `chown -R` back to
the workspace's owner. Removing that step makes the *second* run fail, not the
first.

Since there is one runner, jobs queue rather than run side by side — thirty
across the three workflows, twenty of them the per-host-tool jobs above. Each
job pays its own container start and apt prerequisites, roughly twenty minutes
of overhead across a full toolchain run; that is the price of an attributable
failure per tool rather than one four-hour log. Each workflow has a
`concurrency` group so a nightly still running when the next fires is superseded
rather than stacked.

## Artifacts

Each image build writes `disk.img`, a `swift-linux-<target>.img` symlink, and a
`SHA256SUMS` manifest into the images directory. CI produces the same artifacts
nightly (`.github/workflows/build-images.yml`); a full image build is too long
to run per push.

## Verifying a boot

A build succeeding says nothing about whether the image boots, so
`util/boot-verify.sh` does that part:

```sh
make x86_64-build FRONTEND=minimal      # the bring-up frontend, above
util/boot-verify.sh                     # boots it headless and checks it
```

It prints one line per check and exits non-zero on the first failure, following
the boot in order: the data partition mounting, the RNG-seed and clock scripts
that depend on it, `agetty.tty1` bringing up a session with nobody touching a
keyboard, that session belonging to the unprivileged user rather than root, the
frontend resolving to a terminal, and GL being accelerated rather than quietly
software. It finishes by writing a screenshot next to the image, and leaves
`boot-verify-serial.log` there either way. `--arch arm64`, `--image`,
`--timeout` and `--keep` are the knobs; `--help` lists them.

Two things about it are worth knowing, because both are easy to get wrong:

- **The guest keeps a GL-capable virtio-gpu even with no window.** wlroots needs
  a render node, not a display, so "headless" and "no GL" are separate choices -
  conflating them boots to a serial console with no session to inspect. The
  launchers (`util/x86_64-qemu.sh`, `util/arm64-qemu.sh`) handle this, and gained
  `QEMU_SERIAL_LOG`/`QEMU_SERIAL_SOCK`/`QEMU_MONITOR_SOCK` so a script can read
  the boot log, drive the console, and shut the machine down cleanly.
- **The screenshot comes from `grim` inside the guest**, not from QEMU. With a GL
  scanout QEMU's own `screendump` answers `Error: no surface`, which is why
  `grim` is in `tools-gui.config` in the first place.

Guest interaction goes over the serial console (`util/qemu-console.py`), which
needs no ssh key or password automation - the console is a getty, and the script
logs in the way a person would (`root`/`root`; the session account is
`user`/`1234`, see the README).
