# Cross-compiling Swift for the Swift Linux image

`util/make-swift-sdk.sh` packages a buildroot-swift target sysroot into a
[Swift SDK](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0387-cross-compilation-destinations.md)
artifactbundle, so SwiftPM can build packages for the Swift Linux image from an
x86_64 host:

```sh
swift build --swift-sdk aarch64-unknown-linux-gnu
```

The SDK sysroot is built from the **app-sdk profile**, so every architecture's
bundle carries the same libraries *and headers*: the Swift runtime plus the
graphics/app stack - libGL/EGL/GLES (with `gl.pc`/`glx.pc`), SDL2/SDL3,
wayland, X11, cairo, ALSA - which is what lets both SwiftPM and the generated
CMake toolchain link real applications.

## Prerequisites

- A built target toolchain: run `build-images.sh` for the arch so
  `buildroot-swift/output/<arch>/host/<triple>/sysroot` exists.
- A host Swift toolchain **matching the sysroot's Swift version**. Swift binary
  `.swiftmodule` files are locked to the compiler version that produced them, so
  the host `swiftc` must be the same version. The script prints the version;
  install it with [swiftly](https://www.swift.org/swiftly/):

  ```sh
  swiftly install 6.0.3
  ```

## Generate and install the SDK

```sh
util/make-swift-sdk.sh --arch arm64 --install
```

This writes `swift-linux-arm64.artifactbundle` and registers it with
`swift sdk install`. Four arches are supported: `arm64` and `x86_64` (the image
targets) plus `armv7` and `i386` (the 32-bit companions, built from the app-sdk
profile). The target triple is read from the sysroot, so it is always correct.

### Local vs portable

By default the SDK references the buildroot sysroot **in place** by absolute
path — small and instant, but it only works on the machine that has the
buildroot checkout.

Add `--portable` for a **self-contained** bundle: the sysroot and the cross-gcc
are copied into the bundle (folded under the target triple so clang finds the
crt objects, `libgcc` and `libstdc++` from `--sysroot` alone), and every path is
relative. The result (~450 MB) can be archived and `swift sdk install`ed on any
x86_64 host — no buildroot checkout required:

```sh
util/make-swift-sdk.sh --arch arm64 --portable --out swift-linux-arm64.artifactbundle
tar czf swift-linux-arm64.artifactbundle.tar.gz swift-linux-arm64.artifactbundle
# on another host:
swift sdk install swift-linux-arm64.artifactbundle.tar.gz
```

Either way the host toolchain still has to match the sysroot's Swift version.

The portable bundle carries a **compilation-only sysroot**: runtime trees
(`usr/bin`, `var`, ...) and `usr/share` are stripped, keeping the build-relevant
`usr/share/{pkgconfig,wayland*,cmake}`. Besides size, this matters on macOS:
ncurses' terminfo database and the iptables plugin directory contain filenames
differing only by case, which cannot coexist on the default case-insensitive
APFS — the stripped bundle installs cleanly on Macs. (The kernel's netfilter
UAPI headers still case-collide; they extract as a single file there and only
matter when building iptables extensions.)

### Cross-compiling C/C++ (CMake)

`util/make-cmake-toolchain.sh` generates a CMake toolchain file that drives
clang/clang++ (from the Swift toolchain or PATH) with `--target`/`--sysroot`
against the same SDK sysroot, with lld linking and pkg-config pinned to the
sysroot — so CMake projects (SDL games, native libraries) build for the image:

```sh
util/make-cmake-toolchain.sh --sdk swift-linux-arm64 -o arm64.toolchain.cmake
cmake -B build -DCMAKE_TOOLCHAIN_FILE=arm64.toolchain.cmake
cmake --build build
```

It reads the triple and sysroot from the installed bundle's `swift-sdk.json`
(`--triple` selects within a multi-arch bundle; `--sysroot DIR --triple T`
works without a bundle).

### All-arch combined SDK

`util/combine-swift-sdk.sh` merges several per-arch **portable** bundles into a
single artifactbundle that cross-compiles for every architecture, so one
`swift sdk install` covers both targets:

```sh
util/make-swift-sdk.sh --arch arm64  --portable --out parts/swift-linux-arm64.artifactbundle
util/make-swift-sdk.sh --arch x86_64 --portable --out parts/swift-linux-x86_64.artifactbundle
util/combine-swift-sdk.sh parts/*.artifactbundle --out swift-linux.artifactbundle

swift sdk install swift-linux.artifactbundle
swift build --swift-sdk aarch64-unknown-linux-gnu   # or x86_64-unknown-linux-gnu
```

CI builds this automatically: `build-swift-sdk.yml` builds a bundle per
architecture (x86_64, arm64, armv7, i386) from the app-sdk profile and merges
them into a `swift-linux-swift-sdk` artifact.

## Build a package

```sh
git clone https://github.com/PureSwift/AppRuntime
cd AppRuntime
swiftly run +6.0.3 swift build --swift-sdk aarch64-unknown-linux-gnu
```

The result is an aarch64 ELF (`interpreter /lib/ld-linux-aarch64.so.1`) that runs
on the Swift Linux arm64 image. Products link the Swift runtime from
`/usr/lib/swift/linux`, which the image ships.

### Verifying with qemu-user

```sh
SR=../buildroot-swift/output/arm64/host/aarch64-swift-linux-gnu/sysroot
qemu-aarch64 -L "$SR" \
  -E LD_LIBRARY_PATH="$SR/usr/lib/swift/linux" \
  .build/aarch64-unknown-linux-gnu/debug/<executable>
```
