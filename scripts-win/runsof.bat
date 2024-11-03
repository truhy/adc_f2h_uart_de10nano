@IF NOT DEFINED APP_HOME_PATH CALL scripts-env\env-win.bat

@CD %APP_HOME_PATH%

openocd -f interface/altera-usb-blaster2.cfg -f target/altera_fpgasoc_de.cfg -c "init; halt; c5_reset; halt; c5_spl bsp/u-boot-spl-nocache-f2h; shutdown"
@IF %errorlevel% NEQ 0 GOTO :err_handler

:: Program .sof to the FPGA
:: Parameters: -c 1 = selects J-TAG cable number 1, @2 is referring to device index on the J-TAG chain (1 = HPS SoC CPU, 2 = Cyclone V FPGA)
quartus_pgm -m jtag -c 1 -o "p;%FPGA_SRC_PATH%\output_files\%FPGA_PROGRAM_NAME%.sof@2"
@IF %errorlevel% NEQ 0 GOTO :err_handler

@GOTO :end_of_script

:err_handler
:: If run from double-click
@IF /I %0 EQU "%~dpnx0" @PAUSE

:end_of_script
