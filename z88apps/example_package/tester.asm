; *************************************************************************************
; Tester & Example Package (c) Garry Lancaster 2000-2011
;
; Tester & Example Package is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2, or (at your option) any later version.
; Tester & Example Package is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with
; Tester & Example Package; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

; Tester Application
; 31/1/00-10/3/00 GWL
; This application is used to demonstrate the use of package calls
; and the facilities provided by the "Packages" package. It also provides
; the "example" package.


        module  tester

        org     $c000

; Here we reference the package information block for the example package,
; which is linked in our DOR so that it can be found by the system. Every
; package must be linked to one application in this way.

        xref    pkg_block

        defc    appl_bank=$3f                   ; our bank
        defc    safe=65                         ; workspace used
        defc    unsafe=0
        defc    maxget=16
        defc    banksgot=$1ffe-safe
        defc    scratch=$1ffe-safe+17



include "director.def"
include "dor.def"
include "error.def"
include "stdio.def"
include "fileio.def"
include "integer.def"
include "packages.def"                          ; include packages definitions
include "exampkg.def"                           ; plus definitions for every package needed


; Now comes the application DOR

.in_dor
        defb    0,0,0                           ; links to parent, brother (app), son (package)
        defb	0,0,0
        defw    pkg_block                       ; the link to the package info block
        defb    appl_bank                       ; linked package *must* be in same bank as DOR
        defb    $83                             ; DOR type - application
        defb    indorend-indorstart
.indorstart
        defb    '@'                             ; key to info section
        defb    ininfend-ininfstart
.ininfstart
        defw    0
        defb    'X'                             ; application key
        defb    0                               ; no bad app memory
        defw    0                               ; overhead
        defw    unsafe                          ; unsafe workspace
        defw    safe                            ; safe workspace
        defw    testentry                       ; entry point
        defb    0                               ; bank bindings
        defb    0
        defb    0
        defb    appl_bank
        defb    at_good                         ; good application
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
        defb    0,0,0                           ; no tokens
.inhlpend
        defb    'N'                             ; key to name section
        defb    innamend-innamstart
.innamstart
        defm    "Tester",0
.innamend
        defb    $ff
.indorend

; Topic entries

.in_topics
        defb    0

.incom_topic
        defb    incom_topend-incom_topic
        defm    "COMMANDS",0
        defb    0
        defb    0
        defb    0
        defb    incom_topend-incom_topic

.incom_topend
        defb    0

; Command entries

.in_commands
        defb    0
        
.in_coms1
        defb    in_coms2-in_coms1
        defb    $80
        defm    "PR",0
        defm    "Register process",0
        defb    0
        defb    0
        defb    0
        defb    in_coms2-in_coms1

.in_coms2
        defb    in_coms3-in_coms2
        defb    $81
        defm    "PD",0
        defm    "Deregister process",0
        defb    0
        defb    0
        defb    0
        defb    in_coms3-in_coms2

.in_coms3
        defb    in_coms3a-in_coms3
        defb    $82
        defm    "KR",0
        defm    "Register package",0
        defb    0
        defb    0
        defb    0
        defb    in_coms3a-in_coms3

.in_coms3a
        defb    in_coms4-in_coms3a
        defb    $83
        defm    "KD",0
        defm    "Deregister package",0
        defb    0
        defb    0
        defb    0
        defb    in_coms4-in_coms3a

.in_coms4
        defb    in_coms5-in_coms4
        defb    $84
        defm    "FG",0
        defm    "Get file",0
        defb    0
        defb    0
        defb    1
        defb    in_coms5-in_coms4

.in_coms5
        defb    in_coms6-in_coms5
        defb    $85
        defm    "SR",0
        defm    "Register subs.",0
        defb    0
        defb    0
        defb    0
        defb    in_coms6-in_coms5

.in_coms6
        defb    in_coms7-in_coms6
        defb    $86
        defm    "SD",0
        defm    "Deregister subs.",0
        defb    0
        defb    0
        defb    0
        defb    in_coms7-in_coms6

.in_coms7
        defb    in_coms8-in_coms7
        defb    $87
        defm    "TC",0
        defm    "OZ test call",0
        defb    0
        defb    0
        defb    1
        defb    in_coms8-in_coms7

.in_coms8
        defb    in_coms9-in_coms8
        defb    $88
        defm    "BA",0
        defm    "Allocate any bank",0
        defb    0
        defb    0
        defb    0
        defb    in_coms9-in_coms8

