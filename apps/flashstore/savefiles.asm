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

Module SaveFiles

; This module contains the Save Files to Flash Card Command

     xdef SaveFilesCommand, BackupRamCommand
     xdef fnam_msg
     xdef CompressRamFileName

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FlashEprFileSave          ; Save RAM file to Flash Eprom
     lib FlashEprFileDelete        ; Mark file as deleted on Flash Eprom
     lib FileEprFindFile           ; Find File Entry using search string (of null-term. filename)

     xref SelectRamDevice, GetDefaultRamDevice, selctram_msg
     xref InitFirstFileBar
     xref FlashWriteSupport
     xref DispMainWindow, cls, wbar, sopnln
     xref ReportStdError, DispIntelSlotErr
     xref VduEnableCentreJustify
     xref disp_no_filearea_msg
     xref ResSpace
     xref IntAscii
     xref DispErrMsg

     ; system definitions
     include "stdio.def"
     include "fileio.def"
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

                    call CheckFileArea
                    ret  c                        ; no file area nor write support
                    ret  nz                       ; flash chip was not found in slot!

                    LD   HL, selctram_msg
                    CALL_OZ(GN_Sop)

                    LD   BC,$0103
                    CALL SelectRamDevice          ; user selected RAM device at (buf1)
                    RET  C

                    LD   HL, bckp_wildcard
                    LD   DE, buf1+6
                    LD   BC, 4
                    LDIR                          ; append "//*", wich is ":RAM.X//*"
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
                    ld   (de),a              ; append '/' and null-terminator after default RAM devive

                    pop  de                  ; buf3
                    LD   A,@00100011
                    LD   B,$80
                    LD   C,7                 ; C = set cursor to char after path...
                    LD   L,$28
                    CALL_OZ gn_sip           ; user enter wildcard string with pre-insert default RAM device
                    jp   nc,save_mailbox
                    CP   RC_SUSP
                    JR   Z, fname_sip
                    RET
.save_mailbox
                    call cls

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
                    CALL SaveFileToCard                ; save found RAM file to Flash Card...
                    JR   NC, next_name                 ; saved successfully, fetch next file in RAM..

                    CP   RC_BWR
                    JR   Z, re_save                    ; not saved successfully to Flash Eprom, try again...
                    CALL ReportStdError                ; display all other std. errors...
.save_completed
                    LD   IX,(wcard_handle)
                    CALL_OZ(GN_Wcl)                    ; All files parsed, close Wild Card Handler
.end_save
                    LD   HL,(savedfiles)
                    LD   A,H
                    OR   L
                    CALL NZ, DispFilesSaved
                    CALL Z, DispNoFiles
                    CALL ResSpace
                    RET

.CheckFileArea
                    ld   a,(curslot)
                    ld   c,a
                    call FlashWriteSupport             ; check if Flash Card in current slot supports saveing files?
                    jp   c,DispIntelSlotErr
                    jp   nz,DispIntelSlotErr

                    call FileEprRequest
                    ret  z                             ; File Area header was found..
                    call disp_no_filearea_msg
                    ret

.DispFilesSaved     PUSH AF
                    PUSH HL
                    CALL_OZ GN_Nln
                    CALL VduEnableCentreJustify
                    ld   hl,savedfiles                 ; display no of files saved...
                    call IntAscii
                    CALL_OZ gn_sop
                    LD   HL,ends0_msg                   ; " file"
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

                    CALL InitFirstFileBar               ; initialize file area variables...
                    POP  AF
                    RET

.DispNoFiles        LD   HL, ends2_msg                  ; "No files saved".
                    CALL_OZ(GN_Sop)
                    RET

