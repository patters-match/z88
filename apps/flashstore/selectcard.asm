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
;
Module SelectCard

; This module contains functionality that displays the card / file area selection pop-up
; window and cursor movement

     XDEF SelectFileArea, SelectCardCommand, VduCursor
     XDEF PollFileEproms

     LIB CreateWindow, RamDevFreeSpace
     LIB FileEprRequest, ApplEprType, FlashEprCardId

     XREF greyscr, greyfont, nocursor, nogreyfont, notinyfont
     XREF FlashWriteSupport, execute_format
     XREF CheckFlashCardID
     XREF DispCmdWindow, DispCtlgWindow
     XREF FileEpromStatistics, DispIntelSlotErr, DispKSize
     XREF pwait, rdch
     XREF m16
     XREF DispErrMsg


     include "stdio.def"
     include "fsapp.def"



; *************************************************************************************
;
; Display slot selection window to choose another Flash Card Device
;
.SelectCardCommand
                    CALL greyscr
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call PollSlots
                    ld   hl, selslot_banner
                    call SelectFileArea          ; user selects a File Eprom Area in one of the external slots
                    pop  bc
                    jp   c, user_aborted
                    ret  z                   ; user selected a device, already stored in (curslot)...
.user_aborted
                    ld   a,c
                    ld   (curslot),a         ; user aborted selection, restore original slot...
                    ret
; *************************************************************************************


; *************************************************************************************
; Display the contents of slots 1-3 in an easy understandable symbolically form.
;
; IN: HL = Window Banner Title
;
.SelectFileArea
                    CALL greyscr

                    push hl
                    ld   a, 64 | '3'
                    ld   bc, $004E
                    ld   de, $080F
                    call CreateWindow
                    ld   hl, selectdevhelp
                    call_oz GN_Sop           ; Display small help text in right side window

                    ld   a, 128 | '2'
                    ld   bc, $0016
                    ld   de, $082A
                    pop  hl
                    call CreateWindow        ; Device selection window.

                    ld   a,1                 ; begin from slot 1...
.disp_slot_loop
                    ld   (curslot),a

                    ld   c,a
                    call FileEprRequest
                    jr   c, poll_for_ram_card
                    jr   nz, poll_for_ram_card
                         ld   hl, eprdev          ; File area identified.
                         call DispSlotInfo            ; C = size of File Area in 16K banks (if Fz = 1)
                         jr   nextline            ; D = size of card in 16K banks
.poll_for_ram_card
                    ld   a,(curslot)
                    ld   c,a
                    call RamDevFreeSpace
                    jr   c, poll_for_rom_card

                         call DisplayRamCard      ; RAM Card was found...
                         jr   nextline
.poll_for_rom_card
                    ld   a,(curslot)
                    ld   c,a
                    call ApplEprType
                    jr   c, empty_slot
                         ld   hl, romdev
                         ; ld   c,b
                         call DispSlotInfo        ; display size of card as defined by ROM header
                         jr   nextline
.empty_slot
                    ld   a,(curslot)
                    ld   c,a
                    CALL FlashEprCardId
                    JR   C, slot_really_empty

.slot_really_empty
                    CALL SlotCardBoxCoord
                    LD   A, @00000011
                    CALL DrawCardBox
                    LD   A,B
                    ADD  A,2
                    LD   B,A
                    LD   A,C
                    ADD  A,3
                    LD   C,A
                    CALL VduCursor
                    ld   hl, emptytxt
                    call_oz(Gn_Sop)
                    jr   nextline
.DispSlotInfo
                    PUSH BC
                    PUSH HL
                    CALL SlotCardBoxCoord
                    XOR  A
                    CALL DrawCardBox
                    INC  C              ; Y++
                    INC  B
                    INC  B
                    CALL VduCursor
                    POP  HL
                    CALL_OZ Gn_Sop      ; display device name...
                    POP  BC
                    call DispSlotSize   ; C = size of slot in 16K banks
                    ret
.nextline
                    ld   a,(curslot)
                    inc  a
                    cp   4
                    jr   nz, disp_slot_loop

; ********* to be removed **************
                    call pwait
                    ret
; ********* to be removed **************

                    ; Now, user selects card (if possible) ...
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

.check_empty_flcard
                    call FlashWriteSupport
                    jr   nz, select_slot_loop     ; no Flash Card in slot...
                    jp   nc, execute_format       ; empty flash card in slot (no file area, and erase/write support)

                    CALL DispCmdWindow
                    CALL DispCtlgWindow
                    CALL FileEpromStatistics
                    call DispIntelSlotErr         ; Intel Flash Card found in slot, but no erase/write support in slot
                    cp   a
                    ret

