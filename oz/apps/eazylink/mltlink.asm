; *************************************************************************************
; EazyLink - Fast Client/Server File Management, including support for PCLINK II protocol
; (C) Gunther Strube (gbs@users.sourceforge.net) 1990-2006
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
; $Id$
;
; *************************************************************************************

    MODULE MultiLink4_commands

    LIB createfilename

    XREF ESC_Y, ESC_Z, ESC_N, ESC_F, ESC_E, CRLF, DM_Dev, Current_Dir, Parent_Dir
    XREF TranslateByte
    XREF cli_filename
    XREF SendString, Send_ESC, PutByte, GetByte
    XREF Get_wcard_handle, Find_Next_Match, Close_wcard_handler
    XREF Abort_file, Get_file_handle, Reset_buffer_ptrs, Flush_buffer, Close_file
    XREF Write_buffer, Load_Buffer
    XREF Write_Message, Msg_Command_aborted, Msg_Protocol_error, Msg_File_aborted
    XREF Msg_No_Room, Msg_file_open_error, System_Error
    XREF Message3, Message7, Message14, Message15, Message16
    XREF Message17, Message18
    XREF Set_Traflag, Restore_Traflag, Def_RamDev_wildc, SearchFileSystem, Get_directories
    XREF Open_Serialport, Calc_hexnibble

    XDEF ESC_A_cmd2, ESC_H_cmd2, ESC_D_cmd2, ESC_N_cmd2, ESC_Q_cmd2
    XDEF ImpExp_Send, ImpExp_Receive, ImpExp_Backup
    XDEF FetchBytes
    XDEF Transfer_file
    XDEF Fetch_pathname


    INCLUDE "rtmvars.def"
    INCLUDE "error.def"
    INCLUDE "fileio.def"
    INCLUDE "dor.def"
    INCLUDE "stdio.def"


; ***********************************************************************
; Hello
;
.ESC_A_cmd2       LD   HL,ESC_Y
                  CALL SendString
                  JR   C, esc_a2_aborted
                  JR   Z, esc_a2_aborted
                  LD   HL,message3
                  CALL Write_message
                  XOR  A
                  RET
.esc_a2_aborted   CALL Msg_Command_aborted
                  XOR  A
                  RET


; ***********************************************************************
; Send Z88 Devices, extended protocol
;
.ESC_H_cmd2       
                  LD   A, Dm_Dev
                  LD   (file_type),A
                  LD   A, 0                          ; wildcard search specifier...
                  CALL Def_RamDev_wildc

                  CALL Send_found_names              ; internal & external RAM cards...
                  JR   C, esc_h2_aborted
                  JR   Z, esc_h2_aborted
                  LD   HL,ESC_Z                      ; no more names
                  CALL SendString
                  JR   C, esc_h2_aborted
                  JR   Z, esc_h2_aborted
                  JR   end_ESC_H_cmd2
.esc_h2_aborted
                  CALL Msg_Command_aborted
.end_ESC_H_cmd2
                  XOR  A                             ; signal continue in main loop
                  RET                                ; (Z = 1)



; ***********************************************************************
; Send directory names, extended protocol
;
.ESC_D_cmd2       
                  CALL Set_Traflag                   ; translation ON temporarily
                  CALL Fetch_pathname
                  JR   C, esc_d2_aborted
                  JR   Z, esc_d2_aborted

                  PUSH HL
                  LD   HL, Current_dir               ; Send "."
                  CALL SendString
                  POP  HL
                  JR   C, esc_d2_aborted
                  JR   Z, esc_d2_aborted
                  CALL_OZ (Gn_Prs)                   ; parse pathname
                  LD   A,B                           ; B = no. of segments in path name
                  SUB  1                             ; without wildcard specifier '*'...
                  CP   1                             ; only 1 filename segment?
                  JR   Z,no_parent_dir               ; root directory...
                  LD   HL, Parent_dir                ; Send ".."
                  CALL SendString
                  JR   C, esc_d2_aborted
                  JR   Z, esc_d2_aborted
.no_parent_dir
                  LD   A,dn_dir
                  LD   (file_type),A                 ; find directories
                  LD   A, 1                          ; wildcard search specifier
                  LD   HL, filename_buffer
                  CALL Send_found_names
                  JR   C, esc_d2_aborted
                  JR   Z, esc_d2_aborted
                  LD   HL,ESC_Z                      ; no more names
                  CALL SendString
                  JR   C, esc_d2_aborted
                  JR   Z, esc_d2_aborted
                  JR   end_esc_d2
.esc_d2_aborted
                  CALL Msg_Command_aborted           ; write message and set Fz
