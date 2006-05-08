; *************************************************************************************
; ZetriZ
; (C) Gunther Strube (gbs@users.sf.net) 1995-2006
;
; ZetriZ is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; ZetriZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with ZetriZ;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     module blocklogic

     lib  scroll_left

     xref addpoints
     xref setspeed

     xdef checkmap, checklines, placeblock, positionblock
     xdef zetrizmapaddress


     include "zetriz.def"



; ********************************************************************
;
;    check if current block at (x,y) is colliding with a block
;    or is beyond zetriz map boundaries.
;
.checkmap           ld   a,b
                    cp   -1
                    jr   z, range_error           ; beyond bottom line...
                    add  a,(ix+8)
                    dec  a
                    cp   zetrizmap_height
                    jr   nc, range_error          ; beyond top line...
                    ld   a,c
                    cp   -1
                    jr   z, range_error           ; beyond left border...
                    add  a,(ix+7)
                    dec  a
                    cp   zetrizmap_width
                    jr   nc, range_error          ; beyond right border...

                    call zetrizmapaddress
                    push ix
                    pop  hl
                    ld   bc,7
                    add  hl,bc          ; point at block matrix dimensions
                    ld   c,(hl)         ; get height of block matrix
                    inc  hl
                    inc  hl             ; point at first byte of block matrix

.check_row_loop     push iy             ; for row=height to 0 step -1
                    pop  de

                    ld   b,(ix+8)            ; for col=width to 0 step -1
.check_col_loop     ld   a,(hl)
                    cp   0
                    jr   z, check_next_element    ; if map(x+col,y+row) = 1
                    ex   de,hl
                    cp   (hl)                          ; if map(x+col,y+row)=block(col,row)
                    ex   de,hl
                    jr   z, collision_error
.check_next_element inc  de
                    inc  hl
                    dec  b
                    jr   nz, check_col_loop
                    ld   de,zetrizmap_height
                    add  iy,de
                    dec  c
                    jr   nz, check_row_loop
                    cp   a
                    ret
.collision_error
.range_error        scf
                    ret



; ****************************************************************************
;
.placeblock         push iy

                    ld   hl,blockflags
                    set  blockplaced,(hl)
                    ld   bc,(mapxy)
                    call zetrizmapaddress
                    push ix
                    pop  hl
                    ld   bc,7
                    add  hl,bc          ; point at block matrix dimensions
                    ld   c,(hl)         ; get height of block matrix
                    inc  hl
                    inc  hl             ; point at first byte of block matrix
.place_row_loop
                    push iy
                    pop  de
                    ld   b,(ix+8)
.place_col_loop
                    ld   a,(de)
                    or   (hl)           ; merge block information with zetriz map
                    ld   (de),a
                    inc  de
                    inc  hl
                    dec  b
                    jr   nz, place_col_loop
                    ld   de,zetrizmap_height
                    add  iy,de
                    dec  c
                    jr   nz, place_row_loop

                    pop  iy             ; (current line is at the x coordinate)
                    ret


; **************************************************************************
;
; check line of current (x,y) to be complete:
;    If complete, then the line will be deleted and the block information above
;    is scrolled downward to the deleted line.
;    If not, control is returned to caller.
;
;    in:  b = x coordinate for zetriz map line
;
.checklines         push de
                    push hl
                    ld   c,(ix+8)                 ; width of current zetriz block
                    ld   de,zetrizmap_height      ; offset to next line coordinate
.check_lines_loop   call checkline
                    jr   nz, next_line

                         ; line is complete - remove line b...
                         ld   hl,removedlines
                         inc  (hl)           ; ++removedlines
                         call removeline
                         ld   c,(ix+8)       ; check scrolled line
                         call checklines     ; checkline(b,?) - another line to scroll?
                         jr   exit_checkline

.next_line          dec  c
                    jr   z, exit_checkline
                    inc  b
                    jr   check_lines_loop

.exit_checkline     pop  hl
                    pop  de
                    ret

