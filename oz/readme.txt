
All files in these folders follow some guide lines.

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
        OZ      OS_Esc                          ; Examine special condition


Labels begin at column 1
The assembler begins at column 9
Line comments begin at column 50. 
   
All register input/output parameters in functions or other semantic entity uses
the style from the Developer's Notes.

All variable names and language is plain english.
