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

On this host, always - there is no container backend. Buildroot needs the usual
build prerequisites plus a host compiler new enough for the tree's host tools
(mesa's Intel shader compiler wants GCC 13+, for example), and a seeded or
already-built `output/<arch>`.

CI is the exception, and only historically: `build-images.yml` and
`build-swift-sdk.yml` still start from the published
`colemancda/buildroot-swift` per-arch images, while `build-toolchain.yml` is the
from-source replacement whose release assets `<t>-seed` consumes.

### Accelerators

- `PARALLEL_BUILD=1` — per-package build dirs + a parallel top-level build.
- `CCACHE=1` — compiler cache under `CCACHE_DIR`.
- Downloads live in Buildroot's own `buildroot/dl`, which is already shared
  across every per-arch output; set `DL_DIR` to relocate it.

These carry over to `build-images.sh`, which builds x86_64 + arm64 (with their
32-bit companions) in parallel.

## Artifacts

Each image build writes `disk.img`, a `swift-linux-<target>.img` symlink, and a
`SHA256SUMS` manifest into the images directory. CI produces the same artifacts
nightly (`.github/workflows/build-images.yml`); a full image build is too long
to run per push.
