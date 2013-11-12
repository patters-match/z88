module zdis

; ********************************************************************************************
; ZDisassembler
; 3.4 - 05.02.97
; Z88 disassembler
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
        include "stdio.def"
        include "saverst.def"
        include "memory.def"
        include "director.def"

        defc safe_ws = $100
        defc ram_vars = $1FFE-safe_ws

        DEFVARS ram_vars
        {
        oldbank ds.b 1
        bank    ds.b 1
        scroll  ds.b 1
        tabcnt  ds.b 1
        adrdis  ds.w 1
        adrpag  ds.w 1
        offset  ds.b 1
        izreg   ds.b 1
        buff    ds.b $40
        buf2    ds.b $40
        }


        ORG $CB00


.dor
        DEFW 0
        DEFB 0
        DEFW 0
        DEFB 0
        DEFW 0
        DEFB 0
        DEFM $83,$2A,"@",$12,0,0,"D"
        DEFB 0
        DEFW 0
        DEFW 0
        DEFW safe_ws
        DEFW app_entry
        DEFB 0
        DEFB 0
        DEFB 0
        DEFB $3F
        DEFB 1
        DEFB 1
        DEFM "H"
        DEFB $0C
        DEFW topic
        DEFB $3F
        DEFW command
        DEFB $3F
        DEFW help
        DEFB $3F
        DEFW 0
        DEFB 0
        DEFM "N",$07,"Z80Dis",0,$FF


.topic
        DEFB 0

.tco0
        DEFM tco1-tco0,"Commands",0,0,tco1-tco0
.tco1
        DEFB 0

.command
        DEFB 0
.cnp0
        DEFM cnp1-cnp0,$FE,$FE,0,"Next parameter",0,0,cnp1-cnp0
.cnp1
.cpp0
        DEFM cpp1-cpp0,$FF,$FF,0,"Previous parameter",0,0,cpp1-cpp0
.cpp1
.cdi0
        DEFM cdi1-cdi0,$0D,$E1,0,"Disassemble",0,0,cdi1-cdi0
.cdi1
.cng0
        DEFM cng1-cng0,$20,$E0,0,"Next page",0,1,cng1-cng0
.cng1
.ces0
        DEFM ces1-ces0,$1B,$1B,0,"Escape to menu",0,0,ces1-ces0
.ces1
        DEFB 0

.help
        defm $7F,"Z88 disassembler application"
        defm $7F,"V3.4 by Thierry Peycru (1993-2004) under GPL",0

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
        LD (oldbank),A
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
        LD C,2
        LD A,(oldbank)
        LD B,A
        CALL_OZ(os_mpb)
        XOR A
        CALL_OZ(os_bye)

.win1
        PUSH HL
        CALL greywin
        LD HL,win1def
        JR winfin

.win2
        PUSH HL
        CALL greywin
        LD HL,win2def
        
.winfin
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
        LD A,(bank)
        CALL putareg
        LD A,(adrdis+1)
        CALL putareg
        LD A,(adrdis)
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
        
.displspace
        PUSH AF
        LD A,(tabcnt)
        INC A
        LD (tabcnt),A
        LD A,$20
        CALL_OZ(os_out)
        POP AF
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
        LD A,(tabcnt)
        INC A
        INC A
        LD (tabcnt),A
        POP AF
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

.rb
        PUSH DE
        PUSH HL
        LD DE,(adrdis)
        LD A,D
        AND $3F
        OR 128
        LD D,A
        LD A,(DE)
        PUSH AF
        INC DE
        LD HL,offset
        LD A,D
        AND $3F
        OR (HL)
        LD D,A
        LD (adrdis),DE
        POP AF
        POP HL
        POP DE
        RET

.virg
        PUSH AF
        LD A,44
        RST $20
        DEFB os_out
        POP AF
        RET

.tabmn
        PUSH AF
        PUSH BC
        LD A,(tabcnt)
        LD B,A
        LD A,22
        SUB B
        LD B,A
.spaloop
        CALL displspace
        DJNZ spaloop
        POP BC
        POP AF
        RET

.depl
        PUSH BC
        PUSH HL
        PUSH AF
        LD HL,(adrdis)
        XOR A
        LD B,A
        POP AF
        BIT 7,A
        JR Z,posdepl
        CPL
        LD C,A
        SBC HL,BC
        DEC HL
        JR findepl
.posdepl
        LD C,A
        ADD HL,BC
.findepl
        LD A,H
        CALL hexbyte
        LD A,L
        CALL hexbyte
        POP HL
        POP BC
        RET

.sreg
        PUSH BC
        PUSH HL
        LD B,0
        LD C,A
        LD HL,sreglst
        ADD HL,BC
        LD A,(HL)
        CALL_OZ os_out
        CP '('
        JR Z,hl_out
        POP HL
        POP BC
        RET
.hl_out
        LD HL,hlpmes
        CALL_OZ(gn_sop)
        POP HL
        POP BC
        RET

.dreged
        LD A,B
        AND 48
        RRA
        RRA
        RRA
        RRA
        LD HL,rrrrlst
        CALL tab0
        RET


.tab0
        PUSH BC
        PUSH DE
        CP 0
        JR Z,affmn
        LD D,A
.tabloop
        XOR A
        LD BC,16
        CPIR
        DEC D
        LD A,D
        CP 0
        JR NZ,tabloop
.affmn
        CALL_OZ(gn_sop)
        POP DE
        POP BC
        RET
        
.dreg
        LD HL,dreglst
        CALL tab0
        RET

.adrind
        LD A,'('
        CALL_OZ os_out
        POP HL
        POP AF
        CALL hexbyte
        POP AF
        CALL hexbyte
        LD A,')'
        CALL_OZ os_out
        PUSH HL
        RET

