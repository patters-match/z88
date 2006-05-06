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

     MODULE Define_origin

     XREF z80asm_ERH
     XREF Getsym, GetConstant
     XREF Test_16bit_range
     XREF ReportError_NULL
     XREF Get_stdoutp_handle, Display_error

     XDEF DefineOrigin, GetOrigin

     INCLUDE "stdio.def"
     INCLUDE "rtmvars.def"


; *********************************************************************************************
;
;    Define ORIGIN for machine code. The user is prompted in the message window to enter an
;    ORG address. The routine is only quit when a proper ORG has been entered.
;
;    IN:  None.
;    OUT: DE = origin integer.
;
.DefineOrigin       PUSH BC
                    PUSH HL
.org_loop           CALL Inputorigin
                    LD   (lineptr),DE
                    CALL Getsym                        ; fetch ORG from command line
                    CALL GetOrigin
                    JR   C, org_loop
                    EXX
                    EX   DE,HL                         ; return ORG in DE
                    POP  HL
                    POP  BC
                    RET


; *********************************************************************************************
;
.InputOrigin        LD   DE,Linebuffer                 ; DE points at beginning of buffer
                    PUSH DE
                    LD   A,'$'
                    LD   (DE),A                        ; preceeded with $ for hex address
                    INC  DE
                    XOR  A
                    LD   (DE),A
                    POP  DE
                    LD   C,1                           ; put cursor after '$' symbol
.inpline_loop       LD   HL, org_prompt
                    CALL_OZ(Gn_Sop)
                    LD   A,@00100001                   ; Single Line Lock, info in buffer
                    LD   B,6
                    LD   L,6                           ; allow max. 18 chars.
                    CALL_OZ (Gn_Sip)                   ; edit & type file name...
                    JR   NC,exit_inporg                ; <ENTER> pressed
                    CALL C, z80asm_ERH                 ; process system error codes
                    JR   inpline_loop
.exit_inporg        CALL_OZ(Gn_Nln)                    ; make sure that cursor gets to next line
                    RET

.org_prompt         DEFM 1, "2H5", 13, "Enter ORG address (in hex): ", 0


; ******************************************************************************
;
;    Get ORIGIN constant
;    (Ident) contains constant (previously read with Getsym).
;
;    return ORG integer in alternate HL, Fc = 0 (successfully fetched),
;    otherwise Fc = 1.
;
.GetOrigin          CALL GetConstant              ; and convert to integer
                    JR   C, illegal_origin        ; syntax error, illegal constant
                         EXX                      ; constant returned in alternate DEBC
                         PUSH DE
                         PUSH BC
                         POP  HL
                         EXX
                         POP  HL
                         LD   C,0                 ; convert constant to HLhlC format
                         CALL Test_16bit_Range    ; range must be [0; 65535]
                         RET  NC
.org_range               LD   A, ERR_range
                         CALL OriginError
                         SCF
                         RET
.illegal_origin          LD   A, ERR_syntax
                         CALL OriginError
                         SCF
                         RET


; ******************************************************************************
;
;    IN:  A = error code
;
.OriginError             PUSH IX
                         CALL Get_stdoutp_handle  ; handle for standard output
                         CALL Display_error       ; display error message
                         CALL_OZ(Gn_Nln)          ; but don't affect z80asm error system
                         POP  IX
                         RET
