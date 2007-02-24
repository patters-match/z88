; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2007
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

Module FetchFile

; This module contains the command to fetch a file from a File Card to the current
; RAM device.

     xdef FetchFileCommand, QuickFetchFile
     xdef exct_msg, done_msg, fetf_msg
     xdef InputFileName
     xdef DispInt, disp16bitInt
     xdef DisplayFileSize
     xdef DispCompletedMsg

     lib CreateFilename            ; Create file(name) (OP_OUT) with path
     lib FileEprFileName           ; get a copy of the file name from the file entry.
     lib RamDevFreeSpace           ; Get free space on RAM device

     xref FilesAvailable           ; browse.asm
     xref DispFiles                ; browse.asm
     xref GetCursorFilePtr         ; browse.asm
     xref LeftJustifyText          ; browse.asm
     xref RightJustifyText         ; browse.asm
     xref PromptOverWrFile         ; restorefiles.asm
     xref disp_exis_msg            ; restorefiles.asm
     xref GetDefaultRamDevice      ; defaultram.asm
     xref DispMainWindow, sopnln   ; fsapp.asm
     xref failed_msg               ; fsapp.asm
     xref GetCurrentSlot           ; fsapp.asm
     xref fnam_msg                 ; savefiles.asm
     xref CompressRamFileName      ; savefiles.asm
     xref VduCursor                ; selectcard.asm
     xref IntAscii, ksize_txt      ; filestat.asm
     xref disp_no_filearea_msg     ; errmsg.asm
     xref no_files, DispErrMsg     ; errmsg.asm

     ; system definitions
     include "stdio.def"
     include "syspar.def"
     include "integer.def"
     include "fileio.def"
     include "eprom.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
;
; Fetch file from File Eprom.
; User enters name of file that will be searched for, and if found,
; fetched into a specified RAM file.
;
.FetchFileCommand
                    ld   hl,fetch_bnr
                    call DispMainWindow

                    call GetCurrentSlot           ; C = (curslot)
                    ld   a,EP_Req
                    oz   OS_Epr                   ; check if there's a File Card in slot C
                    jr   z, check_fetchable_files ; File Area found.
                    jp   disp_no_filearea_msg
.check_fetchable_files
                    call FilesAvailable
                    jp   z, no_files              ; Fz = 1, no files available...

                    ld   hl,exct_msg
                    call sopnln
                    ld   hl,fnam_msg
                    CALL_OZ gn_sop

                    LD   HL,buffer                ; preset input line with '/'
                    LD   (HL),'/'
                    INC  HL
                    LD   (HL),0
                    DEC  HL
                    EX   DE,HL                    ; DE = input buffer of filename to search for...
                    LD   C,$01                    ; allow 255 char input, place cursor after '/'
                    CALL InputFileName
                    RET  C                        ; user aborted

                    ld   a,b
                    ld   (linecnt),a              ; B = size of filename that was entered
                    jp   FindFileToFetch
; *************************************************************************************


; *************************************************************************************
;
; Fetch file from File Eprom, based on BHL file entry, when user has pressed
; ENTER on file entry in File Area window; the file might be marked as deleted
; or be an 'active' file.
;
.QuickFetchFile
                    ld   hl,fetch_bnr
                    call DispMainWindow

                    call DisplayFreeRamDevs

                    call GetCursorFilePtr    ; BHL <-- (CursorFilePtr), ptr to cur. file entry
                    ld   (fbnk),a
                    ld   (fadr),hl           ; pointer to found File Entry...

                    call DisplayFileSize     ; display size of file right-justified

                    ld   de,buffer
                    call FileEprFileName
                    ld   (linecnt),a         ; size of input

                    ld   a,EP_Stat
                    oz   OS_Epr              ; check file entry status...
                    jr   nz, get_name        ; no...

                    call_oz GN_Nln
                    ld   hl, warndel1_msg    ; display a flash warning for files marked as deleted
                    CALL_OZ gn_sop           ; before proceeding with the fetch dialog
                    jr   get_name
; *************************************************************************************


; *************************************************************************************
;
.FindFileToFetch
                    call GetCurrentSlot      ; C = (curslot)
                    LD   DE,buffer
                    LD   A,EP_Find
                    OZ   OS_Epr              ; search for <buf1> filename on File Eprom...
                    JP   C, not_found_err    ; File Eprom or File Entry was not available
                    JP   NZ, not_found_err   ; File Entry was not found...

                    ld   a,b
                    ld   (fbnk),a
                    ld   (fadr),hl           ; preserve pointer to found File Entry...

                    push bc
                    push hl
                    call DisplayFreeRamDevs
                    pop  hl
                    pop  bc

                    call DisplayFileSize
