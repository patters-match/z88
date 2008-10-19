; **************************************************************************************************
; GN_WIN, create a window (new API in OZ 4.2 and newer).
; (Based on CreateWindow standard library routine)
;
; This file is part of the Z88 operating system, OZ      0000000000000000      ZZZZZZZZZZZZZZZZZZZ
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
; $Id$
; ***************************************************************************************************

        include "stdio.def"
        include "map.def"
        include "oz.def"
        include "memory.def"

        module GNWin
        xdef GNWin

; **********************************************************************************************************
;
; Standard window create with banner and bottom line.
; Cursor and vertical scrolling is enabled when window is created.
;
;    IN:
;        DE = (optional) "dynamic" pointer to banner (if banner pointer in definition block is 0)
;       BHL = pointer to 7 byte window definition block (if B=0, then local pointer)
;
;           Window Defintion Block offsets:
;           0:  A = window ID (bits 0-3). The ID is in range 1-8
;               bit 7=1, 6=1: Draw left & right bars, shelf brackets, banner text, bottom line
;               bit 7=1, 6=0: Draw left & right bars, shelf brackets, banner text
;               bit 7=0, 6=1: Draw left & right bars
;               bit 7=0, 6=0: Just create window space (no visible borders)
;               bit 5=1: 8 pixel inverted top banner (only evaluated with bit 7=1)
;               bit 5=0: 7 pixel inverted top banner (only evaluated with bit 7=1)
;               bit 4=1: For all windows: grey screen, then draw window to get a pop-up effect.
;           1:  X coordinate (upper left corner) of Window
;           2:  Y coordinate (upper left corner) of Window
;           3:  WIDTH of Window (inclusive banner & bottom line)
;           4:  HEIGHT of Window (inclusive banner & bottom line)
;           5:  low byte, high byte address of window banner text
;               Only specified if bit 7 of window ID is enabled.
;               Set pointer to 0, if using a dynamic banner (window with different banner each time)
;
;       Example (Extended window "2" with 8 pixel banner and bottom line):
;           defb @11100000 | 2
;           DEFW $0000
;           DEFW $0811
;           DEFW bannerptr
;
;    OUT: None.
;
; Register status on return:
;
; A.BCDEHL/IXIY  same
; .F....../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1995-2008
; ----------------------------------------------------------------------
;
.GNWin
        oz      OS_Bix
        push    de                              ; preserve old binding

        push    ix
        push    hl
        pop     ix
        ld      a,(ix+0)                        ; get Window ID
        ld      c,(ix+1)                        ; X
        ld      b,(ix+2)                        ; Y
        ld      e,(ix+3)                        ; W
        ld      d,(ix+4)                        ; H

        oz      OS_Pout                         ; init base window "1"
        defm    1,"7#1",32,32,32+94,32+8,128,1,"2H1",0

        bit     4,a
        jr      z, check_wintype
        oz      OS_Pout
        defm    1,"2G+",0                       ; grey entire screen (but not left side MTH menu window)

.check_wintype
        bit     7,a
        jr      nz, extended_window             ; create extended window (bars, banner, bottom line)
        bit     6,a
        jr      nz, stdwindow_bars
.stdwindow_nobars
        call    stdwindow_dimens
        ld      a,128                           ; create standard window without bars (bit 7=0,6=0)
        jr      resetw

.stdwindow_bars
        call    stdwindow_dimens
        ld      a,129                           ; create standard window with bars
.resetw
        oz      Os_Out
        call    clswin                          ; clear window and enable cursor.
.exit_gnwin
        pop     ix
        pop     de
        oz      OS_Box
        ret

.extended_window
; window with banner, right & left bars, optional bottom line...
        bit     6,a
        jr      z, not_draw_botline

        oz      OS_Pout
        defm    1,"3@",0                        ; VDU cursor position (x and y sent below..)
        ld      a,c
        add     a,32
        oz      Os_Out                          ; X position stored...
        ld      a,b
        add     a,d
        add     a,31                            ; y+height-1 (for bottom line)
        oz      Os_Out
        oz      OS_Pout
        defm    1,"2*",'I',0                    ; first display bottom left corner
        ld      a,e
.draw_bot_line
        oz      OS_Pout
        defm    1,"2*",'E',0                    ; draw bottom line
        dec     a                               ; of width E
        jr      nz,draw_bot_line
        oz      OS_Pout
        defm    1,"2*",'L',0                    ; finish with bottom right corner

