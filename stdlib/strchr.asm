     XLIB StrChr

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************


; ******************************************************************************
;
; StrChr - find character in string.
;
;  IN:    A  = ASCII byte
;         HL = pointer to string, first byte defined as length byte.
; OUT:    Fz = 1: if byte was found in string.
;                 A = position of found character in string (0 = first).
;         Fz = 0, byte not found, A last position of string.
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.StrChr             PUSH BC
                    PUSH HL
                    LD   B,0
                    LD   C,(HL)              ; get length of string
                    INC  HL                  ; point at first character
                    CPIR                     ; search...
                    POP  HL
                    PUSH AF                  ; preserve search flags
                    INC  C
                    LD   A,(HL)
                    SUB  C                   ; A = position of found char.
                    LD   B,A
                    POP  AF                  ; restore search flags
                    LD   A,B                 ; position in A
                    POP  BC
                    RET
