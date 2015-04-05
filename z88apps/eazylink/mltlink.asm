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

    MODULE MultiLink4_commands

    LIB createfilename

    lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
    lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
    lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
    lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
    lib FileEprFindFile, FileEprFileImage, FileEprFileSize, FileEprTransferBlockSize
    lib SafeBHLSegment, MemDefBank
    lib ToUpper                   ; fast upper case conversion

    XREF ESC_Y, ESC_Z, ESC_N, ESC_F, ESC_E, CRLF, Current_Dir, Parent_Dir
    XREF Eprdev, ramdev_wildcard
    XREF TranslateByte
    XREF cli_filename
    XREF SendString, Send_ESC, PutByte, GetByte
    XREF Get_wcard_handle, Find_Next_Match, Close_wcard_handler
    XREF Abort_file, Get_file_handle, Reset_buffer_ptrs, Flush_buffer, Close_file
    XREF Write_buffer, Load_Buffer, Get_Time
    XREF Debug_message, Write_Message, Msg_Command_aborted, Msg_Protocol_error, Msg_File_aborted
    XREF Msg_file_received,Msg_No_Room, Msg_file_open_error, System_Error
    XREF Message3, Message4, Message5, Message6, Message7, Message14, Message15, Message16
    XREF Message17, Message18
    XREF Error_message6
    XREF Set_Traflag, Restore_Traflag, Def_RamDev_wildc, SearchFileSystem, Get_directories
    XREF Open_Serialport, Calc_hexnibble
    XREF FileEprSendFile, FileEprSaveFile, FileEprDeleteFile, SlotWriteSupport

    XDEF ESC_A_cmd2, ESC_H_cmd2, ESC_D_cmd2, ESC_N_cmd2, ESC_Q_cmd2
    XDEF SetEprDevName,CheckEprName,CheckRamName,CheckFileAreaOfSlot
    XDEF ImpExp_Send, ImpExp_Receive, ImpExp_Backup, Batch_Send
    XDEF FetchBytes,SendBuffer
    XDEF Transfer_filename, Transfer_RamfileImage
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
.ESC_H_cmd2       LD   HL,message5                   ; 'Devices'
                  CALL Debug_message
                  LD   A, Dm_Dev
                  LD   (file_type),A
                  LD   A, 0                          ; wildcard search specifier...
                  CALL Def_RamDev_wildc

                  CALL Send_found_names              ; internal & external RAM cards...
                  JR   C, esc_h2_aborted
                  JR   Z, esc_h2_aborted

                  CALL Send_Epr_devices              ; Send "EPR.X", if any file area is found...
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
; send directory names, extended protocol
;
.ESC_D_cmd2       LD   HL,message6
                  CALL Debug_message                 ; 'Directories'
                  CALL Set_Traflag                   ; translation ON temporarily
                  CALL Fetch_pathname
                  JR   C, esc_d2_aborted
                  JR   Z, esc_d2_aborted

                  LD   HL,filename_buffer            ; display pathname
                  CALL Debug_message
                  PUSH HL
                  LD   HL, Current_dir               ; Send "."
                  CALL SendString
                  POP  HL
                  JR   C, esc_d2_aborted
                  JR   Z, esc_d2_aborted

                  CALL CheckEprName                  ; Path begins with ":EPR.x"?
                  JR   Z, end_of_dirnames            ; Yes, indicate no directories in a file area...

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
.end_of_dirnames
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
.ESC_N_cmd2                                          ; send file names from :RAM.x and :EPR.x devices
                  CALL Set_Traflag
                  LD   HL,message7
                  CALL Debug_message                 ; 'File names'

                  CALL Fetch_pathname                ; load pathname into filename_buffer
                  JR   C, esc_n2_aborted
                  JR   Z, esc_n2_aborted             ; timeout - communication stopped

                  LD   HL,filename_buffer
                  CALL Debug_message

                  CALL CheckEprName                  ; Path begins with ":EPR.x"?
                  JR   Z, get_fa_filenames           ; Yes, try to fetch filenames from File Area...

                  LD   A,dn_fil
                  LD   (file_type),A                 ; signal filenames to be found
                  LD   A, 1                          ; wildcard search specifier
                  LD   HL, filename_buffer
                  CALL Send_found_names
                  JR   C, esc_n2_aborted
                  JR   Z, esc_n2_aborted             ; timeout - communication stopped
