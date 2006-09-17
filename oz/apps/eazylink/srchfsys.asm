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

    MODULE Search_filesystem

    XREF Get_wcard_handle, Find_next_match, CLose_wcard_handler, Get_file_handle
    XREF System_Error
    XREF Transfer_file
    XREF Def_RamDev_wildc

    XDEF SearchFileSystem, Get_Directories
    XDEF rw_date
    XDEF cli_filename

    INCLUDE "defs.asm"
    INCLUDE "dor.def"
    INCLUDE "fileio.def"


; **********************************************************************************************************
;
.SearchFilesystem LD   A, 0                          ; wildcard search specifier - files before directories
                  CALL Get_wcard_handle              ; get handle for wildcard
                  JR   NC,filenames_loop
                  XOR  A                             ; no files found...
                  SET  0,A
                  OR   A                             ; indicate no error (Fz = 0, Fc = 0)
                  RET
.filenames_loop   CALL Find_Next_match               ; next file in wildcard search...
                  JR   C, stop_wcard_search          ; no more files from a wildcardcard search...
                  CP   dn_fil
                  JR   NZ, filenames_loop
                  CALL compare_dates
                  CP   $FF
                  JR   Z,new_file                    ; equal date stamps, proces file ...
                  JR   filenames_loop                ; already updated, continue ...
.new_file         LD   HL, filename_buffer
                  CALL Transfer_file                 ; transfer file without ACKN protocol...
                  JR   C, search_filer_aborted       ; Ups - transmission error
                  JR   Z, search_filer_aborted
                  LD   A,op_up                       ; Open for Update...
                  LD   HL, filename_buffer
                  LD   D,H
                  LD   E,L
                  CALL get_file_handle
                  CALL_OZ (gn_cl)                    ; Update file with new date stamp.
                  JR   filenames_loop                ; fetch next file name
.stop_wcard_search
                  SCF
                  CCF
                  SET  0,A
                  OR   A                             ; indicate no error (Fz = 0, Fc = 0)
.search_filer_aborted
                  CALL Close_wcard_handler
                  RET


.Get_directories  LD   A,op_out                      ; open type
                  LD   HL,cli_filename               ; create "DIRECTORIES.CLI" file,
                  LD   D,H
                  LD   E,L
                  CALL get_file_handle
                  JP   C, system_error
                  LD   A,3                           ; length of cli_cmd2
                  LD   HL,0
                  LD   (file_ptr), HL
                  LD   (file_ptr), A
                  LD   (file_ptr+2), HL              ; current length of file = 3
                  CALL_OZ(gn_cl)                     ; close file and
                  LD   A,op_up                       ; re-open (update)
                  LD   HL,cli_filename               ; "DIRECTORIES.CLI" file,
                  LD   DE,filename_buffer
                  CALL get_file_handle               ; to be ignored by search_filer...
                  LD   HL,cli_cmd2                   ; PRINT#ch,"#F"
                  CP   A                             ; length of string at pointer
                  CALL write_string                  ; to "directories.CLI"
                  JR   C,close_CLIfile               ; close file and return to caller
                  CALL_OZ (gn_cl)                    ; tmp close - DOR processing...
                  LD   A, 0                          ; wildcard search specifier...
                  CALL Def_RamDev_wildc
                  CALL Get_wcard_handle              ; now get RAM devices through wildcard handler
                  PUSH IX
.ram_names_loop   POP  IX                            ; handle for wildcard search
                  CALL Find_Next_Match
                  JR   C, exit_dir_search2
                  PUSH IX                            ; save handle for next RAM device fetch
                  CP   Dm_Dev                        ; is a RAM device?
                  JR   NZ,ram_names_loop             ; no get another name...
                  LD   A,op_dor
                  LD   HL, filename_buffer
                  LD   DE, file_buffer               ; explicit RAM device name
                  CALL get_file_handle               ; fetch DOR handle for RAM device
                  CALL C,System_error                ; report error...
                  JR   C,exit_dir_search1            ; stop directory search
                  EX   DE,HL                         ; HL points at end of RAM device name
                  LD   (HL), '/'                     ; end device name with '/'
                  INC  HL
                  LD   (HL), 0                       ; terminate string
                  PUSH IY                            ; save device name stack pointer
                  CALL Init_dir_pointers             ; prepare directory name stack...
                  CALL Get_Subdirectory              ; directory tree to "directories.CLI"
                  POP  IY
                  INC  IY
                  INC  IY                            ; point to next ram device name
                  JR   ram_names_loop
