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

     MODULE flash17

     include "error.def"
     include "syspar.def"
     include "director.def"
     include "stdio.def"
     include "saverst.def"
     include "memory.def"
     include "integer.def"
     include "fileio.def"
     include "interrpt.def"
     include "flashepr.def"
     include "dor.def"


     ; Library references
     ;

     lib CreateFilename            ; Create file(name) (OP_OUT) with path
     lib CreateWindow              ; Create windows...
     lib RamDevFreeSpace           ; poll for free space on RAM device
     lib ApplEprType               ; check for prescence application card in slot
     lib CheckBattLow              ; Check Battery Low condition
     lib FlashEprFileFormat        ; Create "oz" File Eprom or area on application card
     lib FlashEprCardId            ; Return Intel Flash Eprom Device Code (if card available)
     lib FlashEprWriteBlock        ; Write a block of byte to Flash Eprom
     lib FlashEprFileDelete        ; Mark file as deleted on Flash Eprom
     lib FlashEprFileSave          ; Save RAM file to Flash Eprom
     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFreeSpace          ; Return free space on File Eprom
     lib FileEprCntFiles           ; Return total of active and deleted files
     lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
     lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
     lib FileEprPrevFile           ; Return pointer to previous File Entry on File Eprom
     lib FileEprLastFile           ; Return pointer to last File Entry on File Eprom
     lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprFindFile           ; Find File Entry using search string (of null-term. filename)
     lib FileEprFetchFile          ; Fetch file image from File Eprom, and store it to RAM file

     include "fsapp.def"

     ORG $C000

; *************************************************************************************
;
; The Application DOR:
;
.FS_Dor
                    DEFB 0, 0, 0                  ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                      ; DOR type - application ROM
                    DEFB DOREnd0-DORStart0        ; total length of DOR
.DORStart0          DEFB '@'                      ; Key to info section
                    DEFB InfoEnd0-InfoStart0      ; length of info section
.InfoStart0         DEFW 0                        ; reserved...
                    DEFB 'J'                      ; application key letter
                    DEFB RAM_pages                ; I/O buffer for FlashStore
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW SafeWorkSpaceSize        ; Safe workspace
                    DEFW FS_Entry                 ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (none)
                    DEFB 0                        ; bank binding to segment 1 (none)
                    DEFB 0                        ; bank binding to segment 2 (none)
                    DEFB $3F                      ; bank binding to segment 3
                    DEFB AT_Ugly | AT_Popd        ; Ugly popdown
                    DEFB 0                        ; no caps lock on activation
.InfoEnd0           DEFB 'H'                      ; Key to help section
                    DEFB 12                       ; total length of help
                    DEFW FS_Dor
                    DEFB $3F                      ; point to topics (none)
                    DEFW FS_Dor
                    DEFB $3F                      ; point to commands (none)
                    DEFW FS_Help
                    DEFB $3F                      ; point to help (none)
                    DEFW FS_Dor
                    DEFB $3F                      ; point to token base (none)
                    DEFB 'N'                      ; Key to name section
                    DEFB NameEnd0-NameStart0      ; length of name
.NameStart0         DEFM "FlashStore",0
.NameEnd0           DEFB $FF
.DOREnd0

.FS_Help            DEFM $7F
                    DEFM "Freeware utility (GPL licence) by",$7F
                    DEFM "Thierry Peycru (Zlab) & Gunther Strube (InterLogic)",$7F
                    DEFM $7F
                    DEFM "Release V1.7.dev, December 2004",$7F
                    DEFM "(C) Copyright 1997-2004. All rights reserved",0
; *************************************************************************************



; *************************************************************************************
;
; We are somewhere in segment 3...
;
; Entry point for ugly popdown...
;
.FS_Entry
                    JP   app_main
                    SCF                           ; all RAM returned on popdown suicicide
                    RET
; *************************************************************************************



; *************************************************************************************
;
; FlashStore Error Handler
;
.ErrHandler
                    RET  Z
                    CP   rc_susp
                    JR   Z,dontworry
                    CP   rc_esc
                    JR   Z,akn_esc
                    CP   rc_quit
                    JR   Z,suicide
                    CP   A
                    RET
.akn_esc
                    LD   A,1                 ; acknowledge ESC detection
                    CALL_OZ os_esc
.dontworry
                    cp   a                   ; all other RC errors are returned to caller
                    RET
.suicide            xor  a
                    CALL_OZ(os_bye)          ; perform suicide, focus to Index...
.void               JR   void
; *************************************************************************************



; *************************************************************************************
;
.app_main
                    LD   A,(IX+$02)          ; IX points at information block
                    CP   $20+RAM_pages       ; get end page+1 of contiguous RAM
                    JR   Z, continue_fs      ; end page OK, RAM allocated...

                    LD   A,$07               ; No Room for FlashStore, return to Index
                    CALL_OZ(Os_Bye)          ; FlashStore suicide...
.continue_fs
                    ld   a, sc_ena
                    call_oz(os_esc)          ; enable ESC detection

                    xor  a
                    LD   B,A
                    ld   hl,Errhandler
                    CALL_OZ os_erh           ; then install Error Handler...

                    CALL PollFileEproms      ; user selects a File Eprom Area in one of the ext. slots.
                    JP   C, suicide          ; no File Area available, or Flash didn't have write support in found slot
                    JP   NZ, suicide         ; user aborted

                    CALL ClearWindowArea     ; just clear whole window area available
                    CALL mainmenu
                    JP   suicide             ; main menu aborted, leave popdown...
; *************************************************************************************


; *************************************************************************************
;
.mainmenu
                    CALL DispCmdWindow
                    CALL DispCtlgWindow
                    CALL FileEpromStatistics      ; parse for free space and total of files...

                    LD   HL, mainmenu
                    PUSH HL                       ; return address for functions...
.inp_main
                    CALL rdch
                    JR   NC,no_inp_err
                    CP   A
                    JR   inp_main
.no_inp_err
                    CP   IN_ESC
                    JP   Z, suicide
                    OR   $20
                    CP   's'
                    JP   Z, save_main
                    CP   'f'
                    JP   Z, fetch_main
                    CP   'r'
                    JP   Z, restore_main
                    CP   'c'
                    JP   Z, catalog_main
                    CP   '!'
                    JP   Z, format_main
                    CP   'v'
                    JP   Z, device_main
                    CP   'd'                      ; "Delete file"
                    JP   Z, delete_main
                    JR   inp_main