.in_coms9
        defb    in_coms10-in_coms9
        defb    $89
        defm    "BE",0
        defm    "Allocate even bank",0
        defb    0
        defb    0
        defb    0
        defb    in_coms10-in_coms9

.in_coms10
        defb    in_coms_end-in_coms10
        defb    $8a
        defm    "BF",0
        defm    "Free bank",0
        defb    0
        defb    0
        defb    0
        defb    in_coms_end-in_coms10

.in_coms_end
        defb    0


; Help entries

.in_help
        defm    $7f
        defm    "An example of using packages and interrupts",$7f
        defm    "by Garry Lancaster",$7f
        defm    "v1.05, 10th March 2000",$7f
        defb    0



; Main application entry point

.testentry
        jp      teststart
        scf
        ret
.teststart
        xor     a
        ld      (banksgot),a                    ; zeroise grabbed banks
        ld      hl,msg_window
        call_oz(gn_sop)                         ; draw the screen
        ld      a,sc_dis
        call_oz(os_esc)                         ; disable ESC detection
        call_pkg(pkg_ayt)                       ; is package handling installed?
        jp      c,nopkgs                        ; exit app if not
        call_pkg(exm_ayt)                       ; is example package available?
        jr      nc,gotexm
        ld      hl,msg_noexm
        call_oz(gn_sop)                         ; complain but continue

; Now we'll name our instantiation using the process ID obtained with
; the package call pkg_pid. Notice that if any of the pkg_xxx calls
; return an error of rc_pnf, the only way to get the "Packages" package
; re-installed is to run Installer, so we just exit with an error.

.gotexm
        ld      hl,msg_myname
        ld      de,scratch
        ld      bc,msg_endname-msg_myname
        ldir                                    ; copy name to scratch area
        ld      iy,pkg_pid                      ; an alternate way to call
        rst     $10                             ; packages by IY, with rst10
        jp      c,nopkgs                        ; only error would be rc_pnf
        ld      c,a                             ; save ID
        and     $f0
        rlca
        rlca
        rlca
        rlca
        add     a,'0'
        cp      '9'+1
        jr      c,ldig1
        add     a,7
.ldig1
        ld      (de),a                          ; set high hex digit
        inc     de
        ld      a,c
        and     $0f
        add     a,'0'
        cp      '9'+1
        jr      c,ldig2
        add     a,7
.ldig2
        ld      (de),a                          ; set low hex digit
        inc     de
        xor     a
        ld      (de),a                          ; null-terminate name
        ld      hl,scratch
        call_oz(dc_nam)                         ; name ourself


; Now here's the main loop. We'll start off in OS_IN mode

.start_osin
        call_oz(os_pur)                         ; purge keyboard buffer
        ld      hl,msg_mode_osin
        call_oz(gn_sop)
.osin_loop
        call_oz(os_in)
        call    c,inperr                        ; deal with errors
        cp      $80
        jp      z,regprocess
        cp      $81
        jp      z,drgprocess
        cp      $82
        jp      z,regpackage
        cp      $83
        jp      z,drgpackage
        cp      $84
        jp      z,getfile
        cp      $85
        jp      z,subsosgb
        cp      $86
        jp      z,relsosgb
        cp      $87
        jp      z,testcall
        cp      $88
        jp      z,grabany
        cp      $89
        jp      z,grabeven
        cp      $8a
        jp      z,freeone
        cp      'S'
        jr      z,start_scan
        cp      's'
        jr      z,start_scan
        cp      'D'
        jr      z,dodctrs
        cp      'd'
        jr      nz,osin_loop
.dodctrs
        call    dispctrs
        jr      osin_loop

; Now the scan mode loop

.start_scan
        ld      hl,msg_mode_scan
        call_oz(gn_sop)
.scan_loop
        ld      bc,$f7b2
        in      a,(c)
        and     @00001000                       ; check for "D"
        call    z,dispctrs
        ld      bc,$efb2
        in      a,(c)
        and     @00001000                       ; check for "S"
        jr      z,start_osin
        ld      bc,25000
.scanlp
        dec     bc
        ld      a,b
        or      c
        jr      nz,scanlp                       ; pause for ~0.2s
        jr      scan_loop


; At this point, we find there is no package-handling code installed,
; so we can't proceed at all, as any call_pkg macros would cause a crash

.nopkgs
        ld      hl,msg_nopacks
        call_oz(gn_sop)
        call_oz(os_in)
        xor     a
        call_oz(os_bye)


; Subroutine to display the counters

