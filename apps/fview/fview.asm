module fview

; ********************************************************************************************
; FileView
; 1.3 - 29.12.1997
; Text file viewer
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
        
        DEFC unsafe_ws = $100
        DEFC ram_vars  = $1FFE - unsafe_ws
        
        DEFVARS ram_vars
        {
         buf1 ds.b 64
        }    
        
        org $E000
        
.dor
        DEFS 3
        DEFS 3
        DEFS 3
        DEFB $83,len1-len0
.len0
        DEFM "@",inf1-inf0
.inf0
        DEFM 0,0,"W",0
        DEFW $0000,unsafe_ws,$0000,app_entry
        DEFB $00,$00,$00,$3F,$09,$01
.inf1
        DEFM "H",12
        DEFW topic
        DEFB $3F
        DEFW command
        DEFB $3F
        DEFW help
        DEFB $3F
        DEFS 3
        DEFM "N",9,"FileView",0,$FF
.len1
.topic
        DEFW 0
.command
        DEFW 0
.help
        DEFM $7F,"Displays a text file marked from the FILER"
        DEFM $7F,"V1.3 by Thierry Peycru (1993-2004) under GPL",0

.app_entry
        CALL app_start
        SCF
        RET

.app_start
        XOR A
        LD B,A
        LD HL,err_han
        CALL_OZ os_erh
        LD A,5
        CALL_OZ os_esc
        CALL app_main

.app_exit
        XOR A
        CALL_OZ os_bye

.err_han
        RET Z
        CP rc_esc
        JR Z,akn_esc
        CP rc_quit
        JR Z,app_exit
        CP A
        RET

.akn_esc
        LD A,1
        CALL_OZ os_esc
        CP A
        RET

.app_main
        ld hl,winini_ms
        call_oz gn_sop
        ld a,sr_rpd
        ld de,mk_name
        ld bc,$0040
        ld hl,buf1
        call_oz os_sr
        jr c,nofile_error
        ld bc,$0040
        ld hl,buf1
        ld de,buf1
        ld a,1
        call_oz gn_opf
        jr c,errorbox

; D is the line counter (max 8 lines)
; B is the line length (max 80 char)
        call newpage

.chrloop
        CALL_OZ os_gb
        JR C,eof_error

;if CR
        CP $0D
        CALL Z,nextline
        LD E,A
;if <32
        AND @11100000
        CP 0
        JR Z,chrloop
;inc line length
        INC B
        LD A,B
        CP 80
        CALL Z,nextline
;else display char
        LD A,E
        CALL_OZ os_out
        JR chrloop

.nextline
        LD B,0
        INC D
        LD A,D
        CP 8
        JR Z,pagewait
        CALL_OZ gn_nln
        RET

.pagewait
        LD A,sr_pwt
        CALL_OZ os_sr
        JR NC,in2
        CP rc_esc
        JR Z,endmain
        CP A
        JR pagewait
.in2
        CP 0
        JR NZ,newpage
        CALL_OZ os_in

.newpage
        ld a,12
        call_oz os_out
        ld d,0
        ld b,d
        ret

.eof_error
        call close_file
        call resesc
        ret

.endmain
;destroy (call nextline) stacked
        pop hl
        call close_file
        ret

.nofile_error
        ld a,rc_onf

.errorbox
        call_oz gn_err
        ret

.close_file
        push af
        xor a
        call_oz gn_cl
        pop af
        ret

.resesc
        LD HL,resesc_ms
        CALL_OZ gn_sop
.escend
        CALL_OZ os_in
        JR NC,escend
        RET

.winini_ms
        DEFM 1,"6#8  ",$7E,$28,1,"2H8",1,"2G+"
        DEFM 1,"7#1",33,32,114,40,129,1,"2I1",1,"2+S",0
.mk_name
        DEFM "NAME",0
.resesc_ms
        DEFM 1,"T   PRESS ",1,$E4," TO RESUME",1,"T",0

