     XLIB AllocIdentifier

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

     LIB malloc, Bind_bank_s1

                              
; **************************************************************************************************
;
;    Allocate memory for symbol identifier string
;
;    IN: HL  = local pointer to identifier (with initial length byte and null-terminated).
;              The local pointer must not be in SEGMENT 1.
;
;   OUT: BHL = extended pointer to allocated memory with identifier,
;              otherwise NULL if no room
;        Fc = 0 if memory allocated, otherwise Fc = 1
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;                                                  
.AllocIdentifier    ld   a,(hl)                   ; get length of identifier
                    inc  a                        ; length of identifier + length byte
                    inc  a                        ; length of identfifier + null-terminator
                    ld   c,a
                    ex   de,hl                    ; preserve local pointer in DE
                    call malloc                   ; get memory for id. (always bound into segment)
                    ret  c                        ; Ups - no room ...
                    ex   de,hl                    ; HL = local 'from' pointer (in segment 0)
                    push de
                    push bc                       ; preserve extended pointer to memory in BDE
                    ld   b,0                      ; C = length of string
                    ldir                          ; copy string into extended address
                    pop  bc
                    pop  hl                       ; return extended pointer to string in BHL
                    cp   a                        ; Fc = 0, identifier allocated...
                    ret
