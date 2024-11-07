#!/bin/bash

# This is free script released into the public domain.
# Script v20241107 created by Truong Hy.
# Builds a bootable SD card image for the Intel Cyclone V SoC FPGA.
# Note, the SD image generation depends on linux tools so other OS e.g. Windows is not supported.
# Main dependencies: mkfs, dd, sfdisk, losetup, mount, umount

# These variables must be set
if [ -z "${SD_OUT_PATH+x}" ]; then echo "variable SD_OUT_PATH not set"; exit 1; fi
if [ -z "${SDSZ+x}" ]; then echo "variable SDSZ not set"; exit 1; fi
if [ -z "${SDP1SZ+x}" ]; then echo "variable SDP1SZ not set"; exit 1; fi
if [ -z "${SDP2SZ+x}" ]; then echo "variable SDP2SZ not set"; exit 1; fi
if [ -z "${SDP3SZ+x}" ]; then echo "variable SDP3SZ not set"; exit 1; fi
if [ -z "${SDP4SZ+x}" ]; then echo "variable SDP4SZ not set"; exit 1; fi
if [ -z "${SDP1ID+x}" ]; then echo "variable SDP1ID not set"; exit 1; fi
if [ -z "${SDP2ID+x}" ]; then echo "variable SDP2ID not set"; exit 1; fi
if [ -z "${SDP3ID+x}" ]; then echo "variable SDP3ID not set"; exit 1; fi
if [ -z "${SDP4ID+x}" ]; then echo "variable SDP4ID not set"; exit 1; fi
if [ -z "${SDP1FMT+x}" ]; then echo "variable SDP1FMT not set"; exit 1; fi
if [ -z "${SDP2FMT+x}" ]; then echo "variable SDP2FMT not set"; exit 1; fi
if [ -z "${SDP3FMT+x}" ]; then echo "variable SDP3FMT not set"; exit 1; fi
if [ -z "${SDP4FMT+x}" ]; then echo "variable SDP4FMT not set"; exit 1; fi

set -e
function cleanup {
	if mountpoint -q "${SDP1MPATH}"; then sudo umount -d "${SDP1MPATH}"; fi
	if mountpoint -q "${SDP2MPATH}"; then sudo umount -d "${SDP2MPATH}"; fi
	if mountpoint -q "${SDP3MPATH}"; then sudo umount -d "${SDP3MPATH}"; fi
	if mountpoint -q "${SDP4MPATH}"; then sudo umount -d "${SDP4MPATH}"; fi
	if [ -n "${LOOPDEV+x}" ]; then sudo losetup -d "${LOOPDEV}" 1> /dev/null 2>&1; fi
}
trap cleanup EXIT

if [ "$1" = "debug" ]; then SDBUILD=Debug; else SDBUILD=Release; fi

# Settings
SDBUILDPATH=${SD_OUT_PATH}/${SDBUILD}
SDIMG=${SDBUILDPATH}/sd-out/${SD_PROGRAM_NAME}.sd.img
SDTMP=${SDBUILDPATH}/sd-out/${SD_PROGRAM_NAME}.sd.~img
SDPARTINFO=${SDBUILDPATH}/sd-out/${SD_PROGRAM_NAME}.sd.sfdisk.txt
# Source files
SDP1PATH=${SDBUILDPATH}/sd-out/p1
SDP2PATH=${SDBUILDPATH}/sd-out/p2
SDP3PATH=${SDBUILDPATH}/sd-out/p3
SDP4PATH=${SDBUILDPATH}/sd-out/p4
# Mount point paths
SDP1MPATH=${SDBUILDPATH}/sd-out/p1m
SDP2MPATH=${SDBUILDPATH}/sd-out/p1m
SDP3MPATH=${SDBUILDPATH}/sd-out/p1m
SDP4MPATH=${SDBUILDPATH}/sd-out/p1m

# Format partition and then mount to a loop device. If raw then do nothing
fmt_mnt() {
	partid=$1
	loopdev=$2
	sd_fmt=$3
	dstpath=$4
	if [ "${sd_fmt}" = "raw" ]; then
		echo "${partid} (raw): No formatting"
	else
		echo "${partid} (${sd_fmt}): Formatting"
		sudo mkfs.${sd_fmt} "${loopdev}p1"
		mkdir -p "${dstpath}"
		sudo mount -t ${sd_fmt} "${loopdev}p1" "${dstpath}"
	fi
}

