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

; Installer/Bootstrap packages stuff
; 13/9/99 GWL
; 18/1/00 Modified to patch RST 20/RST 38 as well
; 5/2/00 Bugfix for RST 38 patching
; 13/2/00 Now grabs pages required by OZ call substitution
; 27/2/00 Modified for optimized RST 38 stuff
; 1/3/00 Modified for new rst 38 code changing method:
;          now INSTPCODE only installs rst 8 stuff, and SETFCODE is
;          used by PKG_FEAT to ensure correct code is installed for
;          the others. So, INSTALLER & BOOTSTRAP must always do a
;          PKG_FEAT call after running INSTPCODE.
; 2/3/00 New rst 20 call changing stuff added in as well
; 7/3/00 Modified for safe stack-swapping code in rst38


        module  instpkgs

include "packages.def"
include "interrpt.def"
include "pkg_int.def"

        xref    pkg_structure,call_intm1
        xref    call_rst20_oz,call_rst20_tr,call_rst20_oztr
        xref    code_A_src,code_B_src,code_B_end
        xref    code_RST20a_src,code_RST20b_src,code_RST20_end
        xref    rst20pkgbank,rst20structcall,rst20calladd,rst20docall
        xref    rst20jumpon,code_IM1_bank
        xref    code_IM1a_src,code_IM1_jp,code_IM1b_src
        xref    code_IM1c_src,code_IM1_end
        xref    code_IM1org,code_IM1org_end
        xref    intm1call,grabpages

        xdef    instpcode,setfcode


; Subroutine to install the package-handling code if necessary
; Run by Installer & Bootstrap to install rst 8 code only, after
; which they run pkg_feat to ensure other code is correct
; IN:   -
; OUT:  Fc=0, installed it
;       Fc=1, package handling already installed
;
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.instpcode
        call_pkg(pkg_ayt)                       ; is package handling installed?
        jr      c,doit                          ; not at all, so go to do it
        call_pkg(pkg_inf)                       ; if so check version
        jr      c,doit                          ; couldn't locate, so install anyway
        ld      hl,pversion
        sbc     hl,de                           ; is installed version higher than us?
        ret     c                               ; exit with Fc=1 if >us
.doit
        call    oz_di                           ; no interrupts now please!
        push    af
        ld      a,(s3_copy)
        ld      (pkg_base),a                    ; store pointer to Packages package
        ld      hl,pkg_structure
        ld      (pkg_base+1),hl
        ld      hl,code_A_src
        ld      de,code_A_dest
        ld      bc,code_B_src-code_A_src
        ldir                                    ; copy the first block of code
        ld      hl,code_B_src
        ld      de,code_B_dest
        ld      bc,code_B_end-code_B_src
        ldir                                    ; copy the second block of code
        call    grabpages                       ; allocate memory required
        pop     af
        call    oz_ei
        and     a                               ; success
        ret


; Subroutine to install the necessary code for rst 20 & rst 38
; Run by PKG_FEAT only
; IN:   -
; OUT:  -
;
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.setfcode
        call    oz_di
        push    af                              ; save interrupt status
        push    bc
        push    de
        push    hl

; First check the RST 20 handler required

        ld      a,(pkg_features)
        bit     1,a
        jr      nz,yessubs                      ; on if OZ call subs required
        bit     2,a
        jr      z,norst20                       ; on if no handler at all required

; Here, we want a handler for call tracing only
        ld      hl,pkg_structure+3+(pkg_rst20_tr/$100)
        ld      de,call_rst20_tr
        call    instrst20
        jr      checkrst38

; Here, OZ Call substitution is needed, possibly tracing as well
.yessubs
        bit     2,a
        jr      nz,bothplease                   ; on if want call tracing too

; So, here we just want OZ call substitution
        ld      hl,pkg_structure+3+(pkg_rst20_oz/$100)
        ld      de,call_rst20_oz
        call    instrst20
        jr      checkrst38

; And here we want OZ call substitution AND tracing
.bothplease
        ld      hl,pkg_structure+3+(pkg_rst20_oztr/$100)
        ld      de,call_rst20_oztr
        call    instrst20
        jr      checkrst38

