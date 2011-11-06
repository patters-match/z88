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

; Package handling package
; 13/6/99, 12/9/99 GWL
; 25/9/99 Modified to allow for error-handlers
; 2/10/99 Modified for revised standard calls
; 10/10/99 Added "expanded" standard calls
; 18/1/00-21/1/00 Added pkg_feat to pkg_intd for CALL_OZ/IM1 handling
; 23/1/00 Modified for revised RST 8 code; simple OS_GB substitution added
; 24/1/00 Interrupt stuff optimised and corrected
; 24/1/00 Added call tracing
; 25/1/00 Added single process call tracing
; 31/1/00 Added pkg_pid call
; 2/2/00 Bugfixes!
; 5/2/00 Bugfix: correct slot now reported by pkg_get if package was moved
; 13/2/00 Added full OZ call substitution system into pkg_rst20, with new
;         pkg_ozcr, pkg_ozcd calls
; 13/2/00 pkg_dat now gives details of any resources used in OZ call subs
; 14/2/00 pkg_slow added, to be installed as interrupt call for SlowMo option
; 15/2/00 pkg_bal and pkg_bfr calls added for full bank allocation
; 16/2/00 pkg_boot added to allow packages to auto-boot if they want
; 27/2/00 pkg_intm1 now used as direct call for speed
; 29/2/00 Modified for revised package structure & rst8 code
; 1/3/00 pkg_feat now runs setfcode to install/deinstall handlers as required
; 1/3/00 pkg_intm1 no longer checks if chain handling enabled (no need)
; 2/3/00 pkg_feat doesn't allow call subs if memory not allocated
; 2/3/00 pkg_rst20 split to: pkg_rst20_oz, pkg_rst20_tr, pkg_rst20_oztr
; 7/3/00 pkg_rst20_oz finally optimised & re-written!!
; 8/3/00 Fixed segment 3 fetching for process interrupts
; 12/3/00 Fixed pkg_rst20_tr
; 13/3/00 Stopped possibility of process interrupts during call subs/tracing
;         Fixed slot 0 bank allocation
; 29/4/01 Added pkg_nq to replace os_nq for enabling multiple diaries (v1.12)
; 12/5/01 Fixed pkg_rst20_oz bug causing wrong register set to be in use when
;         exiting if substitute call decided to let OZ handle the call or
;         couldn't be found
; 13/5/01 Added pkg_si to replace os_si and fix the serial interface parity bug
;         Removed this again, and commented out code, as OZ doesn't seem to use
;         the CALL_OZ interface for this case.

        module packages

include "packages.def"
include "error.def"
include "fileio.def"
include "interrpt.def"
include "syspar.def"
include "serintfc.def"
include "pkg_int.def"

        xdef    pkg_structure,call_intm1
        xdef    call_rst20_oz,call_rst20_tr,call_rst20_oztr

        xref    callun,pkgext,rst8inst,exback,code_B_src
        xref    checkmemory
        xref    slottype,checkbank,setbank
        xref    setfcode

; The package information block

.pkg_structure
        defb    $0f                             ; Package ID
        defm    "P"
        defb    $2e                             ; highest routine number
        defw    call_inf                        ; pkg_inf (00)
        defw    call_ayt_x                      ; pkg_ayt_x (02)
        defw    call_bye                        ; pkg_bye (04)
        defw    call_dat                        ; pkg_dat (06)
        defw    call_exp                        ; pkg_exp (08)
        defw    call_reg                        ; pkg_reg (0a)
        defw    call_drg                        ; pkg_drg (0c)
        defw    call_nxt                        ; pkg_nxt (0e)
        defw    call_get                        ; pkg_get (10)
        defw    call_feat                       ; pkg_feat (12)
        defw    call_rst20_oz                   ; pkg_rst20_oz (14)
        defw    call_intm1                      ; pkg_intm1 (16)
        defw    call_intr                       ; pkg_intr (18)
        defw    call_intd                       ; pkg_intd (1a)
        defw    call_pid                        ; pkg_pid (1c)
        defw    call_ozcr                       ; pkg_ozcr (1e)
        defw    call_ozcd                       ; pkg_ozcd (20)
        defw    call_slow                       ; pkg_slow (22)
        defw    call_bal                        ; pkg_bal (24)
        defw    call_bfr                        ; pkg_bfr (26)
        defw    call_boot                       ; pkg_boot (28)
        defw    call_rst20_tr                   ; pkg_rst20_tr (2a)
        defw    call_rst20_oztr                 ; pkg_rst20_oztr (2c)
        defw    call_nq                         ; pkg_nq (2e)

; pkg_inf
; IN:   -
; OUT:  Fc=0, success always
;       BHL=pointer to null-terminated package name
;       C=version of package-handling required
;       DE=package version code
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.call_inf
        ld      a,(s3_copy)
        ld      b,a
        ld      hl,inf_mess                     ; BHL points to package name
        ld      c,$01                           ; needs version 1.0
        ld      de,pversion                     ; version number
        and     a                               ; success
        ret

.inf_mess
        defm    "Packages",0


; pkg_ayt_x
; IN:   -
; OUT:  Fc=0, success always
; Registers changed after return:
;   A.BCDEHL/IXIY same
;   .F....../.... different
; Note that using pkg_ayt in assembly files normally accesses the code
; in the package-handling mechanism, not this routine

.call_ayt_x
        and     a                               ; Fc=0
        ret


; pkg_bye
; IN:   -
; OUT:  Fc=1 and A=rc_use (fail always)
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_bye
        ld      a,rc_use        
        scf                                     ; can never uninstall package-handling
        ret


; pkg_dat
; IN:   -
; OUT:  Fc=0, success always
;       CDE=bytes in use
;       B=file handles in use
;       A=package resource usage (unused)
; Registers changed after return:
;   ......HL/IXIY same
;   AFBCDE../.... different

.call_dat
        ld      a,(s1_copy)
        ex      af,af'                          ; A'=seg1 binding
        call    checkmemory                     ; test memory in use
        jr      z,nonegot
        ld      a,(subs_bank1)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind in the first page
        push    iy
        ld      iy,(subs_addr1)
        ld      a,(iy+db_pools+2)
        or      (iy+db_pools+3)                 ; check if 2nd pool in use
        pop     iy
        ld      b,1
        jr      z,onehand
        inc     b
.onehand
        ld      c,0
        ld      de,512                          ; 512 bytes allocated
        jr      end_dat
.nonegot
        ld      bc,0
        ld      de,0                            ; no resources
.end_dat
        xor     a                               ; A=0, Fc=0
        ex      af,af'
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind
        ex      af,af'
        ret


; pkg_exp
; IN:   -
; OUT:  Fc=1, fail always
;       A=RC_UNK, unknown request
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different
; Call provided for future expansion of the package-handling system

.call_exp
        ld      a,rc_unk
        scf
        ret


; pkg_reg
; IN:   A=package ID
; OUT(failed):  Fc=1
; OUT(success): Fc=0
; Registers changed after return:
;   A.BCDEHL/IXIY same
;   .F....../.... different

