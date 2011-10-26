This is the "Public Domain ROM". It contains 4 applications by Richard Haw,
released in 1989:

Z-Help:
        Some useful information about the Z88, including CLI files and
        cable descriptions.
Z-Macro:
        Allows you to define macro commands available from any application.
Utilities:
        Memory dump utility.
Graphics:
        Utility to display Z-Image format graphics file. A sample file,
        demo.img, is also provided.

Full source is not avaliable for this ROM, so the binary bank images (and an
emulator version) are provided here.

The zhelp+zmacro.mth image is an extraction of the MTH structures for the
two most useful applications in the ROM, and is used in the Z88 Forever
compilation ROM. This image file should be located at $C000 in bank 63,
and is designed for the applications to be loaded at $C000 in bank 62.

The zhelp+zmacro.asm source file contains reverse-engineered source-code
for the Z-Help and Z-Macro applications. This file was created with the aid
of the dZ80 utility.

The makeapp scripts build the Z-Help and Z-Macro applications for inclusion
in the Z88 Forever compilation ROM.


Garry Lancaster, 26th October 2011
