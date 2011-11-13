; *************************************************************************************
;
; ZipUp - File archiving and compression utility to ZIP files, (c) Garry Lancaster, 1999-2006
; This file is part of ZipUp.
;
; ZipUp is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; ZipUp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with ZipUp;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

; Huffman table encoding routines

        module  huffmanenc

include "data.def"
include "huffman.def"

        xdef    justify,setupfreq,newfreq,shellsort,genlengths
        xdef    listlengths,addtolist,countcodes
        xdef    copyfreqs,reducefreqs

        xref    clorder

if DEBUG
        xref    oz_gn_sop,oz_os_in
endif


; For the codelength, literal & distance tables usage is as follows for
; each entry:
;               +0 (1)  codelength
;               +1 (2)  during codelength generation: link to next value
;                       after table generation: code
;               +3 (2)  value (not used)


; Subroutine to left justify code entries in the current table

.justify
        ld      hl,(tbstart)    ; get table parameters
        ld      bc,(tbcodes)
.justloop
        ld      a,b
        or      c
        ret     z               ; exit when all entries processed
        ld      a,16
        sub     (hl)            ; A=# bits to shift left by
        inc     hl
        jr      z,noshift       ; move on if none
        ld      e,(hl)
        inc     hl
        ld      d,(hl)          ; DE=code
.justcode
        rl      e               ; shift code left
        rl      d
        dec     a
        jp      nz,justcode
        ld      (hl),d          ; resave code
        dec     hl
        ld      (hl),e
.noshift
        inc     hl              ; move to next entry
        inc     hl
        inc     hl
        inc     hl
        dec     bc
        jp      justloop        ; loop back for more


; Subroutine to generate a blank frequency table (at NODEFREQS),
; containing BC entries.

.newfreq
        ld      hl,nodefreqs
        ld      (hl),0          ; zeroise 1 byte
        ld      de,nodefreqs+1
        push    bc
        dec     bc
        ldir                    ; zeroise BC-1 bytes
        pop     bc
        ldir                    ; zeroise BC bytes (total=BC*2)
        ret

; Subroutine to reduce the frequencies of the last nodes in the table
; to the same as the next least frequent nodes

.reducefreqs
        ld      hl,nodefreqs
        ld      bc,(tbcodes)
        ld      de,$ffff        ; DE=smallest frequency
.findleast
        ld      a,b
        or      c
        jr      z,foundleast    ; move on if found least frequency
        push    bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)          ; BC=current frequency
        inc     hl
        ld      a,b
        or      c
        jr      z,ignz1         ; ignore zero frequencies
        ex      de,hl
        and     a
        sbc     hl,bc           ; test if current is less or equal
        push    af
        add     hl,bc           ; restore current least
        pop     af
        ex      de,hl
        jr      c,ignz1
        ld      d,b             ; set new least
        ld      e,c
.ignz1  pop     bc
        dec     bc
        jr      findleast
.foundleast
        push    de              ; save smallest frequency
        pop     ix              ; to IX
        ld      hl,nodefreqs
        ld      bc,(tbcodes)
        ld      de,$ffff
.find2nd
        ld      a,b
        or      c
        jr      z,found2nd      ; move on if found 2nd least frequency
        push    bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      a,b
        or      c
        jr      z,ignz2         ; ignore zero frequencies
        ex      de,hl
        and     a
        sbc     hl,bc           ; test if current is less or equal
        push    af
        add     hl,bc           ; restore current 2nd least
        pop     af
        ex      de,hl
        jr      c,ignz2
        push    ix
        ex      (sp),hl
        sbc     hl,bc
        pop     hl
        jr      z,ignz2         ; don't set to actual least
        ld      d,b             ; set new 2nd least
        ld      e,c
.ignz2  pop     bc
        dec     bc
        jr      find2nd

; ATP, IX=least and DE=2nd least. We must now set all frequencies matching
; IX to be equal to DE

.found2nd
        ld      hl,nodefreqs-1
        ld      bc,(tbcodes)
.subfreqs
        ld      a,b
        or      c
        ret     z               ; done if reached table end
        push    bc
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        push    ix
        ex      (sp),hl
        and     a
        sbc     hl,bc           ; test for least frequency
        pop     hl
        jr      nz,notleast
        ld      (hl),d          ; update if it is
        dec     hl
        ld      (hl),e
        inc     hl
