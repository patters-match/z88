module zmonitor

; ********************************************************************************************
; ZMonitor
; 5.3 - 1999
; Z88 simple memory dump
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

        include "error.def"
        include "director.def"
        include "stdio.def"
        include "saverst.def"
        include "memory.def"
        include "fileio.def"
        include "integer.def"

        defc safe_ws = $100
        defc ram_vars = $1FFE-safe_ws


        DEFVARS ram_vars
        {
        oldbank2  ds.b 1
        bank2     ds.b 1
        adr       ds.w 1
        offset    ds.b 1
        seaval    ds.w 1
        staval    ds.w 1
        lenval    ds.w 1
        badbyt    ds.w 1
        badtot    ds.w 1
        buff      ds.b $40
        buf2      ds.b $40
        }

        ORG $C000

.dor
        defw 0
        defb 0
        defw 0
        defb 0
        defw 0
        defb 0
        defm $83,$2A,"@",$12,0,0,"M"
        defb 0
        defw 0
        defw 0
        defw safe_ws
        defw app_entry
        defb 0
        defb 0
        defb 0
        defb $3F
        defb 1
        defb 1
        defm "H"
        defb $0C
        defw topic
        defb $3F
        defw command
        defb $3F
        defw help
        defb $3F
        defw 0
        defb 0
        defm "N",$09,"ZMonitor",0,$FF
.topic
        defb 0
.tco0
        defm tco1-tco0,"Commands",0,0,tco1-tco0
.tco1
        defb 0
.command
        defb 0
.cna0
        defm cna1-cna0,2,"A",0,"New address",0,0,cna1-cna0
.cna1

.csv0
        defm csv1-csv0,4,"SV",0,"Search value",0,0,csv1-csv0
.csv1

.csi0
        defm csi1-csi0,3,"SI",0,"System informations",0,0,csi1-csi0
.csi1

.cfs0
        defm cfs1-cfs0,5,"FS",0,"Save binary file",0,0,cfs1-cfs0
.cfs1

.cnp0
        defm cnp1-cnp0,$FE,$FE,0,"Next page     (+$80)",0,1,cnp1-cnp0
.cnp1

.cpp0
        defm cpp1-cpp0,$FF,$FF,0,"Previous page (-$80)",0,0,cpp1-cpp0
.cpp1

.cnk0
        defm cnk1-cnk0,$FA,$FA,0,"Next kilo    (+$400)",0,0,cnk1-cnk0
.cnk1

.cpk0
        defm cpk1-cpk0,$FB,$FB,0,"Previous kilo(-$400)",0,0,cpk1-cpk0
.cpk1

.cto0
        defm cto1-cto0,$F6,$F6,0,"Top          ($0000)",0,0,cto1-cto0
.cto1

.cbo0
        defm cbo1-cbo0,$F7,$F7,0,"Bottom       ($3FFF)",0,0,cbo1-cbo0
.cbo1
        defb 0
.help
        defm $7F,"Z88 memory dump application"
        defm $7F,"V5.3 by Thierry Peycru (1993-2004) under GPL",0

.app_entry
        JP app_start
        SCF
        RET


.app_start
        XOR A
        LD B,A
        LD HL,errhan
        CALL_OZ(os_erh)
        LD A,5
        CALL_OZ(os_esc)
        LD BC,$0002
        CALL_OZ(os_mpb)
        LD A,B
        LD (oldbank2),A
        JP app_main


.errhan
        RET Z
        CP rc_esc
        JR Z,akn_esc
        CP rc_quit
        JR Z,kill
        CP A
        RET


.akn_esc
        LD A,1
        CALL_OZ(os_esc)
        CP A
        RET


.kill
        LD A,(oldbank2)
        LD B,A
        LD C,2
        CALL_OZ(os_mpb)
        XOR A
        CALL_OZ(os_bye)


.win1
        PUSH HL
        CALL greywin
        LD HL,win1def
        CALL_OZ(gn_sop)
        POP HL
        RET


.win2
        PUSH HL
        CALL greywin
        LD HL,win2def
        CALL_OZ(gn_sop)
        POP HL
        RET

.greywin
        LD HL,greydef
        CALL_OZ(gn_sop)
        RET


