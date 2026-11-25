################################################################################
#
# firmware-trogdor-modem
#
################################################################################

# The files themselves, from a pinned commit of Cadmium's firmware
# collection, rather than the whole collection's archive (over 300 MB).
FIRMWARE_TROGDOR_MODEM_VERSION = af0ed4e25416b576285eed48128a39a17e460e4c
FIRMWARE_TROGDOR_MODEM_SITE = https://raw.githubusercontent.com/CadmiumLinux/firmware/$(FIRMWARE_TROGDOR_MODEM_VERSION)/qcom/sc7180-trogdor/modem-nolte
FIRMWARE_TROGDOR_MODEM_SOURCE = qdsp6sw.mbn
FIRMWARE_TROGDOR_MODEM_EXTRA_DOWNLOADS = mba.mbn
FIRMWARE_TROGDOR_MODEM_LICENSE = PROPRIETARY
FIRMWARE_TROGDOR_MODEM_REDISTRIBUTE = NO

define FIRMWARE_TROGDOR_MODEM_EXTRACT_CMDS
	cp $(FIRMWARE_TROGDOR_MODEM_DL_DIR)/qdsp6sw.mbn $(FIRMWARE_TROGDOR_MODEM_DL_DIR)/mba.mbn $(@D)/
endef

define FIRMWARE_TROGDOR_MODEM_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/mba.mbn \
		$(TARGET_DIR)/lib/firmware/qcom/sc7180-trogdor/modem-nolte/mba.mbn
	$(INSTALL) -D -m 0644 $(@D)/qdsp6sw.mbn \
		$(TARGET_DIR)/lib/firmware/qcom/sc7180-trogdor/modem-nolte/qdsp6sw.mbn
endef

$(eval $(generic-package))
