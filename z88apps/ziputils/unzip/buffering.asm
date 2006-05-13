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

; File buffering routines

        module  buffering

include "#fileio.def"
include "data.def"

        xdef    getabyte2,getbufbyte,readbcbytes,skipbcbytes
        xdef    getfpointer,setfpointer,fillbuffer
        xdef    putbyte2,flush,setoutbuf
        xdef    getabyte3

        xref    inf_err,showprogress
        xref    oz_os_mv,oz_os_frm,oz_os_fwm

; Subroutine to skip BC bytes

.skipmorebytes
        call    getbufbyte
        dec     bc
.skipbcbytes
        ld      a,b
        or      c
        jr      nz,skipmorebytes
        ret

; Subroutine to read BC bytes at HL

.readmorebytes
        call    getbufbyte
        ld      (hl),a
        inc     hl
        dec     bc
.readbcbytes
        ld      a,b
        or      c
        jr      nz,readmorebytes
        ret

; Subroutine to get a byte from the input file in A
; All other registers preserved

.getbufbyte
        exx
        ld      a,(hl)
        inc     l
        exx
        ret     nz              ; exit unless at 256-byte boundary
                                ; if so, continue into GETABYTE2

; Subroutine to get next byte from the input buffer
; Use EXX; LD C,(HL); LD B,8; INC L; EXX; CALL Z,GETABYTE2
; Or if in alternate set, use:
;     LD C,(HL); LD B,8; INC L; CALL Z,GETABYTE3

.getabyte2
        push    af
        exx
        inc     h
        ld      a,h
        cp      0+(inbuffer+inbuflen)/$100      ; check if at end of input buffer
        exx
        jr      z,refillit
        pop     af
        ret
.getabyte3
        push    af
        inc     h
        ld      a,h
        cp      0+(inbuffer+inbuflen)/$100
        jr      z,refill2
        pop     af
        ret
.refill2
        exx
        call    fillbuffer
        exx
        pop     af
        ret
.refillit
        pop     af              ; restore regs and enter FILLBUFFER

; Subroutine to re-fill the input buffer

.fillbuffer
        push    af
        push    bc
        push    de
        push    hl
        push    ix
        ld      ix,(inhandle)
        ld      de,inbuffer
        ld      hl,0
        ld      bc,inbuflen
        call    oz_os_mv        ; fill input buffer
        ld      hl,inbuffer
        ld      a,b
        or      c
        jr      z,allread       ; move on if full buffer
        ld      hl,inbuflen
        and     a
        sbc     hl,bc           ; hl=#bytes actually read
        jp      z,inf_err       ; if none, there's a problem
        ld      b,h
        ld      c,l             ; BC=#bytes read
        ld      de,inbuffer-1
        add     hl,de           ; HL=add of last byte read
        ld      de,inbuffer+inbuflen-1  ; DE=end of inbuffer
        lddr                    ; move input to end of buffer
        ex      de,hl
        inc     hl              ; HL=start of input
.allread
        push    hl
        exx
        pop     hl              ; setup HL'
        exx
        pop     ix              ; restore registers
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; Subroutine to output a byte (will be buffered)
; A contains byte (changed), all other registers preserved
; Enter at FLUSH to write remaining output buffer, and
; SETOUTBUF to set it up
; Use EXX; LD (DE),A; INC E; EXX; CALL Z,PUTBYTE2

.putbyte2
        exx
        inc     d
        ld      a,d
        exx
        and     $03
        call    z,showprogress  ; show meter every 1K
        exx
        ld      a,d
        exx
        cp      0+(outbuffer+outbuflen)/$100
        ret     nz              ; exit if don't need to flush
.fullflush
        push    bc
        ld      bc,outbuflen
        ld      a,$ff           ; signal large file
        ld      (bigfile),a
        jr      doflush
.flush  push    bc
        ld      bc,outbuffer
        and     a
        exx
        push    de
        exx
        ex      (sp),hl
        sbc     hl,bc           ; find bytes in buffer
        ex      (sp),hl
        pop     bc              ; BC=bytes to flush
        jr      z,nobytes
.doflush
        push    ix
        push    de
        push    hl
        ld      (flushsize),bc
        ld      ix,(outhandle)
        ld      de,0
        ld      hl,outbuffer
        call    oz_os_mv        ; write buffer
        jp      c,inf_err       ; exit if error
        pop     hl
        pop     de
        pop     ix
.nobytes
        pop     bc
        call    showprogress
.setoutbuf
        exx
        ld      de,outbuffer    ; reset pointer
        exx
        ret

; Subroutine to get the filepointer for the byte next to be read
; from the buffer
; All registers corrupted

.getfpointer
        ld      ix,(inhandle)
        ld      de,0
        ld      a,fa_ptr
        call    oz_os_frm       ; get actual filepointer to DEBC
        push    bc              ; save BC
        exx
        push    hl              ; get buffer address
        exx
        ld      hl,inbuffer+inbuflen
        pop     bc
        and     a
        sbc     hl,bc           ; HL=#bytes in input buffer
        ex      (sp),hl         ; DEHL=filepointer
        pop     bc              ; BC=#bytes in input buffer
        and     a
        sbc     hl,bc
        ex      de,hl
        ld      bc,0
        sbc     hl,bc           ; HLDE contains real filepointer
        ld      (header),de
        ld      (header+2),hl   ; save it
        ret

; Subroutine to set the filepointer to that stored at HEADER,
; refilling buffer from that point

.setfpointer
        ld      ix,(inhandle)
        ld      hl,header
        ld      a,fa_ptr
        call    oz_os_fwm       ; set filepointer
        jp      fillbuffer
