
     XLIB MemDefBank

; ******************************************************************************
;
; Bind bank, defined in B, into segment C. Return old bank binding in B.
; This is the functional equivalent of OS_MPB, but much faster.
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
; $History: MmDefbnk.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 16-04-98   Time: 21:25
; Created in $/Z88/StdLib/Memory
; ----------------------------------------------------------------------
;
;    Register affected on return:
;         AF.CDEHL/IXIY same
;         ..B...../.... different
;
.MemDefBank         PUSH HL
                    PUSH AF

                    LD   A,C                 ; get segment specifier ($00, $01, $02 and $03)
                    AND  @00000011
                    OR   $D0
                    LD   H,$04
                    LD   L,A                 ; BC points at soft copy of cur. binding in segment C

                    LD   A,(HL)              ; get no. of current bank in segment
                    CP   B
                    JR   Z, already_bound    ; bank B already bound into segment

                    PUSH BC
                    LD   (HL),B              ; A contains "old" bank number
                    LD   C,L
                    OUT  (C),B               ; bind...

                    POP  BC
                    LD   B,A                 ; return previous bank binding
                    POP  AF
                    POP  HL
                    RET
.already_bound      
                    POP  AF
                    POP  HL
                    RET