.yourref
        LD DE,buff
        LD HL,refmes
        LD BC,6
        LDIR
        EX DE,HL
        LD A,(bank2)
        CALL putareg
        PUSH HL
        LD HL,offset
        LD A,(adr+1)
        AND 63
        OR (HL)
        POP HL
        CALL putareg
        LD A,(adr)
        CALL putareg
        XOR A
        LD (HL),A
        LD HL,buff
        CALL_OZ(dc_nam)
        RET


.putareg
        PUSH AF
        AND 240
        RRA
        RRA
        RRA
        RRA
        CALL puthex
        INC HL
        POP AF
        AND 15
        CALL puthex
        INC HL
        RET


.puthex
        PUSH HL
        LD H,0
        LD L,A
        LD DE,hexnumb
        ADD HL,DE
        LD A,(HL)
        POP HL
        LD (HL),A
        RET


.v8b
        PUSH BC
        LD B,8
.loophex
        LD A,(HL)
        CALL hexbyte
        CALL displspace
        INC HL
        DJNZ loophex
        POP BC
        RET


.v8a
        PUSH BC
        LD B,8
.loopasc
        LD A,(HL)
        CALL ascbyte
        INC HL
        DJNZ loopasc
        POP BC
        RET


.displspace
        PUSH AF
        LD A,$20
        CALL_OZ(os_out)
        POP AF
        RET


.rdch
        CALL_OZ(os_in)
        JR NC,rdch2
        CP rc_susp
        JR Z,rdch
        SCF
        RET
.rdch2
        CP 0
        RET NZ
        CALL_OZ(os_in)
        RET


.pwait
        LD A,sr_pwt
        CALL_OZ(os_sr)
        JR NC,pwt2
        CP rc_susp
        JR Z,pwait
        SCF
        RET
.pwt2
        CP 0
        RET NZ
        CALL_OZ(os_sr)
        RET


.yes_no
        PUSH HL
        CALL_OZ(gn_sop)
        LD H,D
        LD L,E
        CALL_OZ(gn_sop)
        POP HL
        CALL rdch
        RET C
        CP 13
        JR NZ,yes_no_a
        LD A,E
        CP yes_mes%256
        RET
.yes_no_a
        OR 32
        CP 'y'
        JR NZ,yes_no_b
        LD DE,yes_mes
        JR yes_no
.yes_no_b
        CP 'n'
        JR NZ,yes_no
        LD DE,no_mes
        JR yes_no


.str8
        PUSH BC
XOR A
CALL ctq
RLA
RLA
RLA
RLA
INC DE
CALL ctq
INC DE
POP BC
RET
.ctq
PUSH AF
LD A,(DE)
LD HL,hexnumb
LD BC,$0010
CPIR
LD A,$0F
SUB C
LD C,A
POP AF
ADD A,C
RET


.str16
PUSH AF
CALL str8
PUSH AF
CALL str8
LD E,A
POP AF
LD D,A
POP AF
RET


.hexbyte
PUSH HL
PUSH DE
PUSH AF 
AND 240
RRA
RRA
RRA
RRA
CALL affq
POP AF
AND 15
CALL affq
POP DE
POP HL
RET
.affq
LD H,0
LD L,A
LD DE,hexnumb
ADD HL,DE
LD A,(HL)
CALL_OZ(os_out)
RET


.ascbyte
CP $20
JR C,point
CP $7F
JR NC,point
call_oz(os_out)
RET
.point
LD A,46
call_oz(os_out)
SCF
RET


.redidem
LD HL,(adr)
LD DE,$0080
SBC HL,DE
LD (adr),HL
JR redraw


.app_main
LD HL,$8000
LD (adr),HL
LD A,$C0
LD (offset),A


.redraw
CALL win1
.dumppage
CALL yourref
LD A,12
CALL_OZ(os_out)
.dumprout2
LD B,8
.pageloop
PUSH BC
CALL displspace
LD A,(bank2)
CALL hexbyte
LD HL,offset
LD DE,(adr)
LD A,D
AND 63
OR (HL)
CALL hexbyte
LD A,E
CALL hexbyte
CALL displspace
CALL displspace
LD HL,(adr)
PUSH HL
CALL v8b
CALL displspace
CALL v8b
CALL displspace
POP HL
CALL v8a
CALL displspace
CALL v8a
LD (adr),HL
POP BC
LD A,B
CP 1
JR Z,pasnln
CALL_OZ(gn_nln)
.pasnln
DJNZ pageloop


