#!/bin/bash

# *************************************************************************************
#
# Z-Help + Z-Macro compile script for Linux/Unix/MAC OSX
#
# *************************************************************************************

rm -f *.obj *.sym *.bin *.map

# Assemble the applications for $C000 in bank 62
../../tools/mpm/mpm -b -I../../oz/def -rC000 zhelp+zmacro.asm

