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

; Input routines for Unzip

        module  input

include "saverst.def"
include "stdio.def"
include "data.def"

        xdef    getline,getkey

        xref    errhandler,showoptions,doquit,noredraw
        xref    savecursor,setcursor
        xref    oz_gn_sop,oz_gn_sip,oz_gn_nln
        xref    oz_os_in,oz_os_sr

; Subroutine to get a line of input at WORKAREA (also accepts mail)

.getline
        call    noredraw
        ld      (lastmsg),hl
        call    oz_gn_sop       ; output prompt
        call    savecursor
        ld      a,$08           ; empty buffer, allow commands
.reinput
        push    af
        call    setcursor
        ld      de,mail_name
        ld      b,0
        ld      hl,workarea
        ld      c,80
        ld      a,sr_rpd
        call    oz_os_sr        ; check for mail
        jr      c,notmail
        pop     af
        ld      a,$09           ; set input exists
        push    af
.notmail
        ld      hl,cursor_on
        call    oz_gn_sop       ; turn on cursor
        ld      de,workarea
        pop     af
        ld      b,80
        call    oz_gn_sip       ; get a line
        call    c,errhandler    ; deal with pre-emption issues
        call    docommands      ; deal with any commands
        ld      hl,cursor_off
        call    oz_gn_sop       ; turn cursor off
        cp      in_ent
        ld      a,$09
        jr      nz,reinput      ; try again if not finished
        call    oz_gn_nln
        ret

; Subroutine to wait for a key from a list of options in DE
; Any letters in list should be lowercase

.getkey ld      (lastmsg),hl
        call    setcursor
        call    oz_gn_sop       ; display prompt
.retry  call    oz_os_in        ; get a key
        call    c,errhandler    ; deal with pre-emption
        call    docommands      ; deal with any commands
        ld      h,d             ; get start of keylist
        ld      l,e
        push    de              ; save keylist start
        cp      'A'
        jr      c,notupper
        cp      'Z'+1
        jr      nc,notupper
        or      $20             ; convert uppercase to lower
.notupper
        ld      d,a             ; D=key
.nextkey
        ld      a,(hl)          ; fetch next possibility
        inc     hl
        and     a
        jr      z,listend       ; move on if end of list
        cp      d
        jr      nz,nextkey      ; back if no match
        pop     de
        ret                     ; exit with A=key
.listend
        pop     de
        jr      retry


; Subroutine to handle command codes (in A)

.docommands
        cp      $80
        ret     c               ; exit if not a command
        cp      commands+$80
        ret     nc              ; or if invalid command code
        push    af
        push    de
        push    hl
        sub     $80             ; convert command code
        jp      z,doquit        ; perform Quit
        ld      hl,optcycles-1
        ld      e,a             ; e=option 1-4
        ld      d,0
        add     hl,de
        ld      d,(hl)          ; d=cycle of options
        ld      a,(options)     ; get current options
        ld      h,e
.findopt
        dec     h
        jr      z,gotopt
        rrca
        rrca
        jr      findopt
.gotopt rrca
        rl      h
        rrca
        rl      h
        inc     h
.findnewopt
        dec     h
        jr      z,gotnewopt
        rl      d
        rl      d
        jr      findnewopt
.gotnewopt
        rl      d
        rla
        rl      d
        rla
        ld      h,e
.putnewopt
        dec     h
        jr      z,donenewopt
        rlca
        rlca
        jr      putnewopt
.donenewopt
        ld      (options),a
        pop     hl
        pop     de
        call    showoptions
        pop     af
        ret

; Option cycles

.optcycles
        defb    @01001011       ; Extract (Off/On/Ask)
        defb    @01001011       ; Overwrite (Off/On/Ask)
        defb    @01100011       ; Paths (Off/On)

; Mail ID

.mail_name
        defm    "NAME", 0

; Cursor on/off

.cursor_on
        defm    1, "2+C", 0
.cursor_off
        defm    1, "2-C", 0
