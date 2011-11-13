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

; CRC file checker for Z88
; On entry, IX=file handle (preserved)
; On exit, DEHL=CRC

        module  crc

include "fileio.def"
include "data.def"

        xdef    docrc

        xref    inf_err,oz_os_mv,oz_os_fwm

.docrc  exx                     ; save alternate registers
        push    bc
        push    de
        push    hl
        ld      de,$FFFF        ; initialise CRC register D'E'B'C'
        ld      bc,$FFFF
        exx
        ld      a,(bigfile)
        and     a
        jr      z,smallfile     ; for files<32K, assume in memory
        ld      hl,0
        ld      (seqptr),hl
        ld      (seqptr+2),hl
        ld      hl,seqptr
        ld      a,fa_ptr
        call    oz_os_fwm       ; move to start of file
        jp      c,inf_err       ; exit if any error
        jp      readmore        ; read bytes & start
.smallfile
        ld      hl,outbuffer
        ld      bc,(flushsize)
        ld      a,b
        or      c
        jr      z,crcend        ; exit if zero length file
        jr      crclp
.readmore
        ld      a,(bigfile)
        and     a
        jr      z,crcend        ; move on if none to read
        ld      bc,outbuflen    ; max 32K byte buffer
        ld      de,outbuffer    ; as using output buffer area
        ld      hl,0
        call    oz_os_mv        ; read bytes from file
        ld      hl,outbuflen
        and     a
        sbc     hl,bc
        jr      z,crcend        ; move on if no bytes read
        ld      b,h
        ld      c,l             ; BC=#bytes actually read
        ld      hl,outbuffer
.crclp  ld      a,(hl)          ; get byte
        inc     hl              ; increment address
        dec     bc              ; decrement bytes left
        exx
        xor     c
        ld      l,a
        xor     a
        sla     l
        rla
        sla     l
        rla                     ; AL=4xCRC index byte
        add     a,crctb/$100
        ld      h,a             ; HL=index into CRC table
        ld      a,(hl)
        inc     hl
        xor     b
        ld      c,a             ; shift and XOR 2nd byte to low
        ld      a,(hl)
        inc     hl
        xor     e
        ld      b,a             ; shift and XOR 3rd byte to 2nd
        ld      a,(hl)
        inc     hl
        xor     d
        ld      e,a             ; shift and XOR high byte to 3rd
        ld      d,(hl)          ; get new high byte
        exx
        ld      a,b
        or      c
        jp      nz,crclp        ; back for more
        jp      readmore
.crcend exx
        ld      a,d
        cpl
        ld      d,a             ; complement high byte
        ld      a,e
        cpl
        ld      e,a             ; complement 3rd byte
        ld      a,b
        cpl
        ld      h,a             ; complement 2nd byte
        ld      a,c
        cpl
        ld      l,a             ; complement low byte
        exx                     ; restore alternate registers
        pop     hl
        pop     de
        pop     bc
        exx
        ret                     ; exit with DEHL=CRC
