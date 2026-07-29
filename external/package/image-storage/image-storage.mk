################################################################################
#
# image-storage
#
# Local files only, no upstream: a metapackage whose sole job is kernel
# config fixups for the root and data partition filesystems (see
# Config.in). Built-in (=y, not =m): the root filesystem has to be
# mountable before any module can load, and forcing =y for the data
# filesystems too keeps S15data and system-install from depending on
# module auto-loading being configured right on every board.
#
################################################################################

define IMAGE_STORAGE_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_EROFS_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_EXT4_FS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_F2FS_FS)
endef

$(eval $(generic-package))
