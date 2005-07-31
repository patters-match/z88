; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2005
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
     xdef disp_exis_msg
     xdef InputFileName

     lib CreateFilename            ; Create file(name) (OP_OUT) with path
     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFindFile           ; Find File Entry using search string (of null-term. filename)
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprFetchFile          ; Fetch file image from File Area, and store it to RAM file
     lib FileEprFileName           ; get a copy of the file name from the file entry.
     lib FileEprFileStatus         ; get deleted (or active) status of file entry

     xref FilesAvailable           ; catalog.asm
     xref DispFiles                ; catalog.asm
     xref GetCursorFilePtr         ; catalog.asm
     xref CheckFreeRam             ; restorefiles.asm
     xref PromptOverWrFile         ; restorefiles.asm
     xref GetDefaultRamDevice      ; defaultram.asm
     xref DispMainWindow, sopnln   ; fsapp.asm
     xref failed_msg               ; fsapp.asm
     xref fnam_msg                 ; savefiles.asm
     xref CompressRamFileName      ; savefiles.asm
     xref VduCursor                ; selectcard.asm
     xref disp_no_filearea_msg     ; errmsg.asm
     xref no_files, DispErrMsg     ; errmsg.asm

     ; system definitions
     include "stdio.def"
     include "syspar.def"
     include "fileio.def"
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

                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    jr   z, check_fetchable_files ; File Area found.
                    call disp_no_filearea_msg
                    ret
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
                    CALL_OZ gn_nln
                    call FindFileToFetch
                    RET
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

                    call GetCursorFilePtr    ; BHL <-- (CursorFilePtr), ptr to cur. file entry
                    ld   (fbnk),a
                    ld   (fadr),hl           ; pointer to found File Entry...
                    call FileEprFileSize
                    ld   (free),de
                    ld   a,c
                    ld   (free+2),a

                    ld   de,buffer
                    call FileEprFileName
                    ld   (linecnt),a         ; size of input

                    call_oz Gn_nln

                    call FileEprFileStatus   ; is file marked as deleted?
                    jr   nz, get_name        ; no...

                    ld   hl, warndel1_msg    ; display a flash warning for files marked as deleted
                    CALL_OZ gn_sop           ; before proceeding with the fetch dialog
                    jr   get_name
; *************************************************************************************


; *************************************************************************************
;
.FindFileToFetch
                    LD   A,(curslot)
                    LD   C,A
                    LD   DE,buffer
                    CALL FileEprFindFile     ; search for <buf1> filename on File Eprom...
                    JP   C, not_found_err    ; File Eprom or File Entry was not available
                    JP   NZ, not_found_err   ; File Entry was not found...

                    ld   a,b                 ; File entry found
                    ld   (fbnk),a
                    ld   (fadr),hl           ; preserve pointer to found File Entry...
                    call FileEprFileSize
                    ld   (free),de
                    ld   a,c
                    ld   (free+2),a
                    or   d
                    or   e                   ; is file empty (zero lenght)?
                    jr   nz, get_name
                         ld   a, RC_EOF
                         scf                 ; indicate empty file...
                         ret
.get_name
                    ld   hl,ffet_msg          ; get destination filename from user...
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
                    call PromptOverWrFile
                    jr   c, check_fetch_abort; file doesn't exist (or in use), or user aborted
                    jr   z, create_file      ; file exists, user acknowledged Yes...
                    CP   A
                    RET                      ; user acknowledged no, just return to main...
.check_fetch_abort
                    CP   RC_EOF
                    JR   NZ, create_file
                         CP   A
                         RET                 ; abort file fetching, indicate success
.create_file
                    ld   bc,255              ; filename size (max file entry name + RAM device)
                    ld   hl,buffer           ; pointer to file entry name
                    ld   de,buffer+256       ; generate expanded filename...
                    CALL_OZ (Gn_Fex)
                    jr   c, report_error     ; invalid filename...
                    push bc                  ; preserve length of expanded filename
                    call CheckFreeRam
                    pop  bc
                    JR   C, report_error

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
                    CALL FileEprFetchFile    ; fetch file from current File Eprom
                    PUSH AF                  ; to RAM file, identified by IX handle
                    CALL_OZ(Gn_Cl)           ; then, close file.
                    POP  AF
                    JR   C,report_error

                    LD   HL, done_msg
                    CALL DispErrMsg
                    CP   A                   ; Fc = 0, File successfully fetched into RAM...
                    RET
.report_error
                    CALL_OZ(Gn_Err)          ; report error and exit to main menu...
                    LD   HL, failed_msg
                    CALL DispErrMsg
                    RET

.disp_exis_msg      LD   HL, exis_msg
                    CALL_OZ GN_Sop
                    RET

.not_found_err      LD   HL, file_not_found_msg
                    CALL DispErrMsg
                    RET
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
; constants

.fetch_bnr          DEFM "FETCH FROM FILE AREA",0

.warndel1_msg       DEFM " ", 1, "4+F+RWARNING: File is marked as deleted", 1, "4-F-R", 13, 10, 13, 10, 0

.warndel2_msg       DEFM " A newer, active file version exists in the file area", 13, 10, 13, 10, 0

.exct_msg           DEFM 13, 10, " Enter exact filename (no wildcard).",0

.fetf_msg           DEFM 1,"2+CSaved to ",0
.done_msg           DEFM "Completed.",$0D,$0A,0
.ffet_msg           DEFM 13,1,"B Save to: ", 1,"B",0
.exis_msg           DEFM 13," RAM file already exists. Overwrite?", 13, 10, 0
.file_not_found_msg DEFM "File not found in File Area.", 0
