#!/bin/bash

# Generate & merge handoff into U-Boot source code and compile..

chmod +x ./parameters.sh
source ./parameters.sh

# Generate and merge handoff source code files with U-Boot source code..
cd cv_bsp_generator
python3 cv_bsp_generator.py \
  -i ../../hps_isw_handoff/soc_system_hps_0 \
  -o ../../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT/$UBOOT_QTSFILTER_OUTPUT

#Compile u-boot source code..
cd ../../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT
export PATH=$GCC_ARM_ROOT/bin:$PATH
make clean
make $UBOOT_DEFCONFIG
make -j 8

