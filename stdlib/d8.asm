     XLIB d8

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

     include "error.def"

; **************************************************************************************************
;
; Unsigned 8bit division
;
; IN:
;    H = Dividend
;    L = Divisor
;
; OUT:
;    Fc = 0, division completed
;         H = Quotient
;         L = Remainder
;    Fc = 1,
;         A = RC_Dvz (divide by 0)
;
; Registers changed after return:
;    ......./IXIY same
;    AF...HL/.... different
;
.d8
        xor  a
        inc  l
        dec  l
        jr   nz, do_divide
        ld   a, RC_Dvz
        scf
        ret
.do_divide        
        push af
        push bc
        ld   b,8
.div8loop        
        sla  h          ; advancing a bit
        rla             ; ...
        cp   l          ; checking if the divisor divides the digits chosen (in A)
        jr   c,nextbit  ; if not, advance without subtraction
        sub  l          ; subtracting the divisor
        inc  h          ; and setting the next digit of the quotient
.nextbit
        djnz div8loop
        ld   l,a        ; H = quotient, L = remainder
        pop  bc
        pop  af
        ret