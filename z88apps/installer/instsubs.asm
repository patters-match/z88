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
;
; *************************************************************************************

; Installer Subroutines - Usable by Installer & Bootstrap
; 15/2/00 Modified so routines work for slot 0 also
;         These routines now also used by bank allocation calls in Packages
; 12/3/00 Slot 0 usage now only allowed if OZ has properly set up the
;         RAM bank header; ie if FreeRAM reports 1Mb we don't allow usage
; 29/4/01 Added subroutine for enabling our call substitutions


        module  instsubs

        xdef    slottype,slotprot,getdor,bindbank,protbank,matadd
        xdef    checkbank,setbank,loopparms,protsafe,regsubs
        xdef    getozver

        xref    workparams

include "syspar.def"
include "packages.def"
include "fileio.def"


; Set up loop parameters for every bank in card
;       IN:     -
;       OUT:    B=(IY+4), number of banks
;               HL=IY+5, address of first bank
;
; Registers changed:
;       AF.CDE../IXIY same
;       ..B...HL/.... different

.loopparms
        ld      hl,workparams+4
        ld      b,(hl)
        inc     hl
        ret


; Get CDE=next DOR in chain (pointing to brother), at address BHL
;       IN:     BHL=place to find DOR pointer-3
;               (IY+5) to (IY+12)=banks to look for
;               (IY+4)=number of banks to look for
;               (IY+3)=slot
;       OUT:    CDE=address next application DOR
;               BHL=points to address of bank in original pointer
;               Fc=1 if null pointer, Fz=1 if bank is in list
; Registers changed:
;       ......../IXIY same
;       AFBCDEHL/.... different

.getdor
        ld      a,b
        call    bindbank                        ; bind next bank to DOR
        ld      a,h
        and     @00111111
        or      @01000000                       ; mask address to segment 1
        ld      h,a
        inc     hl                              ; get to brother pointer
        inc     hl
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      c,(hl)                          ; CDE=next DOR
        ld      a,c                             ; test for null pointer
        or      d
        or      e
        scf
        ret     z                               ; exit with Fc=1 if null pointer
        ld      a,c                             ; C=bank
        push    bc
        push    hl
        call    loopparms                       ; B=banks, HL=list
.cckit
        cp      (hl)
        jr      z,donecck                       ; exit with Fz=1 if bank in list
        inc     hl
        djnz    cckit                           ; check rest, ends with Fz=0
.donecck
        pop     hl                              ; restore registers
        pop     bc
        scf
        ccf                                     ; ensure Fc=0 without disturbing Fz
        ret


; Protect a slot
;       IN:     (IY+3)=slot 1..3
;               MAT bound to segment 2
;       OUT:    -
; Registers changed:
;       ......../IXIY same
;       AFBCDEHL/.... different

; No need to protect the top page of a ROM/RAM bank - OZ already does this

.slotprot
        ld      a,$3f                           ; top bank
.protresvd
        call    bindbank
        ld      a,($7ff6)
        and     a
        jr      z,protapps
        push    af
        call    protbank                        ; protect reserved bank
        pop     af
        jr      protresvd
.protapps
        ld      b,$3f
        ld      hl,$7fc3                        ; BHL points to first link-3
.protloop
        call    getdor                          ; get next DOR in CDE
        ret     c                               ; exit if at end of chain
        ld      a,c
        call    protbank                        ; protect next bank
        ld      a,c
        call    bindbank                        ; bind bank into segment 1
        ex      de,hl
        ld      b,c                             ; BHL=current DOR
        push    bc
        push    hl                              ; save it
        ld      a,h
        and     @00111111
        or      @01000000
        ld      h,a                             ; convert address to segment 1
        ld      bc,25
        add     hl,bc                           ; start of segment bindings
        ld      b,4
.protsegs
        ld      a,(hl)
        inc     hl
        and     a
        call    nz,protbank                     ; protect bank if non-zero
        djnz    protsegs
        ld      bc,4
        add     hl,bc                           ; start of MTH pointers
        ld      b,4
.protmth
        ld      a,(hl)
        inc     hl
        or      (hl)
        inc     hl
        or      (hl)
        ld      a,(hl)
        inc     hl
        call    nz,protbank                     ; protect MTH bank if pointer not null
        djnz    protmth
        pop     hl                              ; restore DOR address in BHL
        pop     bc
        jr      protloop


; Protect a safe page in top bank
;       IN:     -
;       OUT:    Fc=0, protected
;               Fc=1, couldn't protect
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.protsafe
        push    de
        push    hl
        push    bc
        ld      a,$3e                           ; A=second bank
        call    matadd                          ; get address of MAT for page we need
        ld      b,63                            ; check 63 pages (not top)
.safeloop
        ld      a,(hl)
        inc     hl
        and     @11111110
        or      (hl)                            ; Fz=0 if protectable
        jr      z,protthis
        inc     hl
        djnz    safeloop                        ; try more
        scf                                     ; failure
        jr      notsafe
.protthis
        ld      (hl),0
        dec     hl
        ld      (hl),1                          ; protect it
        and     a                               ; success
.notsafe
        pop     bc
        pop     hl
        pop     de
        ret


; Protect bank
;       IN:     A=bank
;       OUT:    -
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.protbank
        push    de
        push    hl
        push    bc
        call    matadd                          ; get address in MAT
        push    hl
        call    checkbank                       ; check not allocated
        pop     hl
        ld      de,$0001
        call    z,setbank                       ; allocate if so
        pop     bc
        pop     hl
        pop     de
        ret


