# Powkiddy RGB30

Rockchip RK3566 / quad Cortex-A55 handheld. **Definition only** - this board is described in the tree but
not built or verified here.

A real build needs, beyond this board.config:

- A Rockchip RK3566 / quad Cortex-A55 kernel with this device's device tree (rockchip/rk3566-powkiddy-rgb30) and Mali/panfrost.
- Mali-G52 (panfrost) userspace (mesa panfrost) - selected by the family fragment.
- Verifying the boot chain: U-Boot + ATF + an SD-card image (U-Boot + extlinux)
  are scaffolded in the SoC-family dir but not build-verified (the QEMU boards use a UEFI A/B path instead).

The shared Rockchip RK3566 / quad Cortex-A55 options live in `sdk/board/rockchip-rk3566/`; this board adds only its
device tree name.
