     MODULE FlashEprPollSectorSize

; **************************************************************************************************
; OZ Flash Memory Management.
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
; $Id$
; ***************************************************************************************************

     XDEF FlashEprPollSectorSize

     INCLUDE "flashepr.def"


;***************************************************************************************************
; Return Fz = 1, if Flash chip sector size is 16K (otherwise it's a 64K sector architecture)
;
; This library routine is used as an internal shared support library by several other public
; Flash chip libraries.
;
; IN:
;       HL = Flash Memory ID
;            H = Manufacturer Code (FE_INTEL_MFCD, FE_AMD_MFCD, FE_STM_MFCD)
;            L = Device Code (refer to flashepr.def)
;
; OUT:
;       Fz = 1, Flash chip uses a 16K sector size
;       Fz = 0, Flash chip uses a 64K sector size
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
.FlashEprPollSectorSize
                    PUSH DE
                    LD   DE,FE_AM29F010B     ; AM29F010B Flash Memory?
                    CALL cmp_fid
                    JR   Z,exit_PollSectorSize
                    LD   DE,FE_ST29F010B     ; ST29F010B (STMicroelectronics) Flash Memory?
                    CALL cmp_fid
.exit_PollSectorSize
                    POP  DE
                    RET
.cmp_fid
                    CP   A                   ; Fc = 0...
                    PUSH HL
                    SBC  HL,DE
                    POP  HL
                    RET