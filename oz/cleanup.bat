;REM we leave *.def for other modules


del /S kernel.bin kernel.map kernel.obj

cd bank0
del *.obj *.bin *.map *.err

cd ..\bank1
del *.obj *.bin *.map *.err

cd ..\bank2
del *.obj *.bin *.map *.err

cd ..\bank3
del *.obj *.bin *.map *.err

cd ..\bank6
del *.obj *.bin *.map *.err

cd ..\bank7 
del *.obj *.bin *.map *.err

cd ..
