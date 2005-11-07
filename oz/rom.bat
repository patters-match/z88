:: get OZ localisation locale compilation directive
set ozlocale=%1

:: if no locale is specified, use default UK
if "%ozlocale%"=="" set ozlocale=UK

call kernel %ozlocale%
cd bank1
call bank1
cd ..\bank2
call bank2
cd ..\bank3
call bank3
cd ..\bank6
call bank6
cd ..
copy /B kernel.bn1+bank1\bank1.bin+bank2\bank2.bin+bank3\bank3.bin+banks45\pipedrm.dat+bank6\bank6.bin+kernel.bn0 oz.bin
