
     MODULE ExtRoutine_uppersegment0

     LIB ExtCall

     XDEF ExtRoutine_s01


; ******************************************************************************
;
;
.ExtRoutine_s01   PUSH IX
                  EXX
                  LD   HL,$04D0
                  LD   B,(HL)
                  SET  0,B
                  LD   C,0
                  POP  HL
                  EXX
                  CALL ExtCall              ; then dump contents of Z80 registers
                  RET