; *************************************************************************************


; *************************************************************************************
;
.ClearWindowArea
                    LD   HL, winbackground
                    CALL_OZ(Gn_Sop)
                    RET
; *************************************************************************************



; *************************************************************************************
;
.DispCmdWindow
                    ld   a,'1' | 128
                    ld   bc,$0000
                    ld   de,$080D
                    ld   hl, cmds_banner
                    call CreateWindow

                    ld   hl, menu_msg
                    call_oz(Gn_Sop)
                    RET
; *************************************************************************************


; *************************************************************************************
;
.DispCtlgWindow
                    push af
                    push bc
                    push de
                    push hl

                    ld   a,'2' | 128
                    ld   bc,$000F
                    ld   de,$0837
                    ld   hl, catalog_banner
                    call CreateWindow

                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
.PollSlots
                    push bc
                    push de
                    push hl

                    ld   hl, availslots+1    ; point to counter of available slots
                    push hl
                    ld   c,1                 ; begin with external slot 1
                    ld   e,0                 ; counter of available file eproms
.poll_loop
                    push bc                  ; preserve slot number...
                    call FileEprRequest      ; File Eprom Card or area available in slot C?
                    pop  bc
                    jr   c, no_fileepr
                    jr   nz, no_fileepr      ; no header was found, but a card was available of some sort
                         inc  e              ; File Eprom found
                         pop  hl
                         ld   (hl),c         ; size of file eprom in 16K banks
                         inc  hl
                         push hl
                         jr   next_slot
.no_fileepr
                         pop  hl
                         ld   (hl),0         ; indicate no file eprom
                         inc  hl
                         push hl
.next_slot
                    inc  c
                    ld   a,c
                    cp   4
                    jr   nz, poll_loop

                    ld   a,e
                    pop  hl
                    ld   (availslots),a      ; store total of File Eprom's found

                    pop  hl
                    pop  de
                    pop  bc
                    cp   a                   ; Fc = 0
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Scan external slots and display available File Eprom's from which the
; user selects an item.
;
; If no File Eprom Area was found, then slots 1-3 are examined for a Flash
; Card to be created with a File Eprom Area (whole card or part).
; If found and user acknowledges, then selected slot will be created with a File
; Area and selected as default.
;
; The selected Card will remain as the current File Area throughout
; the life of the instantiated FlashStore popdown.
;
; A small array, <availslots> is used to store the size of each File Eprom
; with the first byte indicating the total of File Eproms available.
;
.PollFileEproms
                    call PollSlots
                    or   a
                    jr   nz, select_slot     ; one or more File Eprom's were found, select one...
                         ld   c,3
.check_for_flash_cards
                         call CheckFlashCardID    ; Empty Flash Cards in slots 3-1?
                         jr   nc, chip_found      ; Yes...
                         dec  c
                         jr   nz, check_for_flash_cards

                         CALL greyscr
                         CALL DispCtlgWindow
.unkn_chip
                         ld   hl, noflash_msg
                         call DispErrMsg
                         scf
                         ret
.chip_found
                         LD   A,C
                         LD   (curslot),A         ; use found Flash Card this as current slot...
                         CALL greyscr
                         CALL DispCtlgWindow
                         call format_main         ; format Flash Card with new File Area
                         ret
.select_slot
                    cp   1
                    jr   z, select_default

                    call SelectSlot          ; User selects a slot from a list...
                    ret
.select_default                              ; select the only File Eprom available
                    ld   hl, availslots+1
                    ld   b,3
                    ld   c,1
                    xor  a
.sel_slot_loop
                    cp   (hl)
                    jr   nz, found_slot
                    inc  hl
                    inc  c
                    djnz sel_slot_loop
.found_slot
                    ld   a,c
                    ld   (curslot),a         ; current slot selected...
                    cp   a
                    ret
; *************************************************************************************


; *************************************************************************************
;
.SelectSlot
                    ld   a,'1' | 128 | 64
                    ld   bc,$0220
                    ld   de,$0516
                    ld   hl, selslot_banner
                    call CreateWindow
                    ld   hl, selvdu
                    call_oz GN_Sop

                    ld   a,1                 ; begin from slot 1
.disp_slot_loop
                    ld   (curslot),a
                    ld   hl, slottxt
                    call_oz(Gn_Sop)
                    ld   a,(curslot)
                    add  a,48
                    call_oz(OS_Out)          ; display slot number
                    ld   a, ' '
                    call_oz(OS_Out)

                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    jr   c, poll_for_ram_card
                    jr   nz, poll_for_ram_card
                         ld   hl, eprdev          ; C = size of File Area in 16K banks (if Fz = 1)
                         call slotsize
                         jr   nextline
.poll_for_ram_card
                    ld   a,(curslot)
                    ld   c,a
                    call RamDevFreeSpace
                    jr   c, poll_for_rom_card
                         ld   hl, ramdev
                         ld   c,a
                         call slotsize
                         jr   nextline
.poll_for_rom_card
                    ld   a,(curslot)
                    ld   c,a
                    call ApplEprType
                    jr   c, empty_slot
                         ld   hl, romdev
                         ld   c,b                 ; display size of card as defined by ROM header
                         call slotsize
                         jr   nextline
.empty_slot
                    ld   hl, emptytxt
                    call_oz(Gn_Sop)
                    jr   nextline
.slotsize
                    call_oz(Gn_Sop)     ; display device name...
                    ld   a,(curslot)
                    add  a,48
                    call_oz(Os_Out)     ; display device number (which is current slot number too)
                    call DispSlotSize   ; C = size of slot in 16K banks
                    ret
.nextline
                    call_oz(Gn_Nln)
                    ld   a,(curslot)
                    inc  a
                    cp   4
                    jr   nz, disp_slot_loop

                    ; Now, user selects the appropriate :EPR device ...
                    ld   a,1
                    ld   (curslot),a              ; set menu bar at "slot 1"
.select_slot_loop
                    call UserMenu
                    ret  c                        ; user aborted selection
                    ld   hl, availslots
                    ld   a,(curslot)
                    ld   b,0
                    ld   c,a
                    add  hl,bc
                    xor  a
                    cp   (hl)
                    jr   z, check_empty_flcard    ; user selected apparently void or illegal slot
                    cp   a                        ; slot selected successfully
                    ret

