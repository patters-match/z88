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

    MODULE Disassembler

    INCLUDE "defs.h"
    INCLUDE "integer.def"
    INCLUDE "memory.def"

    XREF GetKey
    XREF ToggleWindow
    XREF Rst_Mnemonic, LD_Mnemonic, Halt_Mnemonic, JP_Mnemonic
    XREF CALL_Mnemonic, RET_Mnemonic, EXX_Mnemonic, POP_Mnemonic
    XREF EI_Mnemonic, OUT_Mnemonic, IN_Mnemonic, DI_Mnemonic
    XREF EX_Mnemonic, DE_Mnemonic, HL_Mnemonic, PUSH_mnemonic
    XREF AF_Mnemonic, JR_Mnemonic, DJNZ_Mnemonic, NOP_Mnemonic
    XREF ADD_Mnemonic, DEC_Mnemonic, INC_Mnemonic, SET_Mnemonic
    XREF BIT_Mnemonic, RES_Mnemonic, RRD_Mnemonic, RLD_Mnemonic
    XREF NEG_Mnemonic, IM_Mnemonic, RETI_Mnemonic, RETN_Mnemonic
    XREF ADC_Mnemonic, SBC_Mnemonic, IX_Mnemonic, IY_Mnemonic
    XREF OS_Mnemonic, GN_Mnemonic, DC_Mnemonic, FP_Mnemonic
    XREF SP_Mnemonic
    XREF Arithm_8bit_lookup, reg16_lookup, RotShift_Acc_lookup, RotShift_CB_lookup
    XREF ld_block_lookup, cp_block_lookup, in_block_lookup, out_block_lookup
    XREF reg8_Mnemonic, cc_table
    XREF OS_2byte_lookup, OS_1byte_lookup, GN_lookup, DC_lookup, FP_lookup

    XREF Get_errmsg
    XREF Write_CRLF, Write_Msg, Display_char, Display_string
    XREF SkipSpaces, Get_constant
    XREF Disable_INT, Enable_INT
    XREF RST_appl_window, SV_appl_window, Disp_Monitor_Win
    XREF Save_SPAFPC, Restore_SPAFPC
    XREF Save_alternate, Restore_alternate
    XREF InthexDisp, IntHexDisp_H
    XREF DisplayRegisters
    XREF Pause_Interrupt

    XDEF Get_addrparameters
    XDEF Disasm_param
    XDEF DZ_instruction
    XDEF Display_OZ_mnemonic
    XDEF DZ_Z80pc, Get_DZ_PC


; **********************************************************************************
;
.Get_addrparameters CALL SkipSpaces
                    JR   C, no_parameters
                    LD   C,16
                    CALL Get_Constant         ; get DZ address (16bit hex value)
                    RET  C
                    PUSH DE
                    EXX
                    POP  HL                   ; PC ready...
                    EXX
                    CALL SkipSpaces
                    JR   C, no_bank_par
                    LD   C,8                  ; get 8bit hex value...
                    CALL Get_Constant         ; - the bank number
                    RET  C                    ; ups, syntax error
                    LD   B,E                  ; bank number
                    EXX
                    LD   A,H
                    AND  @11000000            ; get segment specifier of DZ address
                    LD   D,A                  ; into D (users logical address for segment)
                    LD   E,$C0                ; bit mask to keep DZ PC in segment 3...
                    SET  7,H
                    SET  6,H                  ; address patched for segment 3
                    EXX
                    CP   A                    ; Fc = 0, signal success
                    RET                       ; Fz = 1, bank B to be bound in appropriate segment

; no parameters specified, use preset address fromm caller...
.no_parameters
.no_bank_par        EXX
                    LD   DE,0                 ; logical address is HL...
                    EXX
                    OR   C                    ; Fc = 0, signal success
                    RET                       ; Fz = 0, signal logical addressing



; **********************************************************************************
;
; Disassemble Z80 instructions
;
; D [<start.addr>] [<bank>]
;
;         <bank>         must be an integer in range [0;255]
;
;         <start.addr>  begin to disassemble from local address <start.addr>
;                       - If <bank> is specified, <startaddr.> defines both offset
;                         within the bank and logical dz. address. If <start.addr> is not
;                         specified, a default logical address of $C000 will be used as
;                         logical disassembly address for that bank.
;                       - If no bank is specified, nor an address, disassembly will
;                        begin at current PC in logical address space.
;                       - If only an address is specified, disassembly will begin at
;                         address in logical address space.
;
.Disasm_param     EXX
                  LD   L,(IY + VP_PC)
                  LD   H,(IY + VP_PC+1)
                  EXX
                  CALL Get_addrparameters   ; setup address parameters in registers
                  RET  C                    ; Ups - syntax error...
                  JR   NZ, Disassemble      ; disassemble in logical address space
                  CALL Save_alternate
                  LD   C, MS_S3
                  CALL_OZ(Os_Mpb)
                  CALL Restore_alternate
                  PUSH BC                   ; remember previous bank number
                  CALL Disassemble          ; start disassembling
                  POP  BC                   ; prev. binding restored
                  CALL_OZ(Os_Mpb)
                  RET



; ****************************************************************************
;
; User disassemble from logical address space or from specified bank.
; This subroutine wil dump the mnemonics 7 lines at a time and then wait for
; a key to be pressed. Any key except <ESC> will continue to disassemble the
; next 8 lines.
;
.Disassemble      LD   B,7
.DZ_loop          PUSH BC
                  CALL DZ_instruction
                  CALL Write_CRLF           ;                                       ** V0.28
                  POP  BC
                  DJNZ, DZ_loop             ; disassemble 7 lines
                  CALL DZ_instruction       ; then the 8' with line feed...         ** V0.28
                  CALL GetKey               ; then wait for a key to be pressed
                  CP   27                   ; is it ESC?
                  JP   Z, Write_CRLF        ; Yes, abort disassembly                ** V0.28
                  CP   9                    ;                                       ** V0.28
                  JR   NZ, more_dz          ; a key was hit, continue disassembly   ** V0.28
                  CALL ToggleWindow         ; clear & activate opposite window      ** V0.28
                  JR   Disassemble          ; continue to disassemble...            ** V0.28
.more_dz          CALL Write_CRLF           ;                                       ** V0.28
                  JR   Disassemble          ;                                       ** V0.28


