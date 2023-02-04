#!/bin/bash

# Patch (if any) u-boot source code..

THIS_SCRIPT_PATH=`pwd`

chmod +x ./parameters.sh
source ./parameters.sh

# Replace u-boot files with our changes
cp $UBOOT_MODIFY/$UBOOT_DEFCONFIG ../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT/configs

