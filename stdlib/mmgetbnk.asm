
     XLIB MemGetBank

; ******************************************************************************
;
; Get current Bank binding for specified segment, defined in C.
; This is the functional equivalent of OS_MGB, but much faster.
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
; $History: MmGetbnk.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 16-04-98   Time: 21:26
; Created in $/Z88/StdLib/Memory
; ----------------------------------------------------------------------
;
;    Register affected on return:
;         AF.CDEHL/IXIY same
;         ..B...../.... different
;
.MemGetBank         PUSH AF
                    PUSH HL

                    LD   A,C                 ; get segment specifier ($00, $01, $02 and $03)
                    AND  $03                 ; preserve only segment specifier...
                    OR   $D0                 ; Bank bindings from address $04D0
                    LD   H,$04
                    LD   L,A                 ; HL points at soft copy of cur. binding in segment C
                    LD   B,(HL)              ; get current bank binding

                    POP  HL
                    POP  AF
                    RET
