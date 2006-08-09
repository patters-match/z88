     XLIB CreateWindow

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

     INCLUDE "stdio.def"
     INCLUDE "map.def"


; **********************************************************************************************************
;
; Standard window create with banner and bottom line.
;
; Cursor and vertical scrolling is enabled when window created.
; Window "1" is a base window for the extended window and will always be defined with max. screen size.
; It is invisible (not creared). You may use "1" for extended windows as well but results are unpredictable.
; If no extended windows are created (bit 7,A = 0) then window "1" also available.
;
;    IN:
;    A = window id ("2" - "6")
;    bit 7=1: 6=1: Extended window: left & right shelf brackets, left & right bars, banner and bottom line
;    bit 7=1, 6=0: Standard window: left & right shelf brackets, left & right bars and banner
;    bit 7=0, 6=1: Standard window: left & right bars, no shelf brackets, no banner, no bottom line.
;    bit 7=0, 6=0: Standard window: no bars, no shelf brackets, no banners.
;
;    HL = pointer to window banner text.
;    BC = Y,X position of window
;    DE = HEIGHT,WIDTH of window (inclusive banner & bottom line)
;
;    OUT: None.
;
; Register status on return:
;
; ......../IXIY  same
; AFBCDEHL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.CreateWindow       BIT  7,A
                    JR   NZ, extended_window           ; create extended window (banner, bottom line)
                    BIT  6,A
                    JR   NZ, stdwindow_bars
.stdwindow_nobars   AND  @00111111                     ; mask out window type bits...
                    PUSH AF
                    CALL stdwindow_dimens
                    LD   A,128                         ; create standard window without bars
                    JR   resetw

.stdwindow_bars     AND  @00111111                     ; mask out window type bits...
                    PUSH AF
                    CALL stdwindow_dimens
                    LD   A,129                         ; create standard window with bars
.resetw             CALL_OZ(Os_Out)
                    LD   HL, ResetWindow               ; clear window and enable cursor.
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    CALL_OZ(OS_Out)                    ; window ID to reset.
                    RET

.extended_window    BIT  6,A
                    JP   NZ, window_bottomline

; window with banner, right & left bars, no bottom line...
                    PUSH HL                             ; ptr. to banner on stack
                    PUSH AF                             ; window id on stack
                    LD   A,'1'
                    CALL ReclaimWindow                  ; make sure that base window is text based
                    POP  AF
                    AND  @00111111                      ; mask out window type bits...
                    PUSH AF
                    LD   HL,base_window                 ; init base window "1"
                    CALL_OZ (Gn_Sop)
                    LD   HL, xypos
                    CALL_OZ(Gn_Sop)
                    LD   A,C
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; X position stored...
                    LD   A,B
                    ADD  A,D
                    ADD  A,32                           ; y+height
                    CALL_OZ(Os_Out)

                    LD   HL,Def_Window                  ; now create window
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    PUSH AF
                    CALL_OZ(Os_Out)                     ; window ID
                    INC  C                              ; window adjusted to bottom line
                    LD   A,C
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; at x,    (absolute coords)
                    LD   A,B
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; y        (rel. to base window)
                    LD   A,E
                    ADD  A,32                           ; width+32
                    LD   E,A
                    CALL_OZ(Os_Out)                     ; width    (rel. to base window)
                    LD   A,D
                    ADD  A,32
                    LD   D,A                            ; height+32
                    CALL_OZ(Os_Out)
                    LD   A, @10000011                   ; bars, shelf brackets ON
                    CALL_OZ(OS_out)

                    LD   HL,ResetWindow                 ; select & clear window area
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    CALL_OZ(Os_Out)                     ; of id in A

                    LD   HL, BannerAttributes
                    CALL_OZ (Gn_Sop)                    ; set tiny font, underline, reverse, centre just.

                    POP  HL                             ; get ptr. to banner
                    PUSH AF                             ; window id back on stack
                    CALL_OZ (Gn_Sop)                    ; write banner at top line of window

                    LD   HL,ApplyToggles                ; define toggles
                    CALL_OZ(Gn_Sop)
                    LD   A,E
                    CALL_OZ(Os_Out)                     ; of window width, then apply to window banner

                    LD   HL,Def_Window                  ; now create window within window
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    CALL_OZ(Os_Out)                     ; with id in A
                    LD   A,C
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; at x,
                    LD   A,B
                    ADD  A,33
                    CALL_OZ(Os_Out)                     ; y+1
                    LD   A,E
                    CALL_OZ(Os_Out)                     ; width
                    LD   A,D
                    SUB  1
                    CALL_OZ(Os_Out)                     ; heigth - 1 (excl. banner)
                    LD   A, @10000000                   ; no bars, no shelf brackets
                    CALL_OZ(Os_Out)                     ; window created, no cursor, no v. scrolling
                    LD   HL, EnableCurScroll
                    CALL_OZ(Gn_Sop)                     ; Enable cursor and vertical scrolling
                    RET                                 ; finished, return to caller

