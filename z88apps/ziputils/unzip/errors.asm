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

; Error handling routines

        module  errors

include "error.def"
include "syspar.def"
include "director.def"
include "data.def"

        xdef    inf_err,errhandler,doquit
        xdef    noredraw,redraw,showoptions,dispoutname
        xdef    savecursor,setcursor
        xdef    closefiles,closeoutput

        xref    restart,oz_os_out,oz_gn_sop,oz_gn_pdn
        xref    oz_gn_nln,oz_gn_esp,oz_gn_soe,oz_os_esc
        xref    oz_os_nq,oz_gn_cl

; Subroutine to clear the "redraw messages"

.noredraw
        push    hl
        ld      hl,0
        ld      (lastmsg),hl
        ld      hl,redrawflag
        ld      (hl),0
        pop     hl
        ret

; Standard error-handler subroutine
; Errors dealt with are: RC_QUIT, RC_SUSP, RC_DRAW, RC_ESC
; All other errors are passed back into the application

.errhandler
        cp      rc_esc
        jr      nz,notescape
        ld      a,sc_ack
        call    oz_os_esc       ; acknowledge ESCape
        ld      a,rc_esc
        jp      inf_err         ; and cause error
.notescape
        cp      rc_draw
        jr      nz,notdraw
        call    redraw          ; redraw the screen
        ld      a,rc_susp
.notdraw
        cp      rc_susp
        jr      nz,notsusp
        or      a               ; clear error for rc_susp & rc_draw
        ret
.notsusp
        cp      rc_quit
        scf
        ret     nz              ; exit unless rc_quit, with error still flagged
.doquit call    closefiles      ; ensure all files closed
        xor     a
        call_oz(os_bye)         ; quit application

; Subroutine to re-draw the application screen

.redraw push    hl
        push    af
        ld      hl,windows
        call    oz_gn_sop       ; show the windows
        call    showoptions     ; display selected options
        ld      a,(redrawflag)
        and     a
        jr      nz,showfname
        call    displast
        call    savecursor
.exitredraw     pop     af
        pop     hl
        ret
.showfname
        call    dispoutname
        call    displast
        jr      exitredraw

; Subroutine to display file details

.dispoutname
        ld      a,32
        call    oz_os_out
        ld      hl,workarea
        call    oz_gn_sop
        push    de
        ld      hl,msg_presize
        call    oz_gn_sop
        ld      hl,header+18
        ld      de,workarea+1024
        xor     a
        call    oz_gn_pdn
        xor     a
        ld      (de),a
        ld      hl,workarea+1024
        call    oz_gn_sop
        ld      hl,msg_midsize
        call    oz_gn_sop
        ld      hl,header+22
        ld      de,workarea+1024
        xor     a
        call    oz_gn_pdn
        xor     a
        ld      (de),a
        ld      hl,workarea+1024
        call    oz_gn_sop
        ld      hl,msg_endsize
        call    oz_gn_sop
        pop     de
        call    savecursor
        ld      a,1
        ld      (redrawflag),a
        ret

; Subroutine to display last message

.displast
        ld      hl,(lastmsg)
        ld      a,h
        or      l
        ret     z
        call    oz_gn_sop
        ret

; Subroutine to save the current cursor position

.savecursor
        push    af
        push    bc
        push    de
        push    hl
        ld      bc,nq_wcur
        xor     a               ; current window
        call    oz_os_nq        ; get cursor position
        ld      (curpos),bc     ; save it
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

; Subroutine to reset the cursor position

.setcursor
        push    af
        push    hl
        ld      hl,msg_setcur
        call    oz_gn_sop
        ld      a,(curpos)
        add     a,32
        call    oz_os_out
        ld      a,(curpos+1)
        add     a,32
        call    oz_os_out
        pop     hl
        pop     af
        ret

; Subroutine to display the currently selected options

.showoptions
        ld      hl,use_opt
        call    oz_gn_sop       ; select the option window
        ld      a,(options)     ; get options
        ld      c,a
        ld      b,3             ; 3 to do
.nextoption
        ld      hl,at_opt
        call    oz_gn_sop
        ld      a,36
        sub     b
        call    oz_os_out       ; move to correct pos
        ld      a,c
        and     3               ; mask current option bits
        ld      hl,opt_off
        jr      z,setopt        ; move on if "off"
        cp      1
        ld      hl,opt_on
        jr      z,setopt        ; move on if "on"
        ld      hl,opt_ask      ; otherwise it's "ask"
