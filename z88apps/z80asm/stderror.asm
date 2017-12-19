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

     MODULE Asm_Errors

     LIB  Bind_bank_s1

     XDEF ReportError, Report_Error, Display_error
     XDEF Get_stdoutp_handle
     XDEF z80asm_Errmsg, Write_stdmessage

     XDEF Errlookup
     XDEF errmsg0, errmsg1, errmsg2, errmsg3, errmsg4, errmsg5, errmsg6
     XDEF errmsg7, errmsg8, errmsg9, errmsg10, errmsg11, errmsg12, errmsg13
     XDEF errmsg14, errmsg15, errmsg16, errmsg17, errmsg18, errmsg19
     XDEF errmsg20, errmsg21, errmsg22, errmsg23, errmsg24, errmsg25
     XDEF errmsg26, errmsg27

     INCLUDE "error.def"
     INCLUDE "syspar.def"
     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "integer.def"

     INCLUDE "rtmvars.def"


; ========================================================================================
;
;    Write error message to error file
;
;    IN:  BHL = pointer to current file, or NULL if no file is referred to
;         DE  = line number in current file, or 0 if no line number is referred to
;         A   = error code (referring to the error message)
;
; Registers changed after return:
;
;    AFBCDEHL/IXIY  same
;    ......../....  different
;
.ReportError
.Report_Error       PUSH IX
                    PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    PUSH AF
                    PUSH DE
                    PUSH BC
                    PUSH HL

                    LD   (ASSEMBLE_ERROR),A            ; save current error code
                    LD   HL,RuntimeFlags3
                    SET  ASMERROR,(HL)                 ; indicate error (use HL, since IY might used by stdlib)

                    LD   HL,(errfilehandle)
                    PUSH HL
                    POP  IX                            ; handle for error file
                    LD   A,H
                    OR   L                             ; error file present?
                    POP  HL
                    POP  BC
                    CALL Z,Get_stdoutp_handle          ; no - get handle for std. output

                    XOR  A
                    CP   B                             ; NULL string?
                    JR   Z, disp_line                  ; Yes - ignore...
                    PUSH HL
                    PUSH BC
                    LD   HL,file_msg
                    CALL Write_stdmessage              ; "In file '"
                    POP  BC
                    POP  HL
                    LD   A,B
                    CALL Bind_bank_s1
                    CALL Write_stdmessage              ; write filename...
                    CALL Bind_bank_s1
                    LD   HL,file2_msg
                    CALL Write_stdmessage              ; "', "

.disp_line          POP  BC
                    LD   A,B
                    OR   C
                    JR   Z, disp_error                 ; no linenumber...
                    PUSH BC
                    LD   HL,line_msg
                    CALL Write_stdmessage              ; "At line "

                    POP  BC                            ; value to convert to ASCII
                    LD   HL,2                          ; indicate value in BC...
                    LD   DE,0                          ; output to stream IX...
                    LD   A,@00000001                   ; no leading zeroes...
                    CALL_OZ(Gn_Pdn)
                    LD   HL,comma_msg
                    CALL Write_stdmessage              ; ", "

.disp_error         POP  AF                            ; get error code
                    CALL Display_error
                    CALL Write_Nln                     ; end message with linefeed

.exit_reporterror   LD   HL,(TOTALERRORS)
                    INC  HL
                    LD   (TOTALERRORS),HL

                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    POP  IX                            ; main registers restored
                    RET


; ==================================================================================================
;
;    Write error message to file (standard output or error file)
;
;    IN:  A = error code
;         IX = file handle
;
;    OUT: None.
;
.Display_error      BIT  7,A
                    JR   NZ, z80asm_error
                                                       ; write system error message
                    CALL_OZ(Gn_Esp)                    ; get pointer to system error message
                    LD   A,B
                    CALL Bind_bank_s1                  ; bind error message into segment 1
                    PUSH AF                            ; preserve previous binding
                    RES  7,H
                    SET  6,H                           ; pointer address into segment 1
                    PUSH HL
                    LD   BC,255
                    XOR  A
                    CPIR
                    POP  DE
                    SBC  HL,DE
                    EX   DE,HL
                    LD   B,D
                    LD   C,E                           ; length of system error message
                    CALL Write_message                 ; write system error message to file...
                    POP  AF                            ; bank number in A
                    CALL Bind_bank_s1                  ; bind bank of system error message
                    RET
.z80asm_error       CP   ERR_totalerrors
                    JR   NZ, write_errmsg
                    PUSH AF
                    LD   A,(TOTALERRORS)               ; total number of errors...
                    LD   B,0
                    LD   C,A
                    LD   HL,2                          ; indicate value in BC...
                    LD   DE,0                          ; output to stream IX...
                    LD   A,@00000001                   ; no leading zeroes...
                    CALL_OZ(Gn_Pdn)
                    POP  AF
.write_errmsg       CALL z80asm_errmsg
                    JP   Write_stdmessage              ; write z80asm errors message to file...


