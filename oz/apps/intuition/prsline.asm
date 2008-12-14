; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

     MODULE Parse_commandline

     XDEF SkipSpaces, GetChar, UpperCase

     INCLUDE "char.def"
     INCLUDE "defs.h"


; **********************************************************************************
;
; Skip spaces in input buffer, and point at first non-space character
; Entry; HL points at position to start skipping spaces...
; On return HL will point at first non-space character.
; If EOL occurs, Fc = 1, otherwise Fc = 0.
;
; Register status after return:
;
;       A.BCDE../IXIY  same
;       .F....HL/....  different
;
.SkipSpaces       PUSH BC
                  LD   B,A
.SpacesLoop       LD   A,(HL)
                  OR   A                    ; EOL ?
                  JR   Z, EOL_reached
                  CP   32
                  JR   NZ, Exit_SkipSpaces  ; x <> spaces!
                  INC  HL
                  JR   SpacesLoop
.EOL_reached      SCF                       ; Ups, EOL!
                  JR   Restore_A
.Exit_SkipSpaces  XOR  A                    ; Fc = 0
.Restore_A        LD   A,B
                  POP  BC
                  RET


; **********************************************************************************
;
; GetChar routine
; - Return a char, in A, from input buffer by the current pointer, HL
;   If EOL reached, return Fc = 1, otherwise Fc = 0
;
; Status of registers on return:
;
;       ..BCDE../IXIY  same
;       AF....HL/....  different
;
.GetChar          LD   A,(HL)               ; get char at current buffer pointer
                  INC  HL                   ; get ready for next char
                  OR   A                    ; EOL ?
                  RET  NZ                   ; No, null-terminator not yet reached
.no_char_read     SCF
                  RET


; ***********************************************************************************
;
; Convert Character to upper Case
; Character to be converted, in A, and returned in A
;
; Register status after return:
;
;       ..BCDEHL/IXIY  same
;       AF....../....  different
;
.UpperCase        CALL_OZ(GN_CLS)
                  RET  NC                   ; not an alpha character
                  RES  5,A                  ; make sure it's upper case...
                  RET
