     XLIB MemReadPointer

     LIB MemDefBank


; ******************************************************************************
;
; Read pointer at record defined as extended (base) address in BHL, offset A.
; Return (extended) pointer in BHL.
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
; $History: MmRdPtr.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 16-04-98   Time: 21:34
; Created in $/Z88/StdLib/Memory
; ----------------------------------------------------------------------
;
;    Register affected on return:
;         AF.CDE../IXIY same
;         ..B...HL/.... different
;
.MemReadPointer     PUSH DE
                    PUSH BC

                    LD   D,0
                    LD   E,A
                    ADD  HL,DE               ; add offset to pointer

                    LD   A,H
                    RLCA
                    RLCA
                    AND  3                   ; top address bits of pointer identify
                    LD   C,A                 ; B = Bank, C = MS_Sx Segment Specifier

                    CALL MemDefBank          ; page in bank temporarily
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    INC  HL
                    LD   A,(HL)
                    EX   DE,HL               ; extended pointer in BHL
                    CALL MemDefBank          ; restore prev. binding

                    POP  BC
                    LD   B,A                 ; BHL is new pointer
                    POP  DE
                    RET