.notleast
        pop     bc
        dec     bc
        jr      subfreqs


; Subroutine to copy node frequencies into NODETABLE, setting depth to 0
; and child of each entry is set to the node number, starting from 1.
; Node layout is: +0 (1) - depth
;                 +1 (2) - frequency
;                 +3 (2) - link to first child

.copyfreqs
        ld      bc,(tbcodes)
        ld      hl,0
        add     hl,bc
        add     hl,hl
        add     hl,hl
        add     hl,bc
        ld      b,h
        ld      c,l
        dec     bc              ; BC=5*TBCODES-1
        ld      hl,(tbstart)    ; HL=alphabet table start
        ld      d,h
        ld      e,l
        inc     de
        ld      (hl),0
        ldir                    ; clear alphabet table
        ld      hl,nodetable    ; start address
        ld      de,1            ; first node number
        ld      bc,(tbcodes)
        ld      ix,nodefreqs
.newnode
        ld      a,b
        or      c
        ret     z               ; exit when done
        ld      (hl),0          ; zero depth
        inc     hl
        ld      a,(ix+0)
        inc     ix
        ld      (hl),a          ; copy frequency
        inc     hl
        ld      a,(ix+0)
        inc     ix
        ld      (hl),a
        inc     hl
        ld      (hl),e          ; link to child
        inc     hl
        ld      (hl),d
        inc     hl
        inc     de              ; increment node number
        dec     bc
        jp      newnode

; Routine to sort the node table into frequency order.
; On entry, TBCODES holds number of entries
; On exit, IX points to the effective start of the ordered table
; (ignoring any initial zero frequency nodes). A table terminator
; of freq $ffff is stored after the final entry, and the address
; of the last node is stored in NODESEND

.shellsort
        ld      hl,nodetable-5
        ld      bc,(tbcodes)    ; get number of entries
        add     hl,bc
        add     hl,bc
        add     hl,bc
        add     hl,bc
        add     hl,bc
        ld      (nodesend),hl   ; save address of last node
        ld      de,6
        add     hl,de           ; get to freq of dummy end node
        ld      (hl),$ff        ; store table end marker
        inc     hl
        ld      (hl),$ff
        push    hl
        pop     ix              ; IX=list end, indexed to freq MSB
        ld      hl,nodetable+2  ; HL=list start, indexed to freq MSB
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
        jr      c,doswap        ; swap if MSB of first node is larger
        jr      nz,noswap       ; don't swap if MSB of 2nd node is larger
        dec     de
        ld      a,(de)
        inc     de
        dec     hl
        cp      (hl)            ; compare LSBs if MSBs were equal
        inc     hl
        jr      nc,noswap       ; don't swap unless first node LSB is larger
.doswap dec     de              ; index to nodestart+1 (don't bother swapping depths)
        dec     hl
        ld      a,(de)
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
        dec     hl
        dec     hl              ; index HL back to node+2 (frequency MSB)
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
.sorted ld      bc,6
.nextone
        ld      a,(hl)          ; get MSB
        dec     hl
        or      (hl)            ; combine with LSB
        jr      nz,gotone       ; exit when found true table start
        add     hl,bc           ; else move to next entry
        jr      nextone
.gotone dec     hl              ; now HL points to start of first real node
        push    hl
        pop     ix              ; save in IX
        ret

; Subroutine to initialise the frequency table for counting literal codes

.setupfreq
        ld      bc,288
        call    newfreq         ; generate 288-entry frequency table
        ld      a,1
        ld      (nodefreqs+256*2),a     ; set end-of-block code freq
        ret

; Subroutine to increment the codelengths of every child in a chain
; On entry, DE=first child
; On exit, HL=address+1 to place link to new child

.inccls ld      a,d
        or      e
        ret     z               ; exit if end of chain
        dec     de              ; DE=value of child
        ld      hl,(tbstart)    ; get address of table we're using
        add     hl,de
        add     hl,de
        add     hl,de
        add     hl,de
        add     hl,de           ; HL=address of value's table entry
        inc     (hl)            ; increment codelength
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)          ; DE=next child
        jr      inccls

