#!/bin/bash

if [ -z "${SCRIPT_PATH+x}" ]; then
	source ../../scripts-env/env-linux.sh
fi

if [ $SHLVL -eq 1 ]; then exec $SHELL; fi
