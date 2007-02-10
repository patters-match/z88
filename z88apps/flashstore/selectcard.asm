; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2006
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

Module SelectCard

; This module contains functionality that displays the card / file area selection pop-up
; window and cursor movement

     XDEF SelectFileArea, SelectCardCommand, SelectDefaultSlot, PollSlots, VduCursor
     XDEF selslot_banner, epromdev, DispSlotSize, DispHelpText

     lib CreateWindow              ; Create an OZ window (with options banner, title, etc)
     lib RamDevFreeSpace           ; Get free space on RAM device
     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFreeSpace          ; Return amount of deleted file space (in bytes)
     lib ApplEprType               ; check for presence of application card in slot
     lib FlashEprCardId            ; Return Intel Flash Eprom Device Code (if card available)

     XREF DispCmdWindow,pwait, rdch     ; fsapp.asm
     XREF greyscr, greyfont, nocursor   ; fsapp.asm
     XREF nogreyfont, notinyfont        ; fsapp.asm
     xref GetCurrentSlot, DispMainWindow; fsapp.asm
     XREF PollFileFormatSlots           ; format.asm
     XREF FlashWriteSupport             ; format.asm
     XREF execute_format, noformat_msg  ; format.asm
     XREF CheckFlashCardID              ; format.asm
     XREF FileEpromStatistics           ; filestat.asm
     XREF m16, ksize_txt, intAscii      ; filestat.asm
     XREF PollFileCardWatermark         ; browse.asm
     XREF FilesAvailable,DispFilesWindow ; browse.asm
     XREF InitFirstFileBar              ; browse.asm
     XREF DispErrMsg, DispIntelSlotErr  ; errmsg.asm

     include "stdio.def"
     include "integer.def"
     include "fsapp.def"
     include "flashepr.def"


; *************************************************************************************
;
; Display slot selection window to choose another Flash Card Device
;
.SelectCardCommand
                    CALL greyscr
                    call GetCurrentSlot           ; C = (curslot)
                    call PollSlots
                    or   a                        ; if no file areas were found, then
                    call z,PollFileFormatSlots    ; investigate slots 1-3 for Flash Cards that can be formatted
                    or   a
                    jr   nz,continue_selcard
                         ld   hl,selslot_banner
                         call DispMainWindow
                         LD   HL, noformat_msg    ; no file areas, nor flash cards available!
                         CALL DispErrMsg
                         ret
.continue_selcard
                    push bc
                    ld   hl, selslot_banner
                    call SelectFileArea           ; user selects a File Eprom Area in one of the external slots
                    pop  bc
                    jp   c, user_aborted
                    jr   nz, user_aborted

                    call FilesAvailable
                    ret  nc                       ; file area found, let user select it...
                    call GetCurrentSlot           ; C = (curslot)
                    call FlashWriteSupport        ; is this an empty flash card with write/format support?
                    ret  c                        ; no flash write/format support for this slot.
                    jp   execute_format           ; prompt the user to format the flash card.
.user_aborted
                    ld   a,c
                    ld   (curslot),a              ; user aborted selection, restore original slot...
                    ret
; *************************************************************************************


; *************************************************************************************
; Display the contents of slots 0-3 in an easy understandable symbolically form.
;
; IN: HL = Window Banner Title
;
.SelectFileArea
                    LD   A,(curslot)
                    LD   (dstslot),A         ; remember current slot selection
                    CALL greyscr

                    push hl
                    ld   hl, selectdevhelp
                    Call DispHelpText        ; display help text window

                    ld   a, 128 | '2'
                    ld   bc, $0010
                    ld   de, $0838
                    pop  hl
                    call CreateWindow        ; Device selection window.

                    ld   a,3                 ; begin from slot 3...
.disp_slot_loop
                    ld   (curslot),a

                    ld   hl,buffer
                    ld   (vdubufptr),hl      ; use 16K buffer for temporary VDU sequence caching

                    ld   c,a
                    call FlashWriteSupport
                    jp   z, flashcard_detected
