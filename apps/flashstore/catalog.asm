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

     xdef CatalogCommand, FilesAvailable

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
     lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprCntFiles           ; Return total of active and deleted files

     xref IntAscii
     xref disp_no_filearea_msg
     xref cls, rightjustify, leftjustify
     xref yesno, no_msg, done_msg
     xref pwait, rdch

     xref no_files                 ; errmsg.asm

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
                    call cls

                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    pop  bc
                    jr   z, check_availfiles     ; File Area header was found..
                    call disp_no_filearea_msg
                    ret                          ; abort - File Area apparently not available...
.check_availfiles
                    call FilesAvailable
                    jp   z, no_files             ; Fz = 1, no files available...
.files_available
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprFirstFile         ; return BHL pointer to first File Entry
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e
                    pop  de
                    jr   nz, dispfirstentry       ; is it the hidden system file entry?
                         call FileEprNextFile     ; yes, skip it and display rest of filenames...
.dispfirstentry
                    ld   a,b
                    ld   (fbnk),a
                    ld   (fadr),hl
                    jr   nc, init_cat

                    CALL no_files
                    RET
.init_cat
                    ld   iy,status
                    res  0,(iy+0)                 ; preset to ignore del. files
                    res  1,(iy+0)                 ; preset to no lines displayed

                    xor  a
                    ld   hl, linecnt
                    ld   (hl),a

                    ld   hl, disp_prompt_delfiles_msg
                    ld   de, no_msg
                    call yesno
                    jr   nz, begin_catalogue
                    set  0,(iy+0)                 ; display all files...
.begin_catalogue
                    call cls
.cat_main_loop
                    ld   a,(fbnk)
                    ld   b,a
                    ld   hl,(fadr)
                    ld   de, buf3            ; write filename at (DE), null-terminated
                    call FileEprFilename     ; copy filename from current file entry
                    jp   c, end_cat          ; Ups - last file(name) has been displayed...
                    jr   nz, disp_filename   ; active file, display...

                    ex   af,af'
                    bit  0,(iy+0)
                    jr   z,get_next_filename ; ignore deleted file(name)...
                    ex   af,af'

.disp_filename      set  1,(iy+0)            ; indicate display of filename...
                    push bc
                    push hl

                    push de
                    call nz,norm_aff
                    call z,tiny_aff
                    pop  hl
                    CALL_OZ(Gn_sop)          ; display filename

                    pop  hl
                    pop  bc
                    push bc
                    push hl
                    call FileEprFileSize     ; get size of File Entry in CDE
                    ld   (flen),de
                    ld   b,0
                    ld   (flen+2),bc

                    call jrsz_aff
                    ld   hl,flen
                    call IntAscii
                    CALL_OZ gn_sop           ; display size of current File Entry
                    call jnsz_aff
                    pop  hl
                    pop  bc
.get_next_filename
                    call FileEprNextFile     ; get pointer to next File Entry in BHL...
                    ld   (fadr),hl
                    ld   a,b
                    ld   (fbnk),a

                    bit  1,(iy+0)
                    jr   z, cat_main_loop    ; no file were displayed, fetch new filename

                    res  1,(iy+0)
                    ld   hl, linecnt
                    inc  (hl)
                    ld   a,7
                    cp   (hl)
                    jr   nz,next_row
                    ld   (hl),0
                    call pwait
                    cp   RC_ESC
                    jr   nz,new_page
                    ret
.new_page
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    jr   nc,ok_new_page
                    call cls
                    call disp_no_filearea_msg
                    scf
                    RET
.ok_new_page
                    ld   a,(fbnk)            ; ready for next page of filenames (after Page Wait)
                    ld   b,a
                    ld   hl,(fadr)
                    ld   de, buf3
                    call FileEprFilename
                    ret  c                   ; Ups - last file was displayed during page wait, back to main menu...
                    call cls
                    jp   cat_main_loop       ; display the next file in a fresh new window...
.next_row
                    CALL_OZ gn_nln
                    jp   cat_main_loop

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
                    ld   hl,endf_msg
                    CALL_OZ gn_sop
                    call pwait
                    ret

.disp_prompt_delfiles_msg
                    LD   HL, prompt_delfiles_msg
                    CALL_OZ gn_sop
                    RET
; *************************************************************************************


; *************************************************************************************
; Check if there's active/deleted files availabe in the File Area
;
.FilesAvailable
                    push bc
                    push de
                    push hl

                    ld   a,(curslot)
                    ld   c,a
                    call FileEprCntFiles          ; any files available in File Area?
                    jr   c, exit_checkfiles       ; no file area!
                    ld   a,h
                    or   l
                    jr   nz, exit_checkfiles      ; active files available...
                    ld   a,d
                    or   e
                    jr   z, exit_checkfiles       ; no active nor deleted files available...
                    cp   1                        ; check for Intel deleted file...
.exit_checkfiles
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; constants

.norm_sq            DEFM 1,"2-G",1,"4+TRUF",1,"4-TRU ",0
.tiny_sq            DEFM 1,"5+TRGUd",1,"3-RU ",0

.endf_msg           DEFM 1,"2-G",1,"4+TUR END ",1,"4-TUR",0

.prompt_delfiles_msg DEFM 13, 10, " Show deleted files? ",13,10,0
