
    MODULE Display_Z80registers

    XREF BC_Mnemonic, DE_Mnemonic, HL_Mnemonic, IX_Mnemonic, IY_Mnemonic, SP_Mnemonic, PC_Mnemonic
    XREF Write_CRLF, Display_string, Display_char
    XREF Display_FlagReg
    XREF IntHexDisp_H

    XDEF DisplayRegisters

    INCLUDE "defs.h"


; ********************************************************************************
; Display contents of registers in current window
; Register status after return:
;
;       AFBCDEHL/IXIY  same
;       ......../....  different
;
.DisplayRegisters   PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   HL, RegTable
                    LD   C,(HL)                        ; number of lines to display
                    INC  HL
.line_loop          LD   B,(HL)                        ; number of columns in line
                    INC  HL
.col_loop           PUSH BC
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    INC  HL
                    EX   DE,HL
                    CALL Display_string                ; Register Mnemonic
                    LD   A, '='
                    CALL Display_char                  ; '=' separator
                    EX   DE,HL
                    LD   E,(HL)
                    INC  HL
                    LD   D,0
                    PUSH IY
                    EX   (SP),HL                       ; HL points at base of Intuition area
                    ADD  HL,DE                         ; + register offset
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                        ; register contents
                    POP  HL
                    LD   A,(HL)                        ; size flag of register (in table)
                    INC  HL
                    PUSH HL
                    EX   DE,HL
                    OR   A
                    PUSH AF
                    CALL Z, Display_flagReg            ; size flag = 0, Display Flag register
                    POP  AF
                    JR   Z, next_column
                    RLA
                    CALL IntHexDisp_H                  ; Display integer as ASCII hexadecimal

.next_column        LD   A, 32
                    CALL Display_char                  ; separate this column with next
                    POP  HL

                    POP  BC
                    DJNZ col_loop
                    CALL Write_CRLF                    ; write a new line to window
                    DEC  C
                    JR   NZ, line_loop

                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET


.RegTable           DEFB 5                             ; 5 lines

                    DEFB 3                             ; 3 columns on this line
                    DEFW BC_Mnemonic
                    DEFB VP_BC, 2^7                    ; BC register
                    DEFW BCx_Mnemonic
                    DEFB VP_BCx, 2^7                   ; alternate BC register
                    DEFW A_Mnemonic
                    DEFB VP_AF+1, 2^6                  ; A register

                    DEFB 3
                    DEFW DE_Mnemonic
                    DEFB VP_DE, 2^7                    ; DE register
                    DEFW DEx_Mnemonic
                    DEFB VP_DEx, 2^7                   ; alternate DE register
                    DEFW Ax_Mnemonic
                    DEFB VP_AFx+1, 2^6                 ; alternate A register

                    DEFB 2
                    DEFW HL_Mnemonic
                    DEFB VP_HL, 2^7                    ; HL register
                    DEFW HLx_Mnemonic
                    DEFB VP_HLx, 2^7                   ; alternate HL register

                    DEFB 3
                    DEFW IX_Mnemonic
                    DEFB VP_IX, 2^7                    ; IX register
                    DEFW SP_Mnemonic
                    DEFB VP_SP, 2^7                    ; SP register
                    DEFW F_Mnemonic
                    DEFB VP_AF, 0                      ; F register

                    DEFB 3
                    DEFW IY_Mnemonic
                    DEFB VP_IY, 2^7                    ; IY register
                    DEFW PC_Mnemonic
                    DEFB VP_PC, 2^7                    ; PC register
                    DEFW Fx_Mnemonic
                    DEFB VP_AFx, 0                     ; alternate F register


.A_Mnemonic         DEFM "A",0
.Ax_Mnemonic        DEFM "a",0
.F_Mnemonic         DEFM "F",0
.Fx_Mnemonic        DEFM "f",0
.BCx_Mnemonic       DEFM "bc",0
.DEx_Mnemonic       DEFM "de",0
.HLx_Mnemonic       DEFM "hl",0
.PC_Mnemonic        DEFM "PC",0
