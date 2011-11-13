; **************************************************************************************************
; FreeRam
; (C) Gunther Strube (gbs@users.sf.net) 1998
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
;
; **************************************************************************************************

     Module FreeRam

; Popdown version; V1.0 implemented 11/06/1998
; Migrated as Index command, June-July 2009

include "stdio.def"
include "dor.def"
include "director.def"
include "memory.def"
include "error.def"
include "integer.def"
include "syspar.def"
include "fpp.def"
include "map.def"
include "screen.def"
include "sysapps.def"
include "../apps/index/freeram.def"

xdef FreeRam
xdef ClsMapWin2, ClsMapWin4
xdef UpdateFreeSpaceRamCard


; ******************************************************************************
;
; Entry of FreeRAM command
;
.FreeRam
                    ld   b,0
                    ld   hl, FreeRamWindowDef
                    oz   GN_Win

                    OZ   OS_Pout
                    ; invisible window area for "K" lines
                    defm 1,"6#2",$20+$4D,$20+0,$20+6,$20+8
                    defm 1,"2C2", 0

                    ld   a,'4'
                    ld   bc, MS_S2 << 8 | MP_MEM
                    ld   hl,64                    ; define a map of 64 pixels, associated with segment 2
                    oz   OS_Map                   ; and create it...
                    ld   a,b
                    ld   (graphics_bank ),a
                    ld   (graphics_base),hl       ; preserve pointer to base area of graphics

                    ld    a, 10                   ; read max. 10 characters
                    ld   bc, PA_DEV               ; read default device
                    ld   de, ascbuf               ; buffer for device name
                    push de                       ; save pointer to buffer
                    call_oz (OS_Nq)
                    pop  hl
                    ld   b,0
                    ld   c,a
                    add  hl,bc
                    dec  hl
                    ld   a,(hl)                   ; get (slot) number of default RAM device

; also called from Index main input loop, A = '0', '1', '2' or '3'.
.UpdateFreeSpaceRamCard
                    ld   (inpbuf),a
                    sub  48                       ; slot number
                    ld   (slotno),a               ; as internal integer

                    call GetFreeSpace             ; get RAM device info
                    call c, DispNoRam             ; - if available
                    call nc,DispFreeRamInfo

                    OZ   OS_Pout                  ; display ":RAM." at top of window
                    defm 1, "2H3", 1, "2JN", 1, "3@", 32+1, 32+1, 1, "2+C:RAM.", 0

                    ld   a,(inpbuf)
                    oz   OS_Out                   ; then current select device number
                    ld   a,8
                    oz   OS_Out                   ; BACKSPACE (cursor on top of number)
                    ret                           ; back to main index loop...


; ***************************************************************************************
;
.DispFreeRamInfo
                    call DispCardSizeColumn

; use a text window to clear it...
                    call ClsMapWin4               ; reset graphics map (no card present)

                    call DispFreeRamMap           ; display graphical view of card
                    call DispCardSize
                    jr   DispFreeSpaceInfo


; ***************************************************************************************
;
.DispNoRam          push af
                    call ClsMapWin2

                    call ClsMapWin4               ; reset graphics map (no card present)

                    oz   OS_Pout                  ; select (and clear) window #3, then write "(None)"
                    defm 1, "2C3", 1, "3@", 32+8, 32+1, "(None)", 0

                    pop  af
                    ret


; ***************************************************************************************
;
.DispCardSize
                    oz   OS_Pout
                    defm 1, "2C3", 1, "3@", 32+8, 32+1, "(", 0
                    ld   a,(cardsize)
                    ld   h,0
                    ld   l,a
                    call m16                      ; cardsize * 16 (K)
                    ld   b,h
                    ld   c,l
                    ld   hl,2
                    call DispIntAscii
                    oz   OS_Pout
                    defm "K)", 0
                    ret