.dispctrs
        ld      hl,msg_myctr
        ld      bc,(scratch)
        call    shownum
        ld      hl,msg_pkgctr
.disp2
        call_pkg(exm_cget)                      ; get the package's counter
        jp      nc,shownum                      ; display if no error
        call_pkg(exm_ayt)                       ; error must be rc_pnf, so try
                                                ; to relocate package
        jr      nc,disp2                        ; if okay, try again
        ld      hl,msg_nodispctr
        call_oz(gn_sop)                         ; else complain
        ret


; Subroutine to display counter BC after message HL

.shownum
        call_oz(gn_sop)
        ld      hl,2
        ld      de,scratch+2
        xor     a
        call_oz(gn_pdn)                         ; form ascii string
        xor     a
        ld      (de),a                          ; add terminator
        ld      hl,scratch+2
        call_oz(gn_sop)
        call_oz(gn_nln)
        ret


; Routine to register an interrupt for this process only
; Note that if a pkg_xxx call fails, using pkg_ayt cannot reinstall
; the "Packages" package, so we'll just have to fail with a message.
; For all other packages, we would first attempt the xxx_ayt procedure.

.regprocess
        call    getparams                       ; get required type & freq
        ld      hl,procint                      ; our interrupt routine
        ld      a,int_prc
        call_pkg(pkg_intr)                      ; register
        ld      hl,msg_regprook
        jr      nc,regproshow                   ; on if okay
        ld      hl,msg_regpkgsgone
        cp      rc_pnf                          ; was package available?
        jr      z,regproshow
        ld      hl,msg_regnoroom                ; otherwise must be rc_room
.regproshow
        call_oz(gn_sop)
        ld      hl,0
        ld      (scratch),hl                    ; reset the counter
        jp      osin_loop


; Here's the interrupt code we run for our process
; We can corrupt AF and any alternate registers, but no main registers
; except IX. We must always set Fc=0 on exit.

.procint
        exx
        ld      hl,(scratch)
        inc     hl                              ; increment our counter
        ld      (scratch),hl
        exx
        and     a                               ; Fc=0 [required]
        ret


; Routine to register an interrupt for the package
; Very similar to the previous call, except when registering we'll
; also try to reset the package's counter if possible.

.regpackage
        call    getparams                       ; get required type & freq
        ld      hl,exm_int                      ; our interrupt call ID
        ld      a,int_pkg
        call_pkg(pkg_intr)                      ; register
        ld      hl,msg_regpkgok
        jr      nc,regpkgshow                   ; on if okay
        ld      hl,msg_regpkgsgone
        cp      rc_pnf                          ; was package available?
        jr      z,regpkgshow
        ld      hl,msg_regnoroom                ; otherwise must be rc_room
.regpkgshow
        call_oz(gn_sop)
        ld      bc,0
.docset
        call_pkg(exm_cset)                      ; reset the counter
        jp      nc,osin_loop                    ; exit if okay
        call_pkg(exm_ayt)                       ; reinstall package if possible
        jr      nc,docset                       ; and try again if success
        ld      hl,msg_nocset
        call_oz(gn_sop)                         ; complain
        jp      osin_loop


; Subroutine to get parameters for registering an interrupt
; Exits with C=interrupt type & B=frequency, as required by pkg_intr

.getparams
        ld      hl,msg_whatint
        call_oz(gn_sop)
.getint
        call_oz(os_in)
        call    c,inperr                        ; deal with errors
        ld      c,int_tick
        cp      'T'
        jr      z,gotint
        cp      't'
        jr      z,gotint
        ld      c,int_sec
        cp      'S'
        jr      z,gotint
        cp      's'
        jr      z,gotint
        ld      c,int_min
        cp      'M'
        jr      z,gotint
        cp      'm'
        jr      nz,getint
.gotint
        call_oz(os_out)
        call_oz(gn_nln)
        ld      hl,msg_whatfreq
        call_oz(gn_sop)
.getfrq
        call_oz(os_in)
        call    c,inperr                        ; deal with errors
        cp      '1'
        jr      c,getfrq
        cp      '9'+1
        jr      nc,getfrq
        call_oz(os_out)
        call_oz(gn_nln)
        sub     '0'
        ld      b,a
        ret


; Routine to deregister an interrupt for this process only, or
; for the package, depending on entry point

.drgpackage
        ld      a,int_pkg
        ld      hl,exm_int                      ; the call ID to deregister
        jr      deregister
.drgprocess
        ld      a,int_prc
