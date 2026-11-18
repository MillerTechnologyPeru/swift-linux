# Game Console R36S

Rockchip RK3326 / quad Cortex-A35 handheld with a Mali-G31 (panfrost) GPU, a
640x480 MIPI-DSI panel and analog sticks read through a single multiplexed ADC.
Shared Rockchip RK3326 options live in `sdk/board/rockchip-rk3326/`.

## Status

**Not yet booted.** The kernel side is resynced from ROCKNIX, which supports
this device, and checked to build (see
`sdk/board/rockchip-rk3326/patches/README.md`):

- Linux 7.1.2 with ROCKNIX's RK3326 patch set, kernel config and device trees,
  including `rk3326-gameconsole-r36s.dts`.
- `rocknix-joypad`, the out-of-tree module that provides
  `rocknix-singleadc-joypad`, which this device tree binds for the controls.

Still missing before an image can boot:

- **Bootloader.** ROCKNIX boots RK3326 with mainline U-Boot v2025.10 plus its
  own `rk3326-handheld_defconfig` and device tree sources, Rockchip's rkbin
  miniloader/DDR/BL31 blobs, and a helper that assembles the idbloader. None
  of that is ported yet; the `rk3326-handheld` defconfig named in
  `board.config` does not exist in mainline U-Boot.
- **Panel variants.** R36S units ship with several different panels, and many
  "R36S" units are clones. ROCKNIX picks the right timings at boot with its
  `generic-dsi` and `device-switch` packages; without an equivalent, this
  device tree's panel (`gameconsole,r36s-panel`, ST7703) only lights the units
  that have that panel.
