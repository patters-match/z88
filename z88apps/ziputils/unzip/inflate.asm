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
; $Id$
;
; *************************************************************************************

; INFLATE routines for Z80
; Code tables are arranged as 5 bytes per code, as follows:
;  bytes   0: code bit length
;  bytes 1-2: code (LSB first)
;  bytes 3-4: value (LSB first)

        module  inflate

include "error.def"
include "data.def"
include "huffman.def"

        xdef    inflate,getbits,decodev

        xref    getbufbyte,getabyte2,putbyte2,inf_err
        xref    getabyte3,dynread,fixgen,shellsort,lenextra,dstextra

; Main decompression routine

.inflate
        ld      a,3
        call    getbits         ; read block header
        ld      a,e             ; get A=header
        srl     a               ; shift "last block" flag to carry
        push    af              ; and save it
        and     a
        jp      z,block00       ; jump for block 00
        dec     a
        jr      z,block01       ; jump for block 01
        dec     a
        jp      nz,codeerr      ; error if not block 10
.block10
        call    dynread         ; read dynamic Huffman codes
        jr      loopdcmp
.block01
        call    fixgen          ; generate fixed Huffman codes
        ld      hl,llalpha
        ld      bc,288
        call    shellsort       ; sort the lit/length table
        ld      (llstart),ix
        ld      hl,dsalpha
        ld      bc,32
        call    shellsort       ; sort the distance table
        ld      (dsstart),ix
.loopdcmp
        ld      hl,(llstart)

; For speed, a copy of the DECODEV
; routine is inserted here
.Ldecodev
        ld      de,0            ; start with code=0
        ld      b,0             ; and codelength=0
.Ldecagain
        ld      a,(hl)
        inc     hl
        ld      c,a             ; save new codelength
        sub     b
        jr      z,Lnomoreh      ; move on if no more bits needed
        jr      c,Lnomoreh      ; error if end of table
        exx                     ; switch to alt (buffer) set
.Lmorehbit
        rr      c               ; rotate bit in
        exx
        rl      e
        rl      d
        exx
        dec     b               ; decrement bits left
        jp      nz,Lsamebyte2
        ld      c,(hl)
        ld      b,8
        inc     l
        call    z,getabyte3     ; get another byte if required
.Lsamebyte2
        dec     a
        jp      nz,Lmorehbit    ; back for more bits
        exx                     ; switch back to normal set
.Lnomoreh
        ld      b,(hl)          ; get code from table
        inc     hl
        ld      a,(hl)
        inc     hl
        cp      d
        jr      nz,Lnotdecoded
        ld      a,b
        cp      e
        jr      z,Ldecoded
.Lnotdecoded
        inc     hl              ; skip value
        inc     hl
        ld      b,c             ; get codelength
        jp      Ldecagain       ; and loop back
.Ldecoded
        ld      e,(hl)          ; de=decoded value
        inc     hl
        ld      d,(hl)
                                ; end of DECODEV copy
        ld      a,d
        and     a
        jr      nz,dolength     ; move on if 256+
        ld      a,e
        exx
        ld      (de),a          ; place literal in output stream
        inc     e
        exx
        call    z,putbyte2
        jp      loopdcmp        ; and loop back
.endblock
        pop     af              ; restore last block flag
        jp      nc,inflate      ; loop back for more blocks
        ret                     ; exit
.dolength
        xor     1
        or      e               ; set Z if D=1 and E=0
        jr      z,endblock
.dodist ld      hl,lenextra-(3*257)
        add     hl,de
        add     hl,de
        add     hl,de           ; hl=address of extra bits etc
        ld      a,(hl)
        call    getbits         ; get extra bits required
        inc     hl
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        add     hl,de           ; hl=length (3-258)
        push    hl              ; save length
        ld      hl,(dsstart)
        call    decodev         ; decode a distance
        ld      hl,dstextra
        add     hl,de
        add     hl,de
        add     hl,de           ; hl=address of extra bits etc
        ld      a,(hl)
        call    getbits         ; get extra bits required
        inc     hl
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
        add     hl,de           ; hl=distance (1-32768)
        pop     bc              ; get length
        ex      de,hl           ; de=distance
        exx
        push    de
        exx
        pop     hl
        and     a
        sbc     hl,de           ; get to position in output stream
        ld      a,h
        cp      outbuffer/$100  ; check if wraps
        jr      c,doeswrap
        cp      0+(outbuffer+outbuflen)/$100
        jr      c,copyloop
