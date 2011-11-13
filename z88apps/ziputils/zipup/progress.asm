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

; Progress meter routines

        module  progress

include "data.def"

        xdef    initprogress,showprogress,progressoff
        xref    oz_gn_sop,oz_gn_d24

; Initialise the progress meter

.initprogress
        ld      hl,(header+18)
        ld      a,(header+20)
        ld      b,a
        ld      c,0
        ld      de,100
        call    oz_gn_d24       ; find 1% of filesize
        ld      a,b
        or      h
        or      l
        jr      nz,nottiny      ; move on if > 99 bytes
        inc     l               ; 1% is 1 byte if not
.nottiny
        ld      (onepercent),hl
        ld      a,b
        ld      (onepercent+2),a
        ld      (cursizeK),hl
        ld      (cursizeK+2),a
        xor     a
        ld      (progpercent),a
        ld      hl,msg_noprog
        call    oz_gn_sop
        ld      a,$ff
        ld      (meteron),a     ; turn on meter
        ret

; Disable progress meter

.progressoff
        xor     a
        ld      (meteron),a
        ret

; Show current progress, preserving all registers

.showprogress
        push    af
        push    bc
        push    hl
        ld      a,(meteron)
        and     a
        jr      z,exitprog      ; exit if not turned on
        ld      hl,(cursizeK)
        ld      bc,1024
        and     a
        sbc     hl,bc
        ld      (cursizeK),hl
        jr      nc,exitprog
        ld      a,(cursizeK+2)
        dec     a
        ld      (cursizeK+2),a
        jr      c,updprog
.exitprog
        pop     hl
        pop     bc
        pop     af
        ret
.updprog
        push    de
        push    af
        ld      de,(onepercent)
        ld      a,(onepercent+2)
        ld      c,a
        ld      a,(progpercent)
        ld      b,a
        pop     af
.incprog
        add     hl,de
        adc     a,c
        inc     b
        jr      nc,incprog
        ld      (cursizeK),hl
        ld      (cursizeK+2),a
        ld      a,b
        ld      (progpercent),a
        cp      100
        jr      nc,hundred      ; on if 100%+
        ld      b,0
.find10s
        inc     b
        sub     10
        jr      nc,find10s
        add     a,10
        dec     b               ; B holds 10s, A holds units
        ld      hl,msg_progmess
        ld      de,progmessage
        push    bc
        ld      bc,msg_noprog-msg_progmess
        ldir
        pop     bc
        add     a,'0'
        ld      (progmessage+9),a
        ld      a,b
        add     a,'0'
        ld      (progmessage+8),a
        ld      hl,progmessage
        jr      outprog
.hundred
        ld      hl,msg_prog100
.outprog
        call    oz_gn_sop
        pop     de
        jr      exitprog

; Progress meter messages

.msg_progmess   defm    1, "2C3      %", 1, "2H1", 0
.msg_noprog     defm    1, "2C3    00%", 1, "2H1", 0
.msg_prog100    defm    1, "2C3   100%", 1, "2H1", 0