.in
CALL rdch
JR NC,noerr
CP rc_quit
JP Z,kill
CP rc_draw
JP Z,redidem
CP rc_esc 
JR Z,okesc
.nopbem
CP A
JR in


.okesc
LD A,1
CALL_OZ(os_esc)
JR nopbem


.noerr
CP $20
JP Z,nextpage
CP $FE
JP Z,nextpage
CP $FF
JP Z,prevpage
CP $FA
JP Z,nextkilo
CP $FB
JP Z,prevkilo
CP $F6
JP Z,top
CP $F7
JP Z,bottom
CP 2
JP Z,nparam
CP 3
JP Z,sysinf
CP 4
JP Z,search
CP 5
JP Z,fsave
JP in


.nextpage
LD HL,(adr)
LD A,H
CP $C0
JP NZ,dumppage
LD HL,$BF80
LD (adr),HL
JP dumppage


.prevpage
LD HL,(adr)
LD A,H
CP $80
JP NZ,prevp2
LD A,L
CP $80
JR Z,prevp3
.prevp2
LD DE,$100
.prevpx
SBC HL,DE
LD (adr),HL
JP dumppage
.prevp3
LD DE,$80
JR prevpx


.nextkilo
LD (adr),HL
LD DE,$400
ADD HL,DE
LD A,H
CP $C0
JP Z,top
LD (adr),HL
JP dumppage


.prevkilo
LD HL,(adr)
LD DE,$400
SBC HL,DE
LD A,H
CP $80
JR C,bottom
LD (adr),HL
JP dumppage


.top
LD HL,$BF80
LD (adr),HL
JP dumppage


.bottom
LD HL,$8000
LD (adr),HL
JP dumppage


.nparam
CALL win2
CALL_OZ(gn_nln)
LD HL,pent_ms
CALL_OZ(gn_sop)
CALL_OZ(gn_nln)
CALL_OZ(gn_nln)
LD HL,nbnkmes
CALL_OZ(gn_sop)
LD A,(bank2)
CALL hexbyte
CALL_OZ(gn_nln)
LD HL,nadrmes
CALL_OZ(gn_sop) 
LD HL,(adr)
LD A,H
AND 63
PUSH HL
LD HL,offset
OR (HL)
POP HL
CALL hexbyte
LD A,L
CALL hexbyte


.bnkinp
LD HL,nbnkloc
CALL_OZ(gn_sop)
LD HL,buff
LD A,(bank2)
CALL putareg
XOR A
LD (HL),A
LD DE,buff
LD A,15
LD B,3
LD C,0
CALL_OZ(gn_sip)
JP C,bnkerr
PUSH AF
LD DE,buff
CALL str8
LD (bank2),A
LD B,A
LD C,2
CALL_OZ(os_mpb)
POP AF
CP $0D
JP Z,redraw
CP $FE
JP Z,adrinp
CP $FF
JP Z,adrinp
JR bnkinp
.bnkerr
LD HL,nparam
JP interr


.adrinp 
LD HL,nadrloc
CALL_OZ(gn_sop)
LD HL,buff
LD A,(offset)
LD C,A
LD A,(adr+1)
AND 63
OR C
CALL putareg
LD A,(adr)
CALL putareg
XOR A
LD (HL),A
LD DE,buff
LD A,15
LD B,5
LD C,0
CALL_OZ(gn_sip)
JP C,bnkerr
PUSH AF
LD DE,buff
CALL str16
LD A,D
AND 192
LD (offset),A
LD A,D
AND 63
OR 128
LD D,A
LD A,E
AND 128
LD E,A
LD (adr),DE
CALL yourref
POP AF
CP $0D
JP Z,redraw
CP $FE
JP Z,bnkinp
CP $FF
JP Z,bnkinp
JR adrinp


.interr
CP rc_susp
JR Z,nopb
CP rc_quit
JP Z,kill
CP rc_esc 
JR Z,pageret
CP rc_draw
JR Z,nopb
.nopb
CP A
JP (HL)
.pageret
LD A,1
CALL_OZ(os_esc)
JP redidem  


