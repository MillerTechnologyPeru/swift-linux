################################################################################
#
# alsa-topology-conf
#
# Data only: topology descriptions for DSP-routed cards (SOF and similar).
#
################################################################################

ALSA_TOPOLOGY_CONF_VERSION = 1.2.5.1
ALSA_TOPOLOGY_CONF_SOURCE = alsa-topology-conf-$(ALSA_TOPOLOGY_CONF_VERSION).tar.bz2
ALSA_TOPOLOGY_CONF_SITE = https://www.alsa-project.org/files/pub/lib
ALSA_TOPOLOGY_CONF_LICENSE = BSD-3-Clause
ALSA_TOPOLOGY_CONF_LICENSE_FILES = LICENSE

define ALSA_TOPOLOGY_CONF_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/alsa
	cp -a $(@D)/topology $(TARGET_DIR)/usr/share/alsa/
endef

$(eval $(generic-package))
