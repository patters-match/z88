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

; Z88 Unzip Application

        module  unzip

include "error.def"
include "fileio.def"
include "data.def"
include "messages.def"

        xdef    in_entry,restart

        xref    checkmethod,decompress,docrc,parsefname,makepath
        xref    redraw,noredraw,showoptions,dispoutname
        xref    savecursor,setcursor
        xref    inf_err
        xref    closefiles,closeoutput
        xref    getbufbyte,readbcbytes,skipbcbytes,fillbuffer
        xref    getfpointer,setfpointer
        xref    flush,setoutbuf,initprogress
        xref    getline,getkey
        xref    skipfile
        xref    oz_gn_sop,oz_gn_nln,oz_gn_soe,oz_gn_esp
        xref    oz_dc_nam,oz_gn_opf,oz_os_esc,oz_gn_esa
        xref    oz_gn_cl,oz_os_fwm

; First, the application entry and enquiry points

.in_entry
        jp      mainentry
.in_enq ld      bc,outbuffer
        ld      de,outbuffer+outbuflen
        or      a               ; give back the 32K output buffer
        ret

.mainentry
        ld      a,@00011010     ; initial options
        ld      (options),a
        ld      a,sc_ena
        call    oz_os_esc       ; enable ESC detection
        call    noredraw        ; no messages to redraw
        call    redraw          ; draw the initial screen
.restart
        ld      hl,stacksig     ; setup stack signature
        push    hl
        push    hl
.askforfile
        xor     a               ; no open files
        ld      (openfiles),a
        ld      hl,msg_null
        call    oz_dc_nam       ; no reference in Index
        ld      hl,msg_whichfile
        call    getline
.gotname
        call    noredraw
        ld      hl,workarea
        ld      de,msg_defext
        call    setdefext       ; set default ".zip" extension
        ld      hl,workarea
        ld      b,0
        ld      de,workarea+80
        ld      c,80
        ld      a,op_in
        call    oz_gn_opf       ; attempt to open file
        jr      nc,gotfile
        call    oz_gn_esp
        call    oz_gn_soe       ; display error
        call    oz_gn_nln
        jr      askforfile
.notrewindable
        ld      hl,msg_notrewindable
        call    oz_gn_sop
.newfile
        call    closefiles
        jr      askforfile
.gotfile
        ld      (inhandle),ix   ; save input file handle
        ld      a,1             ; only input file open
        ld      (openfiles),a
        ld      hl,1
        ld      (header),hl
        dec     hl
        ld      (header+2),hl
        ld      a,fa_ptr
        ld      hl,header
        call    oz_os_fwm       ; make sure we can wind file forwards
        jr      c,notrewindable
        ld      hl,0
        ld      (header),hl
        ld      a,fa_ptr
        ld      hl,header
        call    oz_os_fwm       ; and backwards
        jr      c,notrewindable
        ld      hl,workarea
        ld      de,workarea+80
        ld      b,-1
        ld      c,80
        xor     a
        call    oz_gn_esa       ; read filename segment
        ld      hl,workarea+80
        call    oz_dc_nam       ; place in "Your Ref."
        call    fillbuffer      ; set up the buffer
.findP  call    getbufbyte
.findP2 cp      'P'             ; test for "PK"
        jr      nz,findP
        call    getbufbyte
        cp      'K'
        jr      nz,findP2
        call    getbufbyte
        cp      3               ; test for local header
        jr      nz,notlocal
        call    getbufbyte
        cp      4
        jr      nz,findP2
        jr      foundlocal      ; move on if found local header
.notlocal
        cp      1               ; test for central directory
        jr      nz,findP2
        call    getbufbyte
        cp      2
        jr      nz,findP2
        ld      hl,msg_endoffile ; end of ZIP when c.d. found
        call    oz_gn_sop
        jr      newfile
.foundlocal
        call    getfpointer     ; save filepointer
        ld      hl,header+4     ; read header exc. PK signature
        ld      bc,26
        call    readbcbytes
        ld      bc,(header+26)
        ld      a,b             ; test for max 255 bytes filename
        and     a
        jr      nz,badname
        or      c
        jr      nz,goodname     ; test for non-null filename
.badname
        call    skipbcbytes     ; ignore filename provided
        ld      hl,msg_badname
        ld      de,workarea
        ld      bc,msg_badnamelen
        ldir                    ; copy "badname"
        jr      testescape
.dispandskip
        call    oz_gn_sop
.skipthis
        call    skipfile
        call    noredraw
        jr      findP
.goodname
        ld      hl,workarea
        call    readbcbytes     ; read filename
        ld      (hl),0          ; null-terminate it
.testescape
        ld      a,sc_bit
        call    oz_os_esc       ; test for ESCape
        jr      nc,notescape
        ld      a,sc_ack
        call    oz_os_esc       ; acknowledge ESCape
        ld      a,rc_esc
        jp      inf_err
