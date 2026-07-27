# Rockchip RK3588/RK3588S (4x A76 + 4x A55, Mali-G610) patches

Shared kernel / bootloader patches for all Rockchip RK3588/RK3588S (4x A76 + 4x A55, Mali-G610) handhelds, applied via
BR2_GLOBAL_PATCH_DIR and stacked before each device's own patches/ dir.
linux/*.patch patch the kernel, uboot/*.patch patch U-Boot. Empty for now:
a real bring-up drops the not-yet-mainlined bits here (panel/DSI, gamepad,
charger, DTS additions).
