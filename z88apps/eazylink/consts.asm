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

    MODULE Constants


    XREF ESC_A_cmd1, ESC_H_cmd1, ESC_D_cmd1, ESC_N_cmd1, ESC_S_cmd1, ESC_G_cmd1, ESC_Q_cmd1
    XREF ESC_A_cmd2, ESC_H_cmd2, ESC_D_cmd2, ESC_N_cmd2, ESC_Q_cmd2
    XREF ImpExp_Send, ImpExp_Receive, ImpExp_Backup
    XREF ESC_T_cmd1, ESC_T_cmd2, ESC_C_cmd1, ESC_C_cmd2
    XREF ESC_V_cmd, ESC_X_cmd, ESC_U_cmd, ESC_U_cmd2, ESC_F_cmd
    XREF ESC_Z_cmd, ESC_R_cmd, ESC_Y_cmd, ESC_W_cmd, ESC_G_cmd2
    XREF ESC_m_cmd, ESC_p_cmd, ESC_E_cmd, ESC_M_cmd2

    XDEF TraFilename
    XDEF serial_port, ramdev_wildcard
    XDEF serdmpfile_in, serdmpfile_out
    XDEF pclink_synch, extended_synch
    XDEF menu_banner
    XDEF msg_serdmpfile_enable, msg_serdmpfile_disable
    XDEF Message1, Message2, Message3, Message4, Message5, Message6, Message7, Message8
    XDEF Message9, Message10, Message11, Message12, Message13, Message14, Message15
    XDEF Message16, Message17, Message18, Message19, Message20, Message21, Message22
    XDEF Message23, Message24, Message25, Message26, Message27, Message28
    XDEF Message29, Message30, Message31, Message32, Message33, Message34
    XDEF Message35, Message36
    XDEF Error_Message0, Error_Message1, Error_Message2, Error_Message3
    XDEF Error_Message4, Error_Message5
    XDEF ESC_Z, ESC_F, ESC_N, ESC_E, ESC_Y, ESC_B, ESC_ESC, CRLF
    XDEF Current_dir, Parent_dir
    XDEF BaudRate, No_Parameter, Yes_Parameter
    XDEF EscCommands, Subroutines
    XDEF IBM_TraTableIn, IBM_TraTableOut
    XDEF EasyLinkVersion
    XDEF Command_banner

    INCLUDE "rtmvars.def"
    INCLUDE "stdio.def"

; *********************************************************************************************************
; ***                      Static definitions; device & filenames, messages, etc.                        **
; *********************************************************************************************************

.EasyLinkVersion    DEFM "5.0-05", 0
.TraFilename        DEFM ":*//Translate.dat", 0
.serial_port        DEFM ":COM.0", 0
.ramdev_wildcard    DEFM ":RAM.*", 0
.serdmpfile_in      DEFM "/serdump.in", 0                        ; create files in default RAM device
.serdmpfile_out     DEFM "/serdump.out", 0
.msg_serdmpfile_enable DEFM "Serial port logging enabled"  , 0
.msg_serdmpfile_disable DEFM "Serial port logging disabled", 0
.pclink_synch       DEFB 5, 6
.extended_synch     DEFB 1, 2

.menu_banner        DEFM "EazyLink V5.0.5.DEV", 0
.command_banner     DEFM "Commands", 0
.message1           DEFM "Running",    0
.message2           DEFM "Waiting...", 0
.message3           DEFM "Hello", 0
.message4           DEFM "Quit...",    0
.message5           DEFM "Devices",    0
.message6           DEFM "Directories", 0
.message7           DEFM "Files", 0
.message8           DEFM "Receive files", 0
.message9           DEFM "Send file"   , 0
.message10          DEFM "Auto Translation ON"   , 0
.message11          DEFM "Auto Translation OFF", 0
.message12          DEFM "Auto CRLF Conversion ON", 0
.message13          DEFM "Auto CRLF Conversion OFF"   , 0
.message14          DEFM "ImpExp Receive Files", 0
.message15          DEFM "ImpExp Send Files",    0
.message16          DEFM "ImpExp Backup Files"   , 0
.message17          DEFM "Sending ", 0
.message18          DEFM "Searching for directories...", 0
.Message19          DEFM "Using translations from file"   , 0
.message20          DEFM "Using ISO/IBM translations",    0
.message21          DEFM "EazyLink Release, Protocol Version", 0
.message22          DEFM "File Size", 0
.message23          DEFM "File Date Stamp", 0
.message24          DEFM "File exist?", 0
.message25          DEFM "Set File Date Stamp", 0
.message26          DEFM "Update Translation Table", 0
.message27          DEFM "Delete file/dir ", 0
.message28          DEFM "Create dir ", 0
.message29          DEFM "Rename file ", 0
.message30          DEFM "Get default device/dir", 0
.message31          DEFM "Get Estimated Free Memory", 0
.message32          DEFM "Set System Clock", 0
.message33          DEFM "Get System Clock", 0
.message34          DEFM "Get Explicit Free Memory", 0
.message35          DEFM "Switching to Xon/Xoff serial port handshake", 0
.message36          DEFM "Switching to Hardware serial port handshake", 0

