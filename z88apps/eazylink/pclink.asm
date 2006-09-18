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

    MODULE Pclink_commands


    lib createfilename

    XREF ESC_Y, ESC_Z, ESC_N, ESC_F, ESC_E, CRLF, DM_Dev, Current_Dir, Parent_Dir
    XREF TranslateByte
    XREF ramdev_wildcard
    XREF SendString_ackn, Send_ESC_Byte_ackn, PutByte, PutByte_ackn, GetByte, GetByte_ackn
    XREF Getbyte_raw_ackn
    XREF Get_wcard_handle, Find_Next_Match, Close_wcard_handler
    XREF Abort_file, Get_file_handle, Reset_buffer_ptrs, Flush_buffer, Close_file
    XREF Write_buffer, Load_Buffer, Transfer_file
    XREF Write_Message, Msg_Command_aborted, Msg_Protocol_error, Msg_File_aborted
    XREF Msg_No_Room, Msg_file_open_error, System_Error, File_Open_Error
    XREF Message3, Message4, Message5, Message6, Message7, Message8, Message9, Message10
    XREF Message11, Message12
    XREF Set_Traflag, Restore_Traflag, SearchFileSystem, Get_directories
    XREF Open_Serialport, Calc_hexnibble

    XREF Create_directory

    XDEF ESC_A_cmd1, ESC_H_cmd1, ESC_D_cmd1, ESC_N_cmd1, ESC_S_cmd1, ESC_G_cmd1, ESC_Q_cmd1
    XDEF FetchBytes_ackn
    XDEF Def_Ramdev_wildc

    INCLUDE "rtmvars.def"
    INCLUDE "fileio.def"
    INCLUDE "dor.def"
    INCLUDE "ctrlchar.def"
    INCLUDE "error.def"


; ********************************************************************
; PCLINK II 'Hello'
;
.ESC_A_cmd1       LD   HL,ESC_Y
                  CALL SendString_ackn               ; return Yes...
                  JR   C, esc_a1_aborted
                  JR   Z, esc_a1_aborted
                  LD   HL,message3                   ; 'Hello'
                  CALL Write_message
                  XOR  A                             ; Zero = 1, signal continue
                  RET
.esc_a1_aborted   CALL Msg_Command_aborted
                  XOR  A
                  RET


; ***********************************************************************
; Send Z88 Devices, PC-LINK II protocol
;
.ESC_H_cmd1       LD   HL,message5                   ; 'Devices'
                  CALL Write_message
                  LD   A, Dm_Dev
                  LD   (file_type),A
                  LD   A, 0                          ; wildcard search specifier...
                  CALL Def_RamDev_wildc
                  LD   (buffer),HL                   ; set pointer to beginning of filename_buffer
                  CALL Send_found_names_ackn         ; internal & external RAM cards...
                  JR   C, esc_h1_aborted
                  JR   Z, esc_h1_aborted
                  LD   HL,ESC_Z                      ; no more names
                  CALL SendString_ackn
                  JR   C, esc_h1_aborted
                  JR   Z, esc_h1_aborted
                  XOR  A                             ; signal continue in main loop
                  RET                                ; (Z = 1)
.esc_h1_aborted   CALL Msg_Command_aborted
                  XOR  A
                  RET

.Def_RamDev_wildc LD   BC,7
                  LD   DE,filename_buffer
                  PUSH DE
                  LD   HL,ramdev_wildcard
                  LDIR
                  POP  HL
                  RET



; ***********************************************************************
; send directory names, PC-LINK II protocol
;
.ESC_D_cmd1
                  LD   HL,message6
                  CALL Write_message                 ; 'Directories'
                  CALL Set_Traflag                   ; translation ON temporarily
                  CALL Fetch_pathname_ackn
                  JR   C, esc_d1_aborted
                  JR   Z, esc_d1_aborted
                  LD   HL,filename_buffer            ; display pathname
                  CALL Write_message
                  PUSH HL
                  LD   HL, Current_dir               ; Send "."
                  CALL SendString_ackn
                  POP  HL
                  JR   C, esc_d1_aborted
                  JR   Z, esc_d1_aborted
                  CALL_OZ (Gn_Prs)                   ; parse pathname
                  LD   A,B                           ; B = no. of segments in path name
                  SUB  1                             ; without wildcard specifier '*'...
                  CP   1                             ; only 1 filename segment?
                  JR   Z,no_parent_dir_ackn          ; root directory...
                  LD   HL, Parent_dir                ; Send ".."
                  CALL SendString_ackn
                  JR   C, esc_d1_aborted
                  JR   Z, esc_d1_aborted
