################################################################################
#
# libfreeaptx
#
################################################################################

LIBFREEAPTX_VERSION = 0.2.2
LIBFREEAPTX_SITE = $(call github,iamthehorker,libfreeaptx,$(LIBFREEAPTX_VERSION))
LIBFREEAPTX_LICENSE = LGPL-2.1+
LIBFREEAPTX_LICENSE_FILES = COPYING
LIBFREEAPTX_INSTALL_STAGING = YES

define LIBFREEAPTX_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(@D)
endef

define LIBFREEAPTX_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(STAGING_DIR) PREFIX=/usr install
endef

define LIBFREEAPTX_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) PREFIX=/usr install
endef

$(eval $(generic-package))