; ******************************************************************************
;
; Disassemble at the current Z80 PC.
;
.DZ_Z80pc         EXX
                  LD   DE,0                 ; bit masks zeroed = local address...
                  LD   L,(IY + VP_PC        ;                                           ** V0.28
                  LD   H,(IY + VP_PC+1)     ; get PC                                    ** V0.28
                  EXX                       ; (refer to Get_DZ_PC )


; ******************************************************************************
;
; Disassemble the current instruction at disassembler PC.
; V0.17
;
; The instruction is displayed in the current window with a CR to prepare for
; next display information. The PC is displayed before the instruction.
;
; The Disassemble PC is already installed in HL'.
;
.DZ_instruction   CALL Get_DZ_PC
                  SCF
                  CALL IntHexDisp           ; display it in window with hex format
                  LD   A,9
                  CALL Display_char         ; use <TAB> to separate address and mnemonic dump...
                  JP   Display_instruction  ; now disassemble the current instruction opcode



; ******************************************************************************
;
; Disassemble instruction opcode at (PC) and write Mnemonic to current window
; at current cursor position.
; V0.17
;
; Disassemble PC is already installed in HL'.
;
; The subroutine will set up the following registers with:
;
;         Main set:                               Alternate set:
;        -----------------------------------------------------------
;         A: 1. opcode / alternative opcode       A': A@76            instruction group identifier
;         B: IX/IY offset                         B': A@543 -> @210   subgroup/lookup info
;         C: 1. opcode                            C': A@210           subgroup/lookup info
;         D: No. of bytes in instruction
;
; All registers except IY are used.
;
.Display_instruction
                  LD   D,0                  ; initialize instruction opcode counter ** V0.28
                  EXX                       ; use alternate set
                  LD   A,(HL)               ; fetch first opcode at (PC)
                  INC  HL
                  CALL Disp_Opcode          ;                                       ** V0.28
                  CP   $CB                  ; bit manipulation instructions?
                  JP   Z, DZ_CB_instruct    ; Yes...
                  CP   $ED                  ; $ED instructions?
                  JP   Z, DZ_ED_instruct    ; Yes...
                  CP   $DD                  ; IX instruction ?
                  JR   Z, index_opcode
                  CP   $FD                  ; IY instruction ?
                  JR   Z, index_opcode
                  JR   std_instructions

.index_opcode     EXX                       ; use main register set...
                  LD   C,A                  ; 1. opcode in C
                  EXX                       ; use alternate register set...
                  LD   A,(HL)               ; get 2. opcode...
                  INC  HL
                  CALL Disp_Opcode          ;                                       ** V0.28
                  EXX                       ; main set...
                  CP   $CB
                  JR   NZ, std_instr_group  ; now select the instruction group from opcode
.index_CB_opcode  EXX                       ; alternate...
                  LD   A,(HL)               ; get displacement (2. opcode)
                  INC  HL
                  CALL Disp_Opcode          ;                                       ** V0.28
                  EX   AF,AF'               ; temporarily in A'
                  LD   A,(HL)               ; get 3. opcode for CB instruction
                  INC  HL                   ; ready for next instruction
                  CALL Disp_Opcode          ;                                       ** V0.28
                  EXX                       ; back to main register set
                  EX   AF,AF'
                  LD   B,A                  ; displacement installed
                  EX   AF,AF'               ; 2. opcode in A
                  JP   CB_instr_group       ; identify instruction group

; only 1 opcode in instruction ... (standard Z80 instructions)
.std_instructions EXX                       ; std. Z80 instructions (0 - 255)
                  LD   C,A                  ; back to main set, indicate std. instructions
.std_instr_group  CALL Split_opcode         ; differentiate  A -> A', B', C'
                  EX   AF,AF'               ; get instruction group identifier
                  CP   @01000000
                  JP   Z, std_grp_01        ; Grp 01: 8 subgroups...
                  CP   @10000000
                  JP   Z, std_grp_10        ; Grp 10: 8bit register arithmetic
                  CP   @00000000
                  JP   Z, std_grp_00        ; Grp 00: 8 sub groups...
                  EX   AF,AF'               ; Grp 11: back to original opcode
                  EXX                       ; use alternate set temporarily
                  LD   A,C                  ; fetch instruction subgroup (bits 210)
                  EXX                       ; back to main...
                  OR   A
                  JP   Z, RET_cc_grp
                  CP   1
                  JP   Z, std_grp11_sub001  ; variuos instructions...
                  CP   2
                  JP   Z, JP_cc_grp
                  CP   3
                  JP   Z, std_grp11_sub011
                  CP   4
                  JP   Z, CALL_cc_grp
                  CP   5
                  JP   Z, std_grp11_sub101
                  CP   6
                  JP   Z, Arith_n_8bit_grp

; RST instructions...
;
                  EXX                       ; alternate set...
                  LD   A,B
                  EXX                       ; main set...
                  CP   3                    ; RST  18H ?
                  JR   Z, OZ_floatpoint
                  CP   4                    ; RST  20H ?
                  JR   NZ, ordinary_rst
                  EXX                       ; alternate
                  LD   A,(HL)               ; Yes, get first parameter...
                  INC  HL
                  CALL Disp_Opcode          ;                                       ** V0.28
                  CP   $06                  ; 2 byte parameter?
                  JR   Z, get_second_par    ; 'OS_' 2 byte system call
                  CP   $09
                  JR   Z, get_second_par    ; 'GN_' 2 byte system call
                  CP   $0C
                  JR   Z, get_second_par    ; 'DC_' 2 byte system call
                  EXX                       ; 1 byte parameter
                  LD   L,A                  ;
                  SCF                       ; indicate RST  20H instruction parameter
                  JP   Display_OZ_Mnemonic  ;                                       ** V0.28
.get_second_par   EX   AF,AF'               ; low byte parameter in A'
                  LD   A,(HL)               ; high byte in A
                  INC  HL                   ; DZ PC ready for next instruction
                  CALL Disp_Opcode          ;                                       ** V0.28
                  EXX
                  LD   H,A                  ; second parameter
                  EX   AF,AF'
                  LD   L,A
                  SCF                       ; word integer
                  JP   Display_OZ_Mnemonic  ;                                       ** V0.28

.OZ_floatpoint    EXX                       ; RST  18H - OZ floating point operations...
                  LD   A,(HL)               ; get floating point parameter...
                  INC  HL                   ; DZ PC ready for next instruction
                  CALL Disp_Opcode          ;                                       ** V0.28
                  EXX                       ; back to main set...
                  LD   H,0                  ;                                       ** V0.28
                  LD   L,A
                  CP   A                    ; indicate RST  18H instruction parameter
                  JP   Display_OZ_Mnemonic

.ordinary_rst     LD   HL, RST_Mnemonic     ; Sub group 7: RST pp instructions      ** V0.28
                  CALL Display_Mnemonic     ;                                       ** V0.28
                  LD   A,C                  ; get copy of original opcode...        ** V0.28
                  AND  @00111000            ; fetch RST parameter                   ** V0.28
                  LD   L,A                  ;                                       ** V0.28
                  CP   A                    ;                                       ** V0.28
                  JP   IntHexDisp_H         ; write parameter to window             ** V0.28


;
; Z80 instructions 0 - 255, 01 group:
;
;         LD   r,r'
;         LD   r,(HL)
;         LD   (HL),r
;         HALT
;
.std_grp_01       EX   AF,AF'               ; back to original opcode
                  CP   @01110110            ; is it the HALT instruction ?
                  JR   Z, halt_instruction  ; Yes...
                  EXX                       ; use alternate set temporarily
                  LD   A,B                  ; B' - 8 bit destination register...
                  EXX
                  CALL Get_Displacement     ; fetch displacement if index register instruction
                  LD   HL, LD_Mnemonic      ; "LD"
                  CALL Display_Mnemonic
                  CALL Display_8bit_reg     ; display r, (HL), (IX+d) or (IY+d)
                  CALL Display_Comma
                  EXX
                  LD   A,C                  ; get source register
                  EXX
                  JP   Display_8bit_reg

.halt_instruction LD   HL, HALT_Mnemonic
                  JP   Display_Mnemonic

.JP_cc_grp        LD   HL, JP_Mnemonic
.displ_cc_nn      CALL Disp_Opcode_addr     ; display addr. opcode before mnemonic  ** V0.28
                  CALL Display_Mnemonic
                  EXX                       ; display condition code and absolute address
                  LD   A,B                  ; get condition identifier
                  EXX
                  CALL Display_condition    ; A = condition
                  CALL Display_Comma
                  CALL Fetch_nn             ; get nn at (PC)
                  SCF
                  JP   IntHexDisp_H         ; display absolute address

.CALL_cc_grp      LD   HL, CALL_Mnemonic
                  JR   displ_cc_nn

;
;  RET   Z , RET  NZ , RET  C , RET   NC,
;  RET  PO , RET  PE , RET  P , RET   M
;
.RET_cc_grp       LD   HL, RET_Mnemonic
                  CALL Display_Mnemonic
                  EXX
                  LD   A,B                  ; fetch condition identifier
                  EXX
                  JP   Display_condition

;
; ADD  A,n  ADC A,n ; SUB n ; SBC A,n ; AND n ; OR n ; XOR n ; CP n
;
.Arith_n_8bit_grp LD   HL, Arithm_8bit_lookup
                  EXX                           ; alternate
                  LD   A,B
                  EX   AF,AF'
                  LD   A,(HL)                   ; fetch n
                  INC  HL                       ; ready for next instruction
                  CALL Disp_Opcode              ;                                       ** V0.28
                  EX   AF,AF'                   ; save temporarily in A'
                  EXX                           ; main...
                  CALL Fetch_string_ptr
                  CALL Display_Mnemonic
                  OR   A                        ; 'ADD  A,'
                  JR   Z, display_Acc_n
                  CP   1                        ; 'ADC  A,'
                  JR   Z, display_Acc_n
                  CP   3
                  JR   Z, display_Acc_n         ; 'SBC  A,'
                  JR   disp_arith_8bit_n
.display_Acc_n    LD   A, 'A'
                  CALL Display_Char
                  CALL Display_Comma
.disp_arith_8bit_n
                  EX   AF,AF'
                  LD   L,A
                  CP   A
                  JP   IntHexDisp_H


.std_grp11_sub001 EXX
                  LD   A,B                      ; get sub group (instruction)
                  EXX
                  BIT  0,A
                  JR   Z, pop_qq_instr
                  CP   1
                  JR   Z, ret_instruction
                  CP   3
                  JR   Z, exx_instruction
                  CP   5
                  JR   Z, jp_ind_hl_instr
                  LD   HL, LD_Mnemonic          ; 'LD   SP,HL'
                  CALL Display_Mnemonic
                  LD   HL, SP_Mnemonic
                  CALL Display_String
                  CALL Display_Comma
                  JP   Display_HLIXIY

.ret_instruction  LD   HL, RET_Mnemonic
                  JP   Display_Mnemonic

.exx_instruction  LD   HL, EXX_Mnemonic
                  JP   Display_Mnemonic

.jp_ind_hl_instr  LD   HL, JP_Mnemonic
                  CALL Display_Mnemonic
                  LD   A, '('
                  CALL Display_Char
                  CALL Display_HLIXIY
                  LD   A, ')'
                  JP   Display_Char

.pop_qq_instr     EXX
                  LD   A,B
                  EXX
                  LD   HL, POP_Mnemonic
                  CALL Display_Mnemonic
                  JP   get_push_reg

.std_grp11_sub011 EXX
                  LD   A,B
                  EXX
                  OR   A                        ; JP nn ?
                  JR   Z, JP_instruction
                  CP   2
                  JR   Z, out_n_a_instr
                  CP   3
                  JR   Z, in_a_n_instr
                  CP   4
                  JR   Z, ex_sp_hl_instr
                  CP   5
                  JR   Z, ex_de_hl_instr
                  CP   6
                  JR   Z, DI_instruction
                  LD   HL, EI_Mnemonic
                  JP   Display_Mnemonic

.out_n_a_instr    CALL Disp_Opcode_n            ; display opcode byte before mnemonic   ** V0.28
                  LD   HL, OUT_Mnemonic
                  CALL Display_Mnemonic
                  CALL Display_port_n
                  CALL Display_Comma
                  LD   A, 'A'
                  JP   Display_Char

.in_a_n_instr     CALL Disp_Opcode_n            ;                                       ** V0.28
                  LD   HL, IN_Mnemonic
                  CALL Display_Mnemonic
                  LD   A, 'A'
                  CALL Display_Char
                  CALL Display_Comma
.Display_port_n   LD   A, 40
                  CALL Display_Char
                  EXX
                  LD   A,(HL)
                  INC  HL                       ; DZ P ready for next instr.
                  EXX
                  LD   L,A
                  CP   A
                  CALL IntHexDisp_H
                  LD   A, 41
                  JP   Display_Char

.DI_instruction   LD   HL, DI_Mnemonic
                  JP   Display_Mnemonic

.JP_instruction   CALL Disp_Opcode_addr         ; display addr. opcode before mnemonic  ** V0.28
                  LD   HL, JP_Mnemonic
                  CALL Display_Mnemonic
                  JR   disp_call_addr

.ex_sp_hl_instr   LD   HL, EX_Mnemonic
                  CALL Display_Mnemonic
                  LD   A, 40
                  CALL Display_Char
                  LD   HL, SP_Mnemonic
                  CALL Display_String
                  LD   A, 41
                  CALL Display_Char
                  CALL Display_Comma
                  JP   Display_HLIXIY

.ex_de_hl_instr   LD   HL, EX_Mnemonic
                  CALL Display_Mnemonic
                  LD   HL, DE_Mnemonic
                  CALL Display_String
                  CALL Display_Comma
                  LD   HL, HL_Mnemonic
                  JP   Display_String

.std_grp11_sub101 EXX
                  LD   A,B
                  EXX
                  BIT  0,A
                  JR   NZ, call_instruction
                  LD   HL, PUSH_Mnemonic
                  CALL Display_Mnemonic
.get_push_reg     SRL  A                        ; register opcode 0 - 3
                  CP   2
                  JR   Z, push_hlixiy
                  CP   3
                  JR   Z, push_af
                  LD   HL, reg16_lookup
                  CALL Fetch_string_ptr
                  JP   Display_String
.push_hlixiy      JP   Display_HLIXIY
.push_af          LD   HL, AF_Mnemonic
                  JP   Display_String

.call_instruction CALL Disp_Opcode_addr         ; display addr. opcode before mnemonic  ** V0.28
                  LD   HL, CALL_Mnemonic
                  CALL Display_Mnemonic
.disp_call_addr   CALL Fetch_nn                 ; get nn at (PC)
                  SCF
                  JP   IntHexDisp_H             ; display CALL address

.std_grp_00       EX   AF,AF'                   ; restore opcode
                  EXX                           ; alternate set...
                  LD   A,C                      ; fetch subgroup identifier
                  EXX
                  OR   A
                  JR   Z, std_grp00_sub000
                  CP   1
                  JP   Z, std_grp00_sub001
                  CP   2
                  JP   Z, ld_acc_indirect
                  CP   3
                  JP   Z, IncDec_16bit
                  CP   4
                  JP   Z, Inc_8bit
                  CP   5
                  JP   Z, Dec_8bit
                  CP   6
                  JP   Z, Ld_r_8bit_n
                  EXX
                  LD   A,B                      ; sub group 7: Rotate & Shift accumulator
                  EXX                           ;              CCF, SCF
                  LD   HL, RotShift_Acc_lookup
                  CALL Fetch_string_ptr         ; get pointer to instruction Mnemonic
                  JP   Display_Mnemonic

.std_grp00_sub000 EXX
                  LD   A,B
                  EXX
                  OR   A
                  JR   Z, NOP_instruction
                  CP   1
                  JR   Z, ex_af_instruction
                  CP   2
                  JR   Z, djnz_instruction
                  CP   3
                  JR   Z, JR_e_instruction
                  CALL Disp_Opcode_n            ;                                       ** V0.28
                  LD   HL, JR_Mnemonic
                  CALL Display_Mnemonic
                  RES  2,A                      ; get condition code
                  CALL Display_condition
                  CALL Display_Comma
                  JR   display_e_jump

.djnz_instruction CALL Disp_Opcode_n            ;                                       ** V0.28
                  LD   HL, DJNZ_Mnemonic
                  CALL Display_Mnemonic
                  JR   display_e_jump

.JR_e_instruction CALL Disp_Opcode_n            ;                                       ** V0.28
                  LD   HL, JR_Mnemonic
                  CALL Display_Mnemonic
.display_e_jump   EXX
                  LD   A,(HL)
                  INC  HL                       ; get relative jump e
                  EXX
                  CALL Get_DZ_PC                ; PC (calculated to logical address if
                  LD   C,A                      ; prepare for calculation               ** V1.03
                  RLA                           ;                                       ** V1.04
                  SBC  A,A                      ;                                       ** V1.04
                  LD   B,A                      ; sign-extend offset                    ** V1.03
                  ADD  HL,BC                    ; jump calculated
.disp_reladdress  SCF
                  JP   IntHexDisp_H             ; display relative jump address


.NOP_instruction  LD   HL, NOP_Mnemonic
                  JP   Display_Mnemonic

.ex_af_instruction LD  HL, EX_Mnemonic
                  CALL Display_Mnemonic
                  LD   HL, AF_Mnemonic
                  PUSH HL
                  CALL Display_String
                  CALL Display_Comma
                  POP  HL
                  CALL Display_String
                  LD   A, '''
                  JP   Display_Char

.std_grp00_sub001 EXX
                  LD   A,B
                  EXX
                  BIT  0,A
                  JR   Z, ld_dd_nn
                  LD   HL, ADD_Mnemonic         ; ADD  HL, ss
                  CALL Display_Mnemonic
                  CALL Display_HLIXIY
                  CALL Display_Comma
                  SRL  A
                  CP   2
                  JR   Z, displ_ss_hlixiy
                  LD   HL, reg16_lookup
                  CALL Fetch_string_ptr
                  JP   Display_String
.displ_ss_hlixiy  JP   Display_HLIXIY

.ld_dd_nn         CALL Disp_Opcode_addr         ;                                   ** V0.28
                  LD   HL, LD_Mnemonic
                  CALL Display_Mnemonic
                  SRL  A
                  CP   2
                  CALL Z, Display_HLIXIY
                  JR   Z, displ_ld_dd_nn
                  LD   HL, reg16_lookup
                  CALL Fetch_string_ptr
                  CALL Display_String
.displ_ld_dd_nn   CALL Display_Comma
                  CALL Fetch_nn                 ; fetch nn at (PC)
                  SCF
                  JP   IntHexDisp_H             ; display nn.

.ld_acc_indirect  EXX
                  LD   A,B
                  EXX
                  BIT  2,A
                  JP   Z, ld_ind_reg16_acc
                  CALL Disp_Opcode_addr         ;                                   ** V0.28
                  LD   HL, LD_Mnemonic
                  CALL Display_Mnemonic
                  CP   4
                  JR   Z, ld_indd_hl
                  CP   5
                  JR   Z, ld_hl_indd
                  CP   6
                  JR   Z, ld_indd_acc
                  LD   A, 'A'
                  CALL Display_Char
                  CALL Display_Comma
                  JP   displ_indd_nn            ; LD   A,(nn)

.ld_indd_acc      CALL displ_indd_nn
                  CALL Display_Comma
                  LD   A, 'A'
                  JP   Display_Char             ; LD   (nn),A

.ld_hl_indd       CALL Display_HLIXIY
                  CALL Display_Comma
                  JP   displ_indd_nn            ; LD   HL,(nn)

.ld_indd_hl       PUSH BC
                  CALL displ_indd_nn            ; C is destroyed...
                  CALL Display_Comma
                  POP  BC                       ; restore 1. opcode...
                  JP   Display_HLIXIY           ; LD   (nn),HL

.displ_indd_nn    CALL Fetch_nn
                  JP   Disp_nn_indd             ; '(nn)'

.ld_ind_reg16_acc LD   HL, LD_Mnemonic          ;                                 ** V0.28
                  CALL Display_Mnemonic         ;                                 ** V0.28
                  BIT  0,A
                  JR   Z, ind_reg16_acc         ; LD   (BC),A  ;   LD   (DE),A
                  CALL disp_accumulator
                  CALL Display_Comma
                  JP   Displ_ind_reg16          ; LD   A,(BC)  ;   LD   A,(DE)
.ind_reg16_acc    CALL Displ_ind_reg16
                  CALL Display_Comma
.disp_accumulator EX   AF,AF'
                  LD   A, 'A'
                  CALL Display_Char
                  EX   AF,AF'
                  RET

.Displ_ind_reg16  EX   AF,AF'
                  LD   A, 40
                  CALL Display_Char
                  EX   AF,AF'
                  SRL  A
                  LD   HL,reg16_lookup
                  CALL Fetch_string_ptr
                  CALL Display_String
                  LD   A, 41
                  JP   Display_Char

.IncDec_16bit     EXX
                  LD   A,B
                  EXX
                  BIT  0,A
                  JR   Z, inc_ss_instr
                  LD   HL, DEC_Mnemonic
                  JR   disp_ss_instr
.inc_ss_instr     LD   HL, INC_Mnemonic
.disp_ss_instr    CALL Display_Mnemonic
                  SRL  A                        ; opcode in range 0 - 3
                  CP   2
                  JR   Z, inc_hlixiy
                  LD   HL, reg16_lookup
                  CALL Fetch_string_ptr
                  JP   Display_String
.inc_hlixiy       JP   Display_HLIXIY


.Inc_8bit         LD   HL, INC_Mnemonic
.disp_inc_8bit_r  CALL Get_Displacement         ; fetch displacement if index register instruction
                  CALL Display_Mnemonic
                  EXX
                  LD   A,B
                  EXX
                  JP   Display_8bit_reg

.Dec_8bit         LD   HL, DEC_Mnemonic
                  JR   disp_inc_8bit_r


.Ld_r_8bit_n      LD   HL, LD_Mnemonic
                  CALL Get_Displacement         ; fetch displacement if index register instruction
                  CALL Disp_Opcode_n            ;                                   ** V0.28
                  CALL Display_Mnemonic
                  EXX
                  LD   A,B
                  EX   AF,AF'
                  LD   A,(HL)                   ; get n
                  INC  HL                       ; DZ PC ready for next instruction
                  EX   AF,AF'
                  EXX
                  CALL Display_8bit_reg
                  CALL Display_Comma
                  EX   AF,AF'
                  LD   L,A
                  CP   A
                  JP   IntHexDisp_H


.std_grp_10       CALL Get_Displacement         ; fetch displacement if index reg instr ** V0.28
                  LD   HL, Arithm_8bit_lookup
                  EXX
                  LD   A,B                      ; get instruction identifier
                  EXX
                  CALL Fetch_string_ptr
                  CALL Display_Mnemonic         ; display 'ADD', 'ADC', 'SUB' ...
                  OR   A                        ; 'ADD  A,'
                  JR   Z, display_Acc
                  CP   1                        ; 'ADC  A,'
                  JR   Z, display_Acc
                  CP   3
                  JR   Z, display_Acc           ; 'SBC  A,'
                  EXX                           ; use alternate set temporarily         ** V0.28
                  LD   A,C                      ; C' - 8 bit source register...         ** V0.28
                  EXX                                                               ** V0.28
                  JP   display_8bit_reg

.display_Acc      LD   A, 'A'
                  CALL Display_Char
                  CALL Display_Comma
.disp_arith_8bit  EXX                           ; use alternate set temporarily
                  LD   A,C                      ; C' - 8 bit source register...
                  EXX
                  JP   Display_8bit_reg         ; display r, (HL), (IX+d) or (IY+d)


;
; CB .. instructions:
;
;         BIT  b,r  (HL)
;         RES  b,r  (HL)
;         SET  b,r  (HL)
;         RLC, RRC, RL, RR, SLA, SRA, SLL & SRL
;
.DZ_CB_instruct   LD   A,(HL)                   ; get 2. opcode
                  INC  HL                       ; ready for next instruction
                  CALL Disp_Opcode              ;                                       ** V0.28
                  EXX                           ; Z80 instructions (0 - 255)
                  LD   C,A                      ; back to main set, indicate std. $CB instruction
.CB_instr_group   CALL Split_opcode             ; differentiate  A -> A', B', C'
                  EX   AF,AF'                   ; get instruction group identifier
                  CP   @00000000
                  JP   Z, CB_grp_00             ; Grp 00: Rotate instructions
                  CP   @01000000
                  JP   Z, CB_grp_01             ; Grp 01: BIT b,r instructions
                  CP   @10000000
                  JP   Z, CB_grp_10             ; Grp 10: RES b,r instructions

                  LD   HL, SET_Mnemonic         ; Grp 11: SET b,r instructions
                  JR   disp_bit_param

.CB_grp_00        EXX
                  LD   A,B                      ; get instruction id.
                  EXX                           ; main set...
                  LD   HL, RotShift_CB_lookup   ; RLC, RRC, RL, RR, SLA, SRA, SLL & SRL
                  CALL Fetch_string_ptr
                  CALL Display_Mnemonic
                  JR   fetch_8bit_reg           ; 'r' or '(HL)'

.CB_grp_01        LD   HL, BIT_Mnemonic         ; Grp 01: BIT b,r instructions
                  JR   disp_bit_param

.CB_grp_10        LD   HL, RES_Mnemonic         ; Grp 11: RES b,r instructions
.disp_bit_param   CALL Display_Mnemonic
                  EXX                           ; alternate set...
                  LD   A,B                      ; get bit number
                  EXX                           ; main set...
                  ADD  A,48                     ; convert to ASCII number
                  CALL Display_Char             ; and display...
                  CALL Display_Comma
.fetch_8bit_reg   EXX
                  LD   A,C                      ; get 8 bit register reference
                  EXX
                  JP   Display_8bit_reg         ; no - 8 bit register...

;
; ED .. instructions
;
.DZ_ED_instruct   LD   A,(HL)                   ; get 2. opcode
                  INC  HL
                  CALL Disp_Opcode              ;                                 ** V0.28
                  EXX                           ; back to main register set...
                  CALL Split_opcode
                  EX   AF,AF'
                  CP   @10000000                ; block instructions?
                  JP   Z, block_instructs
                  CP   @11000000                ;                                 ** V0.18
                  JP   Z, Unknown_instruction         ;                                 ** V0.18
                  EXX
                  LD   A,C                      ; get sub group
                  EXX
                  OR   A
                  JP   Z, in_r_instruct
                  CP   1
                  JP   Z, out_r_instruct
                  CP   2
                  JP   Z, arithm_16bit_hl
                  CP   3
                  JP   Z, ld_16bit_indd
                  CP   4
                  JP   Z, NEG_instruction
                  CP   5
                  JP   Z, ret_interrupt
                  CP   6
                  JP   Z, im_instructions
                  EXX
                  LD   A,B
                  EXX
                  OR   A
                  JR   Z, ld_i_a_instr
                  CP   1
                  JR   Z, ld_r_a_instr
                  CP   2
                  JR   Z, ld_a_i_instr
                  CP   3
                  JR   Z, ld_a_r_instr
                  CP   4
                  JP   Z, rrd_instr
                  CP   5
                  JP   Z, rld_instr
                  JP   Unknown_instruction

.ld_i_a_instr     LD   HL, LD_Mnemonic
                  CALL Display_Mnemonic
                  LD   A, 'I'
                  CALL Display_Char
                  CALL Display_Comma
                  LD   A, 'A'
                  JP   Display_Char

.ld_r_a_instr     LD   HL, LD_Mnemonic
                  CALL Display_Mnemonic
                  LD   A, 'R'
                  CALL Display_Char
                  CALL Display_Comma
                  LD   A, 'A'
                  JP   Display_Char

.ld_a_r_instr     LD   HL, LD_Mnemonic
                  CALL Display_Mnemonic
                  LD   A, 'A'
                  CALL Display_Char
                  CALL Display_Comma
                  LD   A, 'R'
                  JP   Display_Char

.ld_a_i_instr     LD   HL, LD_Mnemonic
                  CALL Display_Mnemonic
                  LD   A, 'A'
                  CALL Display_Char
                  CALL Display_Comma
                  LD   A, 'I'
                  JP   Display_Char

.in_r_instruct    LD   HL, IN_Mnemonic
                  CALL Display_Mnemonic
                  EXX
                  LD   A,B
                  EXX
                  CALL Get_8bit_reg
                  CALL Display_Char
                  CALL Display_Comma

.Disp_C_indd      LD   A, 40
                  CALL Display_Char
                  LD   A, 'C'
                  CALL Display_Char
                  LD   A, 41
                  JP   Display_Char

.out_r_instruct   LD   HL, OUT_Mnemonic
                  CALL Display_Mnemonic
                  CALL Disp_C_indd
                  CALL Display_Comma
                  EXX
                  LD   A,B
                  EXX
                  CALL Get_8bit_reg
                  JP   Display_Char

.rrd_instr        LD   HL, RRD_Mnemonic
                  JP   Display_Mnemonic
.rld_instr        LD   HL, RLD_Mnemonic
                  JP   Display_Mnemonic

.NEG_instruction  EXX
                  LD   A,B
                  EXX
                  OR   A
                  JP   NZ, Unknown_instruction
                  LD   HL, NEG_Mnemonic
                  JP   Display_Mnemonic

.im_instructions
                  EXX
                  LD   A,B                      ; get instruction
                  EXX
                  BIT  2,A
                  JP   NZ, Unknown_instruction
                  CP   1
                  JP   Z, Unknown_instruction         ;                                 ** V0.18
                  LD   HL, IM_Mnemonic
                  CALL Display_Mnemonic
                  OR   A
                  JR   Z, disp_im_instr
                  DEC  A
.disp_im_instr    ADD  A,48
                  JP   Display_Char

.ret_interrupt    EXX
                  LD   A,B
                  EXX
                  OR   A
                  JR   Z, retn_instr
                  CP   1
                  JR   Z, reti_instr
                  JP   Unknown_instruction
.reti_instr       LD   HL, RETI_Mnemonic
                  JP   Display_Mnemonic
.retn_instr       LD   HL, RETN_Mnemonic
                  JP   Display_Mnemonic

.arithm_16bit_hl  EXX
                  LD   A,B
                  EXX
                  BIT  0,A
                  JR   Z, sbc_hl_ss_instr
                  LD   HL, ADC_Mnemonic
                  JR   disp_hl_dd
.sbc_hl_ss_instr  LD   HL, SBC_Mnemonic
.disp_hl_dd       CALL Display_Mnemonic
                  LD   HL, HL_Mnemonic
                  CALL Display_String
                  CALL Display_Comma
                  SRL  A                        ; opcode in range 0 - 3
                  LD   HL, reg16_lookup
                  CALL Fetch_string_ptr
                  JP   Display_String

.ld_16bit_indd    CALL Disp_Opcode_addr         ;                                 ** V0.28
                  LD   HL, LD_Mnemonic
                  CALL Display_Mnemonic
                  EXX
                  LD   A,B
                  EXX
                  CALL Fetch_nn                 ; fetch nn at (PC)
                  PUSH HL
                  BIT  0,A
                  JR   Z, ld_nn_dd_instr
                  SRL  A                        ; opcode in range 0 - 3
                  LD   HL, reg16_lookup
                  CALL Fetch_string_ptr
                  CALL Display_String           ; display dd register
                  CALL Display_Comma
                  POP  HL                       ; get nn
                  JP   Disp_nn_indd
.ld_nn_dd_instr   POP  HL
                  CALL Disp_nn_indd             ; '(nn),'
                  CALL Display_Comma
                  SRL  A                        ; opcode in range 0 - 3
                  LD   HL, reg16_lookup
                  CALL Fetch_string_ptr
                  JP   Display_String           ; display dd register


.Disp_nn_indd     PUSH AF
                  LD   A, '('
                  CALL Display_Char
                  SCF
                  CALL IntHexDisp_H             ; display nn
                  LD   A, ')'
                  CALL Display_Char
                  POP  AF
                  RET

.block_instructs  EXX
                  LD   A,C                      ; get sub group
                  EX   AF,AF'
                  LD   A,B                      ; specific instruction
                  EX   AF,AF'
                  EXX
                  EX   AF,AF'
                  BIT  2,A                      ; illegal opcode - not known instruction
                  JP   Z, Unknown_instruction
                  EX   AF,AF'
                  OR   A
                  JR   Z, ld_block_instr
                  CP   1
                  JR   Z, cp_block_instr
                  CP   2
                  JR   Z, in_block_instr
                  CP   3
                  JR   Z, out_block_instr
                  JP   Unknown_instruction

.ld_block_instr   LD   HL, ld_block_lookup
.disp_block_instr EX   AF,AF'
                  RES  2,A                      ; opcode range is 0 - 3
                  CALL Fetch_string_ptr
                  JP   Display_Mnemonic

.cp_block_instr   LD   HL, cp_block_lookup
                  JR   disp_block_instr
.in_block_instr   LD   HL, in_block_lookup
                  JR   disp_block_instr
.out_block_instr  LD   HL, out_block_lookup
                  JR   disp_block_instr


; ******************************************************************************
;
; IN: A = 1. opcode  or alternate opcode
;
; Split opcode bits 76, 543, 210 into A', B' & C'
;
; Register status after return:
;
;       MAIN:          ALTERNATE:
;       AFBCDEHL/IXIY  ....DEHL  same
;       ......../....  AFBC....  different
;
.Split_opcode     PUSH AF
                  PUSH DE
                  PUSH BC
                  LD   D,A                  ; copy of opcode
                  AND  @11000000            ; mask out bits 543210
                  EX   AF,AF'               ; A' ready...
                  LD   A,D
                  AND  @00111000            ; mask out bits 76, 210
                  RRCA
                  RRCA
                  RRCA                      ; move bits into 210
                  LD   B,A
                  LD   A,D
                  AND  @00000111            ; mask out bits 76543
                  LD   C,A
                  PUSH BC
                  EXX
                  POP  BC                   ; BC' installed
                  EXX
                  POP  BC
                  POP  DE
                  POP  AF
                  RET


; ******************************************************************************
;
; Fetch 16 bit address at (PC) (disassemble PC)
;
.Fetch_nn         EXX                       ; use alternate register set
                  PUSH HL
                  INC  HL
                  INC  HL                   ; PC ready for next instruction
                  EXX                       ; back to main register set
                  POP  HL                   ; get PC
                  LD   E,(HL)
                  INC  HL
                  LD   D,(HL)
                  EX   DE,HL                ; HL = nn
                  RET


; ******************************************************************************
;
; Get Disassemble PC calculated to display the correct logical address if
; disassembly is currently processing on extended addresses.
;
; This subroutine is only used to display the correct disassembly PC and at
; JR address calculation (JR e // JR  cc, e // DJNZ,e).
;
; If an external bank is switched in for disassembly, E contains segment specifier
; (which is always OR'ed into PC). This assures that disassembly
; doesn't leave the switched-in bank at that segment.
; If no external bank disassembly is currently executed, E = 0 to indicate
; logical address space disassembly. Please note, that OR E on PC has no effect if E = 0...
;
; HL affected on return.
;
.Get_DZ_PC        EX   AF,AF'               ; AF will not be affected
                  EXX                       ; get alternate register set...
                  XOR  A
                  CP   E
                  PUSH HL
                  EXX
                  POP  HL
                  JR   Z, logical_address   ; logical addressing, return...
                  EXX
                  LD   A,H                  ; get high byte of PC
                  AND  @00111111            ; mask out segment of PC and
                  OR   E                    ; keep PC in sgmt E , else
                  LD   H,A                  ; with E = 0, disassembly addr, as normal...
                  AND  @00111111            ; mask out segment of PC and
                  OR   D                    ; mask in segment from D
                  PUSH HL
                  EXX                       ; get main register set...
                  POP  HL                   ; and PC
                  LD   H,A
.logical_address  EX   AF,AF'               ; AF restored
                  RET


; ******************************************************************************
; V0.28
; Display opcode byte (in A) as HEX Ascii (without trailing 'h')
; Routine always called with alternate set active.
; D is increased to identify another displayed opcode byte
;
;       A.BC.EHL/IXIY  same
;       .F..D.../....  different
;
.Disp_Opcode      BIT  Flg_DZopcode, (IY + FlagStat3)
                  RET  Z                    ; Don't display instruction opcodes   ** V1.02
                  EXX                       ; use main set...
                  PUSH HL
                  PUSH DE
                  PUSH BC
                  PUSH AF
                  LD   L,A                  ; get opcode in L
                  CP   A                    ; display 8bit Hex Ascii
                  CALL IntHexDisp           ; without trailing 'h'
                  LD   A,32
                  CALL Display_char
                  POP  AF
                  POP  BC
                  POP  DE
                  INC  D                    ; displayed another opcode byte
                  POP  HL
                  EXX                       ; back to alternate
                  RET


; ******************************************************************************
; V0.28
; Display two bytes (the opcode address) as HEX Ascii (without trailing 'h')
; Routine always called with main set active.
; DZ PC is not modified
;
.Disp_Opcode_addr EXX                       ; use alternate
                  PUSH AF                   ;
                  LD   A,(HL)               ;  get low byte nn
                  CALL Disp_Opcode          ;
                  INC  HL                   ;
                  LD   A,(HL)               ;  get low byte nn
                  CALL Disp_Opcode          ;
                  DEC  HL                   ;  restore DZ PC
                  POP  AF                   ;
                  EXX                       ; back to main...
                  RET


; ******************************************************************************
;
; Display 2.opcode (8bit value; either JR offset or constant) as HEX Ascii (without trailing 'h')
; Routine always called with main set active.
; DZ PC is not modified
;
.Disp_Opcode_n    EXX                       ;  use alternate
                  PUSH AF
                  LD   A,(HL)               ;  get n
                  CALL Disp_Opcode
                  POP  AF
                  EXX
                  RET


; ******************************************************************************
;
; Display Mnemonic. This routine also executes the appropriate tabulates to
; align for operands, etc...
;
.Display_Mnemonic PUSH AF
                  PUSH BC
                  PUSH DE
                  PUSH HL                   ; remember ptr to Mnemonic
                  BIT  Flg_DZopcode, (IY + FlagStat3)
                  JR   Z, disp_mnemonic     ; no opcodes displayed...               ** V1.02
                  LD   A,4
                  SUB  D
                  JR   Z, disp_mnemonic     ; 4 opcodes displayed, no tabulate...   ** V0.28
                  LD   B,A                  ; missing opcodes (to 4)
                  XOR  A
.calc_tab_loop    ADD  A,3
                  DJNZ calc_tab_loop        ; 3 * <missing opcodes>
                  LD   B,A
                  CALL Display_Spaces       ; tabulate until Mnemonic field.
.disp_mnemonic    CALL Display_String       ; display instruction mnemonic
                  DEC  HL                   ; point at last character
                  POP  DE                   ; get ptr to start of string
                  SBC  HL,DE                ; HL = length of string
                  LD   A,4                  ; always minimum 1 space between
                  SUB  L                    ; mnemonic and operand...
                  LD   B,A                  ; number of spaces to print
                  CALL Display_Spaces
                  POP  DE
                  POP  BC
                  POP  AF
                  RET

.Display_Spaces   LD   A, 32
.disp_spaces_loop CALL Display_Char
                  DJNZ, display_spaces      ; cursor position ready for operand
                  RET



; ******************************************************************************
;
; Display a comma at current cursor position in current window
; (Only called by disassembler)
; V0.17
;
; IX different on return
;
.Display_Comma    PUSH AF
                  LD   A, ','
                  CALL Display_Char
                  POP  AF
                  RET


; ******************************************************************************
;
; Display 8 bit register, '(HL)', '(IX+d)' or '(IY+d)'
;
; IN:     A = 3 bit identifier (0 - 7)
;
.Display_8bit_reg CP   6
                  JR   Z, indirect_hl
                  CALL Get_8bit_reg         ; r -> 'A', 'B', ...
                  JP   Display_Char         ; display register
.indirect_hl
;
; Display '(HL)', '(IX+d)' or '(IY+d)'
;
; B, HL, IX different on return
;
                  PUSH AF                   ; opcode must be intact
                  LD   A, '('
                  CALL Display_Char
                  LD   A,C                  ; get 1. opcode
                  CP   $DD
                  JR   Z, IX_indirect_disp
                  CP   $FD
                  JR   Z, IY_indirect_disp
                  LD   HL, HL_Mnemonic
                  CALL Display_String
                  LD   A, ')'
                  CALL Display_Char
                  POP  AF
                  RET
.IX_indirect_disp LD   HL, IX_Mnemonic
                  CALL Display_String
                  JR   test_offset
.IY_indirect_disp LD   HL, IY_Mnemonic
                  CALL Display_String
.test_offset      BIT  7,B                  ; negative displacement?
                  JR   Z, positive_offset   ; no...
                  LD   A,B
                  NEG                       ; convert to positive number
                  LD   B,A
                  LD   A, '-'
                  JR   display_displ
.positive_offset  LD   A, '+'
.display_displ    CALL Display_Char
                  LD   L,B                  ; now display displacement value
                  CP   A
                  CALL IntHexDisp_H
                  LD   A, ')'
                  CALL Display_Char
                  POP  AF
                  RET


; ******************************************************************************
;
; Display condition code : 'Z' , 'NZ' , 'C' , 'NC' , 'PO' , 'PE' , 'P' , 'M'
;
; IN : A = opcode 0 - 7
;
.Display_condition PUSH HL
                  LD   HL, cc_table
                  CALL Fetch_string_ptr
                  CALL Display_String       ; display condition
                  POP  HL
                  RET


; ******************************************************************************
;
; Get displacement for IX IY indirect addressing with offset, in B
; This subroutine is only used by the main disassembled instruction set
; using (HL), (IX+d) or (IY+d). It is NOT called from $CB group, since the
; displacement already has been fetched there.
;
.Get_Displacement PUSH AF
                  LD   A,C
                  CP   $DD
                  JR   Z, fetch_3_opcode
                  CP   $FD
                  JR   Z, fetch_3_opcode
                  POP  AF                   ; normal HL related instruction,
                  RET                       ; don't fetch displacement...
.fetch_3_opcode   EXX
                  LD   A,(HL)               ; get displacement.
                  INC  HL
                  CALL Disp_Opcode          ;                                       ** V0.28
                  EXX
                  LD   B,A
                  POP  AF
                  RET


; ******************************************************************************
;
; Display 'HL', 'IX' or 'IY'
;
; This subroutine is only called by those instructions which also uses the
; IX, IY variation, but NOT with displacement, since only the index registers
; are used.
;
.Display_HLIXIY   PUSH AF
                  LD   A,C                  ; get 1. opcode
                  CP   $DD
                  JR   Z, displ_ix_reg
                  CP   $FD
                  JR   Z, displ_iy_reg
                  LD   HL, HL_Mnemonic
.disp_16bit_reg   CALL Display_String
                  POP  AF
                  RET
.displ_ix_reg     LD   HL, IX_Mnemonic
                  JR   disp_16bit_reg
.displ_iy_reg     LD   HL, IY_Mnemonic
                  JR   disp_16bit_reg


; ******************************************************************************
;
; Fetch string pointer in lookup table, defined by an index register
; V0.17
;
;  IN:    HL  base pointer to lookup table of string pointers.
;         A   index to element of string pointer in table.
; OUT:    HL  string pointer stored at index.
;
; HL different on return.
;
.Fetch_string_ptr PUSH AF
                  PUSH DE                   ;                                       ** V0.28
                  LD   D,0
                  LD   E,A
                  SLA  E                    ; 2*E
                  ADD  HL,DE
                  LD   E,(HL)
                  INC  HL
                  LD   D,(HL)
                  EX   DE,HL                ; HL = string pointer
                  POP  DE                                                           ** V0.28
                  POP  AF
                  RET


; ******************************************************************************
;
; Get 8 bit register from lookup index in A
;
; Returns ASCII char of 8 bit register
;
; AF different on return
;
.Get_8bit_reg     PUSH HL
                  PUSH DE
                  LD   HL, reg8_Mnemonic
                  LD   D,0
                  LD   E,A                  ; 8 bit destination register
                  ADD  HL,DE
                  LD   A,(HL)
                  POP  DE
                  POP  HL
                  RET


; ***********************************************************************************
;
; Display an RST  18H/20H OZ mnemonic parameter as defined in Z88 Developers notes V2
;
; IN:     HL = OZ parameter opcode.
;         Fc = 0, RST $18, FPP parameter
;
.Display_OZ_Mnemonic
                  PUSH HL                   ; preserve OZ parameter                 ** V0.28
                  PUSH AF                   ;                                       ** V0.28
                  LD   HL, RST_Mnemonic     ; Sub group 7: RST pp instructions      ** V0.28
                  CALL Display_Mnemonic     ;                                       ** V0.28
                  LD   A,C                  ; get copy of original opcode...        ** V0.28
                  AND  @00111000            ; fetch RST parameter                   ** V0.28
                  LD   L,A                  ;                                       ** V0.28
                  CP   A                    ;                                       ** V0.28
                  CALL IntHexDisp_H         ; write parameter to window             ** V0.28
                  CALL Display_comma        ;                                       ** V0.28
                  LD   A, '['
                  CALL Display_Char
                  POP  AF
                  POP  HL                   ; restore OZ parameter                  ** V0.28
                  PUSH HL                   ; preserve OZ parameter
                  LD   A,L                  ; low byte of parameter
                  JR   NC, get_FP_mnemonic
                  CP   $06
                  JR   Z, get_OS_2byte_mnemonic  ; 'OS_' 2 byte system parameter
                  CP   $09
                  JR   Z, get_GN_mnemonic   ; 'GN_' 2 byte system parameter
                  CP   $0C
                  JR   Z, get_DC_mnemonic   ; 'DC_' 2 byte system parameter

                  POP  HL                   ;                                       ** V0.32
                  LD   H,0                  ;                                       ** V0.32
                  PUSH AF                   ; preserve parameter for OS_POUT check
                  LD   DE,check_OS_POUT
                  PUSH DE                   ; RET to OS_POUT check before main DZ loop
                  PUSH HL                   ;                                       ** V0.32
                  LD   HL, OS_Mnemonic      ; 'OS_' 1 byte system parameter
                  LD   IX, OS_1byte_lookup
                  JR   get_OZ_mnemonic
.check_OS_POUT                              ; which 1 byte OZ call mnemonic was displayed?
                  POP  AF
                  CP   $93
                  RET  NZ
.skip_vdu_string                            ; displayed OZ call was OS_POUT, find next instr..
                  EXX
                  LD   A,(HL)
                  INC  HL
                  EXX
                  OR   A
                  JR   NZ,skip_vdu_string   ; skip OS_POUT VDU string and be ready
                  RET                       ; for next instruction..

.get_OS_2byte_mnemonic
                  LD   A,H                  ; get 2. parameter                      ** V0.28
                  LD   HL, OS_Mnemonic
                  LD   IX, OS_2byte_lookup
                  JR   get_OZ_mnemonic

.get_GN_mnemonic  LD   A,H                  ; get 2. parameter                      ** V0.28
                  LD   HL, GN_Mnemonic
                  LD   IX, GN_lookup
                  JR   get_OZ_mnemonic

.get_DC_mnemonic  LD   A,H                  ; get 2. parameter                      ** V0.28
                  LD   HL, DC_Mnemonic
                  LD   IX, DC_lookup
                  JR   get_OZ_mnemonic

.get_FP_mnemonic  LD   HL, FP_Mnemonic
                  LD   IX, FP_lookup

.get_OZ_mnemonic  PUSH IX                   ; only IX is destroyed with display...
                  CALL Display_String       ; display OZ identifier ('OS', 'DC', 'GN', 'FP')
                  PUSH AF                   ; preserve OZ parameter
                  LD   A,'_'
                  CALL Display_Char
                  POP  AF
                  POP  IX                   ; restore base of mnemonic table...

                  CP   (IX+1)               ; check legal parameter boundary
                  JR   C, par_not_defined   ; parameter < low boundary
.check_par_high   CP   (IX+2)
                  JR   C, check_legal_par   ; parameter < high boundary, test if legal
                  JR   NZ, par_not_defined  ; parameter > high boundary
.check_legal_par  LD   H,0                  ; parameter = high boundary
                  SUB  (IX+1)               ; (parameter - low boundary) MOD step = 0
                  LD   L,A                  ; dividend
                  LD   D,0
                  LD   E,(IX+0)             ; divisor (step)
                  EXX
                  PUSH HL                   ; Disassemble PC and memory mask in DE
                  PUSH DE                   ; must be preserved
                  EXX
                  CALL_OZ(Gn_D16)
                  EXX
                  POP  DE
                  POP  HL
                  EXX
                  LD   A,E                  ; get remainder
                  OR   A
                  JR   Z,found_oz_opcode    ; MOD = 0, a legal parameter

.par_not_defined  POP  HL                   ; get OZ parameter...
                  XOR  A                    ;
                  CP   H                    ; Fc = 1 if 2 byte parameter...     ** V0.28
.disp_OZ_constant CALL IntHexDisp_H
                  LD   A,']'
                  JP   Display_Char         ; disassemble next instruction...

.found_oz_opcode  POP  BC                   ; remove original oz parameter
                  LD   BC,3
                  ADD  IX,BC                ; IX = base pointer to table of pointers
                  LD   C,L                  ; parameter in L converted to index of
                  SLA  C                    ; (word) pointer to mnemonic
                  ADD  IX,BC                ; index to pointer of mnemonic calculated
                  LD   E,(IX+0)
                  LD   D,(IX+1)             ; get pointer to mnemonic
                  LD   L,(IX+2)
                  LD   H,(IX+3)             ; get pointer to next mnemonic (to know the end of current)
                  SBC  HL,DE
                  LD   B,L                  ; number of characters in current mnemonic
                  EX   DE,HL                ; HL points to start of mnemonic
.disp_oz_mnemonic LD   A,(HL)
                  INC  HL
                  CALL Display_Char         ; display 2nd part of mnemonic
                  DJNZ disp_oz_mnemonic
                  LD   A, ']'
                  JP   Display_Char


; *******************************************************************
;
; Unknown CB ... and ED ... instructions
;
.Unknown_instruction
                 LD   A, ERR_unknown_instr
                 CALL Get_Errmsg
                 JP   Display_string        ; display error message
