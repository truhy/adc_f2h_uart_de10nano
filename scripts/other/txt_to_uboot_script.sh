#!/bin/bash

chmod +x ../parameters.sh
source ../parameters.sh

../../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT/tools/mkimage -C none -A arm -T script -d u-boot.txt u-boot.scr

