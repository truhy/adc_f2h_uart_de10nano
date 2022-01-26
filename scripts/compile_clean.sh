#!/bin/bash

# Generate & merge handoff into U-Boot source code and compile..

chmod +x ./parameters.sh
source ./parameters.sh

cd ../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT
export PATH=$GCC_ARM_ROOT/bin:$PATH
make clean

