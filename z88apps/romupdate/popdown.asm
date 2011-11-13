; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2009
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

     MODULE RomUpdate


     include "error.def"
     include "director.def"
     include "stdio.def"
     include "memory.def"
     include "fileio.def"
     include "dor.def"
     include "romupdate.def"

     XDEF crctable
     XREF app_main


     ORG $C000

; *************************************************************************************
;
; The Application DOR:
;
.RomUpd_Dor
                    DEFB 0, 0, 0                  ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                      ; DOR type - application ROM
                    DEFB DOREnd0-DORStart0        ; total length of DOR
.DORStart0          DEFB '@'                      ; Key to info section
                    DEFB InfoEnd0-InfoStart0      ; length of info section
.InfoStart0         DEFW 0                        ; reserved...
                    DEFB 'U'                      ; application key letter
                    DEFB RAM_pages                ; RAM pages (I/O buffer / vars for RomUpdate)
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW 0                        ; Safe workspace
                    DEFW RomUpd_Entry             ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (none)
                    DEFB 0                        ; bank binding to segment 1 (none)
                    DEFB 0                        ; bank binding to segment 2 (none)
                    DEFB $3F                      ; bank binding to segment 3
                    DEFB AT_Ugly | AT_Popd        ; Ugly popdown
                    DEFB 0                        ; no caps lock on activation
.InfoEnd0           DEFB 'H'                      ; Key to help section
                    DEFB 12                       ; total length of help
                    DEFW RomUpd_Dor
                    DEFB $3F                      ; point to topics (none)
                    DEFW RomUpd_Dor
                    DEFB $3F                      ; point to commands (none)
                    DEFW RomUpd_Dor
                    DEFB $3F                      ; point to help (none)
                    DEFW RomUpd_Dor
                    DEFB $3F                      ; point to token base (none)
                    DEFB 'N'                      ; Key to name section
                    DEFB NameEnd0-NameStart0      ; length of name
.NameStart0         DEFM "RomUpdate",0
.NameEnd0           DEFB $FF
.DOREnd0
; *************************************************************************************


; *************************************************************************************
;
; We are somewhere in segment 3...
;
; Entry point for ugly popdown...
;
.RomUpd_Entry
                    JP   init_main
                    SCF
                    RET
; *************************************************************************************


; *************************************************************************************
.init_main
                    LD   A,(IX+$02)          ; IX points at information block
                    CP   $20+RAM_pages       ; get end page+1 of contiguous RAM
                    CALL NC, app_main        ; end page OK, RAM allocated...

                    LD   A,$07               ; return to Index
                    CALL_OZ(Os_Bye)

                    DEFS $100-($PC%$100)     ; adjust code to position tables at xx00 address

                    INCLUDE "crctable.asm"
