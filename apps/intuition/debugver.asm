

     MODULE Debugger_version

     XREF Write_Msg, Display_char, IntHexDisp_H, Display_string, Write_CRLF
     XDEF Debugger_version

     INCLUDE "defs.h"


; **********************************************************************************
.Debugger_version LD   HL, Version          ; display Intuition release version
                  CALL Write_Msg
                  LD   HL, Base_Msg
                  CALL Display_String
                  PUSH IY
                  PUSH IY
                  POP  HL                   ; Get base of variable area in HL
                  SCF
                  CALL IntHexDisp_H         ; display address
                  POP  HL                   ; fetch the copy
                  LD   BC,Int_Worksp-1      ; size of monitor area (0 incl.)
                  ADD  HL,BC
                  LD   A, '-'
                  CALL Display_Char
                  SCF
                  CALL IntHexDisp_H         ; display end of variable area
                  JP   Write_CRLF           ; New Line.

.Base_Msg         DEFM "Buffer:",0
.Version          DEFM "V1.1.1",0         ; see 'history.txt' for development history
