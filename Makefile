# This is free script released into the public domain.
# GNU make file v20241019 created by Truong Hy.
#
# Builds SD card image for the Intel Cyclone V SoCFPGA.
# Depending on the options it will output the following application files:
#   - SD card image (.img)
#   - U-Boot image (.uimg)
#
# For usage, type make help
#
# Linux requirements (tested only under Ubuntu):
#   - Bash command-line utilities
#
# Windows limitations:
#   - Natively supports building the C/C++ sources into elf, bin or uimg
#   - Natively does not support building the SD card image and U-Boot, for these use WSL2, Cygwin or MSYS2
#
# Common requirements:
#   - GCC ARM cross compiler toolchain.  The bin directory added to the search path
#   - GNU make (for Windows use xPack's build tools).  The bin directory added to the search path
#
# U-Boot preparation and SD card image requirements, please see the makefiles:
#   - Makefile-prep-ub.mk
#   - Makefile-sd-alt.mk
#   - Makefile-sd-tru.mk
#
# U-Boot's own build dependencies on a fresh Ubuntu 22.04.3 LTS distro:
#   - GNU make
#   - GCC ARM cross compiler toolchain (for building target U-Boot)
#   - gcc (for building host tools)
#   - bison
#   - flex
#   - libssl-dev
#   - bc
#
# This makefile is already complicated, but to keep things a bit more simple:
#   - We assume the required global variables are already set
#   - We assume the required files and paths are relative to the location of this Makefile

# Optional commandline parameters
ub ?= 0
alt ?= 0

ifeq ($(OS),Windows_NT)
$(error Building SD card image is not supported natively in Windows, use WSL2, Cygwin or MSYS2)
endif

# These variables are assumed to be set already
ifndef APP_OUT_PATH
$(error APP_OUT_PATH environment variable is not set)
endif

ifndef APP_OUT_FULL_PATH
$(error APP_OUT_FULL_PATH environment variable is not set)
endif

ifndef SD_PROGRAM_NAME
$(error SD_PROGRAM_NAME environment variable is not set)
endif

ifeq ($(ub),1)
ifndef UBOOT_DEFCONFIG
$(error UBOOT_DEFCONFIG env. variable not set, e.g. export UBOOT_DEFCONFIG=socfpga_de10_nano_defconfig)
endif
ifndef UBOOT_OUT_PATH
$(error UBOOT_OUT_PATH env. variable not set)
endif
endif

ifndef SD_OUT_PATH
$(error SD_OUT_PATH environment variable is not set)
endif

# Convert back-slashes
ifeq ($(OS),Windows_NT)
APP_OUT_PATH := $(subst \,/,$(APP_OUT_PATH))
APP_OUT_FULL_PATH := $(subst \,/,$(APP_OUT_FULL_PATH))
UBOOT_OUT_PATH := $(subst \,/,$(UBOOT_OUT_PATH))
SD_OUT_PATH := $(subst \,/,$(SD_OUT_PATH))
endif

# Export some SD card image environment variables
SDENVFILE := scripts-env/env-sd.sh
include scripts-linux/sdcard/Makefile-sd-env.mk

# ===============
# Common settings
# ===============

UBOOT_IN_PATH := scripts-linux/uboot
SD_IN_PATH := scripts-linux/sdcard

# ============
# App settings
# ============

DBG_PATH1 := $(APP_OUT_PATH)/Debug
DBG_FULL_PATH1 := $(APP_OUT_FULL_PATH)/Debug

REL_PATH1 := $(APP_OUT_PATH)/Release
REL_FULL_PATH1 := $(APP_OUT_FULL_PATH)/Release

# =======================
# U-Boot settings (Debug)
# =======================

DBG_UBOOT_IN_PATH := $(UBOOT_IN_PATH)/Debug
DBG_UBOOT_OUT_PATH := $(UBOOT_OUT_PATH)/Debug
DBG_UBOOT_SRC_PATH := $(DBG_UBOOT_OUT_PATH)/u-boot
DBG_UBOOT_SUB_PATH := $(DBG_UBOOT_OUT_PATH)/ub-out

DBG_UBOOT_SCRTXT_HDR := $(DBG_UBOOT_IN_PATH)/u-boot.scr.hdr.txt
DBG_UBOOT_SCRTXT_FTR := $(DBG_UBOOT_IN_PATH)/u-boot.scr.ftr.txt
DBG_UBOOT_SFP := $(DBG_UBOOT_IN_PATH)/u-boot-with-spl.sfp
DBG_UBOOT_SCRTXT := $(DBG_UBOOT_SUB_PATH)/u-boot.scr.txt
DBG_UBOOT_SCR := $(DBG_UBOOT_SUB_PATH)/u-boot.scr