.izd
        PUSH HL
        PUSH AF
        LD A,'('
        CALL_OZ(os_out)
        CALL izr
        LD A,'+'
        CALL_OZ(os_out)
        POP AF
        CALL hexbyte
        LD A,')'
        CALL_OZ(os_out)
        POP HL
        RET

.izr
        PUSH AF
        LD A,'I'
        CALL_OZ(os_out)
        LD A,(izreg)
        CALL_OZ(os_out)
        POP AF
        RET

.app_main
        CALL win1
        CALL yourref
        LD A,'X'
        LD (izreg),A
        LD HL,(adrdis)
        LD (adrpag),HL
        CALL_OZ(gn_nln)
        LD HL,intms1
        CALL_OZ(gn_sop)
        CALL_OZ(gn_nln)
        CALL_OZ(gn_nln)
        LD HL,intms3
        CALL_OZ(gn_sop)
        LD A,(bank)
        CALL hexbyte
        CALL_OZ(gn_nln)
        LD HL,intms4
        CALL_OZ(gn_sop)
        LD HL,(adrdis)
        LD A,H
        CALL hexbyte
        LD A,L
        CALL hexbyte
        CALL_OZ(gn_nln) 
        CALL_OZ(gn_nln)
        LD HL,intms5
        CALL_OZ(gn_sop)
.bnkinp
        LD HL,bnkloc
        CALL_OZ(gn_sop)
        LD HL,buff
        LD A,(bank)
        CALL putareg
        XOR A
        LD (HL),A
        LD DE,buff
        LD A,15
        LD B,3
        LD C,0
        CALL_OZ(gn_sip)
        PUSH AF
        LD DE,buff
        CALL str8
        LD (bank),A
        LD B,A
        LD C,2
        CALL_OZ(os_mpb)
        CALL yourref
        POP AF
        JR C,bnkerr
        CP $0D
        JP Z,disamain
        CP $FE
        JP Z,adrinp
        CP $FF
        JP Z,adrinp
        JR bnkinp
.bnkerr
        LD HL,bnkinp
        JP interr
.adrinp
        LD HL,adrloc
        CALL_OZ(gn_sop)
        LD HL,buff
        LD A,(adrdis+1)
        CALL putareg
        LD A,(adrdis)
        CALL putareg
        XOR A
        LD (HL),A
        LD DE,buff
        LD A,15
        LD B,5
        LD C,0
        CALL_OZ(gn_sip)
        PUSH AF
        LD DE,buff
        CALL str16
        LD (adrdis),DE
        LD (adrpag),DE
        LD A,D
        AND 192
        LD (offset),A
        CALL yourref
        POP AF
        JR C,adrerr
        CP $0D
        JP Z,disamain
        CP $FE
        JP Z,bnkinp
        CP $FF
        JP Z,bnkinp
        JR adrinp
.adrerr
        LD HL,adrinp
        jr interr
.interr
        CP rc_susp
        JP Z,nopb
        CP rc_quit
        JP Z,kill
        CP rc_esc
        JR Z,pageret
        CP rc_draw
        JP Z,app_main
.pageret
        PUSH HL
        LD A,1
        CALL_OZ(os_esc)
        POP HL
.nopb
        CP A
        JP (HL)

.disamain
        CALL win2
        LD HL,(adrpag)
        LD (adrdis),HL
.disaloop
        LD HL,(adrdis)
        LD (adrpag),HL
        CALL yourref
        CALL disapag
        CALL pwait
        JR NC,disaloop
        ;CCF
        CP rc_esc
        JP Z,app_main
        CP rc_draw
        JR Z,disamain
        CP rc_quit
        JP Z,kill
        JR disaloop
.disapag
        XOR A
        LD (scroll),A
.mainloop
        LD A,(scroll)
        INC A
        LD (scroll),A
        CP 9
        RET Z
        call_oz gn_nln
        XOR A
        LD (tabcnt),A
        CALL displspace
        LD A,(bank)
        CALL hexbyte
        LD HL,(adrdis)
        LD A,H
        CALL hexbyte
        LD A,L
        CALL hexbyte
        CALL displspace
        CALL displspace
        CALL rb
        LD B,A
        CALL hexbyte
        CALL displspace
        LD A,B
        AND 192
        CP 0
        JP Z,part1
        CP 64
        JP Z,part2
        CP 128
        JP Z,part3
        CP 192
        JP Z,part4
        RET

.part1
        LD A,B
        AND 231
        JP Z,part1a
        CP 32
        JP Z,jrcc
        CP 2
        JP Z,ldarr
        CP 34
        JP Z,ldaaa
        LD A,B
        AND 207
        CP 1
        JP Z,ldrrnn
        CP 9
        JP Z,addrr
        CP 3
        JP Z,incrr
        CP 11
        JP Z,decrr
        LD A,B
        AND 3
        JP Z,incs
        DEC A
        JP Z,decs
        DEC A
        JP Z,ldsn
        DEC A
        JP Z,part1b
        JP mainloop
.part1a
        LD A,B
        BIT 4,A
        JP Z,part1a1
        CALL rb
        PUSH AF
        CALL hexbyte
.part1a1
        CALL tabmn
        LD A,B
        AND 24
        RRA
        RRA
        RRA
        LD HL,part1alst
        CALL tab0
        LD A,B
        BIT 4,A
        JP Z,mainloop
        POP AF
        CALL depl
        JP mainloop
