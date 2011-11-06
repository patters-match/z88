; *************************************************************************************
; Installer/Bootstrap/Packages (c) Garry Lancaster 1998-2011
;
; Installer/Bootstrap/Packages is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2, or (at your option) any later version.
; Installer/Bootstrap/Packages is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with
; Installer/Bootstrap/Packages; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

; Installer Popdown
; Changes for v1.08 (18/9/99):
;   Added "Deregister packages" and "List packages" on new Packages menu
;   Automatically installs package handling if required
;   No longer exits on every error message
; Changes for v1.09 (20/1/00):
;   Added support for tracing, interrupt chaining & enhanced OZ
; Changes for v1.10 (24/1/00):
;   Added feature list to the menu
;   Now displaying process reference for traced process
; Changes for v1.11/v1.12 (26/1/00):
;   Just bugfixes this time!
; Changes for v1.13/v1.14 (5/2/00 & 13/2/00)
;   Minor alterations
; Changes for v1.15 (15/2/00)
;   Added "register all packages" and "SlowMo" options
; Changes for v2.00 (16/2/00)
;   Just a version change really
; Changes for v2.01 (23/2/00)
;   Uninstall can't produce huge ROM sizes anymore
;   Purge now zeroises front DOR
;   Uninstall/purge now don't happen if packages active in slot
; Changes for v2.02
;   When installing rst8 code, also ensures handler code uptodate
; 13/3/00 GWL
;   Added conditional assembly with BASINST to provide a basic version of
;   Installer in BASIC
; Changes for v2.03 (29/4/01)
;   Added Kill Package option for single package deregistration
;   Added fix to allow multiple diaries
;   Added code to regenerate keytables after application addition/removal

        module  installer

        xdef    workparams

        xref    slottype,getdor,bindbank,protbank,matadd
        xref    checkbank,setbank,loopparms,protsafe,regsubs

        defc    padlength=199
        defc    headerlength=40

        ; NOTE - These tables were moved elsewhere in OZ4.2.
        defc    keytab1=$0e34
        defc    keytab2=$0e66
        defc    keytab3=$0e98

IF BASINST

        ORG     12288

.startme
        jp      basentry

.pad
        defs    padlength
.filebuffer
        defs    headerlength
.extension
        defw    0
.workparams     
        defs    13
.explicitname
        defs    255
.bstk
        defw    0                               ; our BASIC stack pointer
.basseg1
        defb    0
.basseg2
        defb    0

        defc    s1_copy=$04d1
        defc    s1_port=$d1
        defc    s2_copy=$04d2
        defc    s2_port=$d2

ELSE

        xref    in_tokens
        xref    instpcode,pkg_structure

include "instapp.def"
include "packages.def"
include "pkg_int.def"

ENDIF

include "director.def"
include "dor.def"
include "fileio.def"
include "error.def"
include "stdio.def"
include "saverst.def"
include "integer.def"
include "syspar.def"

IF BASINST

; We enter with A%=function to perform:
;  0=install/uninstall (requires null-terminated filename at PAD)
;  1=reserve banks (requires B%=number required)
;  2=free banks
;  3=purge applications

.basentry
        ld      hl,0
        add     hl,sp
        ld      (bstk),hl                       ; save SP
        push    af
        ld      a,(s1_copy)
        ld      (basseg1),a                     ; and seg 1/2 bindings
        ld      a,(s2_copy)
        ld      (basseg2),a
        pop     af
        ld      iy,workparams
        and     a
        jp      z,openfile                      ; install/uninstall
        dec     a
        jp      z,reservebanks
        dec     a
        jp      z,freebanks
        dec     a
        jp      z,uninstall_all
        jp      donecom2


ELSE

        xdef    installer_dor

; ************************************************************************
; *                         Application DOR                              *
; ************************************************************************

.installer_dor
        defb    0,0,0                           ; links to parent, brother (app), son (package)
        defb    0,0,0
        defw    pkg_structure
        defb    appl_bank
        defb    $83                             ; DOR type - application
        defb    indorend-indorstart
.indorstart
        defb    '@'                             ; key to info section
        defb    ininfend-ininfstart
.ininfstart
        defw    0
        defb    'I'                             ; application key
        defb    0                               ; no bad app memory
        defw    0                               ; overhead
        defw    unsafe                          ; unsafe workspace
        defw    safe                            ; safe workspace
        defw    instentry                       ; entry point
        defb    0                               ; bank bindings
        defb    0
        defb    0
        defb    appl_bank
        defb    at_popd+at_good                 ; good popdown
        defb    0                               ; no caps lock
.ininfend
        defb    'H'                             ; key to help section
        defb    inhlpend-inhlpstart
.inhlpstart
        defw    in_topics
        defb    appl_bank
        defw    in_commands
        defb    appl_bank
        defw    in_help
        defb    appl_bank
        defw    in_tokens
        defb    appl_bank
.inhlpend
        defb    'N'                             ; key to name section
        defb    innamend-innamstart
.innamstart
        defm    "Installer",0
.innamend
        defb    $ff
.indorend

; Topic entries

.in_topics
        defb    0

.incom_topic
        defb    incom_top2-incom_topic
        defm    "COMMANDS",0
        defb    0
        defb    0
        defb    0
        defb    incom_top2-incom_topic

.incom_top2
        defb    incom_top3-incom_top2
        defm    "PACKAGES",0
        defb    0
        defb    0
        defb    0
        defb    incom_top3-incom_top2

.incom_top3
        defb    incom_topend-incom_top3
        defm    "SPECIAL",0
        defb    0
        defb    0
        defb    0
        defb    incom_topend-incom_top3

.incom_topend
        defb    0

; Command entries

.in_commands
        defb    0
        
.in_coms1
        defb    in_coms2-in_coms1
        defb    $83
        defm    "I",0
        defm    "I",$81,0
        defb    0
        defb    0
        defb    0
        defb    in_coms2-in_coms1

.in_coms2
        defb    in_coms3-in_coms2
        defb    $84
        defm    "U",0
        defm    "Uni",$81,0
        defb    0
        defb    0
        defb    0
        defb    in_coms3-in_coms2

.in_coms3
        defb    in_coms3a-in_coms3
        defb    $80
        defm    "SI",0
        defm    "Slot info",0
        defb    0
        defb    0
        defb    0
        defb    in_coms3a-in_coms3

.in_coms3a
        defb    in_coms3b-in_coms3a
        defb    $82
        defm    "FI",0
        defm    "Feature info",0
        defb    0
        defb    0
        defb    0
        defb    in_coms3b-in_coms3a

.in_coms3b
        defb    in_coms4-in_coms3b
        defb    $92
        defm    "SLOW",0
        defm    "SlowMo",0
        defb    0
        defb    0
        defb    0
        defb    in_coms4-in_coms3b

.in_coms4
        defb    in_coms5-in_coms4
        defb    $85
        defm    "R",0
        defm    "Reserve",$89,0
        defb    0
        defb    0
        defb    $01
        defb    in_coms5-in_coms4

.in_coms5
        defb    in_coms6-in_coms5
        defb    $87
        defm    "FREE",0
        defm    $80,"Free",$89,$80,0
        defb    0
        defb    0
        defb    $08
        defb    in_coms6-in_coms5

.in_coms6
        defb    in_coms7-in_coms6
        defb    $90
        defm    "PURGE",0
        defm    $80,"Purge",$83,$80,0
        defb    0
        defb    0
        defb    $09
        defb    in_coms7-in_coms6

.in_coms7
        defb    in_coms_t1end-in_coms7
        defb    $86
        defm    "Q",0
        defm    "Quit",0
        defb    0
        defb    0
        defb    0
        defb    in_coms_t1end-in_coms7

.in_coms_t1end
        defb    1

.in_coms8
        defb    in_coms9-in_coms8
        defb    $81
        defm    "PL",0
        defm    "List packages",0
        defb    0
        defb    0
        defb    0
        defb    in_coms9-in_coms8

.in_coms9
        defb    in_coms10-in_coms9
        defb    $88
        defm    "PD",0
        defm    "Deregister packages",0
        defb    0
        defb    0
        defb    0
        defb    in_coms10-in_coms9

.in_coms10
        defb    in_coms11-in_coms10
        defb    $91
        defm    "PR",0
        defm    "Register packages",0
        defb    0
        defb    0
        defb    0
        defb    in_coms11-in_coms10

.in_coms11
        defb    in_coms_t2end-in_coms11
        defb    $93
        defm    "PK",0
        defm    "Kill package",0
        defb    0
        defb    0
        defb    0
        defb    in_coms_t2end-in_coms11

.in_coms_t2end
        defb    1

