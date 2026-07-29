#!/bin/sh
# Apple Silicon post-image: the platform installer owns partitioning (stub
# container, ESP, root); the distro ships the rootfs and the ESP GRUB payload.
# DEFINITION ONLY - packages the rootfs for the installer flow.
set -e
echo "post-image: rootfs at ${BINARIES_DIR}/rootfs.erofs (installer consumes this; ESP gets grub bootaa64.efi + m1n1 stage2 via the platform's update scripts)"
