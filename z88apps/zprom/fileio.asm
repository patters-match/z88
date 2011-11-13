;          ZZZZZZZZZZZZZZZZZZZZ
;        ZZZZZZZZZZZZZZZZZZZZ
;                     ZZZZZ
;                   ZZZZZ
;                 ZZZZZ           PPPPPPPPPPPPPP     RRRRRRRRRRRRRR       OOOOOOOOOOO     MMMM       MMMM
;               ZZZZZ             PPPPPPPPPPPPPPPP   RRRRRRRRRRRRRRRR   OOOOOOOOOOOOOOO   MMMMMM   MMMMMM
;             ZZZZZ               PPPP        PPPP   RRRR        RRRR   OOOO       OOOO   MMMMMMMMMMMMMMM
;           ZZZZZ                 PPPPPPPPPPPPPP     RRRRRRRRRRRRRR     OOOO       OOOO   MMMM MMMMM MMMM
;         ZZZZZZZZZZZZZZZZZZZZZ   PPPP               RRRR      RRRR     OOOOOOOOOOOOOOO   MMMM       MMMM
;       ZZZZZZZZZZZZZZZZZZZZZ     PPPP               RRRR        RRRR     OOOOOOOOOOO     MMMM       MMMM


; **************************************************************************************************
; This file is part of Zprom.
;
; Zprom is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Zprom is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the Zprom; 
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
;
;***************************************************************************************************


     Module FileIO

     XREF syntax_error

     XDEF Check_file, Get_file_handle, Close_file


     INCLUDE "defs.asm"
     INCLUDE "fileio.def"


; **********************************************************************************************
;
; Test file for excistence. The file name is specified with a pointer.
; This routine expands the filename with a '.bin' extension, if none is specified and then
; tries to open the file added with the '.bin' extension. If it fails, then it try to open
; the file with the original specified name.
;
; IN: HL = pointer to filename buffer
; OUT Fc = 1, if file couldn't be opened (with '.bin' extension or not)
;     Fc = 0, if file is accessible
;
.Check_file         LD   B,0
                    CALL_OZ(Gn_Prs)                    ; check syntax of filename
                    JP   C, syntax_error
                    AND  @00000001
                    RET  NZ                            ; extension used - return
                    LD   B,255                         ; start at filename...
                    LD   A, (Bufsize)                  ; max. size of name
                    LD   C,A
                    LD   A, @10000001                  ; write extension...
                    PUSH HL
                    EX   DE,HL                         ; DE points at filename
                    LD   HL, bin_ext                   ; add '.bin' extension
                    CALL_OZ(Gn_Esa)
                    POP  HL
                    LD   A,OP_IN
                    CALL Get_file_handle
                    JP   NC, Close_file                ; file exist, return to caller
                    LD   B,0
                    LD   A, (Bufsize)                  ; max. size of name
                    LD   C,A
                    XOR  A                             ; find null-terminator
                    PUSH HL
                    CPIR
                    LD   C,5
                    SBC  HL,BC                         ; point at extension separator
                    LD   (HL),0                        ; null-terminate filename
                    POP  HL                            ; pointer to start of filename
                    RET


; **********************************************************************************************
;
; Get a file handle, specified from filename in buffer
;
; IN: A  = Open specifier     (Read, Write, Update)
;     HL = pointer to file name
;
.Get_file_handle    PUSH HL
                    PUSH DE
                    PUSH BC
                    LD   D,H                           ; DE points at scratch buffer
                    LD   E,L                           ; HL points at filename
                    LD   B,0                           ; local pointer...
                    PUSH AF
                    LD   A,(BufSize)                   ; max. buffer size
                    LD   C,A
                    POP  AF
                    CALL_OZ (Gn_Opf)
                    POP  BC
                    POP  DE
                    POP  HL                            ; restore ptr. to start of filename
                    RET
.bin_ext            DEFM "bin"

.Close_file         PUSH  AF
                    CALL_OZ(Gn_Cl)
                    POP   AF
                    RET
