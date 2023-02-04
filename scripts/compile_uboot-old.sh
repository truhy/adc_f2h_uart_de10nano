#!/bin/bash

# Generate & merge handoff into U-Boot source code and compile..

chmod +x ./parameters.sh
source ./parameters.sh

# Generate handoff source code files
cd ..
$SOC_EDS/embedded/embedded_command_shell.sh \
bsp-create-settings \
   --type spl \
   --bsp-dir $SOFTWARE_ROOT/$BOOTLOADER_ROOT \
   --preloader-settings-dir "hps_isw_handoff/soc_system_hps_0" \
   --settings $SOFTWARE_ROOT/$BOOTLOADER_ROOT/settings.bsp

# Merge handoff source code with U-Boot source code..
cd $SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT
./arch/arm/mach-socfpga/qts-filter.sh $UBOOT_QTSFILTER_SOC_TYPE ../../../ ../ ./$UBOOT_QTSFILTER_OUTPUT

#Compile u-boot source code..
export PATH=$GCC_ARM_ROOT/bin:$PATH
make clean
make $UBOOT_DEFCONFIG
make -j 48

