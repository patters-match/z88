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
;
;***************************************************************************************************

    MODULE ViewStack_command

    XREF GetKey
    XREF Get_addrparameters
    XREF simple_window, vert_scroll
    XREF Window_VDU, Set_CurPos
    XREF Write_CRLF, Display_Char, Display_string
    XREF Save_alternate, Restore_alternate
    XREF InthexDisp_H
    XREF Get_DZ_PC, Get_dump_byte, AdjustAddress
    XREF SP_Mnemonic

    XDEF ViewStack

    INCLUDE "defs.h"
    INCLUDE "memory.def"


; ***************************************************************************
;
; View stack pointer                        V0.20/1.03
;
;    IN:  HL pointer to current character in input buffer
;
; Register usage:
;
;                 HL  : pointer to 16bit address at the TOP of screen
;                 DE  :                                 BOTTOM
;
.ViewStack        EXX                       ;                                           ** V1.03
                  LD   L,(IY + VP_SP)       ;                                           ** V1.03
                  LD   H,(IY + VP_SP+1)     ; preset default address                    ** V1.03
                  EXX                       ;                                           ** V1.03
                  CALL Get_addrparameters
                  RET  C
                  JR   NZ, View_addresses
                  LD   C, MS_S3
                  RST  OZ_MPB
                  PUSH BC                   ; preserve current binding state
                  CALL View_addresses
                  POP  BC
                  RST  OZ_MPB               ; restore binding state
                  RET

.View_addresses   LD   HL, simple_window    ; no vertical scrolling,
                  LD   A,(IY + IntWinID)    ; get current Intuition window ID           ** V0.26
                  CALL Window_VDU           ; no cursor. Clear window.                  ** V0.26
                  LD   A,12
                  CALL Display_Char         ; clear screen & cursor at top

                  EXX
                  PUSH HL                   ; BOTTOM pointer
                  LD   BC,14
                  ADD  HL,BC                ; (8 words higher than BOTTOM pointer)
                  EXX
                  CALL AdjustAddress
                  EXX
                  PUSH HL
                  EXX
                  POP  HL                   ; HL = TOP pointer
                  POP  DE                   ; DE = BOTTOM pointer
                  PUSH HL
                  CALL DispStack_8lines     ; display stack 8 words before SP...
                  POP  HL
.ViewStack_loop
                  CALL GetKey
                  CP   27                   ; ESC pressed?
                  JR   Z, exit_viewstack
                  CP   $FE                  ; <Down Cursor>?
                  JR   Z, next_stack_item
                  CP   $FF                  ; <Up Cursor>?
                  JR   Z, prev_stack_item
                  CP   $FA                  ; <SHIFT><Down Cursor>?
                  JR   Z, next_8stackitems
                  CP   $FB                  ; <SHIFT><Up Cursor>?
                  JR   Z, prev_8stackitems
                  JR   ViewStack_loop

.exit_viewstack   LD   HL, vert_scroll      ; enable cursor and vertical scrolling      ** V0.28
                  CALL Display_string       ;                                           ** V0.28
                  LD   BC,$0700             ; set cursor position at bottom of screen   ** V0.28
                  CALL Set_CurPos           ;                                           ** V0.28
                  JP   Write_CRLF           ;                                           ** V0.28

.next_stack_item  DEC  HL                   ; Please note:
                  DEC  HL                   ; the stack grows downwards!
                  DEC  DE
                  DEC  DE                   ; update pointers to next item
                  PUSH HL
                  LD   HL, scroll_up
                  CALL Display_String       ; scroll screen contents one line up
                  LD   BC,$0700             ; set cursor position at bottom of screen
                  CALL Set_CurPos
                  POP  HL
                  EX   DE,HL
                  CALL DispStack_line       ; display stack item at HL
                  EX   DE,HL
                  JR   ViewStack_loop

.prev_stack_item  INC  HL
                  INC  HL
                  INC  DE
                  INC  DE                   ; update pointers to prev. item
                  PUSH HL
                  LD   HL, scroll_down
                  CALL Display_String       ; scroll screen contents one line down
                  LD   BC,$0000             ; set cursor position at top of screen
                  CALL Set_CurPos
                  POP  HL
                  CALL DispStack_line       ; display stack item at HL
                  JR   ViewStack_loop

