; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2004
;
; FlashStore is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

Module CatalogFiles

; This module contains the Catalog Files command

     xdef CatalogCommand

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
     lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprFileStatus         ; Return Active/Deleted status of file entry
     lib FileEprCntFiles           ; Return total of active and deleted files

     xref GetFirstFilePtr          ; browse.asm
     xref GetNextFilePtr           ; browse.asm
     xref FilesAvailable           ; browse.asm
     xref CompressedFileEntryName  ; browse.asm
     xref endf_msg                 ; browse.asm
     xref rightjustify             ; fsapp.asm
     xref leftjustify              ; fsapp.asm
     xref cls, yesno, no_msg       ; fsapp.asm
     xref pwait, rdch              ; fsapp.asm
     xref disp_no_filearea_msg     ; errmsg.asm
     xref no_files                 ; errmsg.asm
     xref IntAscii                 ; filestat.asm
     xref done_msg                 ; fetchfile.asm

     ; system definitions
     include "stdio.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"



; *************************************************************************************
;
; Display name and size of stored files on Flash Eprom.
;
.CatalogCommand
                    call cls                     ; select main window and clear it...

                    call FilesAvailable
                    jp   c, disp_no_filearea_msg
                    jp   z, no_files             ; Fz = 1, no files available...

                    xor  a
                    ld   (linecnt),a

                    ld   a,(curslot)
                    ld   c,a
                    call GetFirstFilePtr         ; BHL = first file entry
.cat_main_loop
                    push bc
                    push hl

                    ld   de, buf3                 ; write filename at (DE), null-terminated
                    call CompressedFileEntryName  ; copy filename from current file entry

                    call FileEprFileStatus
                    call CatalogueFile            ; catalogue current file
.get_next_filename
                    call GetNextFilePtr           ; get pointer to next File Entry in BHL...
                    jr   c, end_cat

                    pop  de
                    pop  de                       ; get rid of old BHL
                    push bc
                    push hl

                    ld   hl, linecnt
                    inc  (hl)
                    ld   a,7
                    cp   (hl)
                    jr   nz,next_row
                    ld   (hl),0
                    call pwait
                    cp   RC_ESC
                    jr   nz,new_page
                    pop  hl
                    pop  bc
                    ret
.new_page
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    jr   nc,ok_new_page
                    call cls
                    call disp_no_filearea_msg
                    pop  hl
                    pop  bc
                    scf
                    RET
.ok_new_page
                    pop  hl
                    pop  bc
                    call FilesAvailable
                    jp   c, disp_no_filearea_msg
                    jp   z, no_files              ; Fz = 1, no files available...
                    call cls
                    jr   cat_main_loop            ; display the next file in a fresh new window...
.next_row
                    CALL_OZ gn_nln
                    pop  hl
                    pop  bc
                    jr   cat_main_loop

.norm_aff           ld   hl,norm_sq
                    jr   dispsq
.tiny_aff           ld   hl,tiny_sq
                    jr   dispsq
.jrsz_aff           ld   hl, rightjustify
                    jr   dispsq
.jnsz_aff           ld   hl, leftjustify
.dispsq             push af
                    CALL_OZ gn_sop
                    pop  af
                    ret
.end_cat
                    pop  hl
                    pop  bc
                    CALL_OZ gn_nln
                    ld   hl,endf_msg
                    CALL_OZ gn_sop
                    call pwait
                    ret
.CatalogueFile
                    push bc
                    push hl

                    push de
                    call nz,norm_aff
                    call z,tiny_aff
                    pop  hl
                    CALL_OZ(Gn_sop)               ; display filename

                    pop  hl
                    pop  bc
                    push bc
                    push hl
                    call FileEprFileSize          ; get size of File Entry in CDE
                    ld   (flen),de
                    ld   b,0
                    ld   (flen+2),bc

                    call jrsz_aff
                    ld   hl,flen
                    call IntAscii
                    CALL_OZ gn_sop                ; display size of current File Entry
                    call jnsz_aff
                    pop  hl
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; constants

.norm_sq            DEFM "F ",0
.tiny_sq            DEFM "d ",0