.get_name
                    call_oz GN_Nln
                    ld   hl,ffet_msg         ; get destination filename from user...
                    CALL_OZ gn_sop

                    ld   hl, buffer
                    ld   de, buffer+256
                    ld   a,(linecnt)         ; size of input
                    ld   b,0
                    ld   c,a
                    ldir
                    ld   de,buffer
                    CALL GetDefaultRamDevice ; default ram to buf1 (6 chars)
                    ld   hl, buffer+256
                    ld   de, buffer+6
                    ld   a,(linecnt)
                    ld   b,0
                    ld   c,a
                    ldir                     ; append filename after default RAM device.
                    xor  a
                    ld   (de),a              ; null-terminate

                    ld   de,buffer
                    ld   C,0
                    CALL InputFilename       ; user may change the filename before saveing to RAM device
                    jr   nc,open_file
                    cp   a
                    ret                      ; user aborted...
.open_file
                    CALL_OZ(GN_Nln)
                    ld   hl,buffer
                    ld   de, disp_exis_msg
                    call PromptOverWrFile
                    jr   c, check_fetch_abort; file doesn't exist (or in use), or user aborted
                    jr   z, create_file      ; file exists, user acknowledged Yes...
                    CP   A
                    RET                      ; user acknowledged no, just return to main...
.check_fetch_abort
                    CP   RC_ESC
                    JR   NZ, create_file
                         CP   A
                         RET                 ; abort file fetching with ESC, indicate success
.create_file
                    ld   bc,255              ; filename size (max file entry name + RAM device)
                    ld   hl,buffer           ; pointer to file entry name
                    ld   de,buffer+256       ; generate expanded filename...
                    CALL_OZ (Gn_Fex)
                    jr   c, report_error     ; invalid filename...
                    push bc
                    ld   b,0                 ; (local pointer)
                    ld   hl,buffer+256       ; pointer to filename...
                    call CreateFilename      ; create file with and path
                    pop  bc                  ; IX = handle of created file...
                    jr   c, report_error

                    CALL_OZ gn_nln
                    ld   hl,fetf_msg
                    CALL_OZ gn_sop

                    ld   hl,buffer+256       ; C = length of expanded filename
                    call CompressRamFileName
                    call sopnln              ; display created RAM filename (compressed, if > 45 chars)...

                    LD   A,(fbnk)
                    LD   B,A
                    LD   HL,(fadr)
                    LD   A,EP_Fetch
                    OZ   OS_Epr              ; fetch file from current File Area
                    PUSH AF                  ; to RAM file, identified by IX handle
                    CALL_OZ(Gn_Cl)           ; then, close file.
                    POP  AF
                    JR   C,report_error
.DispCompletedMsg
                    LD   HL, done_msg
                    CALL DispErrMsg
                    CP   A                   ; Fc = 0, File successfully fetched into RAM...
                    RET
.report_error
                    PUSH AF
                    LD   B,0
                    LD   HL, buffer+256      ; an error occurred, delete file...
                    CALL_OZ(Gn_Del)
                    POP  AF

                    CALL_OZ(Gn_Err)          ; report error and exit to main menu...
                    LD   HL, failed_msg
                    JP   DispErrMsg

.not_found_err      LD   HL, file_not_found_msg
                    JP   DispErrMsg
; *************************************************************************************


; *************************************************************************************
; IN:
;    DE = buffer for string (pre-loaded)
;    C = Cursor position
;
; OUT:
;    Fc = 0, Input entered and acknowledged with ENTER
;       Parameters according to GN_Sip
;    Fc = 1, Input discarded
.InputFileName
                    PUSH IX

                    PUSH BC                       ; preserve cursor position argument
                    PUSH DE                       ; preserve buffer pointer
                    LD   A,0                      ; get cursor position
                    LD   BC,NQ_WCUR
                    CALL_OZ OS_NQ                 ; get current cursor position
                    POP  DE                       ; B = Y window coordinate, C = X window Coordinate
                    PUSH BC
                    POP  IX                       ; cursor (X,Y)
                    POP  BC                       ; original C argument restored
 .inp_loop
                    LD   B,$FF                    ; always 255 char (max size for names in file area)
                    LD   L,$28                    ; always 40 char visible width of input
                    LD   A,@00100011              ; buffer already has filename
                    PUSH BC
                    PUSH IX
                    POP  BC                       ; B = Y window coordinate, C = X window coordinate
                    CALL VduCursor                ; place start of input buffer at window (X,Y) coordinate
                    POP  BC
                    CALL_OZ gn_sip                ; then begin input at cursor position
                    JP   C,sip_error
                    POP  IX                       ; return input
                    RET
