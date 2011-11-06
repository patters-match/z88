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


        module  rst8

include "packages.def"
include "pkg_int.def"

        xdef    code_A_src,code_B_src,code_B_end
        xdef    callun,pkgext,rst8inst,exback

; The first part will be placed at $0008 (RST 8) where 8 bytes are available

.code_A_src
        exx                                     ; use alternate set
        pop     hl                              ; get address of call number
        ld      b,(hl)                          ; B=package ID
        inc     hl
        ld      c,(hl)                          ; C=routine ID
        jp      code_B_dest                     ; jump to the second part

; Following directly from this is the RST $10 code, which accepts a
; package call ID in IY, rather than inline as with RST $8

        exx
        ld      b,iyl                           ; B=package ID
        ld      c,iyh                           ; C=routine ID
        jp      rst8inst+code_B_dest-code_B_src


; The second part will be placed at $0400 (port softcopies)
; where 96 bytes are available (95 used by this code)

.code_B_src
        inc     hl
        push    hl                              ; stack return address
.rst8inst                                       ; entry point for call-by-parameter
        ex      af,af'                          ; save original AF
        ld      a,c
        or      b
        jr      z,exit0000                      ; for pkg_ayt (exx/ex/exit)
        ld      hl,oz_nestlevel
        inc     (hl)                            ; inc call level (for error-handling)
        ld      a,#(pkg_base-$0f)%256
        add     a,b
        ld      l,a
        ld      h,#(pkg_base-$0f)/256
        ld      a,(s3_copy)
        push    af                              ; stack original seg3 binding
        ld      a,(hl)
        inc     hl
        ld      (s3_copy),a
        out     (s3_port),a                     ; bind in package
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl                           ; HL points to package (bound to segment 3)
        ld      a,(hl)
        inc     hl
        cp      b                               ; check package ID
        jr      nz,notpkg                       ; move on if invalid
        ld      a,(hl)
        inc     hl
        cp      'P'
        jr      nz,notpkg
        ld      a,(hl)
        inc     hl
        cp      c                               ; check routine ID
        jr      c,notpkg
        ld      b,0
        add     hl,bc                           ; HL points to routine address
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ld      hl,pkgext-code_B_src+code_B_dest
        ex      af,af'                          ; original AF
        push    hl                              ; stack return address back here
        push    de                              ; stack routine address
.exback
        exx
        ret
.pkgext
        ex      af,af'
        pop     af                              ; A=seg3
        jp      oz_endcall                      ; rebind s3, call errhandler if necessary, exit
.exit0000
        ex      af,af'                          ; original AF
        exx
        and     a                               ; Fc=0, success
        ret


; Code jumps here if package call seems to be invalid
; This is the magical bit where packages are automatically installed
; when their xx_ayt call is used

.notpkg
        ld      a,c
        cp      $02                             ; is this a xx_ayt call?
        jr      z,isayt                         ; go to register package if so
        exx
        ld      a,rc_pnf
        scf
        jr      pkgext
.isayt
        ld      a,b                             ; A=package ID
        exx
        call_pkg(pkg_reg)                       ; else attempt to register it
        jr      pkgext


; The following code is jumped to by the package-handling package
; when it wants to call a routine in an uninstalled package
; Also used by pkg_intm1 for calling processes

.callun
        ld      (s3_copy),a                     ; bind in bank containing package
        out     (s3_port),a
        ret                                     ; return to routine, then to pkgext

.code_B_end

