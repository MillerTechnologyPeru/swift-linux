# Cross-compiling Swift for the Swift Linux image

`util/make-swift-sdk.sh` packages a buildroot-swift target sysroot into a
[Swift SDK](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0387-cross-compilation-destinations.md)
artifactbundle, so SwiftPM can build packages for the Swift Linux image from an
x86_64 host:

```sh
swift build --swift-sdk aarch64-unknown-linux-gnu
```

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
`swift sdk install`. The SDK references the sysroot in place (by absolute path),
so it is a local/dev SDK — regenerate it per machine. Pass `--arch x86_64` for
the 64-bit x86 target.

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
