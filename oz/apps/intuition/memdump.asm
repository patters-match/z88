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

    MODULE Memorydump_to_scr

    XREF GetKey, Disp_Monitor_win
    XREF window2, simple_window
    XREF Window_VDU, Set_CurPos
    XREF Write_CRLF, Display_string, Display_char
    XREF Conv_to_nibble
    XREF IntHexDisp, IntHexDisp_H
    XREF UpperCase
    XREF Get_DZ_PC
    XREF Get_addrparameters
    XREF Save_alternate, Restore_alternate

    XDEF Mem_view, Mem_edit
    XDEF Mem_Dump
    XDEF AdjustAddress, Get_dump_byte

    INCLUDE "defs.h"
    INCLUDE "memory.def"


; ***********************************************************************************************
;
; Memory dump (View/Edit)
;
.Mem_View         RES  Flg_EditMode,(IY + FlagStat1)            ; indicate memory view only
                  JR   Mem_dump_param
.Mem_Edit         SET  Flg_EditMode,(IY + FlagStat1)


; *******************************************************************************************
;
; Input memory address parameters
;
.Mem_dump_param   EXX
                  LD   L,(IY + VP_PC)
                  LD   H,(IY + VP_PC+1)
                  EXX
                  CALL Get_addrparameters
                  RET  C
                  JP   NZ, Mem_dump
                  LD   C, MS_S3
                  RST  OZ_MPB
                  PUSH BC                    ; preserve prev. binding state
                  CALL Mem_dump
                  POP  BC
                  RST  OZ_MPB                ; restore prev. binding state
                  RET


; *********************************************************************************
;
; Memory View/Edit                          V0.19
;
.Mem_dump         LD   HL, window2          ; use window #2 for
                  LD   A,(IY + IntWinID)    ; get current Intuition window ID           ** V0.26
                  CALL Window_VDU           ; memory dump without cursor                ** V0.26
                  LD   HL, simple_window    ; enabled and vertical scrolling on
                  CALL Window_VDU           ;                                           ** V0.26
                  LD   HL, active_cursor    ;                                           ** V0.24d
                  CALL Display_String       ; simple window with active cursor          ** V0.24d
                  CALL ResetCurPos          ; intialise cursor pos. in window           ** V0.24d
                  EXX                       ; get alternate...
                  PUSH HL
                  EXX
                  POP  DE                   ; TOP dump address
                  CALL Dump_96_bytes        ; begin dump from nn
                  EXX
                  PUSH HL
                  EXX
                  POP  HL                   ; BOTTOM dump address