.no_parent_dir_ackn
                  LD   A,dn_dir
                  LD   (file_type),A                 ; find directories
                  LD   A, 1                          ; wildcard search specifier
                  LD   HL, filename_buffer
                  CALL Send_found_names_ackn
                  JR   C, esc_d1_aborted
                  JR   Z, esc_d1_aborted
                  LD   HL,ESC_Z                      ; no more names
                  CALL SendString_ackn
                  JR   C, esc_d1_aborted
                  JR   Z, esc_d1_aborted
                  JR   end_esc_d1
.esc_d1_aborted   CALL Msg_Command_aborted           ; write message and set Fz
.end_esc_d1       CALL Restore_Traflag
                  XOR  A
                  RET



; ***********************************************************************
.ESC_N_cmd1                        ; send file names
                  CALL Set_Traflag
                  LD   HL,message7
                  CALL Write_message                 ; 'File names'
                  CALL Fetch_pathname_ackn           ; load pathname into filename_buffer
                  JR   C, esc_n1_aborted
                  JR   Z, esc_n1_aborted             ; timeout - communication stopped
                  LD   HL,filename_buffer
                  CALL Write_message
                  LD   A,dn_fil
                  LD   (file_type),A                 ; signal filenames to be found
                  LD   A, 1                          ; wildcard search specifier
                  LD   HL, filename_buffer
                  CALL Send_found_names_ackn
                  JR   C, esc_n1_aborted
                  JR   Z, esc_n1_aborted             ; timeout - communication stopped
                  LD   HL,ESC_Z                      ; no more names
                  CALL SendString_ackn
                  JR   C, esc_n1_aborted
                  JR   Z, esc_n1_aborted             ; timeout - communication stopped
                  JR   end_esc_n1
                  .esc_n1_aborted
                  CALL Msg_Command_aborted           ; write message and set Fz
                  .end_esc_n1
                  CALL Restore_Traflag
                  XOR  A
                  RET



; ***********************************************************************
.ESC_S_cmd1                                          ; send files to Z88
                  LD   HL,message8
                  CALL Write_message                 ; 'Receive files'
                  CALL Receive_files_ackn
                  RET  C                             ; error (or ESC pressed)
                  XOR  A                             ; signal continue in main loop
                  RET                                ; (Z = 1)


; ***********************************************************************
.ESC_G_cmd1                                          ; receive file from Z88
                  LD   HL,message9
                  CALL Write_message
                  CALL Set_Traflag
                  CALL Fetch_pathname_ackn
                  CALL Restore_Traflag
                  JR   C, ESC_G_aborted
                  JR   Z, ESC_G_aborted
                  LD   HL,filename_buffer
                  CALL Write_message
                  LD   A,op_in
                  LD   D,H
                  LD   E,L
                  CALL Get_file_handle
                  JP   C,File_open_error
                  LD   (file_handle),IX
.transfer2_loop   CALL Load_buffer                   ; load new block into buffer...
                  JR   Z,end_transfer2_loop          ; EOF reached...
                  LD   A,(buflen)
                  LD   B,A
                  LD   HL,file_buffer                ; start of buffer
.send_buffer      LD   A,(HL)                        ; fetch byte from buffer
.check_CR         CP   CR                            ; is byte a CR?
                  JR   NZ,check_ctrl_byte
                  LD   A,(CRLF_flag)                 ; Yes,
                  CP   $FF                           ; extended to CRLF?
                  LD   A,CR
                  JR   NZ,check_ctrl_byte            ; no, check if byte is a control char
                  PUSH HL                            ; save buffer adr.
                  LD   HL,CRLF                       ; Send CRLF sequense
                  CALL SendString_ackn
                  POP  HL
                  JR   C,ESC_G_aborted
                  JR   Z,ESC_G_aborted
                  JR   continue_send_buffer
