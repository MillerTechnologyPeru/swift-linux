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

$(eval $(cmake-package))