.poll_for_ram_card
                    call RamDevFreeSpace
                    jr   c, poll_for_rom_card
                         LD   (free),A       ; A = size of RAM card in 16K banks, DE = free 256 byte pages
                         LD   HL,ramdev
                         LD   A,1            ; display RAM card box outline in grey (to identify it as non-selectable)
                         CALL DisplayCard
                         dec  c
                         inc  b
                         inc  b
                         CALL CacheVduCursor
                         EX   DE,HL          ; HL = free 256 bytes pages on RAM Card
                         LD   DE,4           ; HL / 4 = free space in K
                         CALL_OZ(GN_D16)
                         EX   DE,HL
                         LD   HL, freetxt
                         CALL CacheVduString
                         CALL CachedDispKSize     ; display free space in DE
                         LD   HL, ksize_txt
                         CALL CacheVduString
                         jp   nextline
.poll_for_rom_card
                    ld   h,c                      ; preserve a copy of slot number...
                    call ApplEprType
                    jr   c, poll_for_eprom_card
                         ld   hl, epromdev
                         ld   (free),bc           ; C = size of physical card
                         ld   a,4                 ; display PadLock (FlashStore does not support write to Eprom)
                         call DisplayCard         ; display size of card as defined by ROM header
                         dec  c
                         inc  b
                         inc  b
                         CALL CacheVduCursor
                         ld   hl, appstxt
                         CALL CacheVduString
                         inc  b
                         CALL CacheVduCursor
                         push bc
                         call GetCurrentSlot      ; C = (curslot)
                         call FileEprRequest
                         ld   a,c
                         pop  bc
                         jr   c, eprom_nofiles    ; the Eprom Application Card had no file area...
                         jr   nz, eprom_nofiles
                         ld   hl, freetxt
                         CALL CacheVduString      ; display size of sub file area in K on Eprom
                         call DispFreeSpace
                         jp   nextline
.eprom_nofiles
                         ld   hl, nofilestxt
                         CALL CacheVduString
                         jp   nextline
.poll_for_eprom_card
                    ld   c,h                      ; poll slot C...
                    call FileEprRequest
                    jr   c, empty_slot
                    jr   nz, empty_slot
                         ld   hl, epromdev        ; C = size of File Area in 16K banks (if Fz = 1)
                         ld   a,d                 ; D = size of card in 16K banks
                         ld   (free),a
                         ld   a,4                 ; display PadLock (FlashStore does not support write to Eprom)
                         call DisplayCard         ; display size of card as defined by ROM header
                         dec  c
                         inc  b
                         inc  b
                         CALL CacheVduCursor
                         ld   hl, freetxt        ; display "Files xxxxK"
                         CALL CacheVduString
                         ld   a,(free)
                         call DispFreeSpace
                         jp   nextline
.empty_slot
                    CALL SlotCardBoxCoord         ; the slot is empty (or contains an empty Eprom Card)
                    LD   A, @00000011             ; draw a grey outline box
                    CALL DrawCardBox
                    LD   A,C
                    ADD  A,2
                    LD   C,A
                    LD   A,B
                    ADD  A,3
                    LD   B,A
                    CALL CacheVduCursor
                    ld   hl, emptytxt             ; and write "empty slot" in the middle of the grey box
                    CALL CacheVduString
                    jr   nextline
.flashcard_detected
                    ld   a,b
                    ld   (free),a                 ; size of Flash Card in 16K banks
                    ld   a,8                      ; display flash label
                    jr   nc, flash_writeable
                    set  2,a                      ; Intel flash in slot 1 or 2 (display padlock)
.flash_writeable
                    ex   af,af'
                    ld   de, amdlogo
                    ld   hl, flashid+1            ; get manufacturer ID of current flash card
                    ld   a,(hl)
                    cp   FE_INTEL_MFCD
                    ld   hl, flashdev
                    jr   nz, dispc                ; flash card ID was Amd
                    ld   de, intellogo            ; flash card ID was Intel
