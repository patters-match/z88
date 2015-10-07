#!/bin/bash

rm -f *.bin *.63 *.epr

# return version of Mpm to command line environment.
# validate that MPM is V1.5 or later - only this version or later supports macros
MPM_VERSIONTEXT=`mpm -version`

if test $? -lt 15; then
  echo Mpm version is less than V1.5, WavPlay compilation aborted.
  echo Mpm displays the following:
  mpm
  exit 1
fi

mpm -b -I../../oz/def wavplay