.call_reg
        push    bc                              ; save registers
        push    de
        push    hl
        ld      c,a                             ; C=package ID to find
        ld      a,(s1_copy)
        push    af                              ; save segment 1 binding
        ld      hl,0
        ld      (pkg_ver),hl                    ; zero version number found
        ld      b,$1f                           ; B=top ROM bank of slot 0
.reglp1
        ld      a,b
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind top bank to segment 1
        ld      hl,($7ffe)
        ld      de,$5a4f
        and     a
        sbc     hl,de                           ; check for "OZ" signature
        jp      nz,skpslt
        ld      hl,($7fc6)
        ld      a,($7fc8)                       ; AHL points to first application DOR
.reglp2
        and     $3f
        ld      d,a                             ; save bank (relative to slot)
        or      h
        or      l
        jr      z,skpslt                        ; finish this slot if null pointer
        ld      a,b
        and     @11000000
        or      d                               ; A=bank combined with slot
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind bank to segment 1
        res     7,h
        set     6,h                             ; adjust HL to seg 1 addressing
        inc     hl
        inc     hl
        inc     hl                              ; move to brother link
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)                          ; ADE=next application DOR
        inc     hl
        push    de                              ; save it
        push    af
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl                           ; HL=address of package (seg 3)
        push    hl
        ld      a,h
        or      l
        jr      z,invpkg                        ; move on if not valid package
        res     7,h                             ; convert address for seg 1
        set     6,h
        ld      a,(hl)
        inc     hl
        cp      c                               ; check ID
        jr      nz,invpkg
        ld      a,(hl)
        inc     hl
        cp      'P'                             ; check package identifier
        jr      nz,invpkg
        ld      a,(hl)
        inc     hl
        cp      8
        jr      c,invpkg                        ; must support calls $00 to $08
        pop     hl
        push    hl
        push    bc                              ; save top bank and ID
        ld      a,(s1_copy)
        ld      de,$0000
        call    pkg_callu                       ; call xx_inf routine
        ld      a,c                             ; A=version of package-handling needed
        pop     bc
        jr      c,invpkg                        ; no good if failed the xx_inf call
        cp      $01
        jr      nz,invpkg                       ; can't install if >v1.0 handling needed
        ld      hl,(pkg_ver)
        and     a
        sbc     hl,de
        jr      nc,invpkg                       ; don't bother if lower or equal version
        ld      (pkg_ver),de                    ; else save version number
        pop     hl
        push    hl
        ld      (pkg_add),hl                    ; and address
        ld      a,(s1_copy)
        ld      (pkg_bnk),a                     ; and bank
.invpkg
        pop     hl                              ; discard package address
        pop     af                              ; restore pointer to next DOR
        pop     hl
        jp      reglp2                          ; and back for more
.skpslt
        ld      a,b                             ; get top bank of current slot
        or      $3f                             ; convert slot 0 numbering to standard
        add     a,$40                           ; next slot
        ld      b,a
        jp      nc,reglp1
        ld      hl,(pkg_ver)
        ld      a,h
        or      l
        jr      z,regfail                       ; no installable version found
        push    bc                              ; save C=ID of package
        ld      hl,(pkg_add)
        ld      a,(pkg_bnk)
        ld      de,$0002
        call    pkg_callu                       ; call package's xx_ayt routine
        pop     bc                              ; C=ID
        jr      c,regfail                       ; couldn't install it
        ex      af,af'                          ; save call results (Fc=0,Fz) in F'
        ld      de,(pkg_add)
        ld      a,(pkg_bnk)                     ; ADE=pointer to package
        call    pkg_ptr                         ; set the package pointer
.regend
        pop     af
        ld      (s1_copy),a                     ; rebind original seg 1 bank
        out     (s1_port),a
        ld      hl,17
        add     hl,sp
        ex      af,af'                          ; get results (Fz,Fc) of call back
        ld      a,(hl)                          ; restore original A from RST 8 stack
        pop     hl                              ; restore registers
        pop     de
        pop     bc
        ret
.regfail
        scf
        ex      af,af'                          ; results (Fc=1) in F'
        jr      regend  


; pkg_boot
; IN:   -
; OUT:  -
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_boot
        push    bc                              ; save registers
        push    de
        push    hl
        ld      a,(s1_copy)
        push    af                              ; save segment 1 binding
        ld      c,pkg_min                       ; start package number  
.bootlp0
        ld      b,$1f                           ; B=top ROM bank of slot 0
.bootlp1
        ld      a,b
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind top bank to segment 1
        ld      hl,($7ffe)
        ld      de,$5a4f
        and     a
        sbc     hl,de                           ; check for "OZ" signature
        jr      nz,bskpslt
        ld      hl,($7fc6)
        ld      a,($7fc8)                       ; AHL points to first application DOR
.bootlp2
        and     $3f
        ld      d,a                             ; save bank (relative to slot)
        or      h
        or      l
        jr      z,bskpslt                       ; finish this slot if null pointer
        ld      a,b
        and     @11000000
        or      d                               ; A=bank combined with slot
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind bank to segment 1
        res     7,h
        set     6,h                             ; adjust HL to seg 1 addressing
        inc     hl
        inc     hl
        inc     hl                              ; move to brother link
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)                          ; ADE=next application DOR
        inc     hl
        push    de                              ; save it
        push    af
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl                           ; HL=address of package (seg 3)
        push    hl
        ld      a,h
        or      l
        jr      z,noboot                        ; move on if not valid package
        res     7,h                             ; convert address for seg 1
        set     6,h
        ld      a,(hl)
        inc     hl
        cp      c                               ; check ID
        jr      nz,noboot
        ld      a,(hl)
        inc     hl
        cp      'P'                             ; check package identifier
        jr      nz,noboot
        ld      a,(hl)
        inc     hl
        cp      8
        jr      c,noboot                        ; must support calls $00 to $08
        pop     hl
        push    hl
        push    bc                              ; save top bank and ID
        ld      a,(s1_copy)
        ld      de,$0008                        ; expansion call
        ld      b,exp_boot                      ; reason code
        call    pkg_callu                       ; call xx_boot routine
        pop     bc                              ; restore top bank & ID
        jr      c,noboot                        ; don't boot this package
        pop     hl                              ; discard package address
        pop     hl                              ; and pointer to next DOR
        pop     hl
        ld      a,c                             ; A=package ID requiring booting
        call_pkg(pkg_reg)                       ; try to register it
        jr      bootnext                        ; go to search for next package
.noboot
        pop     hl                              ; discard package address
        pop     af                              ; restore pointer to next DOR
        pop     hl
        jp      bootlp2                         ; and back for more
.bskpslt
        ld      a,b                             ; get top bank of current slot
        or      $3f                             ; convert slot 0 numbering to standard
        add     a,$40                           ; next slot
        ld      b,a
        jp      nc,bootlp1
.bootnext
        ld      a,c
        add     a,3                             ; next ID number
        ld      c,a
        cp      pkg_max+1
        jp      c,bootlp0                       ; back if not tried all packages
        pop     af
        ld      (s1_copy),a                     ; rebind original seg 1 bank
        out     (s1_port),a
        pop     hl                              ; restore registers
        pop     de
        pop     bc
        ret


