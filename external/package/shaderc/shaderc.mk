################################################################################
#
# shaderc
#
# Built against the system glslang/spirv packages rather than the
# git-synced third_party checkouts the upstream build normally vendors.
#
################################################################################

SHADERC_VERSION = 2026.3
SHADERC_SITE = $(call github,google,shaderc,v$(SHADERC_VERSION))
SHADERC_LICENSE = Apache-2.0
SHADERC_LICENSE_FILES = LICENSE
SHADERC_INSTALL_STAGING = YES
SHADERC_DEPENDENCIES = host-pkgconf glslang spirv-tools spirv-headers

SHADERC_CONF_OPTS = \
	-DSHADERC_SKIP_TESTS=ON \
	-DSHADERC_SKIP_EXAMPLES=ON \
	-DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
	-DBUILD_SHARED_LIBS=ON

$(eval $(cmake-package))
