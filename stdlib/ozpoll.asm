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

; ***************************************************************************************************
;
; Poll for presence of OZ executing in specified slot.
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

                    CALL ApplEprType              ; does OZ run in this slot?
                    JR   C, no_oz
                    CP   $80
                    JR   exit_OZSlotPoll          ; $80: Fz = 1 (app card), $81: Fz = 0 (Fc = 0), OZ found
.no_oz              CP   A                        ; no application card nor OZ...
.exit_OZSlotPoll
                    POP  BC
                    LD   A,B                      ; restore original A
                    POP  BC
                    RET
