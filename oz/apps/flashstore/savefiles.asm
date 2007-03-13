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

Module SaveFiles

; This module contains the Save Files to Flash Card Command

     xdef SaveFilesCommand
     xdef BackupRamCommand
     xdef fnam_msg
     xdef CompressRamFileName
     xdef DispFilesSaved
     xdef CountFileSaved
     xdef FindFile
     xdef DeleteOldFile
     xdef disp_flcovwrite_msg

     xref InitFirstFileBar         ; browse.asm
     xref FilesAvailable           ; browse.asm
     xref FlashWriteSupport        ; format.asm
     xref PromptOverWrite          ; restorefiles.asm
     xref PromptOverWrFile         ; restorefiles.asm
     xref no_active_files          ; restorefiles.asm
     xref saving_msg               ; restorefiles.asm
     xref IntAscii                 ; filestat.asm
     xref FileEpromStatistics      ; filestat.asm
     xref InputFileName            ; fetchfile.asm
     xref SelectRamDevice          ; defaultram.asm
     xref GetDefaultRamDevice      ; defaultram.asm
     xref selctram_msg             ; defaultram.asm
     xref selectdev_msg            ; defaultram.asm
     xref DispMainWindow, ResSpace ; fsapp.asm
     xref cls, wbar, sopnln        ; fsapp.asm
     xref VduEnableCentreJustify   ; fsapp.asm
     xref GetCurrentSlot           ; fsapp.asm
     xref yes_msg, no_msg          ; fsapp.asm
     xref ReportStdError           ; errmsg.asm
     xref DispIntelSlotErr         ; errmsg.asm
     xref DispErrMsg               ; errmsg.asm
     xref disp_no_filearea_msg     ; errmsg.asm

     ; system definitions
     include "stdio.def"
     include "fileio.def"
     include "eprom.def"
     include "dor.def"
     include "error.def"

     ; flash card library definitions
     include "flashepr.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
;
; Backup RAM Card to Flash Card
;
.BackupRamCommand
                    ld   hl,bckp_bnr
                    call DispMainWindow

                    ld   hl,0
                    ld   (savedfiles),hl          ; reset counter to No files saved...

                    call FilesAvailable
                    jp   c, disp_no_filearea_msg  ; no file area!

                    call CheckFileArea
                    ret  c                        ; no file area nor write support
                    ret  nz                       ; flash chip was not found in slot!

                    LD   HL, selctram_msg
                    CALL_OZ(GN_Sop)

                    ld   hl, selectdev_msg
                    call sopnln

                    CALL SelectRamDevice          ; user selected RAM device at (buf1)
                    RET  C                        ; user aborted with ESC

                    LD   HL, bckp_wildcard
                    LD   DE, buf1+6
                    LD   BC, 4
                    LDIR                          ; append "//*", wich is ":RAM.X//*"

                    LD   HL, filecard_promptovwrite_msg
                    LD   DE, yes_msg              ; default to Yes
                    CALL PromptOverWrite          ; prompt user to overwrite all files on file card
                    CP   IN_ESC
                    RET  Z                        ; user aborted with ESC

                    CALL_OZ(GN_Nln)
                    CALL_OZ(GN_Nln)
                    JR   scan_filesystem          ; backup selected RAM to Flash Card...
; *************************************************************************************


; *************************************************************************************
;
; Save Files to Flash Card
;
.SaveFilesCommand
                    ld   hl,fsv1_bnr
                    call DispMainWindow

                    call FilesAvailable
                    jp   c, disp_no_filearea_msg  ; no file area!

                    call CheckFileArea
                    ret  c                        ; no file area nor write support
                    ret  nz                       ; flash chip was not found in slot!

                    ld   hl,0
                    ld   (savedfiles),hl          ; reset counter to No files saved...
