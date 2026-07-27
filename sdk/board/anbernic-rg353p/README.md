# Anbernic RG353P

Rockchip RK3566 / quad Cortex-A55 handheld. **Definition only** - this board is described in the tree but
not built or verified here.

A real build needs, beyond this board.config:

- A Rockchip RK3566 / quad Cortex-A55 kernel with this device's device tree (rockchip/rk3566-anbernic-rg353p) and Mali/panfrost.
- Mali-G52 (panfrost) userspace (mesa panfrost) - selected by the family fragment.
- U-Boot boot support: these devices boot via U-Boot + extlinux from SD/eMMC,
  which this tree does not yet implement (the QEMU boards use a UEFI A/B path).

The shared Rockchip RK3566 / quad Cortex-A55 options live in `sdk/board/rockchip-rk3566/`; this board adds only its
device tree name.
