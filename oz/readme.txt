-----------------------------------------------------------------------------
Compiling the Z88 ROM from the SVN repository
-----------------------------------------------------------------------------

To compile the Z88 ROM, make sure that you have a compiled the Mpm assembler
first and located it in the /tools/mpm directory. Use you favorite C compiler
on your platform with the supplied make files.

Important: The scripts only work with Mpm assembler V1.1 b7 or later.

Then, just simply execute the rom.bat script (or rom.sh for UNix developers)
and you will have the latest OZ rom compiled from Subversion. Default rom
is UK. You can specify the following country codes to get a localised Z88 ROM:
        DK      Denmark
        FR      France
        SE      Swedish/Finish
        FI      Swedish/Finish

Command line example:
        rom DK
        rom dk

both variations will compile a danish Z88 rom, and stored as 'oz.bin' in the
current directory of the rom compile scripts.


-----------------------------------------------------------------------------
Source code guidelines
-----------------------------------------------------------------------------

All source files in these folders follow some guide lines.

All files and folders are lower case.
All ASCII files contain no tabulator encoding (ASCII 9) for tabulating columns.

Z80 mnemonics:
mnemonics are in lower case.
there's 8 spaces between Z80 instruction and register/parameter, eg.
      ld      hl,0.

Here's a complete example:

.Calculator
        ld      iy, $1FAC
        ld      a, 5
        oz      OS_Esc                          ; Examine special condition


Labels begin at column 1
The assembler begins at column 9
Line comments begin at column 50.

All register input/output parameters in functions or other semantic entity uses
the style from the Developer's Notes.

All variable names and language is plain english.



Z88 Forever!