################################################################################
#
# shaderc
#
# shaderc's CMake only builds against vendored third_party source
# checkouts (no system-libs fallback - distros patch it instead), so the
# DEPS-pinned glslang/spirv sources are fetched as extra downloads and
# unpacked into third_party before configure. The system spirv packages
# still provide the runtime libraries other consumers link.
#
################################################################################

SHADERC_VERSION = 2026.3
SHADERC_SITE = $(call github,google,shaderc,v$(SHADERC_VERSION))
SHADERC_LICENSE = Apache-2.0
SHADERC_LICENSE_FILES = LICENSE
SHADERC_INSTALL_STAGING = YES
SHADERC_DEPENDENCIES = host-pkgconf

# The DEPS-pinned third_party sources (shaderc 2026.3's DEPS file).
SHADERC_GLSLANG_DEP = 168d452a4f460d24b588fed08477a81c44ee27a1
SHADERC_SPIRV_HEADERS_DEP = 29981f65241605e08b0ede4cfeb999fe3b723c6a
SHADERC_SPIRV_TOOLS_DEP = b707790a898e44038547df54580022fc1cf89c3d
SHADERC_EXTRA_DOWNLOADS = \
	https://github.com/KhronosGroup/glslang/archive/$(SHADERC_GLSLANG_DEP).tar.gz \
	https://github.com/KhronosGroup/SPIRV-Headers/archive/$(SHADERC_SPIRV_HEADERS_DEP).tar.gz \
	https://github.com/KhronosGroup/SPIRV-Tools/archive/$(SHADERC_SPIRV_TOOLS_DEP).tar.gz

define SHADERC_UNPACK_THIRD_PARTY
	mkdir -p $(@D)/third_party/glslang $(@D)/third_party/spirv-headers \
		$(@D)/third_party/spirv-tools
	$(TAR) --strip-components=1 -xzf \
		$(SHADERC_DL_DIR)/$(SHADERC_GLSLANG_DEP).tar.gz \
		-C $(@D)/third_party/glslang
	$(TAR) --strip-components=1 -xzf \
		$(SHADERC_DL_DIR)/$(SHADERC_SPIRV_HEADERS_DEP).tar.gz \
		-C $(@D)/third_party/spirv-headers
	$(TAR) --strip-components=1 -xzf \
		$(SHADERC_DL_DIR)/$(SHADERC_SPIRV_TOOLS_DEP).tar.gz \
		-C $(@D)/third_party/spirv-tools
endef
SHADERC_POST_EXTRACT_HOOKS += SHADERC_UNPACK_THIRD_PARTY

SHADERC_CONF_OPTS = \
	-DSHADERC_SKIP_TESTS=ON \
	-DSHADERC_SKIP_EXAMPLES=ON \
	-DSHADERC_SKIP_COPYRIGHT_CHECK=ON \
	-DBUILD_SHARED_LIBS=ON \
	-DSKIP_GLSLANG_INSTALL=ON \
	-DSKIP_SPIRV_TOOLS_INSTALL=ON \
	-DSKIP_GOOGLETEST_INSTALL=ON

$(eval $(cmake-package))
