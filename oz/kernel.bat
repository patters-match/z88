:: create binaries for lowram and application data
cd bank7
..\..\tools\mpm\mpm -btg -nv -I..\sysdef lowram.asm
..\..\tools\mpm\mpm -bg -nv -I..\sysdef appdors.asm
cd ..

:: compile kernel to resolve labels for lowram.asm
..\tools\mpm\mpm -bg -nv -DKB%1 -I.\sysdef @kernel.prj

:: create lowram.bin with correct addresses
cd bank7
..\..\tools\mpm\mpm -bt -nv -DFINAL -I..\sysdef lowram.asm
cd ..

:: compile kernel with correct lowram code
..\tools\mpm\mpm -bc -nv -DKB%1 -I.\sysdef @kernel.prj
