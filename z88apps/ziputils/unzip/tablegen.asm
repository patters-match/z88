; *************************************************************************************
;
; UnZip - File extraction utility for ZIP files, (c) Garry Lancaster, 1999-2006
; This file is part of UnZip.
;
; UnZip is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; UnZip is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with UnZip;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

; Huffman table generation routines

        module  tablegen

include "data.def"
include "huffman.def"

        xdef    newtable,generate,fixgen

; Routine to set up a blank code table
; On entry, HL=start address, BC=number of codes
; and A=codelength to fill table with (usually 0)
; It also places code==value
; These values are preserved, but A,A',DE corrupted

.newtable
        ld      de,0            ; initial code
        push    bc              ; save values
        push    hl
        ex      af,af'          ; A'=codelength
.blnknew
        ex      af,af'
        ld      (hl),a          ; place code length
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d          ; place code==value
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d          ; place value
        inc     hl              ; hl=next entry
        inc     de              ; de=next value
        dec     bc              ; decrement # codes
        ex      af,af'          ; A'=codelength
        ld      a,b
        or      c
        jr      nz,blnknew      ; back for more
        pop     hl              ; restore values
        pop     bc
        ret                     ; exit

; Routine to count the number of codes for each bit length
; On entry, HL points to the start of the code table,
; and BC holds the number of entries in the code table.
; At this stage, it is assumed that bytes 0 & 3-4 are correct
; for all entries in the table. The value of bytes 1-2 are
; not important. It is also assumed that the values are in
; ascending order.

.generate
        push    hl              ; save registers
        push    bc
        ld      hl,bitlcnts
        ld      d,h
        ld      e,l
        inc     de
        ld      bc,67
        ld      (hl),0
        ldir                    ; erase table of counts
        pop     bc
        pop     hl              ; restore registers
        push    hl              ; and re-save
        push    bc
        ld      d,0
.cntagain
        ld      a,(hl)
        and     a
        jr      z,nozero        ; don't count zero code lengths
        add     a,a
        add     a,a
        ld      e,a             ; DE=bitlength*4
        push    hl              ; save tableadd
        ld      hl,bitlcnts+2
        add     hl,de           ; get to address of count to increment
        inc     (hl)            ; increment low byte
        jr      nz,lowinc       ; move on if no carry
        inc     hl
        inc     (hl)            ; otherwise, increment high byte
.lowinc pop     hl
.nozero ld      e,5
        add     hl,de           ; get to next table entry
        dec     bc
        ld      a,b
        or      c
        jr      nz,cntagain     ; loop back for more

; Routine to set up the "next_code" values for each bit length

.nxtcodes
        ld      de,0            ; set code=0
        ld      hl,bitlcnts+2   ; start at count for bitlength 0
        ld      a,16            ; loop for 16 bits
.nextnc ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl              ; bc=previous count, hl=add to place
        ex      de,hl
        add     hl,bc
        add     hl,hl
        ex      de,hl           ; code=(code+count(bits-1))*2
        ld      (hl),e
        inc     hl
        ld      (hl),d
        inc     hl              ; store code
        dec     a
        jr      nz,nextnc       ; back for more

; Routine to assign numerical values to all codes. Codes with a
; bit length of zero will not be assigned a value.

        pop     bc              ; restore registers from
        pop     hl              ; previous routine
        push    hl              ; and re-save
        push    bc
.assignco
        ld      a,(hl)          ; get bit length of code
        inc     hl
        push    hl              ; save address
        and     a
        jr      z,skipcode      ; don't assign value if bl=0
        add     a,a
        add     a,a
        ld      e,a
        ld      d,0             ; de=4*bitlength
        ld      hl,bitlcnts
        add     hl,de           ; hl=address of next code value
        ld      e,(hl)
        inc     hl
        ld      d,(hl)          ; get "next code"
        ex      (sp),hl
        ld      (hl),e
        inc     hl
        ld      (hl),d          ; place in code table
        dec     hl
        ex      (sp),hl
        inc     de
        ld      (hl),d
        dec     hl
        ld      (hl),e          ; store back increased code
.skipcode
        pop     hl              ; restore table address
        ld      de,4
        add     hl,de           ; move to next entry
        dec     bc
        ld      a,b
        or      c
        jr      nz,assignco     ; loop back for more
        pop     bc              ; restore registers
        pop     hl
        ret

; Routine to generate Lit/length & distance code tables for fixed
; length Huffman codes. Leaves sorted in value order.

.fixgen ld      hl,llalpha
        ld      bc,288
        ld      a,8
        call    newtable        ; generate table with all 8bit cls
        ld      hl,llalpha+(144*5)      ; get to code 144 cl
        ld      de,5
        ld      a,112           ; fill 112 entries with 9bit cl
.fill9  ld      (hl),9
        add     hl,de
        dec     a
        jr      nz,fill9
        ld      a,24            ; fill 24 entries with 7bit cl
.fill7  ld      (hl),7
        add     hl,de
        dec     a
        jr      nz,fill7
        ld      hl,llalpha
        call    generate        ; generate lit/length code table
        ld      hl,dsalpha
        ld      bc,32
        ld      a,5
        call    newtable        ; generate distance code table
        call    generate
        ret