.error_message0     DEFM "Escape pressed....", 0
.error_message1     DEFM "File open error.", 0
.error_message2     DEFM "- command aborted...", 0
.error_message3     DEFM "Protocol error: Unknown ESC command.", 0
.error_message4     DEFM "File aborted.", 0
.error_message5     DEFM "No Room.", 0

.ESC_Z              DEFM ESC, "Z", 0
.ESC_F              DEFM ESC, "F", 0
.ESC_E              DEFM ESC, "E", 0
.ESC_N              DEFM ESC, "N", 0
.ESC_Y              DEFM ESC, "Y", 0
.ESC_B              DEFM ESC, "B", 0
.ESC_ESC            DEFM ESC, ESC, 0
.CRLF               DEFB CR, LF, 0

.Current_dir        DEFM ESC, "N", ".", 0
.Parent_dir         DEFM ESC, "N", "..", 0

.BaudRate           DEFW 9600   ; Values to be installed in Receive & Transmit Baud Rate
.No_Parameter       DEFB 'N'
.Yes_Parameter      DEFB 'Y'

; Lookup table of commands available.
; total of commands defined in "defs.asm"
.EscCommands        DEFB 'A'                 ; PCLINK  II 'Hello'
                    DEFB 'H'                 ; PCLINK  II Devices
                    DEFB 'D'                 ; PCLINK  II Directories
                    DEFB 'N'                 ; PCLINK  II Files
                    DEFB 'S'                 ; PCLINK  II Send file (from Z88)
                    DEFB 'G'                 ; PCLINK  II Receive f. (from term.)
                    DEFB 'Q'                 ; PCLINK  II Quit
                    DEFB 'a'                 ; EasyLink 'Hello'
                    DEFB 'h'                 ; EasyLink Devices
                    DEFB 'd'                 ; EasyLink Directories
                    DEFB 'n'                 ; EasyLink Files
                    DEFB 's'                 ; EasyLink Send files (ImpExp)
                    DEFB 'b'                 ; EasyLink Receive files (ImpExp)
                    DEFB 'k'                 ; EasyLink Backup files
                    DEFB 'q'                 ; EasyLink Quit
                    DEFB 't'                 ; EasyLink Translation   ON
                    DEFB 'T'                 ; EasyLink Translation   OFF
                    DEFB 'c'                 ; EasyLink CRLF translation   ON
                    DEFB 'C'                 ; EasyLink CRLF translation   OFF
                    DEFB 'v'                 ; EasyLink Application & Protocol version ("X.X-pp")
                    DEFB 'x'                 ; EasyLink File Size
                    DEFB 'u'                 ; EasyLink File Update Date Stamp
                    DEFB 'U'                 ; EasyLink Set File Date Stamp
                    DEFB 'f'                 ; EasyLink File Exist query
                    DEFB 'z'                 ; EasyLink Install translation table
                    DEFB 'r'                 ; EasyLink Delete file on Z88
                    DEFB 'y'                 ; EazyLink Create directory on Z88
                    DEFB 'w'                 ; EazyLink Rename Filename on Z88
                    DEFB 'g'                 ; EazyLink Get default Device/Directory
                    DEFB 'm'                 ; EazyLink Get Estimated Free Memory
                    DEFB 'p'                 ; EazyLink Set System Clock
                    DEFB 'e'                 ; EazyLink Get System Clock
                    DEFB 'M'                 ; EazyLink Get Explicit Free Memory (for RAM device)