.fname_sip
                    ld   hl,wcrd_msg
                    call sopnln

                    LD   HL,fnam_msg
                    CALL_OZ gn_sop

                    ld   de, buf1
                    push de
                    CALL GetDefaultRamDevice
                    pop  hl
                    ld   de, buf3
                    push de
                    ld   bc, 6
                    ldir
                    ld   a,'/'
                    ld   (de),a
                    inc  de
                    xor  a
                    ld   (de),a                        ; append '/' and null-terminator after default RAM devive
                    pop  de                            ; point at start of input buffer (the device name)
                    LD   C,7                           ; C = set cursor to char after path...
                    CALL InputFileName
                    jr   nc,save_mailbox
                    RET                                ; user aborted...
.save_mailbox
                    call cls

                    LD   HL, filecard_promptovwrite_msg
                    LD   DE, yes_msg                   ; default to Yes
                    CALL PromptOverWrite               ; prompt user to overwrite all files on file card
                    CP   IN_ESC
                    RET  Z                             ; user aborted with ESC
                    CALL_OZ(GN_Nln)
                    CALL_OZ(GN_Nln)

                    ld   bc,$0080
                    ld   hl,buf3
                    ld   de,buf1
                    CALL_OZ gn_fex                     ; expand wild card string (max 128 bytes)
                    CALL C, ReportStdError             ; illegal wild card string
                    JR   C, end_save
.scan_filesystem
                    xor  a
                    ld   b,a
                    LD   HL,buf1
                    CALL_OZ gn_opw                     ; open wildcard handler
                    CALL C, ReportStdError             ; wild card string illegal or no names found
                    JR   C, end_save                   ; no files to save...
                    LD   (wcard_handle),IX
.next_name
                    LD   DE,buf2
                    LD   C,$ff                         ; write found name at (buf2) using max. 255 bytes
                    LD   IX,(wcard_handle)
                    CALL_OZ(GN_Wfn)
                    JR   C, save_completed
                    CP   Dn_Fil                        ; file found?
                    JR   NZ, next_name
.re_save
                    LD   BC,5
                    CALL_OZ OS_Tin
                    CP   RC_ESC
                    JR   Z, save_completed             ; ESC pressed - abort saving of files...

                    CALL SaveFileToCard                ; save found RAM file to Flash Card...
                    JR   NC, next_name                 ; saved successfully, fetch next file in RAM..

                    CP   RC_ESC
                    JR   Z, save_completed             ; user aborted command (and release wild card handle)...
                    CP   RC_BWR
                    JR   Z, re_save                    ; not saved successfully to Flash Eprom, try again...
                    CALL ReportStdError                ; display all other std. errors...
.save_completed
                    LD   IX,(wcard_handle)
                    CALL_OZ(GN_Wcl)                    ; All files parsed, close Wild Card Handler
.end_save
                    JP   DispFilesSaved
.UpdateFileAreaStats
                    PUSH AF
                    PUSH HL
                    CALL NC, FileEpromStatistics
                    LD   HL, filewindow
                    CALL_OZ GN_Sop
                    POP  HL
                    POP  AF
                    RET
.CheckFileArea
                    call GetCurrentSlot                ; C = (curslot)
                    call FlashWriteSupport             ; check if Flash Card in current slot supports saveing files?
                    jp   c,DispIntelSlotErr
                    jp   nz,DispIntelSlotErr

                    ld   a,EP_Req
                    oz   OS_Epr                        ; check if there's a File Card in slot C
                    ret  z                             ; File Area header was found..
                    jp   disp_no_filearea_msg

.DispFilesSaved     PUSH AF
                    PUSH HL

                    CALL_OZ GN_Nln
                    CALL VduEnableCentreJustify
                    LD   HL,(savedfiles)
                    PUSH HL
                    ld   bc,(savedfiles)               ; display no of files saved...
                    ld   hl,2
                    call IntAscii                      ; convert 16bit integer in BC to Ascii...
                    CALL_OZ gn_sop
                    LD   HL,ends0_msg                  ; " file"
                    CALL_OZ(GN_Sop)
                    POP  HL
                    LD   A,H
                    XOR  L
                    CP   1
                    JR   Z, endsx
                    LD   A, 's'
                    CALL_OZ(OS_Out)
