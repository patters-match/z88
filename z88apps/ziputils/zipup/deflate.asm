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
; $Id$
;
; *************************************************************************************


; Deflation routines

        module  deflate

include "error.def"
include "data.def"
include "huffman.def"

        xdef    deflate

        xref    justify,shellsort,genlengths,generate
        xref    newfreq,listlengths,addtolist,countcodes,clorder
        xref    reducefreqs,copyfreqs
        xref    getbufbyte,putbyte2,putbyte3,inf_err

        xref    oz_os_in,oz_gn_sop,oz_gn_pdn

; Subroutine to send the header for dynamic blocks
; On exit, DE=number of codelength codes to send

.dynhead
        ld      e,@101          ; last block, dynamic codes
        ld      b,3
        call    putvalue
        ld      e,0             ; 257+0=257 literal codes
        ld      b,5
        call    putvalue
        ld      e,0             ; 1+0=1 distance codes
        ld      b,5
        call    putvalue
        call    countcodes      ; get E=#codelength codes to send
        push    de              ; save them
        ld      a,e
        sub     4
        ld      e,a
        ld      b,4
        call    putvalue        ; output number of codelength codes-4
        pop     de
        ret

; Subroutine to send the codelength table codelengths.
; On entry, DE=number of codelengths to send

.sendclcls
        ld      hl,clorder      ; start of codelength order table
.nextclcl
        ld      c,(hl)
        inc     hl
        ld      b,0             ; BC=offset into codelength table
        push    hl
        push    de
        ld      hl,clalpha
        add     hl,bc
        ld      e,(hl)          ; get codelength
        ld      b,3
        call    putvalue        ; send it
        pop     de              ; restore registers
        pop     hl
        dec     de
        ld      a,d
        or      e
        jr      nz,nextclcl     ; back for more
        ret

; Subroutine to send the literal/length and distance codelengths
; On entry, DE=end of list+1

.sendcls
        ld      hl,cllist       ; start of list
.nextcl
        ld      a,(hl)          ; get next byte
        push    de              ; save end of list
        push    hl              ; save address
        and     a
        sbc     hl,de           ; test for end
        jr      nc,endclsend
        cp      16
        jr      nc,sendclextra  ; move on if sending extra bits too
        ld      e,a
        call    encodelen       ; encode and output
.nextcl2
        pop     hl
        inc     hl              ; next byte
        pop     de
        jr      nextcl
.endclsend
        pop     hl              ; restore regs and exit
        pop     de
        ret
.sendclextra
        ld      e,a
        call    encodelen       ; send the code 16/17/18
        pop     hl
        ld      a,(hl)          ; get code again
        inc     hl
        ld      e,(hl)          ; and extra bits
        push    hl
        ld      b,2
        cp      16
        jr      z,sendit        ; if code 16, 2 extra bits
        ld      b,3
        cp      17
        jr      z,sendit        ; if code 17, 3 extra bits
        ld      b,7             ; if code 18, 7 extra bits
.sendit call    putvalue        ; send the extra bits
        jr      nextcl2


; The Deflate method

.deflate
        exx
        ld      b,8             ; set up bitbuffer
        exx
        ld      hl,288          ; store parameters for lit/length table
        ld      (tbcodes),hl
        ld      hl,llalpha
        ld      (tbstart),hl
        ld      a,15
        ld      (maxdepth),a    ; maximum bitlength for lit/lengths
.redolits
        call    copyfreqs       ; copy the frequencies
        call    shellsort       ; sort the literal frequency table
        call    genlengths      ; generate the codelengths for literals
        jr      nc,litclsok
        call    reducefreqs
        jr      redolits

.litclsok
        call    generate        ; generate the literal alphabet
        call    justify         ; justify the lit/length alphabet

        ld      bc,19
        call    newfreq         ; generate 19-entry frequency table

        ld      ix,cllist
        ld      hl,257          ; only need send 257 literals as a minimum
        ld      (tbcodes),hl
        call    listlengths     ; generate list of codelengths
        ld      a,1
        call    addtolist       ; 1 for the single (required) distance
        push    ix              ; save end of codelength list