.in_coms_10
        defb    in_coms_11-in_coms_10
        defb    $89
        defm    "TRALL",0
        defm    $80,"Trace all",$80,0
        defb    0
        defb    0
        defb    $08
        defb    in_coms_11-in_coms_10

.in_coms_11
        defb    in_coms_12-in_coms_11
        defb    $8a
        defm    "TRONE",0
        defm    $80,"Trace single",$80,0
        defb    0
        defb    0
        defb    $08
        defb    in_coms_12-in_coms_11

.in_coms_12
        defb    in_coms_13-in_coms_12
        defb    $8b
        defm    "TROFF",0
        defm    $80,"Trace off",$80,0
        defb    0
        defb    0
        defb    $08
        defb    in_coms_13-in_coms_12

.in_coms_13
        defb    in_coms_14-in_coms_13
        defb    $8c
        defm    "CHON",0
        defm    $80,"Interrupt chain on",$80,0
        defb    0
        defb    0
        defb    $09
        defb    in_coms_14-in_coms_13

.in_coms_14
        defb    in_coms_15-in_coms_14
        defb    $8d
        defm    "CHOFF",0
        defm    $80,"Interrupt chain off",$80,0
        defb    0
        defb    0
        defb    $08
        defb    in_coms_15-in_coms_14

.in_coms_15
        defb    in_coms_16-in_coms_15
        defb    $8e
        defm    "OZPL",0
        defm    $80,"OZ Plus",$80,0
        defb    0
        defb    0
        defb    $09
        defb    in_coms_16-in_coms_15

.in_coms_16
        defb    in_coms_end-in_coms_16
        defb    $8f
        defm    "OZSTD",0
        defm    $80,"Standard OZ",$80,0
        defb    0
        defb    0
        defb    $08
        defb    in_coms_end-in_coms_16

.in_coms_end
        defb    0


; Help entries

.in_help
        defm    "A",$86," for i",$81,"ing",$83,$87,"RAM,",$7f
        defm    "handling packages and enhancing OZ",$7f
        defm    "v2.03",$85,$7f
        defm    $7f
        defm    "Designed & Programmed ",$82,$7f
        defm    "Additional Design: Dominic Morris & Thierry Peycru",$7f
        defm    $84
        defb    0

ENDIF


; ************************************************************************
; *                        Start/exit routines                           *
; ************************************************************************


; Exit routines
; EXITERR2 if error code in A, EXITERR if error code in E
; CLOSEEXIT if error code in E and should close file first

.closeexit
        call_oz(gn_cl)                          ; close open file
.exiterr
        ld      a,e
.exiterr2
        ld      hl,msg_error
        call_oz(gn_sop)
        call_oz(gn_esp)
        call_oz(gn_soe)                         ; display error message
        ld      a,7
        call_oz(os_out)                         ; bell
        jp      donecom2                        ; back into main program


IF BASINST

; Don't need this gubbins

ELSE

; Main entry point

.instentry
        jp      inststart
        scf
        ret
.inststart
        call    instpcode                       ; install package handler
        ld      b,@00000000
        ld      c,@00000000
        call_pkg(pkg_feat)                      ; ensure correct code handlers installed
        call    regsubs                         ; register call substitutions
        ld      iy,workparams
        ld      a,$ff
        ld      (singlego),a
        xor     a
        ld      (menucommand),a
        ld      a,sc_ena
        call_oz(os_esc)                         ; enable ESCape detection
.showwind
        ld      hl,msg_window
        call_oz(gn_sop)
        ld      b,0
        ld      hl,pad
        ld      de,msg_mailname
        ld      c,padlength
        ld      a,sr_rpd
        call_oz(os_sr)                          ; check for mail
        jp      nc,gotafile                     ; if got one, go to deal with it
        xor     a
        ld      (singlego),a
        call    dispinfo
        ld      hl,msg_barwindow
        call_oz(gn_sop)
.getcom
        call    invertbar                       ; turn bar on
.getcom2
        call_oz(os_in)                          ; for now, just wait for a key
        jr      nc,whichcom                     ; move on if got a possible command
        cp      rc_susp
        jr      z,getcom2                       ; get again if just pre-emption suspicion
        cp      rc_draw
        jr      z,showwind                      ; or re-draw
.okexit
        xor     a                               ; just quit
        call_oz(os_bye)
.whichcom
        ld      iy,workparams
        call    invertbar                       ; turn bar off
        cp      in_up
        jr      z,barup
        cp      in_dwn
        jp      z,bardown
        cp      in_ent
        jr      nz,normcom
        ld      a,(menucommand)
        add     a,$80                           ; convert command line to command code
.normcom
        cp      $80                             ; slot info
        jr      z,showwind
        cp      $81                             ; list packages
        jp      z,lpacks
        cp      $82                             ; feature list
        jp      z,flist
        cp      $83                             ; install
        jr      z,doinst
        cp      $84                             ; uninstall
        jr      z,douninst
        cp      $85                             ; reserve
        jp      z,reservebanks
        cp      $86                             ; quit
        jr      z,okexit
        cp      $87                             ; free
        jp      z,freebanks
        cp      $88                             ; deregister packages
        jp      z,dpacks
        cp      $89                             ; trace all
        jp      z,trall
        cp      $8a                             ; trace one
        jp      z,trone
        cp      $8b                             ; trace off
        jp      z,troff
        cp      $8c                             ; ints on
        jp      z,m1on
        cp      $8d                             ; ints off
        jp      z,m1off
        cp      $8e                             ; oz plus
        jp      z,ozplus
        cp      $8f                             ; oz std
        jp      z,ozstd
        cp      $90                             ; purge
        jp      z,uninstall_all
        cp      $91                             ; register all packages
        jp      z,rpacks
        cp      $92
        jp      z,setslow                       ; slowmo
        cp      $93
        jp      z,kpack                         ; kill single package
        jp      getcom                          ; bad command, so loop back
.barup
        ld      a,(menucommand)
        and     a
        jr      z,tobottom
        dec     a
        ld      (menucommand),a
        jp      getcom
.tobottom
        ld      a,maxcommand
        ld      (menucommand),a
        jp      getcom
.bardown
        ld      a,(menucommand)
        inc     a
        cp      maxcommand+1
        jr      nc,totop
        ld      (menucommand),a
        jp      getcom
.totop
        xor     a
        ld      (menucommand),a
        jp      getcom
.doinst
        ld      hl,msg_toinstall
        ld      e,'p'
        jr      doinpname
.douninst
        ld      hl,msg_touninstall
        ld      e,'u'
.doinpname
        call    inpfname
        jr      openfile
.gotafile
        ld      b,0
        ld      hl,pad
        add     hl,bc
        ld      (hl),b                          ; null-terminate filename

ENDIF

.openfile       
        ld      hl,pad
        ld      b,0
        ld      de,explicitname
        ld      c,255
        ld      a,op_in
        call_oz(gn_opf)                         ; open it, get explicit filename
        jp      c,exiterr2                      ; exit if error
        ld      hl,0
        ld      de,filebuffer
        ld      bc,headerlength
        call_oz(os_mv)                          ; read file header
        ld      e,a                             ; error code to E
        jp      c,closeexit
        ld      e,rc_ftm                        ; "File type mismatch" if not .APP/.APU
        ld      hl,explicitname
        ld      bc,256
        xor     a
        cpir                                    ; find terminating null of explicit filename
        dec     hl
        ld      bc,256
        ld      a,'.'
        cpdr                                    ; find extension
        ld      a,c
        cp      251                             ; check for correct extension length
        jp      nz,closeexit
        inc     hl
        inc     hl                              ; HL points to start of 3-char extension
        ld      a,(hl)
        inc     hl
        or      $20
        cp      'a'
        jp      nz,closeexit                    ; first character not A/a
        ld      a,(hl)
        inc     hl
        or      $20
        cp      'p'
        jp      nz,closeexit                    ; 2nd character not P/p
        ld      (extension),hl                  ; save address of third character
        ld      a,(hl)
        or      $20
        ld      bc,(filebuffer)                 ; get file signature
        cp      'u'
        jp      z,tryapu                        ; try .APU file
        cp      'p'
        jp      nz,closeexit                    ; not .APP
        ld      hl,$5aa5
        and     a
        sbc     hl,bc
        jp      nz,closeexit                    ; not really a .APP file


; ************************************************************************
; *                      Installer section                               *
; ************************************************************************


        ld      hl,(extension)
        ld      (hl),'u'
        push    ix
        ld      b,0
        ld      hl,explicitname
        ld      c,padlength
        ld      de,pad
        ld      a,op_in
        call_oz(gn_opf)                         ; attempt to open .APU file
        jr      c,doinstall                     ; okay to install if couldn't open one
        call_oz(gn_cl)                          ; else close it again
        pop     ix
        ld      e,rc_exis                       ; "already exists" error
        jp      closeexit
