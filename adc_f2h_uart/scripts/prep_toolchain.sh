#!/bin/bash

# Downloads the GCC Arm toolchain and unzip it to home directory

chmod +x ./parameters.sh
source ./parameters.sh

# Make directory for toolchain if it doesn't exist and go into it
mkdir -p ~/DevTools
cd ~/DevTools

# Notes:
#   Toolchain = C & C++ compiler, linker, tools, etc
#   Host = which OS will be used to compile on. E.g. if you are going to use your Intel PC running 32bits Linux to compile with then the host is x86 Linux
#   Target = which system the elf or binary will be running on. E.g. if the development kit proessor is Arm Cortex A9 then it is AArch32 (32bit)
#   x86 Linux = 32bits Linux on Intel processor
#   x64 Linux = 64bits Linux on Intel processor
#   AArch32 = 32bit Arm processor
#   AArch64 = 64bit Arm processor
#   AArch32 Linux = Linux on 32bit Arm processor
#   AArch64 Linux = Linux on 64bit Arm processor
#   Windows (mingw-w64-i686) = 64bits Windows on Intel processor and mingw-w64-i686 C/C++ compiler
#   Hard float = This refers to the target Arm processor which includes a hardware floating unit (ALU) and this option will make use of it. For Linux target the std C/C++ (e.g. glibc) library needs be precompiled so enabling hard float is not selectable using just a switch.  For baremetal a switch can enable the hard float
#   Baremetal = to build an elf or binary where there is no OS

# So for example, for compiling bare-metal programs for Cortex-A9 processor:
#   if using intel linux for compiling you need:
#     Host: x86_64 Linux
#     Target: AArch32 bare-metal target (arm-none-eabi)
#     Example download file: arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-eabi.tar.xz
#   if using intel Windows for compiling you need:
#     Host: Windows for intel
#     AArch32 bare-metal target (arm-none-eabi)
#     Example download file: arm-gnu-toolchain-12.2.rel1-mingw-w64-i686-arm-none-eabi.zip

# For compiling a linux program for Cortex-A9 processor (that will be running linux):
#   if using intel linux for compiling you need:
#     Host: x86_64 Linux
#     Target: AArch32 bare-metal target (arm-none-eabi)
#     Example download file: arm-gnu-toolchain-12.2.rel1-x86_64-arm-none-linux-gnueabihf.tar.xz
#   if using intel Windows for compiling you need:
#     Host: Windows for intel
#     AArch32 bare-metal target (arm-none-eabi)
#     Example download file: arm-gnu-toolchain-12.2.rel1-mingw-w64-i686-arm-none-linux-gnueabihf.zip

# Common GCC Arm toolchain binary builds...

# 1. Arm binary builds for CPUs based on the A, R and M profiles of the Arm architecture (including Cortex-A, Cortex-R, Cortex-M and Neoverse processors)
# https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads

# 2. xPack binary builds (bare-metal target only)
# https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases

# 3. Linaro binary builds  (only linux hosted, barem-etal and linux targets) (seems to be discontinued - last version is 7.5-2019.12)
# https://releases.linaro.org/components/toolchain/binaries

# (Not recommended)
# 4. Arm binary builds for Cortex A-profile (bare-metal and linux target) (A-profile seems to be discontinued - last version is 10.3-2021.07)
# https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads

FILE=xpack-arm-none-eabi-gcc-12.2.1-1.2-linux-x64.tar.gz
URL=https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack/releases/download/v12.2.1-1.2

if [ ! -f "$FILE" ]; then
    wget $URL/$FILE
    tar xf $FILE
fi