if DEBUG
        CALL    DISPLIST
endif
        ld      hl,19           ; store parameters for codelength alphabet
        ld      (tbcodes),hl
        ld      hl,clalpha
        ld      (tbstart),hl
        ld      a,7
        ld      (maxdepth),a    ; max bitlength for codelengths
.redocls
        call    copyfreqs
        call    shellsort       ; sort the codelength frequencies
if DEBUG
        CALL    DISPNODES
endif
        call    genlengths      ; generate codelengths for codelengths
        jr      nc,clclsok
        call    reducefreqs
        jr      redocls
.clclsok
        call    generate        ; generate the codelength alphabet
if DEBUG
        CALL    DISPCLS
endif
        call    justify         ; and justify it

        call    dynhead         ; send the header for dynamic blocks
        call    sendclcls       ; send the codelength codelengths
        pop     de              ; restore end of codelength list
        call    sendcls         ; send the lit/length and distance cls
.defloop
        call    getbufbyte      ; get next byte from file
        jr      z,endblock      ; move on if none left
        ld      l,a
        ld      h,0
        call    encodelit       ; encode a literal
        jp      defloop         ; loop back for more
.endblock
        ld      hl,256
        call    encodelit       ; encode end-of-block literal 256
        exx
        ld      a,b             ; check bit buffer
        exx
        cp      8
        ret     z               ; exit if no bits in bit buffer
        exx
.flushbits
        srl     c
        djnz    flushbits
.got8bits
        ld      (hl),c          ; put into output buffer
        inc     l
        ld      b,8
        exx
        call    z,putbyte2
        ret

; Subroutine to encode literal HL and output to bitstream

.encodelit
        ld      e,l
        ld      d,h             ; DE,HL=literal to encode
        push    hl
        add     hl,hl
        add     hl,hl
        add     hl,de           ; HL=5*literal
        ld      de,llalpha
        add     hl,de           ; HL=table entry
        ld      b,(hl)          ; B=bits
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)          ; DE=code
        pop     hl
        ld      a,b
        and     a
if DEBUG
        JR      Z,ENCERROR1
else
        jr      z,puterror
endif
        jp      putbits         ; go to output code
if DEBUG
.encerror1
        ld      b,h
        ld      c,l
        ld      hl,msg_encerror1
        call    dispnum
        jr      puterror

.MSG_ENCERROR1
        defm    13, 10, "Error encoding literal:", 0
.MSG_ENCERROR2
        defm    13, 10, "Error encodeing codelength:", 0
endif

; Subroutine to encode codelength E and output to bitstream

.encodelen
        ld      d,0
        ld      h,d
        ld      l,e
        push    hl
        add     hl,hl
        add     hl,hl
        add     hl,de           ; HL=5*codelength
        ld      de,clalpha
        add     hl,de           ; HL=table entry
        ld      b,(hl)          ; B=bits
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)          ; DE=code
        POP     HL
        LD      A,B
        AND     A
if DEBUG
        JR      Z,ENCERROR2
else
        jr      z,puterror
endif
        jp      putbits         ; go to output code
if DEBUG
.encerror2
        ld      b,h
        ld      c,l
        ld      hl,msg_encerror2
        call    dispnum
        jr      puterror
endif

; Subroutine to send a B-bit code stored left-justified in DE to the
; output file

.putbits
        ld      a,b
        and     a
        jr      z,puterror      ; error if trying to output zero bits
.putloop
        rl      e
        rl      d
        exx
        rr      c               ; rotate into bit buffer
        djnz    nextbit         ; move on unless full
        ld      b,8             ; signal empty
        ld      (hl),c          ; store byte
        inc     l
        call    z,putbyte3
.nextbit
        exx
        djnz    putloop
        ret
.puterror
        ld      a,rc_ovf
        jp      inf_err

; Subroutine to output a value in DE length B bits to the output stream

.putvalue
        ld      a,b
        or      c
        jr      z,puterror      ; error if trying to send no bits
