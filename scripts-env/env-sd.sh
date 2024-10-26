#!/bin/bash

# SD image total size in bytes or with a prefix K, M or G
export SDSZ=16M
# Partition size in bytes or with a prefix K, M or G. Set partition size to 0 if not required
export SDP1SZ=14M
export SDP2SZ=1M
export SDP3SZ=0M
export SDP4SZ=0M
# Partition type ID, e.g. a2 (Cyclone V SoC), 0b (FAT32), 83 (Linux), 82 (Linux swap)
export SDP1ID=0b
export SDP2ID=a2
export SDP3ID=83
export SDP4ID=82
# Partition file system type, e.g. raw, vfat, ext2, ext3, ext4
export SDP1FMT=vfat
export SDP2FMT=raw
export SDP3FMT=ext4
export SDP4FMT=raw