.check_empty_flcard call FlashWriteSupport
                    jr   nz, select_slot_loop     ; no Flash Card in slot...
                    jp   nc, format_main          ; empty flash card in slot (no file area, and erase/write support)

                    CALL DispCmdWindow
                    CALL DispCtlgWindow
                    CALL FileEpromStatistics
                    call DispIntelSlotErr         ; Intel Flash Card found in slot, but no erase/write support in slot
                    cp   a
                    ret

.DispSlotSize
                    ld   hl,size1delm
                    call_oz(Gn_Sop)

                    LD   H,0
                    LD   L,C
                    CALL m16
                    EX   DE,HL          ; size in DE...
                    CALL DispEprSize

                    ld   hl,size2delm
                    call_oz(Gn_Sop)
                    ret
; *************************************************************************************


; *************************************************************************************
; Return no of formatable file areas, available in inserted Flash Cards in slots 1-3.
;
; IN:
;     None.
; OUT:
;     A = formatable file areas (on for each slot, 1 - 3).
;     C = slot number for a default formatable File Area (if A>0)
;
.PollFileFormatSlots
                    push de
                    push bc
                    push hl

                    ld   hl, availslots+1    ; point to counter of available slots
                    push hl
                    ld   c,1                 ; begin with external slot 1
                    ld   e,0                 ; counter of available file eproms
.poll_format_loop
                    push bc                  ; preserve slot number...
                    call FileEprRequest      ; File Eprom Card or area available in slot C?
                    ld   a,c
                    pop  bc
                    jr   c, check_empty_fep
                         call FlashWriteSupport ; active or potential file area found, check if there's format support
                         jr   c, no_feprformat
.found_feprformat        inc  e              ; Formatable Flash Card found in slot
                         pop  hl
                         ld   (hl),a         ; size of Flash File Area in 16K banks
                         inc  hl
                         push hl
                         jr   next_feprslot
.check_empty_fep                         
                         call FlashWriteSupport
                         jr   c, no_feprformat
                         call CheckFlashCardID
                         ld   a,b            ; empty, formattable flash card has B banks available...
                         jr   found_feprformat
.no_feprformat
                         pop  hl
                         ld   (hl),0         ; indicate no formatable flash file area
                         inc  hl
                         push hl
.next_feprslot
                    inc  c
                    ld   a,c
                    cp   4
                    jr   nz, poll_format_loop

                    ld   a,e
                    pop  hl
                    ld   (availslots),a      ; store total of Formatable Flash File Areas
                    or   a
                    jr   z, end_pollformat   ; no formatable file areas found...

                    ld   hl,availslots+3
                    dec  c                   ; get default formatable slot in c, starting at 3...
.check_default_loop
                    ld   b,(hl)
                    inc  b
                    dec  b
                    jr   nz, end_pollformat
                    dec  hl
                    dec  c
                    jr   nz,check_default_loop
.end_pollformat
                    pop  hl
                    pop  de
                    ld   b,d                 ; orignal B restored
                    pop  de
                    cp   a                   ; Fc = 0
                    ret
; *************************************************************************************



; *************************************************************************************
;
.UserMenu
.menu_loop     CALL DisplMenuBar
               CALL rdch
               CALL RemoveMenuBar
               LD   HL, curslot
               CP   IN_ESC                        ; ESC?
               JR   Z, abort_select
               CP   IN_ENT                        ; ENTER?
               RET  Z
               CP   IN_DWN                        ; Cursor Down ?
               JR   Z, MVbar_down
               CP   IN_UP                         ; Cursor Up ?
               JR   Z, MVbar_up
               CP   '1'
               JR   C,menu_loop                   ; smaller than '1'
               CP   '4'
               JR   NC,menu_loop                  ; >= '4'
               SUB  A,48                          ; ['1'; '3'] keys selected
               LD   (HL),A
               CP   A
               RET
.abort_select
               SCF
               RET
.MVbar_down    LD   A,(HL)                        ; get Y position of menu bar
               CP   3                             ; has m.bar already reached bottom?
               JR   Z,Mbar_topwrap
               INC  A
               LD   (HL),A                        ; update new m.bar position
               JR   menu_loop                     ; display new m.bar position

.Mbar_topwrap  LD   A,1
               LD   (HL),A
               JR   menu_loop

.MVbar_up      LD   A,(HL)                        ; get Y position of menu bar
               CP   1                             ; has m.bar already reached top?
               JR   Z,Mbar_botwrap
               DEC  A
               LD   (HL),A                        ; update new m.bar position
               JR   menu_loop

.Mbar_botwrap  LD   A,3
               LD   (HL),A
               JR   menu_loop
; *************************************************************************************


; *************************************************************************************
;
.DisplMenuBar  PUSH AF
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               LD   HL, xypos                     ; (old menu bar will be overwritten)
               CALL_OZ(Gn_Sop)
               LD   A,32                          ; display menu bar at (0,Y)
               CALL_OZ(Os_out)
               LD   A,(curslot)                   ; get Y position of menu bar
               DEC  A
               ADD  A,32                          ; VDU...
               CALL_OZ(Os_out)
               LD   HL,MenuBarOn                  ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  AF
               RET
; *************************************************************************************


; *************************************************************************************
;
.RemoveMenuBar PUSH AF
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               LD   HL, xypos               ; (old menu bar will be overwritten)
               CALL_OZ(Gn_Sop)
               LD   A,32                    ; display menu bar at (0,Y)
               CALL_OZ(Os_out)
               LD   A,(curslot)             ; get Y position of menu bar
               DEC  A
               ADD  A,32                    ; VDU...
               CALL_OZ(Os_out)
               LD   HL,MenuBarOff           ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  AF
               RET
; *************************************************************************************



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

                    ld   a,'3' | 128 | 64
                    ld   bc,$0048
                    ld   de,$0814
                    ld   hl, buf1
                    call CreateWindow

                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    jr   z, cont_statistics
                         ld   hl, nofepr_msg
                         call_oz (Gn_Sop)
                         ret
.cont_statistics
                    ld   a,(curslot)
                    ld   c,a
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
                    call FileEprFreeSpace         ; free space on current File Eprom
                    ld   (free),bc
                    ld   (free+2),de

                    ld   hl,lac
                    CALL_OZ gn_sop                ; centre justify...

                    ld   hl,tinyvdu
                    CALL_OZ gn_sop

                    ld   a,(curslot)
                    ld   c,a
                    CALL FlashEprInfo
                    CALL_OZ gn_sop
                    CALL_OZ(Gn_Nln)

                    CALL DisplayEpromSize

                    ld   hl,t704_msg
                    CALL_OZ gn_sop
                    ld   hl,free
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,bfre_msg
                    CALL_OZ gn_sop
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

                    ld   hl, nocur
                    CALL_OZ  GN_Sop
                    ret
