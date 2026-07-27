# Anbernic RG35XX Plus

Allwinner H700 / quad Cortex-A53 handheld. **Definition only** - this board is described in the tree but
not built or verified here.

A real build needs, beyond this board.config:

- A Allwinner H700 / quad Cortex-A53 kernel with this device's device tree (allwinner/sun50i-h700-anbernic-rg35xx-plus) and Mali/panfrost.
- Mali-G31 (panfrost) userspace (mesa panfrost) - selected by the family fragment.
- U-Boot boot support: these devices boot via U-Boot + extlinux from SD/eMMC,
  which this tree does not yet implement (the QEMU boards use a UEFI A/B path).

The shared Allwinner H700 / quad Cortex-A53 options live in `sdk/board/allwinner-h700/`; this board adds only its
device tree name.
