# Powkiddy X55

Rockchip RK3566 / quad Cortex-A55 handheld with a Mali-G52 (panfrost) GPU, a
5.5" 1280x720 MIPI-DSI panel and two analog sticks. Its device tree,
`rk3566-powkiddy-x55`, is in mainline Linux. Shared Rockchip RK3566 options
live in `sdk/board/rockchip-rk3566/`.

## Building

```sh
./generate-config.sh --device powkiddy-x55 --profile image   # EmulationStation
./generate-config.sh --device powkiddy-x55 --profile image --frontend minimal
```

or the Build Images workflow with `device: powkiddy-x55`. The result is
`images/disk.img`; write it to a microSD card with `dd` or a flashing tool and
boot from the card slot - the U-Boot here tries the SD card before the eMMC.

## Status

**Not yet booted.** Kernel and bootloader follow upstream, which supports this
device (see `sdk/board/rockchip-rk3566/patches/README.md`):

- Linux 7.2.11 with upstream's RK3566 patch sets and kernel config; the
  device tree is mainline's.
- Mainline U-Boot v2026.01 as upstream builds it for the X55 (the Quartz64-A
  configuration, no board code at boot), with TF-A BL31 at upstream's commit,
  packed with Rockchip's DDR init at sector 64 of the card, booting
  `extlinux.conf` from the FAT boot partition.

Debug serial is UART2 at 1,500,000 baud (`console=ttyS2`).

What only the device can confirm: the panel, the audio amplifier and Wi-Fi
with upstream's patches, and the controls.

Known risk - **the controls are two input devices.** Mainline's device tree
describes the sticks as an `adc-joystick` node and the buttons and d-pad as a
separate `gpio-keys-control` node, so the kernel registers two input devices,
and EmulationStation and RetroArch may treat them as two controllers. Neither
has a dedicated profile here (the RetroArch profiles upstream ships are for
its single-device joypad driver). Whether that needs a merged device - a
small evdev-merging service, say - is the first thing to check on hardware.
