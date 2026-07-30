# HP Chromebook 11a (kappa)

MediaTek MT8183 Chromebook, Mali-G72 (panfrost), jacuzzi sub-baseboard: the
panel hangs off an Analogix ANX7625 DSI-to-eDP bridge rather than being driven
directly over DSI like the kukui tablets, and there is a trackpad
(`linux.fragment` covers both). Device tree
`mediatek/mt8183-kukui-jacuzzi-kappa`, mainline.

Boots via Depthcharge in developer mode (see
`sdk/board/chromebook-common/README.md`). Speaker routing comes from the
family UCM profile in `sdk/board/chromebook-mt8183/rootfs-overlay`. A real
build additionally needs the WiFi/BT firmware blobs in the rootfs and any
not-yet-mainlined kernel quirks staged in
`sdk/board/chromebook-mt8183/patches/`.
