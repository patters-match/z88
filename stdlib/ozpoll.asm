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
; $Id$
;
; ***************************************************************************************************

        LIB ApplEprType
        XREF CheckRomId

; ***************************************************************************************************
;
; Poll for presence of OZ executing in specified slot (top of card should contain 'OZ' + $81 subtype).
; When slot 0 is polled for OZ ROM, also check bank 7; this might contain an original 128K ROM.
;
;
; In:
;         C = slot number (0, 1, 2 or 3)
; Out:
;         Fc = 0
;         Fz = 0, OZ found in slot C
;         Fz = 1, OZ is NOT running in slot C
;
; Registers changed on return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
; ---------------------------------------------------------------------------------------
; Design & programming by Gunther Strube, Aug 2006
; ---------------------------------------------------------------------------------------
;
.OZSlotPoll
                    PUSH BC
                    PUSH AF

                    PUSH BC
                    CALL ApplEprType              ; does OZ run in this slot?
                    POP  BC                       ; C is still slot number even if Fc = 1
                    JR   C, no_oz
                    CP   $80
                    JR   exit_OZSlotPoll          ; $80: Fz = 1 (app card), $81: Fz = 0 (Fc = 0), OZ found
.no_oz              LD   A,C
                    OR   A
                    JR   NZ, no_oz_in_slot13
                    PUSH HL                       ; slot 0: check also for 128K ROM image 'OZ' header in bank 7
                    LD   B,7
                    LD   HL,$3F00
                    CALL CheckRomId
                    POP  HL
                    JR   Z,oz_found
.no_oz_in_slot13    CP   A                        ; no application card nor OZ...
.exit_OZSlotPoll
                    POP  BC
                    LD   A,B                      ; restore original A
                    POP  BC
                    RET
.oz_found           OR   B                        ; Fc = 0, Fz = 0, old OZ ROM image (128K) was recognized in slot 0
                    JR   exit_OZSlotPoll