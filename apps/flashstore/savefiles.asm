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

Module SaveFiles

; This module contains the Save Files to Flash Card Command

     xdef SaveFilesCommand
     xdef fnam_msg, fsok_msg

     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FlashEprFileSave          ; Save RAM file to Flash Eprom
     lib FlashEprFileDelete        ; Mark file as deleted on Flash Eprom
     lib FileEprFindFile           ; Find File Entry using search string (of null-term. filename)

     xref CheckBatteryStatus
     xref FlashWriteSupport
     xref cls, wbar, sopnln
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
; Save Files to Flash Card
;
.SaveFilesCommand
                    call CheckBatteryStatus
                    ret  c                        ; batteries are low - operation aborted
                    call cls
.init_save_main
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    pop  bc
                    jr   z, check_writesupp       ; File Area header was found..
                    call disp_no_filearea_msg
                    ret
.check_writesupp
                    call FlashWriteSupport        ; check if Flash Card in current slot supports saveing files?
                    call c,DispIntelSlotErr
                    ret  c                        ; it didn't...
                    ret  nz                       ; (and flash chip was not found in slot!)

                    ld   hl,0
                    ld   (savedfiles),hl     ; reset counter to No files saved...
.fname_sip
                    call cls
                    ld   hl,fsv1_bnr
                    call wbar
                    ld   hl,wcrd_msg
                    call sopnln

                    LD   HL,fnam_msg
                    CALL_OZ gn_sop

                    ld   bc,$0080
                    ld   hl,curdir
                    ld   de,buf3
                    CALL_OZ gn_fex           ; pre-insert current path at command line...
                    ld   a,'/'
                    ld   (de),a
                    inc  de
                    xor  a
                    ld   (de),a
                    inc  c                   ; C = set cursor to char after path...

                    LD   DE,buf3
                    LD   A,@00100011
                    LD   B,$40
                    LD   L,$20
                    CALL_OZ gn_sip
                    jp   nc,save_mailbox
                    CP   RC_SUSP
                    JR   Z, fname_sip
                    RET
.save_mailbox
                    call cls
                    ld   hl,fsv2_bnr
                    call wbar

                    ld   bc,$0080
                    ld   hl,buf3
                    ld   de,buf1
                    CALL_OZ gn_fex
                    CALL C, ReportStdError             ; illegal wild card string
                    JR   C, end_save

                    xor  a
                    ld   b,a
                    LD   HL,buf1
                    CALL_OZ gn_opw
                    CALL C, ReportStdError             ; wild card string illegal or no names found
                    JR   C, end_save                   ; no files to save...
                    LD   (wcard_handle),IX
.next_name
                    CALL CheckBatteryStatus
                    JR   C, save_completed             ; abort operation if batteries are low

                    LD   DE,buf2
                    LD   C,$80                         ; write found name at (buf2) using max. 128 bytes
                    LD   IX,(wcard_handle)
                    CALL_OZ(GN_Wfn)
                    JR   C, save_completed
                    CP   Dn_Fil                        ; file found?
                    JR   NZ, next_name
.re_save
                    CALL file_save                     ; Yes, save to Flash File Eprom...
                    JR   NC, next_name                 ; saved successfully, fetch next file..

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
                    POP  AF
                    RET

.DispNoFiles        LD   HL, ends2_msg                  ; "No files saved".
                    CALL_OZ(GN_Sop)
                    RET

.filesaved          LD   HL,(savedfiles)               ; another file has been saved...
                    INC  HL
                    LD   (savedfiles),HL               ; savedfiles++
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Save file to Flash Eprom, filename at (buf2), null-terminated.
;
.file_save
                    LD   BC,$0080
                    LD   HL,buf2
                    LD   DE,buf3                       ; expanded filename may have 128 byte size...
                    LD   A, op_in
                    CALL_OZ(GN_Opf)
                    RET  C

                    LD   A,C
                    SUB  7
                    LD   (nlen),A                      ; length of filename excl. device name...
                    LD   A,fa_ext
                    LD   DE,0
                    CALL_OZ(OS_Frm)                    ; file size in DEBC...
                    CALL_OZ(Gn_Cl)                     ; close file

                    LD   (flen),BC
                    LD   (flen+2),DE

                    XOR  A
                    OR   B
                    OR   C
                    OR   D
                    OR   E
                    JP   Z, file_zero_length

                    LD   A,(nlen)                      ; calculate size of File Entry Header
                    ADD  A,4+1                         ; total size = length of filename + 1 + 32bit file length
                    LD   H,0
                    LD   L,A
                    LD   (flenhdr),HL
                    LD   HL,0
                    LD   (flenhdr+2),HL                ; size of File Entry Header

                    LD   HL,savf_msg
                    CALL_OZ gn_sop
                    LD   HL,buf3                       ; display expanded filename
                    CALL_OZ gn_sop

                    LD   DE,buf3+6                     ; point at filename (excl. device name), null-terminated
                    CALL FindFile                      ; find File Entry of old file, if present

                    ld   a,(curslot)
                    ld   bc, BufferSize
                    ld   de, BufferStart
                    ld   hl, buf3
                    call FlashEprFileSave
                    jr   c, filesave_err               ; write error or no room for file...

                    CALL DeleteOldFile                 ; mark previous file as deleted, if any...
                    CALL filesaved
                    LD   HL,fsok_msg
                    CALL_OZ gn_sop
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
                    LD   HL,buf3                       ; display expanded filename
                    call sopnln
                    LD   HL,zerolen_msg
                    call sopnln
                    CP   A
                    RET
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
                    LD   (flentry+2),A
                    LD   (flentry),HL                  ; preserve ptr to current File Entry...
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

.fsv1_bnr           DEFM "SAVE FILES TO FILE AREA",0
.wcrd_msg           DEFM " (Wildcards are allowed).",0
.fnam_msg           DEFM 1,"2+C Filename: ",0

.curdir             DEFM ".",0
.fsv2_bnr           DEFM "SAVING TO FILE AREA ...",0
.ends0_msg          DEFM " file",0
.ends1_msg          DEFM " has been saved.",$0D,$0A,0
.ends2_msg          DEFM $0D,$0A,1,"2JCNo files saved.",1,"2JN",$0D,$0A,0
.savf_msg           DEFM "Saving ",0

.fsok_msg           DEFM " Done.",$0D,$0A,0
.blowerrmsg         DEFM "File not saved properly - will be re-saved.",$0D,$0A,0
.zerolen_msg        DEFM "File has zero length - ignored.",$0D,$0A,0