.no_more_names
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
.get_fa_filenames
                  call    CheckFileAreaOfSlot        ; Check if there is a file area in A = "0", "1", "2" or "3"
                  jr      c,no_more_names            ; this slot had no file area (no card)...
                  jr      nz,no_more_names           ; this slot had no file area (card, but no file area)

                  ld      a,c
                  or      $30
                  call    SetEprDevName              ; Begin filename with device name, ":EPR.x"

                  call    GetFirstEprFile            ; slot C => BHL of first entry in file area..
.send_fa_names    jr      c, no_more_names           ; no more entries in file area...

                  ld      de, filename_buffer+6      ; append filename at after ":EPR.x", null-terminated
                  call    FileEprFilename            ; copy filename from current file entry to (DE)
                  jr      c, no_more_names           ; no more entries in file area...

                  push    bc
                  push    hl
                  LD      HL, ESC_N
                  CALL    SendString
                  pop     hl
                  pop     bc
                  JR      C, esc_n2_aborted          ; abort if serial port timed out...
                  JR      Z, esc_n2_aborted

                  push    bc
                  push    hl
                  LD      HL, filename_buffer        ; pointer to start of EPR.x name and File area filename
                  CALL    SendString
                  pop     hl
                  pop     bc
                  JR      C, esc_n2_aborted
                  JR      Z, esc_n2_aborted

                  call    GetNextEprFile             ; get pointer to next File Entry in BHL...
                  jr      send_fa_names


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
                  LD   HL,message4                   ; 'Quit...'
                  CALL Debug_message
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
.Batch_Receive
.Batch_Receive_loop
                  CALL FetchBytes
                  JR   C, abort_batch_receive            ; system error
                  JR   Z, abort_batch_receive            ; timeout...
                  CP   $FF
                  LD   A,B
                  JR   NZ, err_protocol                  ; no ESC id, protocol error...
                  CP   'N'                               ; is it ESC "N" ?
                  JR   Z, fetch_flnm
                  CP   'Z'                               ; is it ESC 'Z' ?
                  JR   NZ, err_protocol                  ; no, protocol error...
                  RET                                    ; yes, return to main protocol command loop...

.err_protocol     CALL Msg_Protocol_error                ; write error messages on screen, and
                  CALL Msg_Command_aborted
                  XOR  A
                  RET

.Abort_receiving_file
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

                  CALL Get_Time                          ; read system time, to know elapsed time of received file

                  LD   B,0
                  LD   HL,filename_buffer
                  CALL Write_message                     ; write filename to screen

                  CALL CheckEprName                      ; Path begins with ":EPR.x"?
                  JR   Z, verify_write_filearea          ; Yes, validate if it is possible to receive file into File Area?

                  CALL createfilename
                  JP   C, RamFile_create_error

.file_created     LD   (file_handle),IX                  ; save file handle for later use
                  CALL Reset_buffer_ptrs                 ; buffer ready for new file...
.receive_file_loop
                  CALL FetchBytes
                  JR   C,Abort_receiving_file
                  JR   Z,Abort_receiving_file
                  CP   $FF                               ; fetched an ESC id?
                  LD   A,B
                  JR   NZ, byte_to_file                  ; no, still receiving byte to file
                  CP   'E'                               ; is it ESC 'E' ?
                  JR   Z, close_rcvd_file
                  CALL Msg_protocol_error
                  CALL Msg_File_aborted
                  CALL Abort_file
                  JR   abort_batch_receive
.close_rcvd_file                                     ; ESC 'E' received.
                  CALL Flush_buffer                  ; save contents of buffer...
                  CALL Close_file
                  CALL Msg_file_received
                  JP   Batch_Receive_loop            ; new file coming?
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
.void_file_loop                                      ; when an error occurred, receive the rest of the
                  CALL FetchBytes                    ; file until ESC E is received.... then back to main loop
                  JR   C,abort_batch_receive
                  JR   Z,abort_batch_receive
                  CP   $FF                           ; fetched an ESC id?
                  LD   A,B
                  JR   NZ, void_file_loop            ; no, still receiving bytes from files, which is ignored...
                  CP   'E'                           ; is it ESC 'E' ?
                  JR   NZ, void_file_loop
                  JP   Batch_Receive_loop            ; yes, EOF received, wait more files in Batch Receive (or receice End of Batch)..
.RamFile_create_error
                  CALL Msg_file_aborted              ; write 'File aborted' message
                  jr   void_file_loop                ; wait for end of file marker, then back to main loop

