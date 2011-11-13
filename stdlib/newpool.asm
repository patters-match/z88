     XLIB Alloc_new_pool

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

     LIB Open_pool, Get_pool_entity

     DEFC POOL_OPEN = 0, POOL_CLOSED = $FF

     INCLUDE "memory.def"


; ******************************************************************************
;
;    INTERNAL MALLOC ROUTINE.
;
;    IN  : C = new pool index
;
; Register status on return:
; A.BCDEHL/IXIY  same
; .F....../....  different
;
; ---------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ---------------------------------------------------------------------
;
.Alloc_new_pool     PUSH IX
                    PUSH HL
                    PUSH BC
                    PUSH AF                         ; preserve
                    CALL open_pool                  ; open a pool for segment 1
                    JR   C,exit_alloc_pool          ; ups - no memory...
                    CALL Get_pool_entity            ; get pointer to pool index (in C)
                    LD   (HL), POOL_OPEN            ; indicate pool is open
                    INC  HL
                    PUSH IX
                    POP  BC
                    LD   (HL),C
                    INC  HL
                    LD   (HL),B                     ; pool handle saved
                    INC  HL
                    PUSH HL
                    LD   BC,2
                    XOR  A                          ; 2 bytes
                    CALL_OZ(OS_MAL)                 ; dummy allocation to get
                    POP  HL
                    LD   (HL),B                     ; bank number into pool entity
.exit_alloc_pool    POP  BC                         ;
                    LD   A,B                        ; A restored
                    POP  BC                         ; BC restored
                    POP  HL                         ; HL restored
                    POP  IX                         ; IX restored
                    RET
