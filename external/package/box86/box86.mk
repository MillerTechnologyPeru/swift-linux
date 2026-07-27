################################################################################
#
# box86
#
# x86 (32-bit) emulator/translator for 32-bit ARM hosts. ARM_DYNAREC enables
# the just-in-time translator; without it box86 falls back to an interpreter.
#
################################################################################

BOX86_VERSION = 0.3.8
BOX86_SITE = $(call github,ptitSeb,box86,v$(BOX86_VERSION))
BOX86_LICENSE = MIT
BOX86_LICENSE_FILES = LICENSE

BOX86_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DARM_DYNAREC=ON

# box86 ships prebuilt x86 (i386) libraries for the programs it emulates.
# They are deliberately not ARM, so exclude the directory from Buildroot's
# target architecture check ("is Intel 80386, should be ARM").
BOX86_BIN_ARCH_EXCLUDE = /usr/lib/box86-i386-linux-gnu

# As with box64, the arch check cannot exclude the single i386 helper bash at
# /usr/bin/box86-bash (excludes are directory prefixes), so drop it - box86
# emulates i386 binaries without it.
define BOX86_REMOVE_X86_BASH
	rm -f $(TARGET_DIR)/usr/bin/box86-bash
endef
BOX86_POST_INSTALL_TARGET_HOOKS += BOX86_REMOVE_X86_BASH

$(eval $(cmake-package))