.sip_error
                    CP   RC_SUSP
                    JR   Z, inp_loop
                    SCF                           ; signal that input was discarded by user.
                    POP  IX
                    RET
; *************************************************************************************


; *************************************************************************************
; Display the size of the current File entry (in BHL), right justified in the format:
; "File size = XXXX". 'XXXX' is displayed with a trailing 'K' or 'bytes'.
;
.DisplayFileSize
                    push bc
                    push hl                       ; preserve File entry pointer

                    ld   a,EP_Size
                    oz   OS_Epr                   ; get file entry size in CDE
                    ld   b,0
                    ld   (free),de
                    ld   (free+2),bc              ; store file size for CheckFreeRam routine

                    call RightJustifyText         ; display text right justified...
                    ld   hl, filesize_txt
                    call_oz GN_Sop
                    ld   b,c
                    ex   de,hl
                    call DispInt                  ; display BHL (file size)
                    call_oz GN_Sop                ; display trailing "K" or " bytes"
                    call LeftJustifyText          ; back to normal left justified display text...

                    pop  hl
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
; Display the available free space for all RAM cards in the system, each on it's own
; line in the format ":RAM.? = XXXX free". The value is displayed in K if it is
; larger than 1024 bytes, or just as bytes.
;
.DisplayFreeRamDevs
                    ld   a, 12
                    call_oz OS_Out                ; clear window
                    call_oz GN_Nln

                    ld   c,-1                     ; start with displaying free space in :RAM.0
.disp_freeram_loop  inc  c
                    ld   a,c
                    cp   4
                    ret  z                        ; only three slots in Z88...
                    call RamDevFreeSpace
                    jr   c, disp_freeram_loop     ; no Ram device in slot C...
                    push bc                       ; preserve slot number

                    ld   hl,ramdev_basename
                    CALL_OZ GN_Sop
                    ld   a,c
                    add  a,48
                    call_oz OS_Out
                    ld   hl, space_txt
                    call_oz GN_Sop

                    ex   de,hl                    ; DE = free 256 bytes pages on RAM Card
                    ld   b,h
                    ld   h,l
                    ld   l,0                      ; BHL = DE * 256 = free space in bytes
                    call Dispint
                    call_oz Gn_sop                ; display trailing integer size
                    ld   hl, free_txt
                    call_oz Gn_sop

                    pop  bc
                    jr   disp_freeram_loop
; *************************************************************************************


; *************************************************************************************
; Display integer in BHL as Ascii to current VDU cursor position.
;
; Returns HL = pointer to string that contains a trailing 'K', if value > 1024, else
; points to with a trailing ' bytes' string.
;
.DispInt
                    xor  a
                    ld   c,a
                    ld   de,1024                  ; CDE = 24bit divisor

                    or   b
                    jr   nz, dispK                ; integer > 64K...
                    push hl
                    sbc  hl,de
                    pop  hl
                    jr   nc, dispK                ; integer > 1K
                    call disp16bitInt             ; display integer in bytes
                    ld   hl, bytes_txt
                    ret
.dispK
                    call_oz GN_D24                ; 24bit free space / 1024 (convert into K)
                    push hl
                    ld   hl,512
                    sbc  hl,de                    ; if remainder > 512, add 1 to K size (round up)..
                    pop  hl
                    jr   nc, disp16b
                    inc  hl
.disp16b
                    call disp16bitInt             ; HL = 16bit result
                    ld   hl, ksize_txt
                    ret
.disp16bitInt
                    push hl
                    pop  bc                       ; free space always 16bit number...
                    ld   hl,2
                    CALL IntAscii
                    call_oz GN_Sop                ; display the Ascii integer...
                    ret
; *************************************************************************************


; *************************************************************************************
; constants

.fetch_bnr          DEFM "FETCH FROM FILE AREA", 0
.warndel1_msg       DEFM " ", 1, "4+F+RWARNING: File is marked as deleted", 1, "4-F-R", 0
.exct_msg           DEFM 13, 10, " Enter exact filename (no wildcard).", 0
.ramdev_basename    DEFM " :RAM.", 0
.fetf_msg           DEFM 1,"2+CSaved to ", 0
.done_msg           DEFM "Completed.", $0D, $0A, 0
.ffet_msg           DEFM 13,1,"B Save to: ", 1,"B", 0
.file_not_found_msg DEFM "File not found in File Area.", 0
.bytes_txt          DEFM " bytes ", 0
.filesize_txt       DEFM "File size = ", 0
.space_txt          DEFM " = ", 0
.free_txt           DEFM "free", 13, 10, 0
