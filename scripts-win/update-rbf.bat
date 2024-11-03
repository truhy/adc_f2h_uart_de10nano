@IF NOT DEFINED APP_HOME_PATH CALL ..\scripts-env\env-win.bat

@CD "%APP_HOME_PATH%"

:: Convert .sof to .rbf
quartus_cpf -c -o bitstream_compression=on "%FPGA_SRC_PATH%\output_files\%FPGA_PROGRAM_NAME%.sof" scripts-linux\sdcard\Debug\c5_fpga.rbf
COPY /Y scripts-linux\sdcard\Debug\c5_fpga.rbf scripts-linux\sdcard\Release\c5_fpga.rbf

:: If run from double-click
@IF /I %0 EQU "%~dpnx0" @PAUSE
