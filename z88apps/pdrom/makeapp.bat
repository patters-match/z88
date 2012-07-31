:: *************************************************************************************
::
:: Z-Help + Z-Macro compile script for DOS/Windows
::
:: *************************************************************************************

del *.obj *.sym *.bin *.map

:: Assemble the applications for $C000 in bank 62
mpm -b -I..\..\oz\def -rC000 zhelp+zmacro.asm

