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

# box64 ships prebuilt x86_64 libraries for the programs it emulates. They are
# deliberately not the host architecture, so exclude them from Buildroot's
# target architecture check ("is X86-64, should be AArch64").
BOX64_BIN_ARCH_EXCLUDE = /usr/lib/box64-x86_64-linux-gnu

$(eval $(cmake-package))
