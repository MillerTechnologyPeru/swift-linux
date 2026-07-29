################################################################################
#
# mozjs128
#
# SpiderMonkey standalone, the distro way: the Firefox ESR source tarball
# with js/src/configure (the flags below follow the Arch/Yocto mozjs128
# recipes). Needs the Rust host toolchain; the bundled ICU is used rather
# than the system one to decouple from Buildroot's ICU version. This is
# the single hardest cross-compile of the GNOME stack - expect the first
# build to need iteration.
#
################################################################################

MOZJS128_VERSION = 128.14.0
MOZJS128_SOURCE = firefox-$(MOZJS128_VERSION)esr.source.tar.xz
MOZJS128_SITE = https://ftp.mozilla.org/pub/firefox/releases/$(MOZJS128_VERSION)esr/source
MOZJS128_LICENSE = MPL-2.0
MOZJS128_LICENSE_FILES = LICENSE
MOZJS128_INSTALL_STAGING = YES
MOZJS128_DEPENDENCIES = host-pkgconf host-python3 host-rustc zlib

MOZJS128_CONF_ENV = \
	$(TARGET_CONFIGURE_OPTS) \
	RUSTC=$(HOST_DIR)/bin/rustc \
	CARGO=$(HOST_DIR)/bin/cargo \
	MOZBUILD_STATE_PATH=$(@D)/.mozbuild

MOZJS128_CONF_OPTS = \
	--host=$(shell $(HOSTCC) -dumpmachine) \
	--target=$(GNU_TARGET_NAME) \
	--prefix=/usr \
	--disable-debug \
	--disable-debug-symbols \
	--disable-jemalloc \
	--disable-strip \
	--disable-tests \
	--enable-optimize \
	--enable-shared-js \
	--enable-rust-simd=no \
	--with-intl-api \
	--without-system-icu \
	--with-system-zlib

define MOZJS128_CONFIGURE_CMDS
	mkdir -p $(@D)/buildroot-build $(@D)/.mozbuild
	cd $(@D)/buildroot-build && \
		$(MOZJS128_CONF_ENV) $(SHELL) $(@D)/js/src/configure \
			$(MOZJS128_CONF_OPTS)
endef

define MOZJS128_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/buildroot-build
endef

define MOZJS128_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/buildroot-build \
		DESTDIR=$(STAGING_DIR) install
endef

define MOZJS128_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/buildroot-build/js/src/build/libmozjs-128.so \
		$(TARGET_DIR)/usr/lib/libmozjs-128.so
endef

$(eval $(generic-package))
