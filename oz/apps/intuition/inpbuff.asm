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

     MODULE Input_buffer

     ; Defined in 'Windows_asm':
     XREF SV_INT_window, REL_INT_window, ToggleWindow

     XREF Toggle_CLI
     XREF Use_IntErrhandler, RST_ApplErrhandler

     XDEF InputCommand, Input_buffer, Prompt


     INCLUDE "defs.h"
     INCLUDE "stdio.def"


; **************************************************************************
;
; Command line input, 17 bytes max. input.
;
; Register status after return:
;
;       ......../IXIY     same
;       AFBCDEHL/....afb  different
;
; Stack usage:  2 bytes
;
.InputCommand     LD   HL, SV_INTUITION_RAM + Cmdlbuffer
                  LD   D,H
                  LD   E,L                  ; get a copy of start of buffer...
                  LD   A,16                 ; max. buffer size (excl. 0 terminator)

; *****************************************************************************************
;
; Command line input.                        ** V0.31
;
; Entry:
;
; DE = start of true buffer
;
; On return, HL will point to start of buffer & A = length of buffer
;
; register usage:
;         DE     = absolute ptr. to first char of buffer.
;         (DE-1) = max. size of input buffer
;
; Register status after return:
;
;       ......../IXIY     same
;       AFBCDEHL/....     different
;
.Input_Buffer     DEC  A                    ; use 1 byte as max. length id.
                  LD   C,A                  ; place cursor at end of command...
                  LD   (DE),A               ; max length of buffer
                  INC  DE

.input_loop       OZ   OS_Pout              ; place cursor at beginning of line
                  DEFM 1,"2X",32,0

                  CALL DisplayPrompt        ; display Intuition prompt
                  DEC  DE
                  LD   A,(DE)
                  LD   B,A                  ; max. length of buffer...
                  INC  DE                   ; point at first char
                  LD   A,@00001001          ; return unexp. characters, info in buffer
                  CALL Use_IntErrhandler    ; Use Intuition error handler
                  CALL SV_INT_window        ; save Intuition screen before keyboard input
                  CALL_OZ (Gn_Sip)
                  CALL REL_INT_window       ; release Intuition window
                  CALL RST_ApplErrhandler   ; restore application error handler
                  CP   $1F                  ; <DIAMOND>- ?
                  JR   Z, CLI_facility
                  CP   IN_ENT               ; <ENTER>?
                  JR   Z, enter_key
                  CP   IN_TAB               ; <TAB>?
                  JR   Z, inp_togglewindow
                  CP   IN_ESC               ; <ESC>?
                  JR   Z, escape_key
                  JR   input_loop           ; then command line...

.CLI_facility     PUSH DE                   ; preserve pointer to input line
                  PUSH BC                   ; preserve cursor position
                  CALL Toggle_CLI           ; activate/de-activate CLI...
                  POP  BC
                  POP  DE
                  JR   input_loop

.enter_key        CALL_OZ(Gn_Nln)           ; execute a 'new line'
                  LD   H,D
                  LD   L,E                  ; DE points at first char
                  LD   A,B                  ; length of input line
                  RET

.escape_key       CALL_OZ(Gn_Nln)           ; execute a new line...
                  CALL  DisplayPrompt       ;                                           ** V0.19c
                  XOR   A
                  LD    (DE),A              ; null-terminate input line
                  LD    C,A                 ; cursor position at beginning of line
                  JR    input_loop


; *****************************************************************************************
;
; Select Z88-Monitor window 1 or 2.  (toggle)           V0.18 / V0.22b
;
.inp_togglewindow CALL ToggleWindow         ; display Intuition window...               ** V0.22/V0.28
                  CALL DisplayPrompt
                  JR   input_loop


; ***********************************************************************************
;
; Display Intuition input prompt                                                        ** V0.19c
;
.DisplayPrompt    OZ   OS_Pout
                  DEFM 1,"B?>",1,"B",0
                  RET