.deregister
        call_pkg(pkg_intd)                      ; deregister
        ld      hl,msg_drgok
        jr      nc,drgshow                      ; on if okay
        ld      hl,msg_drgpkgsgone
        cp      rc_pnf                          ; was package available?
        jr      z,drgshow
        ld      hl,msg_drgnotreg                ; otherwise must be rc_hand
.drgshow
        call_oz(gn_sop)
        ld      hl,0
        ld      (scratch),hl                    ; reset the counter
        jp      osin_loop


; Routine to get a file to the screen
; This just opens any file & types all ASCII characters to the screen
; It's purpose is to demonstrate the test substitution of OS_GB. The same
; effect would be seen with this short BASIC program:
;       10 X=OPENIN(":*//*")
;       20 A=BGET#X
;       30 PRINT CHR$(A);
;       40 GOTO 20

.getfile
        ld      b,0
        ld      hl,anyfilename
        ld      de,scratch+2
        ld      c,1
        ld      a,op_in
        call_oz(gn_opf)                         ; open a file
        jr      c,noopen
        ld      bc,2048                         ; max 2048 chars to type
.getlp
        call_oz(os_gb)                          ; get a byte
        jr      c,endget                        ; finish on error (rc_eof)
        cp      10
        jr      z,dispch                        ; allow CR/LF
        cp      13
        jr      z,dispch
        cp      ' '
        jr      c,dispdot
        cp      '~'+1
        jr      c,dispch
.dispdot
        ld      a,'.'                           ; replace non-ASCII with "."
.dispch
        call_oz(os_out)                         ; display it
        dec     bc
        ld      a,b
        or      c
        jr      nz,getlp
.endget
        call_oz(gn_nln)
        call_oz(gn_cl)                          ; close file
        jp      osin_loop
.noopen
        ld      hl,msg_noopen
        call_oz(gn_sop)
        jp      osin_loop

.anyfilename
        defm    ":*//*",0


; Routine to set up a call substitution for OS_GB, and for GN_DEL
; using the EXM_GB and EXM_DEL calls from our example package.

.subsosgb
        ld      de,os_gb                        ; the call to replace
        ld      bc,exm_gb                       ; what we're using instead
        call_pkg(pkg_ozcr)                      ; register it
        ld      hl,msg_subsok
        jr      nc,donesubs                     ; show if okay
        ld      hl,msg_subsbad
.donesubs
        call_oz(gn_sop)
        ld      de,gn_del
        ld      bc,exm_del
        call_pkg(pkg_ozcr)
        ld      hl,msg_subs2ok
        jr      nc,donesubs2
        ld      hl,msg_subs2bad
.donesubs2
        call_oz(gn_sop)
        jp      osin_loop


; In an almost identical way, we remove the substitutions,
; returning control to the standard calls

.relsosgb
        ld      de,os_gb                        ; set parameters as before
        ld      bc,exm_gb
        call_pkg(pkg_ozcd)                      ; deregister it
        ld      hl,msg_relsok
        jr      nc,donerels                     ; show if okay
        ld      hl,msg_relsbad
.donerels
        call_oz(gn_sop)
        ld      de,gn_del
        ld      bc,exm_del
        call_pkg(pkg_ozcd)
        ld      hl,msg_rels2ok
        jr      nc,donerels2
        ld      hl,msg_rels2bad
.donerels2
        call_oz(gn_sop)
        jp      osin_loop


; This routine sets up all registers with dummy values, and does a test
; OZ call to ensure tracing is performing correctly

.testcall
        ld      bc,$0111
        push    bc
        pop     af                              ; AF=$0111
        ld      bc,$2131
        ld      de,$4151
        ld      hl,$6171
        ld      ix,$8191
        ld      iy,$a1b1
        call_oz(dc_pol)                         ; use DC_POL as it's unusual
                                                ; and doesn't do anything much
        ld      hl,msg_tested
        call_oz(gn_sop)
        jp      osin_loop


; This routine attempts to allocate a bank of memory for this
; application's usage, using the new pkg_bal call. Entry is at
; grabany for any bank, grabeven for even banks only (useful if you
; need to bind them to segment 0)

.grabeven
        ld      e,bnk_even
        jr      grabone
.grabany
        ld      e,bnk_any
