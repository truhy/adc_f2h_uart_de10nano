#!/bin/bash

chmod +x ./parameters.sh
source ./parameters.sh

cd ..

# Delete temporary folders and files
rm -r $SOFTWARE_ROOT
rm -r db
rm -r incremental_db
#rm -r output_files

