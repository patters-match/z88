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

; Routines to decompress files using known methods

        module  methods

include "data.def"

        xdef    checkmethod,decompress

        xref    inflate,setcursor,getbufbyte,putbyte2
        xref    oz_gn_sop,getabyte3

; Subroutine to check if compression method is okay
; Exits with Z set if known method

.checkmethod
        ld      a,(header+6)    ; get flags
        and     1
        ret     nz              ; bad method if encryption used
        ld      hl,(header+8)   ; get method
        ld      a,h
        and     a
        ret     nz              ; bad method if >255
        ld      a,l
        and     a
        ret     z               ; good method if 0
        cp      8
        ret                     ; or if 8

; Routine to decompress file by all known methods

.decompress
        xor     a
        ld      (bigfile),a     ; signal small file
        ld      hl,0
        ld      (flushsize),hl  ; no bytes flushed yet
        ld      a,(header+8)    ; get method
        ld      hl,msg_inflating
        and     a
        jr      nz,showmsg
        ld      hl,msg_extracting
.showmsg
        ld      (lastmsg),hl
        call    setcursor
        call    oz_gn_sop       ; display appropriate message
        and     a               ; re-check method
        jr      z,doextract     ; inflate the file if not method 0
        call    getbufbyte      ; get first byte
        exx
        ld      c,a             ; save to bit buffer
        ld      b,8             ; 8 bits
        exx
        jp      inflate
.doextract
        ld      hl,(header+22)
        ld      a,(header+24)
        ld      b,a             ; BHL contains filelength
        ld      de,1
.extloop
        ld      a,b
        or      h
        or      l
        ret     z               ; exit if no length
        exx
        ld      a,(hl)          ; get a byte
        ld      (de),a          ; and output it
        inc     l
        call    z,getabyte3
        inc     e
        exx
        call    z,putbyte2
        and     a
        sbc     hl,de
        jp      nc,extloop
        dec     b
        jp      extloop

; Messages

.msg_inflating  defm    " - inflating...        ", 0
.msg_extracting defm    " - extracting...       ", 0
