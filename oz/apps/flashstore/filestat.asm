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

Module FileAreaStatistics

; This module displays the File Area Statistics (right hand side window in main menu mode)

     XDEF FileEpromStatistics, m16, IntAscii, DispKSize
     XDEF ksize_txt

     lib CreateWindow              ; Create an OZ window (with options banner, title, etc)
     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
     lib FileEprTotalSpace         ; Return amount of active and deleted file space (in bytes)
     lib FileEprCntFiles           ; Return total of active and deleted files
     lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
     lib FileEprFreeSpace          ; Return amount of deleted file space (in bytes)
     lib FlashEprCardData          ; Return data about Flash type & size & description
     lib divu8                     ; Unsigned 8bit integer division

     XREF VduCursor                ; selectcard.asm
     XREF DispSlotSize, epromdev   ; selectcard.asm
     XREF centerjustify, tinyfont  ; fsapp.asm
     XREF nocursor, sopnln         ; fsapp.asm
     xref GetCurrentSlot           ; fsapp.asm
     XREF CheckFlashCardID         ; format.asm
     XREF FilesAvailable           ; browse.asm
     XREF DispInt                  ; fetchfile.asm

     ; flash card library definitions
     include "flashepr.def"

     ; system definitions
     include "stdio.def"
     include "fileio.def"
     include "integer.def"
     include "screen.def"
     include "memory.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; ****************************************************************************
; Initialize file statistics window
;
.InitWindow
                    push af
                    push bc
                    push de
                    push hl

                    ld   a,'3' | 128
                    ld   bc,$004A
                    ld   de,$0812
                    ld   hl, buf1
                    call CreateWindow

                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret
; ****************************************************************************


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
                    ld   bc,9
                    ld   hl, slot_bnr
                    ld   de, buf1
                    ldir
                    ld   a,(curslot)
                    add  a,48
                    ld   (de),a
                    ld   hl,buf1+3
                    cp   '1'
                    jr   nz, check_slot3
                    ld   (hl),'N'                 ; display "slot 1" left aligned..
.check_slot3        cp   '3'
                    jr   nz, slot2_selected
                    ld   (hl),'R'                 ; display "slot 3" right aligned..
.slot2_selected                                   ; display "slot 2" center aligned..
                    inc  de
                    xor  a
                    ld   (de),a                   ; null-terminate banner

                    call GetCurrentSlot           ; C = (curslot)
                    push bc
                    call FileEprRequest
                    jr   z, cont_statistics
                         pop  bc

                         call InitWindow
                         ld   hl, nofepr_msg
                         call_oz (Gn_Sop)
                         ret
.cont_statistics
                    call FilesAvailable           ; update file count on current File Eprom
                                                  ; (file) = active files, (fdel) = deleted files
.getfreesp
                    pop  bc                       ; c = slot number...
                    push bc
                    call FileEprFreeSpace         ; get free space on current File Eprom
                    ld   (free),bc
                    ld   (free+2),de
                    pop  bc
                    call FileEprTotalSpace        ; get total used space on current File Eprom (active & deleted)
                    ld   (active),hl
                    ld   a,b
                    ld   (active+2),a             ; remember total active file space
                    ld   (deleted),de
                    ld   a,c
                    ld   (deleted+2),a            ; remember total deleted file space
                    add  hl,de
                    ld   a,b
                    adc  a,c
                    ld   b,0
                    ld   c,a
                    ld   (total),hl
                    ld   (total+2),bc             ; remember total used space (active+deleted)

                    call InitWindow
                    ld   hl,centerjustify
                    CALL_OZ gn_sop                ; centre justify...

                    ld   hl,tinyfont
                    CALL_OZ gn_sop

                    call GetCurrentSlot           ; C = (curslot)
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
                    CALL sopnln
.disp_eprsize
                    CALL DisplayEpromSize

                    ld   hl,tinyfont
                    CALL_OZ gn_sop

                    ld   bc,$0301                 ; VDU (X,Y) = (3,1)
                    CALL VduCursor
                    ld   a,(free+2)
                    ld   b,a
                    ld   hl,(free)
                    call DispInt
                    CALL_OZ gn_sop
                    ld   hl,bfre_msg
                    call sopnln                   ; "xxxx free"

                    ld   hl,(file)
                    ld   de,(fdel)
                    adc  hl,de
                    jr   z, disp_freespbar        ; just display the free space bar on an empty file area

                    ld   a,(total+2)
                    ld   b,a
                    ld   hl,(total)
                    call DispInt
                    CALL_OZ gn_sop
                    ld   hl,bused_msg
                    call sopnln                   ; "xxxx used"

                    ld   bc,(file)
                    ld   hl,2
                    call IntAscii                 ; convert 16bit integer in BC to Ascii...
                    CALL_OZ gn_sop
                    ld   hl,fisa_msg
                    call sopnln

                    ld   bc,(fdel)
                    ld   hl,2
                    call IntAscii                 ; convert 16bit integer in BC to Ascii...
                    CALL_OZ gn_sop
                    ld   hl,fdel_msg
                    CALL_OZ gn_sop
