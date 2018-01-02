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

XLIB fseek64k
LIB fseek

INCLUDE "fileio.def"

; ***************************************************************************************************
;
; Set file pointer within 64K (16bit) range
;
;    IN:    IX = file handle
;           HL = file pointer (16bit)
;
;   OUT:    Fc = 0 (success)
;           Fc = 1, A = RC_xxx (I/O error related)
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.fseek64k           PUSH HL
                    LD   HL,0
                    EX   (SP),HL
                    PUSH HL                       ; 16bit file on stack is XXXX0000
                    LD   HL,0
                    ADD  HL,SP                    ; HL points to XXXX0000 on system stack
                    CALL fseek                    ; reset file pointer to XXXX0000
                    POP  HL
                    INC  SP
                    INC  SP                       ; ignore $0000 on stack
                    RET