.doinstall
        pop     ix                              ; restore file handle
        ld      (iy+3),3                        ; start with slot 3
.findspace
        ld      a,(filebuffer+7)                ; even bank flags
        ld      e,$ff                           ; allow reserved banks to be used
        call    getfree                         ; find free banks in slot
        ld      a,(filebuffer+2)
        dec     a                               ; A=banks required-1
        cp      (iy+4)
        jr      c,gotspace                      ; move on if found enough banks
        dec     (iy+3)
        jr      nz,findspace                    ; check more slots
        ld      e,rc_room
        jp      closeexit                       ; no room error if out of slots
.gotspace
        inc     a
        ld      (iy+4),a                        ; set number of banks we need
        ld      hl,msg_installing
        call    dispdotstuff
        call    loopparms                       ; B=banks, HL=add of first
        ld      c,0                             ; start with .AP0 file
.lfiles
        ld      a,(hl)
        inc     hl
        ld      e,a
        call    remvresvd                       ; remove from reserved list if necessary
        ld      a,e
        call    bindbank                        ; bind the next bank in
        ld      a,c
        push    bc
        push    hl
        call    loadfile                        ; load the next file in
        pop     hl
        pop     bc
        jp      c,closeexit                     ; exit if any error
        inc     c
        djnz    lfiles                          ; load the rest of the files
        ld      hl,(filebuffer+4)
        ld      a,(filebuffer+6)
        ld      b,a                             ; BHL=first DOR pointer from .APP file
        or      h
        or      l
        jr      z,usefront                      ; ignore it if null
        ld      a,(iy+5)
        call    bindbank                        ; bind in top bank of new card
        ld      ($7fc6),hl                      ; else place in ROM front DOR position
        ld      a,b
        ld      ($7fc8),a
.usefront
        bit     1,(iy+2)                        ; is ROM header there?
        jr      nz,headthere
        ld      a,$3f
        call    bindbank                        ; bind in top bank of slot
        call    addheader                       ; add a blank ROM header
.headthere
        call    loopparms                       ; B=#banks, HL=add of first
.protcard
        ld      a,(hl)
        inc     hl
        call    protbank                        ; protect a card bank
        djnz    protcard
        call    firstdor                        ; get BHL=add of first application DOR-3
.apploop
        call    getdor                          ; get CDE=next DOR start
        jr      c,endapps                       ; move on if CDE is null
        ld      a,c
        call    cnvbank                         ; convert bank
        ld      (hl),a                          ; and store in previous link
        ld      b,a
        ex      de,hl                           ; now BHL=current DOR
        call    bindbank                        ; bind the bank to segment 1
        ld      a,h
        and     @00111111
        or      @01000000                       ; convert address to segment 1
        ld      h,a
        push    hl                              ; save address of application DOR
        push    bc
        ld      bc,25
        add     hl,bc                           ; segment bindings
        ld      b,4
.cnvbndings
        ld      a,(hl)
        call    cnvn0bank                       ; convert a segment binding if non-zero
        ld      (hl),a
        inc     hl
        djnz    cnvbndings
        ld      bc,4
        add     hl,bc                           ; MTH pointers
        ld      b,4
.cnvmth
        call    cnvptr                          ; convert a pointer
        ld      (hl),a
        inc     hl
        djnz    cnvmth
        pop     bc
        pop     hl                              ; restore application DOR address
        ld      de,msg_adding
        call    appname
        jr      apploop                         ; back for more

; Now we come to link the new chain into the existing application chain

.endapps
        ld      a,$3f
        call    bindbank                        ; bind bank containing device header
        ld      a,($7ffc)                       ; current ROM size in device
        add     a,(iy+4)                        ; add in newly-installed card size
        ld      ($7ffc),a
        ld      hl,$7fc3                        ; address-3  containing first DOR pointer
        ld      b,$3f
.parsechain
        call    getdor                          ; get next DOR
        jr      c,endchain
        ex      de,hl
        ld      b,c
        jr      parsechain                      ; until CDE is null
.endchain
        push    hl
        push    bc
        call    firstdor                        ; get address of first DOR
        call    getdor                          ; get first DOR in new chain to CDE
        pop     af
        call    bindbank                        ; bind in the bank at end of old chain
        pop     hl
        ld      (hl),c                          ; append new chain
        dec     hl
        ld      (hl),d
        dec     hl
        ld      (hl),e

; Now apply any patches required, and close the .APP file

        ld      a,(filebuffer+3)
        and     a
        jr      z,nopatches
        ld      b,a
        ld      hl,msg_patching
        call_oz(gn_sop)
.patchloop
        call_oz(os_gb)
        call    cnvbank                         ; convert bank
        call    bindbank                        ; and bind to segment 1
        call_oz(os_gb)
        ld      l,a
        call_oz(os_gb)
        and     @00111111
        or      @01000000
        ld      h,a                             ; HL=offset for patch
        call_oz(os_gb)
        ld      c,a                             ; C=flags
        call_oz(os_gb)
        ld      d,a                             ; D=absolute value
        call_oz(os_gb)
        ld      e,a
        jp      c,nopatches                     ; finish if end of patches
        call    cnvbank
        ld      e,a                             ; E=bank value
        xor     a                               ; initialise value to patch
        rr      c
        jr      nc,noabs
        add     a,d                             ; add in absolute value
.noabs
        rr      c
        jr      nc,nobnk
        add     a,e                             ; add in bank value
.nobnk
        ld      (hl),a                          ; apply patch   
        djnz    patchloop                       ; back for more
.nopatches
        call_oz(gn_cl)                          ; close the .APP file

; Now all we need to do is create the .APU file

        ld      hl,msg_createapu
        call_oz(gn_sop)
        ld      hl,(extension)
        ld      (hl),'u'                        ; set extension
        ld      hl,$4bb4
        ld      (workparams+1),hl               ; store .APU identifier
        ld      hl,explicitname
        ld      b,0
        ld      de,pad
        ld      c,padlength
        ld      a,op_out
        call_oz(gn_opf)                         ; create the file
        jp      c,exiterr2
        ld      de,0
        ld      hl,workparams+1
        ld      bc,headerlength
        call_oz(os_mv)                          ; write the file contents
        push    af                              ; save error code
        call_oz(gn_cl)                          ; close the file
        pop     af                              ; restore error code
        jp      c,exiterr2                      ; exit with error

IF BASINST

.donecom
        ld      hl,msg_done
        call_oz(gn_sop)
.donecom2
        call    regenkeys
        ld      a,(basseg1)
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind seg 1/2
        ld      a,(basseg2)
        ld      (s2_copy),a
        out     (s2_port),a
        ld      sp,(bstk)                       ; restore stack
        ret                                     ; back to BASIC

ELSE

.donecom
        ld      hl,msg_done
        call_oz(gn_sop)
.donecom2
        call    regenkeys
        ld      a,(singlego)
        and     a
        jp      z,getcom                        ; if not on single command, go back
        call_oz(os_in)                          ; wait for a key
        xor     a
        call_oz(os_bye)

ENDIF


; ************************************************************************
; *                      Uninstaller section                             *
; ************************************************************************


.tryapu
        ld      hl,$4bb4
        and     a
        sbc     hl,bc
        jp      nz,closeexit                    ; not really a .APU file
        call_oz(gn_cl)                          ; close the .APU file
        ld      hl,filebuffer+2
        ld      de,workparams+3
        ld      bc,9
        ldir                                    ; copy APU contents into work parameters
        call    activeslot                      ; is slot active?
        jr      z,slotquiet                     ; move on if not
        ld      hl,msg_slotbusya

IF BASINST

ELSE
        jr      c,busyapp
        ld      hl,msg_slotbusyp
.busyapp
ENDIF

        ld      de,msg_cantuninst
        call    dispstuff
        ld      a,rc_fail                       ; cannot satisfy request
        jp      exiterr2
.slotquiet
        ld      hl,explicitname
        ld      b,0
        call_oz(gn_del)                         ; and delete the .APU file
        ld      hl,msg_verifyapu
        call_oz(gn_sop)
        call    slottype
        ld      a,(iy+2)
        cp      3
        ld      e,rc_fail
        jp      nz,exiterr                      ; cannot satisfy request if not ROM/RAM
        call    loopparms                       ; B=#banks, HL=start of banklist
.dealcard
        ld      a,(hl)
        inc     hl
        call    deallocate                      ; deallocate next bank
        jp      c,exiterr
        djnz    dealcard
        ld      hl,msg_uninstalling
        call_oz(gn_sop)
        ld      a,$3f   
        call    bindbank                        ; bind top bank in