.check_ctrl_byte
                  CP   $20                           ; A < 32?
                  JR   NC,send_byte
                  CALL Send_ESC_byte_ackn            ; Yes, send ESC B HH sequense of byte...
                  JR   C,ESC_G_aborted
                  JR   Z,ESC_G_aborted
                  JR   continue_send_buffer
.send_byte
                  CALL Putbyte_ackn                  ; put byte to serial port
                  JR   C,ESC_G_aborted               ; (translate if instructed to)
                  JR   Z,ESC_G_aborted
.continue_send_buffer
                  INC  HL
                  DJNZ,send_buffer
                  JR   transfer2_loop
.end_transfer2_loop
                  CALL Close_file
                  LD   HL,ESC_Z
                  CALL SendString_ackn
                  JR   C, ESC_G_aborted
                  JR   Z, ESC_G_aborted
                  JR   end_esc_g1
.ESC_G_aborted    CALL Msg_Command_aborted           ; write 'Command aborted' message
                  CALL Close_file
.end_esc_g1       XOR  A                             ; signal continue in main loop
                  RET


; ***********************************************************************
.ESC_Q_cmd1                                          ; PCLINK II 'Quit'
                  LD   HL,ESC_Y
                  CALL SendString_ackn               ; return Yes...
                  JR   C, esc_q1_aborted
                  JR   Z, esc_q1_aborted
                  LD   HL,message4                   ; 'Quit...'
                  CALL Write_message
                  SET  0,A                           ; Zero = 0, signal 'Quit'...
                  OR   A
                  RET
.esc_q1_aborted   CALL Msg_Command_aborted
                  XOR  A
                  RET


; ***********************************************************************
; HL points at string, A = wildcard search specifier
;
.Send_found_names_ackn
                  CALL Get_Wcard_handle
                  CALL C,System_error
                  RET  C
                  LD   DE,0                          ; reset counters for found names
                  LD   HL,file_type
.read_names_loop_ackn
                  CALL Find_Next_Match               ; read names in current directory
                  JR   C, end_fetch_names_ackn
.fetch_name_ackn  CP   (HL)                          ; found the wanted file type?
                  JR   NZ, read_names_loop_ackn      ; no...
                  LD   B,H
                  LD   C,L
                  LD   HL, ESC_N
                  CALL SendString_ackn
                  JR   C, end_Fetch_names_ackn
                  JR   Z, end_Fetch_names_ackn
                  LD   HL, (buffer)                  ; pointer to start name
                  CALL SendString_ackn               ; (excl. current path name)
                  JR   C, end_Fetch_names_ackn
                  JR   Z, end_Fetch_names_ackn
                  LD   H,B                           ; restore pointer to file type
                  LD   L,C
                  JR   read_names_loop_ackn
.end_fetch_names_ackn
                  CALL Close_Wcard_handler
                  SET  0,A                           ; no errors: Fc=0, Fz=0
                  OR   A
                  SCF
                  CCF
                  RET


; ***********************************************************************
.Fetch_pathname_ackn
                  LD   HL,filename_buffer
.pathname_ackn_loop
                  CALL Getbyte_ackn
                  RET  C
                  RET  Z
                  CP   ESC
                  JR   Z,ESCcmd_ident_ackn
                  LD   (HL),A
                  INC  HL
                  JR   pathname_ackn_loop
.ESCcmd_ident_ackn
                  CALL Getbyte_ackn                  ; either 'Z' or 'F'
                  RET  C
                  RET  Z
                  LD   (buffer),HL                   ; save pointer to end of path name
                  LD   (HL), '*'                     ; wild card information with '*'
                  INC  HL
                  LD   (HL), 0                       ; Null-terminate received name.
                  SET  0,A
                  OR   A                             ; signal succes
                  RET


; ***********************************************************************
; Send files to Z88..
;
.Receive_files_ackn
                  CALL Getbyte_raw_ackn              ; byte in A.
                  JR   C, rec_file_aborted           ; system error
                  JR   Z, rec_file_aborted           ; timeout...
                  CP   ESC
                  JR   NZ, err_protocol_ackn         ; no ESC id, protocol error...
                  CALL Getbyte_raw_ackn              ; ESC command in A.
                  JR   C, rec_file_aborted           ; system error
                  JR   Z, rec_file_aborted           ; timeout...
                  CP   'N'                           ; is it ESC 'N' ?
                  JR   Z, fetch_flnm_ackn
                  CP   'Z'                           ; is it ESC 'Z' ?
                  JR   NZ, err_protocol_ackn         ; no, protocol error...
                  XOR  A                             ; ESC "Z" - receive files ended
                  RET
