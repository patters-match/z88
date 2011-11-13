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

     MODULE Instruction_Break


     XREF SkipSpaces, ConvHexByte, Calc_HL_Ptr
     XREF Write_Err_Msg, Syntax_Error
     XREF Write_CRLF, IntHexDisp

     XDEF DefInstrBreak, InstrBreakList


     INCLUDE "defs.h"



; ******************************************************************************
;
; Define instruction break
;
.DefInstrBreak      PUSH HL
                    LD   C, InstrBreakPatt+1
                    CALL Calc_HL_Ptr
                    EX   DE,HL                         ; DE points at start of string
                    POP  HL                            ; restore ptr. to command line
                    CALL SkipSpaces
                    JR   C, res_instrbrk_flag          ; no parameter - reset search flag
                    LD   C,4                           ; fetch max. 4 bytes

.fetch_bitpattern   LD   A,(HL)
                    OR   A                             ; end of line reached?
                    JR   Z, bitpattern_fetched
                    CALL ConvHexByte
                    JR   C, illegal_hexbyte
                    LD   (DE),A                        ; store bitpattern of instruction
                    INC  DE
                    DEC  C
                    JR   NZ, fetch_bitpattern

.bitpattern_fetched SET  Flg_RTM_BpInst,(IY + FlagStat2)
                    LD   A,4
                    SUB  C
                    LD   (IY + InstrBreakPatt),A       ; store length of instruction
                    RET

.illegal_hexbyte    CALL Syntax_Error                  ; Ups - illegal hex byte
.res_instrbrk_flag  RES  Flg_RTM_BpInst,(IY + FlagStat2)
                    LD   (IY + InstrBreakPatt),0       ; Zero length - no search string
                    RET


; ******************************************************************************
;
; Lst Instruction bitpattern
;
.InstrBreakList
                    LD   C, InstrBreakPatt
                    CALL Calc_HL_Ptr
                    XOR  A
                    CP   (HL)
                    JR   Z, not_defined
                    LD   B,(HL)                   ; length of string
.bitpattern_loop    PUSH BC
                    INC  HL
                    LD   E,(HL)
                    PUSH HL
                    EX   DE,HL
                    CP   A
                    CALL IntHexDisp
                    POP  HL
                    POP  BC
                    DJNZ bitpattern_loop
                    JP   Write_CRLF

.not_defined        LD   A, ERR_none
                    JP   Write_Err_Msg
