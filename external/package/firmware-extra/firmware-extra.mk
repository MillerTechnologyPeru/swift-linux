################################################################################
#
# firmware-extra
#
# Curated firmware from the upstream linux-firmware collection that
# Buildroot's linux-firmware package has no options for: smart-amp speaker
# firmware, Qualcomm Bluetooth, the Qualcomm SoC wifi parts and Intel's AVS
# audio DSP. The version and DL_SUBDIR match the linux-firmware package so
# both share one downloaded tarball.
#
################################################################################

FIRMWARE_EXTRA_VERSION = 20260410
FIRMWARE_EXTRA_SOURCE = linux-firmware-$(FIRMWARE_EXTRA_VERSION).tar.xz
FIRMWARE_EXTRA_SITE = $(BR2_KERNEL_MIRROR)/linux/kernel/firmware
FIRMWARE_EXTRA_DL_SUBDIR = linux-firmware
FIRMWARE_EXTRA_LICENSE = FIRMWARE (redistributable, no modification)
FIRMWARE_EXTRA_LICENSE_FILES = WHENCE LICENCE.qcom LICENCE.cirrus

ifeq ($(BR2_PACKAGE_FIRMWARE_EXTRA_AMP),y)
FIRMWARE_EXTRA_FILES += cirrus cs42l43.bin ti/audio
endif

ifeq ($(BR2_PACKAGE_FIRMWARE_EXTRA_QCA_BT),y)
FIRMWARE_EXTRA_FILES += qca
endif

ifeq ($(BR2_PACKAGE_FIRMWARE_EXTRA_ATH_SOC),y)
FIRMWARE_EXTRA_FILES += \
	ath10k/WCN3990 \
	ath11k/QCA6390 \
	ath11k/WCN6750 \
	ath12k/WCN7850
endif

ifeq ($(BR2_PACKAGE_FIRMWARE_EXTRA_AVS),y)
FIRMWARE_EXTRA_FILES += intel/avs
endif

# cp --parents keeps each file's path under /lib/firmware, whether the
# entry is a single blob or a whole directory.
define FIRMWARE_EXTRA_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware
	$(foreach f,$(FIRMWARE_EXTRA_FILES), \
		cd $(@D) && cp -r --parents $(f) $(TARGET_DIR)/lib/firmware/ ;)
endef

$(eval $(generic-package))