.jrcc
        LD A,B
        PUSH AF
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,jrmes
        CALL_OZ(gn_sop)
        POP BC
        POP AF
        PUSH BC
        AND 24
        RRA
        RRA
        RRA
        AND 3
        LD HL,cclst
        CALL tab0
        CALL virg
        POP AF
        CALL depl
        JP mainloop
.ldrrnn
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL displspace
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        CALL dreged
        CALL virg
        POP AF
        CALL hexbyte
        POP AF
        CALL hexbyte
        JP mainloop
.addrr
        CALL tabmn
        LD HL,addhlmes
        CALL_OZ(gn_sop) 
.affrr
        CALL dreged
        JP mainloop
.ldarr
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        LD A,B
        BIT 4,A
        JR NZ,ldade
        LD HL,bcimes
        JR ldarr1 
.ldade
        LD HL,deimes
.ldarr1
        LD A,B
        BIT 3,A
        JR NZ,adabord
        CALL_OZ(gn_sop)
        CALL virg
        LD A,65
        CALL_OZ(os_out)
        JP mainloop
.adabord
        LD A,65
        CALL_OZ(os_out)
        CALL virg
        CALL_OZ(gn_sop)
        JP mainloop
.ldaaa
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL displspace
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        LD A,B
        BIT 3,A
        JR NZ,adrapres
        CALL adrind
        CALL virg
        CALL ahlreg
        JP mainloop
.adrapres
        CALL ahlreg
        CALL virg
        CALL adrind
        JP mainloop
.ahlreg
        LD A,B
        BIT 4,A
        JR Z,hlreg
        LD A,65
        CALL_OZ(os_out)
        RET 
.hlreg
        LD HL,hlmes
        CALL_OZ(gn_sop)
        RET
.incrr
        CALL tabmn
        LD HL,incmes
        CALL_OZ(gn_sop)
        JP affrr
.decrr
        CALL tabmn
        LD HL,decmes
        CALL_OZ(gn_sop)
        JP affrr
.incs
        CALL tabmn
        LD HL,incmes
        CALL_OZ(gn_sop)
.affs
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        CALL sreg
        JP mainloop
.decs
        CALL tabmn
        LD HL,decmes
        CALL_OZ(gn_sop)
        JR affs
.ldsn
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        CALL sreg
        CALL virg
        POP AF
        CALL hexbyte
        JP mainloop
.part1b
        CALL tabmn
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        LD HL,part1blst
        CALL tab0
        JP mainloop
.part2
        CALL tabmn
        LD A,B
        CP $76
        JR Z,halt_mn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        CALL sreg
        CALL virg
        LD A,B
        AND 7
        CALL sreg
        JP mainloop
.halt_mn
        LD HL,haltmes
        CALL_OZ(gn_sop)
        JP mainloop
.part3
        CALL tabmn
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        LD HL,part3mn
        CALL tab0
        LD A,B
        AND 7
        CALL sreg
        JP mainloop
.part4
        LD A,B
        CP $CB
        JP Z,partcb
        CP $ED
        JP Z,parted
        CP $DD
        JP Z,partix
        CP $FD
        JP Z,partiy
        CP $CD
        JP Z,callmn
        CP $C3
        JP Z,jpmn
        AND 7
        CP 4
        JP Z,call_cc
        CP 2
        JP Z,jp_cc
        CP 0
        JP Z,ret_cc
        LD A,B
        CP $D3
        JP Z,outmn
        CP $DB
        JP Z,inmn
        AND 15
        CP 1
        JP Z,pop_rr
        CP 5
        JP Z,push_rr
        LD A,B
        AND 7
        CP 7
        JP Z,rst
        CP 6
        JP Z,part4mn1
        LD A,B
        AND 39
        CP 35
        JP Z,part4mn2
        LD A,B
        AND 15
        CP 9
        JP Z,part4mn3
        JP mainloop
.ret_cc
        CALL tabmn
        LD HL,retmes
        CALL_OZ(gn_sop)
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        LD HL,cclst
        CALL tab0
        JP mainloop
.pop_rr
        LD HL,popmes
        JR poppush
.push_rr
        LD HL,pushmes
        JR poppush
.poppush
        CALL tabmn
        CALL_OZ(gn_sop)
        LD A,B
        AND 48
        RRA
        RRA
        RRA
        RRA
        CALL dreg
        JP mainloop
.partix
        LD A,'X'
        LD (izreg),A
        JR partiz
.partiy
        LD A,'Y'
        LD (izreg),A
.partiz
        CALL rb
        LD B,A
        CALL hexbyte
        CALL displspace
        LD A,B
        CP $21
        JP Z,ldiznn
        CP $36
        JP Z,ldizdn
        CP $E1
        JP Z,popiz 
        CP $E5
        JP Z,pushiz
        CP $E3
        JP Z,exspiz
        CP $E9
        JP Z,jpiz
        CP $F9
        JP Z,ldspiz
        CP $CB
        JP Z,partcbiz
        LD A,B
        AND $F7
        CP $23
        JP Z,inciz
        CP $22
        JP Z,ldindiz
        LD A,B
        AND $C7
        CP $46
        JP Z,ldsizd
        CP $86
        JP Z,logizd
        LD A,B
        AND $CF
        CP $09
        JP Z,addizrr
        LD A,B
        AND $FE
        CP $34
        JP Z,incizd
        LD A,B
        AND $F8
        CP $70
        JP Z,ldizds
        CALL tabmn
        LD HL,ukmes
        CALL_OZ(gn_sop)
        JP mainloop
.ldiznn
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL rb
        PUSH AF
        CALL displspace
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        CALL izr
        CALL virg
        POP AF
        CALL hexbyte
        POP AF
        CALL hexbyte
        JP mainloop
