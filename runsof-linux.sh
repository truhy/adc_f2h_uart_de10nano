#!/bin/bash

set -e
function cleanup {
	rc=$?
	# If error and shell is child level 1 then stay in shell
	if [ $rc -ne 0 ] && [ $SHLVL -eq 1 ]; then exec $SHELL; else exit $rc; fi
}
trap cleanup EXIT

if [ -z "${SCRIPT_PATH+x}" ]; then
	#chmod +x scripts/env-linux.sh
	source scripts/env-linux.sh
fi

cd $SCRIPT_PATH

openocd -f interface/altera-usb-blaster2.cfg -f target/altera_fpgasoc_de.cfg -c "init; halt; c5_reset; halt; c5_spl bsp/u-boot-spl-nocache-f2h; shutdown"

# Program .sof to the FPGA
# Parameters: -c 1 = selects J-TAG cable number 1, @2 is referring to device index on the J-TAG chain (1 = HPS SoC CPU, 2 = Cyclone V FPGA)
quartus_pgm -m jtag -c 1 -o "p;$FPGA_SRC_PATH\output_files\$FPGA_PROGRAM_NAME.sof@2"
