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

Module RestoreFiles

; This module contains the command to restore files from a File Card to a specified
; RAM device.

     xdef RestoreFilesCommand, PromptOverWrFile, PromptOverWrite
     xdef disp_exis_msg

     lib CreateFilename            ; Create file(name) (OP_OUT) with path
     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprPrevFile           ; Return pointer to previous File Entry on File Eprom
     lib FileEprLastFile           ; Return pointer to last File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprFetchFile          ; Fetch file image from File Eprom, and store it to RAM file
     lib RamDevFreeSpace           ; Get free space on RAM device.

     xref FilesAvailable           ; browse.asm
     xref GetDefaultRamDevice      ; defaultram.asm
     xref CompressRamFileName      ; savefiles.asm
     xref disp_no_filearea_msg     ; errmsg.asm
     xref no_files, DispErrMsg     ; errmsg.asm
     xref DispMainWindow, sopnln   ; fsapp.asm
     xref YesNo, no_msg, yes_msg   ; fsapp.asm
     xref ResSpace, failed_msg     ; fsapp.asm
     xref done_msg                 ; fetchfile.asm
     xref fetf_msg                 ; fetchfile.asm
     xref InputFilename            ; fetchfile.asm

     ; system definitions
     include "stdio.def"
     include "integer.def"
     include "fileio.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"



; *************************************************************************************
;
; Restore ALL active files from current file card into a user defined RAM device (or path)
;
.RestoreFilesCommand
                    ld   hl,rest_banner
                    call DispMainWindow

                    call FilesAvailable
                    jp   c, disp_no_filearea_msg
                    jp   z, no_active_files            ; Fz = 1, no files available...

                    LD   HL,defdst_msg
                    CALL sopnln
                    LD   HL,dest_msg
                    CALL_OZ gn_sop
                    LD   DE,buf1
                    PUSH DE
                    CALL GetDefaultRamDevice
                    POP  DE
                    LD   C,$07
                    CALL InputFilename
                    jr   nc, process_path
                    RET                           ; user aborted command...

.no_active_files    ld   hl, no_restore_files
                    call DispErrMsg
                    ret
.process_path
                    ld   bc,$80
                    ld   hl,buf1
                    ld   de,buf2             ; generate expanded path, if possible...
                    CALL_OZ (Gn_Fex)
                    jr   c, inv_path         ; invalid path

                    AND  @10111000
                    JR   NZ, illg_wc         ; wildcards not allowed...
                    JR   adjust_path

.illg_wc            LD   HL, illgwc_msg
                    CALL DispErrMsg
                    JR   RestoreFilesCommand ; syntax error in path name

.inv_path           LD   HL, invpath_msg
                    CALL DispErrMsg
                    JR   RestoreFilesCommand
.adjust_path
                    DEC  DE
                    LD   A,(DE)              ; assure that last character of path
                    CP   '/'                 ; is not a "/"...
                    JR   NZ,path_ok
                    DEC  DE
.path_ok            INC  DE                  ; DE points at merge position,
                                             ; ready to receive filenames from File Eprom...
                    LD   HL, ram_promptovwrite_msg
                    CALL PromptOverwrite     ; prompt for all existing files to be overwritten
                    CP   IN_ESC
                    RET  Z                   ; user aborted with ESC
                    CALL_OZ GN_nln
                    CALL_OZ GN_nln

                    LD   A,(curslot)
                    LD   C,A
                    CALL FileEprLastFile     ; get pointer to last file on Eprom
                    JP   C, no_files         ; Ups - the card was empty or not present...
.restore_loop                                ; BHL points at current file entry
                    CALL FileEprFilename     ; get filename at (DE)
                    JR   C, restore_completed; all file entries scanned...
                    JR   Z, fetch_next       ; File Entry marked as deleted, get next...

                    ADD  A,6                 ; add length of device name
                    PUSH DE                  ; preserve local ptr to filename buffer...
                    PUSH AF                  ; preserve length of explicit RAM file name
                    CALL FileEprFileSize
                    LD   (free),DE
                    LD   A,C
                    LD   (free+2),A
                    OR   D
                    OR   E                   ; is file empty (zero length)?
                    POP  DE
                    LD   C,D                 ; C = length of explicit filename
                    POP  DE
                    JR   Z, fetch_next       ; yes, try to fetch next...

                    PUSH BC
                    PUSH HL                  ; pointer temporarily...

                    LD   HL, buf2            ; C = size of explicit filename in (buf2)
                    CALL CompressRamFileName ; get a displayable RAM filename
                    CALL_OZ gn_sop           ; display RAM filename (optionally compressed, if too long)...

                    BIT  overwrfiles,(IY+0)
                    JR   NZ, restore_file    ; default - overwrite files...
                    ld   hl, buf2
                    push de                  ; preserve pointer to file area filename
                    ld   de, disp_exis_msg
                    call PromptOverWrFile    ; Does RAM filename at (HL) exist?...
                    pop  de
                    jr   c, check_rest_abort ; does not exist...
                    jr   z, restore_file     ; file exists, user acknowledged Yes...
                    jr   restore_ignored     ; file exists, user acknowledged No...
