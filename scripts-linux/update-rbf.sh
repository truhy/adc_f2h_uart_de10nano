#!/bin/bash

set -e
function cleanup {
	rc=$?
	# If error and shell is child level 1 then stay in shell
	if [ $rc -ne 0 ] && [ $SHLVL -eq 1 ]; then exec $SHELL; else exit $rc; fi
}
trap cleanup EXIT

if [ -z "${SCRIPT_PATH+x}" ]; then
	chmod +x ../scripts-env/env-linux.sh
	source ../scripts-env/env-linux.sh
fi

cd "$SCRIPT_PATH"

# Convert .sof to .rbf
quartus_cpf -c -o bitstream_compression=on "$FPGA_SRC_PATH/output_files/$FPGA_PROGRAM_NAME.sof" scripts-linux/sdcard/Debug/c5_fpga.rbf
cp -f scripts-linux/sdcard/Debug/c5_fpga.rbf scripts-linux/sdcard/Release/c5_fpga.rbf
