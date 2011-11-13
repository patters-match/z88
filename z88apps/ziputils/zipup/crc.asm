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


; CRC file checker for Z88
; On exit, DEHL=CRC

        module  crc

include "data.def"

        xdef    docrc

        xref    inf_err,getbufbyte

.docrc  ld      de,$FFFF        ; initialise CRC register DEBC
        ld      bc,$FFFF
.crclp  call    getbufbyte
        jr      z,endcrc        ; exit if no more bytes available
        push    de              ; save registers
        ld      hl,nodefreqs
        ld      e,a
        ld      d,0
        add     hl,de
        add     hl,de           ; HL=address of frequency to increment
        ld      e,(hl)
        inc     hl
        ld      d,(hl)          ; DE=freq
        inc     de              ; increment it
        ld      (hl),d
        dec     hl
        ld      (hl),e          ; and re-save
        pop     de              ; restore registers
        xor     c
        ld      l,a
        xor     a
        sla     l
        rla
        sla     l
        rla             ; AL=4xCRC index byte
        add     a,crctb/$100
        ld      h,a     ; HL=index into CRC table
        ld      a,(hl)
        inc     hl
        xor     b
        ld      c,a     ; shift and XOR 2nd byte to low
        ld      a,(hl)
        inc     hl
        xor     e
        ld      b,a     ; shift and XOR 3rd byte to 2nd
        ld      a,(hl)
        inc     hl
        xor     d
        ld      e,a     ; shift and XOR high byte to 3rd
        ld      d,(hl)  ; get new high byte
        jp      crclp
.endcrc
        ld      a,d
        cpl
        ld      d,a     ; complement high byte
        ld      a,e
        cpl
        ld      e,a     ; complement 3rd byte
        ld      a,b
        cpl
        ld      h,a     ; complement 2nd byte
        ld      a,c
        cpl
        ld      l,a     ; complement low byte
        ret             ; exit with DEHL=CRC