.dispc
                    ex   af,af'
                    call DisplayCard
                    dec  c
                    inc  b
                    inc  b                        ; prepare for "applications" text
                    push bc
                    call GetCurrentSlot           ; C = (curslot)
                    call ApplEprType
                    ld   a,c
                    pop  bc
                    jr   c, flash_noapps
                         CALL CacheVduCursor
                         ld   hl, appstxt
                         CALL CacheVduString
                         inc  b                   ; prepare for "files " text
.flash_noapps
                    CALL CacheVduCursor
                    push bc
                    call GetCurrentSlot           ; C = (curslot)
                    call FileEprRequest
                    ld   a,c
                    pop  bc
                    jr   c, flash_nofiles
                    jr   nz, flash_nofiles
                         ld   hl, freetxt
                         CALL CacheVduString
                         call DispFreeSpace
                         jr   nextline
.flash_nofiles
                         ld   hl, nofilestxt
                         CALL CacheVduString
.nextline
                    ld   hl, buffer
                    call_oz(Gn_Sop)              ; display cached VDU sequences (the current card box)

                    ld   a,(curslot)
                    dec  a
                    cp   $ff
                    jp   nz, disp_slot_loop

                    ; Now, user selects card (if possible) ...
                    ld   c,-1
                    CALL SelectDefaultSlot        ; preset menu bar at first available card file area
                    ld   (curslot),a
.select_slot_loop
                    call UserMenu
                    jr   c, abort_selection       ; user aborted selection
                    ld   hl, availslots+1
                    ld   b,0
                    call GetCurrentSlot           ; C = (curslot)
                    add  hl,bc
                    xor  a
                    cp   (hl)
                    jr   z, check_empty_flcard    ; user selected apparently void or illegal slot
                    call InitFirstFileBar         ; initialize File Bar cursor for new slot..
                    call PollFileCardWatermark    ; auto-poll watermark in file header for selected slot
                    cp   a                        ; indicate slot was successfully selected
                    ret
.abort_selection
                    ld   a,(dstslot)
                    ld   (curslot),a              ; restore previous slot selection...
                    ret

.check_empty_flcard
                    call FlashWriteSupport
                    jr   nz, select_slot_loop     ; no Flash Card in slot...
                    jp   nc, execute_format       ; empty flash card in slot (no file area, and erase/write support)

                    CALL DispCmdWindow
                    CALL DispMainWindow
                    CALL FileEpromStatistics
                    call DispIntelSlotErr         ; Intel Flash Card found in slot, but no erase/write support in slot
                    cp   a
                    ret
; *************************************************************************************


; *************************************************************************************
; IN
;    A = box draw args (padlock etc)
;    HL = label ("FLASH", "EPROM", "RAM")
;    DE = pointer to Flash Card label (if A.3 is set)
;    (free) = size of card in 16K banks
; OUT
;    BC = (Y,X) of start of displayed label
.DisplayCard
                    CALL SlotCardBoxCoord
                    CALL DrawCardBox
                    INC  B                      ; Y++
                    INC  C
                    INC  C
                    CALL CacheVduCursor
                    CALL CacheVduString         ; display device name (in HL)...
                    LD   A,(free)               ; A = size of slot in 16K banks
.DispSlotSize
                    push bc
                    push de
                    push hl

                    LD   H,0
                    LD   L,A
                    CALL m16
                    EX   DE,HL                  ; size in DE...
                    CALL CachedDispKSize
                    ld   a,'K'
                    CALL CacheVduChar

                    pop  hl
                    pop  de
                    pop  bc
                    ret