.ldizdn
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL rb
        PUSH AF
        CALL displspace
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        POP DE
        POP AF
        PUSH DE
        CALL izd
        CALL virg
        POP AF
        CALL hexbyte
        JP mainloop
.popiz
        CALL tabmn
        LD HL,popmes
        CALL_OZ(gn_sop)
        CALL izr
        JP mainloop
.pushiz
        CALL tabmn
        LD HL,pushmes
        CALL_OZ(gn_sop)
        CALL izr
        JP mainloop
.exspiz
        CALL tabmn
        LD HL,exspmes
        CALL_OZ(gn_sop)
        CALL izr
        JP mainloop
.jpiz
        CALL tabmn
        LD HL,jpmes
        CALL_OZ(gn_sop)
        LD A,'('
        CALL_OZ(os_out)
        CALL izr
        LD A,')'
        CALL_OZ(os_out)
        JP mainloop
.ldspiz
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        LD HL,spmes
        CALL_OZ(gn_sop)
        CALL virg
        CALL izr
        JP mainloop
.addizrr
        CALL tabmn
        LD HL,addmes
        CALL_OZ(gn_sop)
        CALL izr
        CALL virg
        LD A,B
        CP $09
        JR Z,addizbc
        CP $19
        JR Z,addizde
        CP $29
        JR Z,addiziz
        LD HL,spmes
        JR addizend
.addizbc
        LD HL,bcmes
        JR addizend
.addizde
        LD HL,demes
        JR addizend
.addiziz
        CALL izr
        JP mainloop
.addizend
        CALL_OZ(gn_sop)
        JP mainloop
.inciz
        CALL tabmn
        LD A,B
        CP $23
        JR NZ,deciz
        LD HL,incmes
        JR incizend
.deciz
        LD HL,decmes
.incizend
        CALL_OZ(gn_sop)
        CALL izr
        JP mainloop
.incizd
        LD A,B
        CP $34
        JR NZ,decizd
        LD HL,incmes
        PUSH HL
        JR incizdsuite
.decizd
        LD HL,decmes
        PUSH HL
.incizdsuite
        CALL rb
        POP HL
        PUSH AF
        PUSH HL
        CALL hexbyte
        CALL tabmn
        POP HL
        CALL_OZ(gn_sop)
        POP AF
        CALL izd
        JP mainloop
.ldindiz
        LD A,B
        PUSH AF
        POP IY
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL rb
        PUSH AF
        CALL displspace
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        PUSH IY
        POP AF
        CP $22
        JR NZ,izavant
        CALL affnn
        CALL virg
        CALL izr
        JP mainloop
.izavant
        CALL izr
        CALL virg
        CALL affnn
        JP mainloop
.affnn
        LD A,'('
        CALL_OZ(os_out)
        POP IY
        POP AF
        CALL hexbyte
        POP AF
        CALL hexbyte
        PUSH IY
        LD A,')'
        CALL_OZ(os_out)
        RET
.ldsizd
        LD A,B
        PUSH AF
        POP IY
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        PUSH IY
        POP AF
        AND $38
        RRA
        RRA
        RRA
        CALL sreg
        CALL virg
        POP AF
        CALL izd
        JP mainloop
.ldizds
        LD A,B
        PUSH AF
        POP IY
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        POP AF
        CALL izd
        CALL virg
        PUSH IY
        POP AF
        AND $7
        CALL sreg
        JP mainloop
.logizd
        LD A,B
        PUSH AF
        POP IY
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        PUSH IY
        POP AF
        AND $38
        RRA
        RRA
        RRA
        LD HL,part3mn
        CALL tab0
        POP AF
        CALL izd
        JP mainloop
.partcbiz
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL displspace
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        POP AF
        PUSH AF
        AND 192
        CP 0
        JP NZ,brsiz  
        POP AF
        AND 56
        RRA
        RRA
        RRA
        LD HL,rotalst
        CALL tab0
        POP AF
        CALL izd
        JP mainloop
.brsiz
        POP AF
        PUSH AF
        AND 192
        RLCA
        RLCA
        LD HL,partcblst
        CALL tab0
        POP AF
        AND 56
        RRA
        RRA
        RRA
        LD DE,hexnumb
        LD H,0
        LD L,A
        ADC HL,DE
        LD A,(HL)
        CALL_OZ(os_out)
        CALL virg
        POP AF
        CALL izd 
        JP mainloop
.callmn
        LD HL,callmes
        JP calljp
.jpmn
        LD HL,jpmes
        JP calljp
.calljp
        PUSH HL
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL displspace
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        POP BC
        POP DE
        POP HL
        PUSH DE
        PUSH BC
        CALL_OZ(gn_sop)
.affadr
        POP AF
        CALL hexbyte
        POP AF
        CALL hexbyte
        JP mainloop
.call_cc
        LD HL,callmes
        JP calljpcc
.jp_cc
        LD HL,jpmes
        JP calljpcc
.calljpcc
        PUSH HL
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        AND 7
        PUSH AF
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL displspace
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        POP IX
        POP DE
        POP BC
        POP HL
        PUSH BC
        PUSH DE
        PUSH IX
        CALL_OZ(gn_sop)
        POP BC
        POP DE
        POP AF
        PUSH DE
        PUSH BC
        LD HL,cclst
        CALL tab0
        CALL virg
        JR affadr
.outmn
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,out1mes
        CALL_OZ(gn_sop)
        POP AF
        CALL hexbyte
        LD HL,out2mes
        CALL_OZ(gn_sop)
        JP mainloop
.inmn
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,inmes
        CALL_OZ(gn_sop)
        POP AF
        CALL hexbyte
        LD A,')'
        CALL_OZ os_out
        JP mainloop