; Subroutine to install a pointer in table for particular package
;
; IN:   C=package ID
;       ADE=pointer to install for package ID
; OUT:  -
; Registers changed after return:
;   A..CDE../IXIY same
;   .FB...HL/.... different

.pkg_ptr
        ld      b,0
        ld      hl,pkg_base-$0f
        add     hl,bc                           ; HL is address of pointer in table
        ld      (hl),a                          ; store bank first
        inc     hl
        ld      (hl),e                          ; then address
        inc     hl
        ld      (hl),d
        ret


; Subroutine to call a routine in a package that isn't installed
; 
; IN:   AHL=pointer to package structure block in seg 3 (assumed valid)
;       DE=call number (0,2..)
;       B=reason code to pass to call
; OUT:  ?
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.pkg_callu
        ex      af,af'
        ld      a,b                             ; A'=reason code
        ex      af,af'
        inc     hl
        inc     hl
        inc     hl                              ; skip package block header
        add     hl,de                           ; HL points to routine address
        res     7,h                             ; convert for seg 1 addressing (not seg 3)
        set     6,h
        ld      c,a                             ; save C=package bank
        ld      a,(s1_copy)
        ld      b,a                             ; save B=segment 1 binding
        ld      a,c
        ld      (s1_copy),a                     ; bind in package bank to seg 1
        out     (s1_port),a
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                          ; DE holds routine address
        ld      a,b
        ld      (s1_copy),a                     ; restore original segment 1 binding
        out     (s1_port),a
        ld      a,(s3_copy)
        push    af                              ; stack our segment 3 binding
        ld      a,c                             ; A=package bank
        ld      hl,pkgext-code_B_src+code_B_dest
        push    hl                              ; stack return into rst8 code
        push    de                              ; stack routine address
        ld      hl,oz_nestlevel
        inc     (hl)                            ; increment nesting level
        ex      af,af'
        ld      b,a                             ; restore B=reason code
        ex      af,af'
        jp      callun-code_B_src+code_B_dest   ; call it, then exit


; Subroutine to call a routine in a package that *is* installed
; 
; IN:   C=package ID, B=routine ID (or BC=call ID)
; OUT:  ?
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.pkg_calli
        push    bc
        exx
        pop     de
        ld      b,e                             ; B'=package ID
        ld      c,d                             ; C'=routine ID
        jp      rst8inst+code_B_dest-code_B_src


; Subroutine to check if a package has an entry in the pointers table
; 
; IN:   C=package ID
; OUT:  Fz=1 if not installed, Fz=0 if installed
; Registers changed after return:
;   ...CDE../IXIY same
;   AFB...HL/.... different

.pkg_inst
        ld      b,0
        ld      hl,pkg_base-$0f
        add     hl,bc                           ; HL is address of pointer in table
        ld      a,(hl)
        inc     hl
        or      (hl)
        inc     hl
        or      (hl)                            ; Fz=1 if null pointer (not installed)
        ret


; pkg_drg
; IN:   A=package ID
; OUT(failed):  Fc=1
;                  A=rc_use, resources in use
;               or A=rc_pnf, couldn't find package to deregister it
; OUT(success): Fc=0
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_drg
        push    bc
        push    de
        push    hl
        ld      c,a
        push    bc                              ; save C=package ID
        call    pkg_inst                        ; check if package is installed
        jr      z,goodbye                       ; success if not there anyway
.trybye
        pop     bc                              ; ensure C=package ID
        push    bc
        ld      b,$04
        call    pkg_calli                       ; call the xx_bye routine
        jr      nc,goodbye
        cp      rc_pnf
        jr      nz,badbye                       ; package refused to terminate
        pop     bc
        push    bc
        ld      b,$02
        call    pkg_calli                       ; call the xx_ayt routine
        jr      nc,trybye                       ; if installed it, try to remove again
        ld      b,$06
        call    pkg_calli                       ; call the xx_dat routine
        cp      rc_pnf
        jr      z,badbye                        ; really isn't there, so can't deregister
.goodbye
        pop     bc                              ; restore C=package ID
        xor     a
        ld      de,0
        call    pkg_ptr                         ; zero the package's pointer
        and     a                               ; success
        pop     hl
        pop     de
        pop     bc
        ret
.badbye
        pop     bc                              ; discard package ID
        scf                                     ; failed
        pop     hl
        pop     de
        pop     bc
        ret


; pkg_nxt
; IN:   A=last package ID (or 0)
; OUT(failed):  Fc=1, no more installed packages
; OUT(success): Fc=0
;               A=next installed package ID
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_nxt
        push    bc                              ; save registers
        push    hl
        cp      pkg_min
        jr      nc,nxtlp
        ld      a,pkg_min-3                     ; use minimum package number if was less
.nxtlp
        add     a,3                             ; next package ID
        cp      pkg_max+1
        jr      nc,nonext                       ; no more packages
        ld      c,a
        call    pkg_inst                        ; is this one installed?
        ld      a,c
        jr      z,nxtlp                         ; loop back if not
        and     a                               ; Fc=0, success
        pop     hl
        pop     bc
        ret
.nonext
        scf                                     ; Fc=1, fail
        pop     hl
        pop     bc
        ret


; pkg_get
; IN:   A=package ID
; OUT(failed):  Fc=1
;               C=slot package was installed in
;               A=rc_pnf
; OUT(success): Fc=0
;               IXh=file handles in use
;               IXlIY=bytes in use
;               A=package resources in use
;               BHL=pointer to package name
;               DE=package version code
;               C=slot package was installed in
;               
; Registers changed after return:
;   ......../.... same
;   AFBCDEHL/IXIY different

.call_get
        ld      c,a                             ; C=package ID to query
        ld      b,$02
        push    bc
        call    pkg_calli                       ; call the xx_ayt routine
        pop     bc
        push    af                              ; save results
        ld      b,0
        ld      hl,pkg_base-$0f
        add     hl,bc                           ; HL is address of pointer in table
        ld      a,(hl)                          ; A=bank of package
        rlca
        rlca
        and     3                               ; A=slot package is installed in
        ld      b,c                             ; B=package ID
        ld      c,a                             ; C=slot
        pop     af                              ; get results from xx_ayt
        ret     c                               ; exit if rc_pnf error
        push    bc                              ; save package ID and slot
        ld      c,b
        ld      b,$06
        call    pkg_calli                       ; call the xx_dat routine
        push    bc
        pop     ix                              ; IX=file handles, high bytes
        pop     bc                              ; B=package ID again, C=slot
        ret     c                               ; exit if rc_pnf error
        push    de                              ; save low bytes
        push    af                              ; and processes
        ld      a,c
        push    af                              ; save slot
        ld      c,b
        ld      b,$00
        call    pkg_calli                       ; call the xx_inf routine
        pop     af
        ld      c,a                             ; C=slot
        pop     af                              ; get processes
        pop     iy                              ; get low bytes
        ret                                     ; success


