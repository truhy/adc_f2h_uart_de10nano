#!/bin/bash

# Starts a GUI to edit defconfig file

chmod +x ./parameters.sh
source ./parameters.sh

cd ../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT
export PATH=$GCC_ARM_ROOT/bin:$PATH
make menuconfig

