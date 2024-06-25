#!/bin/bash

chmod +x ./parameters.sh
source ./parameters.sh

cd ..
rm -r $SOFTWARE_ROOT
rm -r db
rm -r incremental_db
#rm -r output_files

