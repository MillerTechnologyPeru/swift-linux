################################################################################
#
# libretro-dosbox-pure
#
# Unlike the rolling libretro repositories this upstream tags releases, so
# the pin is a tag. Cores install under /usr/lib/libretro, where retroarch's
# libretro_directory points.
#
################################################################################

LIBRETRO_DOSBOX_PURE_VERSION = 0.9.9
LIBRETRO_DOSBOX_PURE_SITE = $(call github,schellingb,dosbox-pure,$(LIBRETRO_DOSBOX_PURE_VERSION))
LIBRETRO_DOSBOX_PURE_LICENSE = GPL-2.0
LIBRETRO_DOSBOX_PURE_LICENSE_FILES = LICENSE

# The Makefile's target= selects the dynarec: x86_64/arm64/arm get a native
# backend, anything else falls back to the interpreter. WITH_FAKE_SDL stubs
# the SDL calls out of the net/serial code, dropping the SDL dependency.
ifeq ($(BR2_x86_64),y)
LIBRETRO_DOSBOX_PURE_TARGET = target=x86_64
else ifeq ($(BR2_aarch64),y)
LIBRETRO_DOSBOX_PURE_TARGET = target=arm64
else ifeq ($(BR2_arm),y)
LIBRETRO_DOSBOX_PURE_TARGET = target=arm
endif

define LIBRETRO_DOSBOX_PURE_BUILD_CMDS
	$(TARGET_CONFIGURE_OPTS) $(MAKE) -C $(@D) -f Makefile \
		platform=unix $(LIBRETRO_DOSBOX_PURE_TARGET) WITH_FAKE_SDL=1 \
		CC="$(TARGET_CC)" CXX="$(TARGET_CXX)" AR="$(TARGET_AR)"
endef

define LIBRETRO_DOSBOX_PURE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/dosbox_pure_libretro.so \
		$(TARGET_DIR)/usr/lib/libretro/dosbox_pure_libretro.so
endef

$(eval $(generic-package))
