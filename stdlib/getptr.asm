     XLIB GetPointer

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


; ********************************************************************************
;
;    Get an extended pointer in local address space
;
;    IN: HL = local address of pointer.
;
;    OUT: BHL = pointer (HL=offset,B=bank).
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
.GetPointer         PUSH DE
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    INC  HL
                    LD   B,(HL)
                    INC  HL                       ; B = bank
                    EX   DE,HL                    ; HL = offset in bank
                    POP  DE                       ; BHL = pointer to pointer...
                    RET
