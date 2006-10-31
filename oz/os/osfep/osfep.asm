; **************************************************************************************************
; OS_FEP System Call (Flash Eprom functionality).
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; (C) Thierry Peycru (pek@users.sf.net), 1997-2006
; (C) Gunther Strube (gbs@users.sf.net), 1997-2006
;
; $Id$
; ***************************************************************************************************

        module OS_Fep

        xdef    OSFep
        xref    FlashEprCardId, FlashEprSectorErase

        include "flashepr.def"
        include "lowram.def"


; ***************************************************************************************************
;
; OS_Fep, Flash Eprom interface
; RST 20H, DEFB $C806
;
; On entry, OSFrame is established.
;
; Reason code in A
;    Arguments in BC, DE, HL, IX
;
.OSFep
        push    hl
        ld      hl, OSFepTable
        add     a, l
        ld      l, a
        jr      nc,exec_fep_reason
        inc     h                               ; adjust for page crossing.
.exec_fep_reason
        ex      (sp), hl                        ; restore hl and push address
        ret                                     ; goto reason

.OSFepTable
        jp      FlashEprCardId                  ; reason code $00 for FEP_CRDID
        jp      FlashEprSectorErase             ; reason code $03 for FEP_SECER