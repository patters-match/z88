
     XLIB GetPointer


; ********************************************************************************
;
;    Get an extended pointer in local address space
;
;    Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
;    IN: HL = local address of pointer.
;
;    OUT: BHL = pointer (HL=offset,B=bank).
;
; Registers changed after return:
;
;    AF.CDE../IXIY  same
;    ..B...HL/....  different
;
.GetPointer         PUSH DE
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    INC  HL
                    LD   B,(HL)
                    INC  HL                       ; B = bank
                    EX   DE,HL                    ; HL = offset in bank
                    POP  DE                       ; BHL = pointer to pointer...
                    RET
