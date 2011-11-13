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


; File buffering routines

        module  buffering

include "fileio.def"
include "data.def"

        xdef    newinput,resetinput,getbufbyte
        xdef    putbufbyte,putbyte2,putbyte3,flush,setoutbuf,outbytes

        xref    inf_err,showprogress
        xref    oz_os_mv,oz_os_frm,oz_os_fwm

; Subroutine to reset the input buffer

.resetinput
        exx
        ld      de,(lastfill)
        dec     de              ; last fill address-1
        exx
        ld      a,(filled)
        cp      1
        ret     z               ; exit if filled once & once only, else
                                ; continue to new input

; Subroutine to set up input buffer to accept new input

.newinput
        exx
        ld      de,inbuffer+inbuflen-1  ; set to end of buffer-1
        exx
        push    ix
        ld      ix,(inhandle)
        ld      hl,0
        ld      (seqptr),hl
        ld      (seqptr+2),hl
        ld      hl,seqptr
        ld      a,fa_ptr
        call    oz_os_fwm       ; set input handle to file start
        xor     a
        ld      (filled),a      ; input buffer not filled yet
        pop     ix
        ret                     ; when input is attempted, file will be read


; Subroutine to get a byte from the input file in A
; All other registers preserved. Z flag set if byte was not available

.getbufbyte
        exx
        inc     e
        jr      z,getabyte2     ; move on if at 256 byte boundary
        ld      a,(de)          ; else get byte
        exx
        ret                     ; exit with Z reset
.getabyte2
        inc     d
        ld      a,d
        exx
        and     $03
        call    z,showprogress  ; update progress meter every 1K
        exx
        ld      a,d
        cp      0+(inbuffer+inbuflen)/$100      ; check if at end of input buffer
        jr      z,refillit      ; refill buffer if so
        ld      a,(de)          ; else get byte
        exx
        ret                     ; exit with Z reset
.refillit
        exx
        push    bc              ; save registers
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
        jr      z,not_avail     ; if none, go to exit with Z set
        ld      b,h
        ld      c,l             ; BC=#bytes read
        ld      de,inbuffer-1
        add     hl,de           ; HL=add of last byte read
        ld      de,inbuffer+inbuflen-1  ; DE=end of input buffer
        lddr                    ; move input to end of buffer
        ex      de,hl
        inc     hl              ; HL=start of input
.allread
        push    hl
        exx
        pop     de              ; setup DE'
        ld      (lastfill),de   ; save it
        ld      a,(filled)
        inc     a
        ld      (filled),a      ; increment # of times buffer filled
        or      $ff             ; reset Z flag, as data was available
        ld      a,(de)          ; get a byte
        exx
.not_avail
        pop     ix              ; restore registers
        pop     hl
        pop     de
        pop     bc
        ret

; Subroutine to output BC bytes from address HL

.outbytes
        ld      a,b
        or      c
        ret     z               ; exit if none left
        ld      a,(hl)          ; get next
        exx
        ld      (hl),a          ; output it
        inc     l
        exx
        call    z,putbyte2
        inc     hl
        dec     bc
        jp      outbytes        ; back for more

; Subroutine to output a byte (will be buffered)
; A contains byte (changed), all other registers preserved
; Enter at FLUSH to write remaining output buffer, and
; SETOUTBUF to set it up
; Use EXX; LD (HL),A; INC L; EXX; CALL Z,PUTBYTE2 for speed
; In alternate set, LD (HL),A; INC L; CALL Z,PUTBYTE3 for speed

.putbyte3
        inc     h
        ld      a,h
        cp      0+(outbuffer+outbuflen)/$100
        ret     nz              ; exit if don't need to flush
        exx
        call    fullflush
        exx
        ret
.putbufbyte
        exx
        ld      (hl),a
        inc     l
        exx
        ret     nz
.putbyte2
        exx
        inc     h
        ld      a,h
        exx
        cp      0+(outbuffer+outbuflen)/$100
        ret     nz              ; exit if don't need to flush
.fullflush
        push    bc
        ld      bc,outbuflen
        jr      doflush
.flush  push    bc
        ld      bc,outbuffer
        and     a
        exx
        push    hl
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
        ld      ix,(ziphandle)
        ld      de,0
        ld      hl,outbuffer
        call    oz_os_mv        ; write buffer
        jp      c,inf_err       ; exit if error
        pop     hl
        pop     de
        pop     ix
.nobytes
        pop     bc
.setoutbuf
        exx
        ld      hl,outbuffer    ; reset pointer
        exx
        ret