.mem_view_loop    CALL DisplayCurPos        ;                                           ** V0.24d
                  CALL GetKey
                  CP   9                    ; TAB pressed?                              ** V0.24d
                  JP   Z, HexAscii_Cursor   ; toggle between Hex & ASCII cursor         ** V0.24d
                  CP   27
                  JP   Z, exit_mem_view     ; ESC pressed - abort...
                  CP   $FC                  ; <Left Cursor>?                            ** V0.24d
                  JP   Z, mv_cursor_left    ;                                           ** V0.24d
                  CP   $FD                  ; <Right Cursor>?                           ** V0.24d
                  JP   Z, mv_cursor_right   ;                                           ** V0.24d
                  CP   $FE                  ; <Down Cursor> ?
                  JR   Z, next_12_bytes
                  CP   $FF                  ; <Up Cursor>   ?
                  JP   Z, prev_12_bytes
                  CP   $FA                  ; <SHIFT> <Down Cursor> ?
                  JP   Z, next_96_bytes
                  CP   $FB                  ; <SHIFT> <Up Cursor> ?
                  JP   Z, prev_96_bytes

                  CP   126                  ;                                           ** V1.03
                  JP   P, mem_view_loop     ; char > 126, illegal                       ** V1.03
                  CP   32                   ;                                           ** V1.03
                  JP   M, mem_view_loop     ; char < 32, illegal...                     ** V1.03

                  BIT  Flg_EditMode,(IY + FlagStat1) ;                                  ** V0.25
                  JR   Z, mem_view_loop     ; view mode - no memory editing...          ** V0.25
                  BIT  Flg_HexCursor,(IY + FlagStat1) ; allowed input by current cursor ** V0.25
                  JR   Z, put_ascii_byte    ; - put ASCII byte into memory              ** V0.25
                  CALL UpperCase            ; get HEX byte...                           ** V0.25
                  CALL Display_Char
                  CALL Conv_to_nibble       ; ASCII to value 0 - 15.                    ** V0.25
                  CP   16                   ; legal range 0 - 15
                  JR   NC, illegal_byte     ;
                  RLCA                      ;                                           ** V0.28
                  RLCA                      ;                                           ** V0.28
                  RLCA                      ;                                           ** V0.28
                  RLCA                      ;                                           ** V0.28
                  AND  @11110000            ; into bit 7 - 4.                           ** V0.28
                  LD   B,A
                  CALL GetKey
                  CP   126                  ;                                           ** V1.03
                  JP   P, illegal_byte      ; char > 126, illegal                       ** V1.03
                  CP   32                   ;                                           ** V1.03
                  JP   M, illegal_byte      ; char < 32, illegal...                     ** V1.03
                  CALL UpperCase
                  CALL Display_Char
                  CALL Conv_to_nibble       ; ASCII to value 0 - 15.
                  CP   16                   ; legal range 0 - 15
                  JR   NC, illegal_byte
                  OR   B                    ; merge the two nibbles
                  CALL Alter_Memory         ; HEX byte into memory...
                  JP   mv_cursor_right      ; auto move to next memory cell...

.put_ascii_byte   CALL Alter_Memory         ; put into memory and display i window      ** V0.25
                  JP   mv_cursor_right      ; auto move to next memory cell...

.illegal_byte     CALL DisplayCurLine       ; reset cursor at current position          ** V0.25
                  JP   mem_view_loop        ; and re-display memory dump at cur. line   ** V0.25

.exit_mem_view    SET  Flg_IntWin,(IY + FlagStat1)     ; use Intuition #1 window
                  CALL Disp_Monitor_win
                  RET

.next_12_bytes    LD   A,(IY + CY)          ; get CY                                    ** V0.24d
                  CP   7                    ; cursor at bottom line?                    ** V0.24d
                  JR   Z, scroll_12_up      ; Yes - display a new line of bytes         ** V0.24d
                  INC  (IY + CY)            ; move cursor one line down                 ** V0.24d
                  JP   mem_view_loop        ;                                           ** V0.24d
.scroll_12_up     PUSH HL
                  EXX
                  POP  HL                   ; get TOP dump address
                  EXX
                  CALL AdjustAddress        ; execute addr. wrap if necessary...
                  LD   HL, scroll_up
                  CALL Display_String
                  LD   BC,$0700
                  CALL Set_CurPos           ; set print position at (0,7)
                  CALL Dump_12_bytes
                  EXX
                  PUSH HL
                  EXX
                  POP  HL                   ; new BOTTOM dump address
                  PUSH HL
                  CP   A
                  LD   BC,96
                  SBC  HL,BC
                  PUSH HL
                  EXX
                  POP  HL
                  EXX
                  CALL AdjustAddress
                  EXX
                  PUSH HL
                  EXX
                  POP  DE                   ; new TOP dump address
                  POP  HL                   ; new BOTTOM dump address restored
                  JP   mem_view_loop

