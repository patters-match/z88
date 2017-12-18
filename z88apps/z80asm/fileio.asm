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

     MODULE File_manipulation


; external procedures:
     LIB Bind_bank_s1

     XREF ReportError_NULL                                  ; errors.asm

; global constants
     XDEF bufferfile, cdefile

; global procedures in this module:
     XDEF Read_fptr, Write_fptr, Read_string, Write_string
     XDEF ftell, fsize, fseekptr, fseekfwm, fseek0, fseek64k
     XDEF Open_file, Close_file
     XDEF Delete_file
     XDEF Delete_bufferfiles

     INCLUDE "fileio.def"
     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; ****************************************************************************************
;
; Get current file pointer
;
;    IN:    IX = file handle
;   OUT:  DEBC = file pointer
;
; Registers changed after return:
;    ......HL/IXIY  same
;    AFBCDE../....  different
;
.ftell              LD   DE,0
                    LD   A, FA_PTR
                    CALL_OZ(Os_Frm)
                    RET


; ****************************************************************************************
;
; Get size of current file
;
;    IN:    IX = file handle
;   OUT:  DEBC = size of file
;
; Registers changed after return:
;    ......HL/IXIY  same
;    AFBCDE../....  different
;
.fsize              LD   DE,0
                    LD   A, FA_EXT
                    CALL_OZ(Os_Frm)
                    RET


; ****************************************************************************************
;
; Set file pointer via ext.address
;
;    IN:    IX = file handle
;          BHL = pointer to 32bit file position
;           DE = offset
;
;   OUT:   None.
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.fseekptr           PUSH BC
                    PUSH HL
                    ADD  HL,DE               ; add offset to extended pointer
                    LD   A,B
                    CALL Bind_bank_s1        ; bind in file pointer information
                    LD   B,A                 ; old bank binding in B
                    CALL fseekfwm
                    PUSH AF                  ; preserve error flag from OS_FWM
                    LD   A,B
                    CALL Bind_bank_s1        ; restore prev. bank binding
                    POP  AF
                    POP  HL
                    POP  BC
                    RET

; ****************************************************************************************
;
; Set file pointer
;
;    IN:    IX = file handle
;           HL = local pointer to 32bit file position
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.fseekfwm           LD   A, FA_PTR
                    CALL_OZ(Os_Fwm)
                    RET


; ****************************************************************************************
;
; Reset file pointer to beginning of file
;
;    IN:
;           IX = file handle
;   OUT:
;           HL = 0 (always)
;           Fc = 0 (success)
;           Fc = 1, A = RC_xxx (I/O error related)
;
; Registers changed after return:
;    ..BCDE../IXIY  same
;    AF....HL/....  different
;
.fseek0             LD   HL,0


; ****************************************************************************************
;
; Set file pointer within 64K (16bit) range
;
;    IN:    IX = file handle
;           HL = file pointer (16bit)
;
;   OUT:    Fc = 0 (success)
;           Fc = 1, A = RC_xxx (I/O error related)
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.fseek64k           PUSH HL
                    LD   HL,0
                    EX   (SP),HL
                    PUSH HL                       ; 16bit file on stack is XXXX0000
                    LD   HL,0
                    ADD  HL,SP                    ; HL points to XXXX0000 on system stack
                    CALL fseekfwm                 ; reset file pointer to XXXX0000
                    POP  HL
                    INC  SP
                    INC  SP                       ; ignore $0000 on stack
                    RET


; **************************************************************************************************
;
; Write long int (file pointer) to file
;
;    IN:  IX   = handle of file
;         BHL  = pointer to long integer (B=0 means local pointer)
;         DE   = offset (if extended pointer)
;
;    Registers changed after return
;         ..BCDEHL/IXIY  same
;         AF....../....  different
;
.Write_fptr         INC  B
                    DEC  B
                    JR   Z, write_longint
                    LD   A,B
                    CALL Bind_bank_s1
                    PUSH AF
                    PUSH HL
                    ADD  HL,DE                    ; add offset to pointer
                    CALL write_longint
                    POP  HL
                    POP  AF
                    JP   Bind_bank_s1

.write_longint      PUSH BC
                    PUSH HL
                    LD   B,4
.write_long         LD   A,(HL)
                    CALL_OZ(Os_Pb)                ; write file pointer with OS_Pb, not OS_Mv
                    INC  HL
                    DJNZ write_long
                    POP  HL
                    POP  BC
                    RET


; **************************************************************************************************
;
; Read long int (file pointer) to memory
;
;    IN:  IX   = handle of file
;         BHL  = pointer to load long integer (B=0 means local pointer)
;         DE   = offset (if extended pointer)
;
;    Registers changed after return
;         ..BCDEHL/IXIY  same
;         AF....../....  different
;
.Read_fptr          INC  B
                    DEC  B
                    JR   Z, read_longint
                    LD   A,B
                    CALL Bind_bank_s1
                    PUSH AF
                    PUSH HL
                    ADD  HL,DE                    ; add offset to pointer
                    CALL read_longint
                    POP  HL
                    POP  AF
                    JP   Bind_bank_s1