; Finally, here we want the original plain vanilla handler
.norst20
        ld      hl,(rst20jp)                    ; find where code is jumping to
        ld      de,code_RST20a_dest
        and     a
        sbc     hl,de
        jr      nz,checkrst38                   ; if not to a new handler, we're fine
        ld      hl,(rst20jumpon+1+code_RST20b_dest-code_RST20b_src)
        ld      de,6
        and     a
        sbc     hl,de                           ; restore instructions we previously did
        ld      (rst20jp),hl                    ; patch original jump

; Now check the RST 38 handling
.checkrst38
        ld      a,(pkg_features)
        bit     0,a
        jr      z,stdrst38                      ; move on if we want standard handler

; At this point we want the new RST 38 handler
        ld      hl,(intm1call+1-code_IM1a_src+code_IM1a_dest)
        ld      de,code_IM1b_dest
        and     a
        sbc     hl,de
        jr      z,im1newok                      ; no change if new one installed
        ld      hl,(IM1_jumper)
        push    hl                              ; save JP address
        ld      hl,code_IM1a_src
        ld      de,code_IM1a_dest
        ld      bc,code_IM1b_src-code_IM1a_src
        ldir                                    ; copy RST 38 code (part A)
        ld      hl,code_IM1b_src
        ld      de,code_IM1b_dest
        ld      bc,code_IM1c_src-code_IM1b_src
        ldir                                    ; copy RST 38 code (part B)
        ld      hl,code_IM1c_src
        ld      de,code_IM1c_dest
        ld      bc,code_IM1_end-code_IM1c_src
        ldir                                    ; copy RST 38 code (part C)
        pop     hl
        ld      bc,22
        add     hl,bc                           ; skip code we do ourselves
        ld      (code_IM1c_dest+code_IM1_jp+1-code_IM1c_src),hl
                                                ; patch jump address in
.im1newok
        ld      a,(s3_copy)                     ; patch Packages bank in
        ld      (code_IM1_bank+1+code_IM1b_dest-code_IM1b_src),a
        jr      noim1p

; At this point we want the original RST 38 handler
.stdrst38
        ld      hl,(intm1call+1-code_IM1a_src+code_IM1a_dest)
        ld      de,code_IM1b_dest
        and     a
        sbc     hl,de
        jr      nz,noim1p                       ; no change if original one installed
        ld      hl,(code_IM1c_dest+code_IM1_jp+1-code_IM1c_src)
        ld      de,22
        and     a
        sbc     hl,de
        push    hl                              ; save JP address
        ld      hl,code_IM1org
        ld      de,code_IM1a_dest
        ld      bc,code_IM1org_end-code_IM1org
        ldir                                    ; copy RST 38 code (original)
        pop     hl
        ld      (IM1_jumper),hl                 ; patch jump address in

; Now tidy up and finish
.noim1p
        pop     hl
        pop     de
        pop     bc
        pop     af
        call    oz_di
        ret


; Subroutine to install code for a RST 20 handler 
; IN:   HL=address in package structure of call to use
;       DE=call to use
; OUT:  -
;
; Registers changed after return:
;   ......../IXIY same
;   AFBCDEHL/.... different

.instrst20
        push    hl
        push    de
        ld      hl,(rst20jp)                    ; find where code is jumping to
        ld      de,code_RST20a_dest
        and     a
        sbc     hl,de
        jr      z,rst20there                    ; don't copy if already there
        ld      hl,code_RST20a_src
        ld      de,code_RST20a_dest
        ld      bc,code_RST20b_src-code_RST20a_src
        ldir                                    ; copy in RST 20 skeleton (part A)
        ld      hl,code_RST20b_src
        ld      de,code_RST20b_dest
        ld      bc,code_RST20_end-code_RST20b_src
        ldir                                    ; and copy in part B
        ld      hl,(rst20jp)                    ; get original jump address
        ld      de,6
        add     hl,de                           ; skip the instructions we already do
        ld      (rst20jumpon+1+code_RST20b_dest-code_RST20b_src),hl
        ld      hl,code_RST20a_dest
        ld      (rst20jp),hl                    ; patch jump to our code
.rst20there
        pop     hl                              ; HL=call to use
        ld      (rst20calladd+1+code_RST20b_dest-code_RST20b_src),hl
        ld      (rst20docall+1+code_RST20b_dest-code_RST20b_src),hl
        pop     hl                              ; HL=address in package structure
        ld      (rst20structcall+1+code_RST20a_dest-code_RST20a_src),hl
        ld      a,(s3_copy)                     ; Packages bank
        ld      (rst20pkgbank+1+code_RST20a_dest-code_RST20a_src),a
        ret


