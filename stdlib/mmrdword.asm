     XLIB MemReadWord

     LIB MemDefBank


; ******************************************************************************
;
; Read word at record defined as extended (base) address in BHL, offset A.
; Segment mask must be specified in H.
;
; Return word in DE.
;
; ----------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, July 1998
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
;         AFBC..HL/IXIY same
;         ....DE../.... different
;
.MemReadWord        PUSH HL
                    PUSH BC
                    PUSH AF

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
                    CALL MemDefBank          ; restore prev. binding

                    POP  AF
                    POP  BC
                    POP  HL
                    RET