.next_8stackitems DEC  DE                   ; update for next stack item
                  DEC  DE                   ; new TOP ptr.
                  LD   H,D                  ; display next 8 stack items.
                  LD   L,E
                  LD   A,12
                  CALL Display_Char         ; clear screen & cursor at top
                  CALL DispStack_8lines
                  EX   DE,HL                ; new TOP & BOTTOM pointers
                  JR   ViewStack_loop

.prev_8stackitems LD   BC,16                ; 8 words higher on stack...
                  ADD  HL,BC                ; HL = new TOP pointer
                  PUSH HL
                  LD   A,12
                  CALL Display_Char         ; clear screen & cursor at top
                  CALL DispStack_8lines
                  EX   DE,HL                ; DE = new BOTTOM pointer
                  POP  HL
                  JP   ViewStack_loop


; ***************************************************************************
;
; Display 8 lines of contents from current stack address specified by HL
;
; HL - 16 bytes on return
;
.DispStack_8lines LD   B,8
.dispstack_loop   CALL DispStack_line
                  DEC  HL                   ; Please note:
                  DEC  HL                   ; the stack grows downwards!
                  DJNZ,dispstack_loop
                  INC  HL
                  INC  HL
                  RET


; ***************************************************************************
;
; Display stack contents at address specified by HL
; - display:
;
;   'Top Of Stack' if HL has reached ...
;   'SP'           if HL has reached the current stack pointer
;
; - No registers affected on return.
;
.DispStack_line   PUSH HL
                  PUSH DE
                  PUSH BC                   ; don't destroy
                  PUSH AF                   ; registers...
                  PUSH HL
                  EXX
                  POP  HL
                  EXX
                  CALL AdjustAddress
                  EXX
                  PUSH HL
                  EXX
                  CALL Get_DZ_PC
                  SCF
                  CALL IntHexDisp_H         ; display stack address
                  LD   A,32
                  CALL Display_Char
                  LD   A,'<'
                  CALL Display_Char
                  CALL Get_dump_byte
                  LD   L,A
                  CALL Get_dump_byte
                  LD   H,A
                  SCF
                  CALL IntHexDisp_H         ; contents of stack address
                  LD   A,'>'
                  CALL Display_Char
                  LD   A,32
                  CALL Display_Char
                  EXX                       ;                              ** V1.03
                  POP  HL                   ;                              ** V1.03
                  LD   A,H
                  CP   (IY + VP_SP+1)       ; HL = SP?                     ** V1.03
                  EXX                       ;                              ** V1.03
                  JR   NZ, ptr_not_SP       ; No...
                  EXX                       ;                              ** V1.03
                  LD   A,L
                  CP   (IY + VP_SP)         ;                              ** V1.03
                  EXX                       ;                              ** V1.03
                  JR   NZ, ptr_not_SP
                  LD   HL, SP_Msg           ; display '[SP]'
                  CALL Display_String

.ptr_not_SP       PUSH IY                   ;                              ** V1.03
                  EXX                       ;                              ** V1.03
                  POP  BC                   ;                              ** V1.03
                  DEC  BC                   ;                              ** V1.03
                  DEC  BC                   ; BC = Top Of Stack            ** V1.03
                  LD   A,H
                  CP   B                    ; HL = top of stack?
                  EXX                       ;                              ** V1.03
                  JR   NZ, line_finished    ; no...
                  EXX                       ;                              ** V1.03
                  LD   A,L
                  CP   C
                  EXX                       ;                              ** V1.03
                  JR   NZ, line_finished
                  LD   HL, Top_Msg          ; display
                  CALL Display_String       ; 'Top Of Stack' message
.line_finished    CALL Write_CRLF
                  POP  AF
                  POP  BC
                  POP  DE
                  POP  HL
                  RET

.Top_Msg          DEFM "[TOS]",0
.SP_Msg           DEFM "[SP]",0
.scroll_down      DEFM 1,$FE,0
.scroll_up        DEFM 1,$FF,0
