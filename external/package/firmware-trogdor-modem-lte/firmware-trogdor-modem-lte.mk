################################################################################
#
# firmware-trogdor-modem-lte
#
################################################################################

# The files themselves, from a pinned commit of Cadmium's firmware
# collection, rather than the whole collection's archive (over 300 MB).
FIRMWARE_TROGDOR_MODEM_LTE_VERSION = af0ed4e25416b576285eed48128a39a17e460e4c
FIRMWARE_TROGDOR_MODEM_LTE_SITE = https://raw.githubusercontent.com/CadmiumLinux/firmware/$(FIRMWARE_TROGDOR_MODEM_LTE_VERSION)/qcom/sc7180-trogdor/modem
FIRMWARE_TROGDOR_MODEM_LTE_SOURCE = qdsp6sw.mbn
FIRMWARE_TROGDOR_MODEM_LTE_EXTRA_DOWNLOADS = mba.mbn
FIRMWARE_TROGDOR_MODEM_LTE_LICENSE = PROPRIETARY
FIRMWARE_TROGDOR_MODEM_LTE_REDISTRIBUTE = NO

define FIRMWARE_TROGDOR_MODEM_LTE_EXTRACT_CMDS
	cp $(FIRMWARE_TROGDOR_MODEM_LTE_DL_DIR)/qdsp6sw.mbn $(FIRMWARE_TROGDOR_MODEM_LTE_DL_DIR)/mba.mbn $(@D)/
endef

define FIRMWARE_TROGDOR_MODEM_LTE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0644 $(@D)/mba.mbn \
		$(TARGET_DIR)/lib/firmware/qcom/sc7180-trogdor/modem/mba.mbn
	$(INSTALL) -D -m 0644 $(@D)/qdsp6sw.mbn \
		$(TARGET_DIR)/lib/firmware/qcom/sc7180-trogdor/modem/qdsp6sw.mbn
endef

$(eval $(generic-package))