.read_longint       PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   BC,4
                    LD   D,B
                    LD   E,B                      ; DE = 0
                    EX   DE,HL
                    CALL_OZ(Os_Mv)                ; read long int...
                    CALL C, ReportError_NULL
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; **************************************************************************************************
;
; Write string to file
;
;    IN:  IX   = handle of file
;         BHL  = pointer to string (B=0 means local pointer)
;         C    = length of string
;         DE   = offset (if extended pointer, otherwise not used)
;
;    OUT:
;         Fc   = 0, successfully written string to file
;         Fc   = 1, I/O error
;
;    Registers changed after return
;         ..BCDEHL/IXIY  same
;         AF....../....  different
;
.Write_string       INC  B
                    DEC  B
                    JR   Z, write_str             ; local address
                    LD   A,B
                    CALL Bind_bank_s1
                    LD   B,A                      ; B = old bank binding
                    PUSH HL
                    ADD  HL,DE                    ; add offset to pointer
                    CALL write_str
                    POP  HL
                    PUSH AF                       ; preserve errors status
                    LD   A,B
                    CALL Bind_bank_s1
                    LD   B,A                      ; restored original B from pointer
                    POP  AF
                    RET

.write_str          PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   B,0                      ; BC = length of string
                    LD   D,B
                    LD   E,B                      ; DE = 0
                    CALL_OZ(Os_Mv)                ; write string...
                    CALL C, ReportError_NULL
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; **************************************************************************************************
;
; Read string from file into memory
;
;    IN:  IX   = handle of file
;         BHL  = pointer to memory (B=0 means local pointer)
;         C    = length of string
;         DE   = offset (if extended pointer)
;
;    Registers changed after return
;         ..BCDE../IXIY  same
;         AF....HL/....  different
;
.Read_string        INC  B
                    DEC  B
                    JR   Z, read_str
                    LD   A,B
                    CALL Bind_bank_s1
                    PUSH AF
                    ADD  HL,DE                    ; add offset to pointer
                    CALL read_str
                    POP  AF
                    JP   Bind_bank_s1

.read_str           PUSH BC
                    PUSH DE
                    LD   B,0                      ; BC = length of string
                    LD   D,B
                    LD   E,B                      ; DE = 0
                    EX   DE,HL                    ; HL = 0...
                    CALL_OZ(Os_Mv)                ; read string into memory...
                    CALL C, ReportError_NULL
                    EX   DE,HL                    ; HL points at end of string + 1
                    POP  DE
                    POP  BC
                    RET


; ****************************************************************************************
;
; IN BHL = pointer to filename
;    A  = open status
;
; OUT: DE points at explicit file name, null-terminated and length prefixed
;
; Registers changed after return
;    ......HL/..IY  same
;    AFBCDE../IX..  different
;
.Open_file          LD   C,127
                    LD   DE, stringconst+1
                    CALL_OZ(Gn_Opf)
                    RET  C
                    LD   HL, stringconst
                    DEC  C                        ; store length of explicit file name
                    LD   (HL),C                   ; exclusive null-terminator
                    EX   DE,HL
                    RET


; ****************************************************************************************
;
; IN HL = local pointer to file handle
;
; OUT: (HL) = 0, no handle available
;
; Registers changed after return
;    AFBCDE../IXIY  same
;    ......HL/....  different
;
.Close_file         PUSH AF
                    PUSH BC
                    PUSH IX
                    LD   C,(HL)
                    INC  HL
                    LD   B,(HL)
                    LD   A,B
                    OR   C
                    JR   Z, end_closefile              ; no handle available
                    PUSH BC
                    POP  IX
                    CALL_OZ(Gn_Cl)
                    LD   (HL),0
                    DEC  HL
                    LD   (HL),0                        ; no handle available for file...
.end_closefile      POP  IX
                    POP  BC
                    POP  AF
                    RET


; ****************************************************************************************
; Delete any temporary buffer files, before z80asm is completed.
.Delete_bufferfiles LD   B,0
                    LD   HL, bufferfile
                    CALL Delete_file         ; delete ":RAM.-/buf", if it exists...
                    LD   HL, cdefile
                    JP   Delete_file         ; delete ":RAM.-/temp.buf", if it exists...


; ****************************************************************************************************
;
; Delete file
;
;    IN:  BHL = pointer to filename
;
.Delete_file        CALL_OZ(Gn_Del)
                    RET

.bufferfile         DEFM ":RAM.-/buf", 0
.cdefile            DEFM ":RAM.-/temp.buf", 0