.verify_write_filearea
                  call CheckFileAreaOfSlot           ; file area in slot A = "0", "1", "2" or "3" => C = slot number
                  jr   c,FileEpr_create_error        ; this slot had no file area (no card)...
                  jr   nz,FileEpr_create_error       ; this slot had no file area (card, but no file area)
                  call SlotWriteSupport              ; slot C writeable?
                  jr   c,FileEpr_create_error

                  ld   de,filename_buffer+6          ; filename begins with "/" (skip ":EPR.x" device name)
                  call FileEprFindFile               ; filename already exists on file eprom?
                  push af                            ; remember found status... Fz = 1, if found
                  push bc
                  push hl

                  ld   de,File_buffer
                  ld   ix,128                        ; keep serial port buffer small, to avoid waiting timeout from client...
                  ld   hl,filename_buffer+6          ; filename begins with "/" (skip ":EPR.x" device name)
                  call FileEprSaveFile               ; blow file data stream into file card in slot C
                  jr   c, FileEpr_create_error
                  pop  hl                            ; file blown successfully to File Area
                  pop  bc
                  pop  af
                  call nz,Msg_file_received
                  jp   nz,Batch_Receive              ; mark old file as deleted?
                  call FileEprDeleteFile             ; (BHL = old file Entry) Yes, so new "version" from serial port becomes the active one..
                  jp   Batch_Receive
.FileEpr_create_error
                  pop  hl
                  pop  bc
                  pop  af
                  LD   HL, Error_message6            ; "File Card Write Error."
                  CALL Write_message
                  jr   void_file_loop                ; wait for end of file marker, then back to main loop


; *************************************************
.Batch_Send       CALL Set_Traflag
                  CALL Fetch_pathname                ; without ACKN protocol...
                  CALL Restore_Traflag
                  JR   C, err_batch_send
                  JR   Z, err_batch_send
                  LD   B,0
                  LD   HL,filename_buffer
                  CALL Write_message                 ; display pathname / wildcard on screen...

                  CALL CheckEprName                  ; Path begins with ":EPR.x"?
                  JR   Z, send_fa_entry              ; Yes, lookup entry, and transmit file image to serial port...

                  XOR  A                             ; wildcard search specifier - files before directories
                  CALL Get_wcard_handle              ; get handle in IX for pathname in (HL)
                  JR   C, wcard_system_error
.find_files_loop  CALL Find_next_match
                  JR   C, batch_send_end             ; no more files found in wildcard
                  CP   dn_fil
                  JR   NZ,find_files_loop            ; not a file - get next

                  LD   HL, message17
                  CALL_OZ (gn_sop)

                  LD   HL, filename_buffer
                  CALL Write_message
                  CALL Transfer_filename
                  JR   C, batch_send_aborted         ; transmission error...
                  JR   Z, batch_send_aborted

                  CALL Transfer_RamfileImage
                  JR   C, batch_send_aborted         ; transmission error...
                  JR   Z, batch_send_aborted

                  JR   find_files_loop
.batch_send_aborted
                  CALL Close_wcard_handler
.err_batch_send   CALL Msg_Command_aborted
                  XOR  A
                  RET
.batch_send_end   CALL Close_wcard_handler
.batch_send_escz
                  LD   HL, ESC_Z                     ; end of files...
                  CALL SendString
                  RET
.wcard_system_Error
                  XOR  A                             ; Fc = 0, only Fc = 1 if ESC pressed...
                  RET

; transmitting a single File Entry (File Area system doesnt support wild card search...)
.send_fa_entry
                  call    CheckFileAreaOfSlot        ; Check if there is a file area in A = "0", "1", "2" or "3"
                  jr      c,batch_send_escz          ; this slot had no file area (no card)...
                  jr      nz,batch_send_escz         ; this slot had no file area (card, but no file area)

                  ld      de,filename_buffer+6       ; search for filename beginning at "/" in filea area of slot C
                  call    FileEprFindFile            ; search for filename on file eprom...
                  jr      c,batch_send_escz          ; this slot had no file area (no card)...
                  jr      nz,batch_send_escz         ; File Entry was not found...

                  push    bc
                  push    hl                         ; preserve pointer to File Entry...
                  ld      hl,filename_buffer
                  call    Transfer_filename          ; First transmit filename
                  pop     hl
                  pop     bc
                  jr      c,err_batch_send           ; transmission error...
                  jr      z,err_batch_send

                  call    Send_EscF
                  jr      c,err_batch_send           ; transmission error...
                  jr      z,err_batch_send

                  call    FileEprSendFile            ; transmit single File Entry image to serial port
                  jr      c,err_batch_send           ; transmission error...
                  jr      z,err_batch_send

                  call    Send_EscE
                  jr      c,err_batch_send           ; transmission error...
                  jr      z,err_batch_send

                  jr      batch_send_escz            ; completed batach, send ESC Z


