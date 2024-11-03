#!/bin/bash

if [ -z "${APP_HOME_PATH+x}" ]; then
	source ../scripts-env/env-linux.sh
fi

# Clean prepared U-Boot source code
cd "$APP_HOME_PATH/scripts-linux/uboot"
echo "Clean prepared U-Boot source"
#make -C "$APP_HOME_PATH/scripts-linux/uboot" --no-print-directory -f Makefile-prep-ub.mk clean
make -f Makefile-prep-ub.mk clean

# If shell is child level 1 (e.g. Run as a Program) then stay in shell
if [ $SHLVL -eq 1 ]; then exec $SHELL; fi
