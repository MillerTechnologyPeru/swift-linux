################################################################################
#
# gl4es
#
# Desktop OpenGL 1.5/2.1 implemented on top of GLES 1.1/2.0, for GPUs whose
# drivers expose only GLES. Installs its libGL under /usr/lib/gl4es, so a
# program opts in via LD_LIBRARY_PATH rather than the whole system being
# switched over.
#
################################################################################

# Upstream tags releases rarely; pin a known-good commit instead.
GL4ES_VERSION = bfcdd3a452e0d04d41afd2693a879c073b5ad8c9
GL4ES_SITE = $(call github,ptitSeb,gl4es,$(GL4ES_VERSION))
GL4ES_LICENSE = MIT
GL4ES_LICENSE_FILES = LICENSE
GL4ES_INSTALL_STAGING = YES

# NO_INIT_CONSTRUCTOR: initialize on first GL call instead of at library
# load, which keeps LD_PRELOAD/LD_LIBRARY_PATH use from breaking programs
# that only link the library. The policy minimum is for CMake >= 4, which
# refuses the project's older cmake_minimum_required outright.
GL4ES_CONF_OPTS = \
	-DNO_INIT_CONSTRUCTOR=ON \
	-DCMAKE_POLICY_VERSION_MINIMUM=3.5

# The X11/GLX front end needs libX11; without the X.org stack (XWayland
# images carry it) build the EGL-only flavor.
ifeq ($(BR2_PACKAGE_XORG7),)
GL4ES_CONF_OPTS += -DNOX11=ON
endif

# Link against the GLES/EGL that mesa provides when it is in the build.
ifeq ($(BR2_PACKAGE_MESA3D),y)
GL4ES_DEPENDENCIES += mesa3d
endif

# The install puts libGL.so.1 in /usr/lib/gl4es but no dev symlink; add it
# in staging so -lGL against the gl4es directory resolves at link time.
define GL4ES_STAGING_DEV_SYMLINK
	ln -sf libGL.so.1 $(STAGING_DIR)/usr/lib/gl4es/libGL.so
endef
GL4ES_POST_INSTALL_STAGING_HOOKS += GL4ES_STAGING_DEV_SYMLINK

$(eval $(cmake-package))