# Append U-boot script with these lines
DBG_UBOOT_SCRTXT_L1_STR := if test -e mmc $(SDFATDEVPART) c5_fpga.rbf; then
DBG_UBOOT_SCRTXT_L2_STR := fatload mmc $(SDFATDEVPART) \$${loadaddr} c5_fpga.rbf
DBG_UBOOT_SCRTXT_L3_STR := fpga load 0 \$${loadaddr} \$${filesize}
DBG_UBOOT_SCRTXT_L4_STR := fi
DBG_UBOOT_SCRTXT_L5_STR := bridge enable

# =========================
# U-Boot settings (Release)
# =========================

REL_UBOOT_IN_PATH := $(UBOOT_IN_PATH)/Release
REL_UBOOT_OUT_PATH := $(UBOOT_OUT_PATH)/Release
REL_UBOOT_SRC_PATH := $(REL_UBOOT_OUT_PATH)/u-boot
REL_UBOOT_SUB_PATH := $(REL_UBOOT_OUT_PATH)/ub-out

REL_UBOOT_SCRTXT_HDR := $(REL_UBOOT_IN_PATH)/u-boot.scr.hdr.txt
REL_UBOOT_SCRTXT_FTR := $(REL_UBOOT_IN_PATH)/u-boot.scr.ftr.txt
REL_UBOOT_SFP := $(REL_UBOOT_IN_PATH)/u-boot-with-spl.sfp
REL_UBOOT_SCRTXT := $(REL_UBOOT_SUB_PATH)/u-boot.scr.txt
REL_UBOOT_SCR := $(REL_UBOOT_SUB_PATH)/u-boot.scr

# Append U-boot script with these lines
REL_UBOOT_SCRTXT_L1_STR := if test -e mmc $(SDFATDEVPART) c5_fpga.rbf; then
REL_UBOOT_SCRTXT_L2_STR := fatload mmc $(SDFATDEVPART) \$${loadaddr} c5_fpga.rbf
REL_UBOOT_SCRTXT_L3_STR := fpga load 0 \$${loadaddr} \$${filesize}
REL_UBOOT_SCRTXT_L4_STR := fi
REL_UBOOT_SCRTXT_L5_STR := bridge enable

# =====================================
# SD card image partition files (Debug)
# =====================================

DBG_SD_OUT_PATH := $(SD_OUT_PATH)/Debug
DBG_SD_OUT_SUB_PATH := $(DBG_SD_OUT_PATH)/sd-out
DBG_SD_CP_PATH := $(DBG_FULL_PATH1)/sd-out
DBG_SD_IMG := $(DBG_SD_OUT_SUB_PATH)/$(SD_PROGRAM_NAME).sd.img
DBG_SDCP_IMG := $(DBG_SD_CP_PATH)/$(SD_PROGRAM_NAME).sd.img
# Intermediate files to copy into the SD image
DBG_SD_SCR := $(addprefix $(DBG_SD_OUT_SUB_PATH)/$(SDFATFOLDER)/,$(notdir $(DBG_UBOOT_SCR)))
DBG_SD_UIMG := $(addprefix $(DBG_SD_OUT_SUB_PATH)/$(SDFATFOLDER)/,$(notdir $(DBG_UIMG1)))
DBG_SD_BIN :=  $(addprefix $(DBG_SD_OUT_SUB_PATH)/$(SDFATFOLDER)/,$(notdir $(DBG_BIN1)))
DBG_SD_SFP := $(addprefix $(DBG_SD_OUT_SUB_PATH)/$(SDA2FOLDER)/,$(notdir $(DBG_UBOOT_SFP)))
DBG_SD_APP_FMT := $(DBG_SD_OUT_SUB_PATH)/sd_app_fmt.txt
DBG_SD_FPGA_SRC := $(SD_IN_PATH)/Debug/c5_fpga.rbf
DBG_SD_FPGA := $(addprefix $(DBG_SD_OUT_SUB_PATH)/$(SDFATFOLDER)/,$(notdir $(DBG_SD_FPGA_SRC)))

