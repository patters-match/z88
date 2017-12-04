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


     MODULE WriteBytes

; external procedures:
     XREF Add16bit_1, Add16bit_2                       ; z80pass1.asm

; global procedures:
     XDEF WriteByte, WriteWord, WriteLong
     XDEF Init_CDEbuffer, FlushBuffer

     INCLUDE "rtmvars.def"
     INCLUDE "fileio.def"



; *********************************************************************************
;
.Init_CDEbuffer     LD   HL,cdebuffer
                    LD   (cdebufferptr),HL             ; buffer pointer updated
                    XOR  A
                    LD   (cdebufsize),A                ; buffer length updated
                    RET


; *********************************************************************************
;
; Buffer is full - write it to temp. machine code file
;
; OUT : HL = new buffer pointer (to start)
;        A = new buffer length  (reset)
;
; Registers changed after return:
;
;    ..BCDE../IXIY  same
;    AF....HL/....  different
;
.FlushBuffer        PUSH DE
                    PUSH BC
                    PUSH IX
                    LD   IX,(cdefilehandle)
                    LD   HL,cdebuffer                       ; pointer to start of buffer
                    LD   A,(cdebufsize)
                    CP   0
                    JR   Z, end_flushbuffer                 ; nothing to flush...
                    LD   B,0
                    LD   C,A                                ; length of buffer
                    LD   DE,0                               ; memory to file...
                    CALL_OZ(Os_Mv)
                    LD   A,0                                ; new length of buffer
                    LD   HL,cdebuffer
                    LD   (cdebufferptr),HL                  ; buffer pointer updated
                    LD   (cdebufsize),A                     ; buffer length updated
.end_flushbuffer    POP  IX
                    POP  BC
                    POP  DE
                    RET


; *********************************************************************************
;
; write byte to file (through buffer)
;
; IN C = byte
;
; OUT:    (codeptr) +1
;
; Registers changed after return:
;
;    AFBCDEHL/IXIY  same
;    ......../....  different
;
.WriteByte          PUSH HL
                    PUSH AF
                    LD   HL,(cdebufferptr)
                    LD   A,(cdebufsize)
                    CP   255                                ; buffer full?
                    CALL Z,FlushBuffer                      ; Yes - flush buffer first...
                    LD   (HL),C                             ; write byte to buffer
                    INC  A
                    INC  HL
                    LD   (cdebufferptr),HL                  ; buffer pointer updated
                    LD   (cdebufsize),A                     ; buffer length updated
                    LD   HL, codeptr
                    CALL Add16bit_1                         ; codeptr++
                    POP  AF
                    POP  HL
                    RET


; *********************************************************************************
;
; write word to file (through buffer)
;
; IN BC = word
;
; OUT:    (codeptr) +2
;
; Registers changed after return:
;
;    AFBCDEHL/IXIY  same
;    ......../....  different
;
.WriteWord          PUSH HL
                    PUSH DE
                    PUSH AF
                    LD   HL,(cdebufferptr)
                    LD   DE,cdebufsize
                    LD   A,(DE)
                    CP   255                                ; buffer full?
                    CALL Z,FlushBuffer                      ; Yes - write to file...
                    LD   (HL),C                             ; write low byte of word to buffer
                    INC  HL
                    INC  A
                    LD   (DE),A                             ; preserve length for next write
                    CP   255                                ; buffer full?
                    CALL Z,FlushBuffer                      ; Yes - write to file...
                    LD   (HL),B                             ; write high byte of word to buffer
                    INC  HL
                    INC  A
                    LD   (cdebufferptr),HL                  ; preserve pointer for next write
                    LD   (DE),A                             ; preserve length for next write
                    LD   HL, codeptr
                    CALL Add16bit_2                         ; codeptr += 2
                    POP  AF
                    POP  DE
                    POP  HL
                    RET


; *********************************************************************************
;
; write long word to file (through buffer)
;
; IN DEBC = long word
;
; OUT:    (codeptr) +4
;
; Registers changed after return:
;
;    AFBCDEHL/IXIY  same
;    ......../....  differents
;
.WriteLong          PUSH HL
                    PUSH BC
                    PUSH AF
                    CALL WriteWord ; write low word to buffer
                    LD   B,D
                    LD   C,E
                    CALL WriteWord ; write high word to buffer
                    POP  AF
                    POP  BC
                    POP  HL
                    RET
