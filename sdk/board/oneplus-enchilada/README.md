# OnePlus 6

Qualcomm SDM845 phone with an Adreno 630 (freedreno/turnip). **Definition
only** - not built or verified here. The device tree (qcom/sdm845-oneplus-enchilada) is in the mainline
kernel. Sibling of the 6T (fajita) with the same board.

Boot: unlock the bootloader, then `fastboot flash boot boot.img` and flash
the rootfs to userdata. These phones use Android A/B slots (boot_a/boot_b);
slot fallback is handled by the firmware. Real bring-up additionally needs the
device firmware blobs (WiFi/GPU/modem/venus) in /lib/firmware.