; ***************************************************************************************
;
.DispFreeSpaceInfo
                    OZ   OS_Pout
                    defm 1, "2JC", 1, "3@", 32+0, 32+3, 1, "TFREE SPACE", 1, "T", 13, 10, 0
                    ld   hl, freespace
                    call DispIntAscii

                    OZ   OS_Pout
                    defm " bytes", 13, 10, '(', 0

                    xor  a
                    ld   b,a
                    ld   c,a
                    ld   h,a
                    ld   a,(cardsize)
                    ld   l,a
                    ld   de,16384
                    oz   GN_M24                   ; TotalBytes = <cardsize> * 16384

                    push hl
                    ld   d,0
                    ld   e,b
                    ld   hl,(freespace+2)
                    exx
                    pop  de
                    ld   hl,(freespace)
                    exx
                    ld   bc,0
                    fpp  (FP_DIV)                 ; FreeSpace / TotalBytes
                    ld   b,0
                    ld   de,0
                    exx
                    ld   de,100
                    exx
                    fpp  (FP_MUL)                 ; FreeSpace / TotalBytes * 100 (%)

                    ld   de,ascbuf
                    exx
                    ld   d,0
                    ld   e,4
                    exx
                    fpp  (FP_STR)
                    xor  a
                    ld   (de),a

                    ld   hl, ascbuf
                    call_oz(GN_Sop)               ; display free space in %

                    oz   OS_Pout
                    defm "%)", 0
                    ret


; ***************************************************************************************
;
.GetFreeSpace
                    ld   a,(slotno)               ; scan slot x
                    ld   bc, NQ_Mfp
                    oz   OS_Nq
                    ret  c

                    ld   (cardsize),a             ; size of card in 16K banks...
                    ld   b,e                      ; store free space in bytes...
                    ld   c,0
                    ld   e,d
                    ld   d,0                      ; <free pages> * 256 bytes
                    ld   (freespace),bc
                    ld   (freespace+2),de         ; low byte, high byte sequense
                    cp   a
                    ret


; ***************************************************************************************
;
.DispFreeRamMap
                    ld   a,(slotno)
                    rrca
                    rrca                          ; slot number converted to bottom bank
                    or   a
                    jr   nz, external_slot
                         ld   a,$21               ; bottom bank in slot 0 for MAT is $21
.external_slot
                    ld   b,a                      ; get bank of memory allocation table (MAT)
                    ld   c,MS_S1                  ; (bottom of RAM card)
                    rst  OZ_MPB                   ; and bind into segment 1.
                    push bc

                    exx

                    call GetMapAddress            ; Map area base address in BHL
                    ld   c, MS_S2
                    rst  OZ_MPB                   ; bind in map area in segment 2
                    push bc

                    ld   bc,0                     ; row counter in 8x8 matrix (0 - 7)
                    ld   de,$8008                 ; D = column bit in 8x8 matrix (begin with leftmost)
                    exx                           ; E = 8, eight 8x8 pixel matrixes per row

                    ld   a,(cardsize)             ; size of card in 16K banks...
                    ld   b,a                      ; actual number of banks
                    ld   hl,$4100                 ; data start at $0100
                    ld   c,b                      ; parse table of B(anks) * 64 pages

                    sub  8                        ; calculate the pixel scaling, if RAM card < 128K
                    ld   a,1                      ; default 1 pixel per used page
                    jr   nc, init_dispfreeram
                    ld   a,b                      ; A = card size
                    push bc
                    ld   b,8
.factor_loop                                      ; 8/card size = pixel factor
                    rrc  b
                    dec  a
                    cp   1
                    jr   nz,factor_loop
                    ld   a,b                      ; A = pixel factor
                    pop  bc
.init_dispfreeram
                    ld   (pixelfactor),a
.card_scan_loop
                    ld   b,64                     ; total of pages in a bank...
.bank_scan_loop                                   ; (for each bank is 8x8 pixels = character block)
                    ld   a,(hl)
                    inc  hl
                    or   (hl)                     ; must be 00 if free
                    ex   af,af'
                    inc  hl

                    ld   a,(pixelfactor)
                    ld   d,a
