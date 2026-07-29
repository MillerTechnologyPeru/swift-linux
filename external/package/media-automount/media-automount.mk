################################################################################
#
# media-automount
#
# Local files only, no upstream. Everything automount-related lives here:
# the udev rule, the mount helper, and an init script that mounts the
# /media tmpfs and replays coldplug - so images that do not select this
# package are completely untouched (no stray fstab entries or rules).
#
# udev RUN executing mount is safe with eudev: unlike systemd-udevd it
# runs workers without a private mount namespace, so mounts propagate.
#
################################################################################

define MEDIA_AUTOMOUNT_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/media
	$(INSTALL) -D -m 0755 $(MEDIA_AUTOMOUNT_PKGDIR)/files/media-mount \
		$(TARGET_DIR)/usr/bin/media-mount
	$(INSTALL) -D -m 0644 $(MEDIA_AUTOMOUNT_PKGDIR)/files/99-media-automount.rules \
		$(TARGET_DIR)/lib/udev/rules.d/99-media-automount.rules
	$(INSTALL) -D -m 0755 $(MEDIA_AUTOMOUNT_PKGDIR)/files/S16media \
		$(TARGET_DIR)/etc/init.d/S16media
endef

# The media people actually plug in: FAT/exFAT/NTFS, plus the codepages
# the FAT family needs. Board kernel defconfigs do not carry these.
define MEDIA_AUTOMOUNT_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_USB_STORAGE)
	$(call KCONFIG_ENABLE_OPT,CONFIG_MSDOS_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_VFAT_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_EXFAT_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NTFS3_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NLS_CODEPAGE_437)
	$(call KCONFIG_ENABLE_OPT,CONFIG_NLS_ISO8859_1)
endef

$(eval $(generic-package))
