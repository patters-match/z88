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
; ***************************************************************************************************

XLIB fseek

INCLUDE "fileio.def"


; ***************************************************************************************************
;
; Set file pointer
;
;    IN:    IX = file handle
;           HL = local pointer to 32bit file position
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.fseek              LD   A, FA_PTR
                    CALL_OZ(Os_Fwm)
                    RET
