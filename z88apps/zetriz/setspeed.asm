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

     module set_speed_movement

     lib  cleararea

     xref displaynumber
     xdef setspeed, displayspeed

     include "fpp.def"
     include "zetriz.def"


; **************************************************************************
;
;    set program block speed movement from user parameter
;    and current game points.
;
;    speed range is 0 to 7, speeds above 7 will automatically
;    recycle back to 0 (using an AND mask)
;
.setspeed           push af
                    push bc
                    push de
                    push hl

                    ld   hl,(gamepoints+2)
                    ld   de,0
                    exx
                    ld   hl,(gamepoints)
                    ld   de,10000
                    exx
                    ld   bc,0
                    fpp  (FP_IDV)            ; gamepoints DIV 10000
                    ld   a,(speed)           ; initial user speed parameter
                    exx
                    add  a,l                 ; (speed) + gamepoints DIV 10000
                    exx
                    and  @00000111           ; recycle current speed, if overflow...
                    ld   d,a
                    ld   a,(gamespeed)
                    ld   e,a                 ; d = new game speed, e = old game speed
                    ld   a,d
                    ld   (gamespeed),a       ; remember new calculated speed parameter
                    ld   hl, speedtimings
                    ld   b,0
                    ld   c,a
                    add  hl,bc               ; point at current speed parameter
                    ld   a,(hl)
                    ld   (timeout),a         ; set new speed timeout block movement
                    ld   a,d
                    cp   e
                    call nz,displayspeed     ; display new speed parameter, if changed

                    pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret

.speedtimings       defb 32                  ; speed 0 of timout block movement (1/100 seconds)
                    defb 29                  ; speed 1
                    defb 26                  ; speed 2
                    defb 22                  ; speed 3
                    defb 19                  ; speed 4
                    defb 17                  ; speed 5
                    defb 14                  ; speed 6
                    defb 11                  ; speed 7 ... fast ...



; ******************************************************************
;
; display current removed lines at (220,60) downwards
;
.displayspeed       call clearspeed
                    ld   hl,0
                    exx
                    ld   de,$0002       ; format string to max. 4 digits
                    ld   a,(gamespeed)
                    ld   h,0
                    ld   l,a
                    exx
                    ld   bc,0
                    ld   de,pointsascii
                    push de
                    fpp  (fp_str)       ; convert to ascii...
                    ex   de,hl
                    pop  de
                    push hl
                    sbc  hl,de
                    pop  de
                    dec  de             ; point at first digit

                    ld   b,l            ; number of digits to print
                    ld   hl,$c538       ; (x,y) for display of score
                    call displaynumber
                    ret

; ******************************************************************
;
.clearspeed         ld   hl,$c518
                    ld   bc,$0c28       ; width = 12, heigth = 40
                    call cleararea      ; clear speed parameter
                    ret
