; *************************************************************************************
;
; UnZip - File extraction utility for ZIP files, (c) Garry Lancaster, 1999-2006
; This file is part of UnZip.
;
; UnZip is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; UnZip is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with UnZip;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

; Alternate register saving routines

        module  altregs

include "error.def"
include "stdio.def"
include "fileio.def"
include "integer.def"
include "syspar.def"
include "saverst.def"
include "director.def"
include "dor.def"

        xdef    oz_gn_sop,oz_os_out,oz_gn_d24,oz_gn_pdn
        xdef    oz_os_frm,oz_os_fwm,oz_os_mv,oz_os_nq
        xdef    oz_gn_cl,oz_gn_nln,oz_gn_sip,oz_os_in
        xdef    oz_os_sr,oz_gn_opf,oz_gn_esp,oz_gn_soe
        xdef    oz_dc_nam,oz_os_esc,oz_gn_esa,oz_gn_pfs
        xdef    oz_os_dor

; GN_SOP

.oz_gn_sop
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_sop)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_MV

.oz_os_mv
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_mv)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_FRM

.oz_os_frm
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_frm)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_FWM

.oz_os_fwm
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_fwm)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_GN_D24

.oz_gn_d24
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_d24)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_OUT

.oz_os_out
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_out)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; GN_PDN

.oz_gn_pdn
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_pdn)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_NQ

.oz_os_nq
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_nq)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; GN_CL

.oz_gn_cl
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_cl)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_IN

.oz_os_in
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_in)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; GN_SIP

.oz_gn_sip
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_sip)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; GN_NLN

.oz_gn_nln
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_nln)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_SR

.oz_os_sr
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_sr)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret
; GN_OPF

.oz_gn_opf
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_opf)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; GN_ESP

.oz_gn_esp
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_esp)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; GN_SOE

.oz_gn_soe
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_soe)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; DC_NAM

.oz_dc_nam
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(dc_nam)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_ESC

.oz_os_esc
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_esc)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; GN_ESA

.oz_gn_esa
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_esa)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; OS_DOR

.oz_os_dor
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(os_dor)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; GN_PFS

.oz_gn_pfs
        exx
        push    bc
        push    de
        push    hl
        exx
        call_oz(gn_pfs)
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        ret
