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

# Assume u-boot source zip is already downloaded

# Unzip U-boot source
unzip $UBOOT_SRC_ZIP
# Rename u-boot-x.x versioned folder name to a common name
mv $UBOOT_SRC_ZIP_FOLDER $UBOOT_SRC_ROOT

# Apply our patches
cd "$THIS_SCRIPT_PATH"
chmod +x ./patch_uboot.sh
./patch_uboot.sh