# Partition 1 user files to copy into the SD image
ifeq ($(SDP1EXISTS),y)
DBG_SD_P1UF_SRC := $(wildcard $(SD_IN_PATH)/Debug/p1/*)
DBG_SD_P1UF := $(addprefix $(DBG_SD_OUT_SUB_PATH)/p1/,$(notdir $(DBG_SD_P1UF_SRC)))
endif
# Partition 2 user files to copy into the SD image
ifeq ($(SDP2EXISTS),y)
DBG_SD_P2UF_SRC := $(wildcard $(SD_IN_PATH)/Debug/p2/*)
DBG_SD_P2UF := $(addprefix $(DBG_SD_OUT_SUB_PATH)/p2/,$(notdir $(DBG_SD_P2UF_SRC)))
endif
# Partition 3 user files to copy into the SD image
ifeq ($(SDP3EXISTS),y)
DBG_SD_P3UF_SRC := $(wildcard $(SD_IN_PATH)/Debug/p3/*)
DBG_SD_P3UF := $(addprefix $(DBG_SD_OUT_SUB_PATH)/p3/,$(notdir $(DBG_SD_P3UF_SRC)))
endif
# Partition 4 user files to copy into the SD image
ifeq ($(SDP4EXISTS),y)
DBG_SD_P4UF_SRC := $(wildcard $(SD_IN_PATH)/Debug/p4/*)
DBG_SD_P4UF := $(addprefix $(DBG_SD_OUT_SUB_PATH)/p4/,$(notdir $(DBG_SD_P4UF_SRC)))
endif

# =======================================
# SD card image partition files (Release)
# =======================================

REL_SD_OUT_PATH := $(SD_OUT_PATH)/Release
REL_SD_OUT_SUB_PATH := $(REL_SD_OUT_PATH)/sd-out
REL_SD_CP_PATH := $(REL_FULL_PATH1)/sd-out
REL_SD_IMG := $(REL_SD_OUT_SUB_PATH)/$(SD_PROGRAM_NAME).sd.img
REL_SDCP_IMG := $(REL_SD_CP_PATH)/$(SD_PROGRAM_NAME).sd.img
# Intermediate files to copy into the SD image
REL_SD_SCR := $(addprefix $(REL_SD_OUT_SUB_PATH)/$(SDFATFOLDER)/,$(notdir $(REL_UBOOT_SCR)))
REL_SD_UIMG := $(addprefix $(REL_SD_OUT_SUB_PATH)/$(SDFATFOLDER)/,$(notdir $(REL_UIMG1)))
REL_SD_BIN :=  $(addprefix $(REL_SD_OUT_SUB_PATH)/$(SDFATFOLDER)/,$(notdir $(REL_BIN1)))
REL_SD_SFP := $(addprefix $(REL_SD_OUT_SUB_PATH)/$(SDA2FOLDER)/,$(notdir $(REL_UBOOT_SFP)))
REL_SD_APP_FMT := $(REL_SD_OUT_SUB_PATH)/sd_app_fmt.txt
REL_SD_FPGA_SRC := $(SD_IN_PATH)/Release/c5_fpga.rbf
REL_SD_FPGA := $(addprefix $(REL_SD_OUT_SUB_PATH)/$(SDFATFOLDER)/,$(notdir $(REL_SD_FPGA_SRC)))

# Partition 1 user files to copy into the SD image
ifeq ($(SDP1EXISTS),y)
REL_SD_P1UF_SRC := $(wildcard $(SD_IN_PATH)/Release/p1/*)
REL_SD_P1UF := $(addprefix $(REL_SD_OUT_SUB_PATH)/p1/,$(notdir $(REL_SD_P1UF_SRC)))
endif
# Partition 2 user files to copy into the SD image
ifeq ($(SDP2EXISTS),y)
REL_SD_P2UF_SRC := $(wildcard $(SD_IN_PATH)/Release/p2/*)
REL_SD_P2UF := $(addprefix $(REL_SD_OUT_SUB_PATH)/p2/,$(notdir $(REL_SD_P2UF_SRC)))
endif
# Partition 3 user files to copy into the SD image
ifeq ($(SDP3EXISTS),y)
REL_SD_P3UF_SRC := $(wildcard $(SD_IN_PATH)/Release/p3/*)
REL_SD_P3UF := $(addprefix $(REL_SD_OUT_SUB_PATH)/p3/,$(notdir $(REL_SD_P3UF_SRC)))
endif
# Partition 4 user files to copy into the SD image
ifeq ($(SDP4EXISTS),y)
REL_SD_P4UF_SRC := $(wildcard $(SD_IN_PATH)/Release/p4/*)
REL_SD_P4UF := $(addprefix $(REL_SD_OUT_SUB_PATH)/p4/,$(notdir $(REL_SD_P4UF_SRC)))
endif

# ===========================
# Miscellaneous support tools
# ===========================

MK := mkimage

# ===========
# Build rules
# ===========

# Options
.PHONY: all help release debug clean cleantemp

# Default build
all: release

# Dummy force always rule
FORCE:
	

help:
	@echo "Builds the SD card image"
	@echo "Usage:"
	@echo "  make [targets] [options]"
	@echo ""
	@echo "Targets:"
	@echo "  release       Build SD card image Release (default)"
	@echo "  debug         Build SD card image Debug"
	@echo "  clean         Delete all built files"
	@echo "  cleantemp     Clean except target files"
	@echo "Options to use with target:"
	@echo "  ub=1          Force rebuild U-Boot sources"
	@echo "  alt=1         Use Altera's SD card image script"

# ===========
# Clean rules
# ===========

# Clean U-Boot folder
clean_ub:
ifneq ($(OS),Windows_NT)
	@if [ -d "$(UBOOT_OUT_PATH)" ]; then \
		if [ -d "$(DBG_UBOOT_SUB_PATH)" ]; then echo rm -rf "$(DBG_UBOOT_SUB_PATH)"; rm -rf "$(DBG_UBOOT_SUB_PATH)"; fi; \
		if [ -d "$(REL_UBOOT_SUB_PATH)" ]; then echo rm -rf "$(REL_UBOOT_SUB_PATH)"; rm -rf "$(REL_UBOOT_SUB_PATH)"; fi; \
		if [ -d "$(DBG_UBOOT_SRC_PATH)/Makefile)" ]; then make -C "$(DBG_UBOOT_SRC_PATH)" --no-print-directory clean; fi; \
		make -C "$(UBOOT_IN_PATH)" --no-print-directory -f Makefile-prep-ub.mk clean; \
	fi
endif

# Clean SD folder
clean_sd:
ifneq ($(OS),Windows_NT)
ifeq ($(alt),1)
	@if [ -d "$(SD_OUT_PATH)" ]; then make -C "$(SD_IN_PATH)" --no-print-directory -f Makefile-sd-alt.mk clean; fi
else
	@if [ -d "$(SD_OUT_PATH)" ]; then make -C "$(SD_IN_PATH)" --no-print-directory -f Makefile-sd-tru.mk clean; fi
endif
endif

# Clean sublevel 1 folder
clean_1:
	@if [ -d "$(DBG_PATH1)" ]; then echo rm -rf "$(DBG_PATH1)"; rm -rf "$(DBG_PATH1)"; fi
	@if [ -d "$(REL_PATH1)" ]; then echo rm -rf "$(REL_PATH1)"; rm -rf "$(REL_PATH1)"; fi

# Clean root folder
clean: clean_ub clean_sd clean_1
	@if [ -d "$(APP_OUT_PATH)" ] && [ -z "$$(ls -A $(APP_OUT_PATH))" ]; then echo rm -df "$(APP_OUT_PATH)"; rm -df "$(APP_OUT_PATH)"; fi

# ===============================================================
# Clean temporary files rules (does not remove user target files)
# ===============================================================

# Clean U-Boot folder
cleantemp_ub:
ifneq ($(OS),Windows_NT)
	@if [ -d "$(UBOOT_OUT_PATH)" ]; then \
		if [ -f "$(DBG_UBOOT_SCRTXT)" ]; then echo rm -f "$(DBG_UBOOT_SCRTXT)"; rm -f "$(DBG_UBOOT_SCRTXT)"; fi; \
		if [ -f "$(DBG_UBOOT_SCR)" ]; then echo rm -f "$(DBG_UBOOT_SCR)"; rm -f "$(DBG_UBOOT_SCR)"; fi; \
		if [ -f "$(REL_UBOOT_SCRTXT)" ]; then echo rm -f "$(REL_UBOOT_SCRTXT)"; rm -f "$(REL_UBOOT_SCRTXT)"; fi; \
		if [ -f "$(REL_UBOOT_SCR)" ]; then echo rm -f "$(REL_UBOOT_SCR)"; rm -f "$(REL_UBOOT_SCR)"; fi; \
		if [ -d "$(DBG_UBOOT_SUB_PATH)" ]; then echo rm -rf "$(DBG_UBOOT_SUB_PATH)"; rm -rf "$(DBG_UBOOT_SUB_PATH)"; fi; \
		if [ -d "$(REL_UBOOT_SUB_PATH)" ]; then echo rm -rf "$(REL_UBOOT_SUB_PATH)"; rm -rf "$(REL_UBOOT_SUB_PATH)"; fi; \
		if [ -d "$(DBG_UBOOT_SRC_PATH)/Makefile)" ]; then make -C "$(DBG_UBOOT_SRC_PATH)" --no-print-directory clean; fi; \
		make -C "$(UBOOT_IN_PATH)" --no-print-directory -f Makefile-prep-ub.mk clean; \
	fi
endif

# Clean SD folder
cleantemp_sd:
ifneq ($(OS),Windows_NT)
	@if [ -d "$(DBG_SD_OUT_SUB_PATH)" ]; then \
		if [ -d "$(DBG_SD_OUT_SUB_PATH)/p1" ]; then echo rm -rf "$(DBG_SD_OUT_SUB_PATH)/p1"; rm -rf "$(DBG_SD_OUT_SUB_PATH)/p1"; fi; \
		if [ -d "$(DBG_SD_OUT_SUB_PATH)/p2" ]; then echo rm -rf "$(DBG_SD_OUT_SUB_PATH)/p2"; rm -rf "$(DBG_SD_OUT_SUB_PATH)/p2"; fi; \
		if [ -d "$(DBG_SD_OUT_SUB_PATH)/p3" ]; then echo rm -rf "$(DBG_SD_OUT_SUB_PATH)/p3"; rm -rf "$(DBG_SD_OUT_SUB_PATH)/p3"; fi; \
		if [ -d "$(DBG_SD_OUT_SUB_PATH)/p4" ]; then echo rm -rf "$(DBG_SD_OUT_SUB_PATH)/p4"; rm -rf "$(DBG_SD_OUT_SUB_PATH)/p4"; fi; \
		if [ -d "$(DBG_SD_OUT_SUB_PATH)/p1m" ]; then echo rm -rf "$(DBG_SD_OUT_SUB_PATH)/p1m"; rm -rf "$(DBG_SD_OUT_SUB_PATH)/p1m"; fi; \
		if [ -d "$(DBG_SD_OUT_SUB_PATH)/p2m" ]; then echo rm -rf "$(DBG_SD_OUT_SUB_PATH)/p2m"; rm -rf "$(DBG_SD_OUT_SUB_PATH)/p2m"; fi; \
		if [ -d "$(DBG_SD_OUT_SUB_PATH)/p3m" ]; then echo rm -rf "$(DBG_SD_OUT_SUB_PATH)/p3m"; rm -rf "$(DBG_SD_OUT_SUB_PATH)/p3m"; fi; \
		if [ -d "$(DBG_SD_OUT_SUB_PATH)/p4m" ]; then echo rm -rf "$(DBG_SD_OUT_SUB_PATH)/p4m"; rm -rf "$(DBG_SD_OUT_SUB_PATH)/p4m"; fi; \
	fi
	@if [ -d "$(REL_SD_OUT_SUB_PATH)" ]; then \
		if [ -d "$(REL_SD_OUT_SUB_PATH)/p1" ]; then echo rm -rf "$(REL_SD_OUT_SUB_PATH)/p1"; rm -rf "$(REL_SD_OUT_SUB_PATH)/p1"; fi; \
		if [ -d "$(REL_SD_OUT_SUB_PATH)/p2" ]; then echo rm -rf "$(REL_SD_OUT_SUB_PATH)/p2"; rm -rf "$(REL_SD_OUT_SUB_PATH)/p2"; fi; \
		if [ -d "$(REL_SD_OUT_SUB_PATH)/p3" ]; then echo rm -rf "$(REL_SD_OUT_SUB_PATH)/p3"; rm -rf "$(REL_SD_OUT_SUB_PATH)/p3"; fi; \
		if [ -d "$(REL_SD_OUT_SUB_PATH)/p4" ]; then echo rm -rf "$(REL_SD_OUT_SUB_PATH)/p4"; rm -rf "$(REL_SD_OUT_SUB_PATH)/p4"; fi; \
		if [ -d "$(REL_SD_OUT_SUB_PATH)/p1m" ]; then echo rm -rf "$(REL_SD_OUT_SUB_PATH)/p1m"; rm -rf "$(REL_SD_OUT_SUB_PATH)/p1m"; fi; \
		if [ -d "$(REL_SD_OUT_SUB_PATH)/p2m" ]; then echo rm -rf "$(REL_SD_OUT_SUB_PATH)/p2m"; rm -rf "$(REL_SD_OUT_SUB_PATH)/p2m"; fi; \
		if [ -d "$(REL_SD_OUT_SUB_PATH)/p3m" ]; then echo rm -rf "$(REL_SD_OUT_SUB_PATH)/p3m"; rm -rf "$(REL_SD_OUT_SUB_PATH)/p3m"; fi; \
		if [ -d "$(REL_SD_OUT_SUB_PATH)/p4m" ]; then echo rm -rf "$(REL_SD_OUT_SUB_PATH)/p4m"; rm -rf "$(REL_SD_OUT_SUB_PATH)/p4m"; fi; \
	fi
ifeq ($(alt),1)
	@if [ -d "$(SD_OUT_PATH)" ]; then make -C "$(SD_IN_PATH)" --no-print-directory -f Makefile-sd-alt.mk clean; fi
else
	@if [ -d "$(SD_OUT_PATH)" ]; then make -C "$(SD_IN_PATH)" --no-print-directory -f Makefile-sd-tru.mk clean; fi
endif
endif

# Clean root folder
cleantemp: cleantemp_ub cleantemp_sd
	@if [ -d "$(APP_OUT_PATH)" ]; then \
		if [ -f "$(DBG_UBOOT_SCRTXT)" ]; then echo rm -f "$(DBG_UBOOT_SCRTXT)"; rm -f "$(DBG_UBOOT_SCRTXT)"; fi; \
		if [ -f "$(DBG_UBOOT_SCR)" ]; then echo rm -f "$(DBG_UBOOT_SCR)"; rm -f "$(DBG_UBOOT_SCR)"; fi; \
		if [ -f "$(REL_UBOOT_SCRTXT)" ]; then echo rm -f "$(REL_UBOOT_SCRTXT)"; rm -f "$(REL_UBOOT_SCRTXT)"; fi; \
		if [ -f "$(REL_UBOOT_SCR)" ]; then echo rm -f "$(REL_UBOOT_SCR)"; rm -f "$(REL_UBOOT_SCR)"; fi; \
	fi

# ===========
# Build rules
# ===========

# =================
# Top level targets
# =================

debug: $(DBG_SD_IMG)

release: $(REL_SD_IMG)

ifeq ($(ub),1)
debug: dbg_update_uboot
release: rel_update_uboot
endif

# ===============
# Build app rules
# ===============

# ======================================================================
# Build a list of prerequisites for fundamental changes on SD card image
# ======================================================================

# Add prerequisite to list
DBG_SD_FUND_PRE := $(DBG_SD_FUND_PRE) $(DBG_SD_P1UF_SRC) $(DBG_SD_P2UF_SRC) $(DBG_SD_P3UF_SRC) $(DBG_SD_P4UF_SRC) $(SDENVFILE)
REL_SD_FUND_PRE := $(REL_SD_FUND_PRE) $(REL_SD_P1UF_SRC) $(REL_SD_P2UF_SRC) $(REL_SD_P3UF_SRC) $(REL_SD_P4UF_SRC) $(SDENVFILE)

# =====================================================
# Build a list of prerequisites for U-Boot script rules
# =====================================================

# Add prerequisite to list
ifneq (,$(wildcard $(DBG_UBOOT_SCRTXT_HDR)))
DBG_SCR_PRE := $(DBG_SCR_PRE) $(DBG_UBOOT_SCRTXT_HDR)
endif
ifneq (,$(wildcard $(REL_UBOOT_SCRTXT_HDR)))
DBG_SCR_PRE := $(DBG_SCR_PRE) $(REL_UBOOT_SCRTXT_HDR)
endif

# Add prerequisite to list
ifneq (,$(wildcard $(DBG_UBOOT_SCRTXT_FTR)))
DBG_SCR_PRE := $(DBG_SCR_PRE) $(DBG_UBOOT_SCRTXT_FTR)
endif
ifneq (,$(wildcard $(REL_UBOOT_SCRTXT_FTR)))
REL_SCR_PRE := $(REL_SCR_PRE) $(REL_UBOOT_SCRTXT_FTR)
endif

# Add prerequisite to list
# Fundamental changes to SD card image should also rebuild U-Boot script
DBG_SCR_PRE := $(DBG_SCR_PRE) $(DBG_SD_FUND_PRE)
REL_SCR_PRE := $(REL_SCR_PRE) $(REL_SD_FUND_PRE)

# ===================
# U-boot script rules
# ===================

# Create U-Boot text script
$(DBG_UBOOT_SCRTXT): $(DBG_SCR_PRE)
	@mkdir -p "$(DBG_UBOOT_SUB_PATH)"
	@if [ -f "$(DBG_UBOOT_SCRTXT_HDR)" ]; then cp -f "$(DBG_UBOOT_SCRTXT_HDR)" "$@"; else rm -f "$@"; fi
	@if [ -n "$(DBG_UBOOT_SCRTXT_L1_STR)" ]; then echo "$(DBG_UBOOT_SCRTXT_L1_STR)" >> "$@"; fi
	@if [ -n "$(DBG_UBOOT_SCRTXT_L2_STR)" ]; then echo "$(DBG_UBOOT_SCRTXT_L2_STR)" >> "$@"; fi
	@if [ -n "$(DBG_UBOOT_SCRTXT_L3_STR)" ]; then echo "$(DBG_UBOOT_SCRTXT_L3_STR)" >> "$@"; fi
	@if [ -n "$(DBG_UBOOT_SCRTXT_L4_STR)" ]; then echo "$(DBG_UBOOT_SCRTXT_L4_STR)" >> "$@"; fi
	@if [ -n "$(DBG_UBOOT_SCRTXT_L5_STR)" ]; then echo "$(DBG_UBOOT_SCRTXT_L5_STR)" >> "$@"; fi
	@if [ -n "$(DBG_UBOOT_SCRTXT_L6_STR)" ]; then echo "$(DBG_UBOOT_SCRTXT_L6_STR)" >> "$@"; fi
	@if [ -n "$(DBG_UBOOT_SCRTXT_L7_STR)" ]; then echo "$(DBG_UBOOT_SCRTXT_L7_STR)" >> "$@"; fi
	@if [ -f "$(DBG_UBOOT_SCRTXT_FTR)" ]; then cat "$(DBG_UBOOT_SCRTXT_FTR)" >> "$@"; fi

# Convert U-Boot text script to mkimage format
$(DBG_UBOOT_SCR): $(DBG_UBOOT_SCRTXT)
	$(MK) -C none -A arm -T script -d "$(DBG_UBOOT_SCRTXT)" "$@"

# Create U-Boot text script
$(REL_UBOOT_SCRTXT): $(REL_SCR_PRE)
	@mkdir -p "$(REL_UBOOT_SUB_PATH)"
	@if [ -f "$(REL_UBOOT_SCRTXT_HDR)" ]; then cp -f "$(REL_UBOOT_SCRTXT_HDR)" "$@"; else rm -f "$@"; fi
	@if [ -n "$(REL_UBOOT_SCRTXT_L1_STR)" ]; then echo "$(REL_UBOOT_SCRTXT_L1_STR)" >> "$@"; fi
	@if [ -n "$(REL_UBOOT_SCRTXT_L2_STR)" ]; then echo "$(REL_UBOOT_SCRTXT_L2_STR)" >> "$@"; fi
	@if [ -n "$(REL_UBOOT_SCRTXT_L3_STR)" ]; then echo "$(REL_UBOOT_SCRTXT_L3_STR)" >> "$@"; fi
	@if [ -n "$(REL_UBOOT_SCRTXT_L4_STR)" ]; then echo "$(REL_UBOOT_SCRTXT_L4_STR)" >> "$@"; fi
	@if [ -n "$(REL_UBOOT_SCRTXT_L5_STR)" ]; then echo "$(REL_UBOOT_SCRTXT_L5_STR)" >> "$@"; fi
	@if [ -n "$(REL_UBOOT_SCRTXT_L6_STR)" ]; then echo "$(REL_UBOOT_SCRTXT_L6_STR)" >> "$@"; fi
	@if [ -n "$(REL_UBOOT_SCRTXT_L7_STR)" ]; then echo "$(REL_UBOOT_SCRTXT_L7_STR)" >> "$@"; fi
	@if [ -f "$(REL_UBOOT_SCRTXT_FTR)" ]; then cat "$(REL_UBOOT_SCRTXT_FTR)" >> "$@"; fi

# Convert U-Boot text script to mkimage format
$(REL_UBOOT_SCR): $(REL_UBOOT_SCRTXT)
	$(MK) -C none -A arm -T script -d "$(REL_UBOOT_SCRTXT)" "$@"

# ===================
# Update U-Boot rules
# ===================

dbg_update_uboot:
	@echo "Running make to prepare U-Boot"
	@make -C "$(UBOOT_IN_PATH)" --no-print-directory -f Makefile-prep-ub.mk debug
	@echo ""
	@echo "Running make from U-Boot source"
	@make -C "$(DBG_UBOOT_SRC_PATH)" --no-print-directory $(UBOOT_DEFCONFIG)
	@make -C "$(DBG_UBOOT_SRC_PATH)" --no-print-directory -j 8
	@cp -f -u "$(DBG_UBOOT_SRC_PATH)/u-boot-with-spl.sfp" "$(DBG_UBOOT_IN_PATH)"

rel_update_uboot:
	@echo "Running make to prepare U-Boot"
	@make -C "$(UBOOT_IN_PATH)" --no-print-directory -f Makefile-prep-ub.mk release
	@echo ""
	@echo "Running make from U-Boot source"
	@make -C "$(REL_UBOOT_SRC_PATH)" --no-print-directory $(UBOOT_DEFCONFIG)
	@make -C "$(REL_UBOOT_SRC_PATH)" --no-print-directory -j 8
	@cp -f -u "$(REL_UBOOT_SRC_PATH)/u-boot-with-spl.sfp" "$(REL_UBOOT_IN_PATH)"

# =====================================================
# Build a list of prerequisites for SD card image rules
# =====================================================

# Add to prerequisite list
# Note, there is no timestamp so they behave like FORCE
ifeq ($(ub),1)
DBG_SD_IMG_PRE := $(DBG_SD_IMG_PRE) dbg_update_uboot
REL_SD_IMG_PRE := $(REL_SD_IMG_PRE) rel_update_uboot
endif

# Add to prerequisite list
DBG_SD_IMG_PRE := $(DBG_SD_IMG_PRE) $(DBG_SD_FUND_PRE) $(DBG_SD_SFP) $(DBG_SD_SCR) $(DBG_SD_P1UF) $(DBG_SD_P2UF) $(DBG_SD_P3UF) $(DBG_SD_P4UF)
REL_SD_IMG_PRE := $(REL_SD_IMG_PRE) $(REL_SD_FUND_PRE) $(REL_SD_SFP) $(REL_SD_SCR) $(REL_SD_P1UF) $(REL_SD_P2UF) $(REL_SD_P3UF) $(REL_SD_P4UF)

# Add to prerequisite list
ifneq (,$(wildcard $(DBG_SD_FPGA_SRC)))
	DBG_SD_IMG_PRE := $(DBG_SD_IMG_PRE) $(DBG_SD_FPGA)
endif
ifneq (,$(wildcard $(REL_SD_FPGA_SRC)))
	REL_SD_IMG_PRE := $(REL_SD_IMG_PRE) $(REL_SD_FPGA)
endif

# ================================
# SD card image file rules (Debug)
# ================================

$(DBG_SD_SFP): $(DBG_UBOOT_SFP)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_UBOOT_SFP)" "$@"

$(DBG_SD_SCR): $(DBG_UBOOT_SCR)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_UBOOT_SCR)" "$@"

$(DBG_SD_FPGA): $(DBG_SD_FPGA_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_SD_FPGA_SRC)" "$@"

$(DBG_SD_UIMG): $(DBG_UIMG1)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_UIMG1)" "$@"

$(DBG_SD_BIN): $(DBG_BIN1)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_BIN1)" "$@"

# Copy user partition files
$(DBG_SD_P1UF): $(DBG_SD_P1UF_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_SD_P1UF_SRC)" "$@"

# Copy user partition files
$(DBG_SD_P2UF): $(DBG_SD_P2UF_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_SD_P2UF_SRC)" "$@"

# Copy user partition files
$(DBG_SD_P3UF): $(DBG_SD_P3UF_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_SD_P3UF_SRC)" "$@"

# Copy user partition files
$(DBG_SD_P4UF): $(DBG_SD_P4UF_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(DBG_SD_P4UF_SRC)" "$@"

# Create SD card image
$(DBG_SD_IMG): $(DBG_SD_IMG_PRE)
ifeq ($(alt),1)
	@make -C "$(SD_IN_PATH)" --no-print-directory -f Makefile-sd-alt.mk debug
else
	@make -C "$(SD_IN_PATH)" --no-print-directory -f Makefile-sd-tru.mk debug
endif
ifneq ($(SD_OUT_PATH),$(APP_OUT_PATH))
	@if [ -f "$(DBG_SD_IMG)" ]; then \
		mkdir -p "$(DBG_SD_CP_PATH)"; \
		cp -f "$@" "$(DBG_SD_CP_PATH)"; \
		echo Copied to: "$(DBG_SDCP_IMG)"; \
	fi
endif

# ==================================
# SD card image file rules (Release)
# ==================================

$(REL_SD_SFP): $(REL_UBOOT_SFP)
	@mkdir -p "$(@D)"
	@cp -f "$(REL_UBOOT_SFP)" "$@"

$(REL_SD_SCR): $(REL_UBOOT_SCR)
	@mkdir -p "$(@D)"
	@cp -f "$(REL_UBOOT_SCR)" "$@"

$(REL_SD_FPGA): $(REL_SD_FPGA_SRC)
	@mkdir -p "$(@D)"
	cp -f "$(REL_SD_FPGA_SRC)" "$@"

$(REL_SD_UIMG): $(REL_UIMG1)
	@mkdir -p "$(@D)"
	@cp -f "$(REL_UIMG1)" "$@"

$(REL_SD_BIN): $(REL_BIN1)
	@mkdir -p "$(@D)"
	@cp -f "$(REL_BIN1)" "$@"

# Copy user partition files
$(REL_SD_P1UF): $(REL_SD_P1UF_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(REL_SD_P1UF_SRC)" "$@"

# Copy user partition files
$(REL_SD_P2UF): $(REL_SD_P2UF_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(REL_SD_P2UF_SRC)" "$@"

# Copy user partition files
$(REL_SD_P3UF): $(REL_SD_P3UF_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(REL_SD_P3UF_SRC)" "$@"

# Copy user partition files
$(REL_SD_P4UF): $(REL_SD_P4UF_SRC)
	@mkdir -p "$(@D)"
	@cp -f "$(REL_SD_P4UF_SRC)" "$@"

# Create SD card image
$(REL_SD_IMG): $(REL_SD_IMG_PRE)
ifeq ($(alt),1)
	@make -C "$(SD_IN_PATH)" --no-print-directory -f Makefile-sd-alt.mk release
else
	@make -C "$(SD_IN_PATH)" --no-print-directory -f Makefile-sd-tru.mk release
endif
ifneq ($(SD_OUT_PATH),$(APP_OUT_PATH))
	@if [ -f "$(REL_SD_IMG)" ]; then \
		mkdir -p "$(REL_SD_CP_PATH)"; \
		cp -f "$@" "$(REL_SD_CP_PATH)"; \
		echo Copied to: "$(REL_SDCP_IMG)"; \
	fi
endif
