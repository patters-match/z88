
     MODULE ExtRoutine_uppersegment0

     LIB ExtCall

     XDEF ExtRoutine_s00


; ******************************************************************************
;
;
.ExtRoutine_s00   PUSH IX
                  EXX
                  LD   HL,$04D0
                  LD   B,(HL)
                  RES  0,B                  ; bind in lower half of bank
                  LD   C,0                  ; into upper half of segment 0
                  POP  HL
                  EXX
                  CALL ExtCall
                  RET

