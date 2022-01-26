#!/bin/bash

# Extracts u-boot source code..

chmod +x ./parameters.sh
source ./parameters.sh

# Create software folder..
cd ..
mkdir -p $SOFTWARE_ROOT/$BOOTLOADER_ROOT
cd $SOFTWARE_ROOT/$BOOTLOADER_ROOT

# Get it from the internet with git clone
#git clone https://github.com/altera-opensource/u-boot-socfpga

# Below is alternative to git clone, i.e. if you have already downloaded u-boot source into your home directory
unzip ~/$UBOOT_SRC_ZIP
UBOOT_SRC_FOLDER="${UBOOT_SRC_ZIP%.*}"
mv $UBOOT_SRC_FOLDER $UBOOT_SRC_ROOT

