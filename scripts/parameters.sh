#!/bin/bash

# Quartus paths
export QUARTUS_BIN=$QSYS_ROOTDIR/../../bin

# Various paths
export SOFTWARE_ROOT=software
export BOOTLOADER_ROOT=bootloader
export SDCARD_IMAGE_ROOT=sdcard_image
export UBOOT_SRC_ROOT=u-boot-socfpga
export UBOOT_SRC_ZIP=u-boot-2022.10.zip
export UBOOT_MODIFY=other/u-boot-2022-10-modify

# DE10-Nano
export UBOOT_DEFCONFIG=socfpga_de10_nano_defconfig
export UBOOT_QTSFILTER_OUTPUT=board/terasic/de10-nano/qts
export UBOOT_QTSFILTER_SOC_TYPE=cyclone5

# Cyclone 5 (generic)
#export UBOOT_DEFCONFIG=socfpga_cyclone5_defconfig
#export UBOOT_QTSFILTER_OUTPUT=board/altera/cyclone5-socdk/qts
#export UBOOT_QTSFILTER_SOC_TYPE=cyclone5

# ARM tool chain (i.e. Compiler)
export GCC_ARM_ROOT=~/gcc-arm-10.3-2021.07-x86_64-arm-none-eabi
export CROSS_COMPILE=arm-none-eabi-