.DispSlotSize
                    push hl
                    LD   H,0
                    LD   L,C
                    CALL m16
                    EX   DE,HL          ; size in DE...
                    CALL DispKSize

                    ld   hl,sizeK
                    call_oz(Gn_Sop)
                    pop  hl
                    ret
.DisplayRamCard
                    CALL SlotCardBoxCoord
                    LD   A,4
                    CALL DrawCardBox
                    INC  C              ; Y++
                    INC  B
                    INC  B
                    CALL VduCursor
                    LD   HL,ramdev
                    CALL_OZ Gn_Sop      ; display device name...
                    LD   A,(curslot)
                    CALL RamDevFreeSpace
                    LD   C,A
                    call DispSlotSize   ; C = size of slot in 16K banks
                    RET
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
               PUSH BC
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               LD   B,0                           ; display menu bar at (0,Y)
               LD   A,(curslot)                   ; get Y position of menu bar
               DEC  A
               LD   C,A                           ; VDU cursor at ...
               CALL VduCursor                     ; (0,curslot)
               LD   HL,MenuBarOn                  ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  BC
               POP  AF
               RET
; *************************************************************************************


; *************************************************************************************
;
.RemoveMenuBar PUSH AF
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               LD   B,0                           ; display menu bar at (0,Y)
               LD   A,(curslot)                   ; get Y position of menu bar
               DEC  A
               LD   C,A                           ; VDU cursor at ...
               CALL VduCursor                     ; (0,curslot)
               LD   HL,MenuBarOff                 ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  AF
               RET
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
                         call execute_format      ; format Flash Card with new File Area
                         ret
.select_slot
                    cp   1
                    jr   z, select_default

                    ld   hl, selslot_banner
                    call SelectFileArea          ; User selects a slot from a list...
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
; Draw a minimalistic Z88 Card outline using VDU Box characters.
;
; IN:
;     A = BIT 0: draw card box in grey colour
;     A = BIT 1: draw only outline (not the card label line)
;     A = BIT 2: draw Padlock on left bottom edge.
;    BC = (X,Y)
;
.DrawCardBox
                    PUSH BC
                    PUSH HL
                    PUSH AF

                    BIT  0,A
                    JR   Z, use_nocursor
                    LD   HL, greyfont   ; draw the card box in grey colour.
                    CALL_OZ GN_Sop
.use_nocursor
                    LD   HL, nocursor
                    CALL_OZ GN_Sop

                    CALL VduCursor      ; set VDU Cursor at (X,Y)
                    LD   HL,cardtop     ; draw top edge of card box
                    CALL_OZ GN_Sop
                    INC  C              ; Y++
                    CALL DrawCardSides
                    INC  C              ; Y++
                    CALL VduCursor      ; set VDU Cursor at (X,Y)
                    POP  AF
                    PUSH AF
                    BIT  1,A
                    JR   Z, draw_middleline
                    CALL DrawCardSides
                    JR   next_cardside
.draw_middleline
                    LD   HL,cardmiddle  ; draw middle line of card box
                    CALL_OZ GN_Sop
.next_cardside
                    INC  C              ; Y++
                    CALL DrawCardSides
                    INC  C              ; Y++
                    CALL DrawCardSides
                    INC  C              ; Y++
                    CALL DrawCardSides
                    INC  C              ; Y++
                    CALL VduCursor      ; set VDU Cursor at (X,Y)
                    LD   HL,cardbottom  ; draw bottom edge of card box
                    CALL_OZ GN_Sop

                    LD   HL, nogreyfont
                    CALL_OZ GN_Sop
                    LD   HL, notinyfont
                    CALL_OZ GN_Sop

                    LD   A,B
                    ADD  A,9            ; (X+9,Y)
                    LD   B,A
                    CALL VduCursor      ; set VDU cursor for slot number (bottom right edge)
                    LD   A,32
                    CALL_OZ OS_Out
                    LD   A,(curslot)
                    ADD  A,48           ; -> Ascii slot number
                    CALL_OZ OS_Out
                    LD   A,32
                    CALL_OZ OS_Out

                    POP  AF
                    PUSH AF
                    BIT  2,A
                    JR   Z, exit_DrawCardBox
                    LD   A,B
                    SUB  A,7            ; (X+2,Y)
                    LD   B,A
                    CALL VduCursor
                    LD   HL, padlock
                    CALL_OZ GN_Sop
