#!/bin/bash
rm -f *.obj *.bin *.map *.epr
../../csrc/mpm/mpm -bv -I../oz/sysdef -l../stdlib/standard.lib @flashstore
../../csrc/mpm/mpm -bv romhdr
java -jar ../../makeapp.jar flashstore.epr fsapp.bin 3f0000 romhdr.bin 3f3fc0
java -jar ../../z88.jar ram1 1024 epr2 128 27c crd3 1024 28f flashstore.epr
