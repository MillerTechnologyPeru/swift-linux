################################################################################
#
# box64
#
# x86_64 emulator/translator for 64-bit non-x86 hosts (ARM64 etc.). CMake
# auto-detects the host architecture and enables the matching dynarec.
#
################################################################################

BOX64_VERSION = 0.4.2
BOX64_SITE = $(call github,ptitSeb,box64,v$(BOX64_VERSION))
BOX64_LICENSE = MIT
BOX64_LICENSE_FILES = LICENSE

BOX64_CONF_OPTS = -DCMAKE_BUILD_TYPE=Release

# box64 ships prebuilt x86_64 helpers that are deliberately not the host
# architecture. The library set lives under /usr/lib/box64-x86_64-linux-gnu, a
# directory Buildroot's target arch check can skip via BIN_ARCH_EXCLUDE.
BOX64_BIN_ARCH_EXCLUDE = /usr/lib/box64-x86_64-linux-gnu

# The check normalizes each exclude to a directory prefix (it appends a
# trailing slash), so it cannot exclude the single x86_64 helper bash box64
# installs at /usr/bin/box64-bash, and the build fails ("is X86-64, should be
# AArch64"). box64 emulates x86_64 binaries without it - shell scripts run
# under the native bash - so drop it.
define BOX64_REMOVE_X86_BASH
	rm -f $(TARGET_DIR)/usr/bin/box64-bash
endef
BOX64_POST_INSTALL_TARGET_HOOKS += BOX64_REMOVE_X86_BASH

$(eval $(cmake-package))
