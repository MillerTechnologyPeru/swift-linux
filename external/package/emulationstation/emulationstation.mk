################################################################################
#
# emulationstation
#
# Emulator frontend. Tracked by commit rather than a release tag: the fork does
# not publish tags, so pin the revision explicitly and bump it deliberately.
#
# The distro-specific build flags of the upstream fork (its own directory
# layout and menu entries) are deliberately left off, so the frontend uses its
# generic paths and reads its configuration from the user's home directory.
#
################################################################################

EMULATIONSTATION_VERSION = c415efc8801a219169d33ea46376a7cf2369f3ba
EMULATIONSTATION_SITE = https://github.com/ROCKNIX/emulationstation-next.git
EMULATIONSTATION_SITE_METHOD = git
EMULATIONSTATION_GIT_SUBMODULES = YES
EMULATIONSTATION_LICENSE = MIT
EMULATIONSTATION_LICENSE_FILES = LICENSE.md

# No boost: this fork dropped it (nothing in its CMake references Boost),
# so it is deliberately absent from the selects and dependencies.
EMULATIONSTATION_DEPENDENCIES = \
	host-pkgconf sdl2 sdl2_mixer freetype freeimage libcurl \
	rapidjson pugixml vlc alsa-lib

# libudev is an optional probe (light-gun support); depend on it when the
# config has it so the feature set does not vary with build order.
ifeq ($(BR2_PACKAGE_HAS_UDEV),y)
EMULATIONSTATION_DEPENDENCIES += udev
endif

EMULATIONSTATION_CONF_OPTS = \
	-DCEC=0 \
	-DDISABLE_KODI=1 \
	-DENABLE_FILEMANAGER=0 \
	-DUSE_SYSTEM_PUGIXML=1

# Desktop GL where it exists, GLES otherwise; the frontend needs one of them.
ifeq ($(BR2_PACKAGE_HAS_LIBGL),y)
EMULATIONSTATION_DEPENDENCIES += libgl libglu
EMULATIONSTATION_CONF_OPTS += -DGL=1
else
EMULATIONSTATION_DEPENDENCIES += libgles
EMULATIONSTATION_CONF_OPTS += -DGLES2=1
endif

# Audio through ALSA rather than PulseAudio: this system runs PipeWire, whose
# ALSA plugin routes it, and there is no PulseAudio daemon to talk to.
EMULATIONSTATION_CONF_OPTS += -DENABLE_PULSE=0

# Squashfs app images (see the overlay's es-launch): entries in the Apps/
# Games/Tools groups can be .squashfs bundles that get loop-mounted at
# launch, batocera-style. The board kernel defconfigs do not carry loop or
# squashfs, so enable them whenever the frontend is in the image - xz and
# zstd cover the compressors mksquashfs realistically produces.
define EMULATIONSTATION_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_ENABLE_OPT,CONFIG_BLK_DEV_LOOP)
	$(call KCONFIG_ENABLE_OPT,CONFIG_SQUASHFS)
	$(call KCONFIG_ENABLE_OPT,CONFIG_SQUASHFS_XZ)
	$(call KCONFIG_ENABLE_OPT,CONFIG_SQUASHFS_ZSTD)
endef

$(eval $(cmake-package))