.rempart
        ld      hl,$7fc3
        ld      b,$3f                           ; BHL=address-3 of pointer to first DOR
.remloop1
        call    getdor                          ; get next DOR to CDE
        jr      c,premend                       ; move on if null pointer
        jr      z,thiscard                      ; move on if found pointer in this card
        ex      de,hl
        ld      b,c                             ; BHL=next DOR address
        jr      remloop1                        ; loop back until found 
.premend
        ld      a,rc_fail
        jp      exiterr2                        ; exit

; ATP, BHL=place to put link bank, and CDE=current DOR

.thiscard
        push    bc
        push    hl                              ; save pointer place
.prscard
        ex      de,hl
        ld      b,c                             ; BHL=next DOR address
        ld      de,msg_reming
        call    appname
        call    getdor
        jr      c,endcard                       ; if null pointer, move on
        jr      z,prscard                       ; keep going til found DOR in another card
.endcard
        pop     hl
        pop     af                              ; AHL=place to put it
        call    bindbank
        ld      (hl),c                          ; place pointer
        dec     hl
        ld      (hl),d
        dec     hl
        ld      (hl),e
        ld      a,$3f   
        call    bindbank                        ; bind top bank back in
        ld      a,($7ffc)                       ; get current size
        sub     (iy+4)                          ; reduce by amount being uninstalled
        ld      ($7ffc),a
        jp      p,donecom
        xor     a
        ld      ($7ffc),a                       ; make sure doesn't go below zero
        jp      donecom                         ; (shouldn't be able to, but just in case...)



; ************************************************************************
; *                Uninstall all RAM applications                        *
; ************************************************************************

.uninstall_all
        ld      hl,msg_window
        call_oz(gn_sop)
        ld      hl,msg_scanslots
        call_oz(gn_sop)
        ld      (iy+3),3                        ; start with slot 3
.uninstloop
        call    slottype
        ld      a,(iy+2)
        cp      3
        jr      nz,nopurge
        call    activeslot                      ; check for slot activity
        jr      z,purgeslot                     ; move on if none
        ld      hl,msg_slotbusya

IF BASINST
ELSE
        jr      c,busyapp2
        ld      hl,msg_slotbusyp
.busyapp2
ENDIF

        ld      de,msg_cantpurge
        call    dispstuff
        jr      nopurge
.purgeslot
        ld      hl,msg_uninslot
        call    dispdotstuff
        ld      hl,$7fc3                        ; address-3 of first DOR
        ld      b,$3f
.unloop2
        call    getdor                          ; get next DOR in CDE
        jr      c,endpurge                      ; move on if at end of chain
        ld      a,c
        call    deallocate                      ; protect next bank
        ld      a,c
        call    bindbank                        ; bind bank into segment 1
        ex      de,hl
        ld      b,c                             ; BHL=current DOR
        ld      a,h
        and     @00111111
        or      @01000000
        ld      h,a                             ; convert address to segment 1
        push    bc
        push    hl                              ; save it
        ld      bc,25
        add     hl,bc                           ; start of segment bindings
        ld      b,4
.dealsegs
        ld      a,(hl)
        inc     hl
        and     a
        call    nz,deallocate                   ; deallocate bank if non-zero
        djnz    dealsegs
        ld      bc,4
        add     hl,bc                           ; start of MTH pointers
        ld      b,4
.dealmth
        ld      a,(hl)
        inc     hl
        or      (hl)
        inc     hl
        or      (hl)
        ld      a,(hl)
        inc     hl
        call    nz,deallocate                   ; deallocate MTH bank if pointer not null
        djnz    dealmth
        pop     hl                              ; restore DOR address in BHL
        pop     bc
        ld      de,msg_reming
        call    appname
        jr      unloop2
.endpurge
        ld      a,$3f
        call    bindbank                        ; bind top RAM/ROM bank to segment 1
        xor     a
        ld      ($7ffc),a                       ; set card size to zero
        ld      h,a
        ld      l,a
        ld      ($7fc6),hl
        ld      ($7fc8),a                       ; and first DOR pointer
.nopurge
        dec     (iy+3)
        jp      nz,uninstloop
        jp      donecom


; ************************************************************************
; *                  Free all reserved RAM banks                         *
; ************************************************************************

.freebanks
        ld      hl,msg_window
        call_oz(gn_sop)
        ld      hl,msg_scanslots
        call_oz(gn_sop)
        ld      (iy+3),3                        ; start with slot 3
.freeloop
        call    slottype
        ld      a,(iy+2)
        cp      3
        jr      nz,nofree
        ld      hl,msg_freeslot
        call    dispdotstuff
        ld      a,$3f
        call    bindbank
        xor     a
        ld      ($7ff7),a                       ; zeroise reserved banks
.freenext
        ld      a,($7ff6)
        and     a
        jr      z,nofree
        push    af
        call    deallocate                      ; deallocate the bank
        pop     af
        call    bindbank
        jr      freenext
.nofree
        dec     (iy+3)
        jr      nz,freeloop
        jp      donecom


; ************************************************************************
; *                       Reserve RAM banks                              *
; ************************************************************************

.reservebanks
IF BASINST
        ld      a,b                             ; B%=number of banks
        dec     a                               ; we want 0...7
ELSE
        ld      hl,msg_window
        call_oz(gn_sop)
        ld      hl,msg_reservewhat
        call_oz(gn_sop)
.rswhat
        call_oz(os_in)
        jr      nc,rsokay
        cp      rc_quit
        jp      z,okexit
        cp      rc_esc
        jp      z,okexit
        cp      rc_draw
        jr      z,reservebanks
        jr      rswhat
.rsokay
        sub     '1'
        jr      c,rswhat
        cp      8
        jr      nc,rswhat                       ; must be 0..7
ENDIF
        ld      (iy+3),3                        ; start with slot 3
.srchresv
        push    af                              ; save number required
        xor     a                               ; don't require even banks
        ld      e,a                             ; don't use already reserved ones!
        call    getfree
        pop     af
        cp      (iy+4)
        jr      c,canrsv
        dec     (iy+3)
        jr      nz,srchresv
        ld      a,rc_room                       ; error if out of slots
        jp      exiterr2
.canrsv
        inc     a
        ld      (iy+4),a                        ; set number of banks required
        ld      hl,msg_reserving
        call    dispdotstuff
        ld      a,$3f
        call    bindbank                        ; bind in top bank of slot
        bit     1,(iy+2)                        ; check for ROM header
        jr      nz,rsvheadthere
        call    addheader                       ; add a blank ROM header
.rsvheadthere
        ld      a,($7ff7)
        add     a,(iy+4)
        ld      ($7ff7),a                       ; update number of reserved banks
.scnreslst
        ld      a,($7ff6)
        and     a
        jr      z,appendres                     ; move on if reached end of list
        call    bindbank                        ; else bind next bank in
        jr      scnreslst
.appendres
        call    loopparms
.appreslp
        ld      a,(hl)
        ld      ($7ff6),a                       ; store next bank
        call    protbank                        ; protect it
        ld      a,(hl)
        inc     hl
        call    bindbank                        ; bind it in
        djnz    appreslp
        xor     a
        ld      ($7ff6),a                       ; store list endmarker
        jp      donecom


IF BASINST

; We don't want any package handling, or special features...

ELSE


; ************************************************************************
; *                        Package Handling                              *
; ************************************************************************


; Register all packages

.rpacks
        ld      hl,msg_window
        call_oz(gn_sop)
        ld      hl,msg_regging
        call_oz(gn_sop)
        ld      a,pkg_min
.rploop
        push    af
        call_pkg(pkg_reg)                       ; try to register one
        pop     af
        add     a,3
        cp      pkg_max+1
        jr      c,rploop
        jp      lpcks2                          ; go on to show all


; List packages

.lpacks
        ld      hl,msg_window
        call_oz(gn_sop)
.lpcks2
        ld      hl,msg_packages
        call_oz(gn_sop)
        xor     a
        push    af
.pkgloop        
        pop     af
        call_pkg(pkg_nxt)                       ; get next installed package id
        jp      c,donecom                       ; all done
        push    af
        call_pkg(pkg_get)                       ; get package info
        jr      c,nopkginf                      ; package not accessible
        ld      (pad+padlength-1),a             ; save package-defined info
        pop     af
        push    af
        call    disp_pkg_id                     ; display package ID
        call_oz(gn_soe)                         ; and name
        ld      hl,msg_pkgver
        call_oz(gn_sop)
        ld      a,d
        add     a,'0'
        call_oz(os_out)
        ld      a,'.'
        call_oz(os_out)
        ld      a,e
        call    hexpair                         ; display version number (3-nibble format)
        ld      hl,msg_inslot
        call_oz(gn_sop)
        ld      a,c
        add     a,'0'
        call_oz(os_out)                         ; slot package is in
        ld      hl,msg_pkgusing
        call_oz(gn_sop)
        ld      (pad),iy
        ld      (pad+2),ix
        xor     a
        ld      (pad+3),a
        call    dispdecimal                     ; display # bytes
        ld      hl,msg_numbytes
        call_oz(gn_sop)
        defb    $0dd
        ld      c,h                             ; LD C,IXh
        ld      b,0
        call    dispBCdec                       ; display # handles
        ld      hl,msg_numhands
        call_oz(gn_sop)
        ld      a,(pad+padlength-1)
        ld      c,a
        ld      b,0
        call    dispBCdec                       ; display package-defined resource usage
        ld      hl,msg_numuser
        call_oz(gn_sop)
        jr      pkgloop
.nopkginf       
        pop     af
        push    af
        call    inaccmsg                        ; display inaccessible message
        jr      pkgloop


; Kill specific package

.kpack  ld      hl,msg_window
        call_oz(gn_sop)
        ld      hl,msg_kpack
        call_oz(gn_sop)
        call    gethex
        add     a,a
        add     a,a
        add     a,a
        add     a,a
        ld      l,a
        ld      a,c
        call_oz(os_out)
        call    gethex
        or      l                               ; A=package ID to deregister
        push    af
        ld      a,c
        call_oz(os_out)
        pop     bc                              ; B=package number
        ld      hl,msg_notthere
        ld      a,pkg_min
.chkid
        cp      b
        jr      z,okid
        add     a,3
        cp      pkg_max+1
        jr      c,chkid
        jr      knoend
.okid
        push    iy
        ld      iyl,b
        ld      iyh,02                          ; AYT?
        rst     $10                             ; see if it's installed
        pop     iy
        jr      c,knoend
        ld      a,b
        call_pkg(pkg_drg)                       ; deregister package if possible
        ld      hl,msg_nodereg
        jr      c,knoend                        ; package in use
        ld      hl,msg_deregd
.knoend
        call_oz(gn_sop)
        jp      donecom

; Deregister packages

.dpacks
        ld      hl,msg_window
        call_oz(gn_sop)
        ld      hl,msg_dpacks
        call_oz(gn_sop)
        xor     a
.deregloop
        call_pkg(pkg_nxt)                       ; get next installed package id
        jp      c,donecom                       ; all done
        push    af
        call_pkg(pkg_get)                       ; get package info
        jr      c,notacc                        ; package not accessible
        pop     af
        call    disp_pkg_id                     ; display package ID
        call_oz(gn_soe)                         ; and name
        push    af
        call_pkg(pkg_drg)                       ; deregister package if possible
        jr      c,nodereg                       ; package in use
        pop     af
        ld      hl,msg_deregd
        call_oz(gn_sop)                         ; successfully deregistered message
        jr      deregloop
.nodereg
        pop     af
        ld      hl,msg_nodereg
        call_oz(gn_sop)                         ; display in use message
        jr      deregloop
.notacc
        pop     af
        call    inaccmsg                        ; display inaccessible message
        jr      deregloop



; Subroutine to display package inaccessible
; On entry, A=package ID and C=slot number (preserved)

.inaccmsg       
        call    disp_pkg_id
        ld      hl,msg_inaccpkg
        call_oz(gn_sop)
        push    af
        ld      a,c
        add     a,'0'
        call_oz(os_out)
        pop     af
        ld      hl,msg_inaccend
        call_oz(gn_sop)
        ret


; Subroutine to display package ID
; On entry, A=package ID (all registers preserved)

.disp_pkg_id
        push    af
        ld      a,'$'
        call_oz(os_out)
        pop     af
        push    af
        call    hexpair
        ld      a,' '
        call_oz(os_out)
        pop     af
        ret


; Subroutine to display 32-bit number or BC in decimal
; All registers corrupted!

.dispBCdec
        ld      hl,2
        jr      dispdec2
.dispdecimal
        ld      hl,pad
.dispdec2
        ld      de,pad+4
        xor     a
        call_oz(gn_pdn)
        xor     a
        ld      (de),a
        ld      hl,pad+4
        call_oz(gn_sop)
        ret


; ************************************************************************
; *                        Feature Handling                              *
; ************************************************************************

; The feature setting routines

.trall 
        ld      b,@00001100
        ld      c,@00000100
        jr      setfeat
.trone
        ld      a,(s1_copy)
        push    af
        ld      a,(process_ptr+2)
        ld      (s1_copy),a
        out     (s1_port),a
        ld      hl,(process_ptr)                ; AHL=current process pointer
        res     7,h
        set     6,h                             ; segment 1 addressing
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)                          ; ADE=previous process pointer
        ld      (s1_copy),a
        out     (s1_port),a
        ex      de,hl
        res     7,h
        set     6,h                             ; segment 1 addressing
        ld      de,5
        add     hl,de
        ld      e,(hl)                          ; E=process ID
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind
        ld      b,@00001100
        ld      c,@00001100
        jr      setfeat
