

     MODULE Memory_range

     INCLUDE "defs.h"


     XREF Display_char, IntHexDisp_H, Display_string, Write_CRLF

     XDEF Memory_Range


; **********************************************************************************
.Memory_range     LD   HL, range_msg
                  CALL Display_string
                  LD   HL, $2000
                  SCF
                  CALL IntHexDisp_H         ; display address
                  LD   A, '-'
                  CALL Display_Char
                  LD   L,0
                  LD   H,(IY + RamTopPage ) ; RAM top  (start addr of memory back to OZ)
                  DEC  HL
                  SCF
                  CALL IntHexDisp_H         ; display end of variable area
                  CALL Write_CRLF           ; New Line.
                  RET

.range_Msg        DEFM "Memory Range: ",0
