     XLIB Malloc

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

     XREF  pool_index                        ; (byte) current pool handle index
     XREF  allocated_mem                     ; (long) currently allocated memory in bytes
     XREF  MAX_POOLS                         ; (constant) max. number of allowed open pools

     LIB Bind_bank_s1, Get_pool_entity, Alloc_new_pool

     DEFC POOL_OPEN = 0, POOL_CLOSED = $FF

     INCLUDE "memory.def"


; **********************************************************************************
;
; Allocate free memory from Z88 operating system
;
; ATTENTION: This routine may not be called before a OZ memory is initialized
; by the .Init_malloc library routine.
;
;  IN: A   = number of bytes required (MAX 253 bytes)
; OUT: Fc  = 0, memory allocated
;      Fc  = 1, no memory left in Z88
;      Fz  = 0, new pool opened (new bank is bound into segment)
;      Fz  = 1, current bank binding still activate
;      BHL = extended pointer beginning of allocated memory request (Fc = 0)
;            otherwise Fc = 1 and BHL = NULL
;
; Register status on return:
; ...CDE../IXIY  same
; AFB...HL/....  different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ------------------------------------------------------------------------
;
.Malloc             PUSH IY                         ; preserve IY register
                    PUSH IX                         ; preserve IX register
                    PUSH DE                         ; preserve DE register
                    PUSH BC                         ; preserve C register
                    LD   B,0
                    LD   C,A
                    INC  BC                         ; 1 extra byte for pool handle index
                    INC  BC                         ; 1 extra bytes for size
                    LD   A,(pool_index)             ; initialise pool index loop counter
                    LD   E,A
.pool_loop          PUSH BC                         ; total number of bytes to allocate
                    LD   C,E                        ; preserve counter
                    CALL Get_pool_entity
                    PUSH HL
                    POP  IY
                    LD   A,(HL)                     ; get pool flag byte
                    CP   POOL_OPEN                  ; has pool available memory ?
                    JR   NZ, next_pool              ; no - try next pool, id any
                    INC  HL
                    LD   C,(HL)                     ; low byte of pool handle
                    INC  HL
                    LD   B,(HL)                     ; high byte of pool handle
                    PUSH BC
                    POP  IX                         ; pool handle installed
                    POP  BC                         ; number of bytes to allocate
                    PUSH BC                         ; preserve if call fails...
                    CALL_OZ(OS_MAL)                 ; try to allocate
                    JR   C, pool_exhausted          ; failed...
                    LD   A,($04D1)                  ; get current bank binding in segment 1
                    CP   B                          ; is pool already bound in segment
                    JR   Z, init_block              ; Yes, Fz = 1, Fc = 0 on exit of malloc
                    LD   A,B
                    CALL Bind_bank_s1               ; No, execute new binding...
                    OR   B                          ; Fz = 0, Fc = 0 - indicate new bank binding
.init_block         LD   (HL),E                     ; save pool index
                    INC  HL
                    POP  DE                         ; get size of allocated memory
                    CALL Update_memcount            ; allocated_mem += size
                    DEC  DE
                    DEC  DE                         ; requested size
                    LD   (HL),E                     ; save size of allocated block-2
                    INC  HL                         ; new start of allocated block
                    JR   exit_malloc

.Update_memcount    PUSH HL
                    PUSH AF
                    LD   HL,(allocated_mem)
                    ADD  HL,DE
                    LD   (allocated_mem),HL         ; low word of counter updated
                    JR   NC, exit_memcount
                    LD   HL, allocated_mem+2        ; overflow - update most significant byte of integer
                    INC  (HL)
.exit_memcount      POP  AF
                    POP  HL
                    RET

.pool_exhausted     LD   (IY+0), POOL_CLOSED        ; indicate current pool exhausted
.next_pool          XOR  A
                    CP   E
                    JR   Z, open_new_pool           ; first pool also used up - open a new...
                    DEC  E                          ; get another previous pool index
                    POP  BC                         ; restore length
                    JR   pool_loop                  ; and try to allocate in that pool

.open_new_pool      LD   A,(pool_index)
                    CP   MAX_POOLS                  ; reached max. number pools allowed?
                    JR   Z, pool_limit_reached
                    INC  A
                    LD   C,A
                    CALL Alloc_new_pool
                    POP  BC                         ; restore length
                    JR   C, exit_malloc             ; no more room in Z88, return...
                    LD   E,A
                    LD   (pool_index),A             ; update last pool index
                    JR   pool_loop                  ; allocate memory in new pool instead

.pool_limit_reached POP  AF                         ; get rid of BC (total bytes to allocate)
                    XOR  A
                    LD   B,A
                    LD   H,A
                    LD   L,A                        ; NULL pointer
                    SCF                             ; ups, no room for another pool entity

.exit_malloc        LD   A,B
                    POP  BC                         ; original C restored
                    LD   B,A
                    POP  DE                         ; original DE restored
                    POP  IX                         ; original IX restored
                    POP  IY                         ; original IY restored
                    RET