; ****************************************************'
; HL points at filename to be sent...
.Transfer_filename
                  EX   DE,HL                         ; save filename pointer in DE
                  LD   HL, ESC_N
                  CALL SendString
                  RET  C
                  RET  Z
                  LD   H,D
                  LD   L,E                           ; get a copy of filename
                  PUSH HL
                  CALL Set_Traflag
                  CALL SendString
                  CALL Restore_Traflag
                  POP  HL
                  RET

.Send_EscF
                  PUSH BC
                  PUSH HL
                  LD   HL, ESC_F
                  CALL SendString
                  POP  HL
                  POP  BC
                  RET
.Send_EscE
                  PUSH BC
                  PUSH HL
                  LD   HL, ESC_E
                  CALL SendString
                  POP  HL
                  POP  BC
                  RET

.Transfer_RamfileImage
                  CALL Send_EscF
                  RET  C
                  RET  Z

                  LD   A, op_in                      ; open file for transfer...
                  CALL Get_file_handle
                  CALL C, System_error
                  RET  C
                  LD   (file_handle), IX             ; save file handle
.trnsf_file_loop  CALL Load_buffer                   ; load new block into buffer...
                  JR   Z, End_transfer_file          ; EOF reached...

                  LD   BC,(buflen)
                  LD   HL,file_buffer                ; start of buffer
                  CALL SendBuffer
                  JR   C, error_trnsf_file
                  JR   Z, error_trnsf_file

                  JR   trnsf_file_loop
.end_transfer_file
                  CALL Close_file
                  CALL Send_EscE                     ; send EOF file marker to terminal
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
; Transmit buffer contents
; Handles CRLF conversion and ESC byte (transmits ESC ESC)
;
; IN:
;     BC = Buffer length
;     HL = Start of of buffer
;
; OUT:
;     Fc = 1, general tranmit error
;     Fz = 1, timeout
;
;     Fc = 0, Fz = 0 Buffer transmitted succesfully
;
.SendBuffer
                  LD   A,(HL)                        ; fetch byte from buffer
                  CP   ESC                           ; is byte ESC?
                  JR   NZ,test_CR
                  CALL Send_ESC                      ; send ESC ESC sequense
                  RET  C
                  RET  Z
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
                  RET  C
                  RET  Z
                  JR   continue_sending
.send_file_byte   CALL Putbyte                       ; put byte to serial port
                  RET  C
                  RET  Z
.continue_sending INC  HL
                  DEC  BC
                  LD   A,B
                  OR   C
                  JR   NZ,SendBuffer
                  SCF
                  CCF
                  SET  0,A
                  OR   A                             ; indicate no error (Fz = 0, Fc = 0)
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
                  CALL Transfer_filename             ; send file with found directories
                  JR   C, backup_files_aborted
                  JR   Z, backup_files_aborted
                  CALL Transfer_RamfileImage
                  JR   C, backup_files_aborted
                  JR   Z, backup_files_aborted

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
                  LD   (HL), 0                       ; Null-terminate received wildcard search path.
                  JR   pathname_loop
.ESCcmd_ident     CALL Getbyte                       ; either 'Z','F' or 'N'
                  RET  C
                  RET  Z
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


; ***********************************************************************
; Scan all slots for File Areas, and send ":EPR.x" accordingly.
.Send_Epr_devices
                  ld      bc,0
.poll_eprdev_loop ld      a,c
                  cp      4
                  jr      z,completed_Send_Epr_device ; all slots polled for Epr file area...
                  push    bc
                  call    FileEprRequest
                  pop     bc
                  ld      a,c
                  inc     bc                         ; ready for next slot
                  jr      c,poll_eprdev_loop         ; this slot had no file area (no card)... try next
                  jr      nz,poll_eprdev_loop        ; this slot had no file area (car, but no file area)... try next

                  push    bc                         ; preserve slot poll number
                  or      $30                        ; current slot as '0', '1', '2' or '3'
                  call    EprDev_name

                  LD      HL, ESC_N
                  CALL    SendString
                  JR      C, end_Send_Epr_device     ; abort if serial port timed out...
                  JR      Z, end_Send_Epr_device
                  LD      HL, filename_buffer        ; pointer to start of EPR.x name
                  CALL    SendString
                  JR      C, end_Send_Epr_device
                  JR      Z, end_Send_Epr_device
                  pop     bc
                  jr      poll_eprdev_loop
