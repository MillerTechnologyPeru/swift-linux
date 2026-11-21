# Roadmap: retro PowerPC Mac apps on swift-linux

Three phases across four repositories. The detail, and the one-file-per-commit lists, are in two plans this page orders:

- `docs/powerpc-qemu.md` (this repo): the `ppc` image target. Commits S1 to S37 below.
- `Documentation/Plans/powerpc.md` (Perry): the PowerPC port. Commits P1 to P89 below.

## Phase 1: proof of concept in QEMU

**Shows:** `qemu-system-ppc -M mac99 -cpu g4` boots swift-linux to sway and foot, composited in software, and `perry32` run from the terminal opens a PowerPC Cocoa app's window.

**The app**, either of:

- `legacy_window.m` built for ppc: a window, a delegate, `-drawRect:`. Needs a compiler that still emits Darwin ppc (the Perry plan's spike 0.3).
- A universal (ppc + i386) Cocoa app whose i386 slice Perry runs today. Same bundle, same nibs, same resources; only the slice changes, so any failure is the port's and not the app's. This needs no fixture toolchain. None of the three macOS entries in Perry's compatibility database is a candidate (2008 to 2011 Intel-only games), so pick one first: a small nib-based utility from the 10.4 to 10.5 years, checked with `lipo -info`, and confirmed on i386 Perry before any ppc work.

Do both. The universal app is the demonstration; the fixture is what CI can keep.

**Order of work**

| Step | What | Commits |
|---|---|---|
| 1 | Swift 6.4.2 runs on ppc32 under `qemu-ppc-static`: hello, Foundation, a `Task`. Earlier releases did; this confirms the current one and puts it in CI. | S1, S2 |
| 2 | The `ppc` sysroot and Swift SDK. | S5 to S11 |
| 3 | Perry's loader and libSystem against that sysroot, tested under `qemu-ppc`. | P1 to P31 |
| 4 | Perry's Objective-C runtime, Foundation and AppKit; the byte-order pass. | P32 to P56 |
| 5 | The image, booted with `-kernel`, to a serial login and then sway and foot. | S12 to S22 |
| 6 | Perry packaged into the image, run from foot. | new, below |
| 7 | `boot-verify.sh --arch ppc`, extended to launch the app and check its output. | S30 |

Steps 3 and 4 do not wait for step 5: Perry is developed under user-mode `qemu-ppc` against the SDK, which is far faster than the full machine.

Left for later, because the proof does not need them: GRUB and A/B slots through OpenBIOS (S3, S4, S23 to S29), the CI and document commits, EmulationStation, Carbon, OpenGL, CFM.

**New work this phase adds to the plans** (step 6), files to be named when the ports tree is read for it:

- A Buildroot package for Perry on ppc in the ports tree, built from the same scripts the Perry plan adds (`build-ppc-loader.sh`, `build-ppc-system.sh`, `build-ppc-swiftpm.sh`).
- `vm.mmap_min_addr=4096` set at boot, since ppc Mac executables load at 0x1000.

**Risks particular to this phase**

- Nothing on screen uses GL: sway composites with pixman, foot draws on the CPU, and Perry's AppKit draws through SDL, which must be held to its software renderer and shared-memory presentation. If SDL picks a GL renderer it lands on softpipe and crawls.
- Big-endian pixel formats between wlroots, pixman and the emulated display are untested. The spike in the image plan runs sway on both `bochs-drm` and `virtio-gpu-pci` first.
- The universal app must be chosen before step 3, not after: it decides which AppKit classes the port has to get right first.

## Phase 2: real hardware

**Shows:** the same image boots on an iBook G4 from its own disk, with accelerated OpenGL, WiFi, and EmulationStation as the frontend, with an entry that launches Mac apps through `perry32`.

A new board, `sdk/board/ibook-g4/`, reusing the `ppc` arch fragment and the 7400 baseline. None of this can be tested in QEMU, so it starts when the machine is on the desk.

| Area | What it takes | Unknowns |
|---|---|---|
| Boot | Apple's Open Firmware, not OpenBIOS. The known-good layout is an Apple partition map with a small HFS bootstrap partition holding GRUB (`powerpc-ieee1275`), blessed. That is a new genimage layout or a post-image step with hfsutils; the MBR layout from Phase 1 is for QEMU only. | Whether this firmware will also load GRUB from a USB stick, which would make first boots much easier. |
| Kernel | `pmac32` plus: `ADB_PMU` (keyboard, trackpad), `PMAC_BACKLIGHT`, `SND_AOA` or `SND_POWERMAC`, PMU battery and sleep, CPU frequency scaling, the thermal driver, `USB_EHCI_HCD`, `SUNGEM`. | Sleep and resume are historically fragile on these machines. |
| GPU, 2005 models (Mobility Radeon 9550) | Mesa `r300` (its Kconfig is gated to x86 in the Buildroot fork and needs `BR2_powerpc`), kernel `DRM_RADEON` with `FB_RADEON` off, `AGP_UNINORTH`, radeon microcode from linux-firmware, and `radeon.agpmode=-1` if AGP is unstable. A new `gpu/r300.config`. sway moves from pixman to its GLES2 renderer, and the frontend from `minimal` to EmulationStation. | Big-endian `r300` has regressed in several Mesa releases; pin a version known to work. |
| GPU, 2003 to 2004 models (Mobility Radeon 9200) | No GLES2 and no driver in current Mesa. Compositor stays on pixman; EmulationStation has nothing to draw with; these stay on sway and foot, or gmenu2x. | Whether this model is worth supporting at all. |
| WiFi | The AirPort Extreme card is a Broadcom chip driven by `b43` (`B43`, `SSB`). Its firmware is not in linux-firmware and cannot be redistributed: it is cut from Broadcom's driver with `b43-fwcutter`, at build time on the builder's machine or on the device over Ethernet. NetworkManager and the frontend's WiFi menu then work unchanged. | Which chip revision the machine has (`lspci`), and whether it negotiates current WPA modes. |
| Install | `system-install` reads `/usr/share/boardinfo`; it needs an Open Firmware case for partitioning and blessing. | |

Order: boot from the serial-less console to a shell first (the iBook has no serial port, so a framebuffer console and SSH over Ethernet are the debugging tools), then input and backlight, then GPU, then WiFi, then sound and power.

## Phase 3: the apps

With Cocoa running on real hardware, the remaining Perry phases, in the order the apps you want need them:

| Step | What | Commits |
|---|---|---|
| 1 | Carbon in Mach-O programs. Adds Carbon's first tests, on i386 as well. | P57 to P67 |
| 2 | OpenGL and AGL, on `r300`. | P68 to P74 |
| 3 | Carbon in CFM programs: the PEF loader and transition vectors. | P75 to P84 |
| 4 | GRUB with A/B slots, CI, documents, for both repos. | S3, S4, S23 to S29, S31 to S37; P85 to P89 |

## Rules

As in both plans: one file per commit, each repository's existing targets keep building and passing at every commit, messages are one imperative line in the repository's style, and no tool or assistant is named in messages, code or comments.
