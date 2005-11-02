#!/bin/bash

# we leave *.def for other modules

rm -f kernel.bin kernel.map kernel.obj

cd bank0
rm -f *.obj *.bin *.map *.err
cd ../bank1
rm -f *.obj *.bin *.map *.err
cd ../bank2
rm -f *.obj *.bin *.map *.err
cd ../bank3
rm -f *.obj *.bin *.map *.err
cd ../bank6
rm -f *.obj *.bin *.map *.err
cd ../bank7 
rm -f *.obj *.bin *.map *.err

cd ..