.end_esc_d2
                  CALL Restore_Traflag
                  XOR  A
                  RET


; ***********************************************************************
.ESC_N_cmd2                                          ; send file names
                  CALL Set_Traflag
                  CALL Fetch_pathname                ; load pathname into filename_buffer
                  JR   C, esc_n2_aborted
                  JR   Z, esc_n2_aborted             ; timeout - communication stopped

                  LD   A,dn_fil
                  LD   (file_type),A                 ; signal filenames to be found
                  LD   A, 1                          ; wildcard search specifier
                  LD   HL, filename_buffer
                  CALL Send_found_names
                  JR   C, esc_n2_aborted
                  JR   Z, esc_n2_aborted             ; timeout - communication stopped
                  LD   HL,ESC_Z                      ; no more names
                  CALL SendString
                  JR   C, esc_n2_aborted
                  JR   Z, esc_n2_aborted             ; timeout - communication stopped
                  JR   end_esc_n2
.esc_n2_aborted
                  CALL Msg_Command_aborted           ; write message and set Fz
.end_esc_n2
                  CALL Restore_Traflag
                  XOR  A
                  RET


; ***********************************************************************
.ImpExp_Receive
                  LD   HL,message14                  ; send files to Z88, using ImpExp protocol.
                  CALL Write_message                 ; 'ImpExp Receive files...'
                  CALL Batch_Receive
                  RET  C                             ; error (or ESC pressed)
                  XOR  A                             ; signal continue in main loop
                  RET                                ; (Z = 1)


; ***********************************************************************
.ImpExp_Send      LD   HL,message15                  ; send files to terminal, using ImpExp protocol.
                  CALL Write_message
                  CALL Batch_Send
                  RET  C                             ; error (or ESC pressed)
                  XOR  A                             ; signal continue in main loop
                  RET                                ; (Z = 1)


; ***********************************************************************
.ESC_Q_cmd2       LD   HL,ESC_Y                      ; Multilink 'Quit'
                  CALL SendString                    ; return Yes...
                  JR   C, esc_q2_aborted
                  JR   Z, esc_q2_aborted
                  SET  0,A                           ; Zero = 0, signal 'Quit'...
                  OR   A
                  RET
.esc_q2_aborted   CALL Msg_Command_aborted
                  XOR  A
                  RET


; ***********************************************************************
.ImpExp_Backup    LD   HL,message16                  ; Backup files to terminal, using ImpExp protocol.
                  CALL Write_message
                  CALL Backup_files
                  RET  C                             ; error (or ESC pressed)
                  XOR  A                             ; signal continue in main loop
                  RET                                ; (Z = 1)


; ***********************************************************************
.Batch_Receive    CALL FetchBytes
                  JR   C, abort_batch_receive            ; system error
                  JR   Z, abort_batch_receive            ; timeout...
                  CP   $FF
                  LD   A,B
                  JR   NZ, err_protocol                  ; no ESC id, protocol error...
                  CP   'N'                               ; is it ESC "N" ?
                  JR   Z, fetch_flnm
                  CP   'Z'                               ; is it ESC 'Z' ?
                  JR   NZ, err_protocol                  ; no, protocol error...
                  RET                                    ; yes, return to main...

.err_protocol     CALL Msg_Protocol_error                ; write error messages on screen, and
                  CALL Msg_Command_aborted
                  XOR  A
                  RET

.Batch_receive_aborted
                  CALL Abort_file
.abort_batch_receive
                  CALL Msg_Command_aborted              ; write 'Command aborted' message
                  XOR  A
                  RET

.fetch_flnm       CALL Set_TraFlag
                  CALL Fetch_pathname                    ; load filename into filename_buffer
                  CALL Restore_TraFlag
                  JR   C,abort_batch_receive
                  JR   Z,abort_batch_receive             ; timeout - communication stopped
                  LD   B,0
                  LD   HL,filename_buffer
                  CALL Write_message                     ; write filename to screen
                  CALL createfilename
                  JP   C, File_create_error

.file_created     LD   (file_handle),IX                  ; save file handle for later use
                  CALL Reset_buffer_ptrs                 ; buffer ready for new file...
.receive_file_loop
                  CALL FetchBytes
                  JR   C,Batch_receive_aborted
                  JR   Z,Batch_receive_aborted
                  CP   $FF                               ; fetched an ESC id?
                  LD   A,B
                  JR   NZ, byte_to_file                  ; no, still receiving byte to file
                  CP   'E'                               ; is it ESC 'E' ?
                  JR   Z, close_rcvd_file
                  CALL Msg_protocol_error
                  CALL Msg_File_aborted
                  CALL Abort_file
                  JR   Batch_receive                 ; new file coming?
