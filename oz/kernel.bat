:: create binaries for lowram and application data
..\tools\mpm\mpm -bg -nv -I.\sysdef bank7\lowram.asm
..\tools\mpm\mpm -bg -nv -I.\sysdef bank7\appdors.asm

:: compile kernel to resolve labels for lowram.asm
..\tools\mpm\mpm -bg -nv -DKB%1 -I.\sysdef @kernel.prj

:: create lowram.bin with correct addresses
..\tools\mpm\mpm -b -nv -DFINAL -I.\sysdef bank7\lowram.asm

:: compile kernel with correct lowram code
..\tools\mpm\mpm -bc -nv -DKB%1 -I.\sysdef @kernel.prj
