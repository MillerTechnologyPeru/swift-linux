################################################################################
#
# libretro-scummvm
#
# Pinned by commit: the libretro cores are rolling repositories without
# release tags. The libretro backend expects two helper repositories under
# backends/platform/libretro/deps, vendored here as extra downloads pinned
# to their own commits (the upstream build would git-clone them mid-build).
# Cores install under /usr/lib/libretro, where retroarch's
# libretro_directory points.
#
################################################################################

LIBRETRO_SCUMMVM_VERSION = 660e13b0764fe2be39b6d723345ecabfbb318cc5
LIBRETRO_SCUMMVM_SITE = $(call github,libretro,scummvm,$(LIBRETRO_SCUMMVM_VERSION))
LIBRETRO_SCUMMVM_LICENSE = GPL-3.0
LIBRETRO_SCUMMVM_LICENSE_FILES = COPYING

LIBRETRO_SCUMMVM_DEPS_VERSION = 7e6e34f0319f4c7448d72f0e949e76265ccf55a1
LIBRETRO_SCUMMVM_COMMON_VERSION = 70ed90c42ddea828f53dd1b984c6443ddb39dbd6
LIBRETRO_SCUMMVM_EXTRA_DOWNLOADS = \
	https://github.com/libretro/libretro-deps/archive/$(LIBRETRO_SCUMMVM_DEPS_VERSION)/libretro-deps-$(LIBRETRO_SCUMMVM_DEPS_VERSION).tar.gz \
	https://github.com/libretro/libretro-common/archive/$(LIBRETRO_SCUMMVM_COMMON_VERSION)/libretro-common-$(LIBRETRO_SCUMMVM_COMMON_VERSION).tar.gz

define LIBRETRO_SCUMMVM_UNPACK_DEPS
	rm -rf $(@D)/backends/platform/libretro/deps/libretro-deps \
		$(@D)/backends/platform/libretro/deps/libretro-common
	mkdir -p $(@D)/backends/platform/libretro/deps/libretro-deps \
		$(@D)/backends/platform/libretro/deps/libretro-common
	$(TAR) --strip-components=1 -xzf \
		$(LIBRETRO_SCUMMVM_DL_DIR)/libretro-deps-$(LIBRETRO_SCUMMVM_DEPS_VERSION).tar.gz \
		-C $(@D)/backends/platform/libretro/deps/libretro-deps
	$(TAR) --strip-components=1 -xzf \
		$(LIBRETRO_SCUMMVM_DL_DIR)/libretro-common-$(LIBRETRO_SCUMMVM_COMMON_VERSION).tar.gz \
		-C $(@D)/backends/platform/libretro/deps/libretro-common
endef
LIBRETRO_SCUMMVM_POST_EXTRACT_HOOKS += LIBRETRO_SCUMMVM_UNPACK_DEPS

# 64-bit only in this repo's images (x86_64 and aarch64 boards). No AR
# override: the build's rules.mk expects AR to carry its flags ("ar cru"),
# so a bare gcc-ar breaks the archive steps; host ar is fine for static
# archives of cross objects.
define LIBRETRO_SCUMMVM_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D)/backends/platform/libretro \
		platform=unix TARGET_64BIT=1 \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)"
endef

define LIBRETRO_SCUMMVM_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/backends/platform/libretro/scummvm_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/scummvm_libretro.so
endef

$(eval $(generic-package))
