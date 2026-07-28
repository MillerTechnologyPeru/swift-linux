# swift-linux

A small Linux distribution with the Swift runtime built in, and a Swift SDK for
cross-compiling applications to it.

Built with [Buildroot](https://buildroot.org). There is no systemd: the images
boot busybox init with SysV scripts, `seatd` for seat management and `basu`
where a D-Bus system-bus library is needed.

The images run a [sway](https://swaywm.org) session (wlroots, XWayland, Mesa)
on a read-only root filesystem with A/B update slots managed by
[RAUC](https://rauc.io), plus a separate data partition.

## Quick start

Every board and architecture is a make target:

```sh
make list                    # what can be built
make x86_64-build            # build the x86_64 image
make arm64-build             # build the arm64 image
make x86_64-pkg PKG=mesa3d   # rebuild a single package
make x86_64-shell            # a shell in the build environment

util/x86_64-qemu.sh          # boot the result in QEMU with a GTK window
```

`CONTAINER=1` runs the build in a per-architecture toolchain container as your
own user; `PARALLEL_BUILD=1` and `CCACHE=1` speed it up. See
[docs/build.md](docs/build.md).

## Configuration model

Configuration is plain text. Each `*.config` file is a set of Buildroot `BR2_…`
options, and `generate-config.sh` composes them into a defconfig:

```sh
./generate-config.sh --arch arm64 --profile image -o defconfig
./generate-config.sh --device retroid-pocket-5 --profile image
```

| Profile | Composes | For |
|---|---|---|
| `sdk` | toolchain, core libraries, tools, Swift | a minimal Swift sysroot |
| `app-sdk` | + applibs, GUI tools | cross-compiling applications |
| `image` | + network, audio, daemons, board | a bootable image |
| `lib32` | 32-bit companion userland, merged into a 64-bit image as `/usr/lib32` |

Fragments can pull in shared fragments with `include`, which is how boards share
a hardware family and a GPU capability rather than repeating themselves:

```
include sdk/board/qualcomm-sm8250/common.config
include sdk/defconfig/gpu/freedreno.config
```

Whatever the app-sdk can build against, the image can run: both compose the same
application libraries, and the 32-bit companion mirrors them too.

## Layout

| Path | Description |
|---|---|
| `sdk/defconfig/*.config` | Fragments: toolchain, libs, swift, applibs, network, audio, daemons, tools, image. |
| `sdk/defconfig/arch/` | Per-architecture fragments (`armv5`…`arm64`, `i386`, `x86_64`). |
| `sdk/defconfig/gpu/` | GPU capabilities: `virgl`, `freedreno`, `panfrost`, `radeonsi`, `x86-desktop`. |
| `sdk/board/<target>/` | One directory per board: `board.config`, kernel fragment, overlays, patches. |
| `sdk/board/common/` | Overlay, users and post-build scripts shared by every board. |
| `external/` | `BR2_EXTERNAL` packages: sway, SDL3, box64/box86, grim, steam. |
| `util/` | QEMU launchers, Swift SDK and CMake toolchain generators. |
| `docs/` | [Building](docs/build.md) and [the Swift SDK](docs/swift-sdk.md). |
| `Makefile`, `build-images.sh` | Per-target builds; both images plus companions in parallel. |

## Boards

Two targets are built and boot-tested — the **x86_64** and **arm64** QEMU/UEFI
images. The x86_64 image also carries the drivers a physical PC needs (AMD,
Intel and NVIDIA graphics with a software fallback, NVMe, wireless, HD-audio).

The rest are **definition only**: described in the tree, not yet built or
verified on hardware. Each board's README records what its bring-up still
needs.

| Family | Devices |
|---|---|
| Rockchip RK3326 / RK3399 / RK3566 / RK3576 / RK3588 | Anbernic RG351·RG353·RG503·RG552, Powkiddy, Odroid Go, Gameforce, MagicX, … |
| Allwinner H700 | Anbernic RG28XX … RG CubeXX |
| Amlogic S922X | Odroid Go Ultra, Powkiddy RGB10 Max 3 Pro |
| Qualcomm SM6115 / SM8250 / SM8550 / SM8650 / SM8750 | Retroid Pocket, AYN Odin, Ayaneo Pocket, Mangmi |
| Qualcomm SDM845 | OnePlus 6T / 6, Xiaomi Poco F1, SHIFT6mq |
| Chromebooks (RK3399, MT8183, MT8173, SC7180) | kevin, bob, krane, kodama, hana, lazor, coachz, homestar |
| Apple Silicon t600x | MacBook Pro 14"/16" (M1 Pro / M1 Max) |
| Valve | Steam Deck (LCD, OLED) |

Boot chains differ by family — UEFI/GRUB with A/B slots, U-Boot with extlinux,
Depthcharge kernel partitions, and Android boot images — but they share the same
fragments, kernel-config mechanism and build interface.

## Swift SDK

`util/make-swift-sdk.sh` packages a target sysroot as a Swift SDK
artifactbundle, so SwiftPM can cross-compile to the image:

```sh
util/make-swift-sdk.sh --arch arm64 --portable --install
swift build --swift-sdk aarch64-unknown-linux-gnu
```

`util/combine-swift-sdk.sh` merges the per-architecture bundles into one that
covers `aarch64`, `x86_64`, `armv7` and `i686`, and
`util/make-cmake-toolchain.sh` emits a CMake toolchain file for C/C++ projects
against the same sysroot. CI publishes both. Details in
[docs/swift-sdk.md](docs/swift-sdk.md).

## Continuous integration

`.github/workflows/build-images.yml` builds the images, the 32-bit companions
that get merged into them, and a Swift SDK per architecture, then publishes the
combined all-architecture SDK. Builds run in per-architecture containers whose
cached toolchain and Swift runtime are reused, so only the remaining packages
compile.
