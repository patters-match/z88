     XLIB Release_pools

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

     LIB Get_pool_entity
     XREF pool_index, pool_handles          ; data structures in another module
     XREF allocated_mem                     ; (long) variable of allocated bytes

     INCLUDE "memory.def"

; ******************************************************************************
;
; Release all pools allocated by previous .malloc calls.
;
; Register status on return:
;    AFBCDEHL/IXIY  same
;    ......../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Release_pools      PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX

                    LD   B,0
                    LD   HL, pool_handles
.release_loop       LD   C,B
                    CALL Get_pool_entity            ; pointer to pool entity
                    LD   (HL),0
                    INC  HL                         ; ignore flag byte
                    LD   E,(HL)
                    LD   (HL),0
                    INC  HL
                    LD   D,(HL)                     ;
                    LD   (HL),0                     ; indicate released handle...
                    LD   A,D
                    OR   E
                    JR   Z, next_pool               ; pool is released, get next...
                    PUSH DE
                    POP  IX                         ; pool handle installed
                    CALL_OZ(OS_MCL)                 ; release pool back to OZ
.next_pool          LD   A,(pool_index)             ; get last pool index
                    CP   B
                    JR   Z, exit_release_pools      ; all pools released, return...
                    INC  B                          ; get next pool handle
                    JR   release_loop

.exit_release_pools XOR  A
                    LD   (pool_index),A             ; indicate null pool handles
                    LD   H,A
                    LD   L,A
                    LD   (allocated_mem),HL
                    LD   (allocated_mem+2),HL       ; allocated_mem = 0

                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET
