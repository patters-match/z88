
; **************************************************************************************************
; This file is part of the Z88 operating system, OZ
;
; OZ is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; OZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************


;***************************************************************************************************
; Bind bank, defined in B, into segment C. Return old bank binding in B.
; This is the functional equivalent of original OS_MPB, but much faster.
;
;    Register affected on return:
;         AF.CDEHL/IXIY same
;         ..B...../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1997
; ----------------------------------------------------------------------
;
.MemDefBank
        push hl
        push af

        ld   a,c                                ; get segment specifier ($00, $01, $02 and $03)
        and  @00000011
        or   $d0
        ld   h,$04
        ld   l,a                                ; BC points at Blink soft copy of current binding in segment C

        ld   a,(hl)                             ; get bound bank number in current segment
        cp   b
        jr   z, already_bound                   ; bank B already bound into segment

        push bc
        ld   (hl),b                             ; A contains "old" bank number
        ld   c,l
        out  (c),b                              ; bind...

        pop  bc
        ld   b,a                                ; return previous bank binding
.already_bound
        pop  af
        pop  hl
        ret


;***************************************************************************************************
;
; Get current Bank binding for specified segment MS_Sx, defined in C.
; This is the functional equivalent of OS_MGB, but much faster.
;
;    Register affected on return:
;         AF.CDEHL/IXIY same
;         ..B...../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, 1997
; ----------------------------------------------------------------------
;
.MemGetBank
        push af
        push hl

        ld   a,c                                ; get segment specifier ($00, $01, $02 and $03)
        and  $03                                ; preserve only segment specifier...
        or   $d0                                ; Bank bindings from address $04D0
        ld   h,$04
        ld   l,a                                ; HL points at Blink soft copy of current binding in segment C
        ld   b,(hl)                             ; get current bank binding

        pop  hl
        pop  af
        ret
