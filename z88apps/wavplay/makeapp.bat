:: *************************************************************************************

@echo off

del /S /Q *.bin *.63 *.epr 2>nul >nul

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_WAVPLAY
echo Mpm version is less than V1.5, RomUpdate compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_WAVPLAY

mpm -b -I../../oz/def wavplay

:END