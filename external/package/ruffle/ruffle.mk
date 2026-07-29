################################################################################
#
# ruffle
#
# Flash Player emulator, from upstream's prebuilt Linux tarballs (see
# Config.in for why it is not built from source). Upstream only publishes
# dated nightlies; the pin is the tag date, bumped deliberately.
#
# The binaries are produced on a newer distribution than this tree targets
# and carry a GLIBC_2.39 version requirement - for nothing but the two
# pidfd_* symbols Rust's libstd references weakly and falls back from at
# runtime. relax-verneed.py rewrites that requirement (see the script), so
# the binary loads against this tree's glibc; everything else it needs is
# at GLIBC_2.35 or older.
#
################################################################################

RUFFLE_VERSION = 2026-07-29
RUFFLE_SITE = https://github.com/ruffle-rs/ruffle/releases/download/nightly-$(RUFFLE_VERSION)

ifeq ($(BR2_aarch64),y)
RUFFLE_ARCH = aarch64
else
RUFFLE_ARCH = x86_64
endif
RUFFLE_SOURCE = ruffle-nightly-$(subst -,_,$(RUFFLE_VERSION))-linux-$(RUFFLE_ARCH).tar.gz

RUFFLE_LICENSE = MIT or Apache-2.0
RUFFLE_LICENSE_FILES = LICENSE.md

# The tarball has no top-level directory.
RUFFLE_STRIP_COMPONENTS = 0

# Only for relax-verneed.py: python3 is not one of Buildroot's mandatory
# host programs, so the interpreter is depended on rather than assumed.
# Every image that selects this package builds host-python3 anyway (the
# target python3 the frontend's other systems need pulls it in).
RUFFLE_DEPENDENCIES = host-python3

# The version requirement is rewritten on the installed copy, not in the
# build directory: the extracted binary stays pristine, which keeps this
# idempotent when the install step runs again, and the install step is late
# enough that host-python3 is built (extract-time hooks are not - they run
# before a package's dependencies).
define RUFFLE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/ruffle $(TARGET_DIR)/usr/bin/ruffle
	$(HOST_DIR)/bin/python3 $(RUFFLE_PKGDIR)/relax-verneed.py \
		$(TARGET_DIR)/usr/bin/ruffle GLIBC_2.39
	$(INSTALL) -D -m 0644 $(@D)/extras/rs.ruffle.Ruffle.desktop \
		$(TARGET_DIR)/usr/share/applications/rs.ruffle.Ruffle.desktop
	$(INSTALL) -D -m 0644 $(@D)/extras/rs.ruffle.Ruffle.svg \
		$(TARGET_DIR)/usr/share/icons/hicolor/scalable/apps/rs.ruffle.Ruffle.svg
endef

$(eval $(generic-package))