; pkg_feat
; IN:   B=mask for features to change
;       C=bits of changing features
;       E=process number if requiring trace of a single process
; OUT:  Fc=0, success always
;       C=current features
;       E=process number if single process being traced
;       B=# installed package interrupts
;       D=# installed process interrupts
; Bits (for B & C) are:
;       0: Interrupt chain processing
;       1: CALL_OZ substitution
;       2: Call tracing
;       3: Single process tracing (1); global (0)
;       (Bit 3 can only be changed at the same time as bit 2)
; Note that tracing only covers CALL_OZ at present; not CALL_PKG, FP_CALL
; or the OZ_DI/OZ_EI/OZ_BUFF calls.
; Registers changed after return:
;   ......HL/IXIY same
;   AFBCDE../.... different

.call_feat
        call    oz_di                           ; don't interrupt us now!
        push    af
        push    hl
        ld      hl,pkg_features
        rr      b                               ; chain interrupt mode?
        jr      nc,nobit0
        set     0,(hl)
        rr      c                               ; test bit
        jr      c,dobit1                        ; now turned on
        res     0,(hl)                          ; turn off interrupts
        jr      dobit1
.nobit0
        rr      c                               ; ignore bit 0
.dobit1
        rr      b                               ; CALL_OZ substitution?
        jr      nc,nobit1
        res     1,(hl)
        rr      c                               ; test bit
        jr      nc,dobit2                       ; now turned off
        ld      a,(subs_bank1)
        push    hl
        ld      hl,(subs_addr1)
        or      h
        or      l
        pop     hl
        jr      z,dobit2                        ; leave off if no allocated memory
        set     1,(hl)                          ; turn on
        jr      dobit2
.nobit1
        rr      c                               ; ignore bit 1
.dobit2
        rr      b                               ; call tracing?
        jr      nc,nobit2
        rr      c
        jr      c,traceon                       ; go to turn trace on
        res     2,(hl)                          ; turn trace off
        bit     7,(hl)                          ; is a file open?
        jr      z,nobit2                        ; if not, don't worry
        res     7,(hl)
        push    de
        push    hl
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        push    de
        ex      (sp),ix                         ; IX=file handle
        call_oz(gn_cl)                          ; close it
        pop     ix
        pop     hl
        pop     de
        jr      tracetype
.traceon
        set     2,(hl)                          ; turn trace on
        bit     7,(hl)                          ; is a file open?
        jr      nz,tracetype                    ; okay if it is
        push    bc
        push    de
        push    hl
        push    ix
        ld      b,0
        ld      hl,tracefname
        ld      de,tracefexp
        ld      c,1                             ; 1-byte explicit filename
        ld      a,op_out
        call_oz(gn_opf)                         ; open a file
        jr      c,badopen                       ; couldn't open
        ex      (sp),ix
        pop     de                              ; DE=file handle
        pop     hl                              ; HL=pkg_features again
        push    hl
        inc     hl
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        pop     hl
        pop     de
        pop     bc
        set     7,(hl)                          ; signal file open
.tracetype
        rr      b
        jr      nc,nobit2
        res     3,(hl)
        rr      c
        jr      nc,nobit2                       ; move on if global tracing
        set     3,(hl)
        inc     hl
        ld      (hl),e                          ; set process ID
        dec     hl
        jr      nobit2
.badopen
        pop     ix
        pop     hl
        pop     de
        pop     bc
        res     2,(hl)                          ; turn trace off
        jr      tracetype
.nobit2
        ld      c,(hl)                          ; C=new features
        inc     hl
        ld      e,(hl)                          ; E=traced process
        ld      a,(numints)
        ld      b,a                             ; B=# pkg interrupts
        ld      a,(numints+1)
        ld      d,a                             ; D=# process interrupts
        pop     hl
        pop     af
        call    oz_ei
        call    setfcode                        ; update the handlers
        and     a                               ; success
        ret

.tracefexp
        defb    0                               ; where gn_opf is doing its stuff
.tracefname
        defm    ":ram.-/oztrace.dat",0


; pkg_rst20_oz
; This call is only made by the patched RST 20 code, as a direct call
; rather than a package call. It carries out substitutions of some OZ
; calls. If calls are not substituted, it returns to execute them as
; normal, otherwise it jumps out. We enter in the alternate set, hence
; the unusual register requirements. 
; IN:   -
; OUT:  -
; Registers changed after return:
;   ........afbcdehl/IXIY same
;   AFBCDEHL......../.... different

.call_rst20_oz
        ld      a,(s1_copy)
        push    af                              ; save segment 1 copy
        ld      hl,7
        add     hl,sp                           ; pointer to RST 20 return address
        ld      d,(hl)
        dec     hl
        ld      e,(hl)
        ex      de,hl                           ; HL points to call ID
        ld      a,h
        and     @11000000
        cp      @11000000
        jr      nz,nots3                        ; okay if not in segment 3
        res     7,h                             ; alter to segment 1 addressing
        dec     de
        ld      a,(de)                          ; A=original segment 3 binding
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind appropriate bank to seg 1
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                          ; BC=call ID
        jp      wass3
.nots3
        ld      c,(hl)
        inc     hl
        ld      a,h
        cp      $c0
        jr      nz,not48k2                      ; not now in s3
        dec     de
        ld      a,(de)                          ; A=original segment 3 binding
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind appropriate bank to seg 1
        ld      a,($4000)                       ; get the high call byte
        ld      b,a                             ; BC=call ID
        jp      wass3
.not48k2
        ld      b,(hl)                          ; BC=call ID
.wass3
        ld      a,c
        cp      code_os
        jr      z,subsos2                       ; move on for 2-byte OS call
        cp      code_gn
        jr      z,subsgn2                       ; move on for 2-byte GN call
        cp      code_dc
        jr      z,subsdc2                       ; move on for 2-byte DC call

; Here we have a 1-byte OS call to decode

        add     a,tbl_othbase-start_oth         ; A=offset of subs in page 2
        ld      e,a
        ld      d,0
        ld      hl,(subs_addr2)
        add     hl,de                           ; HL=address in page 2
        ld      a,(subs_bank2)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind page 2 to segment 1
        ld      a,(hl)
        and     a
        jp      z,nosubstitute                  ; move on if no call to do
        inc     hl
        ld      c,(hl)                          ; C=routine ID
        ld      b,a                             ; B=package ID
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind segment 1
        ex      af,af'                          ; restore original AF
        push    af                              ; and save it
        call    rst8inst+code_B_dest-code_B_src ; make the call
        jr      nc,done1b                       ; okay if no error
        push    af
        cp      rc_pnf
        jr      nz,done1bp                      ; or if not rc_pnf
        pop     af
        pop     af                              ; restore original AF
        exx                                     ; switch back to the alternate set
        ex      af,af'
        ret                                     ; exit to let OZ deal with call
.done1bp
        pop     af
.done1b
        inc     sp
        inc     sp                              ; discard original AF
        inc     sp
        inc     sp                              ; discard return into rst20
        ex      af,af'
        pop     af                              ; A'=seg 3 binding
        ex      (sp),hl
        inc     hl                              ; bypass call ID (1-byte)
        ex      (sp),hl
        jp      oz_endcall                      ; rebind, courtesy std OZ stuff

; At this point, no substitution is registered, so we exit to let OZ
; handle the call

