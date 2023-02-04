#!/bin/bash

chmod +x ../parameters.sh
source ../parameters.sh

$QUARTUS_BIN/quartus_cpf -c -o bitstream_compression=on ../../output_files/adc_f2h_uart.sof soc_system.rbf