.rst
        LD A,B
        CP $DF
        JR Z,rst18
        CP $E7
        JR Z,rst20
        CALL tabmn
        LD HL,rstmes
        CALL_OZ(gn_sop)
        LD A,B
        AND 56
        CALL hexbyte
        JP mainloop
.rst18
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,fppmes
        CALL_OZ(gn_sop)
        LD HL,fp_mes
        CALL_OZ(gn_sop)
        POP AF
        CALL hexbyte
        JP mainloop
.rst20
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL displspace
        POP AF
        PUSH AF
        AND 240
        JP NZ,rst00os
        POP AF
        PUSH AF
        CP $06
        JP Z,rst06os
        CP $09
        JP Z,rst09gn
        CP $0C
        JP Z,rst0Cdc
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,rstmes
        CALL_OZ(gn_sop)
        LD A,$20
        CALL hexbyte
        LD HL,defwmes
        CALL_OZ(gn_sop)
        POP AF
        CALL hexbyte
        POP AF
        CALL hexbyte
        JP mainloop
.rst00os
        CALL tabmn
        LD HL,oz_mes
        CALL_OZ(gn_sop)
        LD HL,os_mes
        CALL_OZ(gn_sop)
        POP AF
        SUB $21
        LD D,0
        LD E,A
        LD HL,rst20_os00_table
        ADD HL,DE
        LD A,(HL)
        LD E,A
        INC HL
        LD A,(HL)
        LD D,A
        EX DE,HL
        CALL_OZ(gn_sop)
        JP mainloop
.rst06os
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,oz_mes
        CALL_OZ(gn_sop)
        LD HL,os_mes
        CALL_OZ(gn_sop)
        POP AF
        SUB $CA
        LD D,0
        LD E,A
        LD HL,rst20_os06_table
        ADD HL,DE
        LD A,(HL)
        LD E,A
        INC HL
        LD A,(HL)
        LD D,A
        EX DE,HL
        CALL_OZ(gn_sop)
        pop af
        JP mainloop
.rst09gn
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,oz_mes
        CALL_OZ(gn_sop)
        LD HL,gn_mes
        CALL_OZ(gn_sop)
        POP AF
        SUB $06
        LD D,0
        LD E,A
        LD HL,rst20_gn09_table
        ADD HL,DE
        LD A,(HL)
        LD E,A
        INC HL
        LD A,(HL)
        LD D,A
        EX DE,HL
        CALL_OZ(gn_sop)
        pop af
        JP mainloop
.rst0Cdc
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,oz_mes
        CALL_OZ(gn_sop)
        LD HL,dc_mes
        CALL_OZ(gn_sop)
        POP AF
        SUB $06
        LD D,0
        LD E,A
        LD HL,rst20_dc0C_table
        ADD HL,DE
        LD A,(HL)
        LD E,A
        INC HL
        LD A,(HL)
        LD D,A
        EX DE,HL
        CALL_OZ(gn_sop)
        pop af
        JP mainloop
.part4mn1
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        LD HL,part3mn
        CALL tab0
        POP AF
        CALL hexbyte
        JP mainloop
.part4mn2
        CALL tabmn
        LD A,B
        AND 24
        RRA
        RRA
        RRA
        LD HL,part4mn2lst
        CALL tab0
        JP mainloop
.part4mn3
        CALL tabmn
        LD A,B
        AND 48
        RRA
        RRA
        RRA
        RRA
        LD HL,part4mn3lst
        CALL tab0
        JP mainloop
.partcb
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        POP AF
        LD B,A
        AND 192
        RLA
        RLA
        RLA
        CP 0
        JR Z,rota
        LD HL,partcblst
        CALL tab0
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        LD DE,hexnumb
        LD H,0
        LD L,A
        ADC HL,DE
        LD A,(HL)
        CALL_OZ(os_out)
        CALL virg
.cbend
        LD A,B
        AND 7
        CALL sreg
        JP mainloop
.rota
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        LD HL,rotalst
        CALL tab0
        JR cbend
.parted
        CALL rb
        LD B,A
        CALL hexbyte
        CALL displspace
        LD A,B
        AND 199
        CP 64
        JP Z,ined
        CP 65
        JP Z,outed
        CP 66
        JP Z,sbcadced
        CP 67
        JP Z,ldnned
        LD A,B
        AND 231
        CP 71
        JP Z,ldired
        LD A,B
        RES 3,A
        CP $67
        JP Z,rxded
        LD A,B
        AND 246
        CP 68
        JP Z,part1ed
        LD A,B
        AND 231
        CP 70
        JP Z,imed
        LD A,B
        AND 244
        CP 160
        JP Z,part2ed
        LD A,B
        AND 244
        CP 176
        JP Z,part3ed
        JP mainloop
.ined
        CALL tabmn
        LD HL,in1mes
        CALL_OZ(gn_sop)
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        AND 7
        CALL sreg
        LD HL,in2mes
        CALL_OZ(gn_sop)
        JP mainloop
.outed
        CALL tabmn
        LD HL,outmes
        CALL_OZ(gn_sop)
        LD A,B
        AND 56
        RRA
        RRA
        RRA
        AND 7
        CALL sreg
        JP mainloop
.sbcadced
        CALL tabmn
        LD A,B
        BIT 3,A
        JR Z,sbc
        LD HL,adcmes
.sbcadc
        CALL_OZ(gn_sop)
        AND 48
        RRA
        RRA
        RRA
        RRA
        LD HL,rrrrlst
        CALL tab0
        JP mainloop
.sbc
        LD HL,sbcmes
        JR sbcadc