.troff
        ld      b,@00001100
        ld      c,@00000000
        jr      setfeat
.m1on
        ld      b,@00000001
        ld      c,@00000001
        jr      setfeat
.m1off
        ld      b,@00000001
        ld      c,@00000000
        jr      setfeat
.ozplus
        ld      b,@00000010
        ld      c,@00000010
        jr      setfeat
.ozstd
        ld      b,@00000010
        ld      c,@00000000
        jr      setfeat
.flist
        ld      b,0
        ld      c,0
.setfeat
        call_pkg(pkg_feat)                      ; set & get features
        ld      hl,msg_window
        call_oz(gn_sop)
        ld      hl,msg_features
        call_oz(gn_sop)
        ld      hl,msg_fints
        call_oz(gn_sop)
        ld      hl,msg_fon
        rr      c
        jr      c,showints
        ld      hl,msg_foff
.showints
        call_oz(gn_sop)
        ld      hl,msg_fplus
        call_oz(gn_sop)
        ld      hl,msg_fon
        rr      c
        jr      c,showplus
        ld      hl,msg_foff
.showplus
        call_oz(gn_sop)
        ld      hl,msg_ftrace
        call_oz(gn_sop)
        ld      hl,msg_foff
        rr      c
        jr      nc,showtrace
        ld      hl,msg_fglobal
        rr      c
        jr      nc,showtrace
        ld      hl,msg_fsingle
        call_oz(gn_sop)
        ld      a,(s1_copy)
        push    af                              ; save segment 1 binding
        ld      a,(process_ptr+2)
        ld      hl,(process_ptr)                ; AHL=pointer to current process
.findproname
        ld      (s1_copy),a
        out     (s1_port),a
        res     7,h
        set     6,h                             ; adjust to segment 1 addressing
        push    hl
        ex      (sp),ix
        ld      a,(ix+5)
        cp      e
        jr      z,gotprocess                    ; found our traced process
        ld      l,(ix+0)
        ld      h,(ix+1)
        ld      a,(ix+2)                        ; AHL=next pointer
        pop     ix
        ld      d,a
        or      h
        or      l                               ; test for end of list
        ld      a,d
        jr      nz,findproname                  ; back if still more
        jr      doneproname
.gotprocess
        ex      (sp),ix
        pop     hl
        ld      de,$37
        add     hl,de
        call_oz(gn_sop)                         ; show the process name
.doneproname
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind segment 1
        ld      hl,msg_fendprname
.showtrace
        call_oz(gn_sop)
        ld      hl,msg_fpkgi
        call_oz(gn_sop)
        ld      a,b
        add     a,'0'
        call_oz(os_out)
        call_oz(gn_nln)
        ld      hl,msg_fproi
        call_oz(gn_sop)
        ld      a,d
        add     a,'0'
        call_oz(os_out)
        call_oz(gn_nln)
        jp      donecom


; The "SlowMo" feature

.setslow
        ld      hl,msg_window
        call_oz(gn_sop)
        ld      hl,msg_slowmo
        call_oz(gn_sop)
        ld      hl,msg_toslowmo
        call    inpany                          ; get user input
        ld      hl,pad
        ld      de,2
        ld      b,4                             ; max 4 digits
        call_oz(gn_gdn)                         ; convert to numeric
        jr      c,noslow                        ; if not numeric, disable
        ld      a,b
        or      c
        jr      z,noslow                        ; or if zero
        ld      hl,100
        and     a
        sbc     hl,bc
        jr      c,noslow                        ; or if >100%
        ld      h,b
        ld      l,c
        add     hl,hl
        add     hl,hl                           ; HL=4*factor
        add     hl,bc
        add     hl,bc                           ; HL=6*factor
        ld      (slowmo),hl                     ; set it
        ld      a,int_pkg
        ld      c,int_tick
        ld      b,1                             ; every TICK
        ld      hl,pkg_slow
        call_pkg(pkg_intr)                      ; register interrupt
        ld      hl,msg_slowok
        jr      nc,showslow
        ld      hl,msg_cantslow
        jr      showslow
