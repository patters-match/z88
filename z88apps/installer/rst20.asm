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

; Substitute for OZ's standard RST 20, CALL_OZ routine
; 18/1/00 GWL
; 2/3/00 Rewritten to call routines directly, rather than through
;        package calls
; 13/3/00 Hacked so we now increment the OZ call nestlevel


        module  rst20

include "packages.def"
include "pkg_int.def"

        xdef    code_RST20a_src,code_RST20b_src,code_RST20_end,rst20jumpon
        xdef    rst20pkgbank,rst20structcall,rst20calladd,rst20docall


; This code is copied to $04b8, then the original jump from $0020 is
; copied to the end, and a jump to $04b8 is substituted. The various
; values are patched according to what handler is being installed.

.code_RST20a_src
        ex      af,af'
        exx                                     ; use alternate set
        ld      hl,oz_nestlevel
        inc     (hl)                            ; increment the call nesting level
        ld      a,(s3_copy)
        push    af                              ; save seg 3 binding
.rst20pkgbank
        ld      a,0                             ; patched later to Packages bank
        ld      (s3_copy),a
        out     (s3_port),a
.rst20structcall
        ld      hl,(0)                          ; patched later
        jp      code_RST20b_dest                ; jump to second part


; The second part, at $01c3 where 18 bytes are available

.code_RST20b_src
.rst20calladd
        ld      bc,0                            ; patched later
        and     a
        sbc     hl,bc
.rst20docall
        call    z,0                             ; patched later
        pop     af
        ld      (s3_copy),a
        out     (s3_port),a
.rst20jumpon
        jp      0                               ; patched to orginal jp add+6

.code_RST20_end