; Subroutine to generate codelengths in the codelength, distance or
; literal table.
; On entry, IX=start of sorted frequency table
; On exit, Fc=1 if max codelength exceeded

.genlengths
        ld      a,(ix+0)        ; get depth of least frequent node
        ld      c,(ix+5)        ; and depth of next l.f.n.
        cp      c
        jr      c,bigdepth
        ld      c,a
.bigdepth
        inc     c               ; C=new depth (max+1)
        ld      (ix+0),c        ; save back in first node
        ld      e,(ix+1)
        ld      d,(ix+2)
        ex      de,hl           ; HL=first freq
        ld      e,(ix+6)
        ld      d,(ix+7)        ; DE=2nd freq
        add     hl,de
        ex      de,hl
        ld      (ix+1),e        ; save combined freq in 1st node
        ld      (ix+2),d
        ld      e,(ix+3)
        ld      d,(ix+4)
        call    inccls          ; inc codelengths in 1st chain
        ld      e,(ix+8)
        ld      d,(ix+9)
        ld      (hl),d          ; link 2nd chain onto 1st
        dec     hl
        ld      (hl),e
        call    inccls          ; inc codelengths in 2nd chain
        push    ix
        pop     hl
        ld      bc,10
        add     hl,bc           ; HL=start of nodelist to scan
        ld      a,(maxdepth)
        cp      (ix+0)
if DEBUG
        JR      NZ,INSNODE      ; insert node unless max depth
        PUSH    HL
        LD      HL,MSG_MAXDEPTH
        CALL    OZ_GN_SOP
        CALL    OZ_OS_IN
        POP     HL
        SCF
        RET
else
        scf                     ; set Fc=1 - max length exceeded
        ret     z               ; and exit if so
endif

; This part of the subroutine inserts the node at IX into the list
; starting at HL.

.insnode
        ld      d,h
        ld      e,l
        dec     de
        dec     de
        dec     de
        dec     de
        dec     de              ; DE=node to overwrite
        ld      bc,5
        ldir                    ; shift node down
        ex      de,hl           ; HL=node we just shifted
        ld      b,(hl)          ; get B=depth
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      a,(hl)          ; and AC=frequency
        cp      (ix+2)
        jr      c,keepgoing     ; if our MSB freq larger, keep trying
        jr      nz,inserthere   ; if our MSB freq lower, this is the place
        ld      a,c
        cp      (ix+1)
        jr      c,keepgoing     ; if our LSB freq larger, keep trying
        jr      nz,inserthere   ; if our LSB freq lower, this is the place
        ld      a,b
        cp      (ix+0)
        jr      nc,inserthere   ; if our depth less/equal, this is it
.keepgoing
        inc     hl
        inc     hl
        inc     hl              ; point to next node to shift down
        jr      insnode         ; loop back
.inserthere
        ld      bc,7
        and     a
        sbc     hl,bc           ; HL=start of newly-copied node to overwrite
        push    ix
        pop     de              ; DE=start of our node
        ex      de,hl
        ld      bc,5
        ldir                    ; insert our node, leaves HL=new start
.checkend
        push    hl
        pop     ix              ; IX=new list start
        ld      de,(nodesend)   ; DE=last real node address
        and     a
        sbc     hl,de
        jp      c,genlengths    ; back for more if still > 1 node
if DEBUG
        PUSH    HL
        LD      HL,MSG_OKDEPTH
        CALL    OZ_GN_SOP
        CALL    OZ_OS_IN
        POP     HL
endif
        ret                     ; else exit with Fc=0 (success)


; Subroutine to create a list of codelengths at IX, from codes in current
; table (TBSTART & TBCODES)
; This also updates the frequencies in NODEFREQS.
; On exit, IX=address after list end

.listlengths
        ld      hl,$ff00        ; H=last value, L=number of matches
        ld      de,(tbstart)    ; get table parameters
        ld      bc,(tbcodes)
.listlenloop
        ld      a,b
        or      c
        jr      z,addsequence   ; add final sequence & exit
        ld      a,(de)          ; get next codelength
        inc     de
        inc     de
        inc     de
        inc     de
        inc     de              ; move to next table entry
        dec     bc              ; decrement count
        cp      h               ; same as last entry?
        jr      nz,nomatch      ; if not move on
        inc     l               ; if so, just increment count
        jr      nz,listlenloop  ; loop back unless got 256 matches!
        push    hl              ; save code
        dec     l
        call    addsequence     ; add it & 255 matches
        pop     hl              ; restore code with 0 extra matches
        jr      listlenloop
