:: we leave *.def for other modules
@echo off

del /S /Q *.bin *.map *.obj *.lst *.err *.wrn 2>nul >nul
del /Q bank0\*.def bank2\*.def bank7\*.def 2>nul >nul