.not_draw_botline
        oz      OS_Pout
        defm    1,"7#",0                        ; now create window
        call    AscWindowID
        oz      Os_Out                          ; window ID
        inc     c                               ; window adjusted to bottom line
        ld      a,c
        add     a,32
        oz      Os_Out                          ; at x,    (absolute coords)
        ld      a,b
        add     a,32
        oz      Os_Out                          ; y        (rel. to base window)
        ld      a,e
        add     a,32                            ; width+32
        ld      e,a
        oz      Os_Out                          ; width    (rel. to base window)
        ld      a,d
        add     a,32
        ld      d,a                             ; height+32
        bit     6,(ix+0)
        jr      z, no_adj_botline
        sub     1                               ; adjust when a bottom line has been drawn... heigth - 1 (excl. bottom line)
.no_adj_botline
        oz      Os_Out
        ld      a, @10000011                    ; bars, shelf brackets ON
        oz      OS_out
        call    clswin

        bit     5,(ix+0)
        jr      z, banner7pxl
        oz      OS_Pout
        defm    1,"3+TR",0                      ; 8 pixel banner: just set tiny font in reverse
        jr      drawbanner
.banner7pxl
        oz      OS_Pout
        defm    1,"4+TUR",0                     ; 7 pixel banner: set underline & tiny font in reverse
.drawbanner
        oz      OS_Pout
        defm    1,"2JC"                         ; centre text
        defm    1,"3@",$20,$20,0                ; set cursor at (0,0) in window

        call    getBanner                       ; get banner pointer in HL
        oz      Gn_Sop                          ; write banner at top line of window

        oz      OS_Pout
        defm    1,"3@",$20,$20,1,"2A",0         ; apply attributes for banner width

        ld      a,e
        oz      Os_Out                          ; of window width, then apply to window banner

        oz      OS_Pout
        defm    1,"7#",0                        ; now re-create window within window
        call    AscWindowID
        oz      Os_Out                          ; with id in A
        ld      a,c
        add     a,32
        oz      Os_Out                          ; at x,
        ld      a,b
        add     a,33
        oz      Os_Out                          ; y+1
        ld      a,e
        oz      Os_Out                          ; width
        ld      a,d
        sub     1                               ; heigth - 1 (excl. banner)
        bit     6,(ix+0)
        jr      z, no_adj_botline3
        sub     1                               ; heigth - 2 (excl. banner & bottom line)
.no_adj_botline3
        oz      Os_Out
        ld      a, @10000000                    ; no bars, no shelf brackets
        oz      Os_Out                          ; window created, no cursor, no v. scrolling
        oz      OS_Pout
        defm    1,"3+CS",0                      ; Enable cursor and vertical scrolling
        jp      exit_gnwin                      ; finished, return to caller


; ******************************************************************************
;
; Standard window dimensions (x,y,w,h)
;
.stdwindow_dimens
        oz      OS_Pout
        defm    1,"7#",0
        call    AscWindowID                     ; mask out type bits and convert to Ascii Window ID
        oz      Os_Out                          ; VDU 1,"7#",<ID>
        ld      a,c
        add     a,32
        oz      Os_Out                          ; X position
        ld      a,b
        add     a,32
        oz      Os_Out                          ; Y position
        ld      a,e
        add     a,32
        oz      Os_Out                          ; width
        ld      a,d
        add     a,32
        oz      Os_Out                          ; height
        ret

; ******************************************************************************
; Get banner pointer, using either static pointer from window definition
; block or the dynamic DE(in) (if banner ptr is 0), then adjust it to
; OS_Bix segment, if needed.
;
.getBanner
        ld      l,(ix+5)
        ld      h,(ix+6)
        ld      a,h
        or      l
        jr      nz, osbixptr
        ld      l,(iy+OSFrame_E)
        ld      h,(iy+OSFrame_D)                ; HL = 0 in window definition block, use DE as dynamic banner
.osbixptr
        push    ix
        pop     af
        and     @11000000
        ret     z                               ; pointer is in segment 0, OK!
        bit     7,h
        ret     z                               ; pointer in segment 1, OK!
        res     7,h                             ; pointer in segment 2 or 3, define for segment 1
        res     6,h
        or      h                               ; banner and definition block are located in same bank
        ld      h,a                             ; mask segment specifier of OS_Bix for banner pointer
        ret

; ******************************************************************************
; convert integer to
.AscWindowID
        ld      a,(ix+0)
        and     @00001111                       ; mask out window type bits...
        or      @00110000                       ; adjust for Ascii "0" - "9"
        ret

; ******************************************************************************
; clear window (of specified ID in window definition block)
;
.clswin
        oz      OS_Pout
        defm    1,"2C",0                        ; clear window and enable cursor.
        call    AscWindowID                     ; mask out type bits and convert to Ascii Window ID
        oz      OS_Out                          ; window ID to reset.
        ret