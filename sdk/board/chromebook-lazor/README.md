# Acer Chromebook Spin 513 (lazor)

Qualcomm SC7180 Chromebook, Adreno 618 (freedreno). Not yet verified on
hardware. Boots via Depthcharge in developer mode (see
`sdk/board/chromebook-common/README.md`).

One image covers every Spin 513: the kernel partition carries all of
lazor's device trees, one per board revision and SKU (touchscreen,
keyboard-only, LTE, and the limozeen variants), and Depthcharge boots the
one whose compatible matches the unit.

Wi-Fi needs the modem running, since the Wi-Fi's firmware service lives
there. The family config (`sdk/board/chromebook-sc7180/`) supplies the
modem's firmware (ChromeOS's, not in linux-firmware), rmtfs serving the
modem's EFS from files on `/run` (Chromebooks have no EFS partitions), and
a QRTR name-server fix without which the modem stalls at start. The DSI
controller's refgen regulator is built in, because the 7.x trogdor device
tree requires it and the panel stays black without it.