.completed_Send_Epr_device
                  or      a                          ; return Fc = 0, Fz = 0...
                  ret                                ; ESC Z has to be sent
.end_Send_Epr_device
                  pop     bc
.exit_Send_Epr_device
                  ret
.EprDev_name
                  ld      bc,5
                  ld      de,filename_buffer
                  push    de
                  ld      hl,eprdev
                  ldir
                  ld      (de),a                        ; append slot number
                  inc     de
                  xor     a
                  ld      (de),a                        ; null-terminate
                  pop     de
                  ret


; ***********************************************************************
; Check if there is a File Area in slot A = "0", "1", "2" or "3"
;
; returns Fz = 1, Fc = 0, if file area found, DE = size of cards in 16K banks
; otherwise Fc 1 or Fz = 0
;
.CheckFileAreaOfSlot
                  and     3                          ; strip to raw slot number number (0 - 3)
                  ld      c,a
                  push    bc
                  call    FileEprRequest
                  ld      d,0
                  ld      e,c                        ; C -> DE = size of card in 16K banks
                  pop     bc
                  ret


; ***********************************************************************
; Path begins with ":RAM." ?
;
; HL = pointer to path containing device / dir names
;
; returns A = slot number ('0', '1', '2' or '3' or '-'), if :RAM.x device recognized (Fz = 1)
;
.CheckRamName
                  push    bc
                  push    de
                  push    hl

                  ld      de,ramdev_wildcard
                  call    CheckDevName

                  pop     hl
                  pop     de
                  pop     bc
                  ret


; ***********************************************************************
; Path begins with ":EPR." ?
;
; HL = pointer to path containing device / dir names
;
; returns A = slot number ('0', '1', '2' or '3'), if :EPR.x device recognized (Fz = 1)
;
.CheckEprName
                  push    bc
                  push    de
                  push    hl

                  ld      de,eprdev
                  call    CheckDevName

                  pop     hl
                  pop     de
                  pop     bc
                  ret


; ***********************************************************************
; Path begins with ":XXX." 
;
; HL = pointer to path containing device / dir names
; DE = pointer to device name pattern
;
; returns A = slot number ('0', '1', '2', '3' or '-'), if device is recognized
;
.CheckDevName
                  ex      de,hl
                  ld      b,5
.cmp_loop
                  ld      a,(de)
                  call    ToUpper
                  cp      (hl)
                  ret     nz                         ; Fz = 0, no match
                  inc     hl
                  inc     de
                  djnz    cmp_loop
                  cp      a                          ; Fz = 1, match!
                  ld      a,(de)                     ; get slot number of file area
                  ret


; ***********************************************************************
; Set ":EPR.x" device name at (filename_buffer)
;
; IN: A = slot number ('0', '1', '2' or '3')
;
.SetEprDevName
                  push    bc
                  push    de
                  push    hl

                  ld      bc,5
                  ld      hl,eprdev
                  ld      de,filename_buffer
                  ldir
                  ld      (de),a
                  inc     de
                  xor     a
                  ld      (de),a

                  pop     hl
                  pop     de
                  pop     bc
                  ret

; *************************************************************************************
; Get pointer to first file entry. If only active files are currently displayed,
; deleted file entries are skipped until an active file entry is found.
;
; IN:
;    C = slot number of File area
;
; OUT:
;    Fc = 1, No file area or no file entries in file area.
;    Fc = 0
;         BHL = pointer to first file entry
;
.GetFirstEprFile
                    call FileEprFirstFile
                    ret  c
                    ret  nz                          ; an active file entry was found...
                                                     ; Fz = 1, skip deleted file(s) until active file is found
; *************************************************************************************


; *************************************************************************************
; Get pointer to next file entry. If only active files are currently displayed,
; deleted file entries are skipped until an active file entry is found.
;
; IN:
;    BHL = current file entry pointer
;
; OUT:
;    Fc = 1, End of list reached
;    Fc = 0
;         BHL = pointer to next file entry
;
.GetNextEprFile
.fetch_next_fe_loop
                    call FileEprNextFile
                    ret  c
                    ret  nz                          ; an active file entry was found...
                    jr   fetch_next_fe_loop          ; only active files, scan forward until active file..
; *************************************************************************************
