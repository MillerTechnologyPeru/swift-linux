# Rockchip RK3576 (A72 + A53, Mali-G52) patches

Shared kernel / bootloader patches for all Rockchip RK3576 (A72 + A53, Mali-G52) handhelds, applied via
BR2_GLOBAL_PATCH_DIR and stacked before each device's own patches/ dir.
linux/*.patch patch the kernel, uboot/*.patch patch U-Boot. Empty for now:
a real bring-up drops the not-yet-mainlined bits here (panel/DSI, gamepad,
charger, DTS additions).