.noslow
        ld      a,int_pkg
        ld      hl,pkg_slow
        call_pkg(pkg_intd)                      ; deregister interrupt
        ld      hl,msg_noslow
.showslow
        call_oz(gn_sop)                         ; display results
        jp      donecom


ENDIF


; ************************************************************************
; *                        The Subroutines                               *
; ************************************************************************

; Regenerate application key tables
;       IN:     -
;       OUT:    -
; Registers changed:
;       ......../..IY same
;       AFBCDEHL/IX.. different

.regenkeys
        ld      hl,keytab1
        ld      b,3*25
        xor     a
.clrkey
        ld      (hl),a                          ; clear the table
        inc     hl
        ld      (hl),a
        inc     hl
        djnz    clrkey
        ld      ix,0                            ; start with first app
.regenloop
        call_oz(os_poll)
        ret     c                               ; exit if no more apps
        ld      bc,nq_ain
        call_oz(os_nq)                          ; get C=key
        ld      a,c
        cp      'A'
        jr      c,regenloop
        cp      'Z'
        jr      nc,regenloop
        sub     'A'
        add     a,a
        ld      c,a
        ld      b,0                             ; BC=offset into keytables
        ld      hl,keytab1
        add     hl,bc
        ld      a,(hl)
        inc     hl
        or      (hl)
        jr      z,storekey                      ; if free, we can store it
        ld      hl,keytab2
        add     hl,bc
        ld      a,(hl)
        inc     hl
        or      (hl)
        jr      z,storekey                      ; if free, we can store it
        ld      hl,keytab3
        add     hl,bc
        ld      a,(hl)
        inc     hl
        or      (hl)
        jr      nz,regenloop                    ; loop back if not free
.storekey
        push    ix
        pop     bc
        ld      (hl),b
        dec     hl
        ld      (hl),c
        jr      regenloop


; Check for active applications or packages in slot
;       IN:     (IY+3)=slot number
;       OUT:    Fz=1 if no applications/packages active
;               Fz=0 if applications/packages active
;               Fc=1 if activity source=application
;               Fc=0 if activity source=package
;
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.activeslot
        ld      a,(iy+3)
        call_oz(dc_pol)
        scf                                     ; Fc=1; activity source=application

IF BASINST
        ret                                     ; we don't check for packages
ELSE
        ret     nz                              ; exit if any applications active
        push    bc
        push    de
        push    hl
        push    iy
        ld      iyh,$00                         ; xxx_inf call
        ld      iyl,pkg_min                     ; starting package
.actlp
        rst     $10                             ; run the next xxx_inf call
        jr      c,noact                         ; on if failed (no activity)
        ld      a,b
        rlca
        rlca
        and     3                               ; A=slot number of package
        ex      (sp),iy
        cp      (iy+3)
        ex      (sp),iy
        jr      z,activepkg                     ; on if found active package
.noact
        ld      a,iyl
        add     a,3
        ld      iyl,a
        cp      pkg_max+1
        jr      c,actlp                         ; back to check rest of packages
        xor     a                               ; Fz=1, nothing active in slot
        jr      endactck
.activepkg
        ld      a,1
        and     a                               ; Fz=0, Fc=0; package activity
.endactck
        pop     iy
        pop     hl
        pop     de
        pop     bc
        ret
ENDIF


; Remove a bank from the reserved list
;       IN:     E=bank
;       OUT:    -
;
; Registers changed:
;       ..BC.EHL/IXIY same
;       AF..D.../.... different

.remvresvd
        ld      a,$3f
.remrslp
        ld      d,a                             ; D=bank containing pointer
        call    bindbank
        ld      a,($7ff6)
        and     a
        ret     z                               ; exit if reached end of reserved list
        cp      e
        jr      nz,remrslp                      ; loop back if no match
        push    af
        call    deallocate                      ; deallocate it, in case of install probs
        pop     af
        call    bindbank                        ; bind the reserved bank
        ld      a,($7ff6)                       ; get next link
        push    af
        ld      a,d
        call    bindbank
        pop     af
        ld      ($7ff6),a                       ; store link into previous
        ld      a,$3f
        call    bindbank
        ld      a,($7ff7)
        dec     a                               ; decrement reserved bank count
        ld      ($7ff7),a
        ret


; Display an application name after a message
;       IN:     BHL=DOR address
;               DE=message
;       OUT:    -
;
; Registers changed:
;       ..BC..HL/IXIY same
;       AF..DE../.... different

.appname
        ex      de,hl
        call_oz(gn_sop)                         ; display message
        ld      a,b
        call    bindbank                        ; bind in the DOR to segment 1
        ld      hl,47
        add     hl,de
        ld      a,h
        and     @00111111
        or      @01000000
        ld      h,a
        call_oz(gn_sop)                         ; and name
        call_oz(gn_nln)
        ex      de,hl
        ret


IF BASINST

; No need for these bits

ELSE

; Invert the menu bar
;       IN:     -
;       OUT:    -
;
; Registers changed:
;       AFBCDEHL/IXIY same
;       ......../.... different

.invertbar
        push    af
        push    hl
        ld      hl,msg_barstart
        call_oz(gn_sop)
        ld      a,(menucommand)
        add     a,32
        call_oz(os_out)
        ld      hl,msg_barend
        call_oz(gn_sop)
        pop     hl
        pop     af
        ret

; Get hex digit from user
;       OUT:    A=value (0..15)
;               C=char (ASCII)
; Registers changed:
;       ..B.DEHL/IXIY same
;       AF.C..../.... different

.gethex
        call_oz(os_in)
        jr      nc,testdigit
        cp      rc_quit
        jp      z,okexit
        cp      rc_esc
        jp      z,okexit
        jr      gethex                          ; just re-get for other errors
.testdigit
        ld      c,a
        sub     '0'                             ; try digits first
        jr      c,gethex
        cp      10
        ret     c                               ; exit with 0..9
        sub     'A'-'0'-10                      ; now try uppercase
        jr      c,gethex
        cp      16
        ret     c                               ; exit with A..F
        sub     'a'-'A'                         ; now try lowercase
        jr      c,gethex
        cp      16
        ret     c
        jr      gethex

; Get filename from user
; Also used (via inpany) by SlowMo feature
;       IN:     HL=message to display
;               E=filetype ('p' or 'u')
;       OUT:    PAD contains filename
;
; Registers changed:
;       ......../IXIY same
;       AFBCDEHL/.... different

.inpfname
        push    hl
        ld      hl,msg_window
        call_oz(gn_sop)
        pop     hl
.inpany
        call_oz(gn_sop)
        push    de                              ; save filetype
        ld      de,pad
        ld      c,0
        ld      a,@00100000                     ; don't allow special chars, single-line
.inplop
        ld      hl,msg_atinput
        call_oz(gn_sop)
        ld      l,36
        ld      b,padlength-4                   ; allow for extension
        call_oz(gn_sip)
        jr      nc,gotokay
        cp      rc_quit
        jp      z,okexit                        
        cp      rc_esc
        jp      z,okexit
        ld      a,@00100001
        jr      inplop                          ; if just rc_draw, go back
.gotokay
        cp      in_ent
        ld      a,@00100001
        jr      nz,inplop                       ; continue entry if not ended by ENTER
        ld      c,b
        ld      b,0
        ld      hl,pad-1
        add     hl,bc                           ; HL=address of terminating null
        ld      (hl),'.'                        ; append extension
        inc     hl
        ld      (hl),'a'
        inc     hl
        ld      (hl),'p'
        inc     hl
        pop     de
        ld      (hl),e
        inc     hl
        ld      (hl),0
        ld      hl,msg_cursoroff
        call_oz(gn_sop)
        ret


; Display information window
;       IN:     -
;       OUT:    -
;
; Registers changed:
;       ......../IXIY same
;       AFBCDEHL/.... different

.dispinfo
        ld      hl,msg_infheadings
        call_oz(gn_sop)                         ; display info window headings
        ld      (iy+3),3                        ; start with slot 3
.inflp
        ld      hl,msg_infpos
        call_oz(gn_sop)
        ld      a,(iy+3)
        add     a,34
        call_oz(os_out)
        ld      hl,msg_infline
        ld      de,msg_infspaces
        call    dispstuff
        call    slottype                        ; find the type
        ld      a,(iy+1)
        call    dispsize                        ; display RAM size
        ld      hl,msg_infspaces
        call_oz(gn_sop)
        ld      a,$3f
        call    bindbank                        ; bind in top bank
        xor     a                               ; zero ROM size
        bit     1,(iy+2)                        ; is ROM there?
        jr      z,noromhere
        ld      a,($7ffc)                       ; get ROM size
