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

; Memory-handling code for the "Packages" package
; This is currently used to hold OZ call-substitution information
; 13/2/00 GWL
; 15/2/00 Altered to insist on non-swappable memory...
; 7/3/00 Rewrote for optimised rst20 stuff


        module  pkgmemory

include "memory.def"
include "error.def"
include "interrpt.def"
include "packages.def"
include "pkg_int.def"

        xdef    checkmemory,grabpages


; Subroutine to check call-substitution memory is available
; IN:   -
; OUT:  Fz=1 if memory NOT available
;       Fz=0 if memory available
;       Fc=0 always
; Registered changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.checkmemory
        push    hl
        ld      hl,(subs_addr1)
        ld      a,(subs_bank1)
        or      h
        or      l                               ; Fz=1 if datablock not allocated
        pop     hl
        ret


; Subroutine to grab the 2 pages we need for the "Packages" package
; We'll never need to give these back to the system, as this package
; can't be uninstalled, but we'll go through the motions anyway ;)
; IN:   -
; OUT(success): Fc=0
; OUT(failure): Fc=1
;               A=rc_room
; Registers changed after return:
;   ..BCDEHL/IXIY same
;   AF....../.... different

.grabpages
        call    checkmemory
        ret     nz                              ; if pointer installed, exit with Fc=0
        ld      a,(s1_copy)
        push    af
        push    ix
        push    hl
        push    de
        push    bc
        ld      a,mm_s1+mm_fix
        ld      bc,0
        call_oz(os_mop)                         ; open a pool
        jp      c,cantdoit
        ld      bc,256
        xor     a
        call_oz(os_mal)                         ; get 1st page
        jp      c,cantdo1
        push    ix                              ; save pool, address and bank
        push    hl
        push    bc
        ld      bc,256
        xor     a
        call_oz(os_mal)                         ; get 2nd page
        ld      ix,0                            ; didn't need a 2nd pool
        jr      nc,gotboth                      ; on if got a 2nd one okay
        ld      a,mm_s1+mm_fix
        ld      bc,0
        call_oz(os_mop)                         ; open a 2nd pool
        jr      c,cantdo2
        ld      bc,256
        xor     a
        call_oz(os_mal)                         ; get 2nd page from 2nd pool
        jr      c,cantdo3
.gotboth
        ld      (subs_addr2),hl                 ; store pointer to 2nd page
        ld      a,b
        ld      (subs_bank2),a
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind 2nd page
        ld      d,h
        ld      e,l
        inc     de
        ld      bc,255
        ld      (hl),0
        ldir                                    ; clear 2nd page to nulls
        pop     af                              ; A=page 1 bank
        pop     hl                              ; HL=page 1 address
        push    af
        push    hl
        ld      (s1_copy),a
        out     (s1_port),a                     ; bind 1st page
        ld      d,h
        ld      e,l
        inc     de
        ld      bc,255
        ld      (hl),0
        ldir                                    ; clear 1st page to nulls
        ex      (sp),ix                         ; IX=page 1 address
        pop     hl                              ; HL=handle for pool 2
        pop     bc                              ; B=bank 1
        pop     de                              ; DE=handle for pool 1
        ld      (ix+db_pkgid),pkg_pkgid         ; set up initial data area
        ld      (ix+db_verid),dataver
        ld      (ix+db_pools),e
        ld      (ix+db_pools+1),d
        ld      (ix+db_pools+2),l
        ld      (ix+db_pools+3),h
        call    oz_di                           ; no interrupts while setting ptr!
        push    af
        ld      (subs_addr1),ix                 ; set pointer to data area
        ld      a,b
        ld      (subs_bank1),a
        pop     af
        call    oz_ei
        and     a                               ; Fc=0, success!
        jr      grabbedit
.cantdo3
        call_oz(os_mcl)                         ; close the 2nd pool we opened
.cantdo2
        pop     bc
        pop     hl
        pop     ix                              ; restore 1st pool handle
.cantdo1
        call_oz(os_mcl)                         ; close the pool we opened
.cantdoit
        ld      a,rc_room
        scf
.grabbedit
        pop     bc
        pop     de
        pop     hl
        pop     ix
        ex      af,af'
        pop     af
        ld      (s1_copy),a
        out     (s1_port),a                     ; restore seg1 binding
        ex      af,af'
        ret

