################################################################################
#
# glslang
#
################################################################################

GLSLANG_VERSION = 16.4.0
GLSLANG_SITE = $(call github,KhronosGroup,glslang,$(GLSLANG_VERSION))
GLSLANG_LICENSE = BSD-3-Clause, BSD-2-Clause, MIT, Apache-2.0
GLSLANG_LICENSE_FILES = LICENSE.txt
GLSLANG_INSTALL_STAGING = YES
GLSLANG_DEPENDENCIES = host-pkgconf spirv-tools spirv-headers

GLSLANG_CONF_OPTS = \
	-DBUILD_SHARED_LIBS=ON \
	-DENABLE_OPT=ON \
	-DALLOW_EXTERNAL_SPIRV_TOOLS=ON \
	-DGLSLANG_TESTS=OFF \
	-DBUILD_EXTERNAL=OFF

$(eval $(cmake-package))
