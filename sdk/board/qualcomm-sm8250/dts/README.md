# Out-of-tree device trees (Qualcomm SM8250 / Snapdragon 865 (Adreno 650))

None of these devices' DTS are in mainline. The directory is copied over
`arch/arm64/boot/dts/` via BR2_LINUX_KERNEL_CUSTOM_DTS_DIR, keeping the `qcom/`
vendor subdirectory the kernel's device tree makefiles expect, and every .dts
here is compiled. A board still names the one it boots in its own
`board.config`:

    BR2_LINUX_KERNEL_INTREE_DTS_NAME="qcom/sm8250-retroidpocket-rp5"

`sm8250-retroidpocket-common.dtsi` is shared by the four Retroid devices and is
not built on its own.

| Device tree | Board |
|---|---|
| `sm8250-retroidpocket-rp5.dts` | retroid-pocket-5 |
| `sm8250-retroidpocket-flip2.dts` | retroid-pocket-flip2 |
| `sm8250-retroidpocket-rpmini.dts` | retroid-pocket-mini |
| `sm8250-retroidpocket-rpminiv2.dts` | retroid-pocket-mini-v2 |
| `sm8250-mangmi-pocket-max.dts` | mangmi-pocket-max |
| `sm8250-ayn-thorlite.dts` | ayn-thorlite |

Provenance and resync: see ../patches/README.md.
