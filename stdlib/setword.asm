     XLIB Set_word

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


; ******************************************************************************
;
;    Set word in DE at pointer in BHL,A. Returns Fc = 0.
;
;    Register affected on return:
;         ..BCDEHL/IXIY
;         AF....../.... af
;
; ----------------------------------------------------------------------
; Design & programming by Copyright (C) Gunther Strube 1995,2017
; ----------------------------------------------------------------------
;
.Set_word           PUSH HL
                    ADD  A,L
                    LD   L,A
                    JR   NC,swd_bndbnk
                    INC  H
.swd_bndbnk         LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D
                    CALL Bind_bank_s1             ; restore prev. binding
                    POP  HL
                    RET
