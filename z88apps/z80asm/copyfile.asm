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

Module CopyFile

INCLUDE "fileio.def"
INCLUDE "rtmvars.def"

XREF ReportError_NULL

XDEF Copy_file


; ********************************************************************************************************************
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
