################################################################################
#
# ruffle
#
# Flash Player emulator, built from source. Upstream publishes no release
# tags, only dated nightlies, so the pin is a nightly tag and is bumped
# deliberately.
#
# The install step is overridden rather than using the cargo infrastructure's
# default: that runs "cargo install --path ./", which needs an unambiguous
# package at the manifest root, and upstream's root Cargo.toml is a virtual
# manifest (a [workspace] with no [package]). Copying the binary out of
# cargo's own target directory also avoids a second build invocation.
#
# --package ruffle_desktop is passed explicitly even though the workspace's
# default-members already selects it, so an upstream change there cannot
# quietly alter what gets built.
#
# host-rustc is not listed: the cargo infrastructure adds it to both the
# download and build dependencies itself (it runs cargo at download time to
# vendor the crates). The dependencies here are only what the binary links:
# alsa-lib for cpal's audio backend and udev for gilrs' gamepad probing.
# Neither OpenSSL nor nghttp2 is needed - this pin's Cargo.lock has no
# OpenSSL at all, since its TLS is rustls over ring. The windowing and GPU
# crates (winit, wgpu) dlopen their backends - Vulkan through ash, Wayland
# through wayland-backend, X11 through the pure-Rust x11rb - so they need no
# build-time libraries either, only the ones the image already ships.
#
# There is deliberately no ruffle.hash yet. The cargo infrastructure rewrites
# the downloaded archive before it is hashed (it repacks it with the vendored
# crate sources), so the recorded hash would have to be of Buildroot's own
# post-vendored tarball, not of upstream's. It can only be computed by
# running the download once:
#
#     make x86_64-pkg PKG=ruffle
#     sha256sum $(BR2_DL_DIR)/ruffle/ruffle-$(RUFFLE_VERSION).tar.gz
#
# A hash file that exists but has no entry for the archive is a hard error
# (support/download/check-hash exits 3), so it is left absent - which is only
# a warning - until that value is filled in.
#
################################################################################

RUFFLE_VERSION = nightly-2026-01-31
RUFFLE_SITE = $(call github,ruffle-rs,ruffle,$(RUFFLE_VERSION))
RUFFLE_LICENSE = MIT or Apache-2.0
RUFFLE_LICENSE_FILES = LICENSE.md

RUFFLE_DEPENDENCIES = host-pkgconf alsa-lib udev

RUFFLE_CARGO_BUILD_OPTS = --package ruffle_desktop

RUFFLE_BIN_DIR = target/$(RUSTC_TARGET_NAME)/$(if $(BR2_ENABLE_DEBUG),debug,release)

define RUFFLE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/$(RUFFLE_BIN_DIR)/ruffle_desktop \
		$(TARGET_DIR)/usr/bin/ruffle
	$(INSTALL) -D -m 0644 $(@D)/desktop/packages/linux/rs.ruffle.Ruffle.desktop \
		$(TARGET_DIR)/usr/share/applications/rs.ruffle.Ruffle.desktop
	$(INSTALL) -D -m 0644 $(@D)/desktop/packages/linux/rs.ruffle.Ruffle.svg \
		$(TARGET_DIR)/usr/share/icons/hicolor/scalable/apps/rs.ruffle.Ruffle.svg
endef

$(eval $(cargo-package))
