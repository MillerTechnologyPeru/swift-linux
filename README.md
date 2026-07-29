# swift-linux

A small Linux distribution with the Swift runtime built in, and a Swift SDK for
cross-compiling applications to it.

Built with [Buildroot](https://buildroot.org). There is no systemd: busybox
stays pid 1 and hands boot to [OpenRC](https://github.com/OpenRC/openrc)
runlevels (Alpine's model), with `seatd` for seat management and `basu` where
a D-Bus system-bus library is needed.

Images boot into a **frontend** on a read-only root filesystem with A/B update
slots managed by [RAUC](https://rauc.io), plus a separate data partition. The
default frontend is [EmulationStation](https://github.com/ROCKNIX/emulationstation-next)
on a [sway](https://swaywm.org) session (wlroots, XWayland, Mesa), with
RetroArch and libretro cores behind it; boards can pick another - see
[Frontends](#frontends).

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

## Frontends

The user-facing shell of an image is a swappable fragment
(`sdk/defconfig/frontend/`): the image profile includes the default, and a
board switches by including a different one from its `board.config` - board
fragments are emitted last, so the alternative's negations unwind the default.

| Frontend | For | Status |
|---|---|---|
| EmulationStation + sway | GL(ES) gaming devices (default) | working: RetroArch backend, NES/Apps/Games/Tools groups, squashfs app bundles, WiFi/BT/power menus wired to ConnMan/BlueZ/OpenRC |
| gmenu2x | armv5 / no-GPU handhelds, SDL 1.2 on the framebuffer | definition only |
| XFCE + Chicago95 | desktop use on X.org, Windows 95 look by default | packaged, not yet booted |
| GNOME | desktop Wayland (mutter/gnome-shell via elogind on OpenRC) | packaged, not yet compiled |
| Phosh | Android-phone form factors | placeholder |

Details and per-fragment status: [sdk/defconfig/frontend/README.md](sdk/defconfig/frontend/README.md).

## Layout

| Path | Description |
|---|---|
| `sdk/defconfig/*.config` | Fragments: toolchain, libs, swift, applibs, network, audio, daemons, tools, image. |
| `sdk/defconfig/arch/` | Per-architecture fragments (`armv5`…`arm64`, `i386`, `x86_64`). |
| `sdk/defconfig/gpu/` | GPU capabilities: `virgl`, `freedreno`, `panfrost`, `radeonsi`, `x86-desktop`. |
| `sdk/board/<target>/` | One directory per board: `board.config`, kernel fragment, overlays, patches. |
| `sdk/board/common/` | Overlay, users and post-build scripts shared by every board. |
| `external/` | `BR2_EXTERNAL` packages: sway, EmulationStation + RetroArch + cores, gmenu2x, the XFCE and GNOME stacks, gtk4/libadwaita, elogind, SDL3, box64/box86, steam, … |
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
| Allwinner suniv (armv5) | BittBoy 2-3.5, PocketGo, PowKiddy Q90 / V90 / Q20 |

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
