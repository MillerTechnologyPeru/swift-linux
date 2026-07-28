# Valve Steam Deck

LCD ("Jupiter", Van Gogh APU) and OLED ("Galileo", Sephiroth APU). Both are
x86_64 with a Zen 2-class CPU and an RDNA 2 GPU. **Definition only** - described
in the tree but not built or verified on hardware.

## Why this is a separate board

The Deck shares this tree's x86_64 architecture, image profile and UEFI/GRUB
A/B boot path unchanged. What it cannot share is the graphics stack:

| | QEMU x86_64 image | Steam Deck |
|---|---|---|
| GPU driver | virgl (virtio-gpu) | radeonsi (amdgpu) |
| LLVM | avoided deliberately | **required** by radeonsi |
| Vulkan | not enabled | RADV (Proton/DXVK need it) |
| Firmware | none | amdgpu microcode |
| Kernel | virtio drivers | amdgpu, ath11k, cs35l41, hid-steam |

Adding radeonsi to the generic image would force an LLVM build into every
image, including the handhelds that will never use it - so the Deck gets its
own board.config plus a `gpu/radeonsi.config` capability, and the generic image
is untouched.

## Not yet done

- **Not built or verified.** A real bring-up needs the amdgpu firmware present
  before the driver probes, and the vendor kernel tuning that mainline lacks
  (fan curve, display timings) staged in `patches/`.
- **Steam itself is not installed.** The Steam package was removed from the
  image: its bootstrap needs GNU `readlink -e` and `tar -J`, which busybox does
  not provide, so it could never unpack. Fixing that (coreutils + tar + xz) is
  a separate change; this board is about supporting the hardware.
- Gamescope, the Deck's session compositor, is not packaged; the image runs the
  same sway session as the other boards.