.next_96_bytes    PUSH HL
                  EXX
                  POP  HL                   ; get TOP dump address
                  EXX
                  CALL AdjustAddress        ; execute addr. wrap if necessary...
                  CALL Dump_96_bytes
                  EXX
                  PUSH HL
                  EXX
                  POP  HL                   ; new BOTTOM dump address
                  PUSH HL
                  CP   A
                  LD   BC,96
                  SBC  HL,BC
                  PUSH HL
                  EXX
                  POP  HL
                  EXX
                  CALL AdjustAddress
                  EXX
                  PUSH HL
                  EXX
                  POP  DE                   ; new TOP dump address
                  POP  HL                   ; new BOTTOM dump_address restored
                  JP   mem_view_loop

.prev_12_bytes    LD   A,(IY + CY)          ; get CY                                    ** V0.24d
                  CP   0                    ; cursor at top line?                       ** V0.24d
                  JR   Z, scroll_12_down    ; Yes - display a new line of bytes         ** V0.24d
                  DEC  (IY + CY)            ; move cursor one line up                   ** V0.24d
                  JP   mem_view_loop        ;                                           ** V0.24d
.scroll_12_down   PUSH DE
                  EXX                       ; alternate...
                  POP  HL                   ; current dump addr. = TOP dump addr.
                  CP   A                    ; Fc = 0
                  LD   BC,12
                  SBC  HL,BC                ; move 16 bytes back
                  EXX                       ; main...
                  CALL AdjustAddress        ; execute addr. wrap if necessary...
                  EXX                       ; alternate
                  PUSH HL
                  EXX                       ; main...
                  POP  HL
                  LD   D,H
                  LD   E,L                  ; new TOP dump address
                  LD   BC,96
                  ADD  HL,BC                ; calculate new BOTTOM addr.
                  PUSH HL
                  EXX                       ; alternate
                  EX   (SP),HL              ; (SP) = new current dump addr.
                  EXX                       ; HL' = new BOTTOM addr.
                  CALL AdjustAddress        ;
                  EXX                       ; alternate
                  EX   (SP),HL              ; restore current dump address
                  EXX                       ; main
                  POP  HL                   ; new BOTTOM dump address
                  PUSH HL
                  LD   HL, scroll_down
                  CALL Display_String
                  LD   BC,0
                  CALL Set_CurPos           ; set print position at (0,0)
                  CALL Dump_12_bytes
                  POP  HL                   ; restore new BOTTOM dump address
                  JP   mem_view_loop

.prev_96_bytes    PUSH DE
                  EXX                       ; alternate...
                  POP  HL                   ; get TOP dump address
                  CP   A                    ; Fc = 0
                  LD   BC,96
                  SBC  HL,BC                ; move 96 bytes back
                  EXX
                  CALL AdjustAddress        ; execute addr. wrap if necessary...
                  EXX
                  PUSH HL
                  EXX
                  POP  HL
                  LD   D,H
                  LD   E,L                  ; new TOP dump address
                  LD   BC,96
                  ADD  HL,BC
                  PUSH HL
                  EXX
                  EX   (SP),HL
                  EXX
                  CALL AdjustAddress
                  EXX
                  EX   (SP),HL              ; restore current dump address
                  EXX
                  POP  HL                   ; new BOTTOM dump address
                  PUSH HL
                  CALL Dump_96_bytes
                  POP  HL                   ; restore new BOTTOM dump address
                  JP   mem_view_loop

.HexAscii_Cursor  BIT  Flg_HexCursor,(IY + FlagStat1)            ;                                           ** V0.24d
                  JR   Z, set_HexCursor     ; ASCII cursor active, set HEX cursor       ** V0.24d
                  RES  Flg_HexCursor,(IY + FlagStat1)            ; HEX cursor active, set ASCII cursor       ** V0.24d
                  LD   (IY + SC),42         ; SC = 42                                   ** V0.24d
                  LD   (IY + CI),1          ; CI = 1                                    ** V0.24d
                  JP   mem_view_loop        ;                                           ** V0.24d
.set_HexCursor    SET  Flg_HexCursor,(IY + FlagStat1)            ;                                           ** V0.24d
                  LD   (IY + SC),6          ; SC = 6                                    ** V0.24d
                  LD   (IY + CI),3          ; CI = 3                                    ** V0.24d
                  JP   mem_view_loop        ;                                           ** V0.24d