.disp_freespbar
                    CALL DispFreeSpaceBar

                    ld   hl, nocursor
                    CALL_OZ  GN_Sop
                    ret
; *************************************************************************************


; *************************************************************************************
;
.DisplayEpromSize
                    LD   BC, $0101
                    CALL VduCursor           ; VDU Cursor at (1,1)

                    call GetCurrentSlot      ; C = (curslot)
                    CALL FileEprRequest
                    ld   a,c
                    ld   (bytesperline),a    ; remember size of file area in 16K banks

                    LD   H,0
                    LD   L,C                 ; C = total of banks as defined by File Eprom Header
                    CALL m16
                    EX   DE,HL               ; size in DE...

                    LD   A,B
                    AND  @00111111           ; get relative top bank number...
                    CP   $3F                 ; is header located in top bank?
                    JR   Z, true_size        ; Yes - real File Eprom found...

                    LD   HL, tinyfont
                    CALL_OZ(Gn_Sop)
                    CALL DispKSize
                    LD   HL, ksize_txt
                    CALL_OZ(Gn_sop)
                    LD   HL,fepr
                    CALL_OZ(Gn_Sop)
                    RET

.true_size          LD   HL, tinyfont
                    CALL_OZ(Gn_Sop)
                    CALL DispKSize
                    LD   HL, ksize_txt
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

                    CALL FlashEprCardData
                    EX   DE,HL                    ; HL = chip description text
                    RET
; *************************************************************************************


; *************************************************************************************
; Display the graphical free space bar containing a graphical presentation of
; of how deleted space, used space and free space is available
.DispFreeSpaceBar
                    ld   a,SC_LR0
                    ld   b,0
                    CALL_OZ OS_SCI                ; get pointer in BHL to LORES0 (UDG 6x8 pixel font table)

                    ld   a,FA_EOF
                    ld   ix, -1                   ; get Z88 machine state (standard or expanded)
                    ld   de,0
                    call_oz OS_Frm                ; return Fz = 1, if Z88 is expanded
                    jr   z, exp_z88
                    ld   de,14*8                  ; point at 'Q' UDG in LORES0 when Z88 is unexpanded
                    jr   spacebarbase
.exp_z88            ld   de,46*8                  ; point at 'Q' UDG in LORES0 when Z88 is expanded
.spacebarbase
                    add  hl,de
                    res  7,h
                    set  6,h                      ; modify offset pointer to use segment 1.
                    ld   (FreeSpaceBar),hl        ; HL is base pointer at first UDG character, 'Q'

                    ld   c,MS_S1
                    rst  OZ_MPB                   ; bind LORES font memory into segment 1 ($4000-$7FFF)
                    push bc                       ; preserve old bank binding

                    call ResetFreeSpaceBar        ; Initialize (reset) the horisontal bar
                    call FillFreeSpaceBar         ; fill bar with information about deleted and active file space

                    pop  bc
                    rst  OZ_MPB                   ; restore old bank binding in segment 1.

                    ld   hl, spacebar
                    CALL_OZ GN_Sop                ; display the free space graphic bar in file statistics window
                    RET
; *************************************************************************************


; *************************************************************************************
; Empty/reset demographic horisontal view of the deleted / used space of the file
; area. The Bar is 7 pixels high, using 1 pixel border around the bar, displaying a
; 5 high pixel 'bar'.
;
.ResetFreeSpaceBar
                    ld   hl,(FreeSpaceBar)        ; get base pointer to UDG 'Q' - '@'

                    ld   c, @00100000             ; left side of bar
                    call DispBarChar

                    ld   b,16
.barmiddleloop
                    ld   c,0
                    call DispBarChar
                    djnz barmiddleloop

                    ld   c, @00000001             ; right side of bar
                    jp   DispBarChar

; HL = pointer to base of VDU char
; C = 5 pixel line 'middle'
.DispBarChar
                    push bc
                    ld   (hl),@00111111           ; top of bar
                    inc  hl
                    ld   b,5
.middleloop         ld   (hl),c
                    inc  hl
                    djnz middleloop
                    ld   (hl),@00111111           ; bottom of bar
                    inc  hl
                    ld   (hl),0
                    inc  hl
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
.FillFreeSpaceBar
                    ld   a,(bytesperline)         ; get size of File Area in 16K banks
                    ld   b,0
                    ld   h,b
                    ld   l,a
                    ld   c,b
                    ld   de,16384
                    call_oz GN_M24                ; banksize = no-of-banks * 16384 = size of file area in bytes
                    ld   de,106
                    call_oz GN_D24
                    ld   (bytesperline),hl        ; banksize / 106 = no of bytes per vertical line in free space bar
                    push hl

                    ld   hl,(deleted)
                    ld   de,(deleted+2)
                    ld   b,e                      ; bhl = deleted space
                    ld   c,0
                    pop  de                       ; cde = bytes per line
                    call_oz GN_D24                ; BHL = deleted space / bytes per line

                    ld   b,l                      ; draw X lines of deleted space...
                    ld   h,1                      ; starting at line 1
                    inc  b
                    dec  b
                    jr   z, no_delspace           ; no deleted space to be drawn...
                    inc  b                        ; adjust for integer division rounding
