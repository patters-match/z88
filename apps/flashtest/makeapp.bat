del flashtest.epr
del appl.bin
mpm -t -I..\oz\sysdef -l..\stdlib\standard.lib -b appl.asm
mpm -b romhdr.asm
java -jar e:\z88\makeapp.jar flashtest.epr appl.bin 0000 romhdr.bin 3fc0