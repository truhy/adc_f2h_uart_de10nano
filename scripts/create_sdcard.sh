#!/bin/bash

THIS_SCRIPT_PATH=`pwd`

chmod +x ./parameters.sh
source ./parameters.sh

# Update .rbf and .scr files..
cd other
chmod +x ./convert_sof_to_rbf.sh
chmod +x ./txt_to_uboot_script.sh
./convert_sof_to_rbf.sh
./txt_to_uboot_script.sh

# Create SD card image folder..
cd ../..
mkdir -p $SDCARD_IMAGE_ROOT
cd $SDCARD_IMAGE_ROOT

# Get script if it doesn't exists..
MAKE_SDIMAGE_PY_FILE=make_sdimage_p3.py
if [ ! -f "$MAKE_SDIMAGE_PY_FILE" ]; then
    #wget https://releases.rocketboards.org/release/2021.04/gsrd/tools/$MAKE_SDIMAGE_PY_FILE
    cp "$THIS_SCRIPT_PATH"/other/$MAKE_SDIMAGE_PY_FILE .
    chmod +x $MAKE_SDIMAGE_PY_FILE
fi

# Prepare FAT partition files..
rm -rf fat
mkdir fat && cd fat
cp "$THIS_SCRIPT_PATH"/other/soc_system.rbf .
cp "$THIS_SCRIPT_PATH"/other/u-boot.scr .
#cp "$THIS_SCRIPT_PATH"/other/usb_desc_hid.bin .
#cp "$THIS_SCRIPT_PATH"/other/usb_desc_cdc_acm.bin .
#cp ../../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT/arch/arm/dts/socfpga_cyclone5_de10_nano.dtb .
#cp $LINUX_BIN/a9/zImage .

# Make linux conf file..
#mkdir extlinux
#echo "LABEL Linux Default" > extlinux/extlinux.conf
#echo "    KERNEL ../zImage" >> extlinux/extlinux.conf
#echo "    FDT ../socfpga_cyclone5_de10_nano.dtb" >> extlinux/extlinux.conf
#echo "    APPEND root=/dev/mmcblk0p2 rw rootwait earlyprintk console=ttyS0,115200n8" >> extlinux/extlinux.conf

# Prepare Rootfs partition files..
cd ..
rm -rf rootfs
mkdir rootfs && cd rootfs
# Copy linux files..
#sudo tar xf $LINUX_BIN/a9/core-image-minimal-cyclone5.tar.gz
#sudo rm -rf lib/modules/*
#sudo cp -r $LINUX_BIN/a9/modules/* lib/modules

cd ..

# Create SD card image
#sudo python3 ./$MAKE_SDIMAGE_PY_FILE -f \
#-P ../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT/u-boot-with-spl.sfp,num=3,format=raw,size=10M,type=A2  \
#-P fat/*,num=1,format=fat32,size=32M \
#-P rootfs/*,num=2,format=ext3,size=22M \
#-s 64M \
#-n sdcard_de10nano.img

# Create SD card image without Rootfs files..
sudo python3 ./$MAKE_SDIMAGE_PY_FILE -f \
-P ../$SOFTWARE_ROOT/$BOOTLOADER_ROOT/$UBOOT_SRC_ROOT/u-boot-with-spl.sfp,num=3,format=raw,size=10M,type=A2  \
-P fat/*,num=1,format=fat32,size=32M \
-P num=2,format=ext3,size=22M \
-s 64M \
-n sdcard_de10nano.img

# Clean up..
rm -rf fat
rm -rf rootfs
rm $MAKE_SDIMAGE_PY_FILE

