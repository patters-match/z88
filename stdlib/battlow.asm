     XLIB CheckBattLow

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

     DEFC STA = $B1           ; Interrupt Status register
     DEFC BTL = 3             ; If set, Battery low pin is active


; ***********************************************************************
;
; Check Battery Low Status
;
; In:
;         None
;
; Out:
;         Fc = 1, Battery condition is low
;         Fc = 0, Battery condition is OK.
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
; -------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997
; -------------------------------------------------------------
;
.CheckBattLow       PUSH AF
                    IN   A,(STA)             ; Read Interrupt Status Register
                    BIT  BTL,A
                    JR   NZ, battlow
                    POP  AF
                    SCF
                    CCF                      ; Fc = 0, signal Batteries OK
                    RET
.battlow            POP  AF
                    SCF                      ; Fc = 1, signal batteries are low
                    RET