.grabone
        ld      a,(banksgot)
        cp      maxget
        ld      hl,msg_got16
        jr      z,endgrab                       ; this app won't grab more than 16 banks
        ld      hl,banksgot+1
        ld      c,a
        ld      b,0
        add     hl,bc                           ; HL points to address to store bank #
        ld      a,e                             ; reason code from earlier
        call_pkg(pkg_bal)                       ; attempt to grab one
        jr      nc,grabbedone                   ; on if okay
        cp      rc_pnf
        ld      hl,msg_balpkgsgone
        jr      z,endgrab                       ; complain if couldn't run the call
        ld      hl,msg_balroom                  ; else must be no room error
.endgrab
        call_oz(gn_sop)
        jp      osin_loop
.grabbedone
        ld      (hl),a                          ; store bank number we've been allocated
        ld      hl,banksgot
        inc     (hl)                            ; and increment the number
        ld      hl,msg_gotbank
        call_oz(gn_sop)
        call    hexpair                         ; show which bank we were allocated
        jp      osin_loop


; This routine frees one of the banks we've been allocated again, using
; the pkg_bfr call

.freeone
        ld      a,(banksgot)
        and     a
        ld      hl,msg_gotnone
        jr      z,endfree                       ; not got any to free
        ld      hl,banksgot
        ld      c,a
        ld      b,0
        add     hl,bc
        ld      a,(hl)                          ; A=bank number to free, from end of list
        call_pkg(pkg_bfr)                       ; attempt to free it
        jr      nc,freedone
        cp      rc_pnf
        ld      hl,msg_bfrpkgsgone
        jr      z,endfree                       ; couldn't run the call
        ld      hl,banksgot
        dec     (hl)                            ; reduce number if last one is bad anyway
        ld      hl,msg_bfrbad                   ; else must be bad bank number
.endfree
        call_oz(gn_sop)
        jp      osin_loop
.freedone
        ld      a,(hl)                          ; A=bank we freed
        ld      hl,banksgot
        dec     (hl)                            ; decrement the number we have
        ld      hl,msg_freedone
        call_oz(gn_sop)
        call    hexpair                         ; show which one we freed
        jp      osin_loop


; Subroutine to display value in A as hexadecimal

.hexpair
        push    af
        rlca
        rlca
        rlca
        rlca
        and     $0f                             ; isolate hi digit
        cp      10
        jr      c,numeric1
        add     a,'A'-10
        jr      alpha1
.numeric1
        add     a,'0'
.alpha1
        call_oz(os_out)                         ; display hi digit
        pop     af
        and     $0f                             ; isolate lo digit
        cp      10
        jr      c,numeric2
        add     a,'A'-10
        jr      alpha2
.numeric2
        add     a,'0'
.alpha2
        call_oz(os_out)                         ; display lo digit
        call_oz(gn_nln)
        ret


; Error-handling subroutine
; This deals with errors returned by the various OS_IN calls
; RC_ESC can't occur, so we're only worried about RC_QUIT & RC_DRAW

.inperr
        cp      rc_quit
        jr      z,exitapp                       ; move on if we have to quit
        cp      rc_draw
        jr      nz,endipe
        push    hl
        ld      hl,msg_window
        call_oz(gn_sop)                         ; redraw
        pop     hl
.endipe
        xor     a                               ; clear A, so no keys match
        ret


; Before exiting the application, we must deregister any process
; interrupt we have set up. The call is safe if we haven't registered
; one, so we just call it blindly and ignore the results.
; Additionally, we'll need to deallocate any banks we've previously
; grabbed. If the Packages package is not available to do this, we'll
; stop with a message asking the user to reinstate it before trying
; again.

.exitapp
        ld      a,(banksgot)
        and     a
        jr      z,exitend                       ; move on if none allocated
        ld      c,a
        ld      b,0
        ld      hl,banksgot
        add     hl,bc
        ld      a,(hl)                          ; A=last bank in list
        call_pkg(pkg_bfr)                       ; attempt to free
        jr      nc,freeok
        cp      rc_pnf                          ; if error wasn't rc_pnf,
        jr      nz,freeok                       ; ignore it and continue
        ld      hl,msg_window
        call_oz(gn_sop)                         ; else redraw ourselves
        ld      hl,msg_cantquit
        call_oz(gn_sop)                         ; say we can't exit now
        pop     hl                              ; tidy stack (ret from inperr)
        jp      osin_loop                       ; restart
.freeok
        ld      hl,banksgot
        dec     (hl)                            ; decrement banks left
        jr      exitapp                         ; loop back for rest
.exitend
        ld      a,int_prc
        call_pkg(pkg_intd)                      ; deregister process interrupt
        xor     a
        call_oz(os_bye)                         ; quit


; Application messages

