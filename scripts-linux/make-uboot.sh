#!/bin/bash

if [ -z "${SCRIPT_PATH+x}" ]; then
	source ../scripts-env/env-linux.sh
fi

# Prepare U-Boot source code and modifications
cd "$SCRIPT_PATH/scripts-linux/uboot"
echo "1. Prepare U-Boot source"
#make -C "$SCRIPT_PATH/scripts-linux/uboot" --no-print-directory -f Makefile-prep-ub.mk release
make -f Makefile-prep-ub.mk release

# Build U-Boot
cd "$UBOOT_OUT_PATH/Release/u-boot"
#export KBUILD_OUTPUT=$PREP_PATH
#export CROSS_COMPILE=arm-none-eabi-
echo ""
echo "2. Build prepared U-Boot source"
#make clean
make $UBOOT_DEFCONFIG
make -j 8

# Copy new U-Boot file
#echo "3. Copy u-boot-with-spl.sfp to scripts-linux/uboot"
#cp -f -u $UBOOT_OUT_PATH/u-boot/u-boot-with-spl.sfp $SCRIPT_PATH/scripts-linux/Debug/uboot
#cp -f -u $UBOOT_OUT_PATH/u-boot/u-boot-with-spl.sfp $SCRIPT_PATH/scripts-linux/Release/uboot

# If shell is child level 1 (e.g. Run as a Program) then stay in shell
if [ $SHLVL -eq 1 ]; then exec $SHELL; fi
