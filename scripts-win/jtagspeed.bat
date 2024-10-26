@IF NOT DEFINED BM_HOME_PATH CALL ..\scripts-env\env-win.bat

@CD "%BM_HOME_PATH%"

jtagconfig --setparam 1 JtagClock 24M

@GOTO :end_of_script

:err_handler
:: If run from double-click
@IF /I %0 EQU "%~dpnx0" @PAUSE

:end_of_script