.close_rcvd_file  CALL Flush_buffer                  ; save contents of buffer...
                  CALL Close_file                    ; ESC 'Z' received.
                  JP   Batch_receive                 ; new file coming?
; byte in A to file...
.byte_to_file     CP   LF                            ; is it a line feed?
                  JR   NZ,no_linefeed
                  LD   A,(CRLF_flag)                 ; check CRLF flag
                  CP   $FF                           ; active?
                  LD   A,LF
                  JR   NZ,no_linefeed                ; not active - write LF to file...
                  JR   receive_file_loop             ; - ignore LF (reverse CRLF) and fetch next byte...
.no_linefeed      CALL Write_buffer                  ; put byte into buffer
                  JR   C,no_memory                   ; write error - memory full
                  JR   receive_file_loop             ; fetch next byte from serial port
.no_memory        CALL Msg_No_Room
                  CALL Msg_file_aborted
                  CALL Abort_file
                  XOR  A
                  RET
.File_create_error
                  CALL Msg_File_open_error
                  CALL Msg_Command_aborted            ; write 'Command aborted' message
                  XOR  A
                  RET


; *************************************************
.Batch_Send       CALL Set_Traflag
                  CALL Fetch_pathname                ; without ACKN protocol...
                  CALL Restore_Traflag
                  JR   C, err_batch_send
                  JR   Z, err_batch_send
                  LD   B,0
                  LD   HL,filename_buffer
                  CALL Write_message                 ; display pathname / wildcard on screen...

                  XOR  A                             ; wildcard search specifier - files before directories
                  CALL Get_wcard_handle              ; get handle in IX for pathname in (HL)
                  JR   C, wcard_system_error
.find_files_loop  CALL Find_next_match
                  JR   C, batch_send_end             ; no more files found in wildcard
                  CP   dn_fil
                  JR   NZ,find_files_loop            ; not a file - get next

                  LD   HL, filename_buffer
                  CALL Transfer_file

                  JR   C, batch_send_aborted         ; Ups - transmission error
                  JR   Z, batch_send_aborted
                  JR   find_files_loop
.batch_send_aborted
                  CALL Close_wcard_handler
.err_batch_send   CALL Msg_Command_aborted
                  XOR  A
                  RET
.batch_send_end   CALL Close_wcard_handler
                  LD   HL, ESC_Z                     ; end of files...
                  CALL SendString
                  RET
.wcard_system_Error
                  XOR  A                             ; Fc = 0, only Fc = 1 if ESC pressed...
                  RET


; ****************************************************'
; HL points at filename to be sent...
.Transfer_file    EX   DE,HL                         ; save filename pointer in DE
                  LD   HL, ESC_N
                  CALL SendString
                  RET  C
                  RET  Z
                  LD   H,D
                  LD   L,E                           ; get a copy of filename
                  CALL Set_Traflag
                  CALL SendString
                  CALL Restore_Traflag
                  RET  C
                  RET  Z
                  LD   HL, ESC_F
                  CALL SendString
                  RET  C
                  RET  Z
                  LD   HL, message17
                  CALL_OZ (gn_sop)
                  LD   H,D
                  LD   L,E                           ; get a copy of filename
                  CALL Write_message
                  LD   A, op_in                      ; open file for transfer...
                  CALL Get_file_handle
                  CALL C, System_error
                  RET  C
                  LD   (file_handle), IX             ; save file handle
.trnsf_file_loop  CALL Load_buffer                   ; load new block into buffer...
                  JR   Z, End_transfer_file          ; EOF reached...
                  LD   BC,(buflen)
                  LD   HL,file_buffer                ; start of buffer
.send_file_buffer LD   A,(HL)                        ; fetch byte from buffer
                  CP   ESC                           ; ESC byte?
                  JR   NZ,test_CR
                  CALL Send_ESC                      ; send ESC ESC sequense
                  JR   C, error_trnsf_file
                  JR   Z, error_trnsf_file
                  JR   continue_sending
.test_CR          CP   CR                            ; is byte a CR?
                  JR   NZ,send_file_byte
                  LD   A,(CRLF_flag)                 ; Yes,
                  CP   $FF                           ; extended to CRLF?
                  LD   A,CR
                  JR   NZ,send_file_byte             ; no!
                  PUSH HL                            ; save buffer adr.
                  LD   HL,CRLF                       ; Send CRLF sequense
                  CALL SendString
                  POP  HL
                  JR   C, error_trnsf_file
                  JR   Z, error_trnsf_file
                  JR   continue_sending
.send_file_byte   CALL Putbyte                       ; put byte to serial port
                  JR   C, error_trnsf_file
                  JR   Z, error_trnsf_file