.checkline          push bc             ; preserve line width coordinate
                    ld   c,0            ; check from beginning of current line
                    call zetrizmapaddress
                    pop  bc                  ; iy points at beginning of line
                    ld   l,zetrizmap_width   ; line contains 10 block entities
                    ld   a,1
.checkline_loop     cp   (iy+0)         ;
                    ret  nz             ; line is not complete
                    add  iy,de          ; point at next block in line
                    dec  l
                    jr   nz, checkline_loop
                    ret                 ; Fz = 1, line is complete


; **************************************************************************
;
; scroll lines from above current line into current line.
;
;    in:  b = line (map x coordinate)
;
.removeline         push bc
                    ld   c,0            ; beginning of line b
                    call zetrizmapaddress
                    ld   c,zetrizmap_width        ; scroll 10 rows from top to current line
                    ld   a,zetrizmap_height
                    sub  b
                    dec  a
                    ld   b,a            ; row is height-b blocks in length
.scroll_row_loop    push iy
                    pop  de
                    ld   h,d
                    ld   l,e
                    inc  hl
                    push bc             ; preserve length of row...
.scroll_col_loop    ld   a,(hl)
                    ld   (de),a
                    inc  hl
                    inc  de
                    djnz scroll_col_loop
                    xor  a
                    ld   (de),a         ; top line is zeroed...
                    pop  bc
                    ld   de,zetrizmap_height
                    add  iy,de          ; point at beginning of next row...
                    dec  c
                    jr   nz, scroll_row_loop

                    ld   a,b
                    inc  a
                    call graphicscoord
                    sub  2              ; w = row length in pixels
                    ld   b,a
                    ld   c,zetrizmap_width*6 ; 10 rows, each 6 pixels wide...
                    pop  hl
                    push hl
                    ld   a,h
                    call graphicscoord
                    ld   h,a            ; graphics x coordinate of line
                    ld   l,2
                    ld   a,1            ; scroll(x,2,w,60,1)
                    ld   d,6            ; scroll 6 pixels leftward
.scrollpixels_loop  push af             ; but 1 pixel at a time...
                    push bc
                    push de
                    push hl
                    call scroll_left
                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    dec  d
                    jr   nz, scrollpixels_loop
                    pop  bc
                    ret



; ******************************************************************
;
; calculate address of (x,y) coordinate in zetriz map array
;
; in:   bc = (x,y) coordinate
; out:  iy = address of (x,y) coordinate
;
; registers changed after return:
;    afbcdehl/ix..  same
;    ......../..iy  different
;
.zetrizmapaddress   push hl
                    push de
                    push af
                    ld   hl, zetrizmap
                    ld   d,0
                    ld   e,b
                    add  hl,de          ; x position in zetriz map
                    ld   a,c
                    cp   0              ; y coordinate 0?
                    jr   z, address_calculated
                    ld   e,zetrizmap_height
.calc_row_loop      add  hl,de          ; address += y * height
                    dec  a
                    jr   nz, calc_row_loop
.address_calculated push hl
                    pop  iy
                    pop  af
                    pop  de
                    pop  hl
                    ret


; *********************************************************************
;
; posiion zetriz block at top of zetriz map (adjusted to size of block)
;
.positionblock
                    ld   c,(ix+8)       ; width of zetriz block
                    ld   a,zetrizmap_height
                    sub  c
                    ld   b,a
                    ld   c,4
                    ld   (mapxy),bc     ; (x,y) position of block in map
                    call graphicscoord
                    ld   (blockxy+1),a  ; x calculated for graphics coordinate
                    ld   a,$1a
                    ld   (blockxy),a    ; y graphics coordinate prepared
                    ret


; **************************************************************************
;
;    Convert map coordinate to graphics coordinates in zetriz window
;
;    in:  a = map coordinate
;    out: a = graphics coordinate
;
; registers changed after return:
;    ..bcdehl/ixiy  same
;    af....../....  different
;
.graphicscoord      push bc
                    ld   b,a
                    xor  a
                    cp   b
                    jr   z, coord_multiplied
.graphics_addloop   add  a,6
                    djnz graphics_addloop    ; coord = 6*x
.coord_multiplied   add  a,2                 ; coord += 2
                    pop  bc
                    ret