.DispFreeSpace
                    push bc
                    push hl
                    call GetCurrentSlot         ; C = (curslot)
                    call FileEprFreeSpace
                    push bc
                    pop  hl
                    ld   b,e                    ; DEBC -> BHL
                    ld   c,0
                    ld   de,1024                ; BHL / 1024
                    CALL_OZ(Gn_D24)
                    ex   de,hl
                    inc  de
                    call CachedDispKSize        ; no. of K free
                    ld   a, 'K'
                    CALL CacheVduChar
                    pop  hl
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
;
.UserMenu
.menu_loop     CALL ShowMenuBar
               CALL rdch
               CALL RemoveMenuBar
               LD   HL, curslot
               CP   IN_ESC                        ; ESC?
               JR   Z, abort_select
               CP   IN_ENT                        ; ENTER?
               RET  Z
               CP   IN_RGT                        ; Cursor Right ?
               JR   Z, MVbar_right
               CP   IN_LFT                        ; Cursor Left ?
               JR   Z, MVbar_left
               CP   '0'
               JR   C,menu_loop                   ; smaller than '0'
               CP   '4'
               JR   NC,menu_loop                  ; >= '4'
               SUB  A,48                          ; ['0'; '3'] keys selected
               LD   (HL),A
               CP   A
               RET
.abort_select
               SCF
               RET
.MVbar_right   LD   A,(HL)
               CP   3                             ; has m.bar already reached right edge?
               JR   Z,Mbar_rightwrap
               INC  A
               LD   (HL),A                        ; update new m.bar position
               JR   menu_loop                     ; display new m.bar position
.Mbar_rightwrap
               LD   (HL),0
               JR   menu_loop
.MVbar_left
               LD   A,(HL)
               CP   0                             ; has m.bar already reached left edge?
               JR   Z,Mbar_leftwrap
               DEC  A
               LD   (HL),A                        ; update new m.bar position
               JR   menu_loop
.Mbar_leftwrap
               LD   (HL),3
               JR   menu_loop
; *************************************************************************************


; *************************************************************************************
; HL = MenuBar ON/OFF VDU
;
.DisplMenuBar  PUSH AF
               PUSH BC
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               CALL SlotCardBoxCoord
               LD   A,C
               ADD  A,9
               LD   C,A                           ; display menu bar at (Y,6) of card box
               LD   A,B
               ADD  A,6                           ; display menu bar at bottom line of card box
               LD   B,A
               CALL VduCursor
               POP  HL                            ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  BC
               POP  AF
               RET
; *************************************************************************************


; *************************************************************************************
;
.ShowMenuBar
               LD   HL,MenuBarOn
               JR   DisplMenuBar
; *************************************************************************************


; *************************************************************************************
;
.RemoveMenuBar
               LD   HL,MenuBarOff
               JR   DisplMenuBar
; *************************************************************************************


; *************************************************************************************
; Poll all slots (0 - 3) for file areas and return A = count of found file areas,
; or 0 if none were found.
;
.PollSlots
                    push bc
                    push de
                    push hl

                    ld   hl, availslots+1    ; point to slot 0
                    push hl
                    ld   c,0                 ; begin with internal slot 0, then external 1-3
                    ld   e,0                 ; counter of available file eproms
.poll_loop
                    push bc                  ; preserve slot number...
                    call FileEprRequest      ; File Eprom Card or area available in slot C?
                    ld   a,c
                    pop  bc
                    jr   c, no_fileepr
                    jr   nz, no_fileepr      ; no header was found, but a card was available of some sort
                         inc  e              ; File Eprom found
                         pop  hl
                         ld   (hl),a         ; size of file eprom in 16K banks
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
                    cp   a                   ; Fc = 0, A = no. of found file cards...
                    ret
; *************************************************************************************


; *************************************************************************************
; IN:
;    C = -1 (FFh) select first found slot containing a file area
;    C = X (0-3) select first found slot containing a file area that is not X.
;
; OUT:
;    Fc = 0, A = found slot number
;    Fc = 1, no slot was pre-selected
;
.SelectDefaultSlot                              ; select the first available Card File Area
                    push de
                    ld   e,3
                    ld   hl, availslots+4       ; beginning from slot 3, towards slot 1...
                    ld   b,4
.sel_slot_loop
                    xor  a
                    cp   (hl)
                    jr   nz, found_slot
