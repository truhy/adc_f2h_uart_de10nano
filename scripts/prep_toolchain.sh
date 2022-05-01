#!/bin/bash

# Downloads the GCC Arm toolchain and unzip it to home directory

chmod +x ./parameters.sh
source ./parameters.sh

cd ~

# Notes:
#   Toolchain = C & C++ compiler, linker, tools, etc
#   Host = which OS will be used to compile on. E.g. if you are going to use your Intel PC running 32bits Linux to compile with then the host is x86 Linux
#   Target = which system the elf or binary will be running on. E.g. if the development kit is running linux then target is linux, or if no OS then target is baremetal
#   x86 Linux = 32bits Linux on Intel processor
#   x64 Linux = 64bits Linux on Intel processor
#   AArch32 = 32bit Arm processor
#   AArch64 = 64bit Arm processor
#   AArch32 Linux = Linux on 32bit Arm processor
#   AArch64 Linux = Linux on 64bit Arm processor
#   Windows (mingw-w64-i686) = 64bits Windows on Intel processor and mingw-w64-i686 C/C++ compiler
#   Hard float = This refers to the target Arm processor which includes a hardware floating unit (ALU) and this option will make use of it. For Linux target the std C/C++ (e.g. glibc) library needs be precompiled so enabling hard float is not selectable using just a switch.  For baremetal a switch can enable the hard float

# Common GCC Arm toolchain binary builds...

# 1. Arm binary builds for Cortex A-profile (baremetal and linux target) (A-profile seems to be discontinued - last version is 10.3-2021.07)
# https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads

# 2. Linaro binary builds  (baremetal and linux target) (seems to be discontinued - last version is 7.5-2019.12)
# https://releases.linaro.org/components/toolchain/binaries/

# 3. xPack binary builds (baremetal target only)
# https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/

#FILE=gcc-arm-10.3-2021.07-x86_64-arm-none-linux-gnueabihf.tar.xz
FILE=gcc-arm-10.3-2021.07-x86_64-arm-none-eabi.tar.xz
URL=https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel

if [ ! -f "$FILE" ]; then
    wget $URL/$FILE
    tar xf $FILE
fi

