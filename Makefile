# Uniform per-target build interface for Swift Linux.
#
# Every board/arch under sdk/board/ with a board.config gets the same verbs;
# adding a board is dropping a board.config, no Makefile edits.
#
#   make list                       # show the available targets
#   make x86_64-build               # build the image for x86_64
#   make arm64-config               # just (re)configure Buildroot
#   make x86_64-pkg PKG=mesa3d      # rebuild one package
#   make retroid-pocket-5-defconfig # generate a defconfig only
#   make x86_64-clean               # remove that target's output dir
#   make x86_64-refresh             # dirclean recently-changed local packages
#   make arm64-seed                 # pre-populate output/<arch> from the
#                                   # published toolchain (fresh trees only)
#
# Builds run on this host by default; CONTAINER=1 runs the same build inside
# the published base image (Debian 13 + the build prerequisites, no baked
# Buildroot) for hosts that cannot satisfy the prerequisites themselves - see
# the br definition. Either way, an empty output tree means Buildroot builds
# the cross toolchain and host-swift from source, which is hours;
# "make <t>-seed" downloads a prebuilt output/<arch> from the
# toolchain-latest release (built from source by .github/workflows/
# build-toolchain.yml) so only this repo's own packages compile. Seed once per
# architecture, then keep that output tree.
#
# Accelerators (see build-images.sh): PARALLEL_BUILD=1, CCACHE=1. Buildroot's
# default download dir (buildroot/dl) is shared across arches already; set
# DL_DIR to override it.
#
# Buildroot and the package trees are submodules (buildroot/, swift/, ports/);
# every build target checks them out first, or run "make submodules" by hand.

SHELL := /bin/bash
REPO_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
# Buildroot and the two BR2_EXTERNAL trees this repo builds against are git
# submodules, so a checkout pins the exact revisions it was tested with:
#   buildroot/  MillerTechnologyPeru/buildroot        the Buildroot fork
#   swift/      MillerTechnologyPeru/buildroot-swift  the Swift runtime packages
#   ports/      MillerTechnologyPeru/buildroot-ports  apps, games and libraries
# Run "git submodule update --init" (or clone with --recurse-submodules) first.
BUILDROOT ?= $(REPO_DIR)/buildroot
BR_SWIFT ?= $(REPO_DIR)/swift
BR_PORTS ?= $(REPO_DIR)/ports
OUTPUT_BASE ?= $(REPO_DIR)/output
# Buildroot's default download dir ($(TOPDIR)/dl) is already shared across all
# per-arch outputs; only pass BR2_DL_DIR when the caller sets DL_DIR, so a
# prebuilt output's cached downloads keep resolving.
DL_DIR ?=
DL_OPT := $(if $(DL_DIR),BR2_DL_DIR=$(DL_DIR))
CCACHE_DIR ?= $(OUTPUT_BASE)/ccache
EXTERNALS := $(BR_SWIFT):$(BR_PORTS):$(REPO_DIR)/external
GENERATE := $(REPO_DIR)/generate-config.sh
PROFILE ?= image
# Where %-seed fetches prebuilt output trees from: the rolling release that
# build-toolchain.yml publishes, as split .tar.zst parts (release assets cap at
# 2 GiB each, an output tree does not).
TOOLCHAIN_REPO ?= MillerTechnologyPeru/swift-linux
TOOLCHAIN_RELEASE ?= toolchain-latest

