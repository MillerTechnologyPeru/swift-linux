# swift-linux

Lightweight Linux distribution built with Swift.

`swift-linux` provides [Buildroot](https://buildroot.org) configuration fragments
and package definitions for building a small Linux system with the Swift runtime
(and, optionally, application libraries) baked in.

## Layout

| Path | Description |
|------|-------------|
| `sdk/buildroot-version` | Buildroot release the fragments target. |
| `sdk/defconfig/arch/` | Per-architecture fragments (`armv5`, `armv6`, `armv7`, `arm64`, `x86_64`). |
| `sdk/defconfig/toolchain.config` | GNU C toolchain, device management, vendor/hostname. |
| `sdk/defconfig/swift.config` | Swift runtime libraries and their dependencies. |
| `sdk/defconfig/applibs.config` | Application libraries (Wayland, X11, Mesa3D, SDL, Cairo, audio, …). |
| `sdk/defconfig/board/` | Optional per-board overlays (Raspberry Pi, UEFI, Chromebooks, …). |
| `sdk/defconfig/{tools,daemons,supportdata}.config` | Extra fragments you can layer in as needed. |
| `packages/` | Buildroot package definitions for the Swift runtime. |
| `generate-config.sh` | Assembles a defconfig from the fragments above. |
| `util/` | Helper scripts (e.g. running an image under QEMU). |

The configuration is plain text: each `*.config` file is a set of Buildroot
`BR2_...` options. Combine them by hand, or use `generate-config.sh`.

## Generating a defconfig

```sh
# Swift runtime SDK for arm64 -> ./swift_linux_defconfig
./generate-config.sh --arch arm64

# Application SDK (adds applibs.config) for x86_64, custom output path
./generate-config.sh --arch x86_64 --profile app-sdk -o swift_linux_defconfig

# App SDK for arm64 with a Raspberry Pi 4 board overlay
./generate-config.sh --arch arm64 --profile app-sdk --board rpi4
```

Options:

- `--arch <arch>` — required; one of the fragments in `sdk/defconfig/arch/`.
- `--profile <profile>` — `sdk` (default) or `app-sdk`.
- `--board <board>` — optional overlay from `sdk/defconfig/board/`.
- `--output, -o <path>` — output file (default `swift_linux_defconfig`).

Profiles compose the fragments in order:

- `sdk` = arch + toolchain + swift
- `app-sdk` = arch + toolchain + swift + applibs

Run `./generate-config.sh --help` for the full usage.

## Building

Point Buildroot at the generated defconfig and the package definitions in
`packages/`, then build as usual (`make swift_linux_defconfig && make`). See the
[Buildroot manual](https://buildroot.org/downloads/manual/manual.html) for
details on `BR2_EXTERNAL` trees and custom defconfigs.