.subroutines        DEFW ESC_A_cmd1          ; Address of subroutines:
                    DEFW ESC_H_cmd1
                    DEFW ESC_D_cmd1
                    DEFW ESC_N_cmd1
                    DEFW ESC_S_cmd1
                    DEFW ESC_G_cmd1
                    DEFW ESC_Q_cmd1          ; Address of   PCLINK II 'Quit'
                    DEFW ESC_A_cmd2          ;     - "" -   MultiLink 'Hello' command
                    DEFW ESC_H_cmd2          ; ESC "h"
                    DEFW ESC_D_cmd2          ; ESC "d"
                    DEFW ESC_N_cmd2          ; ESC "n"
                    DEFW ImpExp_Send         ; ESC "s"
                    DEFW ImpExp_Receive      ; ESC "b"
                    DEFW ImpExp_Backup       ; ESC "k"
                    DEFW ESC_Q_cmd2          ; ESC "q"
                    DEFW ESC_T_cmd1          ; ESC "T"
                    DEFW ESC_T_cmd2          ; ESC "t"
                    DEFW ESC_C_cmd1          ; ESC "C"
                    DEFW ESC_C_cmd2          ; ESC "c"
                    DEFW ESC_V_cmd           ; ESC "v"
                    DEFW ESC_X_cmd           ; ESC "x"
                    DEFW ESC_U_cmd           ; ESC "u"
                    DEFW ESC_U_cmd2          ; ESC "U"
                    DEFW ESC_F_cmd           ; ESC "f"
                    DEFW ESC_Z_cmd           ; ESC "z"
                    DEFW ESC_R_cmd           ; ESC "r"
                    DEFW ESC_Y_cmd           ; ESC "y"
                    DEFW ESC_W_cmd           ; ESC "w"
                    DEFW ESC_G_cmd2          ; ESC "g"
                    DEFW ESC_M_cmd           ; ESC "m"
                    DEFW ESC_P_cmd           ; ESC "p"
                    DEFW ESC_E_cmd           ; ESC "e"
                    DEFW ESC_M_cmd2          ; ESC "M"

; Z88 ISO - IBM translation table
;
.IBM_TraTableIn     DEFB $00, $01, $02, $03
                    DEFB $04, $05, $06, $07
                    DEFB $08, $09, $0A, $0B
                    DEFB $0C, $0D, $0E, $0F
                    DEFB $10, $11, $12, $13
                    DEFB $14, $15, $16, $17
                    DEFB $18, $19, $1A, $1B
                    DEFB $1C, $1D, $1E, $1F
                    DEFB $20, $21, $22, $23
                    DEFB $24, $25, $26, $27
                    DEFB $28, $29, $2A, $2B
                    DEFB $2C, $2D, $2E, $2F
                    DEFB $30, $31, $32, $33
                    DEFB $34, $35, $36, $37
                    DEFB $38, $39, $3A, $3B
                    DEFB $3C, $3D, $3E, $3F
                    DEFB $40, $41, $42, $43
                    DEFB $44, $45, $46, $47
                    DEFB $48, $49, $4A, $4B
                    DEFB $4C, $4D, $4E, $4F
                    DEFB $50, $51, $52, $53
                    DEFB $54, $55, $56, $57
                    DEFB $58, $59, $5A, $5B
                    DEFB $5C, $5D, $5E, $5F
                    DEFB $60, $61, $62, $63
                    DEFB $64, $65, $66, $67
                    DEFB $68, $69, $6A, $6B
                    DEFB $6C, $6D, $6E, $6F
                    DEFB $70, $71, $72, $73
                    DEFB $74, $75, $76, $77
                    DEFB $78, $79, $7A, $7B
                    DEFB $7C, $7D, $7E, $7F
                    DEFB $80, $81, $82, $83
                    DEFB $84, $85, $86, $87
                    DEFB $88, $89, $8A, $8B
                    DEFB $8C, $8D, $8E, $8F
                    DEFB $90, $91, $92, $93
                    DEFB $94, $95, $96, $97
                    DEFB $98, $99, $9A, $9B
                    DEFB $9C, $9D, $9E, $9F
                    DEFB $A0, $AD, $BD, $9C
                    DEFB $A4, $A5, $DD, $F5
                    DEFB $A8, $B8, $AA, $AE
                    DEFB $AC, $AD, $A9, $AF
                    DEFB $F8, $B1, $B2, $B3
                    DEFB $B4, $B5, $B6, $B7
                    DEFB $B8, $B9, $BA, $AF
                    DEFB $BC, $BD, $BE, $A8
                    DEFB $B7, $B5, $B6, $C7
                    DEFB $8E, $8F, $92, $80
                    DEFB $D4, $90, $D2, $D3
                    DEFB $DE, $D6, $D7, $D8
                    DEFB $D1, $A5, $E3, $E0
                    DEFB $E2, $E5, $99, $9E
                    DEFB $9D, $EB, $E9, $EA
                    DEFB $9A, $ED, $E7, $E1
                    DEFB $85, $A0, $83, $C6
                    DEFB $84, $86, $91, $87
                    DEFB $8A, $82, $88, $89
                    DEFB $8D, $A1, $8C, $8B
                    DEFB $D0, $A4, $95, $A2
                    DEFB $93, $E4, $94, $F6
                    DEFB $9B, $97, $A3, $96
                    DEFB $81, $EC, $E8, $98