; *************************************************************************************


; *************************************************************************************
;
.DisplayEpromSize
                    LD   HL, t701_msg
                    CALL_OZ(GN_Sop)

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

                    LD   HL, tinyvdu
                    CALL_OZ(Gn_Sop)
                    CALL DispEprSize
                    LD   HL, ksize
                    CALL_OZ(Gn_sop)
                    LD   HL,fepr
                    CALL_OZ(Gn_Sop)
                    RET

.true_size          LD   HL, tinyvdu
                    CALL_OZ(Gn_Sop)
                    CALL DispEprSize
                    LD   HL, ksize
                    CALL_OZ(Gn_sop)
                    LD   HL,fepr
                    CALL_OZ(Gn_Sop)
                    RET

.DispEprSize        LD   B,D
                    LD   C,E
                    LD   HL,2
                    CALL IntAscii
                    CALL_OZ(Gn_Sop)     ; display size of File Eprom
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
;
; Display Window bar (below windows title) with caption text identified by HL pointer
;
.wbar
                    PUSH HL
                    LD   HL,bar1_sq
                    CALL_OZ gn_sop
                    POP  HL
                    CALL_OZ gn_sop
                    LD   HL,bar2_sq
                    CALL_OZ gn_sop
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Display slot selection window to choose another Flash Eprom Device
;
.device_main
                    CALL greyscr
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call PollSlots
                    call SelectSlot          ; user selects a File Eprom Area in one of the ext. slots.
                    pop  bc
                    jp   c, suicide          ; no File Eprom's available, kill FlashStore popdown...
                    ret  z                   ; user selected a device...

                    ld   a,c
                    ld   (curslot),a         ; user aborted selection, restore original slot...
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Save Files to Flash Eprom
;
.save_main          call cls
                    call CheckBatteryStatus
                    ret  c                        ; batteries are low - operation aborted

.init_save_main
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    pop  bc
                    ret  c

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
                    CALL ReportStdError
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
;
; Mark file as Deleted from File Eprom.
; User enters name of file that will be searched for, and if found,
; it will be marked as deleted.
;
.delete_main
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    pop  bc
                    ret  c

                    call FlashWriteSupport        ; check if Flash Card in current slot supports saveing files?
                    call c,DispIntelSlotErr
                    ret  c                        ; it didn't...
                    ret  nz                       ; (and flash chip was not found in slot!)

                    call cls
                    ld   hl,delfile_bnr
                    call wbar
                    ld   hl,exct_msg
                    call sopnln
                    ld   hl,fnam_msg
                    CALL_OZ gn_sop

                    LD   HL,buf1                  ; preset input line with '/'
                    LD   (HL),'/'
                    INC  HL
                    LD   (HL),0
                    DEC  HL
                    EX   DE,HL

                    LD   A,@00100011
                    LD   BC,$4001
                    LD   L,$20
                    CALL_OZ gn_sip
                    jp   c,sip_error
                    CALL_OZ gn_nln

                    CALL file_markdeleted
                    RET
; *************************************************************************************



; *************************************************************************************
;
.file_markdeleted
                    LD   A,(curslot)
                    LD   C,A
                    LD   DE,buf1
                    CALL FileEprFindFile          ; search for <buf1> filename on File Eprom...
                    JR   C, delfile_notfound      ; File Eprom or File Entry was not available
                    JR   NZ, delfile_notfound     ; File Entry was not found...

                    CALL FlashEprFileDelete
                    JR   NC, file_deleted
                    LD   HL,markdelete_failed
                    CALL DispErrMsg                    
.delfile_notfound
                    LD   HL,delfile_err_msg
                    CALL DispErrMsg
                    RET
.file_deleted
                    LD   HL,filedel_msg
                    CALL_OZ(GN_Sop)
                    CALL pwait
                    RET
; *************************************************************************************



; *************************************************************************************
;
; Fetch file from File Eprom.
; User enters name of file that will be searched for, and if found,
; fetched into a specified RAM file.
;
.fetch_main
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    ret  c

                    call cls
                    ld   hl,fetch_bnr
                    call wbar
                    ld   hl,exct_msg
                    call sopnln
                    ld   hl,fnam_msg
                    CALL_OZ gn_sop

                    LD   HL,buf1                  ; preset input line with '/'
                    LD   (HL),'/'
                    INC  HL
                    LD   (HL),0
                    DEC  HL
                    EX   DE,HL

                    LD   A,@00100011
                    LD   BC,$4001
                    LD   L,$20
                    CALL_OZ gn_sip
                    jr   c,sip_error
                    CALL_OZ gn_nln

                    call file_fetch
                    JR   C, fetch_error
                    RET
.sip_error
                    CP   rc_susp
                    JR   Z,fetch_main
                    RET
.fetch_error
                    PUSH AF
                    LD   B,0
                    LD   HL, buf3                 ; an error occurred, delete file...
                    CALL_OZ(Gn_Del)
                    POP  AF
                    CALL_OZ gn_err                ; display I/O error (or related)
                    RET
; *************************************************************************************



; *************************************************************************************
;
.file_fetch
                    LD   A,(curslot)
                    LD   C,A
                    LD   DE,buf1
                    CALL FileEprFindFile     ; search for <buf1> filename on File Eprom...
                    JP   C, not_found_err    ; File Eprom or File Entry was not available
                    JP   NZ, not_found_err   ; File Entry was not found...

                    ld   a,b                 ; File entry found
                    ld   (fbnk),a
                    ld   (fadr),hl           ; preserve pointer to found File Entry...
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e                   ; is file empty (zero lenght)?
                    jr   nz, get_name
                         ld   a, RC_EOF
                         scf                 ; indicate empty file...
                         ret
.get_name
                    ld   hl,ffet_msg          ; get destination filename from user...
                    CALL_OZ gn_sop
                    ld   de,buf1
                    LD   A,@00100011         ; buffer has filename
                    LD   BC,$4000
                    LD   L,$20
                    CALL_OZ gn_sip
                    jr   nc,open_file
                    cp   rc_susp
                    jr   z,get_name
                    ret  c                   ; user aborted...
