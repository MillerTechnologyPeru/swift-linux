# Game Console R36S / R35S

Rockchip RK3326 / quad Cortex-A35 handheld with a Mali-G31 (panfrost) GPU, a
640x480 MIPI-DSI panel and analog sticks read through a single multiplexed ADC.
The R35S is the same board in a different shell: the device tree lists
`gameconsole,r35s` alongside `gameconsole,r36s`, so one image serves both.
Shared Rockchip RK3326 options live in `sdk/board/rockchip-rk3326/`.

## Building

```sh
./generate-config.sh --device gameconsole-r36s --profile image   # EmulationStation
./generate-config.sh --device gameconsole-r36s --profile image --frontend minimal
```

or the Build Images workflow with `device: gameconsole-r36s`. The result is
`images/disk.img`; write it to a microSD card with `dd` or a flashing tool and
boot from the system card slot (TF1).

## Status

**Not yet booted.** Kernel and bootloader follow upstream, which supports this
device, and are checked to build (see
`sdk/board/rockchip-rk3326/patches/README.md`):

- Linux 7.1.2 with upstream's RK3326 patch set, kernel config and device
  trees, including `rk3326-gameconsole-r36s.dts`.
- The joypad input driver package, which provides the single-ADC driver this
  device tree binds for the controls.
- U-Boot v2025.10 with upstream's `rk3326-handheld` defconfig, packed with
  Rockchip's DDR init, miniloader and BL31 at sector 64 of the card, booting
  `extlinux.conf` from the FAT boot partition.

Debug serial is UART2 at 1,500,000 baud (`console=ttyS2`), as in the device
tree's `stdout-path`.

Known gap:

- **Panel variants.** R36S units ship with several different panels, and many
  "R36S" units are clones. Upstream picks the right timings at boot with a
  device-tree overlay chosen per panel; without an equivalent, this image
  drives only the panel in this device tree (`gameconsole,r36s-panel`,
  ST7703), and a unit with another panel boots with a dark screen.
