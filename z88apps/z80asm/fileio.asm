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

     XREF FlushBuffer                                       ; bytesio.asm
     XREF ReportError_NULL                                  ; errors.asm
     XREF reloctablefile, bufferfile                        ; reloc.asm
     XREF cdefile                                           ; z80asm.asm

; global procedures in this module:
     XDEF Read_fptr, Write_fptr, Read_string, Write_string
     XDEF ftell, fsize, fseek
     XDEF Open_file, Close_file, Close_files, Copy_file
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
; Set file pointer
;
;    IN:    IX = file handle
;          BHL = pointer to vektor (B=0 is local pointer)
;           DE = offset, if extended pointer
;
;   OUT:   None.
;
; Registers changed after return:
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.fseek              XOR  A
                    CP   B
                    JR   Z, set_fpointer
                         PUSH BC
                         PUSH HL
                         ADD  HL,DE               ; add offset to extended pointer
                         LD   A,B
                         CALL Bind_bank_s1        ; bind in file pointer information
                         LD   B,A                 ; old bank binding in B
                         CALL Set_fpointer
                         PUSH AF                  ; preserve error flag from OS_FWM
                         LD   A,B
                         CALL Bind_bank_s1        ; restore prev. bank binding
                         POP  AF
                         POP  HL
                         POP  BC
                         RET

.set_fpointer       LD   A, FA_PTR
                    CALL_OZ(Os_Fwm)
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
.Write_fptr         LD   A,B
                    CP   0
                    JR   Z, write_longint
                    CALL Bind_bank_s1
                    PUSH AF
                    PUSH HL
                    ADD  HL,DE                    ; add offset to pointer
                    CALL write_longint
                    POP  HL
                    POP  AF
                    CALL Bind_bank_s1
                    RET

.write_longint      PUSH BC
                    PUSH HL
                    LD   B,4
.write_long         LD   A,(HL)
                    CALL_OZ(Os_Pb)
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
.Read_fptr          LD   A,B
                    CP   0
                    JR   Z, read_longint
                    CALL Bind_bank_s1
                    PUSH AF
                    PUSH HL
                    ADD  HL,DE                    ; add offset to pointer
                    CALL read_longint
                    POP  HL
                    POP  AF
                    CALL Bind_bank_s1
                    RET
.read_longint       PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   BC,4
                    LD   DE,0
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
;         DE   = offset (if extended pointer)
;
;    Registers changed after return
;         ..BCDEHL/IXIY  same
;         AF....../....  different
;
.Write_string       LD   A,B
                    CP   0
                    JR   Z, write_str
                    CALL Bind_bank_s1
                    PUSH AF
                    PUSH HL
                    ADD  HL,DE                    ; add offset to pointer
                    CALL write_str
                    POP  HL
                    POP  AF
                    CALL Bind_bank_s1
                    RET
.write_str          PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   B,0                      ; BC = length of string
                    LD   DE,0
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
.Read_string        LD   A,B
                    CP   0
                    JR   Z, read_str
                    CALL Bind_bank_s1
                    PUSH AF
                    ADD  HL,DE                    ; add offset to pointer
                    CALL read_str
                    POP  AF
                    CALL Bind_bank_s1
                    RET
.read_str           PUSH BC
                    PUSH DE
                    LD   B,0                      ; BC = length of string
                    LD   DE,0
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
; IN HL * local pointer to file handle
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
;
.Close_files        LD   HL,srcfilehandle
                    CALL Close_file
                    LD   HL,cdefilehandle
                    CALL Close_file
                    LD   HL,objfilehandle
                    CALL Close_file
                    LD   HL,errfilehandle
                    CALL Close_file
                    LD   HL,symfilehandle
                    CALL Close_file
                    LD   HL,deffilehandle
                    CALL Close_file
                    LD   HL,relocfilehandle
                    CALL Close_file
                    RET


; ****************************************************************************************
; Delete any temporary buffer files, before z80asm is completed.
.Delete_bufferfiles LD   B,0
                    LD   HL, reloctablefile
                    CALL Delete_file         ; delete ":RAM.-/reloctable", if it exists...
                    LD   HL, bufferfile
                    CALL Delete_file         ; delete ":RAM.-/buf", if it exists...
                    LD   HL, cdefile
                    JP   Delete_file         ; delete ":RAM.-/temp.buf", if it exists...