.ldnned
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL displspace
        CALL rb
        PUSH AF
        CALL hexbyte
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        LD A,B
        BIT 3,A
        JR Z,adrdabord
        CALL dreged
        CALL virg
        CALL adrind
        JP mainloop
.adrdabord
        CALL adrind
        CALL virg
        CALL dreged
        JP mainloop
.ldired
        CALL tabmn
        LD HL,ldmes
        CALL_OZ(gn_sop)
        CALL displspace
        LD A,B
        AND 24
        RRA
        RRA
        RRA
        LD HL,irlst
        CALL tab0
        JP mainloop
.rxded
        CALL tabmn
        LD A,B
        BIT 3,A
        JR Z,rrded
        LD HL,rldedmes
        JR rxdaff
.rrded
        LD HL,rrdedmes
.rxdaff
        CALL_OZ(gn_sop)
        JP mainloop
.part1ed
        CALL tabmn
        LD A,B
        AND 9
        BIT 3,A
        JP Z,part1ed1
        OR 2
.part1ed1
        AND 3
        LD HL,part1edlst
        CALL tab0
        JP mainloop
.imed
        LD A,B
        CP $4E
        JP Z,mainloop
        CALL tabmn
        LD HL,immes
        CALL_OZ(gn_sop)
        LD A,B
        AND 24
        RRA
        RRA
        RRA
        LD HL,imlst
        CALL tab0
        JP mainloop
.part2ed
        CALL tabmn
        LD A,B
        AND 3
        LD HL,part2edlst
        CALL tab0
        CALL ided
        JP mainloop
.part3ed
        CALL tabmn
        LD A,B
        AND 3
        LD HL,part3edlst
        CALL tab0
        CALL ided
        LD A,'R'
        CALL_OZ os_out
        JP mainloop
.ided
        LD A,B
        BIT 3,A
        JP Z,ided1
        LD A,'D'
        CALL_OZ os_out
        RET
.ided1
        LD A,'I'
        CALL_OZ os_out
        RET