.err_protocol_ackn
                  CALL Msg_Protocol_error            ; write error messages on screen, and
.rec_file_aborted CALL Msg_Command_aborted
                  XOR  A                             ; return to main fetch synch loop
                  RET
.fetch_flnm_ackn  CALL Fetch_pathname_ackn           ; load filename into filename_buffer
                  JR   C,rec_file_aborted
                  JR   Z,rec_file_aborted            ; timeout - communication stopped
                  LD   HL,(buffer)                   ; get pointer to end of pathname
                  LD   (HL),0                        ; remove '*' wildcard...
                  LD   B,0
                  LD   HL,filename_buffer
                  CALL createfilename
                  JP   C, File_open_error            ; directory path couldn't be created
                  CALL Write_message                 ; display the name of file that is being transferred

.file_created     LD   (file_handle),IX              ; save file handle for later use
                  CALL Reset_buffer_ptrs             ; buffer ready for new file...
.transfer_loop_ackn
                  CALL Getbyte_ackn                  ; byte in A.
                  JP   C, ESC_S_aborted              ; system error
                  CP   ESC
                  JR   Z,fetch_ESC_ackn
                  JR   byte_to_file_ackn
.fetch_ESC_ackn
                  CALL Getbyte_raw_ackn              ; ESC command ...
                  JR   C, ESC_S_aborted              ; system error
                  CP   'B'
                  JR   NZ, is_eof_reached            ; check for ESC E...
                  CALL Getbyte_raw_ackn              ; ESC B HH sequense...
                  JR   C, ESC_S_aborted              ; system error
                  CALL Calc_HexNibble
                  RLCA
                  RLCA
                  RLCA
                  RLCA                               ; first hex nibble * 16
                  LD   B,A
                  CALL Getbyte_raw_ackn
                  JR   C, ESC_S_aborted              ; system error
                  CALL Calc_HexNibble                ; calculate second 4 bit nibble
                  OR   B                             ; byte calculated.
                  JR   byte_to_file_ackn

.is_eof_reached   CP   'E'                           ; is it ESC "E" (End Of File) ?
                  JR   Z, cl_rcvd_file_ackn
                  CALL Msg_protocol_error
                  CALL Msg_File_aborted
                  CALL Abort_file
                  JP   Receive_files_ackn            ; new file coming?
.cl_rcvd_file_ackn
                  CALL Flush_buffer                  ; save contents of buffer...
                  CALL Close_file                    ; ESC "E" received.
                  JP   Receive_files_ackn            ; new file coming?
.byte_to_file_ackn                                   ; byte in A to file...
                  CP   LF                            ; is it a line feed?
                  JR   NZ,no_linefeed_ackn
                  LD   A,(CRLF_flag)                 ; check CRLF flag
                  CP   $FF                           ; active?
                  LD   A,LF
                  JR   NZ,no_linefeed_ackn           ; not active - write LF to file...
                  JR   transfer_loop_ackn            ; - ignore LF (reverse CRLF) and fetch next byte...
.no_linefeed_ackn
                  CALL Write_buffer                  ; put byte into buffer
                  JR   C,no_memory_ackn              ; write error - memory full
                  JR   transfer_loop_ackn            ; fetch next byte from serial port
.no_memory_ackn   CALL Abort_file
                  CALL Getbyte                       ; get a byte
                  JR   C,ESC_S_aborted
                  JR   Z,ESC_S_aborted
                  CALL Msg_No_Room
                  CALL Msg_file_aborted
                  LD   A,$01                         ; to acknowledge back to terminal with error...
                  CALL Putbyte
                  RET  C
                  XOR  A
                  RET
.ESC_S_aborted    CALL Msg_Command_aborted            ; write 'Command aborted' message
                  CALL Abort_file
                  XOR  A
                  RET
