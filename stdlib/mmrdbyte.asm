     XLIB MemReadByte

     LIB MemDefBank


; ******************************************************************************
;
; Read byte at pointer in BHL, offset A. Return byte in A.
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
; $History: Mmrdbyte.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 16-04-98   Time: 21:29
; Created in $/Z88/StdLib/Memory
; ----------------------------------------------------------------------
;
;    Register affected on return:
;         ..BCDEHL/IXIY same
;         AF....../.... different
;
.MemReadByte        PUSH HL
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
                    LD   A,(HL)                   ; read byte at extended address
                    CALL MemDefBank               ; restore prev. binding

                    POP  BC
                    POP  DE
                    POP  HL
                    RET
