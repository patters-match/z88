
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
                    LD   BC, InstrBreakPatt+1
                    PUSH IY
                    POP  HL
                    ADD  HL,BC
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
.InstrBreakList     PUSH IY
                    POP  HL
                    LD   BC, InstrBreakPatt
                    ADD  HL,BC
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