.greydef DEFM 1,"6#8  ",$7E,$28,1,"2H8",1,"2G+",0
.win2def DEFM 1,"7#2",33,32,83,40,129,1,"2C2",1,"2+S",0
.win1def DEFM 1,"7#1",42,32,82,40,131
DEFM 1,"2I1",1,"4+TUR",1,"2JC",1,"3@  Z80DIS V3.4"
DEFM 1,"3@  ",1,"2A",82,1,"4-TUR",1,"2JN"
DEFM 1,"7#1",42,33,82,39,129,1,"2I1",1,"3+CS",0
.hexnumb DEFM "0123456789ABCDEF",0
.refmes DEFM "At : $",0
.intms5 DEFM 1,"T   PRESS ",1,"*+S TO SEND TO FILE AND "
DEFM 1,"+",1,228," TO ABORT",1,"T",0
.intms3 DEFM "   Bank      $",0
.intms4 DEFM "   Address   $",0
.intms1 DEFM 1,"T   USE ",1,242,1,243," AND PRESS ",1,225," WHEN READY",1,"T",0
.bnkloc DEFM 1,"3@",46,35,0
.adrloc DEFM 1,"3@",46,36,0
.tabseq DEFM 1,50,88,54,0
.part1alst DEFM "NOP",0,"EX AF,AF'",0,"DJNZ ",0
.jrmes   DEFM "JR " , 0
.haltmes DEFM "HALT" , 0
.ldmes   DEFM "LD " , 0
.sreglst DEFM "BCDEHL(A"
.hlpmes  DEFM "HL)" , 0
.part3mn DEFM "ADD A,",0,"ADC A,",0
DEFM "SUB A,",0,"SBC A,",0,"AND ",0
DEFM "XOR ",0,"OR ",0,"CP ",0
.cclst   DEFM "NZ",0,"Z",0,"NC",0
DEFM "C",0,"PO",0,"PE",0,"P",0,"M",0
.retmes  DEFM "RET ",0
.popmes  DEFM "POP ",0
.pushmes DEFM "PUSH ",0
.dreglst DEFM "BC",0,"DE",0,"HL",0,"AF",0
.callmes DEFM "CALL ",0
.jpmes   DEFM "JP ",0
.out1mes DEFM "OUT (",0
.out2mes DEFM "),A",0
.inmes   DEFM "IN A,(",0
.rstmes  DEFM "RST ",0
.defbmes DEFM "DEFB ",0
.defwmes DEFM "DEFW ",0
.part4mn2lst DEFM "EX (SP),HL",0,"EX DE,HL",0
DEFM "DI",0,"EI",0
.part4mn3lst DEFM "RET",0,"EXX",0,"JP (HL)",0,"LD SP,HL",0
.partcblst   DEFM " ",0,"BIT ",0,"RES ",0,"SET ",0
.rotalst
DEFM "RLC ",0,"RRC ",0,"RL ",0,"RR ",0
DEFM "SLA ",0,"SRA ",0,"Unknown ",0,"SRL ",0 
.in1mes DEFM "IN ",0
.in2mes DEFM ",(C)",0
.outmes DEFM "OUT (C),",0
.adcmes DEFM "ADC HL,",0
.sbcmes DEFM "SBC HL,",0
.rrrrlst DEFM "BC",0,"DE",0,"HL",0,"SP",0
.irlst   DEFM "I,A",0,"R,A",0,"A,I",0,"A,R",0
.rrdedmes DEFM "RRD",0
.rldedmes DEFM "RLD",0
.part1edlst DEFM "NEG",0,"RETN",0," ",0,"RETI",0
.immes DEFM "IM ",0
.imlst DEFM "0",0," ",0,"1",0,"2",0
.part2edlst DEFM "LD",0,"CP",0,"IN",0,"OUT",0
.part3edlst DEFM "LD",0,"CP",0,"IN",0,"OT",0
.addhlmes DEFM "ADD HL,",0
.incmes DEFM "INC ",0
.decmes DEFM "DEC ",0
.part1blst DEFM "RLCA",0,"RRCA",0
DEFM "RLA",0,"RRA",0,"DAA",0
DEFM "CPL",0,"SCF",0,"CCF",0
.bcimes DEFM "(BC)",0
.deimes DEFM "(DE)",0
.bcmes DEFM "BC",0
.demes DEFM "DE",0
.hlmes DEFM "HL",0
.spmes DEFM "SP",0
.ukmes DEFM "Unknown ",0
.exspmes DEFM "EX (SP),",0
.addmes DEFM "ADD ",0
.fppmes DEFM "FPP ",0
.oz_mes DEFM "CALL_OZ ",0
.os_mes DEFM "os_",0
.gn_mes DEFM "gn_",0
.dc_mes DEFM "dc_",0
.fp_mes DEFM "fp_",0
.rst20_os00_table
DEFW os0bye 
DEFB 0
DEFW os0prt 
DEFB 0
DEFW os0out 
DEFB 0
DEFW os0in  
DEFB 0
DEFW os0tin 
DEFB 0
DEFW os0xin 
DEFB 0
DEFW os0pur 
DEFB 0
DEFW os0ugb 
DEFB 0
DEFW os0gb  
DEFB 0
DEFW os0pb  
DEFB 0
DEFW os0gbt 
DEFB 0
DEFW os0pbt 
DEFB 0
DEFW os0mv  
DEFB 0
DEFW os0frm 
DEFB 0
DEFW os0fwm 
DEFB 0
DEFW os0mop 
DEFB 0
DEFW os0mcl 
DEFB 0
DEFW os0mal 
DEFB 0
DEFW os0mfr 
DEFB 0
DEFW os0mgb 
DEFB 0
DEFW os0mpb 
DEFB 0
DEFW os0bix 
DEFB 0
DEFW os0box 
DEFB 0
DEFW os0nq  
DEFB 0
DEFW os0sp  
DEFB 0
DEFW os0sr  
DEFB 0
DEFW os0esc 
DEFB 0
DEFW os0erc 
DEFB 0
DEFW os0erh 
DEFB 0
DEFW os0ust 
DEFB 0
DEFW os0fn  
DEFB 0
DEFW os0wait
DEFB 0
DEFW os0alm 
DEFB 0
DEFW os0cli 
DEFB 0
DEFW os0dor 
DEFB 0
DEFW os0fc  
DEFB 0
DEFW os0si  
DEFB 0
.os0bye  DEFM "bye",0
.os0prt  DEFM "prt",0
.os0out  DEFM "out",0
.os0in   DEFM "in",0
.os0tin  DEFM "tin",0
.os0xin  DEFM "xin",0
.os0pur  DEFM "pur",0
.os0ugb  DEFM "ugb",0
.os0gb   DEFM "gb",0
.os0pb   DEFM "pb",0
.os0gbt  DEFM "gbt",0
.os0pbt  DEFM "pbt",0
.os0mv   DEFM "mv",0
.os0frm  DEFM "frm",0
.os0fwm  DEFM "fwm",0
.os0mop  DEFM "mop",0
.os0mcl  DEFM "mcl",0
.os0mal  DEFM "mal",0
.os0mfr  DEFM "mfr",0
.os0mgb  DEFM "mgb",0
.os0mpb  DEFM "mpb",0
.os0bix  DEFM "bix",0
.os0box  DEFM "box",0
.os0nq   DEFM "nq",0
.os0sp   DEFM "sp",0
.os0sr   DEFM "sr",0
.os0esc  DEFM "esc",0
.os0erc  DEFM "erc",0
.os0erh  DEFM "erh",0
.os0ust  DEFM "ust",0
.os0fn   DEFM "fn",0
.os0wait DEFM "wait",0
.os0alm  DEFM "alm",0
.os0cli  DEFM "cli",0
.os0dor  DEFM "dor",0
.os0fc   DEFM "fc",0
.os0si   DEFM "si",0
.rst20_dc0C_table
;sub $06 (*2)
DEFW dcCini
DEFW dcCbye
DEFW dcCent
DEFW dcCnam
DEFW dcCin
DEFW dcCout
DEFW dcCprt
DEFW dcCicl
DEFW dcCnq
DEFW dcCsp
DEFW dcCalt
DEFW dcCrbd
DEFW dcCxin
DEFW dcCgen
DEFW dcCpol
DEFW dcCscn
.dcCini  DEFM "ini",0
.dcCbye  DEFM "bye",0
.dcCent  DEFM "ent",0
.dcCnam  DEFM "nam",0
.dcCin   DEFM "in",0
.dcCout  DEFM "out",0
.dcCprt  DEFM "prt",0
.dcCicl  DEFM "icl",0
.dcCnq   DEFM "nq",0
.dcCsp   DEFM "sp",0
.dcCalt  DEFM "alt",0
.dcCrbd  DEFM "rbd",0
.dcCxin  DEFM "xin",0
.dcCgen  DEFM "gen",0
.dcCpol  DEFM "pol",0
.dcCscn  DEFM "scn",0
.rst20_gn09_table
;sub $06 (*2)
DEFW gn9gdt
DEFW gn9pdt
DEFW gn9gtm
DEFW gn9ptm
DEFW gn9sdo
DEFW gn9gdn
DEFW gn9pdn
DEFW gn9die
DEFW gn9dei
DEFW gn9gmd
DEFW gn9gmt
DEFW gn9pmd
DEFW gn9pmt
DEFW gn9msc
DEFW gn9flo
DEFW gn9flc
DEFW gn9flw
DEFW gn9flr
DEFW gn9flf
DEFW gn9fpb
DEFW gn9nln
DEFW gn9cls
DEFW gn9skc
DEFW gn9skd
DEFW gn9skt
DEFW gn9sip
DEFW gn9sop
DEFW gn9soe
DEFW gn9rbe
DEFW gn9wbe
DEFW gn9cme
DEFW gn9xnx
DEFW gn9xin
DEFW gn9xdl
DEFW gn9err
DEFW gn9esp
DEFW gn9fcm
DEFW gn9fex
DEFW gn9opw
DEFW gn9wcl
DEFW gn9wfn
DEFW gn9prs
DEFW gn9pfs
DEFW gn9wsm
DEFW gn9esa
DEFW gn9opf
DEFW gn9cl
DEFW gn9del
DEFW gn9ren
DEFW gn9aab
DEFW gn9fab
DEFW gn9lab
DEFW gn9uab
DEFW gn9alp
DEFW gn9m16
DEFW gn9d16
DEFW gn9m24
DEFW gn9d24
.gn9gdt  DEFM "gdt",0
.gn9pdt  DEFM "pdt",0
.gn9gtm  DEFM "gtm",0
.gn9ptm  DEFM "ptm",0
.gn9sdo  DEFM "sdo",0
.gn9gdn  DEFM "gdn",0
.gn9pdn  DEFM "pdn",0
.gn9die  DEFM "die",0
.gn9dei  DEFM "dei",0
.gn9gmd  DEFM "gmd",0
.gn9gmt  DEFM "gmt",0
.gn9pmd  DEFM "pmd",0
.gn9pmt  DEFM "pmt",0
.gn9msc  DEFM "msc",0
.gn9flo  DEFM "flo",0
.gn9flc  DEFM "flc",0
.gn9flw  DEFM "flw",0
.gn9flr  DEFM "flr",0
.gn9flf  DEFM "flf",0
.gn9fpb  DEFM "fpb",0
.gn9nln  DEFM "nln",0
.gn9cls  DEFM "cls",0
.gn9skc  DEFM "skc",0
.gn9skd  DEFM "skd",0
.gn9skt  DEFM "skt",0
.gn9sip  DEFM "sip",0
.gn9sop  DEFM "sop",0
.gn9soe  DEFM "soe",0
.gn9rbe  DEFM "rbe",0
.gn9wbe  DEFM "wbe",0
.gn9cme  DEFM "cme",0
.gn9xnx  DEFM "xnx",0
.gn9xin  DEFM "xin",0
.gn9xdl  DEFM "xdl",0
.gn9err  DEFM "err",0
.gn9esp  DEFM "esp",0
.gn9fcm  DEFM "fcm",0
.gn9fex  DEFM "fex",0
.gn9opw  DEFM "opw",0
.gn9wcl  DEFM "wcl",0
.gn9wfn  DEFM "wfn",0
.gn9prs  DEFM "prs",0
.gn9pfs  DEFM "pfs",0
.gn9wsm  DEFM "wsm",0
.gn9esa  DEFM "esa",0
.gn9opf  DEFM "opf",0
.gn9cl   DEFM "cl",0
.gn9del  DEFM "del",0
.gn9ren  DEFM "ren",0
.gn9aab  DEFM "aab",0
.gn9fab  DEFM "fab",0
.gn9lab  DEFM "lab",0
.gn9uab  DEFM "uab",0
.gn9alp  DEFM "alp",0
.gn9m16  DEFM "m16",0
.gn9d16  DEFM "d16",0
.gn9m24  DEFM "m24",0
.gn9d24  DEFM "d24",0
.rst20_os06_table
;sub $CA (*2)
DEFW os6wtb
DEFW os6wrt
DEFW os6wsq
DEFW os6isq
DEFW os6axp
DEFW os6sci
DEFW os6dly
DEFW os6blp
DEFW os6bde
DEFW os6bhl
DEFW os6fth
DEFW os6vth
DEFW os6gth
DEFW os6ren
DEFW os6del
DEFW os6cl
DEFW os6op
DEFW os6off
DEFW os6use
DEFW os6epr
DEFW os6ht
DEFW os6map
DEFW os6exit
DEFW os6stk
DEFW os6ent
DEFW os6poll
DEFW os6dom
.os6wtb  DEFM "wtb",0
.os6wrt  DEFM "wrt",0
.os6wsq  DEFM "wsq",0
.os6isq  DEFM "isq",0
.os6axp  DEFM "axp",0
.os6sci  DEFM "sci",0
.os6dly  DEFM "dly",0
.os6blp  DEFM "blp",0
.os6bde  DEFM "bde",0
.os6bhl  DEFM "bhl",0
.os6fth  DEFM "fth",0
.os6vth  DEFM "vth",0
.os6gth  DEFM "gth",0
.os6ren  DEFM "ren",0
.os6del  DEFM "del",0
.os6cl   DEFM "cl",0
.os6op   DEFM "op",0
.os6off  DEFM "off",0
.os6use  DEFM "use",0
.os6epr  DEFM "epr",0
.os6ht   DEFM "ht",0
.os6map  DEFM "map",0
.os6exit DEFM "exit",0
.os6stk  DEFM "stk",0
.os6ent  DEFM "ent",0
.os6poll DEFM "poll",0
.os6dom  DEFM "dom",0