.sysinf
CALL win2
LD HL,nocur
CALL_OZ(gn_sop)
LD A,12
CALL_OZ(os_out)
LD HL,si1mes
CALL_OZ(gn_sop)
CALL_OZ(gn_nln)
LD HL,si2mes
CALL_OZ(gn_sop)
LD A,fa_ext
CALL ixfrm
LD A,C
LD (buff),A
LD A,B
LD (buff+1),A
LD A,E
LD (buff+2),A
LD A,D
LD (buff+3),A
LD HL,buff
LD DE,buf2
LD A,1
CALL_OZ(gn_pdn)
XOR A
LD (DE),A
LD HL,buf2
CALL_OZ(gn_sop)
LD HL,si3mes
CALL_OZ(gn_sop)
CALL_OZ(gn_nln)
LD HL,si4mes
CALL_OZ(gn_sop)
LD A,fa_ptr
CALL ixfrm
PUSH BC
LD B,D
LD C,E
LD HL,2
LD DE,buff
LD A,1
CALL_OZ(gn_pdn)
XOR A
LD (DE),A
LD HL,buff
CALL_OZ(gn_sop)
CALL_OZ(gn_nln)
LD HL,si5mes
CALL_OZ(gn_sop)
POP BC
LD HL,2
LD DE,buff
LD A,1
CALL_OZ(gn_pdn)
XOR A
LD (DE),A
LD HL,buff
CALL_OZ(gn_sop)
CALL_OZ(gn_nln)
LD HL,si6mes
CALL_OZ(gn_sop)
LD A,fa_eof
CALL ixfrm
JR Z,expanded
LD HL,unxmes
JR affexp
.expanded
LD HL,expmes
.affexp
CALL_OZ(gn_sop)
CALL_OZ(gn_nln)
LD HL,si7mes
CALL_OZ(gn_sop)
.insi
CALL rdch
JR NC,insi
LD HL,sysinf
JP interr
.ixfrm
LD IX,$FFFF
LD DE,0
CALL_OZ(os_frm)
RET


.search
CALL win2
CALL_OZ(gn_nln)
LD HL,sevmes1
CALL_OZ(gn_sop)
LD A,(bank2)
CALL hexbyte
CALL_OZ(gn_nln)
LD HL,sevmes2
CALL_OZ(gn_sop)
LD HL,sevstr
LD DE,buff
LD BC,5
LDIR 
LD DE,buff
LD A,39
LD BC,$0500
LD L,B 
CALL_OZ(gn_sip)
JP C,severr
LD DE,buff
CALL str16
LD (seaval),DE
CALL win2
LD HL,$8000
LD BC,$4000
.search2
LD A,(seaval)
CPIR
LD A,B
CP 0
JR Z,endsearch
LD A,C
CP 0
JR Z,endsearch
LD A,(seaval+1)
CP (HL)
JR NZ,search2
PUSH HL
CALL_OZ(gn_nln)
LD HL,foundmes
CALL_OZ(gn_sop)
POP HL
DEC HL
LD A,H
OR 192
CALL hexbyte
LD A,L
CALL hexbyte
PUSH DE
PUSH HL
CALL pwait
POP HL
POP DE
JR C,severr
INC HL
INC HL
JR search2
.endsearch
CALL_OZ(gn_nln)
LD HL,si7mes
CALL_OZ(gn_sop)
.sevendpwt
CALL pwait
JR C,severr
JR sevendpwt
.severr LD HL,search
JP interr