; window with bottom line
.window_bottomline  PUSH HL                             ; ptr. to banner on stack
                    PUSH AF                             ; window id on stack
                    LD   A,'1'
                    CALL ReclaimWindow                  ; make sure that base window is text based
                    POP  AF
                    AND  @00111111                      ; mask out window type bits...
                    PUSH AF
                    LD   HL,base_window                 ; init base window "1"
                    CALL_OZ (Gn_Sop)
                    LD   HL, xypos
                    CALL_OZ(Gn_Sop)
                    LD   A,C
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; X position stored...
                    LD   A,B
                    ADD  A,D
                    ADD  A,31                           ; y+height-1
                    CALL_OZ(Os_Out)
                    LD   HL,bot_left_corner
                    CALL_OZ (Gn_Sop)                    ; first display bottom left corner
                    LD   A,E
.draw_bot_line
                    LD   HL,bot_line
                    CALL_OZ(Gn_Sop)                     ; draw bottom line
                    DEC  A                              ; of width E
                    JR   NZ,draw_bot_line

                    LD   HL,bot_right_corner
                    CALL_OZ (Gn_Sop)                    ; finish with bottom rigth corner

                    LD   HL,Def_Window                  ; now create window
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    PUSH AF
                    CALL_OZ(Os_Out)                     ; window ID
                    INC  C                              ; window adjusted to bottom line
                    LD   A,C
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; at x,    (absolute coords)
                    LD   A,B
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; y        (rel. to base window)
                    LD   A,E
                    ADD  A,32                           ; width+32
                    LD   E,A
                    CALL_OZ(Os_Out)                     ; width    (rel. to base window)
                    LD   A,D
                    ADD  A,32
                    LD   D,A                            ; height+32
                    SUB  1
                    CALL_OZ(Os_Out)                     ; heigth - 1 (excl. bottom line)
                    LD   A, @10000011                   ; bars, shelf brackets ON
                    CALL_OZ(OS_out)

                    LD   HL,ResetWindow                 ; select & clear window area
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    CALL_OZ(Os_Out)                     ; of id in A

                    LD   HL, BannerAttributes
                    CALL_OZ (Gn_Sop)                    ; set tiny font, underline, reverse, centre just.

                    POP  HL                             ; get ptr. to banner
                    PUSH AF                             ; window id back on stack
                    CALL_OZ (Gn_Sop)                    ; write banner at top line of window

                    LD   HL,ApplyToggles                ; define toggles
                    CALL_OZ(Gn_Sop)
                    LD   A,E
                    CALL_OZ(Os_Out)                     ; of window width, then apply to window banner

                    LD   HL,Def_Window                  ; now create window within window
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    CALL_OZ(Os_Out)                     ; with id in A
                    LD   A,C
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; at x,
                    LD   A,B
                    ADD  A,33
                    CALL_OZ(Os_Out)                     ; y+1
                    LD   A,E
                    CALL_OZ(Os_Out)                     ; width
                    LD   A,D
                    SUB  2
                    CALL_OZ(Os_Out)                     ; heigth - 2 (excl. banner & bottom line)
                    LD   A, @10000000                   ; no bars, no shelf brackets
                    CALL_OZ(Os_Out)                     ; window created, no cursor, no v. scrolling
                    LD   HL, EnableCurScroll
                    CALL_OZ(Gn_Sop)                     ; Enable cursor and vertical scrolling
                    RET                                 ; finished, return to caller


; ******************************************************************************
;
; Use window for text only.
;
; IN: A = window id ("1" - "6")
;
.ReclaimWindow      PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   BC, MP_DEL                     ; window must be a text window
                    CALL_OZ(OS_Map)                     ; reclaim window '1' for text
                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET


; ******************************************************************************
;
; Standard window dimensions (x,y,w,h)
;
.window_vduinit     DEFM 1,"7#",0
.stdwindow_dimens
                    PUSH AF
                    CALL ReclaimWindow                  ; use text in window...
                    LD   HL, window_vduinit
                    CALL_OZ(Gn_Sop)
                    POP  AF
                    PUSH AF                             ;
                    CALL_OZ(Os_Out)                     ; VDU 1,"7#",<ID>
                    LD   A,C
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; X position
                    POP  AF
                    LD   A,B
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; Y position
                    LD   A,E
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; width
                    LD   A,D
                    ADD  A,32
                    CALL_OZ(Os_Out)                     ; height
                    RET

; Definitions used only by CreateWindow:
;
.base_window        DEFM 1,"7#1",32,32,32+94,32+8,128,1,"2H1" ; window VDU definitions
                    DEFM 1,"4-SCR",0              ; reset any settings
.def_window         DEFM 1,"7#",0                 ; define window
.ResetWindow        DEFM 1,"2C",0                 ; window id
.EnableCurScroll    DEFM 1,"3+CS",0
.BannerAttributes   DEFM 1,"4+TUR"                ; set underline, tiny font in reverse
                    DEFM 1,"2JC"                  ; centre text
                    DEFM 1,"3@",$20,$20,0         ; set cursor at (0,0) in window

.ApplyToggles       DEFM 1,"3@",$20,$20
                    DEFM 1,"2A",0                 ; apply attributes for banner width

.xypos              DEFM 1,"3@",0                 ; VDU cursor position (x and y sent later)
.bot_left_corner    DEFM 1,"2*",'I',0             ; VDU bottom left corner
.bot_line           DEFM 1,"2*",'E',0             ; VDU bottom line
.bot_right_corner   DEFM 1,"2*",'L',0             ; VDU bottom right corner
;