.continue_sending INC  HL
                  DEC  BC
                  LD   A,B
                  OR   C
                  JR   NZ,send_file_buffer
                  JR   trnsf_file_loop
.end_transfer_file
                  CALL Close_file
                  LD   HL, ESC_E                     ; send EOF file marker to terminal
                  CALL SendString
                  RET  C
                  RET  Z
                  SCF
                  CCF
                  SET  0,A
                  OR   A                             ; indicate no error (Fz = 0, Fc = 0)
                  RET
.error_trnsf_file CALL Close_file
                  RET



; *********************************************************************
;
.Backup_files     CALL Set_Traflag
                  CALL Fetch_pathname                ; without ACKN protocol...
                  CALL Restore_Traflag
                  JR   C, backup_files_aborted
                  JR   Z, backup_files_aborted
                  LD   HL,filename_buffer
                  CALL Write_message                 ; display pathname on screen...
                  CALL SearchFilesystem              ; backup files...
                  RET  C
                  RET  Z
                  LD   HL, message18
                  CALL Write_message                 ; "Searching file system..."
                  CALL Get_Directories               ; for directories in all RAM devices
                  LD   HL, cli_filename
                  CALL Transfer_file                 ; send file with found directories
                  LD   HL, ESC_Z                     ; end of files...
                  CALL SendString
                  RET
.backup_files_aborted
                  CALL Msg_Command_aborted
                  RET



; ***********************************************************************
; HL points at string, A = wildcard search specifier
;
.Send_found_names CALL Get_Wcard_handle
                  CALL C,System_error
                  RET  C
                  LD   DE,0                          ; reset counters for found names
                  LD   HL,file_type
.read_names_loop  CALL Find_Next_Match               ; read names matching wildcard
                  JR   C, end_fetch_names
.fetch_name       CP   (HL)                          ; found the wanted file type?
                  JR   NZ, read_names_loop           ; no, get next filename match...
                  EX   DE,HL
                  LD   HL, ESC_N
                  CALL SendString
                  JR   C, end_Fetch_names
                  JR   Z, end_Fetch_names
                  LD   HL, filename_buffer           ; pointer to start name
                  CALL SendString
                  JR   C, end_Fetch_names
                  JR   Z, end_Fetch_names
                  EX   DE,HL
                  JR   read_names_loop
.end_fetch_names
                  CALL Close_Wcard_handler
                  SET  0,A                           ; no errors: Fc=0, Fz=0
                  OR   A
                  SCF
                  CCF
                  RET


; ***********************************************************************
.Fetch_pathname   LD   HL,filename_buffer
.pathname_loop    CALL Getbyte
                  RET  C
                  RET  Z
                  CP   ESC
                  JR   Z,ESCcmd_ident
                  LD   (HL),A
                  INC  HL
                  JR   pathname_loop
.ESCcmd_ident     CALL Getbyte                       ; either 'Z','F' or 'N'
                  RET  C
                  RET  Z
                  LD   (HL), 0                       ; Null-terminate received wildcard search path.
                  SET  0,A
                  OR   A                             ; signal succes
                  RET


; ***********************************************************************
; Fetch ESC [byte] sequense, without acknowledge, signalling A = &FF when received.
; This call also returns the translated byte from a ESC B xx sequense.
; The received (translated) byte will be in B register on return.
.FetchBytes       PUSH HL                            ; Preserve HL
                  CALL Getbyte                       ; byte in A.
                  JR   C, end_fetchbytes             ; system error
                  JR   Z, end_fetchbytes             ; timeout...
                  CP   ESC
                  JR   Z,fetch_ESC
                  LD   B,A
                  XOR  A                             ; Fc = 0, Fz = 1
                  CPL                                ; A = 255
                  OR   A                             ; Fc = 0, Fz = 0
                  CPL                                ; A = 0, no ESC id found.
                  POP  HL
                  RET
.fetch_ESC        CALL Getbyte                       ; byte in A.
                  JR   C, end_fetchbytes             ; system error
                  JR   Z, end_fetchbytes             ; timeout...
                  CP   ESC                           ; is it a ESC ESC sequense ?
                  JR   Z, ESC_byte
                  LD   B,A                           ; No,
                  LD   A,$FF                         ; but another ESC id...
                  SCF
                  CCF                                ; Fc = 0, Fz = 0
                  POP  HL
                  RET

.ESC_byte         LD   B,A
                  XOR  A                             ; Fc = 0, Fz = 1
                  CPL
                  OR   A                             ; Fz = 0
                  CPL                                ; no ESC id found. (A=0)
.end_fetchbytes   POP  HL
                  RET