.noromhere
        call    dispsize                        ; display ROM size
        ld      hl,msg_infspaces
        call_oz(gn_sop)
        ld      a,(iy+2)
        cp      3                               ; is ROM/RAM card here?
        ld      a,0                             ; zero PROT size
        jr      nz,noprotted
        ld      a,($7ff7)                       ; get PROT size
.noprotted
        call    dispsize
        ld      hl,msg_safish
        bit     0,(iy+2)
        jr      z,safish                        ; not RAM, so who cares if safe?!
        call    protsafe                        ; attempt to make safe
        ld      hl,msg_safeyes
        jr      nc,safish
        ld      hl,msg_safeno
.safish
        call_oz(gn_sop)
        dec     (iy+3)
        jr      nz,inflp                        ; loop back for other slots
        ret


; Display size in K
;       IN:     A=banks (0-64)
;       OUT:    -
;
; Registers changed:
;       ......../IXIY same
;       AFBCDEHL/.... different

.dispsize
        and     a
        jr      z,nosize
        ld      c,a
        ld      b,0
        sla     c
        rl      b
        sla     c
        rl      b
        sla     c
        rl      b
        sla     c
        rl      b                               ; BC=16*banks
        ld      hl,2
        ld      de,pad
        ld      a,4*16
        call_oz(gn_pdn)
        ex      de,hl
        ld      (hl),'K'
        inc     hl
        ld      (hl),0
        ld      hl,pad
        call_oz(gn_sop)
        ret
.nosize
        ld      hl,msg_nosize
        call_oz(gn_sop)
        ret

ENDIF


; Get address-3 of first DOR in new card, ready for GETDOR to process
;       IN:     -
;       OUT:    BHL=address-3 of first new DOR
; Registers changed:
;       ...CDE../IXIY same
;       AFB...HL/.... different

.firstdor
        ld      hl,$7fc3                        ; use ROM Front DOR
        ld      b,(iy+5)                        ; in top bank
        ret


; Deallocate a bank
;       IN:     A=bank
;       OUT:    Fc=1 if bank wasn't allocated to $0001
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.deallocate
        and     a                               ; clear carry
        inc     a
        ret     z                               ; exit if $ff
        dec     a       
        push    bc
        push    de
        push    hl
        call    matadd
        push    hl
        call    checkbank                       ; check current allocation
        pop     hl
        cp      2
        jr      nc,baddeal                      ; move on unless 0 or 1
        ld      de,$0000
        call    setbank                         ; deallocate bank
        and     a                               ; Fc=0, success
.exitdeal
        pop     hl
        pop     de
        pop     bc
        ret
.baddeal
        scf                                     ; Fc=1, error
        jr      exitdeal


; Convert a pointer
;       IN:     HL=address of pointer to convert
;       OUT:    HL=address of pointer bank
;               A=new bank
; Registers changed:
;       ..BCDE../IXIY same
;       AF....HL/.... different

.cnvptr
        ld      a,(hl)
        inc     hl
        or      (hl)                            ; test pointer address
        inc     hl
        ld      a,(hl)
        jr      nz,cnvbank                      ; if non-zero, convert any bank
                                                ; else continue to convert non-zero bank

; Convert a bank reference
;       IN:     A=bank in card ($00 to $ff)
;       OUT:    A=actual RAM bank ($3f-based)
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.cnvn0bank
        and     a
        ret     z                               ; don't convert a zero bank
.cnvbank
        push    bc
        push    hl
        or      @11000000
        ld      c,a                             ; C=-1,-2 etc
.cnvloop2
        call    loopparms                       ; B=#banks, HL=list
.cnvloop
        inc     c
        jr      z,converted
        inc     hl                              ; step through list
        djnz    cnvloop
        jr      cnvloop2                        ; re-initialise list if at end
.converted
        ld      a,(hl)                          ; get correct bank
        pop     hl
        pop     bc
        ret


; Display a message, slot number and message
;       IN:     HL=first message
;               DE=second message (or enter at dispdotstuff)
;       OUT:    -
; Registers changed:
;       ..BC..../IXIY same
;       AF..DEHL/.... different

.dispdotstuff
        ld      de,msg_dots
.dispstuff
        call_oz(gn_sop)
        ld      a,(iy+3)
        add     a,'0'
        call_oz(os_out)
        ex      de,hl
        call_oz(gn_sop)
        ret


; Display a hex pair
;       IN:     A=byte
;       OUT:    -
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.hexpair
        push    af
        rlca
        rlca
        rlca
        rlca
        and     $0f
        cp      10
        jr      c,numeric1
        add     a,'A'-10
        jr      alpha1
.numeric1
        add     a,'0'
.alpha1
        call_oz(os_out)
        pop     af
        and     $0f
        cp      10
        jr      c,numeric2
        add     a,'A'-10
        jr      alpha2
.numeric2
        add     a,'0'
.alpha2
        call_oz(os_out)
        ret


; Load file to segment 1
;       IN:     A=filetype (0 or 1)
;       OUT:    Fc=1 if error
;               E=error code
; Registers changed:
;       ......../IXIY same
;       AFBCDEHL/.... different

.loadfile
        push    ix                              ; save registers
        push    af                              ; save filetype
        ld      hl,(extension)
        add     a,'0'
        ld      (hl),a                          ; modify extension
        ld      hl,msg_loading
        call_oz(gn_sop)
        ld      hl,explicitname
        call_oz(gn_sop)                         ; display name
        ld      hl,msg_tobank
        call_oz(gn_sop)
        ld      a,($04d1)                       ; get bank number
        call    hexpair
        ld      hl,msg_dots
        call_oz(gn_sop)
        ld      hl,explicitname
        ld      b,0
        ld      de,pad
        ld      c,padlength
        ld      a,op_in
        call_oz(gn_opf)                         ; open the file
        jr      c,fileerr
        pop     af                              ; restore filetype
        add     a,a
        add     a,a                             ; A=4*filetype
        ld      hl,filebuffer+8                 ; start of offset/length pairs
        ld      c,a
        ld      b,0
        add     hl,bc                           ; HL points to offset & length info
        ld      e,(hl)
        inc     hl
        ld      a,(hl)
        inc     hl
        and     @00111111
        or      @01000000
        ld      d,a                             ; offset, masked into segment 1
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                          ; length of file
        ld      hl,0                            ; move from file to memory
        call_oz(os_mv)                          ; copy file to segment 1
        push    af                              ; save any error
        call_oz(gn_cl)                          ; close file
        pop     af
        ld      e,a                             ; place any error code in E
        pop     ix                              ; restore registers
        ret                                     ; done
.fileerr
        pop     de                              ; discard filetype
        ld      e,a                             ; place any error code in E
        pop     ix                              ; restore filehandle
        ret                                     ; exit with error


; Add blank ROM header to a RAM card
;       IN:     Segment 1 bound to top card bank
;       OUT:    -
; Registers changed:
;       ......../IXIY same
;       AFBCDEHL/.... different

.addheader
        ld      hl,romheader
        ld      de,$7fc0
        ld      bc,64
        ldir                                    ; copy basic header
        ld      a,$5a
        ld      ($7ff9),a                       ; set card ID
        ld      a,($04d1)
        ld      ($7ff8),a
        ret

.romheader
        defb    0,0,0                           ; parent
        defb    0,0,0                           ; brother
        defb    0,0,0                           ; son
        defb    $13                             ; ROM Front DOR type
        defb    8                               ; length
        defb    'N'                             ; name key
        defb    5                               ; name length
        defm    "APPL",0
        defb    $ff                             ; DOR terminator
        defs    37                              ; unused part
        defw    0                               ; card ID
        defb    @00000011                       ; UK
        defb    $80                             ; external app
        defb    0                               ; card size
        defb    0                               ; card subtype
        defm    "OZ"                            ; identifier


; Find free RAM banks in slot
;       IN:     A=even bank flags
;               E=0 if shouldn't assign reserved banks
;               (IY+3)=slot number
;       OUT:    (IY+4)=free banks found
;               (IY+5) to (IY+12)=bank numbers ($3f based)
; Registers changed:
;       ......../IXIY same
;       AFBCDEHL/.... different

