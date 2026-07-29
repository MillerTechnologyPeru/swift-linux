# Building images

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
  win). See `sdk/defconfig/frontend/README.md`.

## The Makefile (per-target verbs)

Every board/arch with a `sdk/board/<t>/board.config` is discovered
automatically and gets the same verbs:

```sh
make list                        # available targets
make x86_64-build                # build the image
make arm64-config                # (re)configure Buildroot only
make x86_64-pkg PKG=mesa3d       # rebuild one package
make arm64-shell                 # shell in the build env
make retroid-pocket-5-defconfig  # generate a defconfig only
make x86_64-clean                # remove that target's output
make x86_64-refresh DAYS=7       # dirclean local packages changed recently
make arm64-seed                  # pre-populate a fresh output from the
                                 # container's baked toolchain build
```

`<t>-seed` copies the toolchain container's prebuilt Buildroot output into
the host tree, the way CI reuses it: a fresh tree then skips the multi-hour
toolchain/Swift build, and the next `<t>-config` applies this repo's
defconfig incrementally on top. The `CONTAINER=1` bind mount shadows the
baked copy, which is why it must be copied out once. Refuses to touch an
existing output directory.

Adding a board is dropping a `board.config`; no Makefile edits.

### Backends

- **default** — build on the host toolchain (needs a prebuilt `output/<arch>`).
- **`CONTAINER=1`** — build in the matching per-arch toolchain container, as
  your own UID/GID, with the tree bind-mounted at both the container's
  `/workspaces` path (for the baked toolchain paths) and its host path (for
  the host-absolute paths generated defconfigs carry). Uses docker or podman,
  whichever is on `PATH` - rootless podman gets `--userns=keep-id` so nothing
  comes back owned by a subuid; override with `CONTAINER_RUNTIME=`.

### Accelerators

- `PARALLEL_BUILD=1` — per-package build dirs + a parallel top-level build.
- `CCACHE=1` — compiler cache under `CCACHE_DIR`.
- Downloads live in Buildroot's own `buildroot/dl`, which is already shared
  across every per-arch output; set `DL_DIR` to relocate it.

These carry over to `build-images.sh`, which builds x86_64 + arm64 (with their
32-bit companions) in parallel.

## Artifacts

Each image build writes `disk.img`, a `swift-linux-<target>.img` symlink, and a
`SHA256SUMS` manifest into the images directory.
