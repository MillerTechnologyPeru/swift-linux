# Apple MacBook Pro 16" (2021)

M1 Pro (t6000) MacBook Pro. **Definition only** - not built or verified here.

What works without Rust kernel support (deferred): display via the DCP driver
(compositor on the pixman software renderer), keyboard/trackpad (SPI-HID),
NVMe, Wi-Fi/BT (with extracted firmware), battery/SMC, headphone audio. GPU
acceleration, speakers (safety daemon), and suspend are follow-ups.

No 32-bit support on this hardware: the cores are AArch64-only (no armv7
userland, no box86) and 16K pages break 4K-assuming x86 translation, so
Steam/box64 are disabled for this family.

Install flow: the platform installer creates the stub container + ESP + root
partition; this tree provides the rootfs and the standard GRUB arm64-efi
payload. Device firmware (Wi-Fi/BT) is extracted from the machine's macOS
stub to the ESP and must reach /lib/firmware/vendor early (early-initrd) -
not yet wired here.
