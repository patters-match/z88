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

    MODULE Flagregister_commands

    XREF SkipSpaces, GetChar, UpperCase
    XREF Write_CRLF, Display_Char
    XREF Write_Err_msg
    XREF Switch_bitnumber

    XDEF Flagreg_changes, Display_Flagreg

    INCLUDE "defs.h"


; **********************************************************************************
;
; Flag register altering                    ** V0.16
;
.Flagreg_changes  CALL SkipSpaces           ;                                       ** V0.28
                  JR   C, disp_freg         ; no parameter, display flag register   ** V0.28
                  CALL GetChar              ;                                       ** V0.28
                  CALL UpperCase            ; convert flagregister identifer to UC...
                  CP   'E'
                  JR   Z, overflow_parity
                  JR   search_flag
.overflow_parity  LD   A,'V'                ; Fp/v and Fparity uses same flag bit...
.search_flag      LD   D,8                  ; number of bits in Flag register
                  LD   B,@10000000          ; bit number identifier...
                  PUSH HL                   ; preserve pointer to input buffer      ** V0.28
                  LD   HL,Flagregister
.get_flag_loop    CP   (HL)
                  JR   Z, alter_flag        ; identifer found, alter bit in flag register
                  RRC  B                    ; next bit number in flag register
                  INC  HL
                  DEC  D
                  JR   NZ, get_flag_loop
                  POP  HL                   ; remove pointer before exit...         ** V0.28
                  LD   A,$0E                ; 'Cannot satisfy request'
                  JP   Write_Err_Msg        ; flag doesn't exist...

.alter_flag       LD   C, VP_AF             ; fetch F register in register table
                  CP   A
                  POP  HL                   ; restore pointer to inp. buffer        ** V0.28
                  CALL Switch_bitnumber     ; (try to fetch '+' or '-')

.disp_freg        LD   L,A                  ; altered flag register in L
                  CALL Display_FlagReg      ; and display it...
                  JP   Write_CRLF

.Flagregister     DEFM "SZ",$FF,'H',$FF,"VPC"



; **************************************************************************************
; Display a representation of the Flag register contained in L
;
; Conventions:
;
; When a flag is ON, the mnemonic is displayed, Fz = 1, then 'Z' will be
; printed at the position of bit 6, otherwise a zero is displayed.
;
; A special convention is used to for the P/V flag, since it actually displays
; 4 flags, Even Parity (P), Odd Parity (O), Overflow (V) and No overflow (P)
; Here, the flag is represented in only two forms:
;                   E = Even Parity / Overflow
;                   O = Odd Parity  / No overflow
;
; Register status after return:
;
;       AFBCDEHL/IXIY  same
;       ......../....  different
;
.Display_FlagReg  PUSH AF
                  PUSH BC
                  PUSH IX
                  LD   B,8
                  LD   IX, Flagreg_ON
.disp_flagregloop RLC  L                          ; bit 7 into Fc, move bit 7 into bit 0
                  CALL C, flag_ON                 ; Fc = 1, bit was set
                  CALL NC, flag_OFF               ; Fc = 0, bit was reset
                  PUSH IX
                  CALL Display_char               ; A = Flag bit mnemonic
                  POP  IX
                  INC  IX                         ; point at next flag bit mnemonic
                  DJNZ disp_flagregloop           ; display 8 flag bits...
                  POP  IX
                  POP  BC
                  POP  AF
                  RET
.flag_ON          LD   A,(IX+0)
                  RET
.flag_OFF         LD   A,(IX+8)
                  RET

.Flagreg_ON       DEFM "SZ1H1EMC"
.Flagreg_OFF      DEFM "00000OP0"
