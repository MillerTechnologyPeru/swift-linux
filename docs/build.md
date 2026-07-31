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

### What lives on the runner's disk

```
/mnt/br/dl/              Buildroot downloads, shared by every workflow
/mnt/br/ccache/<arch>/   per-arch ccache, shared by every workflow
/mnt/br/shared/          the once-built host-swift tree (build-toolchain.yml)
/mnt/br/output/<arch>/   the per-arch Buildroot output trees
/mnt/br/pkg/<arch>/      scratch staging for the release tarball; removed after
```

This replaces the `actions/cache` restore/save steps the workflows used to
carry: uploading a multi-gigabyte ccache to GitHub and downloading it again next
run is pointless when the same disk is still there, and it no longer has to fit
the 10 GB repo-wide cache budget that forced `--max-size=1.5G`. The workflows
now set `CCACHE_MAX_SIZE: 20G` (one `env:` at the top of each file).

To force something to rebuild from scratch:

```sh
rm -rf /mnt/br/output/<arch>          # one architecture's toolchain tree
rm -rf /mnt/br/shared                 # host-swift; costs ~8 hours to replace
ccache -d /mnt/br/ccache/<arch> -C    # clear one architecture's ccache
```

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

Since there is one runner, jobs queue rather than run side by side: eight jobs
across the three workflows execute one at a time. Each workflow has a
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