; ==================================================================================================
;
.Get_stdoutp_handle PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   BC, NQ_OHN
                    CALL_OZ(Os_Nq)                     ; get handle in IX for standard output
                    LD   HL, select_win5
                    CALL_OZ(Gn_Sop)                    ; use window#5 to display errors message
                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET


; ==================================================================================================
;
.Write_stdmessage   LD   B,0
                    LD   C,(HL)
                    INC  HL

; ==================================================================================================
;
.Write_message      PUSH AF
                    PUSH DE
                    LD   DE,0                          ; BC = length, HL points at local string
                    CALL_OZ(Os_Mv)                     ; write to file....
                    POP  DE
                    POP  AF
                    RET


; ==================================================================================================
;
.Write_Nln          LD   HL,(errfilehandle)
                    LD   A,H
                    OR   L
                    JR   NZ, write_CR
                         CALL_OZ(Gn_Nln)
                         RET
.write_CR           LD   A, CR
                    CALL_OZ(Os_Pb)
                    RET


; ==================================================================================================
;
; Return pointer to error message from code in A
;
.z80asm_errmsg      LD   HL, Errlookup
                    RES  7,A                              ; remove z80asm error code indicator
                    RLCA                                  ; word boundary
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                            ; HL points at index containing pointer
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                           ; pointer fetched in
                    EX   DE,HL                            ; HL
                    RET


.select_win5        DEFM 1, "2H5",  0                     ; select window "5"
.comma_msg          DEFM 2, ", "
.file_msg           DEFM 9, "In file ", '"'
.file2_msg          DEFM 3, '"', ", "
.line_msg           DEFM 8, "At line "

.Errlookup          DEFW errmsg0
                    DEFW errmsg1
                    DEFW errmsg2
                    DEFW errmsg3
                    DEFW errmsg4
                    DEFW errmsg5
                    DEFW errmsg6
                    DEFW errmsg7
                    DEFW errmsg8
                    DEFW errmsg9
                    DEFW errmsg10
                    DEFW errmsg11
                    DEFW errmsg12
                    DEFW errmsg13
                    DEFW errmsg14
                    DEFW errmsg15
                    DEFW errmsg16
                    DEFW errmsg17
                    DEFW errmsg18
                    DEFW errmsg19
                    DEFW errmsg20
                    DEFW errmsg21
                    DEFW errmsg22
                    DEFW errmsg23
                    DEFW errmsg24
                    DEFW errmsg25
                    DEFW errmsg26
                    DEFW errmsg27
                    DEFW errmsg28
                    DEFW errmsg29
                    DEFW errmsg30


.errmsg0            DEFM errmsg1  - $PC - 1, "File open error"
.errmsg1            DEFM errmsg2  - $PC - 1, "Syntax error"
.errmsg2            DEFM errmsg3  - $PC - 1, "Symbol not defined"
.errmsg3            DEFM errmsg4  - $PC - 1, "No room in Z88"
.errmsg4            DEFM errmsg5  - $PC - 1, "Integer out of range"
.errmsg5            DEFM errmsg6  - $PC - 1, "Syntax error in expression"
.errmsg6            DEFM errmsg7  - $PC - 1, ") missing"
.errmsg7            DEFM errmsg8  - $PC - 1, "Out of range"
.errmsg8            DEFM errmsg9  - $PC - 1, "Source filename missing"
.errmsg9            DEFM errmsg10 - $PC - 1, "Illegal option"
.errmsg10           DEFM errmsg11 - $PC - 1, "Unknown identifier"
.errmsg11           DEFM errmsg12 - $PC - 1, "Illegal identifier"
.errmsg12           DEFM errmsg13 - $PC - 1, "Max 64K code size"
.errmsg13           DEFM errmsg14 - $PC - 1, " errors were found"
.errmsg14           DEFM errmsg15 - $PC - 1, "Symbol already defined"
.errmsg15           DEFM errmsg16 - $PC - 1, "Module name already defined"
.errmsg16           DEFM errmsg17 - $PC - 1, "Module name not defined"
.errmsg17           DEFM errmsg18 - $PC - 1, "Already declared local"
.errmsg18           DEFM errmsg19 - $PC - 1, "Already declared global"
.errmsg19           DEFM errmsg20 - $PC - 1, "Already declared external"
.errmsg20           DEFM errmsg21 - $PC - 1, "No arguments"
.errmsg21           DEFM errmsg22 - $PC - 1, "Illegal source filename"
.errmsg22           DEFM errmsg23 - $PC - 1, "Symbol declared global in another module"
.errmsg23           DEFM errmsg24 - $PC - 1, "Re-declaration not allowed"
.errmsg24           DEFM errmsg25 - $PC - 1, "ORG already set"
.errmsg25           DEFM errmsg26 - $PC - 1, "JR addr. must be local"
.errmsg26           DEFM errmsg27 - $PC - 1, "Not an object file"
.errmsg27           DEFM errmsg28 - $PC - 1, "Reserved name"
.errmsg28           DEFM errmsg29 - $PC - 1, "Not a library file"
.errmsg29           DEFM errmsg30 - $PC - 1, "ORG not defined"
.errmsg30