# Copies files to partition
copy_files() {
	partid=$1
	loopdev=$2
	sd_offset=$(echo $(($3)))
	sd_fmt=$4
	srcpath=$5
	dstpath=$6
	for file in "${srcpath}"/*; do
		if [ "${sd_fmt}" = "raw" ]; then
			echo "${partid} DD: $(basename ${file})"
			sudo dd if="${file}" of="${loopdev}" bs=1 seek=${sd_offset} status=none
			file_size=$(stat -L -c %s ${file})
			sd_offset=$(echo $((${sd_offset}+${file_size})))
		else
			echo "${partid} CP: $(basename ${file})"
			sudo cp -f "${file}" "${dstpath}"
		fi
	done
}

# Unmount partition
unmount_part() {
	if mountpoint -q "$1"; then sudo umount -l "$1"; fi
}

# Convert size units to bytes
last=${SDSZ:0-1}
if [ "$last" = K ]; then
	SDSZC=${SDSZ::-1}
	SDSB=$(echo $((1024*${SDSZC})))
	SDSZU=1K
elif [ "$last" = M ]; then
	SDSZC=${SDSZ::-1}
	SDSB=$(echo $((1024*1024*${SDSZC})))
	SDSZU=1M
elif [ "$last" = G ]; then
	SDSZC=${SDSZ::-1}
	SDSB=$(echo $((1024*1024*1024*${SDSZC})))
	SDSZU=1G
else
	SDSZC=${SDSZ::-1}
	SDSB=${SDSZ}
	SDSZU=1
fi

# Convert size units to bytes
last=${SDP1SZ:0-1}
if [ "$last" = K ]; then
	SDP1SB=${SDP1SZ::-1}
	SDP1SB=$(echo $((1024*${SDP1SB})))
elif [ "$last" = M ]; then
	SDP1SB=${SDP1SZ::-1}
	SDP1SB=$(echo $((1024*1024*${SDP1SB})))
elif [ "$last" = G ]; then
	SDP1SB=${SDP1SZ::-1}
	SDP1SB=$(echo $((1024*1024*1024*${SDP1SB})))
else
	SDP1SB=${SDP1SZ}
fi

# Convert size units to bytes
last=${SDP2SZ:0-1}
if [ "$last" = K ]; then
	SDP2SB=${SDP2SZ::-1}
	SDP2SB=$(echo $((1024*${SDP2SB})))
elif [ "$last" = M ]; then
	SDP2SB=${SDP2SZ::-1}
	SDP2SB=$(echo $((1024*1024*${SDP2SB})))
elif [ "$last" = G ]; then
	SDP2SB=${SDP2SZ::-1}
	SDP2SB=$(echo $((1024*1024*1024*${SDP2SB})))
else
	SDP2SB=${SDP2SZ}
fi

# Convert size units to bytes
last=${SDP3SZ:0-1}
if [ "$last" = K ]; then
	SDP3SB=${SDP3SZ::-1}
	SDP3SB=$(echo $((1024*${SDP3SB})))
elif [ "$last" = M ]; then
	SDP3SB=${SDP3SZ::-1}
	SDP3SB=$(echo $((1024*1024*${SDP3SB})))
elif [ "$last" = G ]; then
	SDP3SB=${SDP3SZ::-1}
	SDP3SB=$(echo $((1024*1024*1024*${SDP3SB})))
else
	SDP3SB=${SDP3SZ}
fi

# Convert size units to bytes
last=${SDP4SZ:0-1}
if [ "$last" = K ]; then
	SDP4SB=${SDP4SZ::-1}
	SDP4SB=$(echo $((1024*${SDP4SB})))
elif [ "$last" = M ]; then
	SDP4SB=${SDP4SZ::-1}
	SDP4SB=$(echo $((1024*1024*${SDP4SB})))
elif [ "$last" = G ]; then
	SDP4SB=${SDP4SZ::-1}
	SDP4SB=$(echo $((1024*1024*1024*${SDP4SB})))
else
	SDP4SB=${SDP4SZ}
fi

# Create empty SD image file
mkdir -p "${SDBUILDPATH}"
echo "Creating file: $(basename ${SDTMP}) (empty SD)"
dd if="/dev/zero" of="${SDTMP}" bs=${SDSZU} count=${SDSZC} status=none

# Create sfdisk partition info txt
echo "Creating file: $(basename ${SDPARTINFO}) (partition info)"
rm -rf "${SDPARTINFO}"
SDPXOB=$(echo $((2048*512)))
SDP1SS=$(echo $((${SDP1SB}/512)))
SDP1OB=${SDPXOB}
SDPXOB=$(echo $((${SDPXOB}+${SDP1SB})))
SDP2SS=$(echo $((${SDP2SB}/512)))
SDP2OB=${SDPXOB}
SDPXOB=$(echo $((${SDPXOB}+${SDP2SB})))
SDP3SS=$(echo $((${SDP3SB}/512)))
SDP3OB=${SDPXOB}
SDPXOB=$(echo $((${SDPXOB}+${SDP3SB})))
SDP4SS=$(echo $((${SDP4SB}/512)))
SDP4OB=${SDPXOB}
SDPXOB=$(echo $((${SDPXOB}+${SDP4SB})))
if [ "${SDP1SB}" -ne 0 ]; then
	echo "p1: size=${SDP1SS}, type=${SDP1ID}" >> ${SDPARTINFO}
fi
if [ "${SDP2SB}" -ne 0 ]; then
	echo "p2: size=${SDP2SS}, type=${SDP2ID}" >> ${SDPARTINFO}
fi
if [ "${SDP3SB}" -ne 0 ]; then
	echo "p3: size=${SDP3SS}, type=${SDP3ID}" >> ${SDPARTINFO}
fi
if [ "${SDP4SB}" -ne 0 ]; then
	echo "p4: size=${SDP4SS}, type=${SDP4ID}" >> ${SDPARTINFO}
fi
echo "" >> ${SDPARTINFO}

# Create SD image partition table
LOOPDEV=$(sudo losetup -f --show "${SDTMP}")
echo "Creating partition tables"
#sudo sfdisk "${LOOPDEV}" -q <${SDPARTINFO}
sudo sfdisk "${LOOPDEV}" -q --no-reread --no-tell-kernel < ${SDPARTINFO}

# Refresh loop device by detaching and reattaching with partition scan
sudo losetup -d "${LOOPDEV}"
LOOPDEV=$(sudo losetup -f --show -P "${SDTMP}")

# Copy files
if [ "${SDP1SB}" -ne 0 ]; then
	fmt_mnt "P1" "${LOOPDEV}" ${SDP1FMT} "${SDP1MPATH}"
	copy_files "P1" "${LOOPDEV}" ${SDP1OB} ${SDP1FMT} "${SDP1PATH}" "${SDP1MPATH}"
	sync;
	unmount_part ${SDP1MPATH}
fi

# Copy files
if [ "${SDP2SB}" -ne 0 ]; then
	fmt_mnt "P2" "${LOOPDEV}" ${SDP2FMT} "${SDP2MPATH}"
	copy_files "P2" "${LOOPDEV}" ${SDP2OB} ${SDP2FMT} "${SDP2PATH}" "${SDP2MPATH}"
	sync;
	unmount_part "${SDP2MPATH}"
fi

# Copy files
if [ "${SDP3SB}" -ne 0 ]; then
	fmt_mnt "P3" "${LOOPDEV}" ${SDP3FMT} "${SDP3MPATH}"
	copy_files "P3" "${LOOPDEV}" ${SDP3OB} ${SDP3FMT} "${SDP3PATH}" "${SDP3MPATH}"
	sync;
	unmount_part "${SDP3MPATH}"
fi

# Copy files
if [ "${SDP4SB}" -ne 0 ]; then
	fmt_mnt "P4" "${LOOPDEV}" ${SDP4FMT} "${SDP4MPATH}"
	copy_files "P4" "${LOOPDEV}" ${SDP4OB} ${SDP4FMT} "${SDP4PATH}" "${SDP4MPATH}"
	sync;
	unmount_part "${SDP4MPATH}"
fi

# Rename to final SD image name
mv "${SDTMP}" "${SDIMG}"
echo "SD image created: ${SDIMG}"
