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

; Filename validation & path creation

        module  filenames

include "dor.def"
include "fileio.def"
include "data.def"

        xdef    parsefname,makepath

        xref    oz_os_dor,oz_gn_pfs,oz_gn_opf

; Main routine to parse a filename
; On entry, HL=source, DE=dest
; On exit, DE=parsed name, carry set if directory name
; All other registers corrupted

.parsefname
        xor     a
        ld      (de),a          ; clear byte before
        inc     de
        push    de              ; save dest address
.newsegment
        ld      (lastseg),de    ; save segment start
        ld      b,12            ; max filename length
        call    validchar
        jr      nz,normalchar   ; move on unless . .. or /
        ld      (de),a
        inc     de
        and     a
        jr      z,endfname      ; move on if filename end
        jr      newsegment      ; move back
.morefname
        call    validchar       ; get next char
.normalchar
        ld      (de),a          ; transfer
        inc     de
        jr      c,doextension
        jr      z,endsegment
        djnz    morefname
.longfname
        call    validchar
        jr      nz,longfname    ; skip normal chars after 12
        ld      (de),a          ; enter "."
        inc     de
        jr      nc,endsegment
.doextension
        ld      b,3             ; max extension length
.moreext
        call    validchar
        jr      c,moreext       ; ignore further "."s
        jr      z,endext
        ld      (de),a
        inc     de
        djnz    moreext
.longext
        call    validchar
        jr      c,longext       ; ignore chars to segment end
        jr      nz,longext
        ld      (de),a          ; store segment end char
        inc     de
        jr      endsegment
.endext push    af
        dec     de
        ld      a,(de)
        cp      '.'             ; check last char isn't "."
        jr      z,skipdot
        inc     de
.skipdot
        pop     af
        ld      (de),a          ; add segment end char
        inc     de
.endsegment
        and     a
        jr      nz,newsegment
.endfname
        dec     de
        dec     de
        ld      a,(de)          ; get last char
        cp      '/'
        pop     de              ; DE=dest start
        scf
        ret     z               ; exit with C set if directory
        ld      a,(options)
        and     $30
        ret     nz              ; exit if path wanted
        ld      de,(lastseg)    ; else get last segment only
        ret

; Routine to create the path for filename in HL, if option set
; HL is preserved, all other registers corrupted

.makepath
        ld      a,(options)
        and     $30             ; test paths option
        ret     z               ; exit if don't want them
        push    hl              ; save filename start
.finddir
        ld      a,(hl)          ; get next char
        inc     hl
        and     a
        jr      z,madepath      ; on if end of name
        cp      '/'
        jr      nz,finddir      ; back until found directory
        dec     hl
        ld      (hl),0          ; terminate directory name
        ex      (sp),hl         ; get start
        ld      b,0
        ld      de,workarea+1024
        ld      c,255
        ld      a,op_dir
        call    oz_gn_opf       ; create directory
        jr      c,notmade       ; move on if error occured
        ld      a,dr_fre
        call    oz_os_dor       ; else free DOR handle
.notmade
        ex      (sp),hl         ; restore address
        ld      (hl),'/'        ; replace segment terminator
        inc     hl
        jr      finddir         ; back for next
.madepath
        pop     hl              ; restore filename address
        ret

; Subroutine to get next character from source and ensure valid
; C & Z set for "."
; Z set for end of segment

.validchar
        ld      a,(hl)          ; get char
        inc     hl
        cp      '\'
        jr      nz,notbackslash
        ld      a,'/'
.notbackslash
        cp      '/'
        ret     z               ; Z set if end of segment
        and     a
        ret     z               ; Z set if end of filename
        cp      '.'
        scf
        ret     z               ; C & Z set if "."
        cp      '*'             ; screen wildcard chars out
        jr      z,notvalid
        cp      '?'
        jr      z,notvalid
        cp      ':'
        jr      z,notvalid
        cp      '-'             ; test for known valid chars
        jr      z,isvalid
        cp      '0'
        jr      c,testit
        cp      '9'+1
        jr      c,isvalid
        cp      'A'
        jr      c,testit
        cp      'Z'+1
        jr      c,isvalid
        cp      'a'
        jr      c,testit
        cp      'z'+1
        jr      c,isvalid
.testit push    hl
        push    bc
        push    af
        ld      b,0
        ld      hl,workarea+1025
        ld      (hl),b          ; terminate "segment"
        dec     hl
        ld      (hl),a          ; insert char to check
        call    oz_gn_pfs       ; check it
        jr      c,badchar
        pop     af
        pop     bc
        pop     hl
        or      a               ; clear C & Z flags
        ret
.badchar
        pop     af
        pop     bc
        pop     hl
.notvalid
        ld      a,'-'           ; replace invalid chars with "-"
.isvalid
        or      a               ; clear C & Z flags
        ret
