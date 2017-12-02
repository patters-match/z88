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

     MODULE ReleaseModules

     Lib deleteall

; **************************************************************************************************
;
; Release modules from memory
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.ReleaseModules     LD   HL, modulehdr
                    CALL GetVarPointer                 ; { get modulehdr pointer in BHL}
                    XOR  A
                    CP   B
                    RET  Z                             ; if ( modulehdr == NULL ) return
                    PUSH BC
                    PUSH HL                            ; { preserve modulehdr }
                    LD   A, modules_first
                    CALL Read_pointer                  ; curptr = modulehdr->first
                                                       ; do
.releasemodule_loop      PUSH BC                            ;    { preserve curptr }
                         PUSH HL
                         LD   A, module_cfile
                         CALL Read_pointer
                         XOR  A
                         CP   B
                         JR   Z, rel_localroot              ;    if ( curptr->cfile != NULL )
                              CALL ReleaseFile              ;         ReleaseFile(curptr->cfile)
.rel_localroot           POP  HL
                         POP  BC
                         PUSH BC
                         PUSH HL
                         LD   A,module_localroot
                         CALL Read_pointer
                         XOR  A
                         CP   B
                         JR   Z, rel_mexpr                  ;    if ( curptr->localroot != NULL )
                              CALL ReleaseSymbol            ;         ReleaseSymbol(curptr->localroot)
.rel_mexpr               POP  HL
                         POP  BC
                         PUSH BC
                         PUSH HL
                         LD   A,module_mexpr
                         CALL Read_pointer
                         XOR  A
                         CP   B
                         JR   Z, rel_mname                  ;    if ( curptr->mexpr != NULL )
                              CALL ReleaseExpressions                 ReleaseExprns(curptr->mexpr)
.rel_mname               POP  HL
                         POP  BC
                         PUSH BC
                         PUSH HL
                         LD   A,module_mname
                         CALL Read_pointer
                         XOR  A
                         CP   B
                         JR   Z, rel_module                 ;    if ( curptr->mname != NULL )
                              CALL mfree                              free(curptr->mname)

.rel_module              POP  HL
                         POP  BC
                         PUSH BC                            ;    { restore curptr in BHL }
                         PUSH HL                            ;    tmpptr = curptr
                         LD   A,module_next
                         CALL Read_pointer                  ;    curptr = curptr->nextmodule
                         EX   DE,HL
                         LD   A,B                           ;    tmpptr = CDE
                         POP  HL
                         POP  BC
                         CALL mfree                         ;    free(curptr)
                         LD   B,A
                         EX   DE,HL                         ;    curptr = tmpptr
                         CP   0
                    JR   NZ, releasemodule_loop        ; while (curptr != NULL)

                    POP  HL
                    POP  BC                            ; { restore modulehdr }
                    CALL mfree
                    LD   C,B
                    EX   DE,HL                         ; { CDE = NULL }
                    LD   HL,modulehdr
                    CALL GetPointer                    ; &modulehdr
                    XOR  A
                    JP   Set_pointer                   ; modulehdr = NULL