.CountFileSaved     LD   HL,(savedfiles)               ; another file has been saved...
                    INC  HL
                    LD   (savedfiles),HL               ; savedfiles++
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Save file to Flash Eprom, filename (might contain wildcards) at (buf2), null-terminated.
;
.SaveFileToCard
                    LD   BC,255
                    LD   HL,buf2                       ; partial expanded (wildcard) filename
                    LD   DE,buf3                       ; output buffer for expanded filename (max 255 byte)...
                    LD   A, op_in
                    CALL_OZ(GN_Opf)
                    RET  C

                    ld   hl,buf3                       ; C = size of explicit filename in (buf3)
                    call CompressRamFileName
                    PUSH HL                            ; preserve pointer to (optionally compressed) filename

                    LD   A,fa_ext
                    LD   DE,0
                    CALL_OZ(OS_Frm)                    ; file size in DEBC...
                    CALL_OZ(Gn_Cl)                     ; close file

                    LD   H,B
                    LD   L,C
                    ADC  HL,DE
                    POP  HL
                    JR   Z, file_zero_length           ; Ups, file has zero length - will not be saved...

                    PUSH HL
                    LD   HL,savf_msg
                    CALL_OZ gn_sop
                    POP  HL
                    CALL_OZ gn_sop                     ; display "Saving " + compressed filename, to user...

                    LD   DE,buf3+6                     ; point at filename (excl. device name), null-terminated
                    CALL FindFile                      ; find a matching File Entry, and remember it to be deleted later...

                    ld   a,(curslot)
                    ld   bc, BufferSize
                    ld   de, buffer                    ; use 1K RAM buffer to blow file hdr + image
                    ld   hl,buf3                       ; the expanded RAM filename at buf3 (< 255 char length)...
                    call FlashEprFileSave
                    jr   c, filesave_err               ; write error or no room for file...

                    CALL DeleteOldFile                 ; mark previous file as deleted, if it was previously found...
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
                    CALL DispErrMsg
                    SCF
                    RET

.file_zero_length
                    LD   HL,buf2                       ; display (compressed) filename
                    call sopnln
                    LD   HL,zerolen_msg
                    call sopnln
                    CP   A
                    RET
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
                    ld   a,c
                    cp   42
                    ret  c                             ; filename fits within 42 chars, return original HL

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
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Find file on current File Eprom, identified by DE pointer string (null-terminated),
; and preserve pointer in (flentry).
;
; IN:
;         DE = pointer to search string (filename)
;
.FindFile
                    LD   A,$FF
                    LD   H,A
                    LD   L,A
                    LD   (flentry),HL
                    LD   (flentry+2),A                 ; preset found File Entry to <None>...

                    LD   A,(curslot)
                    LD   C,A
                    CALL FileEprFindFile               ; search for filename on File Eprom...
                    RET  C                             ; File Eprom or File Entry was not available
                    RET  NZ                            ; File Entry was not found...

                    LD   A,B
                    LD   (flentry),HL                  ; preserve ptr to current File Entry...
                    LD   (flentry+2),A
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
                    LD   A,(flentry+2)
                    CP   $FF                      ; Valid pointer to File Entry?
                    RET  Z

                    LD   B,A
                    LD   HL,(flentry)
                    CALL FlashEprFileDelete       ; Mark old File Entry as deleted
                    RET  C                        ; File Eprom not found or write error...
                    RET
; *************************************************************************************


; *************************************************************************************
; constants
.bckp_bnr           DEFM "BACKUP RAM TO FILE CARD AREA",0
.bckp_wildcard      DEFM "//*",0

.fsv1_bnr           DEFM "SAVE FILES TO FILE CARD AREA",0
.wcrd_msg           DEFM 13, 10, " (Wildcards are allowed).",0
.fnam_msg           DEFM 1,"2+C Filename: ",0

.curdir             DEFM ".",0
.fsv2_bnr           DEFM "SAVING TO FILE CARD AREA ...",0
.ends0_msg          DEFM " file",0
.ends1_msg          DEFM " has been saved.",$0D,$0A,0
.ends2_msg          DEFM $0D,$0A,1,"2JCNo files found in RAM card to be saved.",1,"2JN",$0D,$0A,0
.savf_msg           DEFM "Saving ",0

.blowerrmsg         DEFM "File not saved properly - will be re-saved.",$0D,$0A,0
.zerolen_msg        DEFM "File has zero length - ignored.",$0D,$0A,0
