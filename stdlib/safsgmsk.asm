
     XLIB SafeSegmentMask

     LIB ApplSegmentMask

     include "memory.def"

; ********************************************************************
;
; This library routine returns a complement segment mask
; that's outside the scope of the executing code (in a bound bank).
;
; The sole purpose of this is for the application to
; determine another segment than which the application executes in
; at this point of call (the current segment of the PC), to be
; used for reading extended pointer information without swapping
; out the executing program, resided in a potential identical segment.
;
;    In:
;         None
;    Out:
;         A = Safe MM_Sx, but never in segment 0.
;
;    Registers changed after return:
;         ..BCDEHL/IXIY same
;         AF....../...  different
;
.SafeSegmentMask    CALL ApplSegmentMask     ; get MM_Sx of this executing code
                    CPL
                    AND  @11000000           ; preserve only segment mask
                    OR   MM_S1               ; never to segment 0...
                    RET                      ; return safe MM_Sx segment mask