.close_CLIfile    PUSH AF                            ; save CARRY to indicate error
                  CALL_OZ (gn_cl)                    ; for calling program...
                  POP  AF
                  RET
.exit_dir_search1 POP  IX                            ; get wildcard search handle
.exit_dir_search2 CALL Close_wcard_handler           ; file system search completed
                  RET                                ; all directories stored as CLI commands.


.Get_Subdirectory LD   A,dr_son                      ; go to directory...
                  CALL_OZ (os_dor)
                  JR   C,no_elements                 ; no elements found
                  CALL push_directory_name           ; file name, add to list ...
                  CP   dn_dir                        ; a directory?
                  JR   NZ, read_current_dir
                  CALL print_directory_path
                  RET  C                             ; exit on write error
                  CALL Get_Subdirectory              ; check for names in subdirectory
                  RET  C
                  CALL fetch_current_directory       ; handle for current directory
.read_current_dir LD   A,dr_sib                      ; read names in current directory
                  CALL_OZ (os_dor)
                  JR   C,exit_subdirectory           ; no more names in current directory
                  CALL update_directory_name         ; exchange old file name with new.
                  CP   dn_dir                        ; new name, a directory?
                  JR   NZ,read_current_dir
                  CALL print_directory_path
                  RET  C                             ; file error...
                  CALL Get_Subdirectory              ; check for names in subdirectory
                  RET  C                             ; return on error...
                  CALL fetch_current_directory       ; handle for current directory
                  JR   read_current_dir

.exit_subdirectory
                  XOR  A                             ; reset CARRY. indicate no error
                  CALL pop_directory_name            ; remove current filename in list
                  RET                                ; (unstack current filename)
.no_elements      XOR A                              ; reset CARRY flag.
                  RET                                ; indicate no error to caller...


.print_directory_path                                ; print directory path to file.
                  LD   A,dr_fre
                  CALL_OZ (os_dor)                   ; free current DOR handle
                  LD   A,op_up
                  LD   HL,cli_filename
                  LD   DE, filename_buffer
                  CALL get_file_handle               ; open CLI directory file
                  LD   A,fa_ptr
                  LD   HL,file_ptr                   ; move file pointer to end of file.
                  CALL_OZ (os_fwm)
                  LD   HL,cli_cmd3                   ; write CLI command at the end
                  CP   A
                  CALL write_string
                  JR   C,end_print_directory_path
                  XOR  A                             ; search for null-terminator in
                  LD   HL,file_buffer                ; buffer to fetch length of filename
                  LD   BC,255                        ; buffer area
                  CPIR                               ; find byte...
                  DEC  HL                            ; file name without terminator
                  XOR  A                             ; reset Fc (if set)
                  LD   DE,file_buffer
                  SBC  HL,DE
                  LD   B,H
                  LD   C,L                           ; length of file name
                  SCF                                ; indicate BC = length of string
                  EX   DE,HL                         ; HL = pointer to beginning of directory path
                  CALL write_string                  ; write string to file...
                  JR   C,end_print_directory_path
                  LD   HL,cli_cmd5                   ; PRINT#ch,"~E"
                  CP   A                             ; Fc = 0, length of string at (HL)
                  CALL write_string

.end_print_directory_path
                  CALL_OZ (gn_cl)                    ; close "DIRECTORY.CLI" file
                  LD   H,B                           ; get length of file name
                  LD   L,C                           ;
                  LD   BC,8                          ; length of cli_cmd3 + cli_cmd5
                  ADD  HL,BC
                  LD   B,H
                  LD   C,L                           ; result in BC
                  LD   HL,(file_ptr)                 ; get current length of file
                  ADD  HL,BC                         ; and add length of filename and cli's
                  LD   (file_ptr), HL                ; store new length
                  CALL fetch_current_directory       ; continue to read DOR information
                  RET

.fetch_current_directory
                  LD   A,op_dor
                  LD   HL,file_buffer                ; filename of current directory
                  LD   D,H
                  LD   E,L
                  CALL get_file_handle
                  RET

