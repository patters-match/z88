     XLIB GetVarPointer

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
;
;***************************************************************************************************

     LIB GetPointer, Read_pointer


; ********************************************************************************
;
; Get pointer in pointer variable.
;
;    IN: HL = local address of pointer to pointer variable.
;
;    OUT: BHL = pointer in pointer variable.
;         IF pointer to pointer variable is NULL (pointer variable has not yet
;         been created), then a NULL is returned in stead.
;
; Registers changed after return:
;
;    AF.CDE../IXIY  same
;    ..B...HL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.GetVarPointer      CALL GetPointer               ; get &ptr (pointer to pointer)
                    PUSH AF
                    XOR  A
                    CP   B                        ; if ( &ptr == NULL ) return NULL
                    JR   Z, exit_getvarptr
                    CALL Read_pointer             ; read pointer in pointer variable
.exit_getvarptr     POP  AF
                    RET
