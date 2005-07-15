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

Module FileAreaStatistics

; This module displays the File Area Statistics (right hand side window in main menu mode)


     XDEF FileEpromStatistics, m16, IntAscii, DispKSize

     LIB CreateWindow
     LIB FileEprRequest, FileEprCntFiles, FileEprFirstFile, FileEprFileSize
     LIB FileEprUsedSpace, FileEprFreeSpace

     XREF VduCursor, centerjustify, tinyfont, nocursor
     XREF DispSlotSize, epromdev
     XREF CheckFlashCardID

     ; flash card library definitions
     include "flashepr.def"

     ; system definitions
     include "stdio.def"
     include "integer.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; ****************************************************************************
;
; Eprom Statistics from current File Eprom (Area)
;
; Fetch the following information:
;
; (file) = number of files
; (fdel) = number of deleted files
; (free) = free space
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FileEpromStatistics
                    push af
                    call dispstats
                    pop  af
                    ret
.dispstats
                    ld   bc,5
                    ld   hl, slot_bnr
                    ld   de, buf1
                    ldir
                    ld   a,(curslot)
                    add  a,48
                    ld   (de),a
                    inc  de
                    xor  a
                    ld   (de),a                   ; null-terminate banner

                    ld   a,'3' | 128
                    ld   bc,$004A
                    ld   de,$0812
                    ld   hl, buf1
                    call CreateWindow

                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    jr   z, cont_statistics
                         pop  bc
                         ld   hl, nofepr_msg
                         call_oz (Gn_Sop)
                         ret
.cont_statistics
                    pop  bc
                    push bc                       ; preserve slot number
                    call FileEprCntFiles          ; files on current File Eprom
                    add  hl,de                    ; total files = active + deleted
                    ld   (file),hl
                    ld   (fdel),de

                    pop  bc
                    push bc
                    call FileEprFirstFile
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e
                    jr   nz, getfreesp
                         ld   hl,(file)
                         dec  hl
                         ld   (file),hl
                         ld   hl,(fdel)
                         dec  hl
                         ld   (fdel),hl           ; don't include hidden file entry in statistics
.getfreesp
                    pop  bc                       ; c = slot number...
                    push bc
                    call FileEprFreeSpace         ; free space on current File Eprom
                    ld   (free),bc
                    ld   (free+2),de
                    pop  bc
                    call FileEprUsedSpace         ; free space on current File Eprom
                    ld   (flen),bc
                    ld   (flen+2),de              ; used space on current File Eprom

                    ld   hl,centerjustify
                    CALL_OZ gn_sop                ; centre justify...

                    ld   hl,tinyfont
                    CALL_OZ gn_sop

                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    CALL FlashEprInfo
                    pop  bc
                    JR   NC, disp_flash
                    LD   HL, epromdev
                    CALL_OZ(GN_Sop)
                    CALL FileEprRequest
                    LD   A,D
                    CALL DispSlotSize
                    CALL_OZ(Gn_Nln)
                    JR   disp_eprsize
.disp_flash
                    CALL_OZ(GN_Sop)
                    CALL_OZ(Gn_Nln)
.disp_eprsize
                    CALL DisplayEpromSize

                    ld   bc,$0103                 ; VDU (X,Y) = (1,3)
                    CALL VduCursor
                    ld   hl,free
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,bfre_msg
                    CALL_OZ gn_sop                ; "xxxx bytes free"
                    CALL_OZ(Gn_Nln)

                    ld   hl,flen
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,bused_msg
                    CALL_OZ gn_sop                ; "xxxx bytes used"
                    CALL_OZ(Gn_Nln)

                    ld   hl,file
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,fisa_msg
                    CALL_OZ gn_sop
                    CALL_OZ(Gn_Nln)

                    ld   hl,fdel
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,fdel_msg
                    CALL_OZ gn_sop

                    ld   hl, nocursor
                    CALL_OZ  GN_Sop
                    ret
; *************************************************************************************


; *************************************************************************************
;
.DisplayEpromSize
                    LD   BC, $0101
                    CALL VduCursor      ; VDU Cursor at (1,1)

                    ld   a,(curslot)
                    ld   c,a
                    CALL FileEprRequest

                    LD   H,0
                    LD   L,C            ; C = total of banks as defined by File Eprom Header
                    CALL m16
                    EX   DE,HL          ; size in DE...

                    LD   A,B
                    AND  @00111111      ; get relative top bank number...
                    CP   $3F            ; is header located in top bank?
                    JR   Z, true_size   ; Yes - real File Eprom found...

                    LD   HL, tinyfont
                    CALL_OZ(Gn_Sop)
                    CALL DispKSize
                    LD   HL, ksize
                    CALL_OZ(Gn_sop)
                    LD   HL,fepr
                    CALL_OZ(Gn_Sop)
                    RET

