REM create binaries for lowram and application data
mpm -bg -nv -IC:\CVS\oz\sysdef lowram.asm
REM mpm -bg -nv -IC:\CVS\oz\sysdef appdors.asm

REM compile kernel to resolve labels for lowram.asm
mpm -bg -nv -IC:\CVS\oz\sysdef @kernel.prj

REM create lowram.bin with correct addresses
mpm -b -nv -DFINAL -IC:\CVS\oz\sysdef lowram.asm

REM compile kernel with correct lowram code
mpm -b -nv -IC:\CVS\oz\sysdef @kernel.prj

del *.obj
