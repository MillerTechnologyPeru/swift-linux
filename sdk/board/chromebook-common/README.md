# Chromebook boot (Depthcharge)

Chromebooks boot through the firmware's Depthcharge payload, which reads a
ChromeOS *kernel partition*: a FIT image (kernel + device tree, matched by
compatible string) signed with vboot keys. With the public devkeys this works
on any Chromebook in developer mode (`crossystem dev_boot_usb=1` /
`enable_dev_usb_boot`).

A/B is native: two kernel partitions with cgpt priority/tries/successful
attributes; the firmware falls back to the other slot when tries run out.
No GRUB and no U-Boot are involved. `post-image.sh` builds `chromebook.img`
with KERN-A/KERN-B/ROOT and both slots populated.

A real device additionally needs its firmware blobs (WiFi/BT/GPU/EC-touch,
per family README) and the SoC kernel patches staged in the family patches/
directory. Everything here is definition-only until verified on hardware.
