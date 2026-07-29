################################################################################
#
# python-pygame2
#
# pygame 2.x on SDL2. The buildconfig probes sdl2-config and /usr paths on
# the build host, so both are pointed at staging before configure. Docs and
# tests are dropped from the target - they are a third of the install.
#
################################################################################

PYTHON_PYGAME2_VERSION = 2.6.1
PYTHON_PYGAME2_SITE = $(call github,pygame,pygame,$(PYTHON_PYGAME2_VERSION))
PYTHON_PYGAME2_SETUP_TYPE = setuptools
PYTHON_PYGAME2_LICENSE = LGPL-2.1+
PYTHON_PYGAME2_LICENSE_FILES = docs/LGPL.txt
PYTHON_PYGAME2_DEPENDENCIES = sdl2 sdl2_image sdl2_mixer sdl2_ttf libpng \
	jpeg host-python-cython

define PYTHON_PYGAME2_FIX_STAGING_PATHS
	$(SED) "s+sdl2-config+$(STAGING_DIR)/usr/bin/sdl2-config+g" \
		$(@D)/buildconfig/config_unix.py
	$(SED) 's+"/usr+"$(STAGING_DIR)/usr+g' \
		$(@D)/buildconfig/config_unix.py
	$(SED) "s+'/usr+'$(STAGING_DIR)/usr+g" \
		$(@D)/buildconfig/config_unix.py
endef
PYTHON_PYGAME2_PRE_CONFIGURE_HOOKS += PYTHON_PYGAME2_FIX_STAGING_PATHS

define PYTHON_PYGAME2_REMOVE_DOC_AND_TESTS
	rm -rf $(TARGET_DIR)/usr/lib/python*/site-packages/pygame/docs \
		$(TARGET_DIR)/usr/lib/python*/site-packages/pygame/tests \
		$(TARGET_DIR)/usr/lib/python*/site-packages/pygame/examples
endef
PYTHON_PYGAME2_POST_INSTALL_TARGET_HOOKS += PYTHON_PYGAME2_REMOVE_DOC_AND_TESTS

$(eval $(python-package))