.msg_window
        defm    1,"7#1",32+1,32,32+70,32+8,131
        defm    1,"2I1"
        defm    1,"4+TUR",1,"2JC",1,"3@",32,32
        defm    "Tester v1.05"
        defm    1,"3@",32,32,1,"2A",32+70
        defm    1,"7#1",32+1,32+1,32+70,32+7,129
        defm    1,"2C1",1,"S",0

.msg_nopacks
        defm    "This Z88 does not include package support; please",13,10
        defm    "install and run 'Installer' v2.00 or higher.",13,10
        defm    "Press any key to exit.",13,10,0

.msg_noexm
        defm    "Could not locate 'Example' package. Please insert",13,10
        defm    "correct card and check packages in 'Installer'.",13,10
        defm    "Some functions may be temporarily available.",13,10,0

.msg_myname
        defm    "Process ID $"
.msg_endname

.msg_mode_osin
        defm    "Running in OS_IN mode. Use menu options, or press D",13,10
        defm    "to display counters or S to switch modes.",13,10,0

.msg_mode_scan
        defm    "Running in SCAN mode. Press D to display counters",13,10
        defm    "or S to switch modes.",13,10,0

.msg_myctr
        defm    "Counter for this process: ",0

.msg_pkgctr
        defm    "Counter for 'Example' package: ",0

.msg_whatint
        defm    "Select interrupt type; ",1,"2+BT",1,"2-Bick, "
        defm    1,"2+BS",1,"2-Bec, or ",1,"2+BM",1,"2-Bin: ",0

.msg_whatfreq
        defm    "Select interrupt frequency (1-9; 1=most frequent): ",0

.msg_regprook
        defm    "Successfully registered process interrupt!",13,10,0

.msg_regpkgok
        defm    "Successfully registered package interrupt!",13,10,0

.msg_regpkgsgone
        defm    "Couldn't register interrupt: 'Packages' package not found."
        defm    13,10,0

.msg_regnoroom
        defm    "Couldn't register interrupt: chain full.",13,10,0

.msg_nocset
        defm    "Couldn't set package counter; 'Example' package unavailable."
        defm    13,10,0

.msg_nodispctr
        defm    "Couldn't read package counter; 'Example' package unavailable."
        defm    13,10,0

.msg_drgok
        defm    "Successfully deregistered interrupt!",13,10,0

.msg_drgpkgsgone
        defm    "Couldn't deregister interrupt: 'Packages' package not found."
        defm    13,10,0

.msg_drgnotreg
        defm    "Interrupt wasn't registered!",13,10,0

.msg_noopen
        defm    "Unable to open a file.",13,10,0

.msg_subsok
        defm    "OS_GB substitution successfully registered!",13,10,0

.msg_subsbad
        defm    "OS_GB substitution failed; already registered or "
        defm    "table unavailable.",13,10,0

.msg_relsok
        defm    "OS_GB substitution successfully removed!",13,10,0

.msg_relsbad
        defm    "Unable to deregister OS_GB substitution.",13,10,0

.msg_subs2ok
        defm    "GN_DEL substitution successfully registered!",13,10,0

.msg_subs2bad
        defm    "GN_DEL substitution failed; already registered or "
        defm    "table unavailable.",13,10,0

.msg_rels2ok
        defm    "GN_DEL substitution successfully removed!",13,10,0

.msg_rels2bad
        defm    "Unable to deregister GN_DEL substitution.",13,10,0

.msg_tested
        defm    "Ran test DC_POL call for tracing facility.",13,10,0

.msg_got16
        defm    "I seem to already have 16 banks; quite enough!",13,10,0

.msg_balpkgsgone
        defm    "Unable to allocate bank; 'Packages' package not found."
        defm    13,10,0

.msg_balroom
        defm    "No free banks available.",13,10,0

.msg_gotbank
        defm    "The following bank was allocated: $",0

.msg_gotnone
        defm    "I don't have any banks to free!",13,10,0

.msg_bfrpkgsgone
        defm    "Unable to deallocate bank; 'Packages' package not found."
        defm    13,10,0

.msg_bfrbad
        defm    "Error deallocating bank: bad number.",13,10,0

.msg_freedone
        defm    "The following bank was deallocated: $",0

.msg_cantquit
        defm    "Unable to quit application at this time; resources",13,10
        defm    "need to be returned to the 'Packages' package",13,10
        defm    "which is unavailable. Please install and run",13,10
        defm    "Installer v2.00 or higher before trying again.",13,10,0
