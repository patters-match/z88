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
; $Id$
;
; ********************************************************************************************************************

     MODULE CodeRelocation

     XREF Display_integer
     XREF relocator, SIZEOF_relocator
     XREF ReportError_NULL                                            ; stderror.asm

     XREF Open_file, Close_file, Delete_file, fseek, Write_string     ; fileio.asm
     XREF Copy_file                                                   ;

     XDEF InitRelocTable, RelocationPrefix


     INCLUDE "stdio.def"
     INCLUDE "fileio.def"

     INCLUDE "rtmvars.def"
     INCLUDE "symbol.def"


; **************************************************************************************************
;
;    Initialize the relocation table (file) and associated variables
;
.InitRelocTable     LD   A, OP_OUT
                    LD   B,0
                    LD   HL, reloctablefile
                    CALL Open_file
                    JP   C, ReportError_NULL
                    CALL_OZ(Gn_Cl)
                    LD   A, OP_UP
                    LD   B,0
                    LD   HL, reloctablefile
                    CALL Open_file                     ; reloctable = fopen(":RAM.-/reloctable","w+")
                    LD   (relocfilehandle),IX
                    LD   BC,4
                    LD   HL, reloctablehdr
                    CALL Write_string                  ; relocfptr += 4
                    LD   HL,0
                    LD   (totaladdr),HL                ; totaladdr = 0
                    LD   (curroffset),HL               ; curroffset = 0
                    LD   (size_reloctable),HL          ; size_reloctable = 0
                    RET
.reloctablefile     DEFM ":RAM.-/reloctable", 0
.reloctablehdr      DEFB 0, 0, 0, 0


; **************************************************************************************************
;
;    The machine code has been completed. Code has been linked and address patched.
;    Now, the relocation header is put in front of the code:
;
;         1) The relocation table is patched with size and no. of elements. (first four bytes).
;         2) A temporary file, ":ram.-/buf" is created.
;         3) The Relocater program code is written.
;         4) The relocation table is written.
;         5) The linked machine code is written (copied from ".bin" file).
;         6) The original .bin code file is overwritten with new ":ram.-/buf" file.
;         7) ":ram.-/buf" file is closed and deleted.
;         8) The .bin file is closed. Relocation prefix completed.
;
.RelocationPrefix   LD   HL,(totaladdr)
                    LD   A,H
                    OR   L
                    JP   Z, exit_relocprefix           ; if (totaladdr != 0)
                         LD   IX,(relocfilehandle)
                         LD   B,0
                         LD   HL, reloctablehdr             ; point at four zeroes
                         CALL fseek                         ; move file pointer to start of table
                         LD   HL,(totaladdr)
                         LD   A,L
                         CALL_OZ(OS_Pb)                     ; fputc(reloctable, totaladdr % 256)
                         LD   A,H
                         CALL_OZ(OS_Pb)                     ; fputc(reloctable, totaladdr / 256)
                         LD   BC,4
                         LD   HL,(size_reloctable)
                         LD   A,L
                         CALL_OZ(OS_Pb)                     ; fputc(reloctable, size_reloctable % 256)
                         LD   A,H
                         CALL_OZ(OS_Pb)                     ; fputc(reloctable, size_reloctable / 256)
                         ADD  HL,BC
                         LD   (size_reloctable),HL          ; size_reloctable += 4
                         LD   B,0
                         LD   HL, reloctablehdr             ; point at four zeroes
                         CALL fseek                         ; move file pointer to start of table

                         LD   A, OP_OUT
                         LD   HL, bufferfile
                         CALL Open_file                     ; buff = fopen(":ram.-/buf","w")
                         CALL C, ReportError_NULL
                         JP   C, exit_relocprefix           ; if buff != NULL
                              LD   (tmpfilehandle),IX
                              LD   BC, SIZEOF_relocator
                              LD   DE,0
                              LD   HL, relocator
                              CALL_OZ(OS_Mv)                     ; fwrite(buff, relocator, SIZEOF_relocator)

                              LD   HL, relocfilehandle
                              LD   DE, tmpfilehandle
                              XOR  A
                              LD   BC,(size_reloctable)
                              CALL Copy_file                     ; fwrite(buff, reloctable, size_reloctable)

                              LD   IX,(cdefilehandle)
                              LD   B,0
                              LD   HL, reloctablehdr             ; point at four zeroes
                              CALL fseek                         ; move file pointer to start of linked machine code
                              LD   HL, cdefilehandle
                              LD   DE, tmpfilehandle
                              XOR  A
                              LD   BC,(codesize)
                              CALL Copy_file                     ; fwrite(buff, z80code, codesize)
                              LD   HL, tmpfilehandle
                              CALL Close_file                    ; fclose(buff)
                              LD   IX,(cdefilehandle)
                              LD   B,0
                              LD   HL, reloctablehdr             ; point at four zeroes
                              CALL fseek                         ; move file pointer to start of linked machine code

                              LD   A, OP_IN
                              LD   B,0
                              LD   HL, bufferfile
                              CALL Open_file                     ; buff = fopen(":ram.-/buf","r")
                              LD   (tmpfilehandle),IX

                              LD   HL, SIZEOF_relocator
                              LD   BC,(size_reloctable)
                              ADD  HL,BC
                              LD   BC,(codesize)
                              ADD  HL,BC
                              XOR  A
                              LD   B,H
                              LD   C,L                           ; ABC = SIZEOF_relocator + size_reloctable + codesize
                              LD   HL, tmpfilehandle
                              LD   DE, cdefilehandle
                              CALL Copy_file                     ; fwrite(cdefile, buff, ABC)
                              LD   HL, tmpfilehandle
                              CALL Close_file
                              LD   B,0
                              LD   HL, bufferfile
                              CALL Delete_file                   ; remove(":ram.-/buf")

                              LD   HL, relocmsg
                              CALL_OZ(GN_Sop)                    ; puts("Size of relocation header is ")
                              LD   HL, SIZEOF_relocator
                              LD   BC,(size_reloctable)
                              ADD  HL,BC
                              LD   B,H
                              LD   C,L
                              CALL Display_integer               ; printf("%d\n", SIZEOF_relocator+size_reloctable)
                              CALL_OZ(GN_Nln)

.exit_relocprefix   LD   HL, relocfilehandle
                    CALL Close_file                    ; fclose(relocfilehandle)
                    RET
.bufferfile         DEFM ":RAM.-/buf", 0
.relocmsg           DEFM 1, "2H5Size of relocation header is ", 0