.fsave
CALL win2
ld hl,wbkmes
call_oz(gn_sop)
ld a,(bank2)
call hexbyte
CALL_OZ(gn_nln)
LD HL,stames
CALL_OZ(gn_sop)
LD HL,stastr
LD DE,buff
LD BC,5
LDIR
LD DE,buff
LD A,39
LD BC,$0500
LD L,B
CALL_OZ(gn_sip)
JP C,fsaverr
LD DE,buff
CALL str16
LD A,D
AND 63
OR 128
LD D,A
LD (staval),DE
CALL_OZ(gn_nln)
LD HL,lenmes
CALL_OZ(gn_sop)
LD HL,lenstr
LD DE,buff
LD BC,5
LDIR
LD DE,buff
LD A,39
LD BC,$0500
LD L,B
CALL_OZ(gn_sip)
JP C,fsaverr
LD DE,buff
CALL str16
LD A,D
AND 63
OR 128
LD D,A
LD HL,(staval)
EX DE,HL
SBC HL,DE
INC HL
LD (lenval),HL
.fnaminp
CALL_OZ(gn_nln)
LD HL,fnames
CALL_OZ(gn_sop)
LD DE,buff
LD A,32
LD BC,$2000
LD L,B
CALL_OZ(gn_sip)
JP C,fsaverr
LD BC,$0020
LD A,1
LD HL,buff
LD DE,buf2
CALL_OZ(gn_opf)
JR C,fileok
CALL_OZ(gn_cl)
CALL_OZ(gn_nln)
LD HL,eximes
LD DE,no_mes
CALL yes_no
JR Z,fileok
JR fnaminp
.fileok
CALL win2
CALL_OZ(gn_nln)
LD HL,cl1mes
CALL_OZ(gn_sop)
LD A,(bank2)
CALL hexbyte
LD HL,(staval)
LD A,H
AND 63
OR 192
CALL hexbyte
LD A,L
CALL hexbyte
CALL_OZ(gn_nln)
LD HL,cl2mes
CALL_OZ(gn_sop)
LD HL,(lenval)
LD A,H
CALL hexbyte 
LD A,L
CALL hexbyte
CALL_OZ(gn_nln)
LD HL,cl3mes
CALL_OZ(gn_sop)
LD HL,buff
CALL_OZ(gn_sop)
CALL_OZ(gn_nln)
CALL_OZ(gn_nln)
LD HL,cl4mes
LD DE,yes_mes
CALL yes_no
JP NZ,redidem  
LD BC,$0020
LD A,2
LD HL,buff
LD DE,buf2
CALL_OZ(gn_opf)
JP C,fsaverr
LD BC,(lenval)
LD HL,(staval)
LD DE,0
CALL_OZ(os_mv)
JP C,mverr
CALL_OZ(gn_cl)
JP redidem
.mverr PUSH AF
CALL_OZ(gn_cl)
POP AF
.fsaverr LD HL,fsave
JP interr



.win1def
defm 1,"7#1",33,32,109,40,129,1,"2C1",0
.win2def
defm 1,"2G+",1,"7#2",42,33,72,39,131
defm 1,"2C2",1,"4+TUR",1,"2JC"
defm 1,"3@  ZMONITOR V5.3",1,"3@  "
defm 1,"2A",72,1,"4-TUR",1,"2JN"
defm 1,"7#2",42,34,72,38,129,1,"2C2",1,"3+CS",0
.greydef defm 1,"6#8  ",$7E,$28,1,"2H8",1,"2G+",0
.yes_mes defm "Yes",0
.no_mes defm "No ",8,0
.hexnumb defm "0123456789ABCDEF",0
.refmes defm "At : $",0
.nbnkmes defm "  Bank    : $",0
.nadrmes defm "  Address : $",0
.nbnkloc defm 1,"3@",45,35,0
.nadrloc defm 1,"3@",45,36,0
.sevmes1 defm " Working in bank : $",0
.sevmes2 defm " Word to search  : $",0
.foundmes defm " Found at  : $",0
.sevstr defm "0000",0
.wbkmes defm  " Working in bank : $",0
.stames defm  " Start address   : $",0
.lenmes defm  " End address     : $",0 
.fnames defm  " Filename  ",0
.eximes defm 13,"File already exists : overwrite ? ",0
.stastr defm "C000",0
.lenstr defm "C000",0
.cl1mes defm "Physical address start  : $",0
.cl2mes defm "Number of bytes to copy : $",0
.cl3mes defm "Into file ",0
.cl4mes defm 13,"Copy memory into file ? ",0
.nocur  defm 1,"2-C",0
.si1mes defm 1,"T       SYSTEM INFORMATIONS",1,"T",0
.si2mes defm " Free memory       :",0
.si3mes defm " bytes",0
.si4mes defm " Free handles      :",0
.si5mes defm " ROM version code  :",0
.si6mes defm " Machine type      :",0
.si7mes defm 1,"T       PRESS ",1,228," TO RESUME",1,"T",0
.expmes defm "Expanded Z88",0
.unxmes defm "Unexpanded Z88",0
.pent_ms defm 1,"T   USE ",1,242,1,243," AND PRESS ",1,225," WHEN READY",1,"T",0