; ****************************************************************************************
;
; IN:     HL = srcfile, local pointer to input file handle
;         DE = dstfile, local pointer to output file handle
;         ABC = no. of bytes to copy (24bit file size ~ 1.67MB)
;
; OUT:    Fc = 1, file IO error occurred during copy
;         Fc = 0, file copied successfully
;
; Local variables on stack:
;    (IX+0,IX+1)    = handle of sourcefile
;    (IX+2,IX+3)    = handle of destfile
;    (IX+4,IX+6)    = remaining bytes to copy
;
; Registers changed after return:
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.Copy_file          PUSH IY
                    PUSH IX
                    LD   IX,0
                    ADD  IX,SP
                    LD   IY, -7
                    ADD  IY,SP               ; allocate 7 bytes room on stack
                    LD   SP,IY               ; IY points at base...
                    PUSH IX                  ; preserve pointer to original IY below variable area

                    PUSH AF                  ; preserve high byte of file copy size
                    LD   A,(HL)
                    LD   (IY+0),A
                    INC  HL
                    LD   A,(HL)
                    LD   (IY+1),A            ; handle for srcfile...
                    EX   DE,HL
                    LD   A,(HL)
                    LD   (IY+2),A
                    INC  HL
                    LD   A,(HL)
                    LD   (IY+3),A            ; handle for dstfile...
                    LD   (IY+4),C
                    LD   (IY+5),B
                    POP  AF
                    LD   (IY+6),A            ; bytes to copy is saved...

                    CALL CpyFile_64K         ; cpyfile(remainbytes MOD 65536)

.copy_loop          XOR  A
                    CP   (IY+6)              ; while(remainbytes DIV 65536)
                    JR   Z, end_copyfile
                         DEC  (IY+6)
                         LD   (IY+5),$80
                         CALL CpyFile_64K         ; cpyfile(32768)
                         JR   C, err_copyfile
                         LD   (IY+5),$80
                         CALL CpyFile_64K         ; cpyfile(32768)
                    JR   NC, copy_loop

.err_copyfile       CALL ReportError_NULL         ; reporterror(NULL; 0, ERR)
.end_copyfile       POP  HL                       ; get pointer to original IY
                    LD   SP,HL                    ; restore stack pointer
                    POP  IX                       ; restore original IX
                    POP  IY                       ; restore original IY
                    RET

; ****************************************************************************************************
;
; Copy file in 64K boundary blocks
;
.CpyFile_64K
.cpy_loop           LD   A,(IY+4)
                    OR   (IY+5)                   ; while (remainbytes != 0)
                    RET  Z
                         LD   L,(IY+0)
                         LD   H,(IY+1)                 ; {srcfile}
                         PUSH HL
                         POP  IX
                         LD   HL,lineptr-linebuffer    ; bufsize
                         LD   C,(IY+4)
                         LD   B,(IY+5)
                         CP   A                        ; if ( bufsize > remainbytes )
                         SBC  HL,BC                         ; bufsize = remainbytes
                         JR   NC, copy_chunk
                              LD   BC,lineptr-linebuffer
.copy_chunk              LD   HL,0
                         LD   DE,linebuffer            ; bufferstart
                         PUSH BC
                         CALL_OZ(Os_Mv)                ; bytesread = read(srcfile, linebuffer, bufsize)
                         POP  HL
                         CP   A                        ; ignore EOF, if encountered (Fc = 1)
                         SBC  HL,BC
                         LD   B,H
                         LD   C,L                      ; {BC = bytesread}
                         LD   L,(IY+4)
                         LD   H,(IY+5)
                         SBC  HL,BC
                         LD   (IY+4),L
                         LD   (IY+5),H                 ; remainbytes -= bytesread
                         LD   L,(IY+2)
                         LD   H,(IY+3)
                         PUSH HL
                         POP  IX                       ; {dstfile}
                         LD   DE,0
                         LD   HL,linebuffer
                         CALL_OZ(Os_Mv)                ; byteswritten = write(dstfile, linebuffer, bufsize)
                         RET  C
                    JR   cpy_loop


; ****************************************************************************************************
;
; Delete file
;
;    IN:  BHL = pointer to filename
;
.Delete_file        CALL_OZ(Gn_Del)
                    RET

