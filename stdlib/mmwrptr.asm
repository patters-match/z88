     XLIB MemWritePointer

     LIB MemDefBank


; ******************************************************************************
;
; Set pointer in CDE, at pointer in BHL,A.
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
.MemWritePointer    PUSH HL
                    PUSH AF
                    PUSH DE
                    PUSH BC
                    PUSH DE

                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; add offset to pointer

                    LD   A,H
                    RLCA
                    RLCA
                    AND  3                        ; top address bits of pointer identify
                    LD   C,A                      ; B = Bank, C = MS_Sx Segment Specifier

                    CALL MemDefBank               ; page in bank temporarily
                    POP  DE
                    LD   (HL),E                   ; write word at extended address
                    INC  HL
                    LD   (HL),D
                    INC  HL
                    POP  DE
                    LD   (HL),E                   ; C (write bank specifier of pointer CDE)
                    CALL MemDefBank               ; restore prev. binding (original B register)

                    LD   C,E                      ; BC restored
                    POP  DE
                    POP  AF
                    POP  HL
                    RET
