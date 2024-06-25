#!/bin/bash

# Get this script's path
SCRIPT_PATH=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
# Get the parent folder path (one level up) from this script's path
SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"

# Tools settings
TOOLCHAIN_PATH=~/devtools/xpack-arm-none-eabi-gcc-13.2.1-1.1/bin
OPENOCD_PATH=~/devtools/xpack-openocd-0.12.0-2/bin
if [ -z "${QUARTUS_ROOTDIR+x}" ]; then QUARTUS_ROOTDIR=~/intelFPGA_lite/22.1std/quartus/bin; fi

# Search path settings
export PATH=$PATH:$SCRIPT_PATH/scripts-env:$SCRIPT_PATH/scripts-linux
if [ -n "${TOOLCHAIN_PATH+x}" ]; then export PATH=$PATH:$TOOLCHAIN_PATH; fi
if [ -n "${OPENOCD_PATH+x}" ]; then export PATH=$PATH:$OPENOCD_PATH; fi
if [ -n "${QUARTUS_ROOTDIR+x}" ]; then export PATH=$PATH:$QUARTUS_ROOTDIR; fi

# Messages
if [ -n "${TOOLCHAIN_PATH+x}" ];  then echo "Toolchain: $TOOLCHAIN_PATH"; fi
if [ -n "${OPENOCD_PATH+x}" ];    then echo "OpenOCD  : $OPENOCD_PATH"; fi
if [ -n "${QUARTUS_ROOTDIR+x}" ]; then echo "Quartus  : $QUARTUS_ROOTDIR"; fi
