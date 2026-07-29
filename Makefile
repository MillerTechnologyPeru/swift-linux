# Uniform per-target build interface for Swift Linux.
#
# Every board/arch under sdk/board/ with a board.config gets the same verbs;
# adding a board is dropping a board.config, no Makefile edits.
#
#   make list                       # show the available targets
#   make x86_64-build               # build the image for x86_64
#   make arm64-config               # just (re)configure Buildroot
#   make x86_64-pkg PKG=mesa3d      # rebuild one package
#   make arm64-shell                # interactive shell in the build env
#   make retroid-pocket-5-defconfig # generate a defconfig only
#   make x86_64-clean               # remove that target's output dir
#   make x86_64-refresh             # dirclean recently-changed local packages
#   make arm64-seed                 # pre-populate output from the container's
#                                   # baked toolchain build (fresh trees only)
#
# Backends:
#   (default)     build on the host toolchain (needs a prebuilt output/<arch>).
#   CONTAINER=1   build in the matching per-arch Swift toolchain container, as
#                 your own UID/GID and with the local tree bind-mounted at the
#                 container's /workspaces path - so nothing is left root-owned
#                 and the container's baked paths still resolve. Uses docker or
#                 podman, whichever is on PATH (CONTAINER_RUNTIME= to pick).
#
# Accelerators (see build-images.sh): PARALLEL_BUILD=1, CCACHE=1. Buildroot's
# default download dir (buildroot/dl) is shared across arches already; set
# DL_DIR to override it.

SHELL := /bin/bash
REPO_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BR_SWIFT ?= $(abspath $(REPO_DIR)/../buildroot-swift)
BUILDROOT ?= $(BR_SWIFT)/buildroot
OUTPUT_BASE ?= $(BR_SWIFT)/output
# Buildroot's default download dir ($(TOPDIR)/dl) is already shared across all
# per-arch outputs; only pass BR2_DL_DIR when the caller sets DL_DIR, so a
# prebuilt output's cached downloads keep resolving.
DL_DIR ?=
DL_OPT := $(if $(DL_DIR),BR2_DL_DIR=$(DL_DIR))
CCACHE_DIR ?= $(OUTPUT_BASE)/ccache
EXTERNALS := $(BR_SWIFT):$(REPO_DIR)/external
GENERATE := $(REPO_DIR)/generate-config.sh
PROFILE ?= image
CONTAINER_IMAGE ?= docker.io/colemancda/buildroot-swift
# docker or podman, whichever is on PATH; override with CONTAINER_RUNTIME=.
CONTAINER_RUNTIME ?= $(shell command -v docker || command -v podman)
# Rootless podman maps your UID into a subuid range, so the bind-mounted tree
# would come back owned by a subuid rather than by you; keep-id maps it 1:1.
# Relabelling a Buildroot tree for SELinux (:z) is far too expensive, so opt the
# container out of confinement instead.
# Sniff the version rather than the binary name: podman-docker (and hand-rolled
# shims) put podman behind a /usr/bin/docker, which the name check would miss.
CONTAINER_IS_PODMAN := $(shell $(CONTAINER_RUNTIME) --version 2>/dev/null | grep -qi podman && echo 1)
ifeq ($(CONTAINER_IS_PODMAN),1)
CONTAINER_OPTS ?= --userns=keep-id --security-opt label=disable
else
CONTAINER_OPTS ?=
endif

# $(OUTPUT_BASE) as the *build* sees it. Only BR_SWIFT and REPO_DIR are bind-
# mounted, so a container build's output necessarily lives under the container's
# /workspaces/buildroot-swift; passing the host path through would make Buildroot
# look for a defconfig at a path that does not exist inside the container.
ifeq ($(CONTAINER),1)
BUILD_OUTPUT_BASE := /workspaces/buildroot-swift/output
else
BUILD_OUTPUT_BASE := $(OUTPUT_BASE)
endif

