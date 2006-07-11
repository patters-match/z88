; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2006
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     MODULE Main

     include "error.def"
     include "director.def"
     include "stdio.def"
     include "memory.def"
     include "fileio.def"
     include "romupdate.def"

     lib RamDevFreeSpace, FlashEprCardId
     lib CreateWindow

     xdef app_main
     xdef GetSlotNo, GetSectorNo
     xdef suicide
     xdef CheckCrc
     xdef CheckFlashWriteSupport, FlashWriteSupport
     xdef GetTotalFreeRam

     xref bbcbas_progversion, progversion_banner
     xref ReadConfigFile
     xref DeletePreservedSectorBanks
     xref ErrMsgNoFlash, ErrMsgIntelFlash
     xref Update_16k_application, Update_OzRom



; *************************************************************************************
;
; RomUpdate Error Handler
;
.ErrHandler
                    ret  z
                    cp   rc_susp
                    jr   z,dontworry
                    cp   rc_esc
                    jr   z,akn_esc
                    cp   rc_quit
                    jr   z,suicide
                    cp   a
                    ret
.akn_esc
                    ld   a,1                            ; acknowledge esc detection
                    oz   os_esc
.dontworry
                    cp   a                              ; all other RC errors are returned to caller
                    ret
.suicide
                    call DeletePreservedSectorBanks     ; clean up any temp bank files before leaving...
                    xor  a
                    oz   os_bye                         ; perform suicide, focus to Index...
.void               jr   void
; *************************************************************************************


; *************************************************************************************
; Main program entry
;
.app_main
                    ld   a, sc_ena
                    call_oz(os_esc)                     ; enable ESC detection

                    xor  a
                    ld   b,a
                    ld   hl,Errhandler
                    oz   os_erh                         ; then install Error Handler...
if POPDOWN
                    ld   a,'1' | 128
                    ld   bc,$0004
                    ld   de,$0854
                    ld   hl, progversion_banner
                    call CreateWindow                   ; the popdown needs to create it's own window (BBC BASIC has a window established)
else
                    ld   hl, bbcbas_progversion
                    oz   GN_Sop                         ; just display the program version in BBC BASIC
                    oz   GN_Nln
endif

.read_cfgfile
                    call ReadConfigFile                 ; load parameters from 'romupdate.cfg' file (exit app if failure...)
                    ld   a,(update_task)
                    cp   upd_16kapp
                    jp   z,Update_16k_application       ; configuration file defines an Application Update task
                    cp   upd_ozrom
                    jp   z,Update_OzRom                 ; configuration file defines an OZ ROM Update task...
                    jp   suicide                        ; unknown configuration task, exit program
; *************************************************************************************



; *************************************************************************************
; Compare CRC in DEHL with (BC).
;
; IN:
;       DEHL = calculated CRC
;       BC = pointer to start of CRC in memory
; OUT:
;       Fc = 0 (always)
;       Fz = 1, CRC is valid
;       Fz = 0, CRC does not match the CRC supplied in DEHL
;       BC points at byte after CRC in memory
;
; Registers changed after return:
;    ....DEHL/IXIY same
;    AFBC..../.... different
;
.CheckCrc
                    ld   a,(bc)
                    inc  bc
                    cp   l
                    jr   nz, return_crc_status
                    ld   a,(bc)
                    inc  bc
                    cp   h
                    jr   nz, return_crc_status
                    ld   a,(bc)
                    inc  bc
                    cp   e
                    jr   nz, return_crc_status
                    ld   a,(bc)
                    inc  bc
                    cp   d
.return_crc_status
                    scf
                    ccf                                 ; return Fc = 0 always
                    ret                                 ; Fz indicates CRC status
; *************************************************************************************



; *************************************************************************************
; Get sector number for specfied bank (slot independent).
;
; IN:
;    A = bank number
;
; OUT:
;    A = sector number (that bank is part of)
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.GetSectorNo
                    rrca
                    rrca                                ; bankNo/4
                    and  @00001111                      ; sector number containing bank
                    ret
