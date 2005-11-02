#!/bin/bash

./kernel.sh
cd bank1
./bank1.sh
cd ../bank2
./bank2.sh
cd ../bank3
./bank3.sh
cd ../bank6
./bank6.sh
cd ..

cp -f kernel.bn1 bank1/bank1.bin bank2/bank2.bin bank3/bank3.bin banks45/pipedrm.dat bank6/bank6.bin kernel.bn0 > oz.bin