.open_file
                    CALL_OZ(GN_Nln)
                    ld   hl,buf1
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
                    ld   bc,$80
                    ld   hl,buf1
                    ld   de,buf3             ; generate expanded filename...
                    CALL_OZ (Gn_Fex)
                    ret  c                   ; invalid filename...

                    ld   b,0                 ; (local pointer)
                    ld   hl,buf3             ; pointer to filename...
                    call CreateFilename      ; create file with and path
                    ret  c

                    CALL_OZ gn_nln           ; IX = handle of created file...
                    ld   hl,fetf_msg
                    CALL_OZ gn_sop
                    ld   hl,buf3
                    call sopnln              ; display created RAM filename (expanded)...

                    LD   A,(fbnk)
                    LD   B,A
                    LD   HL,(fadr)
                    CALL FileEprFetchFile    ; fetch file from current File Eprom
                    PUSH AF                  ; to RAM file, identified by IX handle
                    CALL_OZ(Gn_Cl)           ; then, close file.
                    POP  AF
                    RET  C

                    LD   HL, done_msg
                    CALL DispErrMsg
                    CP   A                   ; Fc = 0, File successfully fetched into RAM...
                    RET

.disp_exis_msg       LD   HL, exis_msg
                    CALL_OZ GN_Sop
                    RET

.not_found_err      LD   HL, file_not_found_msg
                    CALL DispErrMsg
                    RET
; *************************************************************************************



; *************************************************************************************
;
; Restore ALL active files into a user defined RAM device (or path)
;
.restore_main
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprRequest
                    pop  bc
                    ret  c

                    CALL cls

                    call FileEprCntFiles          ; any files to be restored?
                    ld   a,h
                    or   l
                    jr   z, no_active_files       ; no files available...

                    CALL cls
                    LD   HL,rest_banner
                    CALL wbar
                    LD   HL,defdst_msg
                    CALL sopnln
                    LD   HL,dest_msg
                    CALL_OZ gn_sop
                    CALL GetDefaultDevice
                    LD   DE,buf1
                    LD   A,@00100011
                    LD   BC,$4007
                    LD   L,$20
                    CALL_OZ gn_sip

; add some code here for ESC detection...

                    jr   nc, process_path
                    CP   rc_susp
                    JR   Z,restore_main      ; user aborted command...
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
                    JR   restore_main        ; syntax error in path name

.inv_path           LD   HL, invpath_msg
                    CALL DispErrMsg
                    JR   restore_main
.no_files
                    LD   HL, noeprfilesmsg
                    CALL DispErrMsg
                    RET
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
                    JR   C, no_files         ; Ups - the card was empty or not present...
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
;
; Put Default Device (Panel setting) at (buf1).
;
.GetDefaultDevice
                    LD    A, 64
                    LD   BC, PA_Dev                    ; Read default device
                    LD   DE, buf1                      ; buffer for device name
                    PUSH DE                            ; save pointer to buffer
                    CALL_OZ (Os_Nq)
                    POP  DE
                    LD   B,0
                    LD   C,A                           ; actual length of string...
                    EX   DE,HL
                    ADD  HL,BC
                    LD   (HL),0                        ; null-terminate device name
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Display name and size of stored files on Flash Eprom.
;
.catalog_main
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    ret  c                        ; abort - FE apparently not available...

                    call cls
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

                    ld   hl, noeprfilesmsg
                    CALL DispErrMsg
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
                    cp   rc_esc
                    jr   nz,new_page
                    ret
.new_page
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    jr   nc,ok_new_page
                    ld   a,rc_fail
                    CALL_OZ gn_err
                    RET
.ok_new_page
                    call cls
                    jp   cat_main_loop
.next_row
                    CALL_OZ gn_nln
                    jp   cat_main_loop

.norm_aff           ld   hl,norm_sq
                    jr   dispsq
.tiny_aff           ld   hl,tiny_sq
                    jr   dispsq
.jrsz_aff           ld   hl,jrsz_sq
                    jr   dispsq
.jnsz_aff           ld   hl,jnsz_sq
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
;
; Format Flash Card / (Re)Create File Area.
;
; Out:
;         Fc = 0,
;              Fz = 0, User prompted No to Format
;              Fz = 1, User performed format.
;         Fc = 1, Format process failed.
;
.format_main
                    call cls
                    call PollFileFormatSlots      ; investigate slots 1-3 for Flash Cards that can be formatted
                    or   a
                    jr   z, no_format_available   ; no available Flash Cards available that may be formatted... 
                    call FormatFileArea
                    ret  c                        ; format failed, or Intel Flash format not functional in slot..
                    ret  nz

                    call save_null_file           ; save the hidden "null" file to avoid Intel FE bootstrapping
                    ret
.no_format_available
                    LD   HL, noformat_msg
                    CALL DispErrMsg
                    scf
                    ret                    
.FormatFileArea
                    cp   1
                    jr   z, format_default
                    ; select slot to format...      
.format_default                    
                    ld   a,c
                    ld   (curslot),a              ; the selected slot...
                    call CheckBatteryStatus       ; don't format Flash Card
                    ret  c                        ; if Battery Low is enabled...

                    ld   hl,ffm1_bnr
                    call wbar                     ; "Format Flash eprom" head line

                    PUSH BC
                    CALL FileEprRequest           ; C = slot number...
                    POP  BC
                    JR   Z, area_found
                         PUSH BC
                         CALL ApplEprType         ; C = slot number...
                         POP  BC
                         JR   C, displ_noaplepr
                              CALL NoAppFileAreaMsg
                              JR   ackn_format
.displ_noaplepr
                              CALL disp_empty_flcard_msg  ; "Empty Flash Card in slot x"
                              JR   ackn_format
.area_found
                         CALL Disp_reformat_msg    ; "Re-format File Area (All data will be lost)."
.ackn_format
                    ld   hl,disp_filefmt_ask_msg
                    ld   de,no_msg
                    call yesno
                    ret  nz

                    call cls

                    ld   hl,ffm1_bnr
                    call wbar                     ; "Format Flash eprom" head line

                    ld   hl,ffm2_msg
                    CALL_OZ GN_Sop

                    LD   A,(curslot)
                    LD   C,A
                    CALL FlashEprFileFormat       ; erase blocks of file area & blow "oz" header at top
                    JR   C, formaterr             ; or at top of free area.

                    LD   HL,done_msg
                    CALL_OZ GN_Sop
                    LD   HL, wroz_msg
                    CALL_OZ GN_Sop
                    LD   HL,done_msg
                    CALL sopnln

                    CALL ResSpace
                    CP   A                        ; Signal success (Fc = 0, Fz = 1)
                    RET