.endsx              LD   HL, ends1_msg
                    CALL_OZ(GN_Sop)
                    CALL ResSpace
                    CALL InitFirstFileBar               ; initialize file area variables...

                    POP  HL
                    POP  AF
                    RET

.CountFileSaved     PUSH HL
                    LD   HL,(savedfiles)               ; another file has been saved...
                    INC  HL
                    LD   (savedfiles),HL               ; savedfiles++
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.filecard_promptovwrite_msg
                    LD   HL, disp_flcovwrite_msg
                    CALL_OZ gn_sop
                    RET
; *************************************************************************************


; *************************************************************************************
.filecard_ovwriteflc_msg
                    LD   HL, flcexis_msg
                    CALL_OZ gn_sop
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Save file to Flash Eprom, filename (might contain wildcards) at (buf2), null-terminated.
;
.SaveFileToCard
                    LD   BC,255                        ; local filename (pointer)..
                    LD   HL,buf2                       ; partial expanded (wildcard) filename
                    LD   DE,buf3                       ; output buffer for expanded filename (max 255 byte)...
                    LD   A, op_in
                    CALL_OZ(GN_Opf)
                    RET  C                             ; couldn't open file (in use / not found?)...
                    call_oz GN_Cl                      ; close file again (we got the expanded filename)

                    PUSH BC
                    CALL GetCurrentSlot                ; C = (curslot)
                    LD   DE,buf3+6                     ; point at filename (excl. device name), null-terminated
                    CALL FindFile                      ; find a matching File Entry, and remember it to be deleted later...
                    POP  BC

                    push af                            ; preserve search status...
                    ld   hl,buf3                       ; C = size of explicit filename in (buf3) returned from GN_Opf
                    call CompressRamFileName
                    CALL_OZ gn_sop                     ; display compressed filename, to user...
                    pop  af
                    JR   nz, save_file_to_card         ; file doesn't exists in file area, just save the file from RAM

                    BIT  overwrfiles,(IY+0)            ; file was found in file area, prompt user to overwrite?
                    JR   NZ, save_file_to_card         ; user previously selected to overwrite all files by default

                    ld   hl,buf2
                    ld   de, filecard_ovwriteflc_msg
                    call PromptOverWrFile              ; filename at (HL)...
                    ret  c                             ; user aborted command or file didn't exist...
                    ret  nz                            ; file exists, user acknowledged No...

                    LD   HL, saving_msg
                    CALL_OZ(Gn_Sop)
.save_file_to_card
                    call GetCurrentSlot                ; C = (curslot)
                    ld   ix, BufferSize
                    ld   de, buffer                    ; use 1K RAM buffer to blow file hdr + image
                    ld   hl,buf2                       ; the partial expanded RAM filename at buf2 (< 255 char length)...
                    ld   a,EP_SVFL
                    oz   OS_Epr                        ; save RAM file to file area in slot C
                    jr   c, filesave_err               ; write error or no room for file...

                    CALL DeleteOldFile                 ; mark previous file as deleted, if it was previously found...
                    CALL UpdateFileAreaStats           ; update the file statistics window - a new file was saved to the card.
                    CALL CountFileSaved
                    CALL_OZ GN_Nln
                    CP   A
                    RET
.filesave_Err
                    CP   RC_BWR
                    JR   Z, file_wrerr                 ; not written properly to Flash Eprom
                    CP   RC_VPL
                    JR   Z, file_wrerr                 ; VPP not set (should not happen)
                    SCF
                    RET                                ; otherwise, return with std. OZ errors...

.file_wrerr         LD   HL, blowerrmsg
                    CALL DispErrMsg                    ; user may abort with ESC after error message.
                    SCF
                    JP   cls
; *************************************************************************************


; *************************************************************************************
;
; IN:
;    HL = pointer to explicit filename
;     C = number of characters in expanded filename at (HL)

