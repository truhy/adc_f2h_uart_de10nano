# This is free script released into the public domain.
# GNU make file v20241107 created by Truong Hy.
#
# Prepares and executes Bash script to build an SD card image.
#
# Note, the SD card image generation depends on linux tools, so other OS such as Windows is not supported natively.
# Main dependencies: Bash, mkfs, dd, sfdisk, losetup, mount, umount

# These variables are assumed to be set already
ifndef SD_OUT_PATH
$(error SD_OUT_PATH environment variable is not set)
endif
ifndef SD_PROGRAM_NAME
$(error SD_PROGRAM_NAME environment variable is not set)
endif

# Export some SD card image environment variables
SDENVFILE := ../../scripts-env/env-sd.sh
include Makefile-sd-env.mk

# ========
# Settings
# ========

SD_SCRIPT := make-sd-tru.sh

DBG_SDOUTPATH := $(SD_OUT_PATH)/Debug
DBG_SDOUTSUBPATH := $(DBG_SDOUTPATH)/sd-out
DBG_SDIMG := $(DBG_SDOUTSUBPATH)/$(SD_PROGRAM_NAME).sd.img
DBG_SDTMP := $(DBG_SDOUTSUBPATH)/$(SD_PROGRAM_NAME).sd.~img
DBG_SDPARTINFO := $(DBG_SDOUTSUBPATH)/$(SD_PROGRAM_NAME).sd.sfdisk.txt
DBG_SDP1PATH := $(DBG_SDOUTSUBPATH)/p1
DBG_SDP2PATH := $(DBG_SDOUTSUBPATH)/p2
DBG_SDP3PATH := $(DBG_SDOUTSUBPATH)/p3
DBG_SDP4PATH := $(DBG_SDOUTSUBPATH)/p4
DBG_SDP1FILES := $(wildcard $(DBG_SDP1PATH)/*)
DBG_SDP2FILES := $(wildcard $(DBG_SDP2PATH)/*)
DBG_SDP3FILES := $(wildcard $(DBG_SDP3PATH)/*)
DBG_SDP4FILES := $(wildcard $(DBG_SDP4PATH)/*)

REL_SDOUTPATH := $(SD_OUT_PATH)/Release
REL_SDOUTSUBPATH := $(REL_SDOUTPATH)/sd-out
REL_SDIMG := $(REL_SDOUTSUBPATH)/$(SD_PROGRAM_NAME).sd.img
REL_SDTMP := $(REL_SDOUTSUBPATH)/$(SD_PROGRAM_NAME).sd.~img
REL_SDPARTINFO := $(REL_SDOUTSUBPATH)/$(SD_PROGRAM_NAME).sd.sfdisk.txt
REL_SDP1PATH := $(REL_SDOUTSUBPATH)/p1
REL_SDP2PATH := $(REL_SDOUTSUBPATH)/p2
REL_SDP3PATH := $(REL_SDOUTSUBPATH)/p3
REL_SDP4PATH := $(REL_SDOUTSUBPATH)/p4
REL_SDP1FILES := $(wildcard $(REL_SDP1PATH)/*)
REL_SDP2FILES := $(wildcard $(REL_SDP2PATH)/*)
REL_SDP3FILES := $(wildcard $(REL_SDP3PATH)/*)
REL_SDP4FILES := $(wildcard $(REL_SDP4PATH)/*)

# ==========================================
# Build prerequisites for SD card image rule
# ==========================================

# Build prerequisite list
REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(SDENVFILE)
ifeq ($(SDP1EXISTS),y)
	REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(REL_SDP1FILES)
endif
ifeq ($(SDP2EXISTS),y)
	REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(REL_SDP2FILES)
endif
ifeq ($(SDP3EXISTS),y)
	REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(REL_SDP3FILES)
endif
ifeq ($(SDP4EXISTS),y)
	REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(REL_SDP4FILES)
endif

# Build prerequisite list
DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(SDENVFILE)
ifeq ($(SDP1EXISTS),y)
	DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(DBG_SDP1FILES)
endif
ifeq ($(SDP2EXISTS),y)
	DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(DBG_SDP2FILES)
endif
ifeq ($(SDP3EXISTS),y)
	DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(DBG_SDP3FILES)
endif
ifeq ($(SDP4EXISTS),y)
	DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(DBG_SDP4FILES)
endif

# ===========
# Build rules
# ===========

.PHONY: all release debug clean

# Default
all: release

# Clean sublevel 2 folder
clean2:
#	rm -f $(DBG_SDTMP)
#	rm -f $(DBG_SDIMG)
#	rm -f $(DBG_SDPARTINFO)
#	rm -f $(REL_SDTMP)
#	rm -f $(REL_SDIMG)
#	rm -f $(REL_SDPARTINFO)
	@if [ -d "$(DBG_SDOUTSUBPATH)" ]; then echo rm -rf $(DBG_SDOUTSUBPATH); rm -rf $(DBG_SDOUTSUBPATH); fi
	@if [ -d "$(REL_SDOUTSUBPATH)" ]; then echo rm -rf $(REL_SDOUTSUBPATH); rm -rf $(REL_SDOUTSUBPATH); fi

# Clean sublevel 1 folder
clean1: clean2
	@if [ -d "$(DBG_SDOUTPATH)" ] && [ -z "$$(ls -A $(DBG_SDOUTPATH))" ]; then echo rm -df $(DBG_SDOUTPATH); rm -df $(DBG_SDOUTPATH); fi
	@if [ -d "$(REL_SDOUTPATH)" ] && [ -z "$$(ls -A $(REL_SDOUTPATH))" ]; then echo rm -df $(REL_SDOUTPATH); rm -df $(REL_SDOUTPATH); fi

# Clean root folder
clean: clean1
	@if [ -d "$(SD_OUT_PATH)" ] && [ -z "$$(ls -A $(SD_OUT_PATH))" ]; then echo rm -df $(SD_OUT_PATH); rm -df $(SD_OUT_PATH); fi

# ================================
# Release SD card image file rules
# ================================

release: $(REL_SDIMG)

$(REL_SDIMG): $(REL_SDIMG_PRE)
	@chmod +x ./$(SD_SCRIPT)
	@./$(SD_SCRIPT)

# ==============================
# Debug SD card image file rules
# ==============================

debug: $(DBG_SDIMG)

$(DBG_SDIMG): $(DBG_SDIMG_PRE)
	@chmod +x ./$(SD_SCRIPT)
	@./$(SD_SCRIPT) debug