.doeswrap
        add     a,outbuflen/$100
        ld      h,a             ; now in correct position
.copyloop
        ld      a,(hl)          ; get next byte from buffer
        exx
        ld      (de),a          ; output it
        inc     e
        exx
        call    z,putbyte2
        inc     l
        jp      nz,samepage
        inc     h
        ld      a,h
        cp      0+(outbuffer+outbuflen)/$100
        jp      nz,samepage
        ld      h,outbuffer/$100
.samepage
        dec     bc
        ld      a,b
        or      c
        jp      nz,copyloop
        jp      loopdcmp        ; jump back
.block00
        call    getbufbyte
        ld      e,a
        call    getbufbyte
        ld      d,a             ; DE=block length
        call    getbufbyte
        cpl
        cp      e
        jp      nz,codeerr      ; error if bad NLEN
        call    getbufbyte
        cpl
        cp      d
        jp      nz,codeerr      ; error if bad NLEN
.storeloop
        exx
        ld      a,(hl)          ; get byte
        inc     l
        call    z,getabyte3
        ld      (de),a          ; put in output buffer
        inc     e
        exx
        call    z,putbyte2
        dec     de              ; decrement count
        ld      a,d
        or      e
        jp      nz,storeloop    ; back for more
        exx
        ld      c,(hl)          ; refill bit buffer
        ld      b,8
        inc     l
        exx
        call    z,getabyte2
        jp      endblock        ; back for more blocks


; Now the GETBITS subroutine
; This gets A bits into DE from the input stream

.getbits
        ld      d,a
        ld      e,a
        and     a
        ret     z               ; exit with DE=0 if A=0
        ld      de,32768        ; flag bit 15
        exx                     ; switch to alt (buffer) set
.morebits
        rr      c               ; rotate bit in
        exx
        rr      d
        rr      e
        exx
        dec     b
        jp      nz,samebyte
        ld      c,(hl)
        ld      b,8
        inc     l
        call    z,getabyte3
.samebyte
        dec     a
        jp      nz,morebits     ; back for more
        exx                     ; switch back to normal set
.reshift
        srl     d               ; shift value to bottom of DE
        rr      e
        jp      nc,reshift      ; until flag drops out
        ret

; The DECODEV subroutine
; Using table HL, this decodes a value from the input stream,
; returned in DE. No registers are preserved

.decodev
        ld      de,0            ; start with code=0
        ld      b,0             ; and codelength=0
.decagain
        ld      a,(hl)
        inc     hl
        ld      c,a             ; save new codelength
        sub     b
        jr      z,nomoreh       ; move on if no more bits needed
        jr      c,nomoreh       ; error if end of table
        exx                     ; switch to alt (buffer) set
.morehbit
        rr      c               ; rotate bit in
        exx
        rl      e
        rl      d
        exx
        dec     b               ; decrement bits left
        jp      nz,samebyte2
        ld      c,(hl)
        ld      b,8
        inc     l
        call    z,getabyte3     ; get another byte if required
.samebyte2
        dec     a
        jp      nz,morehbit     ; back for more bits
        exx                     ; switch back to normal set
.nomoreh
        ld      b,(hl)          ; get code from table
        inc     hl
        ld      a,(hl)
        inc     hl
        cp      d
        jr      nz,notdecoded
        ld      a,b
        cp      e
        jr      z,decoded
.notdecoded
        inc     hl              ; skip value
        inc     hl
        ld      b,c             ; get codelength
        jp      decagain        ; and loop back
.decoded
        ld      e,(hl)          ; de=decoded value
        inc     hl
        ld      d,(hl)
        ret                     ; done

; If an error in the ZIP file has been found
.codeerr
        ld      a,rc_ovf        ; use "Overflow" error
        jp      inf_err ; do it