; Bind bank A in slot to segment 1
;       IN:     A=bank ($3f downwards)
;               (IY+0)=slot mask
;       OUT:    Bank bound to segment 1
;               A=absolute bank
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.bindbank
        and     $3f
        or      (iy+0)                          ; A=absolute bank
        ld      ($04d1),a
        out     ($d1),a                         ; bind to segment 1
        ret


; Find address following bank in MAT
;       IN:     A=bank to locate (must be $3f downwards)
;               (IY+1)=#banks in RAM device
;       OUT:    HL=address of following allocation bytes in MAT
; Registers changed:
;       ..BCDE../IXIY same
;       AF....HL/.... different


.matadd
        ld      hl,$8100                        ; start of MAT (in segment 2)
        push    bc
        dec     (iy+1)
        and     (iy+1)
        inc     (iy+1)
        inc     a
        ld      b,a                             ; B=bank 1..n
        ld      c,0
        srl     b
        rr      c                               ; BC=128*bank
        add     hl,bc                           ; HL=address in MAT
        pop     bc
        ret


; Check allocation status of pages
;       IN:     HL=address in MAT *after* pages (bound to segment 2)
;       OUT:    Fz=1 if pages free
; Registers changed:
;       ..BCDE../IXIY same
;       AF....HL/.... different

.checkbank
        push    bc
        ld      b,16*4                          ; 4 pages for every 1K, 16K in bank
        xor     a                               ; null allocation
.chkpage
        dec     hl
        or      (hl)
        dec     hl
        or      (hl)
        djnz    chkpage
        pop     bc
        ret                                     ; exit with Fz=1 if none allocated


; Set allocation status of pages
;       IN:     HL=address in MAT *after* pages (bound to segment 2)
;               DE=value to allocate with
;       OUT:    HL=address of start of checked pages
; Registers changed:
;       AFBCDE../IXIY same
;       ......HL/.... different


.setbank
        push    bc      
        ld      b,16*4                          ; 4 pages for every 1K, 16K in bank
.doset
        dec     hl
        ld      (hl),d                          ; allocate a page
        dec     hl
        ld      (hl),e
        djnz    doset
        pop     bc
        ret


; Find type of device in slot
;       IN:     (IY+3)=slot number (0..3)
;       OUT:    (IY+2)=bit 0 set for RAM, bit 1 set for ROM
;               (IY+1)=# RAM banks if RAM device 
;               (IY+0)=slot mask
;               MAT bank bound to segment 2
; Registers changed:
;       ..BCDEHL/IXIY same
;       AF....../.... different

.slottype
        push    bc
        push    hl
        ld      (iy+2),0                        ; reset device type
        ld      (iy+1),0                        ; and RAM banks
        ld      a,(iy+3)                        ; get slot number
        rrca
        rrca                                    ; convert to slot mask
        and     @11000000
        ld      (iy+0),a                        ; save slot mask
        or      @00111111                       ; look at top bank
        ld      ($04d2),a
        out     ($d2),a                         ; bind to segment 2
        ld      hl,($bffe)                      ; check top two bytes
        ld      bc,$5a4f
        and     a
        sbc     hl,bc
        jr      nz,notrom
        set     1,(iy+2)                        ; set bit 1 of type for ROM devices
.notrom
        and     @11000000                       ; look at bottom bank
        jr      nz,notslot0
        ld      a,$21                           ; use $21 for slot 0
.notslot0
        ld      ($04d2),a
        out     ($d2),a                         ; bind to segment 2
        ld      hl,($8000)                      ; check for RAM header
        ld      bc,$a55a
        and     a
        sbc     hl,bc
        pop     hl
        pop     bc
        ret     nz                              ; exit if not RAM type
        set     0,(iy+2)                        ; set bit 0 of type for RAM devices
        ld      a,($8002)
        ld      (iy+1),a                        ; store number of RAM banks
        cp      $40
        ret     nz                              ; exit unless claimed to have 1Mb RAM...
        ld      a,(iy+3)
        and     a
        ret     nz                              ; ...in slot 0
        res     0,(iy+2)                        ; don't allow RAM to be taken from slot 0
        ld      (iy+1),a                        ; as OZ is not handling it properly
        ret

; Register call substitutions provided with Packages package
;       IN:     -
;       OUT:    -
; Registers changed:
;       ......HL/IXIY same
;       AFBCDE../.... different

.regsubs
        ld      de,os_nq
        ld      bc,pkg_nq
        call_pkg(pkg_ozcr)
        ret


; Obtain OZ version and check compatibility
;       IN:     -
;       OUT:    Fz=1, incompatible version 4.1 to 4.3
;               Fz=0, compatible version
;               Fc=1, OZ <= v4.0
;               Fc=0, OZ >= v4.4
;               A=version
; Registers changed:
;       ......HL/..IY same
;       AFBCDE../IX.. different

.getozver
        ld      ix,-1                           ; get system values
        ld      a,fa_ptr                        ; want handles & version
        ld      de,0                            ; results in DE & BC
        call_oz(os_frm)
        jr      nc,testozver
.badozver
        xor     a                               ; Fz=1, incompatible version if error
        ret
.testozver
        ld      a,c                             ; A=version number
        cp      $41
        ret     c                               ; exit with Fz=0, Fc=1 if OZ <= v4.0
        jr      badozver                        ; OZ v4.1+ all incompatible at the moment
;        cp      $44
;        ccf
;        ret     nc                              ; exit with Fz=0, Fc=0 if OZ v4.1-v4.3
;        cp      $43
;        ccf
;        ret                                     ; exit with Fz=0, Fc=1 for OZ >= v4.4

