     XLIB MemWriteByte

     LIB MemDefBank


; ******************************************************************************
;
; Set byte in C, at pointer in BHL,A.
;
; ----------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, 1995-97
;
; ----------------------------------------------------------------------
; Version History:
;
; $Header$
;
; $History: MmWrbyte.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 16-04-98   Time: 21:36
; Created in $/Z88/StdLib/Memory
; ----------------------------------------------------------------------
;
;    Register affected on return:
;         AFBCDEHL/IXIY same
;         ......../.... different
;
.MemWriteByte       PUSH HL
                    PUSH DE
                    PUSH AF
                    PUSH BC

                    LD   E,A
                    XOR  A
                    LD   D,A
                    ADD  HL,DE                    ; add offset to pointer

                    LD   A,H
                    RLCA
                    RLCA
                    AND  3                        ; top address bits of pointer identify
                    LD   C,A                      ; B = Bank, C = MS_Sx Segment Specifier

                    CALL MemDefBank               ; page in bank temporarily
                    POP  DE
                    LD   (HL),E                   ; write byte at extended address
                    CALL MemDefBank               ; restore prev. binding

                    LD   B,D
                    LD   C,E                      ; BC restored...
                    POP  AF
                    POP  DE
                    POP  HL
                    RET
