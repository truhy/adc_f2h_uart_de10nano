#!/bin/bash

# Downloads the GCC Arm toolchain and unzip it to home directory

chmod +x ./parameters.sh
source ./parameters.sh

cd ~

# Latest versions and variations:
# https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads

FILE=gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz
URL=https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel

if [ ! -f "$FILE" ]; then
    wget $URL/$FILE
    tar xf $FILE
fi

