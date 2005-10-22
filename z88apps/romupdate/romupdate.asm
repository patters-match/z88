; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005
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
; $Id$
;
; *************************************************************************************

     MODULE RomUpdate


     include "error.def"
     include "director.def"
     include "stdio.def"
     include "memory.def"
     include "fileio.def"
     include "dor.def"

     XREF ApplRomFindDOR, ApplRomFirstDOR, ApplRomNextDOR, ApplRomReadDorPtr
     XREF ApplRomCopyDor

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
                    DEFB 0                        ; I/O buffer / vars for RomUpdate
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW 256                      ; Safe workspace
                    DEFW RomUpd_Entry             ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (none)
                    DEFB 0                        ; bank binding to segment 1 (none)
                    DEFB 0                        ; bank binding to segment 2 (none)
                    DEFB $3F                      ; bank binding to segment 3
                    DEFB AT_Popd                  ; Good Popdown
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
.RomUpd_Entry
                    ld   iy,2
                    add  iy,sp               ; start of 256 byte safe workspace (two bytes above stack pointer)

                    ld   a, sc_ena
                    call_oz(os_esc)          ; enable ESC detection

                    xor  a
                    ld   b,a
                    ld   hl,Errhandler
                    oz   os_erh              ; then install Error Handler...

                    ld   c,3                 ; check slot for an application card
                    ld   de, appName         ; and return pointer DOR for application name (pointed to by DE)
                    call ApplRomFindDOR
                    ret  c                   ; application DOR not found or no application ROM available.

                    push iy
                    pop  de
                    call ApplRomCopyDor      ; copy DOR at (BHL) to (DE)

                    jr   suicide             ; leave popdown...
; *************************************************************************************


; *************************************************************************************
;
; RomUpdate Error Handler
;
.ErrHandler
                    ret  z
                    cp   rc_susp
                    jr   z,dontworry
                    cp   rc_esc
                    jr   z,akn_esc
                    cp   rc_quit
                    jr   z,suicide
                    cp   a
                    ret
.akn_esc
                    ld   a,1                 ; acknowledge esc detection
                    oz   os_esc
.dontworry
                    cp   a                   ; all other RC errors are returned to caller
                    ret
.suicide            xor  a
                    oz   os_bye              ; perform suicide, focus to Index...
.void               jr   void
; *************************************************************************************

.appName            defm "FlashStore", 0     ; application (DOR) name to search for in slot.