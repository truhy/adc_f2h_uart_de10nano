# This is free script released into the public domain.
# GNU make file v20241003 created by Truong Hy.
#
# Prepares the U-Boot source files for building U-Boot for the Intel Cyclone V SoC:
#   - uncompress U-Boot source
#   - apply modified U-Boot files (overwrites U-Boot's default)
#   - execute Altera's Python script, which re-generates HPS BSP files for U-Boot (overwrites U-Boot's default)
#
# Dependencies: unzip
#
# Note, as you may already know, U-Boot's make depends on various Linux tools.
# Other OSes such as Windows is not supported natively, for these use WSL, Cygwin or MSYS2.

# These variables are assumed to be set already
ifndef UBOOT_ZIP
$(error UBOOT_ZIP environment variable is not set)
endif
ifndef UBOOT_OUT_PATH
$(error UBOOT_OUT_PATH environment variable not set)
endif
ifndef UBOOT_PATCH_FOLDER
$(error UBOOT_PATCH_FOLDER environment variable not set)
endif
ifndef UBOOT_BSP_GEN_FOLDER
$(error UBOOT_BSP_GEN_FOLDER environment variable not set)
endif
ifndef UBOOT_DEFCONFIG
$(error UBOOT_DEFCONFIG environment variable not set)
endif
ifndef UBOOT_QTS_FOLDER
$(error UBOOT_QTS_FOLDER environment variable not set)
endif

# Check if unzip command exists
ifeq (,$(shell which unzip))
$(error "Command 'unzip' not found")
endif

# =====
# Paths
# =====

DBG_UBOOT_OUT_PATH := $(UBOOT_OUT_PATH)/Debug
REL_UBOOT_OUT_PATH := $(UBOOT_OUT_PATH)/Release
DBG_UBOOT_SRC_PATH := $(DBG_UBOOT_OUT_PATH)/u-boot
REL_UBOOT_SRC_PATH := $(REL_UBOOT_OUT_PATH)/u-boot

# ================================
# U-Boot replacment modified files
# ================================

DBG_SRC_FILE1 := Debug/$(UBOOT_PATCH_FOLDER)/$(UBOOT_DEFCONFIG)
DBG_DST_FILE1 := $(DBG_UBOOT_SRC_PATH)/configs/$(UBOOT_DEFCONFIG)
REL_SRC_FILE1 := Release/$(UBOOT_PATCH_FOLDER)/$(UBOOT_DEFCONFIG)
REL_DST_FILE1 := $(REL_UBOOT_SRC_PATH)/configs/$(UBOOT_DEFCONFIG)

# ============
# BSP settings
# ============

ALTERA_BSP_SCRIPT := $(UBOOT_BSP_GEN_FOLDER)/cv_bsp_generator.py
HANDOFF := hps_isw_handoff/soc_system_hps_0
DBG_UBOOT_QTS_PATH := $(DBG_UBOOT_SRC_PATH)/$(UBOOT_QTS_FOLDER)
REL_UBOOT_QTS_PATH := $(REL_UBOOT_SRC_PATH)/$(UBOOT_QTS_FOLDER)

# ==========================================================================================
# Dummy prep file so that we have a timestamp for satisfying GNU make's prerequite condition
# ==========================================================================================

DBG_UBOOT_SRC_DUMMY := $(DBG_UBOOT_SRC_PATH)/_dummy_prep.txt
REL_UBOOT_SRC_DUMMY := $(REL_UBOOT_SRC_PATH)/_dummy_prep.txt

# ===========================
# Miscellaneous support tools
# ===========================

UZ := unzip

# =====
# Rules
# =====

.PHONY: all release debug clean

# Default
all: release