.formaterr                                        ; current block was not formatted properly...
                    LD   HL, failed_msg          
                    CALL sopnln
                    LD   HL, fferr_msg
                    CALL DispErrMsg
                    RET                    
; *************************************************************************************



; *************************************************************************************
; Due to a strange side effect with Intel Flash Chips, a special "NULL" file is saved
; as the first file to the Card. These byte occupies the first bytes that othewise
; could be interpreted as a random boot command for the Intel chip - the behaviour
; is an Intel chip suddenly gone into command mode for no particular reason.
;
; The NULL file prevents this possible behaviour by save a file that avoids any kind
; of boot commands which sends the chip into command mode when the card has been inserted
; into a Z88 slot.
.save_null_file
                    ld   A,(curslot)
                    CP   3
                    JR   Z, poll_intel_card
.exit_null_file     CP   A                   ; It was not an Intel Flash that was formated, return "happy"
                    RET
.poll_intel_card
                    LD   C,A
                    CALL CheckFlashCardID
                    JR   C, exit_null_file
                    LD   A,$89               ; Check for Intel Manufacturer code
                    CP   H
                    JR   NZ, exit_null_file  ; it was not an Intel chip, then the null file is not necessary...

                    ld   b,$c0               ; Intel Flash available
                    ld   hl,0                ; blow null file at bottom of card in slot 3...
                    ld   de, nullfile
                    ld   c, MS_S1            ; use segment 1 to blow the bytes...
                    ld   iy,6                ; Initial File Entry is 6 bytes long...
                    call FlashEprWriteBlock
                    ret
.nullfile
                    defb 1, 0, 0, 0, 0, 0
; *************************************************************************************



; *************************************************************************************
;
.sopnln
                    PUSH AF
                    PUSH HL
                    CALL_OZ gn_sop
                    CALL_OZ gn_nln
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
;
.greyscr
                    PUSH HL
                    LD   HL,grey_msg
                    CALL_OZ gn_sop
                    POP  HL
                    RET
; *************************************************************************************



; *************************************************************************************
;
.cls
                    PUSH AF
                    PUSH HL

                    LD   HL, clsvdu
                    CALL_OZ Gn_Sop

                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
;
.rdch
                    CALL_OZ os_in
                    JR   NC,rd2
                    CP   RC_ESC
                    JR   Z, ret_esc
                    SCF
                    RET
.ret_esc
                    LD   A, IN_ESC
                    RET
.rd2
                    CP   0
                    RET  NZ
                    CALL_OZ os_in
                    RET
; *************************************************************************************


; *************************************************************************************
;
.pwait
                    LD   A,sr_pwt
                    CALL_OZ os_sr
                    JR   NC,pw2
                    CP   rc_susp
                    JR   Z,pwait
                    SCF
                    RET
.pw2
                    CP   0
                    RET  NZ
                    CALL_OZ os_in
                    RET
; *************************************************************************************


; *************************************************************************************
;
.yesno
                    LD   BC, yesno_loop
                    PUSH BC
                    JP   (HL)                ; call display message
.yesno_loop         LD   H,D
                    LD   L,E
                    CALL_OZ gn_sop
                    CALL_OZ(OS_Pur)          ; make sure no keys in sys. inp. buffer...
                    CALL rdch
                    RET  C
                    CP   IN_ESC
                    JR   Z, abort_yesno
                    CP   13
                    JR   NZ,yn1
                    LD   A,E
                    CP   yes_msg % 256        ; Yes, Fc = 0, Fz = 1
                    RET  Z
                    OR   A                   ; No, Fc = 0, Fz = 0
                    RET
.abort_yesno
                    OR   A                   ; ESC pressed
                    RET                      ; return Fc = 0, Fz = 0
.yn1
                    OR   32
                    CP   'y'
                    JR   NZ,yn2
                    LD   DE,yes_msg
                    JR   yesno_loop
.yn2
                    CP   'n'
                    JR   NZ,yesno
                    LD   DE,no_msg
                    JR   yesno_loop
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
; Fetch Intel Flash Eprom Device Code and return information of chip.
;
; IN:
;    None.
;
; OUT:
;    Fc = 0, Flash Eprom Recognized in slot 3
;         B = total of Blocks on Flash Eprom
;         HL = pointer to Mnemonic description of Flash Eprom
;    Fc = 1, Flash Eprom not found in slot X, or Device code not found
;
.FlashEprInfo       LD   A,(curslot)
                    LD   C,A
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
;
; User is prompted with "Press SPACE to Resume". The keyboard is then scanned
; for the SPACE key.
;
; The routine returns when the user has pressed ESC.
;
; Registers changed after return:
;    None.
;
.ResSpace
                    PUSH AF
                    PUSH HL
                    LD   HL,ResSpace_msg
                    CALL_OZ gn_sop
.escin
                    CALL rdch
                    JR   C,escin
                    CP   32
                    JR   NZ,escin
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; Display a centre-justified message, which is defined by two null-terminated strings. 
; The current slot number is displayed between the two strings.
;
; IN:
;    HL = Pointer to address block, containg (string1), (string2)
;
; Registers changed after return:
;    AFBCDE../IXIY same
;    ......HL/.... different
;
.DispSlotErrorMsg   PUSH AF
                    PUSH DE
                    CALL VduEnableCentreJustify
                    CALL GetMsgAddr
                    CALL_OZ GN_Sop
                    LD   A,(curslot)
                    ADD  A,48
                    CALL_OZ OS_Out
                    EX   DE,HL
                    CALL GetMsgAddr         
                    CALL sopnln
                    CALL VduEnableNormalJustify
                    POP  DE
                    POP  AF
                    RET
.GetMsgAddr         LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    INC  HL
                    EX   DE,HL
                    RET


