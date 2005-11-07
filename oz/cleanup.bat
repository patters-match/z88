:: we leave *.def for other modules
@echo off

del /S /Q kernel.bin kernel.map kernel.obj kernel.bn? 2>nul >nul

cd bank0
del /S /Q *.obj *.bin *.map *.err *.wrn 2>nul >nul

cd ..\bank1
del /S /Q *.obj *.bin *.map *.err *.wrn 2>nul >nul

cd ..\bank2
del /S /Q *.obj *.bin *.map *.err *.wrn 2>nul >nul

cd ..\bank3
del /S /Q *.obj *.bin *.map *.err *.wrn 2>nul >nul

cd ..\bank6
del /S /Q *.obj *.bin *.map *.err *.wrn 2>nul >nul

cd ..\bank7 
del /S /Q *.obj *.bin *.map *.err *.wrn 2>nul >nul

cd ..
