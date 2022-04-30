#!/bin/bash

# Extracts u-boot source code..

THIS_SCRIPT_PATH=`pwd`

chmod +x ./parameters.sh
source ./parameters.sh

# Create software folder..
cd ..
mkdir -p $SOFTWARE_ROOT/$BOOTLOADER_ROOT
cd $SOFTWARE_ROOT/$BOOTLOADER_ROOT

# Get it from the internet with git clone
#https://github.com/u-boot/u-boot

# Alternative you can use Altera's u-boot fork
#git clone https://github.com/altera-opensource/u-boot-socfpga

# Below is alternative to git clone, i.e. if you have already downloaded u-boot source into your home directory
unzip ~/$UBOOT_SRC_ZIP
UBOOT_SRC_FOLDER="${UBOOT_SRC_ZIP%.*}"
mv $UBOOT_SRC_FOLDER $UBOOT_SRC_ROOT

cp "$THIS_SCRIPT_PATH"/$UBOOT_MODIFY/$UBOOT_DEFCONFIG $UBOOT_SRC_ROOT/configs

