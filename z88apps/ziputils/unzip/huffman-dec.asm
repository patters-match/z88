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

; Huffman decoding routines

        module  huffman

include "data.def"
include "huffman.def"

        xdef    dynread,shellsort

        xref    clorder,newtable,generate,getbits,decodev

; Routine to sort the code table into bit length order.
; On entry, HL holds table start and BC holds number of entries
; On exit, IX points to the effective start of the ordered table
; (ignoring any initial zero bit length codes). A table terminator
; of zero is stored after the final entry.

.shellsort
        push    hl
        add     hl,bc
        add     hl,bc
        add     hl,bc
        add     hl,bc
        add     hl,bc
        ld      (hl),0          ; store table end marker
        ex      (sp),hl
        pop     ix              ; IX=list end, HL=list start
.sortloop
        srl     b               ; halve distance
        rr      c
        ld      a,b
        or      c
        jr      z,sorted        ; finished sorting
        push    hl              ; save list start
        push    bc              ; and distance
        ld      d,h
        ld      e,l             ; DE=list start
        add     hl,bc
        add     hl,bc
        add     hl,bc
        add     hl,bc
.sortloop2
        add     hl,bc           ; HL=list middle
        ex      de,hl
        ld      (listptr),hl    ; save list pointers
        ld      (listptr+2),de
.moreswaps
        ld      a,(de)
        cp      (hl)            ; compare items
        jr      nc,noswap
        ld      b,(hl)          ; swap items if required
        ld      (hl),a
        ld      a,b
        ld      (de),a
        inc     de
        inc     hl
        ld      a,(de)          ; swap 2nd byte
        ld      b,(hl)
        ld      (hl),a
        ld      a,b
        ld      (de),a
        inc     de
        inc     hl
        ld      a,(de)          ; swap 3rd byte
        ld      b,(hl)
        ld      (hl),a
        ld      a,b
        ld      (de),a
        inc     de
        inc     hl
        ld      a,(de)          ; swap 4th byte
        ld      b,(hl)
        ld      (hl),a
        ld      a,b
        ld      (de),a
        inc     de
        inc     hl
        ld      a,(de)          ; swap 5th byte
        ld      b,(hl)
        ld      (hl),a
        ld      a,b
        ld      (de),a
        dec     hl
        dec     hl
        dec     hl
        dec     hl
        ld      d,h
        ld      e,l
        pop     bc              ; BC=distance
        and     a
        sbc     hl,bc
        sbc     hl,bc
        sbc     hl,bc
        sbc     hl,bc
        sbc     hl,bc
        ex      de,hl
        ex      (sp),hl
        push    hl
        dec     hl
        and     a
        sbc     hl,de
        pop     hl
        ex      (sp),hl
        push    bc
        ex      de,hl
        jr      c,moreswaps
.noswap ld      hl,(listptr)    ; restore listpointers
        ld      de,(listptr+2)
        ld      bc,5            ; move to next entries
        add     hl,bc
        ex      de,hl
        add     hl,bc
        push    ix
        pop     bc
        and     a
        sbc     hl,bc           ; test for table end
        jr      c,sortloop2     ; back if not
        pop     bc              ; restore registers
        pop     hl
        jp      sortloop        ; loop back
.sorted ld      bc,5
.nextone
        ld      a,(hl)
        and     a
        jr      nz,gotone       ; exit when found true table start
        add     hl,bc           ; else move to next entry
        jr      nextone
.gotone push    hl
        pop     ix
        ret

; Routine to read the encoded Literal/Length & Distance code
; block for dynamic Huffman codes

.dynread
        ld      hl,0
        ld      (lastclv),hl    ; zeroise repeat values
        ld      hl,clalpha
        ld      bc,19
        xor     a
        call    newtable        ; set up codelength code table
        ld      a,5
        call    getbits
        ld      b,e             ; B=# of literal/length codes-257
        ld      a,5
        call    getbits
        ld      c,e             ; C=# of distance codes-1
        push    bc              ; save # length/lit & distance codes
        ld      a,4
        call    getbits
        ld      a,e
        add     a,4
        ld      b,a             ; B=# of codelength codes
        ld      ix,clorder      ; IX=cl order table start
.morecls
        ld      a,3
        call    getbits         ; get next code length codelength
        ld      a,e
        ld      e,(ix+0)        ; get offset to place in table
        ld      hl,clalpha
        add     hl,de
        ld      (hl),a          ; place code length codelength
        inc     ix              ; step to next offset
        djnz    morecls         ; back for rest of cl codelengths
        ld      hl,clalpha
        ld      bc,19
        call    generate        ; generate the code table for cls
        call    shellsort       ; sort the table
        pop     bc              ; B=#lit/length codes-257
        push    bc              ; resave counts
        ld      c,b
        ld      b,0
        ld      hl,257
        add     hl,bc
        ld      b,h
        ld      c,l             ; BC=#lit/length codes
        ld      hl,llalpha      ; HL=start of lit/length table
        call    decalpha
        ld      (llstart),hl
        pop     bc              ; C=#distance codes-1
        inc     c
        ld      b,0             ; BC=#distance codes
        ld      hl,dsalpha      ; HL=start of distance alphabet
        call    decalpha
        ld      (dsstart),hl
        ret                     ; exit

; Routine to decode a lit/length or distance alphabet, using the code
; length alphabet
; On entry, IX=start of codelength table (preserved),
; HL=start of lit/length table (on exit=effective start)
; BC=number of codes

.decalpha
        push    ix              ; save registers
        push    hl
        push    bc
        xor     a
        call    newtable        ; create blank table
        ld      de,(lastclv)    ; D=repeats left, E=last value
.decalph2
        ld      a,d
        and     a               ; check if any repeats left
        jr      z,getnewval
.dorepeat
        dec     d               ; decrement repeats
        ld      a,e             ; get value
        jr      gotaval
.getnewval
        push    de
        push    bc
        push    hl
        push    ix
        pop     hl              ; get HL=table start
        push    hl
        call    decodev         ; decode a value
        pop     ix
        pop     hl
        pop     bc
        ld      a,e
        and     15
        cp      e
        jr      nz,repvals      ; move on if 16-18 (=repeats)
        pop     de              ; discard old value
        ld      e,a             ; new "last" value
        ld      d,0             ; zeroise repeats
.gotaval
        ld      (hl),a          ; store codelength
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl              ; HL points to next entry
        dec     bc
        ld      a,b
        or      c
        jr      nz,decalph2     ; back for more codes
        ld      (lastclv),de    ; save repeat info
        pop     bc
        pop     hl
        call    generate        ; generate code table
        call    shellsort
        ex      (sp),ix         ; IX=start of codelength table
        pop     hl              ; HL=start of generated table
        ret                     ; exit
.repvals
        push    af              ; save A
        add     a,2             ; A=2/3/4
        cp      4
        jr      nz,not18        ; skip if was code 18
        ld      a,7             ; else get 7 bits
.not18  call    getbits         ; get additional bits
        pop     af
        and     a
        jr      nz,copy0s       ; move on if codes 17/18
        ld      a,e
        add     a,3             ; A=number of times to copy value
        pop     de              ; restore last code
        ld      d,a             ; D=# repeats
        jr      dorepeat
.copy0s cp      2               ; check if val 18 or 17
        ld      a,e             ; A=bits to add
        jr      z,was18
        add     a,3             ; times=3-10 for code 17
        jr      copy0s2
.was18  add     a,11            ; times=11-138 for code 18
.copy0s2
        pop     de
        ld      d,a             ; D=# repeats
        ld      e,0             ; value=zero
        jp      dorepeat

