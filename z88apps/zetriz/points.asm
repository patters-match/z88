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

     module zetriz_points

     lib  cleararea, displayblock

     xdef addpoints, displaypoints, displaylines, displayblocks
     xdef displaynumber

     include "fpp.def"
     include "stdio.def"
     include "error.def"

     include "zetriz.def"



; ******************************************************************
;
; display current removed lines at (220,60) downwards
;
.displaylines       call clearlines
                    ld   hl,0
                    exx
                    ld   de,$0004       ; format string to max. 4 digits
                    ld   hl,(totallines)
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
                    ld   hl,$e338       ; (x,y) for display of score
                    call displaynumber
                    ret


; ******************************************************************
;
; display current number of blocks
;
.displayblocks      call clearblocks
                    ld   hl,0
                    exx
                    ld   de,$0006       ; format string to max. 6 digits
                    ld   hl,(totalblocks)
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
                    ld   hl,$d438       ; (x,y) for display of score
                    call displaynumber
                    ret


; ******************************************************************
;
.clearlines         ld   hl,$e318       ; at ($e3,24)
                    ld   bc,$0c28       ; width = 12, heigth = 40
                    call cleararea      ; clear number area
                    ret


; ******************************************************************
;
.clearblocks        ld   hl,$d41e       ; at ($d4,30)
                    ld   bc,$0c28       ; width = 12, heigth = 40
                    call cleararea      ; clear number area
                    ret



; ******************************************************************
;
;    Add points to current game points, depending on how many
;    lines have been removed.
;
.addpoints          ld   hl,removedlines
                    inc  (hl)
                    dec  (hl)
                    ret  z                   ; no lines removed, no points...

                    ld   b,0                 ; lines are removed, update game points
                    ld   c,(hl)
                    dec  c                   ; adjust for points array (0 to 4)
                    sla  c                   ; word boundary
                    ld   hl,linepoints
                    add  hl,bc               ; point at score for removed lines
                    ld   c,(hl)
                    inc  hl
                    ld   b,(hl)              ; bc = points for removed lines
                    ld   hl,(gamepoints)
                    add  hl,bc               ; add points to score
                    ld   (gamepoints),hl
                    ld   hl,(gamepoints+2)
                    ld   bc,0
                    adc  hl,bc
                    ld   (gamepoints+2),hl   ; overflow adjust
                    call displaypoints       ; display new score

                    ld   a,(removedlines)
                    ld   d,0
                    ld   e,a
                    ld   hl,(totallines)
                    add  hl,de
                    ld   (totallines),hl     ; lines count updated
                    call displaylines        ; display new removed line count
                    ret

.linepoints         defw 100            ; points for 1 removed line
                    defw 300            ; points for 2 removed lines
                    defw 700            ; points for 3 removed lines
                    defw 1500           ; points for 4 removed lines
                    defw 3300           ; points for 5 removed lines



; ******************************************************************
;
; display current score at (238,24) downwards
;
.displaypoints      call clearscoretable
                    ld   hl,(gamepoints+2)
                    exx
                    ld   de,$0006       ; format string to max. 6 digits
                    ld   hl,(gamepoints)
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
                    ld   hl,$f238       ; (x,y) for display of score
                    call displaynumber
                    ret



; *******************************************************************
;
;
.displaynumber      push ix

.dispscore_loop     ld   a,(de)
                    dec  de             ; prepare for next digit

                         push bc        ; preserve loop counter
                         push de        ; preserve pointer to next digit
                         push hl        ; preserve current graphics coordinate for digit
                         sub  48        ; convert ascii digit to integer
                         rlca           ; use integer as lookup, word boundary
                         ld   b,0
                         ld   c,a
                         ld   hl,digitlookup
                         add  hl,bc     ; point at digit graphics representation vector
                         ld   c,(hl)
                         inc  hl
                         ld   b,(hl)
                         push bc
                         pop  ix        ; pointer to digit in ix...
                         pop  hl
                         call displayblock   ; display digit
                         pop  de
                         pop  bc

.next_digit         ld   a,l
                    sub  6
                    ld   l,a            ; set graphics cursor for next digit
                    djnz dispscore_loop

                    pop  ix
                    ret


; ******************************************************************
;
.clearscoretable    ld   hl,$f218       ; at (x,y)
                    ld   bc,$0c28       ; width = 12, heigth = 40
                    call cleararea      ; clear score table area...
                    ret


; ******************************************************************
;
.digitlookup        defw digit0
                    defw digit1
                    defw digit2
                    defw digit3
                    defw digit4
                    defw digit5
                    defw digit6
                    defw digit7
                    defw digit8
                    defw digit9


.digit0             defb end_digit0-digit0
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit0         defb @00111111,@11100000
                    defb @01000000,@00010000
                    defb @01000000,@00010000
                    defb @01000000,@00010000
                    defb @00111111,@11100000


.digit1             defb end_digit1-digit1
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit1         defb @01000000,@10000000
                    defb @01000000,@01000000
                    defb @01111111,@11110000
                    defb @01000000,@00000000
                    defb @01000000,@00000000


.digit2             defb end_digit2-digit2
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit2         defb @01111000,@01100000
                    defb @01000100,@00010000
                    defb @01000010,@00010000
                    defb @01000001,@00010000
                    defb @00110000,@11100000


.digit3             defb end_digit3-digit3
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit3         defb @00110000,@01100000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000101,@00010000
                    defb @00111000,@11100000


.digit4             defb end_digit4-digit4
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit4         defb @00111100,@00000000
                    defb @00100011,@00000000
                    defb @00100000,@11000000
                    defb @01111111,@11110000
                    defb @00100000,@00000000


.digit5             defb end_digit5-digit5
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit5         defb @00110001,@11110000
                    defb @01000001,@00010000
                    defb @01000001,@00010000
                    defb @01000001,@00010000
                    defb @00111110,@00010000


.digit6             defb end_digit6-digit6
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit6         defb @00111111,@11100000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @00111100,@01100000


.digit7             defb end_digit7-digit7
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit7         defb @00000000,@00100000
                    defb @01111000,@00010000
                    defb @00000110,@00010000
                    defb @00000001,@10010000
                    defb @00000000,@01110000


.digit8             defb end_digit8-digit8
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit8         defb @00111101,@11100000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @00111101,@11100000


.digit9             defb end_digit9-digit9
                    defb 2,5                 ; 2 byte width, 5 pixel rows
.end_digit9         defb @00110001,@11100000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @00111111,@11100000
