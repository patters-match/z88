     xlib move

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     lib line_r
     xref TURTLE, HEADING, COORDS

     include "fpp.def"

; ****************************************************************************
;
; Move turtle <BC> pixels steps towards the default heading.
;
; If the turtle is not set down, only the current pixel coordinate is updated.
;
; IN:     BC = pixels to move (+/-).
;         IX = pointer to plot routine.
; OUT:    None.
;
;    Registers affected after return:
;         AFBCDEHL/IXIY  same
;         ......../....  different
;
; ---------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ---------------------------------------------------------------------
;
.move               push af
                    push bc
                    push de
                    push hl

                    push bc                  ; preserve move steps
                    push bc

                    call getheading
                    fpp(FP_COS)              ; get COSinus of direction
                    pop  de
                    call multiply            ; COS(heading) * steps
                    call add_point_5         ; + .5
                    fpp(FP_INT)              ; horisontal X direction
                    exx
                    ex   (sp),hl             ; preserve X steps
                    push hl                  ; preserve 2. copy of move steps
                    exx

                    call getheading
                    fpp(FP_SIN)              ; get SINus of direction
                    pop  de
                    call multiply            ; SIN(heading) * steps
                    call add_point_5         ; + .5
                    fpp(FP_INT)              ; vertical Y direction...

                    exx
                    ld   a,(TURTLE)
                    or   a                   ; if (TURTLE is moving)
                    jr   z, update_coords
                         ex   de,hl               ; DE = y direction
                         pop  hl                  ; HL = x direction
                         call line_r              ; draw line ...
                         jr   exit_move      ; else
.update_coords           ex   de,hl               ; y_direction in DE
                         ld   hl,(COORDS)
                         ld   b,h
                         ld   h,0                 ; HL = Y
                         add  hl,de
                         ld   c,l                 ; Y = Y + y_direction
                         ld   h,0
                         ld   l,b                 ; HL = X
                         pop  de                  ; x_direction
                         add  hl,de
                         ld   b,l                 ; X = X + x_direction
                         ld   (COORDS),bc    ; endif

.exit_move          pop  hl
                    pop  de
                    pop  bc
                    pop  af
                    ret


; ****************************************************************************
;
; Get heading in radians
;
.GetHeading         ld   c,0
                    ld   hl,0
                    exx
                    ld   hl,(HEADING)        ; get the heading direction in degrees
                    exx
                    fpp(FP_RAD)              ; convert degrees to radians...
                    ret

; ****************************************************************************
;
; Add .5 to current value in HLhlC
;
.Add_point_5        ld   b,$7F
                    ld   de,0
                    exx
                    ld   de,0
                    exx
                    fpp(FP_ADD)              ; value + .5
                    ret

; ****************************************************************************
;
; Multiply value with <BC>
;
.multiply           push de
                    ld   b,0
                    ld   de,0
                    exx
                    pop  de
                    exx
                    fpp(FP_MUL)              ; value * <BC>
                    ret
