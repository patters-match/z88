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

; Routines to write header & central directory information

        module  headers

include "fileio.def"
include "dor.def"
include "data.def"

        xdef    initheader,writeheaders,appendcd

        xref    flush,outbytes,getbufbyte,putbyte2,putbufbyte
        xref    newinput,inf_err
        xref    oz_os_frm,oz_os_fwm,oz_os_mv,oz_gn_opf,oz_os_dor
        xref    oz_gn_d24,oz_gn_die,oz_os_pb

; Subroutine to initialise the header with all possible initial
; information and write to the ZIP file
; Leaves compressed size, CRC and method to be filled in
; It assumes the input file is *not* open, and leaves it open, flagging
; bit 2 of the OPENFILES flag if successful

.initheader
        ld      hl,header
        ld      (hl),0
        ld      de,header+1
        ld      bc,39
        ldir                    ; clear header to nulls
        ld      a,verneeded
        ld      (header),a      ; version required to extract
        call    namesize
        ld      (header+22),hl  ; filename size
        ld      hl,infilename
        ld      de,workarea
        ld      bc,255
        ld      a,op_dor
        call    oz_gn_opf       ; get DOR handle
        ld      a,dr_rd
        ld      b,dt_upd
        ld      de,workarea
        ld      c,6
        call    oz_os_dor       ; get last update time & date
        ld      a,dr_fre
        call    oz_os_dor       ; free DOR handle
        call    setdatetime     ; set DOS date & time
        ld      hl,infilename
        ld      b,0
        ld      de,workarea
        ld      c,maxfilename
        ld      a,op_in
        call    oz_gn_opf       ; attempt to open input file
        jr      c,cantopin
        ld      (inhandle),ix   ; save handle
        ld      a,@00001111     ; ZIP, CD, wildcard & input all open
        ld      (openfiles),a
        ld      de,0
        ld      a,fa_ext
        call    oz_os_frm       ; get size of file to DEBC
        ld      (header+18),bc  ; store in header as uncompressed size
        ld      (header+20),de
.cantopin
        ld      hl,(files)
        inc     hl              ; increment # files in ZIP
        ld      (files),hl
        call    flush           ; ensure ZIP file is fully flushed
        ld      ix,(ziphandle)
        ld      de,0
        ld      a,fa_ptr
        call    oz_os_frm       ; get offset of local header
        ld      (header+36),bc  ; store in header
        ld      (header+38),de
        ld      hl,msg_localsig
        ld      bc,4
        call    outbytes        ; output local header signature
        ld      hl,header
        ld      bc,26
        call    outbytes        ; and local part of header
        ld      hl,(infileadd)
        ld      bc,(header+22)
        call    outbytes        ; output filename
        call    flush           ; flush ZIP buffer
        ld      de,0
        ld      a,fa_ptr
        call    oz_os_frm       ; get offset of compressed file start
        ld      (header+14),bc  ; store temporarily in header
        ld      (header+16),de
        ret

; Subroutine to set DOS date and time in header according to internal time
; and date stored at WORKAREA. Year is bounded to lower and upper limits
; of 1980 and 2107.

.setdatetime
        ld      hl,(workarea)
        ld      a,(workarea+2)
        ld      b,a             ; BHL=internal time
        ld      de,100
        ld      c,0
        call    oz_gn_d24       ; BHL=#secs since start of day
        ld      de,3600
        ld      c,0
        call    oz_gn_d24       ; L=hour, CDE=minutes since start of hour
        push    hl              ; save hour
        ex      de,hl
        ld      b,c
        ld      de,60
        ld      c,0
        call    oz_gn_d24       ; L=minute, E=second
        ld      a,l             ; A=minute (bits 0-5)
        pop     hl
        ld      h,l             ; HL=hour (bits 8-12)
        rla
        rla
        rla
        rl      h
        rla
        rl      h
        rla
        rl      h
        and     @11100000
        ld      l,a             ; HL=hour (bits 11-15) and min (bits 5-10)
        ld      a,e
        rra
        and     @00011111       ; A=secs/2
        or      l
        ld      l,a             ; HL=DOS time
        ld      (header+6),hl   ; store it
        ld      bc,(workarea+3)
        ld      a,(workarea+5)  ; ABC=internal date
        call    oz_gn_die       ; convert to zoned
        ld      hl,1980
        ex      de,hl
        and     a
        sbc     hl,de           ; get year relative to 1980
        jr      nc,after1980
        ld      hl,0            ; use 1980 if before 1980
.after1980
        ld      a,l
        and     @10000000
        or      h
        jr      z,before2107
        ld      l,127           ; use 2107 if after 2107
.before2107
        ld      h,l             ; HL=year (bits 8-14)
        rr      b
        rr      l
        rr      b
        rr      l
        rr      b
        rr      l
        rr      b
        rl      h               ; HL=year (bits 9-15) and month (bits 5-8)
        ld      a,l
        and     @11100000
        ld      l,a
        ld      a,c
        and     @00011111
        or      l
        ld      l,a             ; HL=DOS date
        ld      (header+8),hl   ; store it
        ret


; Subroutine to write local & central directory headers, first filling in
; compressed size information