; *************************************************************************************


; *************************************************************************************
; Get slot number from absolute bank number (rotate slot mask in bits 1,0)
;
; IN:
;    A = (absolute) bank number
;
; OUT:
;    A = slot number (that bank number is part of)
;    C = slot number
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.GetSlotNo
                    rlca
                    rlca
                    and  @00000011
                    ld   c,a
                    ret
; *************************************************************************************



; *************************************************************************************
; Check if current slot supports Flash Write/erase operations.
; Return only if write/erase support is available for slot. In error situation,
; display error message and exit RomUpdate program.
;
; IN:
;    C = slot Number
;
; OUT:
;    Only returns with Fz = 1, Fc = 0 (Flash Card available in slot, write/erase support)
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.CheckFlashWriteSupport
                    push bc
                    call FlashWriteSupport              ; is flash card updateable in slot C?
                    pop  bc                             ; (restore bank no of pointer to DOR)
                    jp   nz,ErrMsgNoFlash               ; Display error to user that app. can only be updated on Flash Card (not Eprom)
                    jp   c,ErrMsgIntelFlash             ; no write/erase support for Intel Flash Card other than in slot 3
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Validate the Flash Card erase/write functionality in the specified slot.
; If the Flash Card in the specified slot contains an Intel chip, the slot
; must be 3 for erase and write functionality.
; Report an error to the caller with Fc = 1, if an Intel Flash chip was recognized
; in all slots except 3.
;
; IN:
;    C = slot number
;
; OUT:
;    Fz = 1, if a Flash Card is available in the current slot (Fz = 0, no Flash Card available!)
;         B = size of card in 16K banks
;    Fc = 1, if no erase/write support is available for current slot.
;
; Registers changed after return:
;    A..CDEHL/IXIY same
;    .FB...../.... different
;
.FlashWriteSupport
                    push hl
                    push de
                    push bc
                    push af
                    call FlashEprCardId
                    jr   nc, flashcard_found
                    or   c                   ; Fz = 0, indicate no Flash Card available in slot
                    scf                      ; Fc = 1, indicate no erase/write support either...
                    jr   exit_chckflsupp
.flashcard_found
                    ld   a,c
                    cp   3
                    jr   z, end_chckflsupp   ; erase/write works for all flash cards in slot 3 (Fc=0, Fz=1)
                    ld   a,$01
                    cp   h                   ; Intel flash chip in slot 0,1 or 2?
                    jr   z, end_chckflsupp   ; No, we wound an AMD Flash chip (erase/write allowed, Fc=0, Fz=1)
                    cp   a                   ; (Fz=1, indicate that Flash is available..)
                    scf                      ; no erase/write support in slot 0,1 or 2 with Intel Flash...
.end_chckflsupp
                    pop  de
                    ld   a,d                 ; A restored (f changed)
                    pop  de
                    ld   c,e                 ; C restored (B = total of 16K banks on card)
                    pop  de                  ; DE restored
                    pop  hl                  ; HL restored
                    ret
.exit_chckflsupp
                    pop  de
                    ld   a,d                 ; A restored (f changed)
                    pop  bc
                    pop  de
                    pop  hl
                    ret
; *************************************************************************************


; *************************************************************************************
; Return total amount of free RAM pages in Z88 system
;
; IN:
;    None.
; OUT:
;    HL = accumulated free RAM pages in Z88
;
.GetTotalFreeRam
                    push bc                             ; preserve amount of necessary pages for preserved banks
                    push de

                    ld   hl,0
                    ld   b,3
.scan_ram_loop
                    ld   a,b
                    call RamDevFreeSpace                ; ask slot for available free RAM (pages)
                    jr   c, poll_next_ram               ; not a RAM card...
                    add  hl,de                          ; total of free ram pages in Z88...
.poll_next_ram
                    dec  b
                    ld   a,b
                    cp   -1
                    jr   nz, scan_ram_loop

                    pop  de
                    pop  bc
                    ret
; *************************************************************************************