.get_next_defslot
                    dec  hl
                    dec  e
                    djnz sel_slot_loop
                    scf
                    pop  de
                    ret
.found_slot
                    ld   a,c
                    cp   e
                    jr   z, get_next_defslot    ; the found slot is to be avoided...
.set_defaultslot
                    ld   a,e                    ; return this slot as default...
                    cp   a
                    pop  de
                    ret
; *************************************************************************************


; *************************************************************************************
; Draw a minimalistic Z88 Card outline using VDU Box characters.
;
; IN:
;     A = BIT 0: draw card box in grey colour
;     A = BIT 1: draw only outline (not the card label line)
;     A = BIT 2: draw Padlock on left bottom edge.
;     A = BIT 3: draw 'AMD' or 'INTEL' label on left top edge.
;     BC = (Y,X)
;     DE = pointer to Flash Card label ('AMD' or 'INTEL')
;
.DrawCardBox
                    PUSH BC
                    PUSH HL
                    PUSH AF

                    BIT  0,A
                    JR   Z, use_nocursor
                    LD   HL, greyfont           ; draw the card box in grey colour.
                    CALL CacheVduString
.use_nocursor
                    LD   HL, nocursor
                    CALL CacheVduString

                    CALL CacheVduCursor        ; set VDU Cursor at (Y,X)
                    LD   HL,cardtop             ; draw top edge of card box
                    CALL CacheVduString

                    POP  AF
                    PUSH AF
                    BIT  3,A                    ; display Flash card label?
                    JR   Z, draw_sides
                    INC  C
                    INC  C
                    CALL CacheVduCursor        ; set VDU Cursor at (Y,X+1)
                    EX   DE,HL
                    CALL CacheVduString
                    DEC  C
                    DEC  C
.draw_sides
                    INC  B                      ; Y++
                    CALL DrawCardSides
                    INC  B                      ; Y++
                    CALL CacheVduCursor        ; set VDU Cursor at (Y,X)
                    POP  AF
                    PUSH AF
                    BIT  1,A
                    JR   Z, draw_middleline
                    CALL DrawCardSides
                    JR   next_cardside
.draw_middleline
                    LD   HL,cardmiddle          ; draw middle line of card box
                    CALL CacheVduString
.next_cardside
                    INC  B                      ; Y++
                    CALL DrawCardSides
                    INC  B                      ; Y++
                    CALL DrawCardSides
                    INC  B                      ; Y++
                    CALL DrawCardSides
                    INC  B                      ; Y++
                    CALL CacheVduCursor        ; set VDU Cursor at (Y,X)
                    LD   HL,cardbottom          ; draw bottom edge of card box
                    CALL CacheVduString

                    LD   HL, nogreyfont
                    CALL CacheVduString
                    LD   HL, notinyfont
                    CALL CacheVduString

                    LD   A,C
                    ADD  A,9                    ; (Y,X+9)
                    LD   C,A
                    CALL CacheVduCursor        ; set VDU cursor for slot number (bottom right edge)
                    LD   A,32
                    CALL CacheVduChar
                    LD   A,(curslot)
                    ADD  A,48                   ; -> Ascii slot number
                    CALL CacheVduChar
                    LD   A,32
                    CALL CacheVduChar

                    POP  AF
                    PUSH AF
                    BIT  2,A
                    JR   Z, exit_DrawCardBox

                    LD   A,C
                    SUB  A,7                    ; (Y,X+7)
                    LD   C,A
                    CALL CacheVduCursor
                    LD   HL, padlock
                    CALL CacheVduString
.exit_DrawCardBox
                    POP  AF
                    POP  HL
                    POP  BC
                    RET
; BC = Y,X
.DrawCardSides      PUSH BC
                    CALL CacheVduCursor        ; set VDU Cursor at (Y,X)
                    LD   HL, cardside
                    PUSH HL
                    CALL CacheVduString         ; draw left side
                    LD   A,C
                    ADD  A,13
                    LD   C,A
                    CALL CacheVduCursor        ; set VDU Cursor at (Y,X+13)
                    POP  HL
                    CALL CacheVduString         ; draw right side
                    POP  BC
                    RET
