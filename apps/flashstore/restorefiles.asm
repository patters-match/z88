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

Module RestoreFiles

; This module contains the command to restore files from a File Card to a specified
; RAM device.

     xdef RestoreFilesCommand, PromptOverWrFile

     lib CreateFilename            ; Create file(name) (OP_OUT) with path
     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprPrevFile           ; Return pointer to previous File Entry on File Eprom
     lib FileEprLastFile           ; Return pointer to last File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprFetchFile          ; Fetch file image from File Eprom, and store it to RAM file

     xref FilesAvailable
     xref GetDefaultRamDevice
     xref disp_no_filearea_msg, no_files, DispErrMsg
     xref cls, sopnln, wbar
     xref fetf_msg, fsok_msg, done_msg, no_msg, yes_msg
     xref disp_exis_msg
     xref YesNo

     ; system definitions
     include "stdio.def"
     include "fileio.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"



; *************************************************************************************
;
; Restore ALL active files from current file card into a user defined RAM device (or path)
;
.RestoreFilesCommand
                    CALL cls

                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    pop  bc
                    jr   z, check_restorable_files     ; File Area found
                    call disp_no_filearea_msg
                    ret
.check_restorable_files
                    call FilesAvailable
                    jp   z, no_active_files            ; Fz = 1, no files available...

                    CALL cls
                    LD   HL,rest_banner
                    CALL wbar
                    LD   HL,defdst_msg
                    CALL sopnln
                    LD   HL,dest_msg
                    CALL_OZ gn_sop
                    CALL GetDefaultRamDevice
                    LD   DE,buf1
                    LD   A,@00100011
                    LD   BC,$4007
                    LD   L,$20
                    CALL_OZ gn_sip

; add some code here for ESC detection...

                    jr   nc, process_path
                    CP   rc_susp
                    JR   Z, RestoreFilesCommand      ; user aborted command...
                    RET

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
                    CALL_OZ GN_nln
                    CALL PromptOverwrite     ; prompt for all existing files to be overwritten
                    CALL_OZ GN_nln

                    LD   A,(curslot)
                    LD   C,A
                    CALL FileEprLastFile     ; get pointer to last file on Eprom
                    JP   C, no_files         ; Ups - the card was empty or not present...
.restore_loop                                ; BHL points at current file entry
                    CALL FileEprFilename     ; get filename at (DE)
                    JR   C, restore_completed; all file entries scanned...
                    JR   Z, fetch_next       ; File Entry marked as deleted, get next...

                    PUSH DE                  ; preserve local ptr to filename buffer...
                    CALL FileEprFileSize
                    LD   A,C
                    OR   D
                    OR   E
                    POP  DE                  ; is file empty (zero length)?
                    JR   Z, fetch_next       ; yes, try to fetch next...

                    PUSH BC
                    PUSH HL                  ; preserve pointer temporarily...

                    LD   HL,fetf_msg          ; "Fetching to "
                    CALL_OZ gn_sop
                    LD   HL,buf2
                    CALL_OZ(Gn_Sop)          ; display RAM filename...

                    LD   HL,status
                    BIT  0,(HL)
                    JR   NZ, restore_file    ; default - overwrite files...

                    LD   HL, buf2
                    call PromptOverWrFile
                    jr   c, check_rest_abort
                    jr   z, overwr_file      ; file exists, user acknowledged Yes...
                    jr   restore_ignored     ; file exists, user acknowledged No...
.check_rest_abort
                         cp   RC_EOF
                         jr   nz, restore_file    ; file doesn't exist (or in use)
                              POP  HL
                              POP  BC
                              CP   A         ; restore command aborted.
                              RET
.restore_ignored
                    CALL_OZ(Gn_Nln)
                    POP  HL
                    POP  BC
                    JR   fetch_next          ; user acknowledged No, get next file
.overwr_file
                    LD   HL, fetch_msg
                    CALL_OZ(Gn_Sop)

.restore_file       LD   B,0                 ; (local pointer)
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

                    PUSH BC
                    PUSH HL
                    LD   HL, fsok_msg
                    CALL_OZ(GN_Sop)          ; "Done"
                    POP  HL
                    POP  BC
.fetch_next                                  ; BHL = current File Entry
                    CALL FileEprPrevFile     ; get pointer to previous File Entry...
                    JR   NC, restore_loop
.restore_completed
                    LD   HL, done_msg
                    CALL DispErrMsg
                    RET
.filecreerr
                    CALL_OZ(Gn_Err)          ; report fatal error and exit to main menu...
                    RET
; *************************************************************************************



; *************************************************************************************
;
; Prompt user to to overwrite all existing files (in RAM) when restoring
;
; IN: None
;
; OUT:
;    (status), bit 1 = 1 if all files are to be overwritten...
;
.PromptOverWrite    PUSH DE
                    PUSH HL
                    LD   HL,status
                    SET  0,(HL)              ; preset to Yes (to overwrite existing files)

                    LD   HL, disp_promptovwrite_msg
                    LD   DE, no_msg
                    CALL YesNo
                    JR   C, exit_promptoverwr
                    JR   Z, exit_promptoverwr; Yes selected...

                    LD   HL,status
                    RES  0,(HL)              ; No selected (to overwrite existing files)
.exit_promptoverwr
                    POP  HL
                    POP  DE
                    RET
.disp_promptovwrite_msg
                    LD   HL, promptovwrite_msg
                    CALL_OZ gn_sop
                    RET
; *************************************************************************************



; *************************************************************************************
;
; Prompt user to to overwrite file, if it exist.
;
; IN:
;    HL = (local) ptr to filename (null-terminated)
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
                    PUSH DE
                    PUSH HL
                    PUSH IX

                    LD   A, OP_IN
                    LD   BC,$0040            ; expanded file, room for 64 bytes
                    LD   D,H
                    LD   E,L
                    CALL_OZ (GN_Opf)
                    JR   C, exit_overwrfile  ; file not available
                    CALL_OZ(GN_Cl)

                    CALL_OZ GN_nln
                    LD   HL, disp_exis_msg
                    LD   DE, yes_msg
                    CALL yesno               ; file exists, prompt "Overwrite file?"
                    JR   Z,exit_overwrfile
.check_ESC
                    CP   IN_ESC
                    JR   Z, abort_file
                         OR   A
                         JR   exit_overwrfile
.abort_file
                    LD   A,RC_EOF
                    OR   A                   ; Fz = 0, Fc = 1
                    SCF

.exit_overwrfile    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    RET
; *************************************************************************************



; *************************************************************************************
; constants

.rest_banner        DEFM "RESTORE ALL FILES FROM FILE AREA",0
.fetch_msg          DEFM $0D,$0A," Fetching... ",0
.promptovwrite_msg  DEFM " Overwrite RAM files? ",13, 10, 0
.defdst_msg         DEFM " Enter Device/path.",0
.dest_msg           DEFM 1,"2+C Device: ",0
.illgwc_msg         DEFM $0D,$0A,"Wildcards not allowed.",0
.invpath_msg        DEFM $0D,$0A,"Invalid Path",0
.no_restore_files   DEFM "No files available in File Area to restore.", 0