; returns
;    HL = pointer to compressed filename (buffer), or original HL
;    length of filename fits within 42 characters.
;
.CompressRamFileName
                    push af

                    ld   a,c
                    cp   42
                    jr   c, flnm_short                 ; filename fits within 42 chars, return original HL

                    push bc
                    push de

                    ld   de,buffer
                    push de
                    push hl
                    ld   bc,42-9                       ; compress expanded file name to use max 42-9 chars
                    call_oz GN_Fcm                     ; compress filename (at buffer) to fit nicely inside 42 chars...
                    xor  a
                    ld   (de),a                        ; null-terminate compressed filename

                    push bc                            ; C = length of compressed filename
                    ld   bc,9
                    push de                            ; pointer to end of buffer
                    ex   de,hl
                    add  hl,bc                         ; HL = pointer at end of buffer + 9
                    pop  de                            ; DE = end of buffer
                    pop  bc
                    ld   b,0
                    ex   de,hl
                    lddr                               ; shift filename 9 bytes up...
                    pop  hl                            ; pointer to original explicit filename
                    pop  de                            ; pointer to buffer (now with room for device...)
                    push de

                    ld   c,7
                    ldir                               ; copy RAM device to compressed name
                    ld   a,'.'
                    ld   (de),a
                    inc  de
                    ld   (de),a                        ; compressed RAM filename is eg. ':RAM.1/..<compressed filename'
                    pop  hl                            ; return HL = pointer to compressed filename

                    pop  de
                    pop  bc
.flnm_short
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Find file on current File Eprom, identified by DE pointer string (null-terminated),
; and preserve pointer in (flentry).
;
; IN:
;          C = slot number of file area to scan
;         DE = pointer to search string (filename)
; OUT:
;         Fc = 1, No File Card
;         Fc = 0,
;              Fz = 0, file entry not found
;              Fz = 1, file entry found
.FindFile
                    PUSH BC
                    PUSH HL

                    XOR  A
                    LD   H,A
                    LD   L,A
                    LD   (flentry),HL
                    LD   (flentry+2),A                 ; preset found File Entry to <None>...

                    LD   A,EP_Find
                    OZ   OS_Epr                        ; search for filename on File Eprom...
                    JR   C, exit_FindFile              ; File Eprom or File Entry was not available
                    JR   NZ, exit_FindFile             ; File Entry was not found...

                    LD   A,B
                    LD   (flentry),HL                  ; preserve ptr to current File Entry...
                    LD   (flentry+2),A
.exit_FindFile
                    POP  HL
                    POP  BC
                    RET
; *************************************************************************************



; *************************************************************************************
;
; Mark File Entry as deleted, if a valid pointer is registered in (flentry).
;
; IN:
;         BHL = (flentry)
;
.DeleteOldFile
                    PUSH BC
                    PUSH HL

                    LD   A,(flentry+2)
                    LD   B,A
                    LD   HL,(flentry)
                    OR   H
                    OR   L                        ; Valid pointer to File Entry?
                    JR   Z, exit_DeleteOldFile    ; no, no file entry to be marked as deleted

                    LD   A,EP_Delete
                    OZ   OS_Epr                   ; Mark old File Entry as deleted
.exit_DeleteOldFile
                    POP  HL
                    POP  BC
                    RET
; *************************************************************************************


; *************************************************************************************
; constants
.bckp_bnr           DEFM "BACKUP FROM RAM TO FILE CARD AREA",0
.bckp_wildcard      DEFM "//*",0
.filewindow         DEFM 1,"2H2",0
.fsv1_bnr           DEFM "SAVE FILES TO FILE CARD AREA",0
.wcrd_msg           DEFM 13, 10, " (Wildcards allowed).",0
.fnam_msg           DEFM 1,"2+C Filename: ",0
.disp_flcovwrite_msg DEFM 13, 10, " Overwrite all files?",13, 10, 0
.curdir             DEFM ".",0
.fsv2_bnr           DEFM "SAVING TO FILE CARD AREA ...",0
.ends0_msg          DEFM " file",0
.ends1_msg          DEFM " saved.",$0D,$0A,0

.blowerrmsg         DEFM "File not saved properly - will be re-saved.",$0D,$0A,0
.flcexis_msg        DEFM 13," File already exists in File Card. Overwrite?", 13, 10, 0