.mv_cursor_left   LD   A,(IY + CX)          ; get CX                                    ** V0.24d
                  CP   0                    ; cursor reached left boundary?             ** V0.24d
                  JR   Z, wrap_curs_right   ; Yes - wrap to right boundary              ** V0.24d
                  DEC  (IY + CX)            ; move cursor 1 byte left                   ** V0.24d
                  JP   mem_view_loop        ;                                           ** V0.24d
.wrap_curs_right  LD   (IY + CX),11         ;                                           ** V0.24d
                  JP   prev_12_bytes        ;                                           ** V0.24d/V0.28

.mv_cursor_right  LD   A,(IY + CX)          ; get CX                                    ** V0.24d
                  CP   11                   ; cursor reached right boundary?            ** V0.24d
                  JR   Z, wrap_curs_left    ; Yes - wrap to left boundary               ** V0.24d
                  INC  (IY + CX)            ; move cursor 1 byte right                  ** V0.24d
                  JP   mem_view_loop        ;                                           ** V0.24d
.wrap_curs_left   LD   (IY + CX),0          ;                                           ** V0.24d
                  JP   next_12_bytes        ;                                           ** V0.24d/V0.28

;
; V0.25
; A = byte to be put into the memory location the cursor is currently pointing at
;
.Alter_Memory     PUSH AF
                  CALL Get_CurOffset        ; cursor offset in A
                  CALL Get_OffsetPtr        ; added with TOP pointer
                  POP  AF                   ; returns cursor pointer to memory...
                  LD   (BC),A               ; put byte into memory
                  CALL DisplayCurLine
                  RET

;
; display memory dump at current cursor line
;
.DisplayCurLine   CALL Get_CurOffset        ; get cursor offset
                  SUB  (IY + CX)            ; to start of line, (CY*12-CX)
                  CALL Get_OffsetPtr
                  PUSH BC
                  EXX
                  POP  HL                   ; into HL'
                  EXX
                  LD   B,(IY + CY)          ; get CY (current cursor line)
                  LD   C,0                  ; start of line
                  CALL Set_CurPos           ; set cursor position
                  CALL Dump_12_bytes        ; dump memory...
                  RET

;
; calculate cursor offset from top corner of screen
; (also referenced as offset from TOP pointer)
;
.Get_CurOffset    PUSH BC
                  LD   A,(IY + CY)          ; get CY
                  CP   0
                  JR   Z, CY_multiplied
                  LD   C,A
                  LD   B,11
.CY_x_12          ADD  A,C                  ; CY*12
                  DJNZ, CY_x_12
.CY_multiplied    ADD  A,(IY + CX)          ; CY*12+CX = cursor offset from TOP
                  POP  BC
                  RET

;
; Calculate absolute pointer from TOP pointer with cursor offset into BC
;
.Get_OffsetPtr    PUSH HL
                  PUSH DE
                  LD   C,A                  ;
                  LD   B,0
                  EX   DE,HL
                  ADD  HL,BC                ; add offset to base...
                  LD   A,H                  ; get high byte of cursor memory location
                  EXX
                  OR   E                    ; keep PC in sgmt 3 (E=@11000000), else
                  EXX
                  LD   B,A                  ; with E = 0, dump addr. not affected...
                  LD   C,L                  ; BC = ptr. to current cursor memory cell
                  POP  DE
                  POP  HL
                  RET


; *********************************************************************************
; Reset cursor position in window           V0.24d
;
; - No registers affected
;
.ResetCurPos      LD   (IY + SC),6            ; cursor begins at tab 6
                  LD   (IY + CI),3            ; CI = 3 with Hex cursor
                  LD   (IY + CX),0            ; CX = 0
                  LD   (IY + CY),0            ; CY = 0
                  SET  Flg_HexCursor,(IY + FlagStat1)            ; Indicate Hex cursor
                  RET


