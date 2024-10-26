# This is free script released into the public domain.
# GNU make file v20231226 created by Truong Hy.
#
# Prepares environment to support building an SD card image.

# These variables are assumed to be set already
ifndef APP_HOME_PATH
$(error APP_HOME_PATH environment variable is not set)
endif

# Represents an empty white space - we need it for extracting the elf entry address from readelf output
SPACE := $() $()

# =================================================
# Read file and export some SD enviroment variables
# =================================================

export SDENVFILE := $(APP_HOME_PATH)/scripts-env/env-sd.sh

# Read environment file
SDENV := $(strip $(file <$(SDENVFILE)))
SDENV := $(subst #export$(SPACE),#export_,$(SDENV))
SDENV := $(filter-out #export_%,$(SDENV))
# Environment names
SDENV01 := SDSZ
SDENV02 := SDP1SZ
SDENV03 := SDP2SZ
SDENV04 := SDP3SZ
SDENV05 := SDP4SZ
SDENV06 := SDP1ID
SDENV07 := SDP2ID
SDENV08 := SDP3ID
SDENV09 := SDP4ID
SDENV10 := SDP1FMT
SDENV11 := SDP2FMT
SDENV12 := SDP3FMT
SDENV13 := SDP4FMT
SDENV14 := SDUBBMARG1
SDENV15 := SDUBBMARG2
SDENV16 := SDUBBMARG3
# Extract environment values and export them
export SDSZ := $(filter-out $(SDENV01),$(subst =,$(SPACE),$(filter $(SDENV01)=%,$(SDENV))))
export SDP1SZ := $(filter-out $(SDENV02),$(subst =,$(SPACE),$(filter $(SDENV02)=%,$(SDENV))))
export SDP2SZ := $(filter-out $(SDENV03),$(subst =,$(SPACE),$(filter $(SDENV03)=%,$(SDENV))))
export SDP3SZ := $(filter-out $(SDENV04),$(subst =,$(SPACE),$(filter $(SDENV04)=%,$(SDENV))))
export SDP4SZ := $(filter-out $(SDENV05),$(subst =,$(SPACE),$(filter $(SDENV05)=%,$(SDENV))))
export SDP1ID := $(filter-out $(SDENV06),$(subst =,$(SPACE),$(filter $(SDENV06)=%,$(SDENV))))
export SDP2ID := $(filter-out $(SDENV07),$(subst =,$(SPACE),$(filter $(SDENV07)=%,$(SDENV))))
export SDP3ID := $(filter-out $(SDENV08),$(subst =,$(SPACE),$(filter $(SDENV08)=%,$(SDENV))))
export SDP4ID := $(filter-out $(SDENV09),$(subst =,$(SPACE),$(filter $(SDENV09)=%,$(SDENV))))
export SDP1FMT := $(filter-out $(SDENV10),$(subst =,$(SPACE),$(filter $(SDENV10)=%,$(SDENV))))
export SDP2FMT := $(filter-out $(SDENV11),$(subst =,$(SPACE),$(filter $(SDENV11)=%,$(SDENV))))
export SDP3FMT := $(filter-out $(SDENV12),$(subst =,$(SPACE),$(filter $(SDENV12)=%,$(SDENV))))
export SDP4FMT := $(filter-out $(SDENV13),$(subst =,$(SPACE),$(filter $(SDENV13)=%,$(SDENV))))
export SDUBBMARG1 := $(filter-out $(SDENV14),$(subst =,$(SPACE),$(filter $(SDENV14)=%,$(SDENV))))
export SDUBBMARG2 := $(filter-out $(SDENV15),$(subst =,$(SPACE),$(filter $(SDENV15)=%,$(SDENV))))
export SDUBBMARG3 := $(filter-out $(SDENV16),$(subst =,$(SPACE),$(filter $(SDENV16)=%,$(SDENV))))

# Assumes there is only one a2 partition
# Assumes there is only one FAT partition

# Partition 1 size > 0?
ifeq (,$(filter 0 0K 0M 0G,$(SDP1SZ)))
export SDP1EXISTS := y
# Is a2 partition?
ifneq (,$(filter a2 A2,$(SDP1ID)))
export SDA2FOLDER := p1
endif
# Is FAT partition?
ifneq (,$(filter 0b 0B b B,$(SDP1ID)))
export SDFATFOLDER := p1
export SDFATDEVPART := 0:1
endif
else
export SDP1EXISTS := n
endif

# Partition 2 size > 0?
ifeq (,$(filter 0 0K 0M 0G,$(SDP2SZ)))
export SDP2EXISTS := y
# Is a2 partition?
ifneq (,$(filter a2 A2,$(SDP2ID)))
export SDA2FOLDER := p2
endif
# Is FAT partition?
ifneq (,$(filter 0b 0B b B,$(SDP2ID)))
export SDFATFOLDER := p2
export SDFATDEVPART := 0:2
endif
else
export SDP2EXISTS := n
endif

# Partition 3 size > 0?
ifeq (,$(filter 0 0K 0M 0G,$(SDP3SZ)))
export SDP3EXISTS := y
# Is a2 partition?
ifneq (,$(filter a2 A2,$(SDP3ID)))
export SDA2FOLDER := p3
endif
# Is FAT partition?
ifneq (,$(filter 0b 0B b B,$(SDP3ID)))
export SDFATFOLDER := p3
export SDFATDEVPART := 0:3
endif
else
export SDP3EXISTS := n
endif

# Partition 4 size > 0?
ifeq (,$(filter 0 0K 0M 0G,$(SDP4SZ)))
export SDP4EXISTS := y
# Is a2 partition?
ifneq (,$(filter a2 A2,$(SDP4ID)))
export SDA2FOLDER := p4
endif
# Is FAT partition?
ifneq (,$(filter 0b 0B b B,$(SDP4ID)))
export SDFATFOLDER := p4
export SDFATDEVPART := 0:4
endif
else
export SDP4EXISTS := n
endif

ifneq (,$(SDUBBMARG1))
UBOOT_SCRTXT_ARGS_STR := $(UBOOT_SCRTXT_ARGS_STR) $(SDUBBMARG1)
endif
ifneq (,$(SDUBBMARG2))
UBOOT_SCRTXT_ARGS_STR := $(UBOOT_SCRTXT_ARGS_STR) $(SDUBBMARG2)
endif
ifneq (,$(SDUBBMARG3))
UBOOT_SCRTXT_ARGS_STR := $(UBOOT_SCRTXT_ARGS_STR) $(SDUBBMARG3)
endif
ifneq (,$(UBOOT_SCRTXT_ARGS_STR))
UBOOT_SCRTXT_ARGS_STR := $(strip $(UBOOT_SCRTXT_ARGS_STR))
export UBOOT_SCRTXT_ARGS_STR)
endif
