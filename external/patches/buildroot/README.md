# Buildroot patches

Changes to the **Buildroot tree itself** (its `package/` definitions) do not
live here anymore: they are commits on the `buildroot` submodule fork's
`feature/swift-linux` branch, which is rebased onto upstream Buildroot
weekly. Buildroot's `BR2_GLOBAL_PATCH_DIR` only patches package *source
code*, so tree changes can only travel as fork commits - the freedreno/turnip
Vulkan driver, the GRUB 2.14 bump (EROFS driver) and the pipewire LC3 hookup
all live there now.

If a tree change ever has to be staged here temporarily, apply it to the
Buildroot checkout before building:

    cd <buildroot>
    patch -p1 < <this repo>/external/patches/buildroot/<patch>

and move it into the fork branch at the next rebase.