.setopt call    oz_gn_sop       ; display option
        srl     c               ; shift to next option
        srl     c
        djnz    nextoption      ; back for more
        ld      hl,use_main
        call    oz_gn_sop       ; reselect main window
        ret

; Subroutines to close files
; Enter at closefiles for all, closeoutput otherwise

.closefiles
        ld      a,(openfiles)
        and     1
        jr      z,closeoutput   ; move on if input not open
        ld      ix,(inhandle)
        call    oz_gn_cl        ; close input file
        ld      a,(openfiles)
        and     6               ; flag input closed
        ld      (openfiles),a
.closeoutput
        ld      a,(openfiles)
        ld      b,a             ; save open files flag
        and     2
        jr      z,closeoi       ; move on if output closed
        ld      ix,(outhandle)
        call    oz_gn_cl
        ld      a,b
        and     5               ; clear output open flag
        ld      b,a
.closeoi
        ld      a,b
        and     4
        jr      z,endclose      ; move on if oi closed
        ld      ix,(oihandle)
        call    oz_gn_cl
        ld      a,b
        and     3               ; clear oi open flag
        ld      b,a
.endclose
        ld      a,b
        ld      (openfiles),a   ; save open files flag
        ret

; The error handling routine for during inflation
; All non-fatal errors come here

.inf_err
        push    af
        call    closefiles
        call    oz_gn_nln
        pop     af
        cp      rc_ovf          ; check for error in ZIP
        jr      nz,othererr
        ld      hl,msg_ziperr
        call    oz_gn_sop
        jr      allerrs
.othererr
        call    oz_gn_esp
        call    oz_gn_soe       ; display non-fatal error message
.allerrs
        ld      hl,error_beep
        call    oz_gn_sop       ; make a noise
        ld      de,stacksig     ; stack signature
.getsig pop     hl
        and     a
        sbc     hl,de
        jr      nz,getsig       ; loop until found 1st
        pop     hl
        and     a
        sbc     hl,de
        jr      nz,getsig       ; try again if not twice
        jp      restart

; Cursor control

.msg_setcur
        defm    1, "3@", 0

; Window definitions & messages

.windows
        defm    1, "7#1", 33, 32, 111, 40, 131
        defm    1, "2I1"
        defm    1, "4+TUR", 1, "2JC", 1, "3@", 32, 32
        defm    "Unzip v1.12 by Garry Lancaster"
        defm    1, "3@", 32, 32, 1, "2A", 112
        defm    1, "7#1", 33, 33, 111, 39, 129
        defm    1, "2C1", 1, "2+S"

        defm    1, "7#2", 114, 32, 43, 38, 131
        defm    1, "2I2"
        defm    1, "4+TUR", 1, "2JC", 1, "3@", 32, 32
        defm    "Options"
        defm    1, "3@", 32, 32, 1, "2A", 12
        defm    1, "7#2", 114, 33, 43, 37, 129
        defm    1, "2C2"
        defm    13, 10, "  Extract", 13, 10
        defm    "  Overwrite"
        defm    "  Paths"

        defm    1, "7#3", 114, 38, 43, 34, 131
        defm    1, "2I3"
        defm    1, "4+TUR", 1, "2JC", 1, "3@", 32, 32
        defm    "Progress"
        defm    1, "3@", 32, 32, 1, "2A", 12
        defm    1, "7#3", 114, 39, 43, 33, 129
        defm    1, "2C3"
        defm    "    00%"

        defb    0

.use_opt        defm    1, "2H2", 0
.at_opt         defm    1, "2X", 32, 1, "2Y", 0
.use_main       defm    1, "2H1", 0
.opt_on         defm    " ", 1, 245, 0
.opt_off        defm    "  ", 0
.opt_ask        defm    1, 241, 0
.error_beep     defm    13, 10, 13, 10, 7, 7, 0
.msg_ziperr     defm    "Error in ZIP file", 0
.msg_presize    defm    " (", 0
.msg_midsize    defm    " ", 1, 249, " ", 0
.msg_endsize    defm    ")", 0