.push_directory_name
                  PUSH AF                            ; save flags
                  LD   IY,(directory_ptr)            ; pointer to top of stack
                  LD   E,(IY+0)
                  LD   D,(IY+1)                      ; DE pointer to new directory name
                  DEC  DE                            ; pointer to end of previous name
                  LD   A,'/'                         ; delimeter for directory names
                  LD   (DE),A
                  INC  DE                            ; original pointer
                  PUSH DE                            ; save directory name to pointer
                  CALL dor_record_name               ; (IX = DOR handle)
                  LD   A,0                           ; search for null-terminator in
                  POP  HL                            ; buffer for directory name.
                  LD   BC,17                         ; read max 17 letters.
                  CPIR                               ; find byte...
                  INC  IY                            ; adress of next directory name
                  INC  IY                            ; increase directory stack pointer
                  LD   (IY+0),L
                  LD   (IY+1),H                      ; save pointer to free bytes
                  LD   (directory_ptr),IY            ; new top of stack.
                  POP  AF                            ; restore flags
                  RET

.pop_directory_name
                  PUSH AF
                  LD   IY,(directory_ptr)            ; adress of top of directory stack
                  LD   (IY+0),0                      ; remove pointer of cur. cat. name
                  LD   (IY+1),0
                  DEC  IY
                  DEC  IY
                  LD   (directory_ptr),IY            ; new top of stack
                  LD   L,(IY+0)
                  LD   H,(IY+1)                      ; pointer to new name
                  DEC  HL                            ; move to end of previous name
                  LD   A,0
                  LD   (HL),A                        ; null-terminate file name.
                  POP  AF
                  RET

.update_directory_name
                  PUSH AF
                  CALL pop_directory_name
                  CALL push_directory_name           ; stack new directory name
                  POP  AF
                  RET

;
; Print string to file.
;
; IN:
;       local pointer to string in HL
;       Fc = 1, length of string in C, other length of string at (HL)
;
.write_string     PUSH BC
                  PUSH DE
                  LD   B,0
                  JR   C,write_to_file
                  LD   C,(HL)
                  INC  HL
.write_to_file    LD   DE,0
                  CALL_OZ (os_mv)                   ; from memory to file...
                  CALL C,System_error
                  POP  DE
                  POP  BC
                  RET


.init_dir_pointers
                  PUSH HL
                  LD   HL, DirName_Stack+2
                  LD   (directory_ptr), HL            ; top of stack
                  LD   HL, file_buffer
                  LD   (DirName_Stack), HL            ; point at beginning of path
                  LD   HL, file_buffer+7
                  LD   (DirName_Stack+2), HL          ; point at end of ram device name...
                  POP  HL
                  RET


; ***********************************************************************
.Dor_record_name  PUSH HL                            ; write filename of current DOR
                  PUSH BC                            ; record at (DE)
                  LD   A,dr_rd
                  LD   B,dt_nam
                  LD   C,17                          ; filename of 16 bytes & terminator
                  CALL_OZ (os_dor)
                  POP  BC
                  POP  HL
                  RET


;*************************************************************
; DE = pointer to date buffer
.rw_date          PUSH HL                            ; H  = dr_rd | dr_wr
                  PUSH DE                            ; L  = Creation, Update date
                  LD   A,op_dor                      ; pointer to file name
                  LD   HL, filename_buffer           ; open DOR information to file.
                  LD   D,H
                  LD   E,L
                  CALL get_file_handle
                  JR   C, file_err
                  POP  DE                            ; buffer to date
                  POP  HL
                  LD   A,H                           ; A = dr_rd | dr_wr
                  LD   B,L                           ; B = ASC"C" | ASC"U"
                  LD   C,6                           ; C = buf. length (of date) => (DE)
                  CALL_OZ (os_dor)
                  LD   A,dr_fre
                  CALL_OZ (os_dor)                   ; close DOR to file.
                  RET
.file_err         POP  DE
                  POP  HL
                  RET

; *****************************************************
.compare_dates    PUSH BC
                  PUSH HL
                  PUSH DE
                  LD   DE,creation_date
                  LD   H,dr_rd
                  LD   L,'C'
                  CALL rw_date
                  LD   DE,update_date
                  LD   H,dr_rd
                  LD   L,'U'
                  CALL rw_date
                  LD   B,6
                  LD   DE,creation_date
                  LD   HL,update_date
.compare_loop     LD   A,(DE)
                  CP   (HL)
                  JR   NZ,not_equal_dates
                  INC  HL
                  INC  DE
                  DJNZ,compare_loop
.equal_dates      LD   A,$FF
                  JR   end_compare_dates
.not_equal_dates  XOR  A
.end_compare_dates
                  POP  DE
                  POP  HL
                  POP  BC
                  RET

.cli_filename     DEFM ":RAM.-/DIRECTORIES.CLI", 0
.cli_cmd2         DEFM 3, "#F", 13
.cli_cmd3         DEFM 5, "|CD|D"
.cli_cmd5         DEFM 3, "~E", 13