.nosubstitute
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind segment 1
        ret                                     ; exit

; Here we have a 2-byte OS/GN/DC call to decode

.subsos2
        ld      a,b
        add     a,tbl_osbase-start_os
        jp      subs2byte
.subsgn2
        ld      a,b
        add     a,tbl_gnbase-start_gn
        jp      subs2byte
.subsdc2
        ld      a,b
        add     a,tbl_dcbase-start_dc
.subs2byte
        ld      e,a
        ld      d,0
        ld      hl,(subs_addr1)
        add     hl,de                           ; HL=address in page 1
        ld      a,(subs_bank1)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind page 1 to segment 1
        ld      a,(hl)
        and     a
        jp      z,nosubstitute                  ; move on if no call to do
        inc     hl
        ld      c,(hl)                          ; C=routine ID
        ld      b,a                             ; B=package ID
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind segment 1
        ex      af,af'                          ; restore original AF
        push    af                              ; and save it
        call    rst8inst+code_B_dest-code_B_src ; make the call
        jr      nc,done2b                       ; okay if no error
        push    af
        cp      rc_pnf
        jr      nz,done2bp                      ; or if not rc_pnf
        pop     af
        pop     af                              ; restore original AF
        exx                                     ; switch back to alternate set
        ex      af,af'
        ret                                     ; exit to let OZ deal with call
.done2bp
        pop     af
.done2b
        inc     sp
        inc     sp                              ; discard original AF
        inc     sp
        inc     sp                              ; discard return into rst20
        ex      af,af'
        pop     af                              ; A'=seg 3 binding
        ex      (sp),hl
        inc     hl
        inc     hl                              ; bypass call ID (2-byte)
        ex      (sp),hl
        jp      oz_endcall                      ; rebind, courtesy std OZ stuff


; pkg_rst20_tr
; This call is only made by the patched RST 20 code, as a direct call
; rather than a package call. It carries out tracing of CALL_OZ
; calls. We enter in the alternate set, hence
; the unusual register requirements. 
; IN:   -
; OUT:  -
; Registers changed after return:
;   ........afbcdehl/IXIY same
;   AFBCDEHL......../.... different

.call_rst20_tr
        call    dotrace
        ret


; This is the actual subroutine that does all the work

.dotrace
        ld      a,(oz_nestlevel)
        dec     a
        ret     nz                              ; only trace top-level calls
        ld      a,(pkg_features)
        bit     3,a
        jr      z,traceeverything               ; move on if not tracing single
        ld      a,(s1_copy)
        push    af
        ld      a,(process_ptr+2)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind bank of process block
        ld      hl,(process_ptr)
        res     7,h
        set     6,h                             ; set to segment 1 addressing
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      l,(hl)                          ; L=current process ID
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind bank to segment 1
        ld      a,(pkg_features+1)
        cp      l
        ret     nz                              ; don't trace if wrong process
.traceeverything
        push    iy                              ; form trace frame IY>AF
        push    ix
        exx
        push    hl
        push    de
        push    bc
        ex      af,af'
        push    af
        ld      hl,17
        add     hl,sp
        ld      a,(hl)
        inc     hl
        ex      af,af'                          ; A'=original seg 3 binding
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                          ; DE=PC+1
        dec     de
        push    de                              ; add PC to trace frame
        inc     de
        ex      de,hl                           ; HL points to call ID
        ld      a,h
        and     @11000000
        cp      @11000000
        jr      nz,nots3a                       ; okay if not in segment 3
        res     7,h                             ; alter to segment 1 addressing
        ld      a,(s1_copy)
        push    af
        ex      af,af'                          ; A'=original segment 3 binding
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind appropriate bank to seg 1
        ex      af,af'
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                          ; DE=call ID
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind segment 1
        jr      addcallID
.nots3a
        ld      e,(hl)
        inc     hl
        ld      a,h
        cp      $c0
        jr      nz,not49152                     ; not now is s3
        ld      a,(s1_copy)
        push    af
        ex      af,af'                          ; A'=original segment 3 binding
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind appropriate bank to seg 1
        ex      af,af'
        ld      a,($4000)                       ; get the high call byte
        ld      d,a
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a
        jr      addcallID
.not49152
        ld      d,(hl)                          ; DE=call ID (only if not in S3)
