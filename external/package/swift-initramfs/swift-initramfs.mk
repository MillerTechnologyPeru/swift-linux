################################################################################
#
# swift-initramfs
#
# Builds its own static busybox from the same tarball the image's busybox
# uses (shared download), with the vendored minimal busybox.config - the
# initramfs needs a shell, mount and switch_root, not a userland. (A
# KCONFIG_ALLCONFIG fragment would be nicer, but busybox 1.38's kconfig
# ignores it - hence the full config file.) The
# cpio is generated here and installed as /boot/initrd inside the rootfs,
# so each A/B slot carries its own copy and RAUC updates it atomically;
# grub.cfg loads it only when present.
#
################################################################################

SWIFT_INITRAMFS_VERSION = 1.38.0
SWIFT_INITRAMFS_SOURCE = busybox-$(SWIFT_INITRAMFS_VERSION).tar.bz2
SWIFT_INITRAMFS_SITE = https://www.busybox.net/downloads
SWIFT_INITRAMFS_LICENSE = GPL-2.0
SWIFT_INITRAMFS_LICENSE_FILES = LICENSE

define SWIFT_INITRAMFS_CONFIGURE_CMDS
	$(INSTALL) -m 0644 $(SWIFT_INITRAMFS_PKGDIR)/busybox.config \
		$(@D)/.config
	yes "" | $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		CROSS_COMPILE="$(TARGET_CROSS)" oldconfig
endef

define SWIFT_INITRAMFS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		CROSS_COMPILE="$(TARGET_CROSS)" busybox
endef

define SWIFT_INITRAMFS_INSTALL_TARGET_CMDS
	rm -rf $(@D)/initramfs-root
	mkdir -p $(@D)/initramfs-root/bin \
		$(@D)/initramfs-root/dev \
		$(@D)/initramfs-root/proc \
		$(@D)/initramfs-root/sys \
		$(@D)/initramfs-root/new_root
	$(INSTALL) -m 0755 $(@D)/busybox $(@D)/initramfs-root/bin/busybox
	$(INSTALL) -m 0755 $(SWIFT_INITRAMFS_PKGDIR)/init \
		$(@D)/initramfs-root/init
	cd $(@D)/initramfs-root && find . | cpio -H newc -o --quiet | \
		gzip -9 > $(@D)/initrd
	$(INSTALL) -D -m 0644 $(@D)/initrd $(TARGET_DIR)/boot/initrd
endef

# The kernel must accept an external gzip initramfs.
define SWIFT_INITRAMFS_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_BLK_DEV_INITRD)
	$(call KCONFIG_ENABLE_OPT,CONFIG_RD_GZIP)
endef

$(eval $(generic-package))
