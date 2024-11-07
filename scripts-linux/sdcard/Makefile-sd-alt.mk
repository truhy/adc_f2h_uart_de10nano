# This is free script released into the public domain.
# GNU make file v20241107 created by Truong Hy.
#
# Prepares and executes Altera's Python 3 script to build an SD card image.
#
# Note, the SD card image generation depends on linux tools, so other OS such as Windows is not supported natively.
# Main dependencies: Python 3, mkfs, dd, fdisk, losetup, mount, umount

# These variables are assumed to be set already
ifndef SD_OUT_PATH
$(error SD_OUT_PATH environment variable is not set)
endif
ifndef SD_PROGRAM_NAME
$(error SD_PROGRAM_NAME environment variable is not set)
endif

# Export some SD card image environment variables
ifndef SDENV
include Makefile-sd-env.mk
endif

# ===============
# Common Settings
# ===============

ALTERA_SCRIPT := make_sdimage_p3_20231221.py

# ==============
# Debug settings
# ==============

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

# =========================================================================================
# Build commandline inputs for Altera's SD card image python script, one line per partition
# =========================================================================================

# Partition 1
ifeq ($(SDP1EXISTS),y)
ifneq (,$(filter a2 A2,$(SDP1ID)))
DBG_SDP1 := -P $(DBG_SDP1PATH)/u-boot-with-spl.sfp,num=1,format=$(SDP1FMT),size=$(SDP1SZ),type=a2
else
DBG_SDP1 := -P $(DBG_SDP1PATH)/*,num=1,format=$(SDP1FMT),size=$(SDP1SZ)
endif
endif
# Partition 2
ifeq ($(SDP2EXISTS),y)
ifneq (,$(filter a2 A2,$(SDP2ID)))
DBG_SDP2 := -P $(DBG_SDP2PATH)/u-boot-with-spl.sfp,num=2,format=$(SDP2FMT),size=$(SDP2SZ),type=a2
else
DBG_SDP2 := -P $(DBG_SDP2PATH)/*,num=2,format=$(SDP2FMT),size=$(SDP2SZ)
endif
endif
# Partition 3
ifeq ($(SDP3EXISTS),y)
ifneq (,$(filter a2 A2,$(SDP3ID)))
DBG_SDP3 := -P $(DBG_SDP3PATH)/u-boot-with-spl.sfp,num=3,format=$(SDP3FMT),size=$(SDP3SZ),type=a2
else
DBG_SDP3 := -P $(DBG_SDP3PATH)/*,num=3,format=$(SDP3FMT),size=$(SDP3SZ)
endif
endif
# Partition 4
ifeq ($(SDP4EXISTS),y)
ifneq (,$(filter a2 A2,$(SDP4ID)))
DBG_SDP4 := -P $(DBG_SDP4PATH)/u-boot-with-spl.sfp,num=4,format=$(SDP4FMT),size=$(SDP4SZ),type=a2
else
DBG_SDP4 := -P $(DBG_SDP4PATH)/*,num=4,format=$(SDP4FMT),size=$(SDP4SZ)
endif
endif

# ================
# Release settings
# ================

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

# =========================================================================================
# Build commandline inputs for Altera's SD card image python script, one line per partition
# =========================================================================================

# Partition 1
REL_SDSFP := $(REL_SDP4PATH)/u-boot-with-spl.sfp
ifeq ($(SDP1EXISTS),y)
ifneq (,$(filter a2 A2,$(SDP1ID)))
REL_SDP1 := -P $(REL_SDP1PATH)/u-boot-with-spl.sfp,num=1,format=$(SDP1FMT),size=$(SDP1SZ),type=a2
else
REL_SDP1 := -P $(REL_SDP1PATH)/*,num=1,format=$(SDP1FMT),size=$(SDP1SZ)
endif
endif
# Partition 2
ifeq ($(SDP2EXISTS),y)
ifneq (,$(filter a2 A2,$(SDP2ID)))
REL_SDP2 := -P $(REL_SDP2PATH)/u-boot-with-spl.sfp,num=2,format=$(SDP2FMT),size=$(SDP2SZ),type=a2
else
REL_SDP2 := -P $(REL_SDP2PATH)/*,num=2,format=$(SDP2FMT),size=$(SDP2SZ)
endif
endif
# Partition 3
ifeq ($(SDP3EXISTS),y)
ifneq (,$(filter a2 A2,$(SDP3ID)))
REL_SDP3 := -P $(REL_SDP3PATH)/u-boot-with-spl.sfp,num=3,format=$(SDP3FMT),size=$(SDP3SZ),type=a2
else
REL_SDP3 := -P $(REL_SDP3PATH)/*,num=3,format=$(SDP3FMT),size=$(SDP3SZ)
endif
endif
# Partition 4
ifeq ($(SDP4EXISTS),y)
ifneq (,$(filter a2 A2,$(SDP4ID)))
REL_SDP4 := -P $(REL_SDP4PATH)/u-boot-with-spl.sfp,num=4,format=$(SDP4FMT),size=$(SDP4SZ),type=a2
else
REL_SDP3 := -P $(REL_SDP4PATH)/*,num=4,format=$(SDP4FMT),size=$(SDP4SZ)
endif
endif

# ==========================================
# Build prerequisites for SD card image rule
# ==========================================

# Build prerequisite list
REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(SDENVFILE)
ifeq (,$(filter 0 0K 0M 0G,$(SDP1SZ)))
	REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(REL_SDP1FILES)
endif
ifeq (,$(filter 0 0K 0M 0G,$(SDP2SZ)))
	REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(REL_SDP2FILES)
endif
ifeq (,$(filter 0 0K 0M 0G,$(SDP3SZ)))
	REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(REL_SDP3FILES)
endif
ifeq (,$(filter 0 0K 0M 0G,$(SDP4SZ)))
	REL_SDIMG_PRE := $(REL_SDIMG_PRE) $(REL_SDP4FILES)
endif

# Build prerequisite list
DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(SDENVFILE)
ifeq (,$(filter 0 0K 0M 0G,$(SDP1SZ)))
	DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(DBG_SDP1FILES)
endif
ifeq (,$(filter 0 0K 0M 0G,$(SDP2SZ)))
	DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(DBG_SDP2FILES)
endif
ifeq (,$(filter 0 0K 0M 0G,$(SDP3SZ)))
	DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(DBG_SDP3FILES)
endif
ifeq (,$(filter 0 0K 0M 0G,$(SDP4SZ)))
	DBG_SDIMG_PRE := $(DBG_SDIMG_PRE) $(DBG_SDP4FILES)
endif

# ===========
# Build rules
# ===========

# Options
.PHONY: all release debug clean

# Default build
all: release

# ===========
# Clean rules
# ===========

# Clean sublevel 2 folder
clean2:
#	rm -f $(DBG_SDIMG)
#	rm -f $(REL_SDIMG)
	@if [ -d "$(DBG_SDOUTSUBPATH)" ]; then echo rm -rf "$(DBG_SDOUTSUBPATH)"; rm -rf "$(DBG_SDOUTSUBPATH)"; fi
	@if [ -d "$(REL_SDOUTSUBPATH)" ]; then echo rm -rf "$(REL_SDOUTSUBPATH)"; rm -rf "$(REL_SDOUTSUBPATH)"; fi

# Clean sublevel 1 folder
clean1: clean2
	@if [ -d "$(DBG_SDOUTPATH)" ] && [ -z "$$(ls -A $(DBG_SDOUTPATH))" ]; then echo rm -df "$(DBG_SDOUTPATH)"; rm -df "$(DBG_SDOUTPATH)"; fi
	@if [ -d "$(REL_SDOUTPATH)" ] && [ -z "$$(ls -A $(REL_SDOUTPATH))" ]; then echo rm -df "$(REL_SDOUTPATH)"; rm -df "$(REL_SDOUTPATH)"; fi

# Clean root folder
clean: clean1
	@if [ -d "$(SD_OUT_PATH)" ] && [ -z "$$(ls -A $(SD_OUT_PATH))" ]; then echo rm -df "$(SD_OUT_PATH)"; rm -df "$(SD_OUT_PATH)"; fi

# ================================
# Release SD card image file rules
# ================================

release: $(REL_SDIMG)

# Create SD card image
$(REL_SDIMG): $(REL_SDIMG_PRE)
	sudo python3 $(ALTERA_SCRIPT) -f \
	$(REL_SDP1) \
	$(REL_SDP2) \
	$(REL_SDP3) \
	$(REL_SDP4) \
	-s $(SDSZ) \
	-n $@

# ==============================
# Debug SD card image file rules
# ==============================

debug: $(DBG_SDIMG)

# Create SD card image
$(DBG_SDIMG): $(DBG_SDIMG_PRE)
	sudo python3 $(ALTERA_SCRIPT) -f \
	$(DBG_SDP1) \
	$(DBG_SDP2) \
	$(DBG_SDP3) \
	$(DBG_SDP4) \
	-s $(SDSZ) \
	-n $@
