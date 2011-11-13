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

; Z88 ZipUp Application

        module  zipup

include "error.def"
include "fileio.def"
include "director.def"
include "dor.def"
include "data.def"
include "messages.def"

        xdef    in_entry,restart

        xref    redraw,noredraw,showoptions
        xref    savecursor,setcursor,dispmsg,dispatcursor
        xref    inf_err
        xref    setoutbuf,newinput,resetinput
        xref    closefiles
        xref    initheader,appendcd
        xref    getline,getkey
        xref    docrc,setupfreq,compress,initprogress,progressoff
        xref    oz_gn_sop,oz_gn_nln,oz_gn_soe,oz_gn_esp
        xref    oz_dc_nam,oz_gn_opf,oz_os_esc,oz_gn_esa
        xref    oz_gn_cl,oz_gn_opw,oz_gn_wfn,oz_gn_wcl
        xref    oz_gn_fex,oz_gn_del

; First, the application entry and enquiry points

.in_entry
        jp      mainentry
.in_enq ld      bc,inbuffer
        ld      de,inbuffer+inbuflen
        or      a               ; give back the 32K input buffer
        ret

.mainentry
        ld      a,(ix+2)        ; get page past end of bad application RAM
        cp      $20+ram_pages   ; must match expected memory
        jr      z,badram_okay
        ld      a,rc_room       ; otherwise exit with "no room"
        call_oz(os_bye)
.badram_okay
        ld      a,@00000100     ; initial options
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
        ld      de,msg_defext   ; default extension (".zip")
        call    setdefext       ; set if required
        ld      hl,workarea
        ld      de,zipfilename
        call    openupd         ; attempt to create file
        jp      c,cantopen
        ld      (ziphandle),ix  ; save output file handle
        ld      a,@00000001     ; only zip file open
        ld      (openfiles),a
        call    setoutbuf       ; set up outbuf buffer
        ld      hl,0
        ld      (files),hl      ; no files added to ZIP yet
        ld      hl,zipfilename
        ld      de,workarea+80
        ld      b,-1
        ld      c,80
        xor     a
        call    oz_gn_esa       ; read filename segment
        ld      hl,workarea+80
        call    oz_dc_nam       ; place in "Your Ref."
        ld      hl,msg_cdname
        ld      de,workarea
        call    openupd         ; attempt to create CD file
        jp      c,cantopen
        ld      (cdhandle),ix   ; save CD file handle
.asktoadd
        ld      a,@00000011
        ld      (openfiles),a   ; flag CD & zip files open
        ld      hl,msg_addfiles
        call    getline
        ld      hl,workarea
        ld      a,(hl)          ; test first character
        and     a
        jp      z,done_adding
        ld      b,0
        ld      c,maxfilename
        ld      de,workarea+80
        call    oz_gn_fex       ; expand filename to add device
        ld      hl,workarea+80
        ld      b,0
        xor     a
        call    oz_gn_opw       ; open wildcard handler
        jr      nc,gotwild
        call    oz_gn_esp
        call    oz_gn_soe       ; display error
        call    oz_gn_nln
        jr      asktoadd
.gotwild
        ld      (wldhandle),ix  ; save wildcard handle