.true_size          LD   HL, tinyfont
                    CALL_OZ(Gn_Sop)
                    CALL DispKSize
                    LD   HL, ksize
                    CALL_OZ(Gn_sop)
                    LD   HL,fepr
                    CALL_OZ(Gn_Sop)
                    RET

.DispKSize          LD   B,D
                    LD   C,E
                    LD   HL,2
                    CALL IntAscii
                    CALL_OZ(Gn_Sop)     ; display size of File Eprom
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Convert integer in HL (or BC) to Ascii string, which is written to (buf1)
; and null-terminated.
;
; HL points at Ascii string, null-terminated.
;
.IntAscii
                    PUSH AF
                    PUSH DE
                    xor  a
                    ld   de,buf1
                    push de
                    CALL_OZ(GN_Pdn)
                    XOR  A
                    LD   (DE),A
                    POP  HL
                    pop  de
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Multiply HL * 16, result in HL.
;
.m16
                    PUSH BC
                    LD   B,4
.multiply_loop      ADD  HL,HL
                    DJNZ multiply_loop  ; banks * 16K = size of card in K
                    POP  BC
                    RET
; *************************************************************************************


; *************************************************************************************
; Display Intel Flash Eprom Device Code and return information of chip.
;
; IN:
;    C = Slot Number
;
; OUT:
;    Fc = 0, Flash Eprom Recognized in slot 3
;         B = total of Blocks on Flash Eprom
;         HL = pointer to flash Card text
;    Fc = 1, Flash Eprom not found in slot X, or Device code not found
;
.FlashEprInfo
                    CALL CheckFlashCardID
                    RET  C

                    LD   A,L                      ; get Device Code in A.
                    PUSH DE
                    LD   HL, FlashEprTypes
                    LD   DE, 6                    ; each table entry is 6 bytes (3 x 2 16bit words)
                    LD   B,(HL)                   ; no. of Flash Eprom Types in table
                    INC  HL
.find_loop          CP   (HL)                     ; device code found?
                    JR   NZ, get_next
                         INC  HL                  ; points at manufacturer code
                         INC  HL
                         LD   B,(HL)              ; B = total of block on Flash Eprom
                         INC  HL
                         INC  HL                  ; points at mnemonic string description.
                         LD   E,(HL)
                         INC  HL
                         LD   D,(HL)
                         EX   DE,HL               ; HL = pointer to mnemonic string
                         POP  DE
                         RET                      ; Fc = 0, Flash Eprom data returned...
.get_next           ADD  HL,DE
                    DJNZ find_loop                ; point at next entry...
                    SCF
                    POP  DE                       ; Flash Eprom Device Code not recognised
                    RET
; *************************************************************************************


; *************************************************************************************
; constants

.ksize              DEFM "K ",0
.fepr               DEFM "FILE AREA",1,"2-T",0
.slot_bnr           DEFM "SLOT ", 0
.bfre_msg           DEFM " bytes free",0
.bused_msg          DEFM " bytes used",0
.fisa_msg           DEFM " files saved",0
.fdel_msg           DEFM " files deleted",0
.nofepr_msg         DEFM 13,10,13,10,1,"2JC",1,"2+F"
                    DEFM "No File Area"
                    DEFM 1,"2JN",1,"3-FC",0

.FlashEprTypes
                    DEFB 6
                    DEFW FE_I28F004S5, 8, mnem_i004
                    DEFW FE_I28F008SA, 16, mnem_i008
                    DEFW FE_I28F008S5, 16, mnem_i8s5
                    DEFW FE_AM29F010B, 8, mnem_am010b
                    DEFW FE_AM29F040B, 8, mnem_am040b
                    DEFW FE_AM29F080B, 16, mnem_am080b

.mnem_i004          DEFM "I28F004S5 (512K)", 0
.mnem_i008          DEFM "I28F008SA (1024K)", 0
.mnem_i8S5          DEFM "I28F008S5 (1024K)", 0
.mnem_am010b        DEFM "AM29F010B (128K)", 0
.mnem_am040b        DEFM "AM29F040B (512K)", 0
.mnem_am080b        DEFM "AM29F080B (1024K)", 0