; *************************************************************************************
.NoAppFileAreaMsg   PUSH HL
                    LD   HL, no_appflarea_msgs
                    CALL DispSlotErrorMsg
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.disp_empty_flcard_msg
                    PUSH HL
                    LD   HL, empty_flcard_msgs
                    CALL DispSlotErrorMsg
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.disp_reformat_msg
                    PUSH HL
                    LD   HL, reformat_msgs
                    CALL DispSlotErrorMsg
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.disp_filefmt_ask_msg
                    PUSH HL
                    LD   HL, filefmt_msgs
                    CALL DispSlotErrorMsg
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.DispIntelSlotErr
                    push af
                    push hl
                    call cls
                    ld   hl, intelslot_msgs
                    CALL DispSlotErrorMsg
                    CALL ResSpace            ; "Press SPACE to resume" ...
                    pop  hl
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Write Error message, and wait for SPACE key to be pressed.
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.DispErrMsg
                    PUSH AF                  ; preserve error status...
                    PUSH HL
                    CALL_OZ GN_Nln
                    CALL VduEnableCentreJustify
                    CALL sopnln
                    CALL VduEnableNormalJustify
                    CALL ResSpace            ; "Press SPACE to resume" ...
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
.VduEnableCentreJustify
                    PUSH HL
                    LD   HL, errmsg_cjust
                    CALL_OZ GN_Sop           ; enable centre justify VDU                    
                    POP  HL
                    RET
; *************************************************************************************

                    
; *************************************************************************************
.VduEnableNormalJustify
                    PUSH HL
                    LD   HL, errmsg_njust
                    CALL_OZ GN_Sop           ; enable centre justify VDU                    
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
;
.ReportStdError     PUSH AF
                    CALL_OZ(Gn_Err)
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
;
; Check for Battery Low status and report to user, if enabled.
;
; IN:
;    None.
;
; Out:
;    Fc = 1, if Battery Low Status is enabled
;         A = RC_WP (Flash Eprom Write Protected)
;    Fc = 0, Battery Power is operational for Flash Eprom action
;
.CheckBatteryStatus CALL CheckBattLow
                    RET  NC

                    PUSH HL
                    LD   HL, battlowmsg
                    CALL DispErrMsg
                    POP  HL

                    LD   A, RC_Wp                 ; general failure...
                    SCF
                    RET
; *************************************************************************************



; *************************************************************************************
;
; Validate the Flash Card erase/write functionality in the specified slot.
; If the Flash Card in the specified slot contains an Intel chip, the
; slot must be 3 for format, save and delete functionality.
; Report an error to the caller with Fc = 1, if an Intel Flash chip was recognized
; in all slots except 3.
;
; (This routine is called by format, save & delete functionality in FlashStore)
;
; IN:
;    C = slot number
;
; OUT:
;    Fz = 1, if a Flash Card is available in the current slot (Fz = 0, no Flash Card available!)
;    Fc = 1, if no erase/write support is available for current slot.
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.FlashWriteSupport
                    push hl
                    push de
                    push bc
                    push af
                    call CheckFlashCardID
                    jr   nc, flashcard_found
                    or   c                   ; Fz = 0, indicate no Flash Card available in slot
                    scf                      ; Fc = 1, indicate no erase/write support either...
                    jr   exit_chckflsupp
.flashcard_found
                    ld   a,c
                    cp   3
                    jr   z, exit_chckflsupp  ; erase/write works for all flash cards in slot 3 (Fc=0, Fz=1)
                    ld   a,$01
                    cp   h                   ; Intel flash chip in slot 0,1 or 2?
                    jr   z, exit_chckflsupp  ; No, we wound an AMD Flash chip (erase/write allowed, Fc=0, Fz=1)
                    cp   a                   ; (Fz=1, indicate that Flash is available..)
                    scf                      ; no erase/write support in slot 0,1 or 2 with Intel Flash...
.exit_chckflsupp
                    pop  bc
                    ld   a,b                 ; A restored (f changed)
                    pop  bc
                    pop  de
                    pop  hl
                    ret
; *************************************************************************************



; *************************************************************************************
;
; Check/Fetch Flash Card ID (Manufacturer & Device Code)
;
; IN:
;    C = Slot Number
;
; Out:
;    Register status from FlashEprCardId library routine
;    (flashid) variable updated: FFFF = no Flash Card found, otherwise HL -> (flashid)
;
.CheckFlashCardID
                    call FlashEprCardId
                    jr   c, no_flash_found
                    ld   (flashid),hl
                    ret
.no_flash_found     ld   hl,-1
                    ld   (flashid),hl
                    ret
; *************************************************************************************


; *************************************************************************************
; Text & VDU constants.
;
.catalog_banner     DEFM "FLASHSTORE V1.7.dev, (C) 1997-2004 Zlab & InterLogic",0

.cmds_banner        DEFM "Commands",0
.menu_msg
                    DEFM 1,"3@",32,32
                    DEFM 1,"B C",1,"Batalogue",$0D,$0A
                    DEFM 1,"B S",1,"Bave file",$0D,$0A
                    DEFM 1,"B F",1,"Betch file",$0D,$0A
                    DEFM 1,"B R",1,"Bestore",$0D,$0A
                    DEFM " De", 1,"BV",1,"Bice",$0D,$0A
                    DEFM 1,"B D",1,"Belete file",$0D,$0A
                    DEFM 1,"B ! ",1,"BFormat"
                    DEFM 1,"2-C"
                    defb 0

.selslot_banner     DEFM "SELECT FILE AREA",0
.eprdev             DEFM ":EPR.",0
.ramdev             DEFM ":RAM.",0
.romdev             DEFM ":ROM.",0
.slottxt            DEFM "SLOT ",0
.emptytxt           DEFM "EMPTY",0
.size1delm          DEFM " [",0
.size2delm          DEFM "K]",0
.selvdu             DEFM 1,"3-SC"               ; no vertical scrolling, no cursor
                    DEFM 1,"2+T",0

.xypos              DEFM 1,"3@",0
.norm_sq            DEFM 1,"2-G",1,"4+TRUF",1,"4-TRU ",0
.tiny_sq            DEFM 1,"5+TRGUd",1,"3-RU ",0
.jrsz_sq            DEFM 1,"2JR",0
.jnsz_sq            DEFM 1,"2JN",0
.grey_msg           DEFM 1,"6#8  ",$7E,$28,1,"2H8",1,"2G+",0
.clsvdu             DEFM 1,"2H2",12,0
.winbackground      DEFM 1,"7#1",32,32,32+94,32+8,128
                    DEFM 1,"2C1",0

.SelectMenuWindow
                    DEFM 1,"2H1",1,"2-C",0     ; activate menu window, no Cursor...
.MenuBarOn          DEFM 1,"2+R"               ; set reverse video
                    DEFM 1,"2A",32+22,0        ; XOR 'display' menu bar (22 chars wide)