.IBM_TraTableOut    DEFB $00, $01, $02, $03
                    DEFB $04, $05, $06, $07
                    DEFB $08, $09, $0A, $0B
                    DEFB $0C, $0D, $0E, $0F
                    DEFB $10, $11, $12, $13
                    DEFB $14, $15, $16, $17
                    DEFB $18, $19, $1A, $1B
                    DEFB $1C, $1D, $1E, $1F
                    DEFB $20, $21, $22, $23
                    DEFB $24, $25, $26, $27
                    DEFB $28, $29, $2A, $2B
                    DEFB $2C, $2D, $2E, $2F
                    DEFB $30, $31, $32, $33
                    DEFB $34, $35, $36, $37
                    DEFB $38, $39, $3A, $3B
                    DEFB $3C, $3D, $3E, $3F
                    DEFB $40, $41, $42, $43
                    DEFB $44, $45, $46, $47
                    DEFB $48, $49, $4A, $4B
                    DEFB $4C, $4D, $4E, $4F
                    DEFB $50, $51, $52, $53
                    DEFB $54, $55, $56, $57
                    DEFB $58, $59, $5A, $5B
                    DEFB $5C, $5D, $5E, $5F
                    DEFB $60, $61, $62, $63
                    DEFB $64, $65, $66, $67
                    DEFB $68, $69, $6A, $6B
                    DEFB $6C, $6D, $6E, $6F
                    DEFB $70, $71, $72, $73
                    DEFB $74, $75, $76, $77
                    DEFB $78, $79, $7A, $7B
                    DEFB $7C, $7D, $7E, $7F
                    DEFB $C7, $FC, $E9, $E2
                    DEFB $E4, $E0, $E5, $E7
                    DEFB $EA, $EB, $E8, $EF
                    DEFB $EE, $EC, $C4, $C5
                    DEFB $C9, $E6, $C6, $F4
                    DEFB $F6, $F2, $FB, $F9
                    DEFB $FF, $D6, $DC, $F8
                    DEFB $A3, $D8, $D7, $9F
                    DEFB $E1, $ED, $F3, $FA
                    DEFB $F1, $D1, $A6, $A7
                    DEFB $BF, $AE, $AA, $AB
                    DEFB $AC, $A1, $AB, $BB
                    DEFB $B0, $B1, $B2, $B3
                    DEFB $B4, $C1, $C2, $C0
                    DEFB $A9, $B9, $BA, $BB
                    DEFB $BC, $A2, $BE, $BF
                    DEFB $C0, $C1, $C2, $C3
                    DEFB $C4, $C5, $E3, $C3
                    DEFB $C8, $C9, $CA, $CB
                    DEFB $CC, $CD, $CE, $CF
                    DEFB $F0, $D0, $CA, $CB
                    DEFB $C8, $D5, $CD, $CE
                    DEFB $CF, $D9, $DA, $DB
                    DEFB $DC, $A6, $CC, $DF
                    DEFB $D3, $DF, $D4, $D2
                    DEFB $F5, $D5, $E6, $DE
                    DEFB $FE, $DA, $DB, $D9
                    DEFB $FD, $DD, $EE, $EF
                    DEFB $F0, $F1, $F2, $F3
                    DEFB $F4, $A7, $F7, $F7
                    DEFB $B0, $F9, $FA, $FB
                    DEFB $FC, $FD, $FE, $FF
