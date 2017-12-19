; ********************************************************************************************************************
;
;     ZZZZZZZZZZZZZZZZZZZZ    8888888888888       00000000000
;   ZZZZZZZZZZZZZZZZZZZZ    88888888888888888    0000000000000
;                ZZZZZ      888           888  0000         0000
;              ZZZZZ        88888888888888888  0000         0000
;            ZZZZZ            8888888888888    0000         0000       AAAAAA         SSSSSSSSSSS   MMMM       MMMM
;          ZZZZZ            88888888888888888  0000         0000      AAAAAAAA      SSSS            MMMMMM   MMMMMM
;        ZZZZZ              8888         8888  0000         0000     AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
;      ZZZZZ                8888         8888  0000         0000    AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
;    ZZZZZZZZZZZZZZZZZZZZZ  88888888888888888    0000000000000     AAAA      AAAA           SSSSS   MMMM       MMMM
;  ZZZZZZZZZZZZZZZZZZZZZ      8888888888888       00000000000     AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM
;
; Copyright (C) Gunther Strube, 1995-2006
;
; Z80asm is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Z80asm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Z80asm;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; ********************************************************************************************************************

     MODULE Getsym

     LIB IsSpace, IsAlpha, IsAlNum, IsDigit, StrChr, ToUpper

     XDEF disp_ident
     XDEF GetSym, separators


     INCLUDE "stdio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ******************************************************************************
;
; GetSym - read a symbol from the current position of the file's current line.
;
;  IN:    None.
; OUT:    A = symbol identifier
;         (sym) contains symbol identifier
;         (Ident) contains symbol (beginning with a length byte)
;         (lineptr) is updated to point at the next character in the line
;         HL = current lineptr
;
;         If a name or a constant has been fetched:
;         DE = points to start of Ident
;         BC = points at last char+1 of Ident
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.GetSym             PUSH BC
                    PUSH DE
                    PUSH HL

                    XOR  A
                    LD   DE, Ident           ; DE always points at length byte...
                    LD   (DE),A              ; initialise Ident to zero length
                    LD   BC, Ident+1         ; point at pos. for first byte

                    LD   HL,(lineptr)
.skiplead_spaces    LD   A,(HL)
                    CP   CR
                    JR   Z, newline_symbol   ; CR or CRLF as newline
                    CP   LF
                    JR   Z, newline_symbol   ; LF as newline
                    OR   A
                    JR   Z, nonspace_found   ; EOL reached
                    CALL IsSpace
                    JR   NZ, nonspace_found
                    INC  HL                  ; white space...
                    JR   skiplead_spaces

.nonspace_found     PUSH HL                  ; preserve lineptr
                    LD   HL, separators
                    CALL StrChr              ; is byte a separator?
                    POP  HL
                    JR   NZ, separ_notfound

                    ; found a separator - return
                    LD   (sym),A             ; pos. in string is separator symbol
                    INC  HL
                    LD   (lineptr),HL        ; prepare for next read in line
                    JR   exit_getsym

.newline_symbol     LD   A,sym_newline
                    LD   (sym),A
                    JR   exit_getsym

.separ_notfound     LD   A,(HL)              ; get first byte of identifier
                    CP   '$'                 ; identifier a hex constant?
                    JR   Z, found_hexconst
                    CP   '@'                 ; identifier a binary constant?
                    JR   Z, found_binconst
                    CALL IsDigit             ; identifier a decimal constant?
                    JR   Z, found_decmconst
.test_alpha         CALL IsAlpha             ; identifier a name?
                    JR   NZ, found_rubbish
.found_name         LD   A,sym_name
                    JR   read_identifier

.found_decmconst    LD   A, sym_decmconst
                    JR   fetch_constant

.found_hexconst     LD   A,sym_hexconst
                    JR   fetch_constant

.found_binconst     LD   A,sym_binconst
                    JR   fetch_constant

.found_rubbish      LD   A,sym_nil
.read_identifier    LD   (sym),A             ; new symbol found - now read it...
                    XOR  A                   ; Identifier has initial zero length

.name_loop          CP   MAX_IDLENGTH        ; identifier reached max. length?
                    JR   Z,exit_getsym
                    LD   A,(HL)              ; get byte from current line position
                    CALL IsSpace
                    JR   Z, ident_complete   ; separator encountered...
                    PUSH HL
                    LD   HL,separators       ; test for other separators
                    CALL StrChr
                    POP  HL
                    JR   Z, ident_complete   ; another separator encountered
                    LD   A,(HL)
                    CALL IsAlNum             ; byte alphanumeric?
                    JR   NZ, illegal_ident
                    CALL ToUpper             ; name is converted to upper case
                    LD   (BC),A              ; new byte in name stored
                    INC  BC
                    INC  HL
                    LD   (lineptr),HL
                    EX   DE,HL
                    INC  (HL)                ; update length of identifer
                    LD   A,(HL)
                    EX   DE,HL
                    JR   name_loop           ; get next byte for identifier

.illegal_ident      LD   A,sym_nil
                    LD   (sym),A
                    JR   exit_getsym

.ident_complete     XOR  A
                    LD   (BC),A              ; null-terminate identifier
.exit_getsym        LD   A,(sym)
                    POP  HL
                    POP  DE
                    POP  BC
                    RET

.fetch_constant     LD   (sym),A             ; new symbol found - now read it...
                    XOR  A
.constant_loop      CP   MAX_IDLENGTH        ; identifier reached max. length?
                    JR   Z,exit_getsym
                    LD   A,(HL)              ; get byte from current line position
                    CALL IsSpace
                    JR   Z, ident_complete   ; separator encountered...
                    PUSH HL
                    LD   HL,separators       ; test for other separators
                    CALL StrChr
                    POP  HL
                    JR   Z, ident_complete   ; another separator encountered
                    LD   A,(HL)
                    CALL ToUpper
                    LD   (BC),A              ; new byte of identifier stored
                    INC  BC
                    INC  HL
                    LD   (lineptr),HL        ; update lineptr variable
                    EX   DE,HL
                    INC  (HL)                ; update length of identifer
                    LD   A,(HL)
                    EX   DE,HL
                    JR   constant_loop       ; get next byte for identifier

.separators         DEFB separators2-separators1                 ; length byte
.separators1        DEFM 0, '"', "'", ";,.({})+-*/%^=&~|:!<>#", 13, 10
.separators2