.pixelfactor_loop
                    push de
                    ex   af,af'
                    call nz,plot_usedpage         ; page used, plot a pixel (scaled for current 128K row in map...
                    ex   af,af'
                    call update_pixelptr          ; prepare for next pixel position
                    pop  de
                    dec  d
                    jr   nz,pixelfactor_loop
                    djnz bank_scan_loop
                    dec  c
                    jr   nz, card_scan_loop
                    pop  bc
                    rst  OZ_MPB                   ; restore segment 2 binding..
                    pop  bc
                    rst  OZ_MPB                   ; restore segment 1 binding..
                    ret
.plot_usedpage
                    push af
                    exx
                    push hl
                    add  hl,bc                    ; ptr to current row in matrix
                    ld   a,(hl)                   ; get current row of matrix
                    or   d
                    ld   (hl),a                   ; "plot" point identifying used page
                    pop  hl
                    exx
                    pop  af
                    ret
.update_pixelptr
                    exx
                    inc  c                        ; next row of matrix...
                    bit  3,c
                    call nz,new_column
                    exx
                    ret
.new_column
                    rrc  d                        ; in next pixel column (bit 7 -> bit 0)
                    call c,next_matrix            ; when bit arrives in Fc, all 64 bits (8x8 pixels) done
                    ld   c,0                      ; begin at first row (next 8x8 pixel block)
                    ret
.next_matrix
                    add  hl,bc                    ; in next matrix
                    dec  e
                    ret  nz                       ; 8x8 matrix row still not complete
                    ld   e,8
                    ret


; ***************************************************************************************
;
.DispCardSizeColumn
                    call ClsMapWin2               ; select (and clear) window #2
                    oz   OS_Pout
                    defm 1, "2JR", 1,  "2+T", 0   ; window "2", right justify, ; no cursor no scrolling

                    ld   a,(cardsize)
                    ld   d,a                      ; B = card size (in 16K banks)
                    ld   e,0                      ; X = 0
.disp_k_loop
                    ld   a,d
                    inc  a
                    dec  a
                    ret  z                        ; while B > 0
                         sub  8                   ;    if B-8 < 0 then
                         jr   nc, larger_128K
                         ld   c,d                 ;         i = B
                         jr   disp_k              ;    else
.larger_128K             ld   c,8                 ;         i = 8
.disp_k
                         ld   a,e
                         add  a,c
                         ld   e,a                 ;    X = X + i
                         ld   a,d
                         sub  c
                         ld   d,a                 ;    B = B - i

                         ld   h,0
                         ld   l,e
                         call m16                 ;    X*16
                         ld   b,h
                         ld   c,l
                         ld   hl,2
                         call DispIntAscii        ;    print str$(X*16) + "K"
                         oz   OS_Pout
.kb                      defm "K ", 13, 10, 0
                    jr   disp_k_loop              ; end while


; ***************************************************************************************
;
; Multiply HL * 16, result in HL.
;
.m16                add  hl,hl
                    add  hl,hl
                    add  hl,hl
                    add  hl,hl
                    ret


; ****************************************************************************
;
; Convert integer in HL (or BC) to Ascii string, which is written to (AscBuf)
; and null-terminated.
;
.DispIntAscii
                    push af
                    push de
                    xor  a
                    ld   de,ascbuf
                    push de
                    oz   Gn_Pdn
                    xor  a
                    ld   (de),a
                    pop  hl
                    oz   Gn_Sop                 ; display integer
                    pop  de
                    pop  af
                    ret


; ******************************************************************
;
; Return base of Map area in BHL, adjusted for segment 2 address space
.GetMapAddress
                    ld      b,0
                    ld      a,sc_hr0
                    oz      os_sci                          ; get base address of map area (hires0) in BHL
                    set     7,h
                    res     6,h                             ; Base of map area adjusted to segment 2 for BHL
                    ld      (graphics_base),hl              ; preserve base of graphics area
                    ld      a,b
                    ld      (graphics_bank),a
                    ret


; ******************************************************************
;
; Clear graphics area, i.e. reset all bits in graphics (map)
; window of width x height (64 x 64) pixels.
;
.ClsMapWin4
                    call GetMapAddress
                    ld   c, MS_S2
                    rst  OZ_MPB
                    push bc
                    ld   bc, 10*8*8
                    ld   (hl),0
                    ld   d,h
                    ld   e,1                 ; de = base_graphics+1
                    ldir                     ; reset graphics window
                    pop  bc
                    rst  OZ_MPB
                    ret


; ***************************************************************************************
;
.ClsMapWin2         oz   OS_Pout
                    defm 1, "2C2", 0         ; select (and clear) window #2
                    ret


; ***************************************************************************************
;
; "FREE RAM" Window definition
;
.FreeRamWindowDef
        DEFB    @10100000 | 3
        DEFW    $003B
        DEFW    $0810
        DEFW    freeram_banner
.freeram_banner
        defm    "FREE RAM",0