; *********************************************************************************
;
; display cursor in window (with VDU 1,"3","@",32+CX,32+CY)
;
; - No registers affected
;
.DisplayCurPos    PUSH AF
                  PUSH BC
                  LD   A,(IY + CX)          ; get CX
                  LD   B,(IY + CI)          ; get CI
                  DEC  B
                  JR   Z, CX_calculated
                  LD   C,A
.tab_loop         ADD  A,C                  ; CX*CI
                  DJNZ,tab_loop
.CX_calculated    ADD  A,(IY + SC)          ; add rel. horisontal start in window
                  LD   C,A                  ; CX position in window ready.
                  LD   B,(IY + CY)          ; get CY
                  CALL Set_CurPos           ; display cursor at CX,CY
                  POP  BC
                  POP  AF
                  RET


; *********************************************************************************
;
; Dump 96 bytes to #2 in Hex and ASCII format from current address in HL'
; HL' will point +96 bytes on return
;
.Dump_96_bytes    LD   A,12
                  CALL Display_Char
                  LD   B,8                  ; display 8 lines
.dump_loop        PUSH BC
                  CALL Dump_12_bytes        ; dump 1 line (16 bytes)
                  POP  BC
                  DJNZ,dump_loop
                  RET


; *********************************************************************************
;
; Dump 12 bytes to #2 in Hex and ASCII format from current address in HL'
; HL' will point +16 bytes on return
;
.Dump_12_bytes    PUSH DE
                  PUSH HL
                  CALL Get_DZ_PC            ; get HL' simulated in HL
                  SCF                       ; display 16bit hex
                  CALL IntHexDisp_H         ; - the current dump address
                  LD   A,32
                  CALL Display_Char
                  EXX                       ; first display 12 HEX values
                  PUSH HL                   ; but remember start
                  EXX                       ; for ASCII dump.
                  LD   B,12
.dump_hex_loop    PUSH BC
                  CALL Get_dump_byte        ; fetch byte at dump address
                  CP   A                    ; display in 8bit HEX
                  LD   L,A
                  CALL IntHexDisp
                  LD   A,32
                  CALL Display_Char
                  POP  BC
                  DJNZ,dump_hex_loop
                  EXX
                  POP  HL
                  EXX
                  LD   B,12                 ; now dump same bytes in ASCII format
.dump_ascii_loop  PUSH BC
                  CALL Get_dump_byte        ; fetch byte at dump address
                  CP   32
                  JP   M, disp_dot
                  CP   127
                  JP   M, disp_ascii_byte
.disp_dot         LD   A, '.'               ; display '.' if A = [0;31] [128;255]
.disp_ascii_byte  CALL Display_Char
                  POP  BC
                  DJNZ,dump_ascii_loop
                  CALL Write_CRLF
                  POP  HL
                  POP  DE
                  RET


; *********************************************************************************
;
; Get a byte from Dump address and increase dump address for next fetch.
;
.Get_dump_byte    EXX                       ; get alternate register set...
                  LD   A,(HL)               ; get byte at dump address
                  INC  HL
                  EXX
                  CALL AdjustAddress
                  RET


; *********************************************************************************
; - This routine will automatically executed wrap around if dump is executed in
; a bank and the dump address is about to go beyond the bank.
;
.AdjustAddress    EX   AF,AF'
                  EXX
                  XOR  A
                  CP   E
                  JR   Z, using_logaddr     ;
                  LD   A,H                  ; get high byte of PC
                  AND  @00111111
                  OR   E                    ; keep PC in segment
                  LD   H,A
.using_logaddr    EXX
                  EX   AF,AF'               ; AF restored
                  RET

.active_cursor    DEFM 1,"C",0
.scroll_down      DEFM 1,$FE,0
.scroll_up        DEFM 1,$FF,0
