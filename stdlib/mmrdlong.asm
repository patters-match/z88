     XLIB MemReadLong

     LIB MemDefBank


; ******************************************************************************
;
; Read long integer (in debc) at pointer in BHL,A.
;
; ----------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, 1997
;
; ----------------------------------------------------------------------
; Version History:
;
; $Header$
;
; $History: Mmrdlong.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 16-04-98   Time: 21:30
; Created in $/Z88/StdLib/Memory
; ----------------------------------------------------------------------
;
;    Register affected on return:
;         ..BCDEHL/IXIY .......  same
;         AF....../.... afbcdehl different
;
.MemReadLong        PUSH HL
                    PUSH DE
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
                    PUSH HL
                    EXX
                    POP  HL
                    LD   C,(HL)
                    INC  HL
                    LD   B,(HL)
                    INC  HL
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    EXX
                    CALL MemDefBank               ; restore prev. binding

                    POP  BC
                    POP  DE
                    POP  HL
                    RET