# Clean sublevel 1 folder
clean1:
	@if [ -d "$(DBG_UBOOT_SRC_PATH)" ]; then echo rm -rf $(DBG_UBOOT_SRC_PATH); rm -rf $(DBG_UBOOT_SRC_PATH); fi
	@if [ -d "$(REL_UBOOT_SRC_PATH)" ]; then echo rm -rf $(REL_UBOOT_SRC_PATH); rm -rf $(REL_UBOOT_SRC_PATH); fi
	@if [ -d "$(DBG_UBOOT_OUT_PATH)" ] && [ -z "$$(ls -A $(DBG_UBOOT_OUT_PATH))" ]; then echo rm -df $(DBG_UBOOT_OUT_PATH); rm -df $(DBG_UBOOT_OUT_PATH); fi
	@if [ -d "$(REL_UBOOT_OUT_PATH)" ] && [ -z "$$(ls -A $(REL_UBOOT_OUT_PATH))" ]; then echo rm -df $(REL_UBOOT_OUT_PATH); rm -df $(REL_UBOOT_OUT_PATH); fi

# Clean root folder
clean: clean1
	@if [ -d "$(UBOOT_OUT_PATH)" ] && [ -z "$$(ls -A $(UBOOT_OUT_PATH))" ]; then echo rm -df $(UBOOT_OUT_PATH); rm -df $(UBOOT_OUT_PATH); fi

# =============
# Release rules
# =============

release: $(REL_DST_FILE1) $(REL_UBOOT_QTS_PATH)/pll_config.h

# Uncompress U-Boot source
$(REL_UBOOT_SRC_PATH)/Makefile:
	mkdir -p $(REL_UBOOT_OUT_PATH)
	$(UZ) $(UBOOT_ZIP) -d $(REL_UBOOT_OUT_PATH)

# Rename folder to a common name and create prep txt
$(REL_UBOOT_SRC_DUMMY): $(REL_UBOOT_SRC_PATH)/Makefile
	$(eval FIND_REL_UBOOT_SRC_PATH := $(shell find $(REL_UBOOT_OUT_PATH)/u*boot* -maxdepth 0 -mindepth 0 -type d))
	mv $(FIND_REL_UBOOT_SRC_PATH) $(REL_UBOOT_SRC_PATH)
	@echo "U-Boot source: $(UBOOT_ZIP)" > $(REL_UBOOT_SRC_DUMMY)

# Apply modified files
$(REL_DST_FILE1): $(REL_UBOOT_SRC_DUMMY)
	cp -f $(REL_SRC_FILE1) $(REL_DST_FILE1)

# Apply BSP files
$(REL_UBOOT_QTS_PATH)/pll_config.h: $(REL_UBOOT_SRC_DUMMY) $(HANDOFF)/hps.xml
	python3 $(ALTERA_BSP_SCRIPT) -i $(HANDOFF) -o $(REL_UBOOT_QTS_PATH)

# ===========
# Debug rules
# ===========

debug: $(DBG_DST_FILE1) $(DBG_UBOOT_QTS_PATH)/pll_config.h

# Uncompress U-Boot source
$(DBG_UBOOT_SRC_PATH)/Makefile:
	mkdir -p $(DBG_UBOOT_OUT_PATH)
	$(UZ) $(UBOOT_ZIP) -d $(DBG_UBOOT_OUT_PATH)

# Rename folder to a common name and create prerequite dummy file
$(DBG_UBOOT_SRC_DUMMY): $(DBG_UBOOT_SRC_PATH)/Makefile
	$(eval FIND_DBG_UBOOT_SRC_PATH := $(shell find $(DBG_UBOOT_OUT_PATH)/u*boot* -maxdepth 0 -mindepth 0 -type d))
	mv $(FIND_DBG_UBOOT_SRC_PATH) $(DBG_UBOOT_SRC_PATH)
	@echo "U-Boot source: $(UBOOT_ZIP)" > $(DBG_UBOOT_SRC_DUMMY)

# Apply modified files
$(DBG_DST_FILE1): $(DBG_UBOOT_SRC_DUMMY)
	cp -f $(DBG_SRC_FILE1) $(DBG_DST_FILE1)

# Apply BSP files
$(DBG_UBOOT_QTS_PATH)/pll_config.h: $(DBG_UBOOT_SRC_DUMMY) $(HANDOFF)/hps.xml
	python3 $(ALTERA_BSP_SCRIPT) -i $(HANDOFF) -o $(DBG_UBOOT_QTS_PATH)