.notescape
        ld      hl,workarea
        ld      de,workarea+256
        call    parsefname      ; parse name to Z88 style
        jr      c,skipthis      ; skip directories
        ld      hl,workarea
.xferfname
        ld      a,(de)
        inc     de
        ld      (hl),a          ; transfer filename
        inc     hl
        and     a
        jr      nz,xferfname    ; until terminator found
        call    dispoutname
        ld      bc,(header+28)
        call    skipbcbytes     ; skip extra field
        call    checkmethod
        ld      hl,msg_wrongmethod
        jr      nz,dispandskip
        ld      a,(options)
        and     $03             ; get "Extract" flag
        jr      nz,mayextract
        call    oz_gn_nln
        jr      skipthis
.dontextract
        ld      hl,msg_skip
        call    setcursor
        jr      dispandskip     ; back if not extracting
.mayextract
        dec     a
        jr      z,extractit     ; if extracting all, move on
        ld      hl,msg_askextract
        ld      de,msg_ynar
        call    getkey          ; else ask user
        cp      'n'
        jp      z,dontextract
        cp      'y'
        jr      z,extractit
        cp      'a'
        jr      z,extractall
        call    rename
        jr      extractit
.extractall
        ld      a,(options)
        and     $ff-$03         ; mask extract flag
        or      $01             ; set to on
        ld      (options),a     ; store options
        call    showoptions     ; redisplay
.extractit
        ld      hl,workarea
        call    makepath        ; ensure correct path exists
        ld      de,workarea+1025
        ld      b,0
        ld      c,255
        ld      a,op_in
        call    oz_gn_opf       ; check if file exists
        jr      c,createit      ; move on if not found
        call    oz_gn_cl        ; close file
        ld      a,(options)
        and     $0c             ; get overwrite flag
        jr      nz,mayoverwrite
.dontoverwr
        ld      hl,msg_exists
        call    setcursor
        jp      dispandskip
.mayoverwrite
        cp      $04
        jr      z,createit      ; move on if always overwrite
        ld      hl,msg_askoverwr
        ld      de,msg_ynar
        call    getkey          ; else ask user
        cp      'n'
        jr      z,dontoverwr
        cp      'y'
        jr      z,createit
        cp      'a'
        jr      z,overwrall
        call    rename
        ld      hl,workarea
        call    makepath
        jr      createit
.overwrall
        ld      a,(options)
        and     $ff-$0c         ; mask overwrite flag
        or      $04             ; set to on
        ld      (options),a     ; store options
        call    showoptions     ; redisplay
.createit
        ld      hl,workarea
        ld      de,workarea+1025
        ld      b,0
        ld      c,255
        ld      a,op_out
        push    bc
        push    de
        call    oz_gn_opf       ; create output file
        pop     de
        pop     bc
        jp      c,inf_err
        ld      (outhandle),ix  ; save output file handle
        ld      a,3             ; input & output open
        ld      (openfiles),a
        ld      a,op_in
        call    oz_gn_opf       ; open output for reading
        jp      c,inf_err
        ld      (oihandle),ix
        ld      a,7             ; all 3 files open
        ld      (openfiles),a
        call    setoutbuf       ; clear the output buffer
        call    initprogress    ; initialise progress meter
        call    decompress      ; decompress the file
        call    flush           ; flush output
        ld      hl,msg_crccheck
        ld      (lastmsg),hl
        call    setcursor
        call    oz_gn_sop
        ld      ix,(oihandle)
        call    docrc           ; find CRC-32 of file
        ld      bc,(header+14)
        and     a
        sbc     hl,bc           ; test low half of CRC-32
        jr      nz,badcrc
        ex      de,hl
        ld      bc,(header+16)
        and     a
        sbc     hl,bc           ; test high half of CRC-32
        ld      hl,msg_crcok
        jr      z,goodcrc
.badcrc ld      hl,msg_crcfailed
.goodcrc
        call    setcursor
        call    oz_gn_sop
        call    closeoutput
        call    noredraw
        exx
        ld      a,b
        exx
        cp      8               ; check if 8 bits available
        jp      nz,findP        ; back if not
        exx
        ld      a,c             ; else get the byte
        exx
        jp      findP2          ; and use it

; Subroutines to get new name for output file
; and to output file details

.rename ld      hl,msg_newname
        ld      (lastmsg),hl
        call    oz_gn_sop
        xor     a
        ld      (redrawflag),a
        call    getline
        jp      dispoutname


; Subroutine to add a default extension to a filename if it doesn't
; already have one
; On entry, HL=filename, DE=extension (including "." and term. null)
; All registers corrupted

.setdefext
        ld      a,(hl)
        and     a
        jr      z,noext         ; move on if found no extension
        cp      '.'
        ret     z               ; exit if did find one
        inc     hl
        jr      setdefext       ; check rest of filename
.noext  ld      a,(de)
        ld      (hl),a          ; copy default extension
        inc     de
        inc     hl
        and     a
        jr      nz,noext        ; until terminator copied as well
        ret
