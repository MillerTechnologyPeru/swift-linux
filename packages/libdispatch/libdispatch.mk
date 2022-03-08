### Grand Central Dispatch
LIBDISPATCH_VERSION = $(SWIFT_VERSION)
LIBDISPATCH_SOURCE = swift-$(SWIFT_VERSION)-RELEASE.tar.gz
LIBDISPATCH_SITE = https://github.com/apple/swift-corelibs-libdispatch/archive/refs/tags
LIBDISPATCH_INSTALL_STAGING = YES
LIBDISPATCH_INSTALL_TARGET = YES
LIBDISPATCH_SUPPORTS_IN_SOURCE_BUILD = NO
LIBDISPATCH_DEPENDENCIES = libbsd
LIBDISPATCH_PATCH = \
	https://gist.githubusercontent.com/colemancda/e19ec96d8b3caa7f4a3f9ec9a82f356a/raw/a8a62d61856de09f02618d32d14ac637017cc44f/libdispatch-5.5.3-armv5.patch

LIBDISPATCH_CONF_OPTS += \
    -DLibRT_LIBRARIES="${STAGING_DIR}/usr/lib/librt.a" \

ifeq (LIBDISPATCH_SUPPORTS_IN_SOURCE_BUILD),YES)
LIBDISPATCH_BUILDDIR			= $(LIBDISPATCH_SRCDIR)
else
LIBDISPATCH_BUILDDIR			= $(LIBDISPATCH_SRCDIR)/build
endif

define LIBDISPATCH_CONFIGURE_CMDS
	# Clean
	rm -rf $(LIBDISPATCH_BUILDDIR)
	rm -rf $(STAGING_DIR)/usr/lib/swift/dispatch
	# Configure for Ninja
	(mkdir -p $(LIBDISPATCH_BUILDDIR) && \
	cd $(LIBDISPATCH_BUILDDIR) && \
	rm -f CMakeCache.txt && \
	PATH=$(BR_PATH) \
	$(LIBDISPATCH_CONF_ENV) $(BR2_CMAKE) -S $(LIBDISPATCH_SRCDIR) -B $(LIBDISPATCH_BUILDDIR) -G Ninja \
		-DCMAKE_INSTALL_PREFIX="/usr" \
		-DCMAKE_COLOR_MAKEFILE=OFF \
		-DBUILD_DOC=OFF \
		-DBUILD_DOCS=OFF \
		-DBUILD_EXAMPLE=OFF \
		-DBUILD_EXAMPLES=OFF \
		-DBUILD_TEST=OFF \
		-DBUILD_TESTS=OFF \
		-DBUILD_TESTING=OFF \
		-DBUILD_SHARED_LIBS=ON \
		-DCMAKE_BUILD_TYPE=$(if $(BR2_ENABLE_RUNTIME_DEBUG),Debug,Release) \
    	-DCMAKE_C_COMPILER=$(SWIFT_NATIVE_PATH)/clang \
    	-DCMAKE_CXX_COMPILER=$(SWIFT_NATIVE_PATH)/clang++ \
		-DCMAKE_C_FLAGS="-w -fuse-ld=lld -target $(SWIFT_TARGET_NAME) --sysroot=$(STAGING_DIR) -I$(STAGING_DIR)/usr/include -B$(STAGING_DIR)/usr/lib -B$(HOST_DIR)/lib/gcc/$(GNU_TARGET_NAME)/$(call qstrip,$(BR2_GCC_VERSION)) -L$(HOST_DIR)/lib/gcc/$(GNU_TARGET_NAME)/$(call qstrip,$(BR2_GCC_VERSION))" \
    	-DCMAKE_C_LINK_FLAGS="-target $(SWIFT_TARGET_NAME) --sysroot=$(STAGING_DIR)" \
    	-DCMAKE_CXX_FLAGS="-w -fuse-ld=lld -target $(SWIFT_TARGET_NAME) --sysroot=$(STAGING_DIR) -I$(STAGING_DIR)/usr/include -I$(HOST_DIR)/$(GNU_TARGET_NAME)/include/c++/$(call qstrip,$(BR2_GCC_VERSION))/ -I$(HOST_DIR)/$(GNU_TARGET_NAME)/include/c++/$(call qstrip,$(BR2_GCC_VERSION))/$(GNU_TARGET_NAME) -B$(STAGING_DIR)/usr/lib -B$(HOST_DIR)/lib/gcc/$(GNU_TARGET_NAME)/$(call qstrip,$(BR2_GCC_VERSION)) -L$(HOST_DIR)/lib/gcc/$(GNU_TARGET_NAME)/$(call qstrip,$(BR2_GCC_VERSION))" \
		-DCMAKE_CXX_LINK_FLAGS="-target $(SWIFT_TARGET_NAME) --sysroot=$(STAGING_DIR)" \
		$(LIBDISPATCH_CONF_OPTS) \
	)
endef

define LIBDISPATCH_BUILD_CMDS
	# Compile
	(cd $(LIBDISPATCH_BUILDDIR) && ninja)
endef

define LIBDISPATCH_INSTALL_TARGET_CMDS
	(cd $(LIBDISPATCH_BUILDDIR) && \
	cp ./*.so $(TARGET_DIR)/usr/lib/ \
	)
endef

define LIBDISPATCH_INSTALL_STAGING_CMDS
	# Copy libraries
	cp $(LIBDISPATCH_BUILDDIR)/*.so $(STAGING_DIR)/usr/lib/
	# Copy headers
	mkdir -p ${STAGING_DIR}/usr/include/dispatch
	cp $(LIBDISPATCH_SRCDIR)/dispatch/*.h ${STAGING_DIR}/usr/include/dispatch
	mkdir -p ${STAGING_DIR}/usr/include/Block
	cp $(LIBDISPATCH_SRCDIR)/src/BlocksRuntime/Block.h ${STAGING_DIR}/usr/include/Block/
	mkdir -p ${STAGING_DIR}/usr/include/os
	cp $(LIBDISPATCH_SRCDIR)/os/object.h ${STAGING_DIR}/usr/include/os/
	cp $(LIBDISPATCH_SRCDIR)/os/generic_unix_base.h ${STAGING_DIR}/usr/include/os/
endef

$(eval $(generic-package))
