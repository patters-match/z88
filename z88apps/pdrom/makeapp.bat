:: *************************************************************************************
::
:: Z-Help + Z-Macro compile script for DOS/Windows
::
:: *************************************************************************************

@echo off

del /S /Q *.obj *.sym *.bin *.map 2>nul >nul

:: return version of Mpm to command line environment.
:: Only V1.5 or later of Mpm supports macros
mpm -version 2>nul >nul
if ERRORLEVEL 15 goto COMPILE_PDROM
echo Mpm version is less than V1.5, PDrom compilation aborted.
echo Mpm displays the following:
mpm
goto END

:COMPILE_PDROM

:: Assemble the applications for $C000 in bank 62
mpm -b -I..\..\oz\def -rC000 zhelp+zmacro.asm

:END
