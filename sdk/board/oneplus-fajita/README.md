# OnePlus 6T

Qualcomm SDM845 phone with an Adreno 630 (freedreno/turnip). **Definition
only** - not built or verified here. The device tree (qcom/sdm845-oneplus-fajita) is in the mainline
kernel. Notch panel; the 6T's larger battery/fingerprint variant of the OnePlus 6.

Boot: unlock the bootloader, then `fastboot flash boot boot.img` and flash
the rootfs to userdata. These phones use Android A/B slots (boot_a/boot_b);
slot fallback is handled by the firmware. Real bring-up additionally needs the
device firmware blobs (WiFi/GPU/modem/venus) in /lib/firmware.
