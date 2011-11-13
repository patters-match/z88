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

; Substitute for OZ's standard RST 38 im1 routine
; 18/1/00 GWL
; 6/2/00 Modified to remove self-modifying stuff
; 27/2/00 Big optimizations!
; 1/3/00 Added standard rst38 handler so we can stuff it back in when needed
; 7/3/00 Re-organised to include swapping stack to safe place if necessary

        module  rst38

include "packages.def"
include "pkg_int.def"

        xdef    code_IM1a_src,code_IM1_jp,code_IM1b_src
        xdef    code_IM1c_src,code_IM1_end
        xdef    code_IM1org,code_IM1org_end
        xdef    intm1call,code_IM1_bank

        xref    pkg_structure,call_intm1


; This part is the IM1 routine at $0038, and saves some
; registers as per the original code (but later), then moves on

.code_IM1a_src
        push    af
        ld      a,(s3_copy)
        push    af
        push    bc
        push    de
        push    hl
        push    ix
        ld      hl,0
.intm1call
        jp      code_IM1b_dest                  ; move to next part


; This part is at $01a5 and occupies 30 bytes

.code_IM1b_src
        ex      af,af'                          ; A'=original seg3
        push    af                              ; save entrant AF'
        add     hl,sp
        ld      a,h
        cp      $20                             ; check for safe stack
        jr      c,stackok
        ld      sp,(os_stack)                   ; else swap with OS stack
.stackok
        push    hl                              ; save old SP
.code_IM1_bank
        ld      a,0                             ; patched later to Packages bank
        ld      (s3_copy),a
        out     (s3_port),a                     ; bind in Packages
        ld      hl,(pkg_structure+3+(pkg_intm1/$100))
        ld      bc,call_intm1
        and     a
        jp      code_IM1c_dest

; This last part is at $04ed and occupies 16 bytes

.code_IM1c_src
        sbc     hl,bc
        call    z,call_intm1                    ; make call if available
        xor     a                               ; more of the original code
        ld      (s3_copy),a
        out     (s3_port),a
        in      a,(sta_port)
.code_IM1_jp
        jp      0                               ; patched later

.code_IM1_end


; Here's the original code, that we shove back in place when interrupt
; chain handling is disabled

.code_IM1org
        push    af
        ld      a,(s3_copy)
        push    af
        xor     a
        ld      (s3_copy),a
        out     (s3_port),a
        in      a,(sta_port)
        jp      0                               ; patched later

.code_IM1org_end

