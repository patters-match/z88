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
; (C) Thierry Peycru (pek@users.sf.net), 1997-2007
; (C) Gunther Strube (gbs@users.sf.net), 1997-2007
;
; $Id$
; ***************************************************************************************************

        module OS_Fep

        xdef    OSFep
        xdef    FEP_VppError, FEP_EraseError, FEP_WriteError
        xdef    AM29Fx_InitCmdMode

        xref    FlashEprCardId                  ; osfep/fepcrdid.asm
        xref    FlashEprCardData                ; osfep/fepcrddata.asm
        xref    FlashEprSectorErase             ; osfep/fepsecera.asm
        xref    FlashEprCardErase               ; osfep/fepcdera.asm
        xref    FlashEprFileFormat              ; osfep/fepflfmt.asm
        xref    FlashEprWriteByte               ; osfep/fepwrbyt.asm
        xref    FlashEprWriteBlock              ; osfep/fepwrblk.asm
        xref    FlashEprCopyFileEntry           ; osfep/fepfcopy.asm
        xref    PutOSFrame_BHL                  ; misc5.asm
        xref    PutOSFrame_BC                   ; misc5.asm
        xref    PutOSFrame_DE                   ; misc5.asm
        xref    PutOSFrame_HL                   ; misc5.asm

        include "error.def"
        include "lowram.def"
        include "sysvar.def"


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
        ret                                     ; execute subroutine defined by reason code

.OSFepTable
        jp      ozFlashEprCardId                ; reason code $00 for FEP_CDID
        jp      ozFlashEprCardData              ; reason code $03 for FEP_CDDT
        jp      FlashEprSectorErase             ; reason code $06 for FEP_SCER  (returns only error status in AF)
        jp      FlashEprCardErase               ; reason code $09 for FEP_CDER  (returns only error status in AF)
        jp      ozFlashEprFileFormat            ; reason code $0C for FEP_FFMT
        jp      FlashEprWriteByte               ; reason code $0F for FEP_WRBT  (returns only error status in AF)
        jp      ozFlashEprWriteBlock            ; reason code $12 for FEP_WRBL
        jp      FlashEprCopyFileEntry           ; reason code $15 for FEP_CPFL  (returns only error status in AF)



; ***************************************************************************************************
.ozFlashEprCardId                               ; IN: C = slot number (0, 1, 2 or 3)
        call    FlashEprCardId
        ret     c                               ; return error condition
        call    PutOSFrame_BHL                  ; return B = total of 16K banks on Flash Memory Chip
        ld      (iy+OSFrame_A),A                ; return H = Manufacturer Code, L = Device Code
        ret                                     ; return A = FE_28F or FE_29F, defining the Flash Memory chip generation


; ***************************************************************************************************
.ozFlashEprCardData                             ; IN: HL = (Flash Memory Chip Manufacturer & Device Code)
        call    FlashEprCardData
        ret     c                               ; return error condition
        call    PutOSFrame_BC                   ; return B = total of 16K banks on Flash Memory Chip
        call    PutOSFrame_DE                   ; return CDE = extended pointer to null-terminated string description of chip
        ld      (iy+OSFrame_A),A                ; return A = FE_28F or FE_29F, defining the Flash Memory chip generation
        ret


; ***************************************************************************************************
.ozFlashEprFileFormat                           ; IN: C = slot number (0, 1, 2 or 3) of Flash Memory Card
        call    FlashEprFileFormat
        ret     c                               ; return error condition
        call    PutOSFrame_BC                   ; return C = Number of 16K banks of File Eprom Area
        jp      PutOSFrame_HL                   ; return BHL = absolute pointer to "oz" header in card


; ***************************************************************************************************
.ozFlashEprWriteBlock
        call    FlashEprWriteBlock
        ret     c                               ; return error condition
        call    PutOSFrame_BC                   ; return C = FE_28F or FE_29F (depending on found card)
        jp      PutOSFrame_HL                   ; return BHL = updated to pointer after block


; ***************************************************************************************************
; Generic error return codes used by INTEL/AMD/STM low level flash routines.
;
.FEP_VppError
        ld      a, RC_VPL
        scf
        ret
.FEP_EraseError
        ld      a, RC_BER
        scf
        ret
.FEP_WriteError
        ld      a, RC_BWR
        scf
        ret
; ***************************************************************************************************


; ***************************************************************************************************
; Prepare AMD Command Mode sequense addresses.
;
; In:
;       HL points into bound bank of Flash Memory
; Out:
;       BC = $aa55
;       DE = address $x2AA  (derived from HL)
;       HL = address $x555  (derived from HL)
;
; Registers changed on return:
;    AF....../IXIY same
;    ..BCDEHL/.... different
;
.AM29Fx_InitCmdMode
        push    af
        ld      bc,$aa55                        ; B = Unlock cycle #1 code, C = Unlock cycle #2 code
        ld      a,h
        and     @11000000
        ld      d,a
        or      $05
        ld      h,a
        ld      l,c                             ; HL = address $x555
        set     1,d
        ld      e,b                             ; DE = address $x2AA
        pop     af
        ret
