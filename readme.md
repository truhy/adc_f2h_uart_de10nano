# ADC to HPS UART for the Terasic DE10-Nano Development Kit

## Overview

A FPGA design (in Verilog) for the DE10-Nano to reads 12-bit samples from the on-board ADC and sends them to UART0 (the mini USB socket wired to the UART-USB).

In summary, it does the following all within the FPGA fabric:
1. Repeatedly reads ADC sample from channels 0 to 7 from the ADC LTC2308 chip (over SPI serial communication) at 2Hz (slow enough for viewing from a UART terminal)
2. A loop sends a read (when ready) to the existing HPS UART0 (UART-USB) which is wired to the HPS side

Note, the Terasic DE10-Nano CD (zip file) already has an ADC demo, but it uses the NIOS II FPGA softcore processor (instead of the hardware ARM) and also a custom Platform Designer ADC IP.  My version is more plain and perhaps more useful for a beginner.

## Running from USB Blaster II JTAG cable with a script

Requires OpenOCD and Quartus lite or Quartus programmer to be installed and in search paths.
Search paths are set in the scripts folder.

1. Eject SD card if there is one in the slot
2. Connect USB Blaster II cable
3. Connect a USB cable between the UART-USB connector on the DE10-Nano and your computer
4. Start a serial terminal program such as PuTTY and set it to use the correct serial port, with settings 115200 baud, 8 data bits, 1 stop bit, no parity, no control flow
5. On Windows run the script rundemo-win.bat, or on linux run rundemo-linux.sh
6. Wait for U-Boot to boot up and quartus to program the FPGA.  You should see a bunch of U-Boot messages in the serial terminal program
7. The 12-bit sample reads are displayed in hex format

## Running from SD card image

1. Write the sdcard_de10nano.img to a micro SD card.  Use any of these:
   - Win32 Disk Imager (https://sourceforge.net/projects/win32diskimager/)
   - Rufus (https://rufus.ie/en/)
   - balenaEtcher (https://www.balena.io/etcher/)
2. Connect a USB cable between the UART-USB connector on the DE10-Nano and your computer
3. Start a serial terminal program such as PuTTY and set it to use the correct serial port, with settings 115200 baud, 8 data bits, 1 stop bit, no parity, no control flow
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
| top.v                            | Top level Verilog file                              |
| adc_ltc2308.v                    | ADC LTC2308 module                                  |
| uart_dev.v                       | HPS UART module                                     |
| rd_axi.v                         | Basic read axi helper module                        |
| wr_axi.v                         | Basic write axi helper module                       |

## The SD card image is built using the following software versions

- Ubuntu 22.04.1 LTS 64bit
- [Quartus Prime 22.1 Lite Edition for Linux](https://www.intel.co.uk/content/www/uk/en/software/programmable/quartus-prime/download.html)
- [U-Boot source v2022.10](https://github.com/u-boot/u-boot/tree/v2022.10)
- [xPack GNU Arm Embedded Toolchain 13.2.1-1.1](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads)
