# Apple iBook G4 (PowerBook6,7)

PowerPC G4 (7447A) with AltiVec, Mobility Radeon 9550 (M12, r300 family),
AirPort Extreme (BCM4318, b43), gmac Ethernet (sungem), Kauai ATA, an ADB
keyboard and a USB trackpad on the PMU, and a TAS3004 codec on I2S
(snd-aoa). Not yet verified on hardware.

The QEMU mac99 board's image (`sdk/board/ppc`), without Perry, made to boot
from a USB stick through Open Firmware:

- an Apple partition map, since Open Firmware cannot read GPT;
- an HFS boot partition (2) holding `zImage.pmac`, an ELF Open Firmware
  loads, and `ofboot.b`, the CHRP boot script it runs, typed `tbxi` in the
  blessed folder;
- the EROFS root (3), which the boot script passes as `/dev/sdb3`: the
  internal disk is `/dev/sda`, and an Apple partition map has no UUIDs.

Write the image to a stick, then hold Option at power-on and pick it, or
enter Open Firmware (Cmd-Option-O-F) and type:

    boot ud:2,\\:tbxi

Graphics composite with pixman for now: Mesa's r300 driver for the Radeon
is not built yet. There is no data partition, so nothing persists across
boots.
