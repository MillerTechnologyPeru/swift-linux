# Plan: swift-linux on PowerPC (QEMU mac99)

## Goal

A third boot-tested image target, `ppc`: 32-bit big-endian PowerPC, booting in `qemu-system-ppc -M mac99` to sway and foot, composited in software, with the Swift runtime, and a `powerpc-unknown-linux-gnu` Swift SDK beside the existing four.

Exit test: `make ppc-build FRONTEND=minimal && util/boot-verify.sh --arch ppc` passes, and a SwiftPM package built with `--swift-sdk powerpc-unknown-linux-gnu` runs in the guest.

Not yet: the EmulationStation frontend (it needs a GPU; see the roadmap's Phase 2), the G3 (the image needs AltiVec, so `-cpu g4` only), real Power Macs (the image should be close, but nothing here is tested on one), ppc64, a 32-bit companion, GL acceleration.

## What the tree gives, and what it does not

Read from this repo at `33151fd`, the Buildroot fork at `00755d3`, ports at `27b9b62` and buildroot-swift at `21532fe`.

| Area | State for `BR2_powerpc` |
|---|---|
| Fragments and profiles | Arch-neutral. A new arch is `sdk/defconfig/arch/ppc.config` plus `sdk/board/ppc/`. |
| Swift runtime | buildroot-swift has `swift_ppc_defconfig` and the LLVM patch. Built in its experimental CI only, never run. `swift.mk` hard-codes `-mcpu=7400`, which is the CPU this target uses. |
| Host Swift | The shared `host-swift-6.4.2` on the runner is the released toolchain, unpacked: its sources carry the 32-bit PowerPC `swiftcall` patch, but its binaries were never built from them, and its clang warns "'swiftcall' calling convention is not supported for this target" for `powerpc-unknown-linux-gnu` and drops the attribute. Its swiftc does emit ppc32 objects. The runtime needs a host-swift compiled from source (`build-toolchain.yml` with `from_source`) before spike 1 means anything. |
| Boot | `boot/uefi-ab.config` does not apply: mac99's firmware is OpenBIOS (Open Firmware). The fork's GRUB has no `powerpc-ieee1275` target (`BR2_TARGET_GRUB2_ARCH_SUPPORTS` lists x86, arm, aarch64, riscv64, loongarch64). |
| GPU | `gpu/virgl.config` is the image default. Buildroot's LLVM does not support powerpc, so there is no llvmpipe; softpipe builds. virgl in a big-endian guest is unproven. |
| Compositor | wlroots needs EGL, GLES and GBM to build. At run time it can use its pixman renderer, as the Apple t600x boards already do. |
| Dropped by Kconfig | podman and crun (Go has no ppc32 port), target QEMU, box64, box86, wine, LLVM. These vanish silently; the defconfig check must confirm nothing still selects them. |
| Still offered | OpenJDK (zero VM), mono, LuaJIT, Rust packages (glibc only). |
| Scripts with arch lists | `Makefile` (`IMAGE_ARCHES`, `seed_arch`), `generate-config.sh` (messages), `util/gen-boardinfo.py` (`BOOTFW`, `ARCH`), `util/make-swift-sdk.sh`, `util/boot-verify.sh`, the three workflows. |

## Decisions

1. **CPU baseline is the 7400 (G4), with AltiVec.** It matches what buildroot-swift already builds, and AltiVec is worth having in pixman, the codecs and the kernel on real hardware. The image does not run under `-cpu g3`. A G3 build is a later, separate target (`BR2_powerpc_750`), and needs buildroot-swift to take the CPU from Buildroot instead of hard-coding it.
2. **Frontend is `minimal`: sway and foot, with no GL at run time.** sway composites with wlroots' pixman renderer (`WLR_RENDERER=pixman`), as the Apple t600x boards already do, and foot draws on the CPU into shared memory. Mesa is built with softpipe only because wlroots needs EGL, GLES and GBM to link; nothing uses it, and no LLVM is needed. EmulationStation waits for a board with a working GPU.
3. **Boot in two steps.** First QEMU's `-kernel`, which needs no firmware support at all. Then OpenBIOS loading GRUB (`powerpc-ieee1275`) from a small ext2 boot partition, with the same `grub.cfg` slot logic and RAUC `bootloader=grub` as the UEFI boards.
4. **MBR partition table**, four primaries: boot, root-a, root-b, data. OpenBIOS reads Mac and PC partition maps, not GPT. `PARTUUID`s become `<disk-signature>-<n>`; the board's `grub.cfg` and `system.conf` are its own, so nothing shared changes.
5. **The disk is IDE** (`pata-macio`, `/dev/sda`) so the firmware and the kernel see the same device; network is the machine's `sungem`. virtio-blk and virtio-net are enabled in the kernel for later.
6. **`time_t` stays as armv7 and i386 have it** (no `BR2_TIME_BITS_64`), so the Swift runtime and the C libraries agree. Revisit for all 32-bit targets together.

## Phase 0: spikes (no commits)

1. **Swift runs.** Build buildroot-swift's `swift_ppc_defconfig` with `swift-hello`, run it under `qemu-ppc-static -L target`. Add Foundation and a `Task`. Check `nm -D --undefined-only libswiftCore.so | grep hf` for the Float16 helpers that ppc64le needed a patch for.
2. **Firmware path.** With a GRUB built elsewhere (`grub-mkimage -O powerpc-ieee1275`), confirm OpenBIOS loads `core.elf` from ext2 on an MBR disk (`-prom-env 'boot-device=hd:1,\boot\grub\core.elf'`), that GRUB then reads an uncompressed EROFS slot, and that `grubenv` on ext2 is writable from Linux.
3. **Display.** In any ppc Linux guest on mac99 (Debian sid works), run sway with `WLR_RENDERER=pixman` on the default VGA device (`bochs-drm`) and on `-device virtio-gpu-pci`. Note which gives correct colors; big-endian framebuffer formats are the risk.
4. **Config.** Generate the image defconfig for ppc, run `olddefconfig`, diff. Every symbol that disappeared is either expected (table above) or a package to gate.
5. **Kernel.** Confirm `pmac32_defconfig` on the current kernel boots mac99 to a serial console on `ttyPZ0`, and whether the image is `vmlinux` or `zImage.pmac` for each boot path.

## Phase 1: Swift on ppc (buildroot-swift)

One file per commit.

| # | File | Commit message |
|---|---|---|
| 1 | `package/swift/0002-Provide-Float16-helpers-on-powerpc64le.patch` | Provide the Float16 helpers on 32-bit PowerPC too (only if spike 1 shows them undefined) |
| 2 | `.github/workflows/buildroot-experimental.yml` | Build and run swift-hello for the experimental architectures |

## Phase 2: GRUB for Open Firmware (buildroot fork)

| # | File | Commit message |
|---|---|---|
| 3 | `boot/grub2/Config.in` | Add the powerpc-ieee1275 GRUB target |
| 4 | `boot/grub2/grub2.mk` | Build and install GRUB's core.elf for powerpc-ieee1275 |

## Phase 3: sysroot and SDK (swift-linux)

| # | File | Commit message |
|---|---|---|
| 5 | `sdk/defconfig/arch/ppc.config` (new) | Add the 32-bit PowerPC architecture fragment |
| 6 | `sdk/defconfig/arch/ppc-override.config` (new) | Withdraw OpenJDK and mono on ppc until they are built there |
| 7 | `generate-config.sh` | List ppc among the architectures and image targets |
| 8 | `util/make-swift-sdk.sh` | Package a powerpc-unknown-linux-gnu Swift SDK |
| 9 | `util/combine-swift-sdk.sh` | Include powerpc in the combined SDK |
| 10 | `util/make-cmake-toolchain.sh` | Emit a CMake toolchain for ppc |
| 11 | `swift` (submodule) | Bump buildroot-swift for the ppc runtime checks |

Checkpoint: `./generate-config.sh --arch ppc --profile app-sdk` builds, and a SwiftPM executable built against the SDK runs under `qemu-ppc-static`.

## Phase 4: the board, booted by `-kernel`

| # | File | Commit message |
|---|---|---|
| 12 | `sdk/defconfig/gpu/softpipe.config` (new) | Add a software GPU capability for targets without LLVM |
| 13 | `sdk/board/ppc/board.config` (new) | Add the QEMU mac99 board |
| 14 | `sdk/board/ppc/linux.fragment` (new) | Build in the mac99 and virtio drivers the image boots from |
| 15 | `sdk/board/ppc/genimage.cfg` (new) | Lay out the ppc disk as MBR with A/B slots |
| 16 | `sdk/board/ppc/post-build.sh` (new) | Add the ppc post-build step |
| 17 | `sdk/board/ppc/post-image.sh` (new) | Assemble the ppc disk image |
| 18 | `sdk/board/ppc/rootfs-overlay/etc/profile.d/00-renderer.sh` (new) | Composite with pixman on ppc |
| 19 | `util/gen-boardinfo.py` | Describe ppc boards and Open Firmware boot |
| 20 | `sdk/board/ppc/boardinfo` (new, generated) | Record the ppc board's metadata |
| 21 | `Makefile` | Make ppc an image target with its own seed |
| 22 | `util/ppc-qemu.sh` (new) | Add a QEMU launcher for the ppc image |

`board.config`: `pmac32` kernel defconfig, getty on `ttyPZ0`, `include sdk/defconfig/gpu/softpipe.config` (which negates virgl and the virtio Vulkan driver), `include sdk/defconfig/frontend/minimal.config`, no `uefi-ab.config`.

`linux.fragment`, all built in since there is no initramfs: `ALTIVEC`, `PATA_MACIO`, `SUNGEM`, `SERIAL_PMACZILOG` and its console, `ADB_PMU`, `USB_OHCI_HCD`, `USB_HID`, `DRM_BOCHS`, `DRM_VIRTIO_GPU`, `DRM_FBDEV_EMULATION`, `VIRTIO_PCI`, `VIRTIO_BLK`, `VIRTIO_NET`, `INPUT_EVDEV`, `EXT4_FS`, `BINFMT_MISC`.

`ppc-qemu.sh`, first form:

    qemu-system-ppc -M mac99,via=pmu -cpu "${CPU:-g4}" -m 2048 \
        -kernel images/vmlinux \
        -append "root=/dev/sda2 ro rootwait rauc.slot=A console=tty0 console=ttyPZ0" \
        -drive file=disk.img,format=raw,if=ide \
        -netdev user,id=n0,hostfwd=tcp::2222-:22 -device sungem,netdev=n0 \
        -device usb-tablet -serial mon:stdio

mac99 takes one CPU and at most 2 GB. There is no KVM on an x86 or arm host, so everything runs under TCG.

Checkpoint: serial login, ssh on 2222, the data partition mounted, then sway and foot on the display.

## Phase 5: firmware boot and A/B

| # | File | Commit message |
|---|---|---|
| 23 | `sdk/defconfig/boot/ieee1275-ab.config` (new) | Add the Open Firmware GRUB boot capability with A/B slots |
| 24 | `sdk/board/ppc/grub.cfg` (new) | Pick the ppc slot from grubenv |
| 25 | `sdk/board/ppc/rootfs-overlay/etc/rauc/system.conf` (new) | Configure RAUC for the ppc slots |
| 26 | `sdk/board/ppc/board.config` | Boot the ppc board through GRUB |
| 27 | `sdk/board/ppc/genimage.cfg` | Put GRUB and grubenv on the ppc boot partition |
| 28 | `util/ppc-qemu.sh` | Boot the ppc image through OpenBIOS by default |
| 29 | `buildroot` (submodule) | Bump Buildroot for the powerpc-ieee1275 GRUB target |

Like `uefi-ab.config`, the new boot fragment turns EROFS compression off, because GRUB reads the kernel from inside the slot. `KERNEL=1 util/ppc-qemu.sh` keeps the direct boot for bisecting firmware problems.

Checkpoint: boot slot A, `rauc install` a bundle, reboot into B, mark good, and fall back when B is marked bad.

## Phase 6: verification, CI, documents

| # | File | Commit message |
|---|---|---|
| 30 | `util/boot-verify.sh` | Verify ppc boots: software compositor, QEMU screendump, longer timeout |
| 31 | `.github/workflows/build-toolchain.yml` | Publish a ppc toolchain seed |
| 32 | `.github/workflows/build-swift-sdk.yml` | Build the ppc Swift SDK |
| 33 | `.github/workflows/build-images.yml` | Build the ppc image on demand |
| 34 | `sdk/board/ppc/README.md` (new) | Describe the ppc board and its open questions |
| 35 | `docs/build.md` | Document the ppc target |
| 36 | `docs/swift-sdk.md` | Document the ppc SDK |
| 37 | `README.md` | List ppc among the boot-tested targets |

On ppc, `boot-verify.sh` must not fail on a software renderer: its GL check becomes "the compositor answers `swaymsg`". With no GL scanout, QEMU's own `screendump` works, so grim is optional. The image job is manual, not nightly, until its duration under ccache is known; ppc has no companion, so the `lib32` matrix is untouched.

## Rules for the commits

- One file per commit, in the order above, across the three repositories; each submodule bump is its own commit.
- Every commit leaves `x86_64` and `arm64` defconfig generation byte-identical, checked by the existing config job.
- Messages are one imperative line in the repository's style. No tool or assistant is named in messages, code or comments, and there are no co-author trailers.
- Rows that depend on a spike are dropped, not stubbed, if the spike says they are unnecessary.

## Risks, largest first

1. Swift 6.4.2 has not been run on ppc32 (Phase 0.1). Earlier releases ran under `qemu-ppc-static`, so this is a regression check, but nothing in CI makes it yet.
2. OpenBIOS may not load GRUB the way decision 3 assumes. The fallback keeps `-kernel` for QEMU and uses an Apple partition map with an HFS bootstrap partition for firmware boot, which costs a new genimage layout.
3. Big-endian display formats through wlroots and pixman (Phase 0.3). The fallback is gmenu2x on the framebuffer.
4. Speed. Under TCG the full image profile will be slow to boot, and a from-source build adds a fifth toolchain to the weekly job.
5. Packages that have never been built big-endian. Expect a tail of fixes in ports; each is its own commit in that repository.
