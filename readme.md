# ADC to HPS UART for the Terasic DE10-Nano Development Kit

## Overview

A FPGA design (in Verilog) for the DE10-Nano that reads 12-bit samples from the built-in ADC and sends them to UART0 (built-in UART-USB).

In summary, it does the following all within in the FPGA fabric:
1. Repeatedly reads Channel 0 ADC sample data from the builtin ADC LTC2308 chip using SPI serial communication
2. A loop sends a read (when ready) to the existing HPS UART0 (UART-USB) which is wired to the HPS side

Note, there is an ADC demo on the the DE10-Nano CD, but it uses the NIOS II softcore processor and the ADC IP is a custom Platform Designer IP.  My version is more plain and perhaps more useful for a beginner.

## Running instructions

1. Write the sdcard_de10nano.img to a micro SD card.  Use any of these:
   - Win32 Disk Imager (https://sourceforge.net/projects/win32diskimager/)
   - Rufus (https://rufus.ie/en/)
   - balenaEtcher (https://www.balena.io/etcher/)
2. Connect a USB cable between the UART-USB connector on the DE10-Nano and your computer
3. Start a serial console program such as PuTTY and set it to serial mode, 115200 baud, 8 data bits, 1 stop bit, no parity, no control flow
4. Insert the micro SD card into the DE10-Nano and turn on the 5V power supply
5. Wait for U-Boot to boot up.  You should see a bunch of U-Boot messages and then stop with a console prompt
6. The 12-bit sample reads are displayed in hex format

Note, I've configured U-Boot to boot only to the console prompt.

## Main files

A Quartus Prime Lite Verilog HDL project:

| File                             | Description                                         |
| -------------------------------- | --------------------------------------------------- |
| sdcard_image/sdcard_de10nano.img | A prebuilt SD card image                            |
| adc_f2h_uart.qpf                 | Quartus Prime Lite project file                     |
| adc_f2h_uart.qsf                 | Quartus Prime Lite settings file                    |
| adc_f2h_uart.v                   | Top level Verilog file                              |
| adc_ltc2308.v                    | ADC LTC2308 module                                  |
| uart_dev.v                       | HPS UART module                                     |
| rd_axi.v                         | Basic read axi helper module                        |
| wr_axi.v                         | Basic write axi helper module                       |

## The SD card image is built using the following software versions

- Ubuntu 20.04.1 LTS 64bit
- [Quartus Prime 21.1 Lite Edition for Linux](https://www.intel.co.uk/content/www/uk/en/software/programmable/quartus-prime/download.html)
- [Quartus SoC EDS 20.1 for Linux](https://fpgasoftware.intel.com/soceds)
- [U-Boot source v2022.01](https://github.com/u-boot/u-boot/tree/v2022.01)
- [GNU Arm Embedded Toolchain 10.3-2021.07 for Linux x86 64](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads)
