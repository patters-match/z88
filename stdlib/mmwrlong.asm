     XLIB MemWriteLong

     LIB MemDefBank


; ******************************************************************************
;
; Set long integer in debc, at pointer in BHL,A.
; Segment specifier must be included in HL.
;
; ----------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, 1995-98
;
; ----------------------------------------------------------------------
; Version History:
;
; $Header$
;
; $History: $
; 
; ----------------------------------------------------------------------
;
;    Register affected on return:
;         AFBCDEHL/IXIY same
;         ......../.... different
;
.MemWriteLong       PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; add offset to pointer

                    LD   A,H
                    RLCA
                    RLCA
                    AND  3                        ; top address bits of pointer identify
                    LD   C,A                      ; B = Bank, C = MS_Sx Segment Specifier

                    CALL MemDefBank               ; page in bank temporarily
                    PUSH HL
                    EXX
                    POP  HL
                    LD   (HL),C                   ; write long at extended address
                    INC  HL
                    LD   (HL),B
                    INC  HL
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D
                    EXX
                    CALL MemDefBank               ; restore prev. binding (original B register)

                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET
