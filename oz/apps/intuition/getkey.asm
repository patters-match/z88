; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
;***************************************************************************************************

    MODULE GetKey


    ; String defined in 'Errmsg_asm':
    XREF SV_INT_window, REL_INT_window
    XREF Use_IntErrhandler, RST_ApplErrhandler, Int_Errhandler

     ; subroutine in lower 8K (through Extcall)
     XREF WaitKey 
    
    ; Routines defined in this module:
    XDEF GetKey, Toggle_CLI

    INCLUDE "defs.h"
    INCLUDE "oz.def"     
    INCLUDE "stdio.def"
    INCLUDE "fileio.def"
    INCLUDE "director.def"
    INCLUDE "integer.def"


; **************************************************************************************
;
; Get keypress from Intuition keyboard. 
;
; Register status after return:
;
;       ..BCDEHL/afbcdehl/..IY  same
;       AF....../......../IX..  different
;
.GetKey           PUSH BC                   ; save all Z80 registers...
                  PUSH DE                   ; except AF
                  PUSH HL
                  EX   AF,AF'               ;
                  PUSH AF                   ;
                  EX   AF,AF'               ;
                  EXX
                  PUSH BC                   ;
                  PUSH DE
                  PUSH HL                   ;
                  EXX

.read_keyboard    
                  EXTCALL WaitKey, OZBANK_INTUITION | 0
                  CP   27
                  JR   Z, exit_getkey
                  CP   $1F                  ; <DIAMOND>- pressed...
                  JR   Z, CLI_facility

.exit_getkey      EXX
                  POP  HL                   ;
                  POP  DE
                  POP  BC                   ;
                  EXX
                  EX   AF,AF'               ;
                  POP  AF                   ;
                  EX   AF,AF'               ;
                  POP  HL
                  POP  DE
                  POP  BC
                  RET


; *********************************************************************************
;
.CLI_facility     CALL Toggle_CLI
                  JR   read_keyboard        ; back to main keyboard routine


; execute CLI routines
.Toggle_CLI       PUSH IX
                  BIT  Flg_CLI,(IY + FlagStat1)
                  JR   Z, Create_logfile

.Close_logfile    LD   IX,0                       ; close file and quit CLI.
                  LD   A,4                        ; T-output code
                  CALL_OZ(Dc_Rbd)
                  RES  Flg_CLI,(IY + FlagStat1)   ; indicate no CLI running
                  CP   A                          ; signal success
                  POP  IX
                  RET

.Create_logfile   CALL Use_IntErrhandler
                  CALL SV_INT_window              ; save Intuition window before reading keyboard
                  LD   HL,0
                  ADD  HL,SP
                  LD   D,H
                  LD   E,L
                  LD   BC,-10
                  ADD  HL,BC                      ; make 10 bytes room for logfilename
                  LD   SP,HL                      ; set SP below logfilename buffer
                  PUSH DE                         ; remember current SP
                  PUSH HL                         ; remember start of filename buffer

                  LD   DE,CLI_file                ; ptr. to CLI filename
                  EX   DE,HL                      ; HL = source, DE = dest.
                  LD   BC,5                       ; copy standard filename into tmp buffer
                  LDIR                            ; DE = ptr. to end of name +1
                  LD   HL,2                       ; indicate BC = integer to be converted
                  LD   A, @00000001               ; to ASCII
                  INC  (IY + LogfileNr)           ; Update log file number
                  LD   C,(IY + LogfileNr)         ; BC = log file number
                  CALL_OZ(Gn_Pdn)                 ; convert log number into ASCII representation
                  XOR  A
                  LD   (DE),A                     ; then null terminate file name

                  POP  HL
                  PUSH HL
                  LD   A,OP_OUT
                  LD   D,H
                  LD   E,L                        ; also scratch buffer...
                  LD   BC,5
                  CALL_OZ(Gn_Opf)                 ; log file 'log.xxx' & 0
                  POP  DE
                  JR   C, exit_logfile            ; Ups - open error, return immediately

                  PUSH DE
                  LD   HL, CLI_command            ; 2. command to the CLI file
                  LD   BC,2                       ;
                  LDIR                            ; copy CLI command to buffer
                  POP  HL                         ; point at CLI command
                  LD   C,2
                  CALL_OZ(Dc_Icl)                 ; activate '.S' CLI redirection
                  JR   C, exit_logfile
                  LD   BC,1                       ; dummy key read to allow execute CLI
                  CALL_OZ(Os_Tin)
                  LD   A,4
                  CALL_OZ(DC_Rbd)                 ; rebind stream to T-output screen, file
                  JR   C, exit_logfile
                  SET  Flg_CLI,(IY + FlagStat1)   ; indicate CLI running...
.exit_logfile     POP  HL                         ; get old SP
                  LD   SP,HL                      ; install old SP
                  POP  IX
                  CALL REL_INT_window             ; release Intuition window...
                  JP   RST_ApplErrhandler

.CLI_file         DEFM "/log."                    ; standard CLI logfile 1, 5 bytes long
.CLI_command      DEFM ".S",0