.check_rest_abort
                    cp   RC_ESC
                    jr   nz, restore_file    ; file doesn't exist (or in use)
                         POP  HL
                         POP  BC
                         CP   A              ; restore command aborted with ESC.
                         RET
.restore_ignored
                    CALL_OZ(Gn_Nln)
                    POP  HL
                    POP  BC
                    JR   fetch_next          ; user acknowledged No, get next file
.restore_file
                    LD   B,0                 ; (local pointer)
                    LD   HL,buf2             ; pointer to filename...
                    CALL CreateFilename      ; create file with implicit path...
                    POP  HL                  ; IX = file handle...
                    POP  BC                  ; restore pointer to current File Entry
                    JR   C, filecreerr       ; not possible to create file, exit restore...

                    CALL FileEprFetchFile    ; fetch file from File Eprom
                    PUSH AF                  ; to RAM file, identified by IX handle
                    CALL_OZ(Gn_Cl)           ; then, close file.
                    POP  AF
                    JR   C, filecreerr       ; not possible to transfer, exit restore...

                    CALL_OZ GN_Nln
.fetch_next                                  ; BHL = current File Entry
                    CALL FileEprPrevFile     ; get pointer to previous File Entry...
                    JR   NC, restore_loop
.restore_completed
                    LD   HL, done_msg
                    CALL DispErrMsg
                    RET
.no_room
                    POP  HL
                    POP  BC
.filecreerr
                    PUSH AF
                    LD   B,0
                    LD   HL, buf2            ; an error occurred, delete file...
                    CALL_OZ(Gn_Del)
                    POP  AF
                    CALL_OZ(Gn_Err)          ; report fatal error and exit to main menu...
                    LD   HL, failed_msg
                    CALL DispErrMsg
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Prompt user to to overwrite all existing files when processing files.
;
; IN:
;    HL = pointer to display prompt message routine
;
; OUT:
;    (status), bit 1 = 1 if all files are to be overwritten, else prompt...
;
.PromptOverWrite    PUSH DE
                    PUSH HL

                    SET  overwrfiles,(IY+0)  ; preset to Yes (to overwrite existing files)
                    LD   DE, no_msg
                    CALL YesNo
                    JR   C, exit_promptoverwr
                    JR   Z, exit_promptoverwr; Yes selected...

                    RES  overwrfiles,(IY+0)  ; No selected (to overwrite existing files)
.exit_promptoverwr
                    POP  HL
                    POP  DE
                    RET
.ram_promptovwrite_msg
                    LD   HL, disp_ramovwrite_msg
                    CALL_OZ gn_sop
                    RET
; *************************************************************************************



; *************************************************************************************
;
; Prompt user to to overwrite file, if it exist.
;
; IN:
;    HL = (local) ptr to filename (null-terminated)
;    DE = pointer to prompt file overwrite message routine
;
; OUT:
;    Fc = 0, file exists
;         Fz = 1, Yes, user acknowledged overwrite file
;         Fz = 0, No - acknowledged preserve file
;
;    Fc = 1,
;         file doesn't exists or
;         or user aborted with ESC (during Yes/No) prompt.
;
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.. different
;
.PromptOverWrFile   PUSH BC
                    PUSH HL
                    PUSH IX
                    PUSH DE

                    LD   A, OP_IN
                    LD   BC,$0040            ; expanded file, room for 64 bytes
                    LD   D,H
                    LD   E,L
                    CALL_OZ (GN_Opf)
                    JR   C, exit_overwrfile  ; file not available
                    CALL_OZ(GN_Cl)

                    CALL_OZ GN_nln
                    POP  HL
                    PUSH HL                  ; pointer to prompt display routine
                    LD   DE, yes_msg
                    CALL yesno               ; file exists, prompt "Overwrite file?"
                    JR   Z,exit_overwrfile
.check_ESC
                    CP   IN_ESC
                    JR   Z, abort_file
                         OR   A
                         JR   exit_overwrfile
.abort_file
                    LD   A,RC_ESC
                    OR   A                   ; Fz = 0, Fc = 1
                    SCF
.exit_overwrfile
                    POP  DE
                    POP  IX
                    POP  HL
                    POP  BC
                    RET
; *************************************************************************************


; *************************************************************************************
.disp_exis_msg      LD   HL, exis_msg
                    CALL_OZ GN_Sop
                    RET
; *************************************************************************************


; *************************************************************************************
; constants

.rest_banner        DEFM "RESTORE ALL FILES FROM FILE AREA",0
.disp_ramovwrite_msg DEFM 13, 10, " Overwrite RAM files? ",13, 10, 0
.defdst_msg         DEFM 13, 10, " Enter Device/path.",0
.dest_msg           DEFM 1,"2+C Device: ",0
.illgwc_msg         DEFM $0D,$0A,"Wildcards not allowed.",0
.invpath_msg        DEFM $0D,$0A,"Invalid Path",0
.no_restore_files   DEFM "No files available in File Area to restore.", 0
.exis_msg           DEFM 13," RAM file already exists. Overwrite?", 13, 10, 0