.nomatch
        push    af              ; save current entry
        call    addsequence     ; add a sequence of L value H's
        pop     af
        ld      h,a             ; save new match value
        ld      l,0             ; reset number of matches
        jr      listlenloop     ; loop back

; Subroutine to add a sequence of L value H's to the list

.addsequence
        ld      a,h
        and     a
        jr      z,addzeros      ; special case for code zero
        cp      $ff
        ret     z               ; do nothing if this was a dummy code
        call    addtolist       ; add the code to the list
.addnonzeros
        ld      a,l             ; check number of further matches
        and     a
        ret     z               ; exit if none
        cp      3
        jr      nc,code16       ; do a code 16 if 3 matches or more
.dofew  push    bc
        ld      b,a
        ld      a,h
.loopfew
        call    addtolist       ; just output one or two more copies
        djnz    loopfew
        pop     bc
        ret
.code16 ld      a,16
        call    addtolist       ; add a code 16
        ld      a,l
        cp      7
        jr      c,code16end     ; if less than 7 matches left, last go
        ld      (ix+0),3        ; else do 6 matches
        inc     ix
        sub     6
        ld      l,a
        jr      addnonzeros     ; back to do further matches
.code16end
        sub     3
        ld      (ix+0),a        ; store extra bits for code 16
        inc     ix
        ret                     ; finished
.addzeros
        inc     hl              ; HL=total number of zero codes
.morezeros
        push    de              ; save DE
        ex      de,hl           ; DE=total zero codes left
        ld      hl,138
        and     a
        sbc     hl,de
        ex      de,hl
        pop     de
        jr      c,hugematch     ; move on if > 138 zeros
        ld      a,l
        cp      11
        jr      nc,code18       ; move on if code 18 (11-138 zeros)
        cp      3
        jr      c,dofew         ; go to just ouput 1 or 2 single zeros
.code17 ld      a,17
        call    addtolist       ; add a code 17 to the list
        ld      a,l
        sub     3
        ld      (ix+0),a        ; store extra bits
        inc     ix
        ret
.code18 ld      a,18
        call    addtolist       ; add a code 18 to the list
        ld      a,l
        sub     11
        ld      (ix+0),a        ; store extra bits
        inc     ix
        ret
.hugematch
        push    de
        ld      de,138
        and     a
        sbc     hl,de           ; HL=zeros to do after first 138
        pop     de
        push    hl              ; save remaining zeros
        ld      hl,138
        call    code18          ; output a code 18 for the first 138
        pop     hl              ; get remainder
        jr      morezeros       ; loop back for rest

; Subroutine to insert A into list & increment frequency for code
; All registers preserved (IX updated to new list position)

.addtolist
        ld      (ix+0),a        ; insert value into list
        inc     ix
        push    hl              ; save registers
        push    bc
        ld      hl,nodefreqs
        ld      c,a
        ld      b,0
        add     hl,bc
        add     hl,bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)          ; BC=code frequency
        inc     bc              ; increment frequency for this code
        ld      (hl),b
        dec     hl
        ld      (hl),c          ; resave frequency
        pop     bc              ; restore registers
        pop     hl
        ret

; Subroutine to count the number of codelength codes to be sent
; On exit, DE=#codes to send

.countcodes
        ld      bc,clorder+18   ; end of cl order table
        ld      de,19           ; start with 19 to send
.countnext
        ld      a,(bc)          ; get next code
        dec     bc
        push    bc              ; save
        ld      c,a
        ld      b,0
        ld      hl,clalpha
        add     hl,bc           ; HL=address of code's codelength
        pop     bc
        ld      a,(hl)
        and     a
        ret     nz              ; exit on first non-zero codelength
        dec     e
        ld      a,e
        cp      4
        jr      nz,countnext    ; back if not at minimum of 4
        ret

if DEBUG
.MSG_MAXDEPTH   defm    13, 10, "WARNING - maximum depth exceeded!", 7, 0
.MSG_OKDEPTH    defm    13, 10, "Maximum depth not exceeded!", 0
endif
