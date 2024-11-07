@ECHO OFF

:: Get the parent folder path (one level up) from this script's path
FOR %%i IN ("%~dp0..") DO SET "SCRIPT_PATH=%%~fi"
::FOR %%i IN ("%~dp0..") DO SET "SCRIPT_PATH=%%~dpi"

:: Tools settings
SET MAKE_PATH=C:\devtools\xpack-windows-build-tools-4.4.1-2\bin
SET TOOLCHAIN_PATH=C:\devtools\xpack-arm-none-eabi-gcc-13.2.1-1.1\bin
SET OPENOCD_PATH=C:\devtools\xpack-openocd-0.12.0-2\bin
IF "%QUARTUS_ROOTDIR%"=="" SET QUARTUS_ROOTDIR=C:\intelFPGA\22.1std\qprogrammer

:: Application settings
SET APP_HOME_PATH=%SCRIPT_PATH%
SET APP_OUT_PATH=.

:: FPGA settings
SET FPGA_SRC_PATH=source
SET FPGA_PROGRAM_NAME=adc_f2h_uart

:: Other stuff
CALL :NORMALIZEPATH %APP_OUT_PATH%
SET APP_OUT_FULL_PATH=%RETVAL%

:: Search path settings
SET path=%path%;%SCRIPT_PATH%\scripts-env;%SCRIPT_PATH%\scripts-win
IF "%MAKE_PATH%" NEQ "" SET path=%path%;%MAKE_PATH%
IF "%TOOLCHAIN_PATH%" NEQ "" SET path=%path%;%TOOLCHAIN_PATH%
IF "%OPENOCD_PATH%" NEQ "" SET path=%path%;%OPENOCD_PATH%
IF "%QUARTUS_ROOTDIR%" NEQ "" SET path=%path%;%QUARTUS_ROOTDIR%\bin64

:: Messages
IF "%MAKE_PATH%" NEQ ""       ECHO Make     : %MAKE_PATH%
IF "%TOOLCHAIN_PATH%" NEQ ""  ECHO Toolchain: %TOOLCHAIN_PATH%
IF "%OPENOCD_PATH%" NEQ ""    ECHO OpenOCD  : %OPENOCD_PATH%
IF "%QUARTUS_ROOTDIR%" NEQ "" ECHO Quartus  : %QUARTUS_ROOTDIR%

EXIT /B

:NORMALIZEPATH
  SET RETVAL=%~f1
  EXIT /B