.addnext
        ld      a,@00001011
        ld      (openfiles),a   ; zip file, CD & wildcard handler open
        ld      ix,(wldhandle)
        ld      de,infilename
        ld      c,maxfilename
        call    oz_gn_wfn       ; get next match
        jp      c,endwild
        cp      dn_fil
        jr      nz,addnext      ; skip non-file matches
        ld      hl,infilename
        ld      de,zipfilename
        call    checkfnames
        jr      z,addnext       ; ignore if ZIP file
        ld      de,msg_cdname
        call    checkfnames
        jr      z,addnext       ; or CD file
        call    initheader      ; initialise header info
        call    noredraw
        ld      hl,msg_indent
        call    dispmsg
        ld      hl,(infileadd)
        call    dispmsg
        call    savecursor      ; save cursor after filename
        ld      a,(openfiles)
        and     @00000100       ; check if input file was opened
        jp      z,cantopen      ; error if not
        call    newinput        ; initialise input
        ld      hl,msg_calc_crc
        call    dispatcursor
        call    initprogress
        call    setupfreq       ; initialise literal frequency table
        call    docrc           ; calculate CRC & count literal frequencies
        ld      (header+10),hl  ; store in header
        ld      (header+12),de
        call    resetinput
        ld      hl,msg_examining
        call    dispatcursor
        call    compress        ; compress the file
        ld      ix,(inhandle)
        call    oz_gn_cl        ; close the input file
        ld      a,@00001011     ; ZIP, cd and wildcard open
        ld      (openfiles),a
        call    savecursor
        ld      a,(options)
        and     @00000011       ; check deletion flag
        jp      z,addnext       ; back for more if no delete
        cp      1
        jr      z,dodelete      ; move on if always delete
        ld      hl,msg_askdelete
        ld      de,msg_yna
        call    getkey
        cp      'y'
        jr      z,dodelete      ; move on to delete
        cp      'n'
        jr      z,nodelete
        ld      a,(options)
        and     @11111100       ; mask delete flag
        or      @00000001       ; set to on
        ld      (options),a
        call    showoptions     ; redisplay options
.dodelete
        ld      hl,msg_deleting
        call    dispatcursor    ; say we're doing it
        ld      hl,infilename
        ld      b,0
        call    oz_gn_del       ; try to delete
        ld      hl,msg_deleted
        jr      nc,showdelmsg
        ld      hl,msg_notdeld
.showdelmsg
        call    dispatcursor    ; display success/failure
        jp      addnext         ; loop back to add more
.nodelete
        ld      hl,msg_retained
        jr      showdelmsg
.endwild
        call    oz_gn_wcl       ; close wildcard handler
        jp      asktoadd
.done_adding
        call    noredraw
        ld      hl,msg_doingcd
        call    dispmsg
        call    appendcd        ; append central directory & flush
        ld      hl,msg_donecd
        call    dispmsg
        call    closefiles      ; close all files
        jp      askforfile

; Error routine if can't perform an open

.cantopen
        call    oz_gn_esp
        call    oz_gn_soe       ; display error
        call    oz_gn_nln
        call    closefiles      ; close any open files
        jp      askforfile      ; restart

; Subroutine to check whether filenames at DE & HL
; BC and HL preserved only. On exit, Z set if filenames equal

.checkfnames
        push    hl
        push    bc
.checknext
        ld      a,(de)
        cp      'A'
        jr      c,notup1
        cp      'Z'+1
        jr      nc,notup1
        or      32              ; convert 1st char to lowercase
.notup1 ld      b,a
        ld      a,(hl)
        cp      'A'
        jr      c,notup2
        cp      'Z'+1
        jr      nc,notup2
        or      32              ; convert 2nd char to lowercase
.notup2 cp      b               ; check character
        inc     de
        inc     hl
        jr      nz,endcheck     ; move on if different
        and     a
        jr      nz,checknext    ; back if not end of filenames
.endcheck
        pop     bc
        pop     hl
        ret                     ; exit (with Z set if same)


; Subroutine to create a file, close and re-open for update
; On entry, HL=name, DE=buffer for explicit filename
; On exit, IX=handle. Carry set if error (A=error)

.openupd
        push    de              ; save registers
        push    hl
        ld      b,0
        ld      c,maxfilename
        ld      a,op_out
        call    oz_gn_opf       ; create file
        pop     hl
        pop     de
        ret     c               ; exit if error
        call    oz_gn_cl        ; close file
        ld      b,0
        ld      c,maxfilename
        ld      a,op_up
        call    oz_gn_opf       ; open for update
        ret


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