; *************************************************************************************


; *************************************************************************************
; Place window cursor at (Y,X)
; B = Y window coordinate, C = X window Coordinate
.VduCursor          PUSH AF
                    PUSH HL

                    LD   HL,$1800       ; temp buffer at bottom of system stack
                    LD   (vdubufptr),HL
                    CALL CacheVduCursor
                    CALL_OZ GN_Sop      ; execute VDU

                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; Place window cursor at (Y,X)
; B = Y window coordinate, C = X window Coordinate
.CacheVduCursor     PUSH AF
                    PUSH HL

                    LD   HL, xypos
                    CALL CacheVduString
                    LD   A,C            ; X
                    ADD  A,32
                    CALL CacheVduChar
                    LD   A,B            ; Y
                    ADD  A,32
                    CALL CacheVduChar

                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
.CachedDispKSize    LD   B,D
                    LD   C,E
                    LD   HL,2
                    CALL IntAscii
                    CALL CacheVduString
                    RET
; *************************************************************************************


; *************************************************************************************
; Cache VDU sequence in buffer pointed to by (vdubufptr)
;
; IN:
;       HL = local pointer to null-terminated VDU sequence
; OUT:
;       HL points at null-terminator of string
;
.CacheVduString
                   PUSH AF
                   PUSH DE

                   LD   DE,(vdubufptr)
.cache_loop
                   LD   A,(HL)
                   LD   (DE),A
                   OR   A
                   JR   Z, exit_CacheVdu
                   INC  DE
                   INC  HL
                   JR   cache_loop
.exit_CacheVdu
                   LD   (vdubufptr),DE  ; updated VDU Cache pointer
                   POP  DE
                   POP  AF
                   RET
; *************************************************************************************


; *************************************************************************************
; Cache VDU character in buffer pointed to by (vdubufptr)
;
; IN:
;       A = char
; OUT:
;
.CacheVduChar
                   PUSH AF
                   PUSH DE

                   LD   DE,(vdubufptr)
                   LD   (DE),A
                   INC  DE
                   XOR  A
                   LD   (DE),A          ; null-terminate by default
                   LD   (vdubufptr),DE  ; updated VDU Cache pointer

                   POP  DE
                   POP  AF
                   RET
; *************************************************************************************


; *************************************************************************************
; Return VDU Card Box (0,X) coordinate for slot X (0-3) fetched in (curslot)
;
; OUT:
;    BC = (Y,X)
;
.SlotCardBoxCoord
                    PUSH AF
                    PUSH HL
                    LD   A,(curslot)
                    LD   B,A            ; X coord multiply counter
                    OR   A              ; first card box displayed at (0,0)
                    JR   Z, cardbox_x_coord
.get_x_coord        ADD  A,13
                    DJNZ get_x_coord
.cardbox_x_coord    LD   C,A
                    LD   B,0
                    POP  HL
                    POP  AF
                    RET
; *************************************************************************************


; *************************************************************************************
; Create help window in right side of screen and display help text string by HL
;
.DispHelpText
                    push hl
                    ld   a, 64 | '3'
                    ld   bc,$004B
                    ld   de,$0812
                    call CreateWindow
                    pop  hl
                    call_oz GN_Sop           ; Display small help text in right side window
                    ret
; *************************************************************************************


; *************************************************************************************
; Text constants

.selslot_banner     DEFM "SELECT FILE CARD AREA",0
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

