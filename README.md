# swift-linux

A small Linux distribution with the Swift runtime built in, and a Swift SDK for
cross-compiling applications to it.

Built with [Buildroot](https://buildroot.org). There is no systemd: busybox
stays pid 1 and hands boot to [OpenRC](https://github.com/OpenRC/openrc)
runlevels (Alpine's model), with `seatd` for seat management and `basu` where
a D-Bus system-bus library is needed.

Images boot into a **frontend** on a read-only [EROFS](https://erofs.docs.kernel.org)
root filesystem with A/B update slots managed by [RAUC](https://rauc.io)
(updates write whole slot images), plus a separate data partition (ext4 on
x86, f2fs on the flash-storage ARM boards) that carries all mutable state. The
default frontend is [EmulationStation](https://github.com/ROCKNIX/emulationstation-next)
on a [sway](https://swaywm.org) session (wlroots, XWayland, Mesa), with
RetroArch and libretro cores behind it; boards can pick another - see
[Frontends](#frontends).

## Quick start

Buildroot and the package trees are submodules, so clone with them:

```sh
git clone --recurse-submodules https://github.com/MillerTechnologyPeru/swift-linux.git
```

Every board and architecture is a make target:

```sh
make list                    # what can be built
make x86_64-build            # build the x86_64 image
make arm64-build             # build the arm64 image
make x86_64-pkg PKG=mesa3d   # rebuild a single package
make x86_64-seed             # fetch a prebuilt toolchain into a fresh tree

util/x86_64-qemu.sh          # boot the result in QEMU with a GTK window
```

Builds run on your host. A fresh checkout has no toolchain, and building gcc,
glibc and host-swift from source takes hours, so seed the output tree once per
architecture from the `toolchain-latest` release (`make <t>-seed`, which needs
`gh` and `zstd`) and keep it. `PARALLEL_BUILD=1 CCACHE=1 make …` speeds the rest
up - pass them in the environment, since `CCACHE` on the make command line would
override Buildroot's own variable of that name. See [docs/build.md](docs/build.md).

### Logging in

The images auto-log the default user into the frontend on tty1, so a device
boots straight into its session and nobody types anything. When you do need
credentials - a serial console, ssh, or `sudo` - they are:

| Account | Password |
|---|---|
| `user` (uid 1000, the session account) | `1234` |
| `root` | `root` |

Both are defaults meant for development images: change them before a device
leaves your desk. The user account is in `video`, `input`, `audio`, `tty`,
`dialout` and `wheel`, which is what lets the compositor reach DRM through
seatd and games read gamepads directly from evdev. Under QEMU the launchers
forward ssh to `localhost:2222`.

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
A single build can override that choice without editing the board:

```sh
./generate-config.sh --arch x86_64 --profile image --frontend minimal
FRONTEND=minimal ./build-images.sh x86_64
```

| Frontend | For | Status |
|---|---|---|
| EmulationStation + sway | GL(ES) gaming devices (default) | working: RetroArch backend, NES/Apps/Games/Tools groups, squashfs app bundles, WiFi/BT/power menus wired to NetworkManager/BlueZ/OpenRC |
| sway + foot (`minimal`) | bring-up: proving a board boots, and short build cycles | working: 34 fewer packages, none of the emulator stack |
| gmenu2x | armv5 / no-GPU handhelds, SDL 1.2 on the framebuffer | definition only |
| XFCE + Chicago95 | desktop use on X.org, Windows 95 look by default | packaged + kconfig-validated, not yet booted |
| GNOME | desktop Wayland (mutter/gnome-shell via elogind on OpenRC) | packaged + kconfig-validated, not yet compiled |
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
| `buildroot/` | Submodule: the [Buildroot](https://github.com/MillerTechnologyPeru/buildroot) fork the images are built from. |
| `swift/` | Submodule: [buildroot-swift](https://github.com/MillerTechnologyPeru/buildroot-swift), the Swift toolchain and runtime packages. |
| `ports/` | Submodule: [buildroot-ports](https://github.com/MillerTechnologyPeru/buildroot-ports) - sway, EmulationStation + RetroArch + cores, gmenu2x, the XFCE and GNOME stacks, gtk4/libadwaita, elogind, SDL3, box64/box86, steam, … |
| `external/` | This distribution's own `BR2_EXTERNAL` packages: the initramfs, board firmware, the kernel filesystem support (`image-storage`), storage/automount and board daemons. |
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
| Rockchip RK3326 / RK3399 / RK3566 / RK3576 / RK3588 | Anbernic RG351·RG353·RG503·RG552, Powkiddy, Odroid Go, Gameforce, MagicX, GameConsole R33S/R36S, GKD Pixel2, … |
| Allwinner H700 | Anbernic RG28XX … RG CubeXX |
| Amlogic S922X | Odroid Go Ultra, Powkiddy RGB10 Max 3 Pro |
| Qualcomm SM6115 / SM8250 / SM8550 / SM8650 / SM8750 | Retroid Pocket, AYN Odin / Thor, Ayaneo Pocket, Mangmi, Konkr Pocket Fit |
| Qualcomm SDM845 | OnePlus 6T / 6, Xiaomi Poco F1, SHIFT6mq |
| Chromebooks (RK3399, MT8183, MT8173, SC7180) | kevin, bob, krane, kodama, hana, lazor, coachz, homestar |
| Apple Silicon t600x | MacBook Pro 14"/16" (M1 Pro / M1 Max) |
| Valve | Steam Deck (LCD, OLED) |
| Allwinner suniv (armv5) | BittBoy 2-3.5, PocketGo, PowKiddy Q90 / V90 / Q20 |

Boot chains differ by family — UEFI/GRUB with A/B slots, U-Boot with extlinux,
Depthcharge kernel partitions, and Android boot images — but they share the same
fragments, kernel-config mechanism and build interface.

An image can install itself onto internal storage: boot it from USB or SD and
run `system-install` (the frontend's "Install to Internal Disk" entry). The
running system is copied partition-for-partition; the install path comes from
the board metadata baked into the image (`/usr/share/boardinfo`, generated by
`util/gen-boardinfo.py`), not from runtime sniffing.

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

Three workflows, split so each red mark means one thing:

- `build-images.yml` — the x86_64 and arm64 disk images with their 32-bit
  companions, plus a fast defconfig-generation check; nightly and on demand
  (a full Buildroot build takes hours, so it does not run per push).
- `build-swift-sdk.yml` — a Swift SDK artifactbundle per architecture
  (x86_64, arm64, armv7, i386) from the app-sdk profile, merged into the
  combined all-architecture bundle, nightly.
- `build-toolchain.yml` — the cross toolchain and expensive host tools from
  source, weekly, published to the `toolchain-latest` release as the seed the
  other builds can start from.

Builds run in per-architecture containers whose cached toolchain and Swift
runtime are reused, so only the remaining packages compile.
