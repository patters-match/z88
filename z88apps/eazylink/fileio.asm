; *************************************************************************************
; EazyLink - Fast Client/Server File Management, including support for PCLINK II protocol
; (C) Gunther Strube (gstrube@gmail.com) 1990-2012
;
; EazyLink is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; EazyLink is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with EazyLink;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************


    MODULE Filesystem_IO


    XREF TraFilename, IBM_TraTableIn, IBM_TraTableOut
    XREF Write_message, Message19, Message20

    XDEF LoadTranslations
    XDEF Use_StdTranslations
    XDEF Get_wcard_handle, Find_Next_Match, Close_wcard_handler
    XDEF Abort_file, Write_Buffer, Flush_buffer, Load_buffer, Reset_buffer_ptrs
    XDEF Get_file_handle, Close_file, TranslateByte

    INCLUDE "rtmvars.def"
    INCLUDE "fileio.def"


; ***********************************************************************
; Load translation byte pairs [<in>,<out>] from file 'Translate,dat'
; If file is not present in filing system, use the standard Z88 - IBM table.
;
.LoadTranslations PUSH IX                            ; Load translations from file.
                  PUSH HL
                  PUSH DE
                  PUSH BC                            ; if ':RAM.0/Translates' file is not
                  LD   A,OP_IN                       ; found, ISO-IBM internal is instal-
                  LD   HL,TraFilename                ; led from internal table.
                  CALL Get_file_handle               ; open Std. Translations file
                  CALL C,use_StdTranslations         ; not found or 'in use'...

                  JR   C,end_LoadTranslations

.readbytes_loop   CALL LoadByte                      ; byte in A
                  JR   Z,close_Trafile
                  LD   D,A                           ; Value1
                  CALL LoadByte
                  JR   Z,close_Trafile
                  LD   E,A                           ; Value2
                  CALL InstallByte
                  JR   readbytes_loop

.close_Trafile    CALL_OZ (gn_cl)
                  LD   HL, message19
                  CALL Write_message
                  JR   end_LoadTranslations

.end_LoadTranslations
                  POP  BC
                  POP  DE
                  POP  HL
                  POP  IX
                  RET


.Use_StdTranslations
                  PUSH AF
                  LD   BC,512                        ; size of complete translation table
                  LD   HL,IBM_TraTableIn
                  LD   DE,TraTableIn                 ; copy IBM table...
                  LDIR
                  LD   HL, message20
                  CALL Write_message

                  POP  AF
                  RET

; ***********************************************************************
.InstallByte      PUSH BC                            ; Install byte in tra-table...
                  PUSH HL
                  LD   B,0                           ; D = value1
                  LD   C,D                           ; E = value2
                  LD   HL,TraTableIn
                  ADD  HL,BC
                  LD   (HL),E                        ; TraTable_in(Value1) = Value2
                  LD   C,E
                  LD   HL,TraTableOut
                  ADD  HL,BC
                  LD   (HL),D                        ; TraTable_out(Value2) = Value1
                  POP  HL
                  POP  BC
                  RET


; ***********************************************************************
.LoadByte         PUSH DE
                  LD   A,FA_EOF
                  CALL_OZ (Os_Frm)
                  POP  DE
                  RET  Z
                  CALL_OZ (Os_Gb)
                  RET



; *********************************************************
; HL points at filename, A = wildcard search specifier
; procedure return Fc = 1 if no handle was available, otherwise 0 for success
; (wildcard_handle) contains handle for filename...
.Get_wcard_handle PUSH BC
                  PUSH HL
                  PUSH IX
                  LD   B,0
                  CALL_OZ (Gn_Opw)                   ; open wildcard handler.
                  LD   (wildcard_handle),IX          ; save handle for later use.
                  POP  IX
                  POP  HL
                  POP  BC
                  RET


; **************************************************************
; Find next file match from wildcard search handle...
; C = file length, A = File type
; (DE) contains found filename
;
.Find_Next_Match  PUSH DE
                  PUSH IX
                  LD   IX,(wildcard_handle)          ; exit loop when last name have been
                  LD   DE, filename_buffer           ; processed.
                  LD   C,255                         ; maximum length of found filename.
                  CALL_OZ (Gn_Wfn)                   ; fetch next file name ...
                  POP  IX
                  POP  DE
                  RET


; *************************************************************
.Close_wcard_handler
                  PUSH AF
                  PUSH IX
                  LD   IX, (wildcard_handle)
                  CALL_OZ (Gn_Wcl)                   ; release handle.
                  POP  IX
                  POP  AF
                  RET


; ***********************************************************************
.Abort_file       PUSH AF
                  PUSH BC
                  PUSH HL
                  CALL Close_file
                  LD   B,0
                  LD   HL,filename_buffer
                  CALL_OZ (Gn_Del)
                  POP  HL
                  POP  BC
                  POP  AF
                  RET


; ***********************************************************************
.Write_buffer     LD   HL,(buffer)                   ; entry of buffer
                  LD   (HL),A                        ; put byte into buffer
                  INC  HL
                  LD   (buffer),HL                   ; save adr of next entry into buffer
                  LD   HL,(buflen)                   ; current size of buffer
                  INC  HL                            ; updated with new byte
                  LD   (buflen),HL                   ; save back new buffer length
                  LD   BC,file_buffer_end - file_buffer
                  CP   A
                  SBC  HL,BC                         ; is buffer full?
                  JR   Z,Flush_buffer                ; Yes, write to file...
                  XOR  A                             ; Clear Carry if set...
                  RET                                ; return, fetch next byte...
.Flush_buffer     LD   IX,(file_handle)              ; Also called directly if EOF before
                  LD   BC,(buflen)
                  LD   DE,0
                  LD   HL,file_buffer
                  CALL_OZ (Os_Mv)                    ; write buffer to file.
                  CALL Reset_buffer_ptrs
                  RET                                ; C detection in calling program


; ***********************************************************************
.Load_buffer      LD   IX,(file_handle)
                  LD   A,fa_eof
                  CALL_OZ (Os_Frm)
                  RET  Z                             ; EOF
                  LD   BC,file_buffer_end - file_buffer
                  LD   HL,0
                  LD   DE,file_buffer
                  PUSH BC
                  CALL_OZ (Os_Mv)
                  POP  HL
                  CP   A
                  SBC  HL,BC
                  LD   (buflen),HL                    ; actual length of buffer
                  RET


; ***********************************************************************
.Reset_buffer_ptrs
                  EXX
                  LD   HL,file_buffer
                  LD   (buffer),HL
                  LD   HL,0
                  LD   (buflen),HL
                  EXX
                  RET



; ***********************************************************************
.Get_file_handle  LD   B,0                           ; HL pointer to filename
                  LD   C,128                         ; buffer length
                  CALL_OZ (Gn_Opf)                   ; IX = handle for file.
                  RET


; ***********************************************************************
.Close_file       PUSH AF                            ; save F register flags
                  PUSH HL
                  PUSH IX
                  LD   HL,(file_handle)              ; (could be called if error occurres
                  LD   A,H
                  OR   L
                  JR   Z, exit_Close_file            ; no file to close...
                  PUSH HL
                  POP  IX
                  CALL_OZ (Gn_Cl)
                  LD   HL,0
                  LD   (file_handle),HL
.exit_Close_file
                  POP  IX
                  POP  HL
                  POP  AF
                  RET
