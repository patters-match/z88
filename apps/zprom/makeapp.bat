del *.obj
del *.bin
del *.map
mpm -b -I..\oz\sysdef tokens
mpm -bg -I..\oz\sysdef mthzprom
mpm -b -I..\oz\sysdef -l..\stdlib\standard.lib @zprom
mpm -b -I..\oz\sysdef romhdr
java -jar e:\z88\makeapp.jar -sz 32 zprom.epr tokens.bin 3e0000 mthzprom.bin 3e1200 zprom.bin 3fc000 romhdr.bin 3f3fc0


