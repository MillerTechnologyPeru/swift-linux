# Buildroot patches

Patches against the **Buildroot tree itself** (its `package/` definitions),
not against package sources. Buildroot's `BR2_GLOBAL_PATCH_DIR` only patches
package *source code*, so these cannot be applied that way — apply them to the
Buildroot checkout before building:

    cd <buildroot>
    patch -p1 < <this repo>/external/patches/buildroot/0001-*.patch

## 0001-mesa3d-add-freedreno-vulkan-turnip-driver.patch

Adds `BR2_PACKAGE_MESA3D_VULKAN_DRIVER_FREEDRENO`, the freedreno (turnip)
Vulkan driver for Qualcomm Adreno GPUs. Buildroot 2026.05 ships the freedreno
gallium (OpenGL/GLES) driver but not the Vulkan one, so Adreno devices such as
the Retroid Pocket 5 / Flip 2 (Snapdragon 865) otherwise have no Vulkan.

The Vulkan *runtime* (the `vulkan-loader` ICD loader, `vulkan-headers` and
`vulkan-tools`) is already in Buildroot; this patch only adds the missing
Adreno *driver* (ICD), wired to mesa's `-Dvulkan-drivers=freedreno`.

## 0002-pipewire-support-the-LC3-bluetooth-codec.patch

Buildroot hardcodes `-Dbluez5-codec-lc3=disabled`. This makes it follow
`BR2_PACKAGE_LIBLC3` (this repo's external package), enabling the LE Audio
codec in PipeWire's bluez plugin when the library is in the config.
