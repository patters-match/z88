     XLIB MemWriteWord

     LIB MemDefBank


; ******************************************************************************
;
; Set word in DE, at pointer in BHL,A.
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
.MemWriteWord       PUSH HL
                    PUSH AF
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
                    CALL MemDefBank               ; restore prev. binding

                    POP  BC
                    POP  AF
                    POP  HL
                    RET