# ---- target discovery ----------------------------------------------------
IMAGE_ARCHES := x86_64 arm64
ALL_BOARD_DIRS := $(notdir $(patsubst %/board.config,%,$(wildcard $(REPO_DIR)/sdk/board/*/board.config)))
DEVICES := $(filter-out $(IMAGE_ARCHES) common,$(ALL_BOARD_DIRS))
TARGETS := $(IMAGE_ARCHES) $(DEVICES)

# generate-config flag: arches select by --arch, devices by --device.
gen_flag = $(if $(filter $(1),$(IMAGE_ARCHES)),--arch $(1),--device $(1))
# The toolchain a target seeds from (every device board is aarch64 today).
seed_arch = $(if $(filter $(1),x86_64),x86_64,arm64)

BR2_MAKE_OPTS :=
ifeq ($(PARALLEL_BUILD),1)
BR2_MAKE_OPTS += -j$(shell nproc) -l$(shell nproc)
endif

# make_defconfig <target>  - write $(OUTPUT_BASE)/<target>.defconfig
define make_defconfig
	@mkdir -p $(OUTPUT_BASE)
	$(GENERATE) $(call gen_flag,$(1)) --profile $(PROFILE) -o $(OUTPUT_BASE)/$(1).defconfig
endef

# br <target> <make-args...>  - run Buildroot for a target.
#
# The default is this host. CONTAINER=1 runs the identical invocation inside
# the published base image instead - Debian 13 with the Swift toolchain and
# every Buildroot host prerequisite, and no Buildroot tree or prebuilt output
# baked in (unlike the retired per-arch images, whose GCC 12 could no longer
# build the tree's host tools). For hosts whose own distro cannot satisfy the
# build prerequisites; everything else about the build is the same.
#
# Everything mutable lives on host mounts, nothing lands in the container:
#   - the repo (and with it the buildroot/swift/ports submodules, the
#     generated defconfig and buildroot/dl) at its own host path, because
#     generate-config.sh writes host-absolute paths into the defconfig;
#   - the per-target output at the container root, built as O=/<target>, so
#     the absolute paths Buildroot embeds - and ccache hashes - are the same
#     on every machine and checkout;
#   - the ccache over Buildroot's default BR2_CCACHE_DIR location
#     ($HOME/.buildroot-ccache, and HOME=/tmp here), so the cache dir needs
#     no threading through make variables;
#   - a caller-set DL_DIR at its own path (unset, downloads already land in
#     the repo-mounted buildroot/dl).
ifeq ($(CONTAINER),1)
CONTAINER_IMAGE ?= docker.io/colemancda/buildroot-swift:latest
# docker or podman, whichever is on PATH; override with CONTAINER_RUNTIME=.
CONTAINER_RUNTIME ?= $(shell command -v docker || command -v podman)
ifeq ($(CONTAINER_RUNTIME),)
$(error CONTAINER=1 needs docker or podman on PATH, or an explicit CONTAINER_RUNTIME=)
endif
# Rootless podman maps your UID into a subuid range, so the bind-mounted tree
# would come back owned by a subuid rather than by you; keep-id maps it 1:1.
# Relabelling a Buildroot tree for SELinux (:z) is far too expensive, so opt
# the container out of confinement instead. Sniff the version rather than the
# binary name: podman-docker shims put podman behind /usr/bin/docker.
CONTAINER_IS_PODMAN := $(shell $(CONTAINER_RUNTIME) --version 2>/dev/null | grep -qi podman && echo 1)
ifeq ($(CONTAINER_IS_PODMAN),1)
CONTAINER_OPTS ?= --userns=keep-id --security-opt label=disable
else
CONTAINER_OPTS ?=
endif
define br
	@mkdir -p $(OUTPUT_BASE)/$(1) $(CCACHE_DIR)
	$(CONTAINER_RUNTIME) run --rm $(CONTAINER_OPTS) \
		--user $(shell id -u):$(shell id -g) -e HOME=/tmp \
		-v $(REPO_DIR):$(REPO_DIR) \
		-v $(OUTPUT_BASE):$(OUTPUT_BASE) \
		-v $(OUTPUT_BASE)/$(1):/$(1) \
		-v $(CCACHE_DIR):/tmp/.buildroot-ccache \
		$(if $(DL_DIR),-v $(DL_DIR):$(DL_DIR)) \
		-w /$(1) $(CONTAINER_IMAGE) \
		bash -lc 'FORCE_UNSAFE_CONFIGURE=1 make -C $(BUILDROOT) O=/$(1) \
			BR2_EXTERNAL=$(EXTERNALS) $(DL_OPT) \
			$(BR2_MAKE_OPTS) $(2)'
endef
else
define br
	FORCE_UNSAFE_CONFIGURE=1 make -C $(BUILDROOT) O=$(OUTPUT_BASE)/$(1) \
		BR2_EXTERNAL=$(EXTERNALS) $(DL_OPT) BR2_CCACHE_DIR=$(CCACHE_DIR) \
		$(BR2_MAKE_OPTS) $(2)
endef
endif

.PHONY: list help submodules
help list:
	@echo "Targets: $(TARGETS)"
	@echo "Verbs:   <t>-defconfig <t>-config <t>-build <t>-pkg PKG=x <t>-clean <t>-refresh <t>-seed"
	@echo "Builds run on this host (CONTAINER=1 for the container backend); seed a fresh output tree first (<t>-seed). PARALLEL_BUILD=1 / CCACHE=1 to accelerate"

# submodules: check out buildroot/, swift/ and ports/ if the clone skipped them.
# Every build depends on this, so a plain "git clone" still just works.
submodules:
	@for d in $(BUILDROOT) $(BR_SWIFT) $(BR_PORTS); do \
		[ -e "$$d/Config.in" ] || { echo "checking out submodules..."; \
			git -C $(REPO_DIR) submodule update --init || exit 1; break; }; \
	done

# ---- per-target pattern rules -------------------------------------------
# %-defconfig: just generate the defconfig.
$(addsuffix -defconfig,$(TARGETS)): %-defconfig:
	$(call make_defconfig,$*)

# %-config: configure Buildroot from the generated defconfig.
$(addsuffix -config,$(TARGETS)): %-config: submodules %-defconfig
	$(call br,$*,BR2_DEFCONFIG=$(OUTPUT_BASE)/$*.defconfig defconfig)

# %-build: build the image (or override with CMD=...).
$(addsuffix -build,$(TARGETS)): %-build: %-config
	$(call br,$*,$(if $(CMD),$(CMD),all))

# %-pkg PKG=name: force-rebuild a single package.
$(addsuffix -pkg,$(TARGETS)): %-pkg:
	@[ -n "$(PKG)" ] || { echo "usage: make $*-pkg PKG=<package>"; exit 1; }
	$(call br,$*,$(PKG)-dirclean $(PKG)-rebuild)

# %-seed: pre-populate a fresh output dir with a prebuilt toolchain, skipping
# the multi-hour from-source build of gcc/glibc/host-swift that an empty tree
# implies. The tree comes from the $(TOOLCHAIN_RELEASE) release, built from
# source by .github/workflows/build-toolchain.yml with the sdk profile; the
# next %-config applies this repo's defconfig on top and Buildroot rebuilds
# only the difference.
#
# The asset is split into parts because release assets cap at 2 GiB, so the
# parts are concatenated on the way into tar. Refuses to touch an existing
# output dir: Buildroot stamps absolute paths into a tree, and unpacking over
# a live one would mix two configurations.
$(addsuffix -seed,$(TARGETS)): %-seed:
	@command -v gh >/dev/null || { echo "seed needs the gh CLI"; exit 1; }
	@command -v zstd >/dev/null || { echo "seed needs zstd"; exit 1; }
	@[ ! -e $(OUTPUT_BASE)/$* ] || { echo "$(OUTPUT_BASE)/$* already exists; refusing to overwrite"; exit 1; }
	@mkdir -p $(OUTPUT_BASE)
	@a=$(call seed_arch,$*); tmp=$$(mktemp -d); \
	echo "seeding $* from $(TOOLCHAIN_RELEASE) ($$a toolchain)"; \
	gh release download $(TOOLCHAIN_RELEASE) --repo $(TOOLCHAIN_REPO) \
		--pattern "toolchain-$$a.tar.zst.part*" --dir $$tmp || \
		{ rm -rf $$tmp; echo "no toolchain asset for $$a in $(TOOLCHAIN_RELEASE)"; exit 1; }; \
	cat $$tmp/toolchain-$$a.tar.zst.part* | tar --zstd -x -C $(OUTPUT_BASE) || \
		{ rm -rf $$tmp; exit 1; }; \
	rm -rf $$tmp; \
	[ "$$a" = "$*" ] || mv $(OUTPUT_BASE)/$$a $(OUTPUT_BASE)/$*

# %-clean: remove the target's output dir (keeps shared dl/ccache).
$(addsuffix -clean,$(TARGETS)): %-clean:
	rm -rf $(OUTPUT_BASE)/$* $(OUTPUT_BASE)/$*.defconfig

# %-refresh: dirclean the packages that changed recently in git - this repo's
# own external/package tree plus the ports submodule - then let the next build
# rebuild them: faster than a full clean, more correct than trusting stamps for
# locally-edited packages.
DAYS ?= 7
$(addsuffix -refresh,$(TARGETS)): %-refresh:
	@pkgs=$$({ cd $(REPO_DIR) && git log --since="$(DAYS) days ago" --name-only --pretty=format: \
			-- external/package | sed -n 's,^external/package/\([^/]*\)/.*,\1,p'; \
		cd $(BR_PORTS) 2>/dev/null && git log --since="$(DAYS) days ago" --name-only --pretty=format: \
			-- package | sed -n 's,^package/[^/]*/\([^/]*\)/.*,\1,p'; } | sort -u); \
	[ -n "$$pkgs" ] || { echo "no local packages changed in the last $(DAYS) days"; exit 0; }; \
	echo "refreshing: $$pkgs"; \
	for p in $$pkgs; do $(call br,$*,$$p-dirclean) || true; done
