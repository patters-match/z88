     XLIB OZSlotPoll

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
; ***************************************************************************************************

        INCLUDE "director.def"

; ***************************************************************************************************
;
; Poll for presence of OZ executing in specified slot.
; OZ can only run in slot 0 or slot 1; C = 2 or C = 3 returns Fz =1 always.
;
; In:
;         C = slot number (0, 1, 2 or 3)
; Out:
;         Fc = 0
;         Fz = 0, OZ is running in slot C
;         Fz = 1, OZ is NOT running in slot C
;
; Registers changed on return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
; ---------------------------------------------------------------------------------------
; Design & programming by Gunther Strube, Aug 2006, Feb 2009
; ---------------------------------------------------------------------------------------
;
.OZSlotPoll
                    PUSH IX
                    PUSH BC
                    PUSH AF

                    LD   IX,0
                    OZ   OS_Poll                ; get handle for Index (the first application in the system)
                    PUSH IX
                    EX   (SP),HL
                    LD   A,L                    ; the low byte of the handle reveals the slot mask...
                    POP  HL                     ; restore original HL
                    AND  @11000000              ; keep only slot mask
                    RLCA
                    RLCA                        ; slot mask -> slot number
                    CP   C
                    JR   Z, oz_found            ; C == OZ slot, return Fz = 0
                    CP   A                      ; C != OZ slot, return Fz = 1
.exit_OZSlotPoll
                    POP  BC
                    LD   A,B                    ; restore original A
                    POP  BC
                    POP  IX
                    RET
.oz_found           INC  C                      ; Fc = 0, Fz = 0, OZ ROM is running in slot C
                    JR   exit_OZSlotPoll        ; (INC C for slot 0 ensures Fz = 0)