.amdlogo            DEFB 1, 138, '=', 'J'
                    DEFB @10000000
                    DEFB @10011111
                    DEFB @10011001
                    DEFB @10010110
                    DEFB @10010000
                    DEFB @10010110
                    DEFB @10011111
                    DEFB @10000000
                    DEFM 1, "2?J"
                    DEFB 1, 138, '=', 'K'
                    DEFB @10000000
                    DEFB @10111111
                    DEFB @10100100
                    DEFB @10101010
                    DEFB @10101110
                    DEFB @10101110
                    DEFB @10111111
                    DEFB @10000000
                    DEFM 1, "2?K"
                    DEFB 1, 138, '=', 'L'
                    DEFB @10000000
                    DEFB @10111111
                    DEFB @10100011
                    DEFB @10101101
                    DEFB @10101101
                    DEFB @10100011
                    DEFB @10111111
                    DEFB @10000000
                    DEFM 1, "2?L"
                    DEFB 1, 138, '=', 'M'
                    DEFB @10000000
                    DEFB @10000000
                    DEFB @10000000
                    DEFB @10011111
                    DEFB @10000000
                    DEFB @10000000
                    DEFB @10000000
                    DEFB @10000000
                    DEFM 1, "2?M", 0

.intellogo          DEFB 1, 138, '=', 'N'
                    DEFB @10000000
                    DEFB @10011111
                    DEFB @10010001
                    DEFB @10011011
                    DEFB @10011011
                    DEFB @10010001
                    DEFB @10011111
                    DEFB @10000000
                    DEFM 1, "2?N"
                    DEFB 1, 138, '=', 'O'
                    DEFB @10000000
                    DEFB @10111111
                    DEFB @10011010
                    DEFB @10001011
                    DEFB @10010011
                    DEFB @10011011
                    DEFB @10111111
                    DEFB @10000000
                    DEFM 1, "2?O"
                    DEFB 1, 138, '=', 'P'
                    DEFB @10000000
                    DEFB @10111111
                    DEFB @10001000
                    DEFB @10011011
                    DEFB @10011011
                    DEFB @10011000
                    DEFB @10111111
                    DEFB @10000000
                    DEFM 1, "2?P"
                    DEFB 1, 138, '=', 'Q'
                    DEFB @10000000
                    DEFB @10111110
                    DEFB @10101110
                    DEFB @10101110
                    DEFB @10101110
                    DEFB @10100010
                    DEFB @10111110
                    DEFB @10000000
                    DEFM 1, "2?Q", 0

.padlock            DEFM 1, 138, '=', 'Z'
                    DEFM @10001100
                    DEFM @10010010
                    DEFM @10010010
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10111111
                    DEFM @10011110
                    DEFM " ", 1, "2?Z", " ", 0

.selectdevhelp      DEFM 1,"2JC", 1,"3-SC"
                    DEFM "Select card with", 13, 10
                    DEFM 1,"B0 - 3", 1,"B", 13, 10
                    DEFM 13, 10
                    DEFM "or move cursor", 13, 10
                    DEFM "over card", 13, 10
                    DEFM 13, 10
                    DEFM 1, SD_ENT, " to select", 0

.epromdev           DEFM 1,"2+T", "EPROM ", 0
.flashdev           DEFM 1,"2+T", "FLASH ", 0
.ramdev             DEFM 1,"2+T", "RAM ",0
.freetxt            DEFM 1,"2+T", " FREE ", 0
.appstxt            DEFM 1,"2+T", "APPLICATIONS",0
.nofilestxt         DEFM 1,"2+T", "NO FILE AREA",0
.slottxt1           DEFM "SLOT ",0
.slottxt2           DEFM ": ",0
.emptytxt           DEFM 1,"2+T", "EMPTY SLOT", 1,"2-T", 0
.selvdu             DEFM 1,"3-SC"               ; no vertical scrolling, no cursor
                    DEFM 1,"2+T",0

.SelectMenuWindow
                    DEFM 1,"2H2",1,"2-C",0     ; activate menu window, no Cursor...
.MenuBarOn          DEFM 1,"4+F+R"             ; enable flash and inverse video
                    DEFM 1,"2A",32+3,0         ; XOR 'display' menu bar (3 chars wide)
.MenuBarOff         DEFM 1,"4-F-R"             ; disable flash & set normal video
                    DEFM 1,"2A",32+3,0         ; apply 'display' menu bar (3 chars wide)
