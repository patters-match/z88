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

; Skip file in ZIP routines

        module  skipfile

include "data.def"

        xdef    skipfile

        xref    getfpointer,setfpointer
        xref    getbufbyte,skipbcbytes

; Subroutine to skip past file in ZIP, if its header is stored

.skipfile
        ld      hl,(header)     ; get DEHL=filepointer
        ld      de,(header+2)
        ld      bc,26
        call    addbc           ; skip header
        ld      bc,(header+26)
        call    addbc           ; skip filename
        ld      bc,(header+28)
        call    addbc           ; skip extra field
        ld      a,(header+6)
        and     8               ; is length stored here?
        jr      nz,nolength     ; move on if not
        ld      bc,(header+18)
        add     hl,bc
        ld      bc,(header+20)
        ex      de,hl
        adc     hl,bc           ; add in stored length
        ld      (header),de
        ld      (header+2),hl
        call    setfpointer     ; set the filepointer
        ret
.nolength
        ld      (header),hl
        ld      (header+2),de
        call    setfpointer     ; set to start of compressed file
.finddesc
        call    getbufbyte      ; locate data descriptor header
.finddesc2
        cp      'P'
        jr      nz,finddesc
        call    getbufbyte
        cp      'K'
        jr      nz,finddesc2
        call    getbufbyte
        cp      7
        jr      nz,finddesc2
        call    getbufbyte
        cp      8
        jr      nz,finddesc2
        ld      bc,12
        call    skipbcbytes     ; ignore data descriptor fields
        ret

; Subroutine to add BC to DEHL

.addbc  add     hl,bc
        ret     nc
        inc     de
        ret
