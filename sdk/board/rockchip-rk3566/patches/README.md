# Rockchip RK3566 kernel / U-Boot patches

Shared patches for all RK3566 handhelds in this family (applied via
`BR2_GLOBAL_PATCH_DIR`, stacked before each device's own `patches/`).

Buildroot applies `linux/*.patch` to the kernel and `uboot/*.patch` to U-Boot
(subdirectory named after the package). Put SoC-wide fixes here - panel/DSI
bring-up, RK817 audio/charger, ADC joystick - and device-specific ones in the
device board's `patches/`.

Empty for now: a real bring-up drops the not-yet-mainlined patches here.
