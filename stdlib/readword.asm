     XLIB Read_word

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
;    Read word at pointer in BHL,A. Return word in DE.
;
;    Register affected on return:
;         ..BC..HL/IXIY
;         AF..DE../.... af
;
; ----------------------------------------------------------------------
; Design & programming by Copyright (C) Gunther Strube 1995,2017
; ----------------------------------------------------------------------
;
.Read_word          PUSH HL
                    ADD  A,L
                    LD   L,A
                    JR   NC,rdw_bndbnk
                    INC  H
.rdw_bndbnk         LD   A,B
                    CALL Bind_bank_s1             ; page in bank temporarily
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                   ; read word at ext. address
                    CALL Bind_bank_s1             ; restore previous binding, Fc = 0
                    POP  HL
                    RET