.MenuBarOff         DEFM 1,"2-R"               ; set reverse video
                    DEFM 1,"2A",32+22,0        ; apply 'display' menu bar (22 chars wide)

.slot_bnr           DEFM "SLOT "
.lac                DEFM 1,"2JC",0
.t704_msg           DEFM 1,"3@",33,35,0
.bfre_msg           DEFM " bytes free",0
.fisa_msg           DEFM " files saved",0
.fdel_msg           DEFM " files deleted",0
.nocur              DEFM 1,"2-C",0
.nofepr_msg         DEFM 13,10,13,10,1,"2JC",1,"2+F"
                    DEFM "No File Area",13,10,"available"
                    DEFM 1,"2JN",1,"3-FC",0
.t701_msg           DEFM 1,"3@",33,33,0
.tinyvdu            DEFM 1,"2+T",0
.ksize              DEFM "K ",0
.fepr               DEFM "FILE AREA",1,"2-T",0
.bar1_sq            DEFM 1,"4+TUR",1,"2JC",1,"3@  ",0
.bar2_sq            DEFM 1,"3@  ",1,"2A",87,1,"4-TUR",1,"2JN",0

.fsv1_bnr           DEFM "SAVE FILES TO FILE AREA",0
.wcrd_msg           DEFM " Wildcards are allowed.",0
.fnam_msg           DEFM 1,"2+C Filename: ",0

.curdir             DEFM ".",0
.fsv2_bnr           DEFM "SAVING TO FILE AREA ...",0
.ends0_msg          DEFM " file",0
.ends1_msg          DEFM " has been saved.",$0D,$0A,0
.ends2_msg          DEFM $0D,$0A,1,"2JCNo files saved.",1,"2JN",$0D,$0A,0
.savf_msg           DEFM "Saving ",0

.fsok_msg           DEFM " Done.",$0D,$0A,0
.blowerrmsg         DEFM "File was not saved properly - will be re-saved.",$0D,$0A,0
.zerolen_msg        DEFM "File has zero length - ignored.",$0D,$0A,0

.delfile_bnr        DEFM "MARK FILE AS DELETED IN FILE AREA",0

.delfile_err_msg    DEFM "File not found.", 0
.markdelete_failed  DEFM "Error. File was not deleted.",0
.filedel_msg        DEFM 1,"2JC", 13,10, "File was deleted.",1,"2JN", 0

.fetch_bnr          DEFM "FETCH FROM FILE AREA",0
.exct_msg           DEFM " Enter exact filename (no wildcard).",0

.fetf_msg           DEFM 1,"2+C Fetching to ",0
.done_msg           DEFM "Completed.",$0D,$0A,0
.ffet_msg           DEFM 13," Fetch as : ",0
.exis_msg           DEFM 13," Overwrite RAM file : ", 13, 10, 0
.file_not_found_msg DEFM "File was not found in File Area.", 0

.no_restore_files   DEFM "No files available in File Area to restore.", 0

.rest_banner        DEFM "RESTORE ALL FILES FROM FILE AREA",0
.fetch_msg          DEFM $0D,$0A," Fetching... ",0
.promptovwrite_msg  DEFM " Overwrite RAM files? ",13, 10, 0
.defdst_msg         DEFM " Enter Device/path.",0
.dest_msg           DEFM 1,"2+C Device: ",0
.illgwc_msg         DEFM $0D,$0A,"Wildcards not allowed.",0
.invpath_msg        DEFM $0D,$0A,"Invalid Path",0

.prompt_delfiles_msg DEFM 13, 10, " Show deleted files? ",13,10,0
.noeprfilesmsg      DEFM "Empty File Area.",$0D,$0A,0


.endf_msg           DEFM 1,"2-G",1,"4+TUR END ",1,"4-TUR",0

.failed_msg         DEFM "Failed.",0
.fferr_msg          DEFM "File Area was not formatted/erased properly!",$0D,$0A,0
.ffm1_bnr           DEFM "FORMAT FILE AREA ON FLASH CARD",0
.ffm2_msg           DEFM 13, 10, " Formatting File Area ... ",0
.wroz_msg           DEFM " Writing File Area Header... ",0
.noflash_msg        DEFM 1,"BNo Flash Cards were found in slots 1-3.",1,"B",0
.noformat_msg       DEFM 1,"BNo Flash Cards were available to be formatted.",1,"B",0                    


.yes_msg            DEFM 13,1,"2+C Yes",8,8,8,0
.no_msg             DEFM 13,1,"2+C No ",8,8,8,0

.ResSpace_msg       DEFM 1,"2JC",1,"3+FTPRESS ",1,SD_SPC," TO RESUME",1,"4-FTC",1,"2JN",$0D,$0A,0

.no_appflarea_msgs  DEFW no_appflarea1_msg
                    DEFW no_appflarea2_msg
.no_appflarea1_msg  DEFM 13, 10, 1,"BNo File Area available on Application Card in slot ",0
.no_appflarea2_msg  DEFM ".",1,"B",0

.empty_flcard_msgs  DEFW empty_flcard1_msg
                    DEFW empty_flcard2_msg
.empty_flcard1_msg  DEFM 13, 10, 1,"BFlash Card is empty in slot ", 0
.empty_flcard2_msg  DEFM ".",1,"B",0

.reformat_msgs      DEFW reformat1_msg
                    DEFW reformat2_msg
.reformat1_msg      DEFM 13, 10, 1,"BRe-format File Area in slot ",0
.reformat2_msg      DEFM " (All data is lost).",1,"B",0

.filefmt_msgs       DEFW filefmt_ask1_msg
                    DEFW filefmt_ask2_msg
.filefmt_ask1_msg   DEFM 1,"2+C",13,"Format (or create new) file area in slot ",0
.filefmt_ask2_msg   DEFM "? ",0

.intelslot_msgs     DEFW intelslot_err1_msg
                    DEFW intelslot_err2_msg
.intelslot_err1_msg DEFM 13, 10, 1,"BAn Intel Flash Card was found in (current) slot ",0
.intelslot_err2_msg DEFM ".",1,"B", 13, 10, "You can only format file area, save files or", 13, 10
                    DEFM "mark files as deleted in slot 3.", 13, 10, 0

.errmsg_cjust       DEFM 1, "2JC", 0
.errmsg_njust       DEFM 1, "2JN", 0

.battlowmsg         DEFM "Batteries are low.",0


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