if DEBUG
        push    bc
        push    de
        push    hl
        ld      hl,msg_putting
        ld      b,d
        ld      c,e
        call    dispnum
        call    oz_os_in
        pop     hl
        pop     de
        pop     bc
endif
.putvloop
        rr      d
        rr      e
        exx
        rr      c               ; rotate into bit buffer
        djnz    nextvbit        ; move on unless full
        ld      b,8             ; signal empty
        ld      (hl),c          ; store byte
        inc     l
        call    z,putbyte3
.nextvbit
        exx
        djnz    putvloop
        ret

if DEBUG
; DEBUGGING subroutines

; Subroutine to display message in HL followed by number in BC
; No registers preserved

.dispnum
        call    oz_gn_sop
        ld      de,ascnumber
        ld      hl,2
        ld      a,1
        call    oz_gn_pdn
        xor     a
        ld      (de),a
        ld      hl,ascnumber
        call    oz_gn_sop
        ret

; Subroutine to display sorted nodelist starting at IX
; All registers preserved

.dispnodes
        push    af              ; save registers
        push    bc
        push    de
        push    hl
        push    ix
.dispnloop
        ld      c,(ix+1)
        ld      b,(ix+2)        ; BC=frequency
        ld      a,b
        and     c
        inc     a
        jr      z,enddispnodes  ; exit if BC=$ffff
        push    bc              ; save frequency
        ld      c,(ix+3)
        ld      b,(ix+4)
        dec     bc              ; BC=value (initial child)
        ld      hl,msg_value
        call    dispnum         ; show value
        pop     bc
        ld      hl,msg_freq
        call    dispnum         ; and frequency
        call    oz_os_in        ; wait for key
        ld      bc,5
        add     ix,bc           ; next node
        jr      dispnloop
.enddispnodes
        pop     ix              ; restore registers
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

.msg_putting    defm    13, 10, "Putting value:", 0
.msg_value      defm    13, 10, "Value:", 0
.msg_freq       defm    ", Frequency:", 0
.msg_codelen    defm    ", Code length:", 0
.msg_code       defm    ", Code:", 0
.msg_list       defm    "Codelength list:", 0
.msg_comma      defm    ", ", 0
.msg_bitlength  defm    13, 10, "Bitlength:", 0
.msg_bitcount   defm    ", Count:", 0
.msg_bitcode    defm    ", Next code:", 0

; Subroutine to display non-zero codelengths in alphabet

.dispcls
        push    af
        push    bc
        push    de
        push    hl
        ld      de,(tbstart)
        ld      bc,(tbcodes)
.dispclloop
        ld      a,(de)          ; get next code length
        inc     de
        and     a
        jr      z,nodispcl
        ld      hl,(tbcodes)    ; get number of codes in alphabet
        and     a
        sbc     hl,bc           ; HL=literal value
        push    bc              ; save registers
        push    de
        push    af              ; save code length
        ld      b,h
        ld      c,l
        ld      hl,msg_value
        call    dispnum
        pop     af
        ld      b,0
        ld      c,a
        ld      hl,msg_codelen
        call    dispnum
        pop     de
        push    de
        ld      a,(de)
        ld      c,a
        inc     de
        ld      a,(de)
        ld      b,a             ; BC=code
        ld      hl,msg_code
        call    dispnum
        call    oz_os_in
        pop     de
        pop     bc
.nodispcl
        inc     de
        inc     de
        inc     de
        inc     de
        dec     bc
        ld      a,b
        or      c
        jr      nz,dispclloop
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; Subroutine to display the codelength list (ending prior to IX)
; All registers preserved

.displist
        push    af
        push    bc
        push    de
        push    hl
        push    ix
        ld      bc,cllist       ; start of list
        ld      hl,msg_list
.dlloop pop     de
        push    de              ; DE=list end+1
        ex      de,hl
        and     a
        sbc     hl,bc
        jr      z,finlist       ; exit if finished
        ex      de,hl
        ld      a,(bc)          ; get next value
        inc     bc
        push    bc
        ld      c,a
        ld      b,0
        call    dispnum
        pop     bc
        ld      hl,msg_comma
        jr      dlloop
.finlist        pop     ix
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret
endif
