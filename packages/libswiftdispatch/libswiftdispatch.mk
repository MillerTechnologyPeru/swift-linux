### Grand Central Dispatch
LIBSWIFTDISPATCH_VERSION = $(SWIFT_VERSION)
LIBSWIFTDISPATCH_SOURCE = swift-$(SWIFT_VERSION)-RELEASE.tar.gz
LIBSWIFTDISPATCH_SITE = https://github.com/apple/swift-corelibs-libdispatch/archive/refs/tags
LIBSWIFTDISPATCH_INSTALL_STAGING = YES
LIBSWIFTDISPATCH_INSTALL_TARGET = YES
LIBSWIFTDISPATCH_SUPPORTS_IN_SOURCE_BUILD = NO
LIBSWIFTDISPATCH_DEPENDENCIES = libbsd swift
LIBSWIFTDISPATCH_PATCH = \
	https://gist.githubusercontent.com/colemancda/e19ec96d8b3caa7f4a3f9ec9a82f356a/raw/a8a62d61856de09f02618d32d14ac637017cc44f/libdispatch-5.5.3-armv5.patch

LIBSWIFTDISPATCH_CONF_OPTS += \
    -DLibRT_LIBRARIES="${STAGING_DIR}/usr/lib/librt.a" \
    -DENABLE_SWIFT=YES \
	-DCMAKE_Swift_FLAGS=${SWIFTC_FLAGS} \

ifeq (LIBSWIFTDISPATCH_SUPPORTS_IN_SOURCE_BUILD),YES)
LIBSWIFTDISPATCH_BUILDDIR			= $(LIBSWIFTDISPATCH_SRCDIR)
else
LIBSWIFTDISPATCH_BUILDDIR			= $(LIBSWIFTDISPATCH_SRCDIR)/build
endif

define LIBSWIFTDISPATCH_CONFIGURE_CMDS
	# Clean
	rm -rf $(LIBSWIFTDISPATCH_BUILDDIR)
	rm -rf $(STAGING_DIR)/usr/lib/swift/dispatch
	# Configure for Ninja
	(mkdir -p $(LIBSWIFTDISPATCH_BUILDDIR) && \
	cd $(LIBSWIFTDISPATCH_BUILDDIR) && \
	rm -f CMakeCache.txt && \
	PATH=$(BR_PATH) \
	$(LIBSWIFTDISPATCH_CONF_ENV) $(BR2_CMAKE) -S $(LIBSWIFTDISPATCH_SRCDIR) -B $(LIBSWIFTDISPATCH_BUILDDIR) -G Ninja \
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
		$(LIBSWIFTDISPATCH_CONF_OPTS) \
	)
endef

define LIBSWIFTDISPATCH_BUILD_CMDS
	# Compile
	(cd $(LIBSWIFTDISPATCH_BUILDDIR) && ninja)
endef

define LIBSWIFTDISPATCH_INSTALL_TARGET_CMDS
	(cd $(LIBSWIFTDISPATCH_BUILDDIR) && \
	cp ./*.so $(TARGET_DIR)/usr/lib/ \
	)
endef

define LIBSWIFTDISPATCH_INSTALL_STAGING_CMDS
	# Copy libraries
	cp $(LIBSWIFTDISPATCH_BUILDDIR)/*.so $(STAGING_DIR)/usr/lib/swift/linux/
	# Copy headers
	mkdir -p ${STAGING_DIR}/usr/lib/swift/dispatch
	cp $(LIBSWIFTDISPATCH_SRCDIR)/dispatch/*.h ${STAGING_DIR}/usr/lib/swift/dispatch/ 
	cp $(LIBSWIFTDISPATCH_SRCDIR)/dispatch/module.modulemap ${STAGING_DIR}/usr/lib/swift/dispatch/
	mkdir -p ${STAGING_DIR}/usr/lib/swift/Block
	cp $(LIBSWIFTDISPATCH_SRCDIR)/src/BlocksRuntime/Block.h ${STAGING_DIR}/usr/lib/swift/Block/
	mkdir -p ${STAGING_DIR}/usr/lib/swift/os
	cp $(LIBSWIFTDISPATCH_SRCDIR)/os/object.h ${STAGING_DIR}/usr/lib/swift/os/
	cp $(LIBSWIFTDISPATCH_SRCDIR)/os/generic_unix_base.h ${STAGING_DIR}/usr/lib/swift/os/
	# Copy Swift modules
	cp $(LIBSWIFTDISPATCH_BUILDDIR)/src/swift/swift/* ${STAGING_DIR}/usr/lib/swift/linux/$(SWIFT_TARGET_ARCH)/
endef

$(eval $(generic-package))
