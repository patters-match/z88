     XLIB MemAbsPtr

     LIB SafeSegmentMask

; ************************************************************************
;
; Convert relative BHL pointer for slot number A (0 to 3) to absolute
; pointer, addressed for safe bank binding segment.
;
; Internal Support Library Routine.
;
; ----------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, April 1998
;
; ----------------------------------------------------------------------
; Version History:
;
; $Header$
;
; $History: MmAbsPtr.asm $
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 16-04-98   Time: 21:21
; Created in $/Z88/StdLib/Memory
; ----------------------------------------------------------------------
;
; IN:
;    A = slot number (0 to 3)
;    BHL = relative pointer 
;
; OUT:
;    BHL pointer, absolute addressed for physical slot C, and specific segment.
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.MemAbsPtr
                    AND  @00000011                ; only 0 - 3 allowed...
                    RRCA                          ;
                    RRCA                          ; Slot number A converted to slot mask
                    RES  7,B
                    RES  6,B                      ; clear before masking to assure proper effect...
                    OR   B
                    LD   B,A                      ; B = converted to physical bank of slot A
                    CALL SafeSegmentMask          ; Get a safe segment address mask
                    RES  7,H
                    RES  6,H
                    OR   H                        ; for bank I/O (outside this executing code)
                    LD   H,A                      ; offset mapped for specific segment
                    RET
