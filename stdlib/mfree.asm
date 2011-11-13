     XLIB mfree

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

     LIB Bind_bank_s1
     XREF pool_index, pool_handles           ; data structures in another module
     XREF allocated_mem

     DEFC POOL_OPEN = 0, POOL_CLOSED = $FF

     INCLUDE "memory.def"
     INCLUDE "error.def"


; ******************************************************************************
;
; Release memory back to pool. Note: The pool need not be bound into the corresponding segment
;
; IN    : BHL = extended pointer to previously allocated memory
; OUT   : Fc = 1, if pointer was incorrect, A = RC_TYPE
;         otherwise Fc = 0, BHL = NULL
;
; Register status on return:
; A..CDE../IXIY  same
; .FB...HL/....  different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ------------------------------------------------------------------------
;
.mfree              PUSH IY
                    PUSH IX
                    PUSH DE
                    PUSH AF
                    PUSH BC
                    PUSH HL                         ; preserve pointer
                    INC  B
                    DEC  B
                    JR   Z, handle_not_found        ; illegal pointer...

                    LD   IY,pool_handles            ; point at base of pool array
                    LD   C,0                        ; search index

.find_pool_handle   LD   A,(IY+3)                   ; get bank of pool entity
                    CP   B                          ; found pool entity bank from pointer?
                    JR   Z, found_pool_bank         ; Yes...
                    LD   A,(pool_index)             ; no, get index of last pool
                    CP   C
                    JR   Z, handle_not_found        ; last pool entity, and still no match...
                    INC  C
                    LD   DE,4
                    ADD  IY,DE                      ; check next pool entity for bank
                    JR   find_pool_handle

.handle_not_found   POP  HL
                    POP  BC
                    LD   A, RC_TYPE
                    SCF                             ; illegal pointer or no pool available
                    JR   exit_mfree

.found_pool_bank    LD   E,(IY+1)
                    LD   D,(IY+2)
                    LD   A,D
                    OR   E
                    JR   Z, handle_not_found        ; handle not available...

                    PUSH DE
                    POP  IX                         ; pool handle installed
                    POP  HL                         ; restore offset pointer in pool area
                    LD   A,B
                    CALL Bind_bank_s1               ; bind bank of offset into segment
                    DEC  HL
                    LD   C,(HL)                     ; get size of allocated area-2
                    DEC  HL
                    CALL Bind_bank_s1               ; restore prev. bank binding
                    LD   B,0
                    INC  BC                         ; now true pointer in AHL
                    INC  BC                         ; now true size of area
                    CALL Update_memcount            ; allocated_mem -= size
                    CALL_OZ(OS_MFR)                 ; release memory back to OZ
                    POP  BC                         ; original BC restored
                    JR   C, exit_mfree
                    XOR  A
                    LD   B,A
                    LD   H,A
                    LD   L,A                        ; NULL pointer
                    LD   (IY+0), POOL_OPEN          ; indicate pool has space to be allocated
.exit_mfree         POP  DE
                    LD   A,D                        ; original A restored
                    POP  DE
                    POP  IX
                    POP  IY
                    RET

.Update_memcount    PUSH HL
                    PUSH AF
                    CP   A
                    LD   HL,(allocated_mem)
                    SBC  HL,BC
                    LD   (allocated_mem),HL         ; low word of counter updated
                    JR   NC, exit_memcount
                    LD   HL,allocated_mem+2         ; overflow - update most significant byte of integer
                    DEC  (HL)
.exit_memcount      POP  AF
                    POP  HL
                    RET
