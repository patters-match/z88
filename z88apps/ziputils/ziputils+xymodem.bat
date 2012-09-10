:: *************************************************************************************
::
:: ZipUp & UnZip & XY-modem compile script for DOS/Windows
::
:: *************************************************************************************

:: compile XY-Modem popdown from scratch
cd ..\xymodem
del *.obj *.bin *.map
..\..\tools\mpm\mpm -b -I..\..\oz\def xy-modem.asm
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
