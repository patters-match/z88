module WavPlay

; ********************************************************************************************
; WavPlay
; 0.3 - 09.01.1999
; A Wav file player for the Z88
; Thierry Peycru (pek@users.sourceforge.net)
;
; This is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with it;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; ********************************************************************************************

        INCLUDE "error.def"
        INCLUDE "director.def"
        INCLUDE "fileio.def"
        INCLUDE "saverst.def"
        INCLUDE "stdio.def"
        INCLUDE "interrpt.def"

        DEFC unsafe_ws = $100
        DEFC ram_vars  = $1FFE - unsafe_ws
        DEFVARS ram_vars
        {
        buffer   ds.b 64
        }

        ORG $E200

; The application DOR
.dor
        DEFS 9
        DEFB $83,len1-len0
.len0
        DEFM '@',18
        DEFM 0,0                                 ; reserved
        DEFB 'W'
        DEFB 0                                   ; 8K / 40K contiguous
        DEFW $0000,unsafe_ws,$0000,app_entry
        DEFB $00,$00,$00,$3F                     ; binding
        DEFB $0C,$01                             ; ugly popdown
        DEFM 'H',12
        DEFW topic
        DEFB $3F
        DEFW command
        DEFB $3F
        DEFW help
        DEFB $3F
        DEFS 3
        DEFM 'N',8,"WavPlay",0,$FF
.len1

.topic
        DEFW 0
.command
        DEFW 0
.help
        DEFM $7F,"Plays a WAV file marked from the Filer"
        DEFM $7F,"(WAV format at 11KHz, 8bits, Mono)"
        DEFM $7F,"V0.3 by Thierry Peycru (1999-2004) under GPL"
        DEFB 0

.app_entry
        call app_start
        scf
        ret

.app_start
        XOR A
        LD B,A
        LD HL,error_handler
        CALL_OZ os_erh
        LD A,5
        CALL_OZ os_esc
        CALL app_main
.kill
        CALL C,error_box
        XOR A
        CALL_OZ os_bye
.error_box
        CALL_OZ gn_err
        CP A
        RET

.error_handler
        RET Z
        CP rc_esc
        JR Z,akn_esc
        CP rc_quit
        JR Z,kill
        CP A
        RET
.akn_esc
        LD A,1
        CALL_OZ os_esc
        CP A
        RET

.NAME_TYPE
        defm "NAME",0

.app_main

;File open
        ld a,SR_RPD
        ld de,NAME_TYPE
        ld bc,$0040
        ld hl,buffer
        call_oz OS_SR
        ld a,RC_ONF
        ret c
        ld bc,$0040
        ld hl,buffer
        ld de,buffer
        ld a,OP_IN
        call_oz GN_OPF
        ret c
        ld de,0
        ld a,FA_EXT
        call_oz os_frm
        push bc                                  ; should verify filelenght
        ld hl,0
        ld de,$2000
        call_oz os_mv
        cp a
        call_oz gn_cl

;transform the wav
;only for 11KHz, 8 Bits, Mono
;keep only the 4 most significant bits
;ie 4 bits PCM, Mono, 11KHz
        ld hl,$2000
        ld de,$A000
.tloop
        ld a,(hl)
        rrca
        rrca
        rrca
        rrca
        and $0F
        ld (hl),a
        inc hl
        dec de
        ld a,d
        or e
        jr nz,tloop

;play the sample at $2000, length $2000
        pop de
        ld hl,$2000
        call oz_di
.ploop
        inc hl
        ld a,15
        ld b,(hl)
        sub b
        ld c,a
        dec de
        ld a,d
        or e
        jr z,done

;HIGH time
        ld a,5
        out ($B0),a
.Bloop
        nop
        nop
        djnz Bloop

;LOW time
        ld a,69
        out ($B0),a
.Cloop
        nop
        dec c
        jr nz,Cloop
        jr Ploop

.done
        ld a,5
        out ($B0),a
        call oz_ei
        cp a
        ret
