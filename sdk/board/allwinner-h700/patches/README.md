# Allwinner H700 kernel / U-Boot patches

Shared patches for all H700 handhelds (applied via `BR2_GLOBAL_PATCH_DIR`,
stacked before each device's own `patches/`). `linux/*.patch` patch the kernel,
`uboot/*.patch` patch U-Boot. Put SoC-wide fixes here (panel/DSI, AXP charger,
ADC joystick) and device-specific ones in the device board's `patches/`.
