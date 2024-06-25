#!/bin/bash

#chmod +x scripts/env-linux.sh
source scripts/env-linux.sh

# If shell is child level 1 (e.g. Run as a Program) then stay in shell
if [ $SHLVL -eq 1 ]; then exec $SHELL; fi