.addcallID
        push    de                              ; add callID to frame
        ld      hl,0
        add     hl,sp                           ; HL=start of trace frame
        ld      de,0                            ; move from memory
        ld      bc,16                           ; frame size
        ld      ix,(pkg_features+2)
        call_oz(os_mv)                          ; move the data (don't care if error)
        pop     hl                              ; discard callID
        pop     hl                              ; discard PC
        pop     af
        ex      af,af'                          ; restore af
        pop     bc
        pop     de
        pop     hl
        exx                                     ; restore bcdehl
        pop     ix
        pop     iy                              ; restore IXIY
        ret


; pkg_rst20_oztr
; Finally, this call does both call tracing and substitution, by the
; simple expedient of calling both the others.
; IN:   -
; OUT:  -
; Registers changed after return:
;   ........afbcdehl/IXIY same
;   AFBCDEHL......../.... different

.call_rst20_oztr
        call    dotrace                         ; do call tracing
        jp      call_rst20_oz                   ; call substitution & exit


; Subroutine to decode an OZ call ID
; IN:   DE=OZ call ID
; OUT(success):
;       Fc=0
;       DE=address into data area page, bound to segment 1
; OUT(failure):
;       Fc=1
; Registers changed after return:
;   ..BC..HL/IXIY same
;   AF..DE../.... different

.decodeOZ
        ld      a,e                             ; check for $xx06/$xx09/$xx0c
        cp      code_os                         ; variants
        jr      z,decodeos
        cp      code_gn
        jr      z,decodegn
        cp      code_dc
        jr      z,decodedc
        sub     start_oth                       ; decoding a single-byte call
        ret     c
        cp      end_oth-start_oth+1
        ccf
        ret     c
        add     a,tbl_othbase
        ld      e,a
        ld      d,0                             ; DE=offset
        push    hl
        ld      hl,(subs_addr2)
        add     hl,de
        ex      de,hl                           ; DE=address in page 2
        pop     hl
        ld      a,(subs_bank2)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind to segment 1
        and     a                               ; success
        ret
.decodeos
        ld      a,d
        sub     start_os
        ret     c
        cp      end_os-start_os+1
        ccf
        ret     c
        add     a,tbl_osbase
.dec2byte
        ld      e,a
        ld      d,0
        push    hl
        ld      hl,(subs_addr1)
        add     hl,de
        ex      de,hl                           ; DE=address in page 1
        pop     hl
        ld      a,(subs_bank1)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind to segment 1
        and     a                               ; success
        ret
.decodegn
        ld      a,d
        sub     start_gn
        ret     c
        cp      end_gn-start_gn+1
        ccf
        ret     c
        add     a,tbl_gnbase
        jr      dec2byte
.decodedc
        ld      a,d
        sub     start_dc
        ret     c
        cp      end_dc-start_dc+1
        ccf
        ret     c
        add     a,tbl_dcbase
        jr      dec2byte


; pkg_ozcr
; Register an OZ call substitution
; IN:   BC=package call ID to use
;       DE=OZ call ID to be substituted
; OUT(success):
;       Fc=0
; OUT(failure):
;       Fc=1
;       A=rc_pnf, call substitution table not available
;       A=rc_room, substitution already in place for this call  
;       A=rc_bad, invalid OZ call ID
; Registers changed after return:
;   ..BC..HL/IXIY same
;   AF..DE../.... different

.call_ozcr
        ld      a,(s1_copy)
        ex      af,af'                          ; save seg 1 binding
        call    checkmemory
        ld      a,rc_pnf
        scf
        jr      z,end_ozcr                      ; exit if no substitution table
        call    decodeOZ
        ld      a,rc_bad
        jr      c,end_ozcr                      ; or invalid OZ call ID
        ld      a,(de)
        and     a
        ld      a,rc_room
        scf
        jr      nz,end_ozcr                     ; or call already substituted
        call    oz_di                           ; disable interrupts while registering!
        push    af
        ex      de,hl
        ld      (hl),c                          ; register package call
        inc     hl
        ld      (hl),b
        ex      de,hl
        pop     af
        call    oz_ei
        and     a                               ; Fc=0, success
.end_ozcr
        ex      af,af'
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind segment 1
        ex      af,af'
        ret


; pkg_ozcd
; Deregister an OZ call substitution
; NB: We only actually check that the correct package is doing the
;     deregistering; don't actually check the routine!
; IN:   BC=package call ID used
;       DE=OZ call ID that was substituted
; OUT(success):
;       Fc=0
; OUT(failure):
;       Fc=1
;       A=rc_pnf, call substitution table not available 
;       A=rc_bad, invalid OZ call ID, or not previously substituted
; Registers changed after return:
;   ..BC..HL/IXIY same
;   AF..DE../.... different

.call_ozcd
        ld      a,(s1_copy)
        ex      af,af'                          ; save seg1 binding
        call    checkmemory
        ld      a,rc_pnf
        scf
        jr      z,end_ozcd                      ; exit if no substitution table
        call    decodeOZ
        ld      a,rc_bad
        jr      c,end_ozcd                      ; or invalid OZ call ID
        ld      a,(de)
        cp      c
        ld      a,rc_bad
        scf
        jr      nz,end_ozcd                     ; or wrong package call ID
        call    oz_di                           ; disable ints while deregistering!
        push    af
        xor     a
        ld      (de),a
        inc     de
        ld      (de),a                          ; reset call substitution
        pop     af
        call    oz_ei
        and     a                               ; Fc=0, success
.end_ozcd
        ex      af,af'
        ld      (s1_copy),a
        out     (s1_port),a
        ex      af,af'
        ret


; pkg_intm1
; This call is only made by the patched RST 38 code, and runs all
; appropriate handlers in the chain, before returning.
; It is now run as a direct call rather than a package call (for speed)
; and entered with seg3 binding at SP+13, and all registers saved except
; B'C'D'E'H'L'IY, which *must* be preserved here.
; IN:   -
; OUT:  Fc=0, always
; Registers changed after return:
;   ..BCDEHL/..IY same
;   AF....../IX.. different

.call_intm1
        ld      hl,sta_copy
        in      a,(sta_port)
        and     (hl)
        rra
        bit     3,a
        ld      a,@00001000                     ; for UART, just set bit 3
        jr      nz,uartint
        ret     nc                              ; no TIME interrupt active
        bit     1,(hl)
        ret     z                               ; RTC interrupts disabled
        ld      l,mask_copy&$ff
        in      a,(tim_port)
        and     (hl)                            ; A=time interrupts (bit 0->2)
.uartint
        and     @00001111
        ld      c,a                             ; C=current interrupts (b0->b3)
        ld      hl,im1table
        ld      a,(numints)
        ld      b,a                             ; B=#package interrupts registered
        inc     b
.pkgintloop
        dec     b
        jr      z,doproints                     ; move on if none left
; Now process a package interrupt
        ld      a,(hl)
        and     c
        jr      z,skippkg                       ; skip if didn't occur
        inc     hl
        inc     hl
        ld      d,(hl)                          ; D=initial counter
        inc     hl
        dec     (hl)                            ; decrement counter
        jr      nz,skippkg2                     ; skip if not enough times
        ld      (hl),d                          ; reset counter
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                          ; DE=package ID
        inc     hl
        push    bc                              ; save our registers
        push    de
        push    hl
        ex      af,af'
        push    af                              ; save original seg 3 binding
        ld      b,e
        ld      c,d                             ; B=package ID, C=routine ID
        call    rst8inst+code_B_dest-code_B_src
        exx
        pop     af
        ex      af,af'                          ; restore original seg 3 binding
        pop     hl
        pop     de
        pop     bc
        jp      pkgintloop
.skippkg
        inc     hl                              ; skip to next entry
        inc     hl
        inc     hl
.skippkg2
        inc     hl      
        inc     hl
        inc     hl
        jp      pkgintloop                      ; back for more
; Now we need to do the single process interrupt, if there is one
.doproints
        ld      a,(numints+1)
        and     a
        ret     z                               ; exit if no process ints
        ld      b,a                             ; B=# process ints registered
        inc     b
        ld      a,(oz_nestlevel)                ; level should be zero
        and     a
        ret     nz                              ; if not, exit this
        ld      a,(s1_copy)
        ld      d,a                             ; D=segment 1 binding
        ld      a,(process_ptr+2)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind bank of process block
        push    hl
        ld      hl,(process_ptr)
        res     7,h
        set     6,h                             ; set to segment 1 addressing
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      e,(hl)                          ; E=current process ID
        pop     hl
        ld      a,d
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind bank to segment 1
.prointloop
        dec     b
        ret     z                               ; exit when checked all
; Now process a process interrupt (!)
        ld      a,(hl)
        and     c
        jr      z,skippro                       ; skip if didn't occur
        inc     hl
        ld      a,(hl)
        cp      e
        jr      nz,skippro1                     ; or if wrong process ID
        inc     hl
        ld      d,(hl)                          ; D=initial counter
        inc     hl
        dec     (hl)                            ; decrement counter
        ret     nz                              ; exit if not enough times
        ld      (hl),d                          ; reset counter
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                          ; DE=routine address
        ex      af,af'                          ; A=required seg 3 binding
        ld      hl,exback+code_B_dest-code_B_src
        push    hl                              ; return to EXX;RET
        push    de                              ; stack routine address
        exx
        jp      callun+code_B_dest-code_B_src   ; call & exit
; Here we skip the current table entry
.skippro
        inc     hl
.skippro1
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        jp      prointloop


; pkg_intr
; IN:   A=reason code;
;               int_prc, register single process interrupt routine
;               int_pkg, register global package interrupt routine
;       C=type of interrupts to accept (set bits required);
;               0: TICK (1/100s)
;               1: SEC (1s)
;               2: MIN (1m)
;               3: UART
;       B=# of acceptable interrupts required before running handler
;       (eg set C=@00000001 & B=5 to run every 5 TICKs)
;       HL=routine address (A=int_prc) or package call ID (A=int_pkg)
; OUT(success): Fc=0
; OUT(failed):  Fc=1, A=rc_room, no room to install handler
;                     A=rc_unk, unknown reason code
;               NB: The package could also return rc_pnf, of course
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.call_intr
        ld      d,a
        call    oz_di                           ; don't interrupt us!
        push    af
        ld      a,d
        push    bc
        call    checkhandler                    ; see if installed
        jr      nc,noterror
.insterror
        pop     bc
        ld      d,a
        pop     af
        call    oz_ei                           ; re-enable interrupts
        ld      a,d
        scf
        ret
.noterror
        jr      z,gothandler
; At this point we need to install a new handler, so check if space
        ld      a,(numints)
        ld      e,a                             ; E=# installed package interrupts
        ld      a,(numints+1)
        add     a,e                             ; A=total interrupts
        cp      maxhandlers
        jr      c,canaddone
        ld      a,rc_room
        scf
        jr      insterror                       ; exit if already max handlers
.canaddone
        ex      af,af'                          ; A=reason, A'=total interrupts
        cp      int_prc
        jr      z,addatend                      ; add process handlers at list end
        push    bc
        push    hl
        ld      hl,im1table+((maxhandlers-1)*6)-1
        ld      de,im1table+(maxhandlers*6)-1
        ld      bc,6*(maxhandlers-1)
        lddr                                    ; insert space at list start
        pop     hl
        pop     bc
        ld      de,im1table                     ; space to insert
        ld      a,(numints)
        inc     a
        ld      (numints),a                     ; increment # pkg handlers
        jr      gothandler
.addatend
        ex      af,af'
        add     a,a
        ld      e,a
        add     a,a
        add     a,e
        ld      e,a
        ld      d,0
        push    hl
        ld      hl,im1table
        add     hl,de
        ex      de,hl                           ; DE=space to append
        pop     hl
        ld      a,(numints+1)
        inc     a
        ld      (numints+1),a                   ; increment # prc handlers
; At this point, DE points to our 6-byte space
.gothandler
        ex      de,hl                           ; HL=address, DE=handler
        ld      a,c                             ; A=process number
        pop     bc                              ; B=timer, C=interrupts
        ld      (hl),c                          ; install the handler
        inc     hl
        ld      (hl),a
        inc     hl
        ld      (hl),b
        inc     hl
        ld      (hl),b
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d
        pop     af
        call    oz_ei
        and     a                               ; success
        ret


; pkg_intd
; IN:   A=reason code;
;               int_prc, deregister single process interrupt routine
;               int_pkg, deregister global package interrupt routine
;       HL=package call that was previously registered (if A=int_pkg)
; OUT(success): Fc=0
; OUT(failed):  Fc=1, A=rc_hand, no installed handler found
;                     A=rc_unk, unknown reason code
;               NB: The package could also return rc_pnf, of course
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.call_intd
        call    checkhandler                    ; see if installed
        ret     c                               ; exit if error
        ld      a,rc_hand
        scf
        ret     nz                              ; or if not found
        ex      af,af'
        ld      b,a                             ; B=reason code
        call    oz_di                           ; don't interrupt us!
        push    af
        push    bc                              ; save reason code
        ld      hl,im1table+(maxhandlers*6)
        and     a
        sbc     hl,de
        ld      b,h
        ld      c,l                             ; BC=bytes to move down
        ld      hl,6
        add     hl,de                           ; HL=entry above one being deleted
        ldir                                    ; move entries down
        ld      hl,im1table+((maxhandlers-1)*6)
        ld      de,im1table+((maxhandlers-1)*6)+1
        ld      bc,5
        ld      (hl),0
        ldir                                    ; clear final entry
        pop     bc
        ld      a,b
        cp      int_prc
        jr      z,remprocess                    ; move on if removing process
        ld      a,(numints)
        dec     a
        ld      (numints),a                     ; decrement pkg counter
        jr      endintd
.remprocess
        ld      a,(numints+1)
        dec     a
        ld      (numints+1),a                   ; decrement prc counter
.endintd
        pop     af
        call    oz_ei
        and     a                               ; success
        ret


; Subroutine to check if handler mentioned is currently installed,
; returning DE=address if so
; IN:   A=reason code
;       HL=package call ID (if A=int_pkg)
; OUT:  Fz=1 & Fc=0 if found
;       Fz=0 & Fc=0 if not
;       Fc=1 & A=error if failed
;       DE=address of table entry if found
;       C=current process (if A=int_prc)
;       A'=reason code
; Registers changed after return:
;   ......HL/IXIY same
;   AFBCDE../.... different

.checkhandler
        cp      int_prc+1
        jr      c,okreason
        ld      a,rc_unk
        scf
        ret                                     ; exit with bad reason code
.okreason
        push    ix
        ld      ix,im1table
        cp      int_prc
        jr      z,checkprchandler               ; move on to check for prc handler
; Here we're checking for a package handler
        ex      af,af'                          ; save A'=reason code
        ld      a,(numints)
        ld      e,a                             ; E=number to check
        inc     e
.chkpkg
        dec     e
        jr      z,nohndfound
        ld      a,(ix+4)
        cp      l
        jr      z,foundhandler                  ; found if package ID matches
.skppkg
        inc     ix
        inc     ix
        inc     ix
        inc     ix
        inc     ix
        inc     ix
        jr      chkpkg
; Here we're checking for a process handler
.checkprchandler
        ex      af,af'                          ; save A'=reason code
        ld      a,(s1_copy)
        ld      d,a                             ; D=segment 1 binding
        ld      a,(process_ptr+2)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind bank of process block
        push    hl
        ld      hl,(process_ptr)
        res     7,h
        set     6,h                             ; set to segment 1 addressing
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      c,(hl)                          ; C=current process ID
        pop     hl
        ld      a,d
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind bank to segment 1
        ld      a,(numints)
        add     a,a
        ld      e,a
        add     a,a
        add     a,e
        ld      e,a
        ld      d,0                             ; DE=6*#pkg handlers
        add     ix,de                           ; IX points to process handlers
        ld      a,(numints+1)
        ld      e,a                             ; E=number to check
        inc     e
.chkprc
        dec     e
        jr      z,nohndfound
        ld      a,(ix+1)
        cp      c
        jr      z,foundhandler                  ; move on if correct process
.skpprc
        inc     ix
        inc     ix
        inc     ix
        inc     ix
        inc     ix
        inc     ix
        jr      chkprc
; We failed to find the handler
.nohndfound
        pop     ix
        xor     a
        inc     a                               ; Fz=0, Fc=0 (not found)
        ret
; We found the handler at IX
.foundhandler
        ex      (sp),ix
        pop     de                              ; DE=table address
        xor     a                               ; Fz=1, Fc=0 (found)
        ret


; pkg_pid
; IN:   -
; OUT:  Fc=0
;       A=process ID currently running
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_pid
        push    de
        push    hl
        ld      a,(s1_copy)
        ld      d,a                             ; D=segment 1 binding
        ld      a,(process_ptr+2)
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind bank of process block
        ld      hl,(process_ptr)
        res     7,h
        set     6,h                             ; set to segment 1 addressing
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      e,(hl)                          ; E=current process ID
        ld      a,d
        ld      (s1_copy),a
        out     (s1_port),a                     ; rebind bank to segment 1
        ld      a,e                             ; A=current process ID
        pop     hl
        pop     de
        and     a                               ; Fc=0
        ret


; pkg_slow
; IN:   -
; OUT:  Fc=0
; Registers changed after return:
;   ..BCDEHL/..IY same
;   AF....../IX.. different

.call_slow
        exx
        ld      bc,(slowmo)
.slowit
        dec     bc
        ld      a,b
        or      c
        jr      nz,slowit
        exx
        and     a                               ; Fc=0
        ret


; pkg_bal
; IN:   A=reason code;
;               bnk_any, don't care which bank is allocated
;               bnk_even, even-numbered bank required (to bind to seg 0)
; OUT(success):
;       Fc=0
;       A=bank number
; OUT(failure):
;       Fc=1
;       A=rc_room, no free banks available
;       A=rc_unk, unknown reason code
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_bal
        cp      bnk_even+1
        jr      nc,badbnkreason
        push    iy                              ; save registers
        push    bc
        push    de
        push    hl
        ld      e,a                             ; E=reason code
        ld      a,(s2_copy)
        push    af                              ; save segment 2
        push    hl                              ; push 4 dummy bytes
        push    hl
        ld      iy,0
        add     iy,sp                           ; IY points to 4 bytes
        ld      (iy+3),0                        ; start with slot 0
.balloop1
        call    slottype
        bit     0,(iy+2)
        jr      z,nextslot                      ; can't use if not RAM
        ld      b,(iy+1)                        ; B=#banks to check
.balloop2
        ld      a,e
        cp      bnk_even                        ; do we only want even?
        jr      nz,allokay
        bit     0,b                             ; B=bank+1, so should be odd
        jr      z,skipbank
.allokay
        call    mymatadd
        push    hl
        call    checkbank
        pop     hl
        jr      z,gotbank                       ; on if found one
.skipbank
        djnz    balloop2                        ; back for rest of slot
.nextslot
        inc     (iy+3)
        ld      a,(iy+3)
        cp      4
        jr      c,balloop1                      ; back for other slots
        ld      a,rc_room                       ; can't find bank
        scf
        jr      endbal
.gotbank
        ld      de,$0001
        call    setbank                         ; set bank as allocated
        ld      a,(iy+3)
        and     a
        ld      a,0
        jr      nz,notslot0
        ld      a,$20                           ; offset of $20 for slot 0
.notslot0
        add     a,b
        dec     a                               ; A=bank number in slot
        or      (iy+0)                          ; abs bank; Fc=0, success!
.endbal
        pop     hl
        pop     hl                              ; discard 4 dummy bytes
        ex      af,af'
        pop     af
        ld      (s2_copy),a
        out     (s2_port),a                     ; rebind segment 2
        ex      af,af'
        pop     hl                              ; restore registers
        pop     de
        pop     bc
        pop     iy
        ret
.badbnkreason
        ld      a,rc_unk                        ; unknown reason code
        scf
        ret


; Subroutine to find the address of a bank (0-based)
; in the MAT. This returns the address *after* the bank.
; IN:   B=bank+1 (0-based)
; OUT:  HL=address in MAT (seg2-addressing)
; Registers changed after return
;   ..BCDE../IXIY same
;   AF....HL/.... different

.mymatadd
        ld      hl,$8100
        push    bc
        ld      c,0
        srl     b
        rr      c                               ; BC=128*(bank+1)
        add     hl,bc                           ; HL=add of bank+1
        pop     bc
        ret


; pkg_bfr
; IN:   A=bank previously allocated
; OUT(success):
;       Fc=0
; OUT(failure):
;       Fc=1
;       A=rc_bad, bad bank number
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.call_bfr
        push    iy                              ; save registers
        push    bc
        push    de
        push    hl
        ld      e,a                             ; E=bank to free
        ld      a,(s2_copy)
        push    af                              ; save segment 2
        push    hl                              ; push 4 dummy bytes
        push    hl
        ld      iy,0
        add     iy,sp                           ; IY points to 4 bytes
        ld      a,e
        rlca
        rlca
        and     3                               ; convert mask to slot #
        ld      (iy+3),a
        call    slottype                        ; check slot
        bit     0,(iy+2)
        jr      z,badfree                       ; can't free if not RAM
        ld      a,e
        and     @11000000
        jr      z,isslot0                       ; move on if slot 0
        ld      a,e
        and     @00111111                       ; else convert to 0-based
        jr      tryfree
.isslot0
        ld      a,e
        and     @00111111
        sub     $20                             ; for slot 0, subtract $20
.tryfree
        ld      b,a
        inc     b                               ; B=bank+1
        cp      (iy+1)
        jr      nc,badfree                      ; no good if bank>=#banks
        call    mymatadd
        push    hl
        call    checkbank
        pop     hl
        cp      1
        jr      nz,badfree                      ; only free if alloc=$0001
        ld      de,$0000
        call    setbank                         ; free the bank
        and     a                               ; Fc=0, success
        jr      endbfr
.badfree
        ld      a,rc_bad                        ; non-allocated bank
        scf
.endbfr
        pop     hl
        pop     hl                              ; discard 4 dummy bytes
        ex      af,af'
        pop     af
        ld      (s2_copy),a
        out     (s2_port),a                     ; rebind segment 2
        ex      af,af'
        pop     hl                              ; restore registers
        pop     de
        pop     bc
        pop     iy
        ret

; pkg_nq
; Call substitution for OS_NQ
; This is currently used only when BC=NQ_AIN and IX=2, and allows
; for multiple Diary instances
; IN:   BC=reason code - only NQ_AIN handled, and other parameters refer to this
;       IX=application handle
; OUT(success):
;       Fc=0
;       BHL=pointer to application name (null-terminated)
;       BDE=pointer to application DOR
;       A=application attribute byte
;       C=preferred key
; OUT(failure):
;       Fc=1
;       A=rc_hand, bad application handle
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.call_nq
        ld      a,b                             ; check for NQ_AIN
        cp      nq_ain/$100
        jr      nz,std_nq
        ld      a,c
        cp      nq_ain&$ff
        jr      nz,std_nq
        ld      a,ixh                           ; check for IX=2
        and     a
        jr      nz,std_nq
        ld      a,ixl
        cp      2
        jr      nz,std_nq
        push    bc
        ld      de,os_nq
        ld      bc,pkg_nq
        call_pkg(pkg_ozcd)                      ; temporarily deregister our substitution
        pop     bc
        call_oz(os_nq)                          ; carry out the call
        push    af
        push    bc
        push    de
        ld      de,os_nq
        ld      bc,pkg_nq
        call_pkg(pkg_ozcr)                      ; re-register the substitution
        pop     de
        pop     bc
        pop     af
        ret     c                               ; don't do anything if there was an error
        res     4,a                             ; clear AT_ONES bit
        ret
.std_nq
        ld      a,rc_pnf
        scf
        ret