.exit_DrawCardBox
                    POP  AF
                    POP  HL
                    POP  BC
                    RET
; BC = X,Y
.DrawCardSides      PUSH BC
                    CALL VduCursor      ; set VDU Cursor at (X,Y)
                    LD   HL, cardside
                    PUSH HL
                    CALL_OZ GN_Sop      ; draw left side
                    LD   A,B
                    ADD  A,13
                    LD   B,A
                    CALL VduCursor      ; set VDU Cursor at (X+13,Y)
                    POP  HL
                    CALL_OZ GN_Sop      ; draw right side
                    POP  BC
                    RET
; *************************************************************************************


; *************************************************************************************
; BC = X,Y
.VduCursor          PUSH AF
                    PUSH HL
                    LD   HL, xypos
                    CALL_OZ GN_Sop
                    LD   A,B            ; X
                    ADD  A,32
                    CALL_OZ OS_Out
                    LD   A,C            ; Y
                    ADD  A,32
                    CALL_OZ OS_Out
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; Return VDU Card Box (X,Y) coordinate for slot X (1-3)
;
; OUT:
;    BC = (X,Y)
;
.SlotCardBoxCoord
                    PUSH AF
                    PUSH HL
                    LD   A,(curslot)
                    DEC  A              ; first card box displayed at (0,0)
                    LD   B,A            ; X coord multiply counter
                    JR   Z, cardbox_x_coord
.get_x_coord        ADD  A,13
                    DJNZ get_x_coord
.cardbox_x_coord    LD   B,A
                    LD   C,0
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; Text constants

.selslot_banner     DEFM "SELECT FILE AREA",0
.noflash_msg        DEFM 1,"BNo Flash Cards found in slots 1-3.",1,"B",0

.xypos              DEFM 1,"3@",0

.cardtop            defm 1, "2*C", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E" ; Top left corner
                    defm 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*F" ; Top right corner
                    defb 0
.cardmiddle         defm 1, "2*K", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E" ; Left T-section
                    defm 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*N" ; Rigth T-section
                    defb 0
.cardbottom         defm 1, "2*I", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E" ; Bottom left corner
                    defm 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*E", 1, "2*L" ; Bottom right corner
                    defb 0
.cardside           DEFM 1, "2*J", 0

.padlock            DEFM 1, 138, '=', 'A'
                    DEFM @10001100
                    DEFM @10010010
                    DEFM @10010010
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10011110
                    DEFM " ", 1, "2?A", " ", 0

.selectdevhelp      DEFM 1,"2JC", 1,"3-SC"
                    DEFM "Select device", 13, 10
                    DEFM "with either", 13, 10
                    DEFM 1,"B1", 1 ,"B ", 1, "B2", 1,"B or ", 1,"B3", 1, "B", 13, 10
                    DEFM "or", 13, 10
                    DEFM "move cursor", 13, 10
                    DEFM "over the device", 13, 10
                    DEFM 13, 10
                    DEFM 1, SD_ENT, " selects it", 0

.epromtxt           DEFM 1,"2+T", "EPROM", 0
.flashtxt           DEFM 1,"2+T", "FLASH", 0
.cardtxt            DEFM "CARD", 0
.eprdev             DEFM "FILES", 0
.ramdev             DEFM 1,"2+T", "RAM ",0
.romdev             DEFM 1,"2+T", "APPLICATIONS",0
.slottxt1           DEFM "SLOT ",0
.slottxt2           DEFM ": ",0
.emptytxt           DEFM 1,"2+T", "EMPTY SLOT", 1,"2-T", 0
.selvdu             DEFM 1,"3-SC"               ; no vertical scrolling, no cursor
                    DEFM 1,"2+T",0

.sizeK              DEFM "K ",1, "2X", 32+14, 0   ; display "K" (for Kilobyte), then prepare for next text..

.SelectMenuWindow
                    DEFM 1,"2H1",1,"2-C",0     ; activate menu window, no Cursor...
.MenuBarOn          DEFM 1,"2+R"               ; set reverse video
                    DEFM 1,"2A",32+22,0        ; XOR 'display' menu bar (22 chars wide)
.MenuBarOff         DEFM 1,"2-R"               ; set reverse video
                    DEFM 1,"2A",32+22,0        ; apply 'display' menu bar (22 chars wide)

                    defm 1, "3@", 32+9, 32+6, 1, "4+F+R",  " 1 ", 1, "4-F-R"
                    defm 1, "3@", 32+14+9, 32+6, " 2 "
                    defm 1, "3@", 32+14*2+9, 32+6, " 3 "
                    defb 0
