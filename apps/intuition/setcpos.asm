
     MODULE Set_CursorPosition

     XREF Display_string
     XDEF Set_CurPos


     INCLUDE "defs.h"


; *************************************************************************************
;
; Set cursor at X,Y position in current window          V0.18
;
; IN:
;         C,B  =  (X,Y)
;
; Register status after return:
;
;       ..BCDEHL/IXIY  same
;       AF....../....  different
;
.Set_CurPos       PUSH HL
                  PUSH BC
                  LD   BC,24
                  PUSH IY
                  POP  HL
                  ADD  HL,BC
                  POP  BC
                  PUSH HL
                  LD   (HL),1               ; VDU 1,'3','@',32+C,32+B
                  INC  HL
                  LD   (HL),'3'
                  INC  HL
                  LD   (HL),'@'
                  INC  HL
                  LD   A,C
                  ADD  A,32
                  LD   (HL),A               ; X coordinate
                  INC  HL
                  LD   A,B
                  ADD  A,32
                  LD   (HL),A               ; Y coordinate
                  INC  HL
                  LD   (HL),0               ; null terminate VDU string
                  POP  HL
                  CALL Display_String       ; execute VDU
                  POP  HL
                  RET