.writeheaders
        call    flush           ; flush the output buffer
        ld      ix,(ziphandle)
        ld      de,0
        ld      a,fa_ptr
        call    oz_os_frm       ; get current filepointer
        ld      (zipoffset),bc  ; save it
        ld      (zipoffset+2),de
        ld      hl,header+36
        ld      a,fa_ptr
        call    oz_os_fwm       ; move pointer to header start
        ld      h,b
        ld      l,c
        ld      bc,(header+14)  ; get offset of compressed file start
        and     a
        sbc     hl,bc
        ld      (header+14),hl
        ld      c,l
        ex      de,hl
        ld      de,(header+16)
        sbc     hl,de
        ld      (header+16),hl  ; now header holds compressed size
        ld      hl,msg_localsig
        ld      bc,4
        call    updatezip       ; output local header signature
        ld      hl,header
        ld      bc,26
        call    updatezip       ; and local part of header
        ld      hl,zipoffset
        ld      a,fa_ptr
        call    oz_os_fwm       ; move pointer back to end of ZIP file
        ld      ix,(cdhandle)   ; now use central directory file
        ld      de,0
        ld      hl,msg_centralsig
        ld      bc,6
        call    oz_os_mv        ; output central directory signature
        jp      c,inf_err       ; exit if any error
        ld      de,0
        ld      hl,header
        ld      bc,40
        call    oz_os_mv        ; output central directory header
        jp      c,inf_err
        ld      de,0
        ld      hl,(infileadd)
        ld      bc,(header+22)
        call    oz_os_mv        ; output filename
        jp      c,inf_err
        ret

; Subroutine to update BC bytes from HL to current positon in ZIP file

.updatezip
        ld      a,b
        or      c
        ret     z               ; exit if no bytes left
        ld      a,(hl)
        call    oz_os_pb        ; update a byte
        inc     hl
        dec     bc
        jr      updatezip

; Subroutine to append central directory to ZIP file & flush it

.appendcd
        call    flush           ; flush ZIP file
        ld      ix,(ziphandle)
        ld      de,0
        ld      a,fa_ptr
        call    oz_os_frm       ; get offset of central directoy
        ld      (zipoffset),bc
        ld      (zipoffset+2),de; save it
        call    swaphandles     ; swap CD & input file handles
        call    newinput        ; initialise input buffer
.appendloop
        call    getbufbyte      ; get a byte from CD
        jr      z,endappend     ; move on if done
        exx
        ld      (hl),a          ; output it
        inc     l
        exx
        jp      nz,appendloop
        call    putbyte2
        jp      appendloop
.endappend
        call    swaphandles     ; swap handles back again
        ld      hl,msg_endcdsig
        ld      bc,4
        call    outbytes        ; output end of central directory sig
        ld      b,4
        call    putzeros        ; output disk number & central dir disk
        ld      b,2
.outnumfiles
        ld      a,(files)
        call    putbufbyte
        ld      a,(files+1)
        call    putbufbyte      ; output #files
        djnz    outnumfiles     ; twice
        ld      ix,(cdhandle)
        ld      de,0
        ld      a,fa_ext
        call    oz_os_frm       ; get size of central directory file
        ld      a,c
        call    putbufbyte
        ld      a,b
        call    putbufbyte
        ld      a,e
        call    putbufbyte
        ld      a,d
        call    putbufbyte      ; output it
        ld      hl,zipoffset
        ld      bc,4
        call    outbytes        ; output offset of central directory
        ld      b,2
        call    putzeros        ; output zero zipfile comment length
        call    flush           ; flush zipfile
        ret

; Subroutine to output B zeros to the file

.putzeros
        xor     a
        call    putbufbyte
        djnz    putzeros
        ret

; Subroutine to swap CD and input handles over

.swaphandles
        ld      hl,(cdhandle)
        push    hl
        ld      hl,(inhandle)
        ld      (cdhandle),hl
        pop     hl
        ld      (inhandle),hl   ; swap CD and input file handles
        ld      hl,openfiles
        ld      a,(hl)          ; get open file flags
        bit     1,a
        res     2,(hl)          ; reset CD file flag
        jr      z,notset
        set     2,(hl)          ; unless input file was open
.notset bit     2,a
        res     1,(hl)          ; reset input file flag
        ret     z
        set     1,(hl)          ; unless CD file was open (we hope!)
        ret

; Subroutine to get size of filename in HL

.namesize
        ld      hl,infilename
        ld      a,(hl)
        cp      ':'
        jr      nz,nodevice     ; move on if device not specified
.skipdev
        inc     hl
        ld      a,(hl)
        cp      '\'
        jr      z,nodevice
        cp      '/'
        jr      nz,skipdev
.nodevice
        ld      (infileadd),hl  ; save address after device
        ld      d,h
        ld      e,l             ; set DE=HL=last '/' or '\'
        ld      a,(hl)
        cp      '/'
        jr      z,checkname
        cp      '\'
        jr      z,checkname
        dec     de              ; if no leading '/' or '\', decrement DE
.checkname
        ld      a,(hl)
        and     a
        jr      z,endofname     ; move on if found end of name
        cp      '/'
        jr      z,isslash
        cp      '\'
        jr      nz,notslash
.isslash
        ld      d,h             ; set position of last slash
        ld      e,l
.notslash
        inc     hl
        jr      checkname       ; back for more
.endofname
        ld      a,(options)
        and     @00110000       ; check path option
        jr      nz,withpaths
        ld      (infileadd),de  ; if none, start at last slash
.withpaths
        ld      de,(infileadd)
        ld      a,(de)
        cp      '/'
        jr      z,ignslsh
        cp      '\'
        jr      nz,noignslsh
.ignslsh
        inc     de              ; skip past any leading slash
        ld      (infileadd),de
.noignslsh
        and     a
        sbc     hl,de           ; HL=filename length
        ret

; Signatures

.msg_localsig   defm    "PK", 3, 4
.msg_centralsig defm    "PK", 1, 2
                defm    10, $ff          ; version 1.0 of "unknown" system
.msg_endcdsig   defm    "PK", 5, 6

