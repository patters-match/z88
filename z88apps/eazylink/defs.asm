; *************************************************************************************
; EazyLink - Fast Client/Server Remote File Management with PCLINK II protocol
;
; (C) Gunther Strube (gbs@users.sourceforge.net) 1990-2005
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

; Application Safe workspace

; Variabel Address definitions...
; All variables are put into the Safe workspace (defined for both 'PClink' and 'MultiLink' to 1072 bytes)

; EazyLink commands identifiers in lookup tables
DEFC TotalOfCmds = 33

DEFC RAM_pages = 6                 ; allocate 6 * 256 bytes contigous memory from $2000...

DEFC SerportXonXoffMode = 1        ; Parity No, Xon/Xoff Yes (serial port software handshake)
DEFC SerportHardwareMode = 2       ; Parity No, Xon/Xoff No (serial port hardware handshake)

; MTH Command Code Definitions
DEFC EazyLink_CC_dbgOn = $80       ; Serial Dump Enable
DEFC EazyLink_CC_dbgOff = $81      ; Serial Dump Disable


DEFVARS $2000                      ; work space buffer for popdown...
{
    CurrentSerportMode   ds.b 1    ; Software (1) or hardware handshake (2) mode
    SignalSerportMode    ds.b 1    ; a command signals a handshake mode (1 or 2)
    PollHandshakeCounter ds.b 1    ; Change handshake if signaled after 1 complete second timeout (10 X serial port timeouts)
    UserToggles          ds.b 1    ; various user toggles
    Cpy_PA_Txb           ds.b 3    ; Length byte + 2 byte Txb baud rate
    Cpy_PA_Rxb           ds.b 3    ; Length byte + 2 byte Txb baud rate
    Cpy_PA_Xon           ds.b 1    ; Copy of current Xon/Xoff
    Cpy_PA_Par           ds.b 1    ; Copy of current parity i Panel
    MenuBarPosn          ds.b 1    ; Y position of menu bar
    PopDownTimeout       ds.w 1    ; x centiseconds to timeout and Screen Off...
    file_type            ds.b 1    ; File type of current found file name in wildcard search
    tra_flag             ds.b 1    ; Translate-bytes-flag, $FF when active.
    tra_flag_copy        ds.b 1
    CRLF_flag            ds.b 1    ; $FF, when active
    HWSER_flag           ds.b 1    ; enable fast serial port I/O, $FF when active
    buffer               ds.w 1    ; Address of next free byte in buffer
    buflen               ds.b 1    ; Current length of buffer
    serport_Inp_handle   ds.w 1    ; Handle to serial port input
    serport_Out_handle   ds.w 1    ; Handle to serial port output.
    serfile_in_handle    ds.w 1    ; Handle to dump file of serial port input
    serfile_out_handle   ds.w 1    ; Handle to dump file of serial port output
    file_handle          ds.w 1    ; Handle of opened file (read/write)
    wildcard_handle      ds.w 1    ; Handle of current wildcard search
    Filename_buffer      ds.b 128  ; Buffer for filenames
    File_buffer          ds.b 255  ; Buffer for remote saving & loading of files
    TraTableIn           ds.b 256  ; ASCII translation lookup table, Z88
    TraTableOut          ds.b 256  ; ASCII translation lookup table, External computer
    Creation_date        ds.b 6    ; Temp store of a file's creation date
    Update_date          ds.b 6    ; Temp store of a file's update date
    file_ptr             ds.l 1
    directory_ptr        ds.w 1
    DirName_stack        ds.b 128
}
