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

     MODULE Main

     xdef app_main

     include "error.def"
     include "director.def"
     include "stdio.def"
     include "memory.def"
     include "fileio.def"
     include "dor.def"
     include "romupdate.def"

     XREF ApplRomFindDOR, ApplRomFirstDOR, ApplRomNextDOR, ApplRomReadDorPtr
     XREF ApplRomCopyDor
     XREF CrcFile, CrcBuffer


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


; *************************************************************************************
.app_main
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

                    ld   bc,80               ; local filename (pointer)..
                    ld   hl,filename         ; filename to card image
                    ld   de,buffer           ; output buffer for expanded filename (max 255 byte)...
                    ld   a, op_in
                    oz   GN_Opf
                    ret  c                   ; couldn't open file (in use / not found?)...

                    ld   de,buffer
                    ld   bc,16384            ; 16K buffer
                    call CrcFile             ; calculate CRC-32 of file
                    oz   GN_Cl               ; close file again (we got the expanded filename)

                    ld   hl,buffer
                    ld   bc,16384            ; 16K buffer
                    call CrcBuffer           ; calculate CRC-32 of buffer (should be the same as above)

                    jp   suicide             ; leave popdown...
; *************************************************************************************


.appName            defm "FlashStore", 0     ; application (DOR) name to search for in slot.
.filename           defm ":RAM.0/flashstore.epr", 0     ; 16K card image