# ---- target discovery ----------------------------------------------------
IMAGE_ARCHES := x86_64 arm64
ALL_BOARD_DIRS := $(notdir $(patsubst %/board.config,%,$(wildcard $(REPO_DIR)/sdk/board/*/board.config)))
DEVICES := $(filter-out $(IMAGE_ARCHES) common,$(ALL_BOARD_DIRS))
TARGETS := $(IMAGE_ARCHES) $(DEVICES)

# generate-config flag: arches select by --arch, devices by --device.
gen_flag = $(if $(filter $(1),$(IMAGE_ARCHES)),--arch $(1),--device $(1))
# container arch for a target (devices are aarch64 today).
cont_arch = $(if $(filter $(1),x86_64),x86_64,arm64)

BR2_MAKE_OPTS :=
ifeq ($(PARALLEL_BUILD),1)
BR2_MAKE_OPTS += -j$(shell nproc) -l$(shell nproc)
endif

# make_defconfig <target>  - write $(OUTPUT_BASE)/<target>.defconfig
define make_defconfig
	@mkdir -p $(OUTPUT_BASE)
	$(GENERATE) $(call gen_flag,$(1)) --profile $(PROFILE) -o $(OUTPUT_BASE)/$(1).defconfig
endef

# br <target> <make-args...>  - run Buildroot for a target, host or container.
# The trees are mounted twice: at the container's baked /workspaces paths (the
# prebuilt toolchain resolves against those) AND at their host paths, because
# generate-config.sh writes host-absolute paths into the defconfig (rootfs
# overlays, kernel config fragments, users tables, post-build scripts) which
# Buildroot then reads at build time.
ifeq ($(CONTAINER),1)
ifeq ($(CONTAINER_RUNTIME),)
$(error CONTAINER=1 needs docker or podman on PATH, or an explicit CONTAINER_RUNTIME=)
endif
define br
	$(CONTAINER_RUNTIME) run --rm $(CONTAINER_OPTS) \
		--user $(shell id -u):$(shell id -g) -e HOME=/tmp \
		-v $(BR_SWIFT):/workspaces/buildroot-swift \
		-v $(REPO_DIR):/workspaces/swift-linux \
		-v $(BR_SWIFT):$(BR_SWIFT) \
		-v $(REPO_DIR):$(REPO_DIR) \
		-w /workspaces/swift-linux $(CONTAINER_IMAGE):swift_$(call cont_arch,$(1))_defconfig \
		bash -lc 'FORCE_UNSAFE_CONFIGURE=1 make -C /workspaces/buildroot-swift/buildroot \
			O=$(BUILD_OUTPUT_BASE)/$(1) \
			BR2_EXTERNAL=/workspaces/buildroot-swift:/workspaces/swift-linux/external \
			$(BR2_MAKE_OPTS) $(2)'
endef
else
define br
	FORCE_UNSAFE_CONFIGURE=1 make -C $(BUILDROOT) O=$(OUTPUT_BASE)/$(1) \
		BR2_EXTERNAL=$(EXTERNALS) $(DL_OPT) BR2_CCACHE_DIR=$(CCACHE_DIR) \
		$(BR2_MAKE_OPTS) $(2)
endef
endif

.PHONY: list help
help list:
	@echo "Targets: $(TARGETS)"
	@echo "Verbs:   <t>-defconfig <t>-config <t>-build <t>-pkg PKG=x <t>-shell <t>-clean <t>-refresh <t>-seed"
	@echo "Backend: CONTAINER=1 for a containerized build ($(if $(CONTAINER_RUNTIME),$(CONTAINER_RUNTIME),no docker/podman found)); PARALLEL_BUILD=1 / CCACHE=1 to accelerate"

# ---- per-target pattern rules -------------------------------------------
# %-defconfig: just generate the defconfig.
$(addsuffix -defconfig,$(TARGETS)): %-defconfig:
	$(call make_defconfig,$*)

# %-config: configure Buildroot from the generated defconfig.
$(addsuffix -config,$(TARGETS)): %-config: %-defconfig
	$(call br,$*,BR2_DEFCONFIG=$(BUILD_OUTPUT_BASE)/$*.defconfig defconfig)

# %-build: build the image (or override with CMD=...).
$(addsuffix -build,$(TARGETS)): %-build: %-config
	$(call br,$*,$(if $(CMD),$(CMD),all))

# %-pkg PKG=name: force-rebuild a single package.
$(addsuffix -pkg,$(TARGETS)): %-pkg:
	@[ -n "$(PKG)" ] || { echo "usage: make $*-pkg PKG=<package>"; exit 1; }
	$(call br,$*,$(PKG)-dirclean $(PKG)-rebuild)

# %-shell: interactive shell in the build environment.
$(addsuffix -shell,$(TARGETS)): %-shell:
	$(call br,$*,BR2_DEFCONFIG=$(BUILD_OUTPUT_BASE)/$*.defconfig defconfig)
	@echo "(shell target is most useful with CONTAINER=1)"

# %-seed: pre-populate a fresh target output dir from the toolchain
# container's baked output, the way CI reuses it - skipping the multi-hour
# from-scratch toolchain and Swift build that an empty tree otherwise
# implies (the CONTAINER=1 bind mount shadows the baked copy, so it has to
# be copied out once). The baked output was built with the container's own
# swift_<arch>_defconfig; the next %-config applies this repo's defconfig
# on top and Buildroot rebuilds only the difference. Refuses to touch an
# existing output dir.
$(addsuffix -seed,$(TARGETS)): %-seed:
	@[ -n "$(CONTAINER_RUNTIME)" ] || { echo "seed needs docker or podman on PATH"; exit 1; }
	@[ ! -e $(OUTPUT_BASE)/$* ] || { echo "$(OUTPUT_BASE)/$* already exists; refusing to overwrite"; exit 1; }
	@mkdir -p $(OUTPUT_BASE)
	cid=$$($(CONTAINER_RUNTIME) create $(CONTAINER_IMAGE):swift_$(call cont_arch,$*)_defconfig) && \
	{ $(CONTAINER_RUNTIME) cp $$cid:/workspaces/buildroot-swift/output/$(call cont_arch,$*) $(OUTPUT_BASE)/$*; \
	  rc=$$?; $(CONTAINER_RUNTIME) rm -f $$cid >/dev/null; exit $$rc; }

# %-clean: remove the target's output dir (keeps shared dl/ccache).
$(addsuffix -clean,$(TARGETS)): %-clean:
	rm -rf $(OUTPUT_BASE)/$* $(OUTPUT_BASE)/$*.defconfig

# %-refresh: dirclean this repo's own (external) packages that changed
# recently in git, then let the next build rebuild them - faster than a full
# clean, more correct than trusting stamps for locally-edited packages.
DAYS ?= 7
$(addsuffix -refresh,$(TARGETS)): %-refresh:
	@pkgs=$$(cd $(REPO_DIR) && git log --since="$(DAYS) days ago" --name-only --pretty=format: \
		-- external/package | sed -n 's,^external/package/\([^/]*\)/.*,\1,p' | sort -u); \
	[ -n "$$pkgs" ] || { echo "no local packages changed in the last $(DAYS) days"; exit 0; }; \
	echo "refreshing: $$pkgs"; \
	for p in $$pkgs; do $(call br,$*,$$p-dirclean) || true; done