.getfree
        exx
        ld      b,a                             ; B'=even bank flags
        ld      c,0                             ; C'=assigned bank flags
        exx
        call    slottype                        ; bind MAT to seg 2, get type/banks
        ld      a,$3f
        call    matadd                          ; get address of end of MAT in HL
        ld      (iy+4),0                        ; none available
        bit     0,(iy+2)                        ; check slot type
        ret     z                               ; if doesn't contain RAM, no good
        call    protsafe                        ; if it does, protect safe page if possible
        ld      a,e
        and     a
        jr      z,notresvd                      ; move on if shouldn't use reserved
        ld      a,$3f                           ; top bank
.useresvd
        call    bindbank
        ld      a,($7ff6)
        and     a
        jr      z,notresvd                      ; move on if end of reserved list
        ld      e,a
        call    assignbank                      ; assign bank
        ld      a,e
        jr      useresvd
.notresvd
        ld      e,$3f                           ; top bank
        ld      d,(iy+1)                        ; number of banks
.check1
        call    checkbank                       ; test next bank
        call    z,assignbank                    ; offer it to assigned banks if free
.notgot
        dec     e
        dec     d
        jr      nz,check1                       ; loop back to re-check
        ret                                     ; exit if out of banks


; Assign a bank to available banks
;       IN:     E=bank
;               B'=even bank flags
;               C'=assigned bank flags
;       OUT:    (IY+4) updated if assigned
;               (IY+5) to (IY+12) updated
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.assignbank
        ld      a,e
        exx                                     ; use alternate set
        push    iy
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl                              ; HL=address to place first bank-1
        ld      d,8                             ; number of banks
.asloop
        inc     hl                              ; point to next bank
        rrc     c
        jr      c,isass                         ; move on if already assigned
        rrc     b
        jr      nc,noeven                       ; skip next test if don't need even bank
        bit     0,a
        jr      z,noeven                        ; go to assign if it's even
        push    bc                              ; save current registers
        push    de
        push    af
        push    hl
        ld      a,9
        sub     d
        ld      d,a                             ; count backwards through previous banks
        rlc     c                               ; step back past current
.swaplp2
        rlc     b
.swaploop
        dec     d
        jr      z,noswap
        dec     hl
        rlc     c
        jr      nc,swaplp2                      ; can't swap if bank not assigned here
        rlc     b
        jr      c,swaploop                      ; or if it also needs even bank
        ld      a,(hl)
        bit     0,a
        jr      nz,swaploop                     ; or if it's also an odd bank
        pop     bc
        ld      (bc),a                          ; put earlier even bank to current address
        pop     af
        ld      (hl),a                          ; and odd bank to this one
        ld      h,b
        ld      l,c                             ; restore HL
        pop     de                              ; restore regs
        pop     bc
        jr      doneswap                        ; and complete assignment
.noswap
        pop     hl                              ; restore registers
        pop     af
        pop     de
        pop     bc
        jr      isodd                           ; don't assign it at all
.noeven
        ld      (hl),a                          ; store bank
.doneswap
        set     7,c                             ; signal bank is assigned
.shftflgs
        dec     d
        jr      z,noround
        rrc     c                               ; shift flags back to start
        rrc     b
        jr      shftflgs
.noround
        ld      d,8
        ld      e,c                             ; E=assigned banks
        xor     a                               ; count available banks
.cntbnks
        rrc     e
        jr      nc,stopcnt                      ; stop counting as soon as get unassigned
        inc     a
        dec     d
        jr      nz,cntbnks
.stopcnt
        ld      (iy+4),a                        ; store count of banks
        exx
        ret
.isass
        rrc     b
.isodd
        dec     d
        jr      nz,asloop
        exx
        ret                                     ; exit without assigning


; Messages

IF BASINST

.msg_window
        defm    0


ELSE

.msg_mailname
        defm    "NAME",0

.msg_window
        defm    1,"7#1",32+18,32,32+50,32+8,131
        defm    1,"2I1"
        defm    1,"4+TUR",1,"2JC",1,"3@",32,32
        defm    "Installer v2.03"
        defm    1,"3@",32,32,1,"2A",32+50
        defm    1,"7#1",32+18,32+1,32+50,32+7,129
        defm    1,"2C1",1,"S",0

.msg_nosize
        defm    "   - ",0
.msg_infheadings
        defm    1,"2+T"
        defm    1,"3@",32+17,32+1,"RAM    ROM    RSVD    SAFE",0
.msg_infpos
        defm    1,"3@",32+8,0
.msg_infline
        defm    "SLOT ",0
.msg_infspaces
        defm    "  ",0
.msg_safish
        defb    0
.msg_safeyes
        defm    "     *",0
.msg_safeno
        defm    "     ?",0

.msg_toinstall
        defm    "  Install: ",1,"C",0
.msg_touninstall
        defm    "Uninstall: ",1,"C",0
.msg_atinput
        defm    1,"2X",32+11,0
.msg_cursoroff
        defm    1,"C",13,10,0

.msg_barwindow
        defm    1,"7#2",32+1,32,32+15,32+8,131
        defm    1,"2I2"
        defm    1,"4+TUR",1,"2JC",1,"3@",32,32
        defm    "Commands"
        defm    1,"3@",32,32,1,"2A",32+15
        defm    1,"7#2",32+1,32+1,32+15,32+7,129
        defm    1,"2C2",1,"T"
        defm    "   SLOT INFO",13,10
        defm    "   PACKAGES",13,10
        defm    "   FEATURES",13,10
        defm    "   INSTALL",13,10
        defm    "   UNINSTALL",13,10
        defm    "   RESERVE",13,10
        defm    "   QUIT",1,"T",0

.msg_barstart
        defm    1,"2H2",1,"R",1,"3@",32,0

.msg_barend
        defm    1,"2A",32+15,1,"2H1",0

.msg_regging
        defm    "Registering available packages...",13,10,0
.msg_kpack
        defm    "Enter package ID $",0
.msg_dpacks
        defm    "Deregistering packages...",13,10,0
.msg_pkgid
        defm    "ID $",0
.msg_inaccpkg
        defm    "<inaccessible - was in slot ",0
.msg_inaccend
        defm    ">",13,10,0
.msg_nodereg
        defm    " - in use",13,10,0
.msg_deregd
        defm    " - deregistered",13,10,0
.msg_notthere
        defm    " - not present",13,10,0
.msg_packages
        defm    "Installed packages:",13,10,0
.msg_pkgver
        defm    " v",0
.msg_inslot
        defm    " [",0
.msg_pkgusing
        defm    "]: ",0
.msg_numhands   
.msg_numbytes
        defm    " / ",0
.msg_numuser
        defm    13,10,0

.msg_features
        defm    1,"2+BFeature Settings:",1,"2-B",13,10,0
.msg_ftrace
        defm    "Tracing: ",0
.msg_fints
        defm    "Interrupt handling: ",0
.msg_fplus
        defm    "OZPlus Features: ",0
.msg_fon
        defm    "On",13,10,0
.msg_foff
        defm    "Off",13,10,0
.msg_fglobal
        defm    "Global",13,10,0
.msg_fsingle
        defm    "Single process ('",0
.msg_fendprname
        defm    "')",13,10,0
.msg_fpkgi
        defm    "Registered package interrupts: ",0
.msg_fproi
        defm    "Registered process interrupts: ",0

.msg_toslowmo
        defm    "Percentage:",1,"C",0
.msg_slowmo
        defm    "Speed reduction (1-100%) or ENTER to disable",13,10,0
.msg_slowok
        defm    "SlowMo activated",13,10,0
.msg_cantslow
        defm    "Unable to activate SlowMo - no free interrupts",13,10,0
.msg_noslow
        defm    "SlowMo disabled",13,10,0
.msg_reservewhat
        defm    "Banks to reserve (1 to 8)?",13,10,0
.msg_slotbusyp
        defm    "Packages registered in slot ",0


ENDIF


.msg_installing
        defm    "Installing in slot ",0
.msg_patching
        defm    " patching"
.msg_dots
        defm    "...",13,10,0
.msg_createapu
        defm    " creating .APU file...",13,10,0
.msg_done
        defm    "Done!",7,0
.msg_scanslots
        defm    "Scanning...",13,10,0
.msg_uninslot
        defm    " purging slot ",0
.msg_freeslot
        defm    " freeing banks in slot ",0
.msg_reserving
        defm    "Reserving banks in slot ",0
.msg_verifyapu
        defm    "Validating...",13,10,0
.msg_uninstalling
        defm    " uninstalling...",13,10,0
.msg_loading
        defm    " loading ",0
.msg_tobank
        defm    " to bank $",0
.msg_error
        defm    13,10,1,"2+BERROR: ",0
.msg_adding
        defm    " adding ",0
.msg_reming
        defm    " removing ",0
.msg_slotbusya
        defm    "Applications active in slot ",0
.msg_cantuninst
        defm    " - cannot uninstall",13,10,0
.msg_cantpurge
        defm    " - slot not purged",13,10,0

