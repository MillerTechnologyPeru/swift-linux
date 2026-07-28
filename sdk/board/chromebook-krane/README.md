# Lenovo Chromebook Duet (krane)

MediaTek MT8183 Chromebook, Mali-G72 (panfrost). **Definition only** - not built or verified here.
Boots via Depthcharge in developer mode (see
`sdk/board/chromebook-common/README.md`). A real build additionally needs the
device firmware blobs (WiFi/BT/GPU) in the rootfs and any not-yet-mainlined
kernel quirks staged in `sdk/board/chromebook-mt8183/patches/`.
