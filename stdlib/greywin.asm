
     XLIB GreyApplWindow

     INCLUDE "stdio.def"


; **********************************************************************************************************
;
; Grey Application window (using base window "1")
;
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.GreyApplWindow     PUSH AF
                    PUSH HL
                    LD   HL,greywindow                  ; use base window
                    CALL_OZ(Gn_Sop)                     ; then grey window...
                    POP  HL
                    POP  AF
                    RET
.greywindow         DEFM 1,"7#1",$20,$20,32+$5E,$28,128,1,"2H1" ; window VDU definitions
                    DEFM 1,"2H1",1,"2G+",0
