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
        xdef    noredraw,redraw,showoptions
        xdef    dispmsg,dispatcursor
        xdef    savecursor,setcursor
        xdef    closefiles

        xref    restart,oz_os_out,oz_gn_sop,oz_gn_pdn
        xref    oz_gn_nln,oz_gn_esp,oz_gn_soe,oz_os_esc
        xref    oz_os_nq,oz_gn_cl,oz_gn_wcl,oz_gn_del
        xref    msg_cdname

; Subroutine to clear the "redraw message stack"

.noredraw
        push    hl
        ld      hl,msgstack-1
        ld      (msgpointer),hl         ; empty message stack
        ld      (cursorstack),hl        ; set cursor position here
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
        or      a               ; clear error for rc_susp ,  rc_draw
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
        push    de
        push    af
        ld      hl,windows
        call    oz_gn_sop       ; show the windows
        call    showoptions     ; display selected options
        ld      de,msgstack-1   ; get message stackpointer
.showstack
        ld      hl,(cursorstack)
        and     a
        sbc     hl,de           ; check to save cursor here
        call    z,savecursor2   ; if so, save it
        ld      hl,(msgpointer)
        and     a
        sbc     hl,de           ; check for bottom of stack
        jr      z,exitredraw    ; exit if so
        ex      de,hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl           ; HL=message
        call    oz_gn_sop       ; display it
        jr      showstack       ; loop back
.exitredraw
        pop     af
        pop     de
        pop     hl
        ret

; Subroutine to save the current cursor position

.savecursor
        push    hl
        ld      hl,(msgpointer)
        ld      (cursorstack),hl; save message stack pointer
        pop     hl
.savecursor2
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
        ld      hl,(cursorstack)
        ld      (msgpointer),hl         ; reset stack to when cursor saved
        pop     hl
        pop     af
        ret

; Subroutine to display a message (in HL) and add it to the redraw stack
; Enter at DISPATCURSOR to reset to saved cursor position first

.dispatcursor
        call    setcursor
.dispmsg
        push    de
        push    hl
        call    oz_gn_sop       ; display it
        pop     de              ; DE has message address
        ld      hl,(msgpointer)
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d          ; stack message
        ld      (msgpointer),hl ; resave pointer
        pop     de              ; restore DE
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
        and     @00000001
        jr      z,closeoutput   ; move on if zip not open
        ld      ix,(ziphandle)
        call    oz_gn_cl        ; close input file
        ld      a,(openfiles)
        and     @11111110       ; flag input closed
        ld      (openfiles),a
.closeoutput
        ld      a,(openfiles)
        ld      b,a             ; save open files flag
        and     @00000010
        jr      z,closeinp      ; move on if Central directory closed
        ld      ix,(cdhandle)
        call    oz_gn_cl        ; close CD file
        ld      a,b
        and     @11111101       ; clear output open flag
        ld      b,a
.closeinp
        ld      a,b
        and     @00000100
        jr      z,closewild     ; move on if inp closed
        ld      ix,(inhandle)
        call    oz_gn_cl
        ld      a,b
        and     @11111011       ; clear inp open flag
        ld      b,a
.closewild
        ld      a,b
        and     @00001000
        jr      z,endclose      ; move on if wildcard handler closed
        ld      ix,(wldhandle)
        call    oz_gn_wcl
        ld      a,b
        and     @11110111       ; clear wild flag
        ld      b,a
.endclose
        ld      a,b
        ld      (openfiles),a   ; save open files flag
        push    bc
        push    hl
        ld      hl,msg_cdname
        ld      b,0
        call    oz_gn_del       ; delete any CD file (ignore errors)
        pop     hl
        pop     bc
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
        defm    "ZipUp v1.01 by Garry Lancaster"
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
        defm    13, 10, "  Delete", 13, 10
        defm    "  Compress", 13, 10
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
.msg_ziperr     defm    "Error compressing file", 0
.msg_presize    defm    " (", 0
.msg_midsize    defm    " ", 1, 249, " ", 0
.msg_endsize    defm    ")", 0
