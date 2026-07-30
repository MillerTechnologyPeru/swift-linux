# Buildroot patches

Patches against the **Buildroot tree itself** (its `package/` definitions),
not against package sources. Buildroot's `BR2_GLOBAL_PATCH_DIR` only patches
package *source code*, so these cannot be applied that way — apply them to the
Buildroot checkout before building:

    cd <buildroot>
    patch -p1 < <this repo>/external/patches/buildroot/0002-*.patch

Only changes the Buildroot fork (the `buildroot` submodule) does not already
carry belong here; anything merged into the fork gets deleted from this
directory. The freedreno/turnip Vulkan driver and the GRUB 2.14 bump (with its
EROFS driver) used to live here and are now the fork's own commits.

## 0002-pipewire-support-the-LC3-bluetooth-codec.patch

Buildroot hardcodes `-Dbluez5-codec-lc3=disabled`. This makes it follow
`BR2_PACKAGE_LIBLC3` (the ports external's package), enabling the LE Audio
codec in PipeWire's bluez plugin when the library is in the config.
