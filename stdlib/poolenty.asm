     XLIB Get_pool_entity

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

     XREF pool_handles                            ; data structure in another module


; ******************************************************************************
;
; INTERNAL MALLOC ROUTINE.
;
; IN : C = handle index
; OUT: HL = pointer to pool entity
;
; Register status on return:
; AFBCDE../IXIY  same
; ......HL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Get_pool_entity    PUSH AF
                    PUSH BC
                    LD   HL, pool_handles
                    SLA  C
                    SLA  C                          ; handle index * 4
                    LD   B,0
                    ADD  HL,BC                      ; HL points at pool entity
                    POP  BC
                    POP  AF
                    RET
