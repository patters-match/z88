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

; Routines to compress files using various methods

        module  methods

include "data.def"
include "fileio.def"

        xdef    compress

        xref    getbufbyte,putbyte2,flush,setoutbuf,resetinput
        xref    dispatcursor,dispmsg
        xref    deflate
        xref    initprogress,progressoff,writeheaders
        xref    oz_gn_d24,oz_gn_m24,oz_gn_pdn,oz_os_frm,oz_os_fwm

; Routine to compress file by best method

.compress
        call    initprogress
        ld      a,(options)
        and     @00001100       ; check compress option
        jp      z,method_store  ; store if no compression wanted
        ld      hl,(header+18)
        ld      a,(header+20)
        or      h
        or      l
        jp      z,method_store  ; or if file is zero bytes long
        ld      a,8
        ld      (header+4),a    ; deflate method
        ld      hl,msg_deflating
        call    dispatcursor
        call    deflate         ; deflate the file
        ld      ix,(ziphandle)  ; use the ZIP file
        exx
        push    hl
        exx
        pop     hl
        ld      bc,outbuffer
        and     a
        sbc     hl,bc           ; HL=bytes in output buffer
        ld      de,0
        ld      a,fa_ptr
        call    oz_os_frm       ; DEBC=current filepos
        add     hl,bc
        ld      b,h
        ld      c,l
        ld      hl,0
        adc     hl,de
        ex      de,hl           ; DEBC=effective current filepos
        ld      hl,header+14
        call    sub32           ; DEBC=compressed size
        ld      hl,header+18
        call    sub32           ; compare with uncompressed size
        jr      nc,method_store ; if not smaller, go to store instead
        ld      hl,msg_deflated
.endmethods
        call    dispatcursor    ; display appropriate message
        call    progressoff     ; turn off progress meter
        call    writeheaders    ; update and write headers
        ld      hl,(header+14)
        ld      a,(header+16)
        ld      b,a             ; BHL=compressed size
        ld      de,100
        ld      c,0
        call    oz_gn_m24       ; multiply by 100
        ld      de,(header+18)
        ld      a,(header+20)
        ld      c,a             ; CDE=uncompressed size
        or      d
        or      e
        jr      z,percent100    ; if zero size, use 100%
        call    oz_gn_d24       ; now BHL=percentage
        ld      c,l
        ld      b,h
        ld      hl,2
        ld      a,1
        ld      de,ascnumber
        call    oz_gn_pdn       ; convert to ASCII
        xor     a
        ld      (de),a          ; null-terminate it
        ld      hl,ascnumber
        jr      disppercent
.percent100
        ld      hl,msg_100percent
.disppercent
        call    dispmsg
        ld      hl,msg_percent
        call    dispmsg
        ret

; The Store method

.method_store
        ld      hl,header+14
        ld      a,fa_ptr
        call    oz_os_fwm       ; re-locate filepointer to after header
        call    setoutbuf       ; and clear output buffer
        call    resetinput
        xor     a
        ld      (header+4),a    ; store method
        ld      hl,msg_storing
        call    dispatcursor
.dostore
        call    getbufbyte      ; get next byte
        jr      z,endstore      ; exit if none left
        exx
        ld      (hl),a          ; store byte
        inc     l
        exx
        jp      nz,dostore
        call    putbyte2
        jp      dostore
.endstore
        ld      hl,msg_stored
        jr      endmethods


; Subroutine to subtract a 32bit number at HL from DEBC

.sub32  push    de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ex      de,hl
        push    hl
        ld      h,b
        ld      l,c
        pop     bc
        and     a
        sbc     hl,bc
        ld      b,h
        ld      c,l
        ex      de,hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        pop     hl
        sbc     hl,de
        ex      de,hl
        ret


; Messages

.msg_storing    defm    " - storing...        ", 0
.msg_stored     defm    " - stored (", 0
.msg_deflating  defm    " - deflating...      ", 0
.msg_deflated   defm    " - deflated (", 0
.msg_percent    defm    "%)       ", 13, 10, 0
.msg_100percent defm    "100", 0
