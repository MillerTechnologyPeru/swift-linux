################################################################################
#
# chicago95
#
# Pure data: the GTK/xfwm4 theme, icons and cursors, installed to the
# standard theme paths, plus /etc/xdg xfconf channel defaults (xsettings +
# xfwm4) that select it - so a first boot comes up themed without any
# per-user state. A user can still pick another theme; their choice lands
# in ~/.config/xfce4 on the data partition and overrides these.
#
################################################################################

CHICAGO95_VERSION = 3.0.1
CHICAGO95_SITE = $(call github,grassmunk,Chicago95,v$(CHICAGO95_VERSION))
CHICAGO95_LICENSE = GPL-3.0+, MIT
CHICAGO95_LICENSE_FILES = README.md

define CHICAGO95_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/themes $(TARGET_DIR)/usr/share/icons
	cp -a "$(@D)/Theme/Chicago95" $(TARGET_DIR)/usr/share/themes/
	cp -a "$(@D)/Icons/Chicago95" $(TARGET_DIR)/usr/share/icons/
	cp -a "$(@D)/Cursors/Chicago95_Cursor_White" $(TARGET_DIR)/usr/share/icons/
	$(INSTALL) -D -m 0644 $(CHICAGO95_PKGDIR)/xsettings.xml \
		$(TARGET_DIR)/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
	$(INSTALL) -D -m 0644 $(CHICAGO95_PKGDIR)/xfwm4.xml \
		$(TARGET_DIR)/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
endef

$(eval $(generic-package))
