; *************************************************************************************
; Installer/Bootstrap/Packages (c) Garry Lancaster 1998-2014
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

; A rst 8 package-calling-mechanism
; 19/5/99 GWL
; Modified 13/6/99 for DEFW xxyy operation, with 0000=pkg_ayt
; 18/9/99 Split into parts to fit within available memory areas
; 25/9/99 Modified to integrate with OZ and support error-handlers
; 23/1/00 Modified to be interruptable, and prevent errors on pkg_rst20
;         and pkg_intm1 calls
; 5/2/00 Bugfix; s/m code was occasionally being corrupted by interrupt
;        package calls!
; 13/2/00 Added rst $10 code, to call with package ID as parameter in IY
; 29/2/00 Optimizations from DJM & GWL, with following changes:
;          seg3 binding now not available to calls in A', but at SP+3
;          package structure headers now: defb pkgid,'P',hirout
;          rst20/rst38 no longer use it, so extra checks removed
; 10/6/14 Complete rewrite for compatibility with OZ4.5+, using only
;         the 8 byte rst8 & rst10 slots, plus the 5 bytes at the end
;         of each of the rst20 & rst30 slots.


        module  rstcode

include "packages.def"
include "pkg_int.def"

        xdef    code_rst8_src,code_rst10_src_end
        xdef    code_rst23_src,code_rst23_src_end
        xdef    code_rst33_src,code_rst33_src_end

        xdef    patch_pkgsentry,patch_pkgsbank


; The first part will be placed at $0008 (RST 8) and $0010 (RST 10),
; where 16 consecutive bytes are available.

.code_rst8_src
        push    hl                              ; -- orgHL
.patch_pkgsentry
        ld      hl,$0000                        ; routine entry to be patched here
        ex      (sp),hl                         ; orgHL -- entry
        push    bc                              ; entry -- entry,orgBC
        jr      next1

.code_rst10_src
IF code_rst10_src-code_rst8_src <> $0008
        ERROR "rst10 code entry is misaligned!"
ENDIF
        rst     8                               ; enter via RST 8 with $0011 on stack
.pkgexit
        ld      (bc),a                          ; save seg1 soft copy
        out     (c),a                           ; switch seg1 bank
        pop     af                              ; restore registers
        pop     bc
        ret                                     ; enter/exit package system
        defs    1                               ; free byte
.code_rst10_src_end


; This section is for alignment of code segments only, and will not be copied
; into the restart area.

.code_rst18_marker
IF code_rst18_marker-code_rst10_src <> $0008
        ERROR "rst18 code entry is misaligned!"
ENDIF
        defs    8                               ; space for RST 18 (not patched)
        defs    3                               ; space for 3 bytes at RST 20 (not patched)


; The second part will be placed at $0023 (after JP at RST 20),
; where 5 bytes are available.

.code_rst23_src
IF code_rst23_src-code_rst10_src <> $0013
        ERROR "rst23 code entry is misaligned!"
ENDIF
.next1  ld      bc,s1_copy                      ; BC=softcopy/port address for seg1
        jr      next2
.code_rst23_src_end


; This section is for alignment of code segments only, and will not be copied
; into the restart area.

.code_rst28_marker
IF code_rst28_marker-code_rst10_src <> $0018
        ERROR "rst28 code entry is misaligned!"
ENDIF
        defs    8                               ; space for RST 28 (not patched)
        defs    3                               ; space for 3 bytes at RST 30 (not patched)


; The third part will be placed at $0023 (after JP at RST 20),
; where 5 bytes are available.

.code_rst33_src
IF code_rst33_src-code_rst10_src <> $0023
        ERROR "rst33 code entry is misaligned!"
ENDIF
.next2  push    af                              ; entry,orgBC -- entry,orgBC,orgAF
.patch_pkgsbank
        ld      a,0                             ; package code bank patched here
        jr      pkgexit                         ; use pkgexit to enter packages code
.code_rst33_src_end