.draw_delspace_loop
                    set  7,a                      ; indicate stippled vertical line
                    call DispBarLine
                    inc  h
                    cpl                           ; flip-flop bit 0
                    djnz draw_delspace_loop
.no_delspace
                    push hl                       ; remember position of line pointer

                    ld   hl,(active)
                    ld   a,(active+2)
                    ld   b,a                      ; BHL = Active file space
                    ld   c,0
                    ld   de,(bytesperline)
                    call_oz GN_D24                ; Active file space / bytes per line
                    ld   b,l                      ; draw X lines of active file space...
                    inc  b
                    dec  b

                    pop  hl                       ; (get line counter)
                    ret  z                        ; no active file space to display
                    xor  a                        ; indicate filled vertical line
                    inc  b                        ; adjust for integer division rounding
.draw_actspace_loop
                    call DispBarLine
                    inc  h
                    djnz draw_actspace_loop       ; draw active file space...
                    ret
; *************************************************************************************


; *************************************************************************************
; H = bar line to draw (0 - 107).
;
; A = 0: draw filled line
; A = 128 (bit 7): draw stippled line - first pixel not drawn
; A = 129 (bit 7,0): draw stippled line - first pixel drawn
;
.DispBarLine
                    push af
                    push bc
                    push de
                    push hl

                    push af
                    call GetDrawAddrBit           ; get UDG char base address and pixel mask
                    pop  af

                    ld   b,5                      ; the vertical line consists of 5 pixels in the bar, top -> down
                    or   a
                    jr   z, draw_line_loop        ; draw a filled, vertical line...
.draw_stippled_line_loop
                    bit  0,a                      ; skip drawing a pixel?
                    call nz,MaskLine
                    inc  hl
                    cpl
                    djnz draw_stippled_line_loop
                    jr   exit_DispBarLine
.draw_line_loop
                    call MaskLine
                    inc  hl
                    djnz draw_line_loop
.exit_DispBarLine
                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret
.MaskLine
                    push af
                    ld   a,c
                    or   (hl)
                    ld   (hl),a                   ; mask new 5 pixel line into bar
                    pop  af
                    ret
; *************************************************************************************


; *************************************************************************************
; IN:
;    H = bar line to draw (0 - 107).
; OUT:
;    HL = first address of UDG row to draw vertical pixel line
;    C = pixel mask representing vertical pixel line.
;
.GetDrawAddrBit
                    ld   l,6                      ; line DIV 6, get relative UDG character position
                    call divu8
                    ld   b,l                      ; (the pixel line bit position of UDG char)

                    ld   d,0
                    ld   e,h
                    sla  e                        ; (each UDG character consists of 8 bytes pixel data)
                    sla  e
                    sla  e                        ; DE = (line DIV 8) * 8, base of UDG character

                    ld   hl,(FreeSpaceBar)        ; get base pointer to UDG space bar, 'Q' - '@'
                    add  hl,de                    ; HL points at first pixel line of UDG char to draw line
                    inc  hl                       ; move past top line, ready for first vertical pixel

                    ld   c,@00100000
                    inc  b
                    dec  b
                    ret  z                        ; pixel line is already at offset 0 of UDG char
.pixel_line_adjust
                    sra  c
                    djnz pixel_line_adjust        ; pixel line adjusted correctly within byte
                    ret
; *************************************************************************************


; *************************************************************************************
; constants

.ksize_txt          DEFM "K ",0
.fepr               DEFM "FILE AREA",1,"2-T",0
.slot_bnr           DEFM 1,"2JC", "SLOT ", 0
.bfre_msg           DEFM "FREE",0
.bused_msg          DEFM "USED",0
.fisa_msg           DEFM " FILES SAVED",0
.fdel_msg           DEFM " FILES DELETED",0
.nofepr_msg         DEFM 13,10,13,10,1,"2JC",1,"2+F"
                    DEFM "No File Area"
                    DEFM 1,"2JN",1,"3-FC",0

; UDG's used for space bar (18 chars of 6x8 pixels), left - right order: QPONMLKJIHGFEDCBA@
.spacebar           DEFM 1,"3@",32+0,32+2
                    DEFM 1, "2?Q", 1, "2?P", 1, "2?O", 1, "2?N", 1, "2?M", 1, "2?L", 1, "2?K", 1, "2?J"
                    DEFM 1, "2?I", 1, "2?H", 1, "2?G", 1, "2?F", 1, "2?E", 1, "2?D", 1, "2?C", 1, "2?B"
                    DEFM 1, "2?A", 1, "2?@", 0
