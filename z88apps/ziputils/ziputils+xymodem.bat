:: *************************************************************************************
::
:: ZipUp & UnZip & XY-modem compile script for DOS/Windows
::
:: *************************************************************************************

@echo off

:: compile XY-Modem popdown from scratch
cd ..\xymodem
del /S /Q *.obj *.bin *.map 2>nul >nul

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_XYM
echo Mpm version is less than V1.5, XY-Modem compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_XYM

mpm -b -I..\..\oz\def xy-modem.asm
cd ..\ziputils

:: --------------------------------------------------------------------

cd unzip
call makeapp.bat
cd ..

cd zipup
call makeapp.bat
cd ..

:: Create a 16K Rom Card with ZipUp & Unzip & XY-modem
z88card -f ziputils+xymodem.loadmap
