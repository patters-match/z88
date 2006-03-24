     XLIB FlashEprPollSectorSize

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

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
