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

    MODULE Serialport_IO

    XREF ErrHandler
    XREF System_Error
    XREF Write_Message, Message2, ESC_B, ESC_ESC

    XDEF Check_synch, Send_Synch, Check_timeout, SendString, SendString_ackn
    XDEF Send_ESC, Send_ESC_byte_ackn
    XDEF GetByte, GetByte_ackn, PutByte, PutByte_ackn, TranslateByte
    XDEF Getbyte_raw_ackn
    XDEF Dump_serport_in_byte

    INCLUDE "defs.asm"
    INCLUDE "fileio.def"
    INCLUDE "screen.def"
    INCLUDE "error.def"


; ***********************************************************************
; H = <startsynch>, L = <end_synch> ID
;
.Check_synch
.Synch_loop       CALL Getbyte                       ; byte in A.
                  RET  C                             ; system error
                  RET  Z                             ; timeout...
                  CP   L                             ; check end synch byte
                  JR   Z,synch_OK                    ; eof synch...
                  CP   H                             ; receive next synch byte?
                  JR   Z, Synch_loop                 ; synch byte, continue...
                  JR   bad_synch                     ; illegal <synch> ID received.
.synch_OK         SET  0,A
                  OR   A                             ; Z = 0, indicate succes,
                  RET                                ; A non-zero value...
.bad_synch        XOR  A                             ; Zero = 1
                  RET


; ***********************************************************************
.Send_synch       LD   B,2
.Send_synch_loop  LD   A,H                           ; start, body of synch...
                  CALL Putbyte                       ; B = length of synch...
                  RET  C                             ; return if ESC pressed
                  RET  Z                             ; return if timeout
                  DJNZ,Send_synch_loop
                  LD   A,L                           ; end of synch...
                  CALL Putbyte
                  RET


; ***********************************************************************
.Getbyte          PUSH BC
                  LD   BC,3000                       ; 30 sek. timeout
                  LD   IX,(serport_Inp_handle)
                  CALL_OZ (Os_Gbt)                   ; get a byte from serial port
                  CALL C,Check_timeout
                  JR   C,Getbyte_error
                  JR   Z,Getbyte_error
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  PUSH HL
                  LD   HL,TraTableOut
                  CALL TranslateByte                 ; byte in A
                  LD   B,A
                  SET  0,A                           ; reset Z flag, indicate no timeout
                  OR   A
                  LD   A,B                           ; A = byte received & translated
                  POP  HL
.Getbyte_error    POP  BC
                  RET




; ***********************************************************************
; Get byte and acknowledge...
;
.Getbyte_ackn     PUSH BC
                  LD   BC,3000                       ; 30 sek. timeout
                  LD   IX,(serport_Inp_handle)
                  CALL_OZ (Os_Gbt)                   ; get a byte from serial port
                  CALL C,Check_timeout               ; byte in A
                  JR   C,end_GetbyteAckn
                  JR   Z,end_GetbyteAckn
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  PUSH DE
                  LD   D,A
                  LD   A,0                           ; acknowledge byte...
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  LD   BC,1000
                  LD   IX,(serport_Out_handle)
                  CALL_OZ (Os_Pbt)
                  LD   A,D
                  POP  DE
                  CALL C,Check_timeout
                  JR   C,end_GetbyteAckn             ; system error, e.g. ESC pressed...
                  JR   Z,end_GetbyteAckn
                  PUSH HL
                  LD   HL,TraTableOut
                  CALL TranslateByte
                  LD   B,A
                  SET  0,A                           ; reset Z flag, indicate no timeout
                  OR   A
                  LD   A,B                           ; A = byte received & translated
                  POP  HL
.end_GetbyteAckn  POP  BC
                  RET

; ***********************************************************************
; Get byte and acknowledge (no translation)...
;
.Getbyte_raw_ackn PUSH BC
                  LD   BC,3000                       ; 30 sek. timeout
                  LD   IX,(serport_Inp_handle)
                  CALL_OZ (Os_Gbt)                   ; get a byte from serial port
                  CALL C,Check_timeout               ; byte in A
                  JR   C,end_Getbyte_raw_ackn
                  JR   Z,end_Getbyte_raw_ackn
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  PUSH DE
                  LD   D,A
                  LD   A,0                           ; acknowledge byte...
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  LD   BC,1000
                  LD   IX,(serport_Out_handle)
                  CALL_OZ (Os_Pbt)
                  LD   A,D
                  POP  DE
                  CALL C,Check_timeout
.end_Getbyte_raw_ackn
                  POP  BC
                  RET


; ***********************************************************************
.Putbyte          PUSH HL                            ; save counter
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  LD   HL,TraTableIn
                  CALL TranslateByte                 ; A contains translated byte
                  LD   IX,(serport_Out_handle)
                  CALL_OZ (Os_Pb)                    ; send byte to serial port
                  CALL C,Check_timeout               ; byte in A.
                  JR   C,Putbyte_error
                  JR   Z,Putbyte_error
                  SET  0,A
                  OR   A
.Putbyte_error    POP  HL
                  RET


; ***********************************************************************
.Putbyte_ackn     PUSH BC
                  PUSH HL                            ; save counter
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  LD   HL,TraTableIn
                  CALL TranslateByte                 ; A contains translated byte
                  LD   BC,1000                       ; 10 sek. timeout
                  LD   IX, (Serport_Out_handle)
                  CALL_OZ (Os_Pbt)                   ; send byte to serial port
                  CALL C,Check_timeout
                  JR   C,error_Putbyte_ackn          ; byte in A.
                  JR   Z,error_Putbyte_ackn
                  LD   BC,3000                       ; 30 sek. timeout.
                  LD   IX,(serport_Inp_handle)
                  CALL_OZ (Os_Gbt)
                  CALL C,Check_timeout
                  JR   C,error_Putbyte_ackn
                  JR   Z,error_Putbyte_ackn
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  SET  0,A                           ; reset Z flag, indicate no timeout
                  OR   A
.error_Putbyte_ackn
                  POP  HL
                  POP  BC
                  RET


; ***********************************************************************
; send byte without translation
.Putbyte_raw_ackn
                  PUSH BC
                  PUSH HL                            ; save counter
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  LD   BC,1000                       ; 10 sek. timeout
                  LD   IX, (Serport_Out_handle)
                  CALL_OZ (Os_Pbt)                   ; send byte to serial port
                  CALL C,Check_timeout
                  JR   C,error_Putbyte_raw_ackn      ; byte in A.
                  JR   Z,error_Putbyte_raw_ackn
                  LD   BC,3000                       ; 30 sek. timeout.
                  LD   IX,(serport_Inp_handle)
                  CALL_OZ (Os_Gbt)
                  CALL C,Check_timeout
                  JR   C,error_Putbyte_raw_ackn
                  JR   Z,error_Putbyte_raw_ackn
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  SET  0,A                           ; reset Z flag, indicate no timeout
                  OR   A
.error_Putbyte_raw_ackn
                  POP  HL
                  POP  BC
                  RET


; ***********************************************************************
; If Serial port input stream copy is enabled, then dump recently
; fetched byte into INPUT dump file
;
.Dump_serport_in_byte
                  PUSH HL
                  PUSH IX
                  PUSH AF

                  LD   HL,(serfile_in_handle)
                  LD   A,H
                  OR   L
                  JR   Z, exit_Dump_serport_in_byte    ; no dump file...

                  PUSH HL
                  POP  IX                   ; dump file handle
                  POP  AF
                  PUSH AF                   ; get byte from serial port
                  CALL_OZ (Os_Pb)           ; and dump a copy into debug file

.exit_Dump_serport_in_byte
                  POP  AF
                  POP  IX
                  POP  HL
                  RET


; ***********************************************************************
; If Serial port output stream copy is enabled, then dump
; output byte to serial into OUTPUT dump file
;
.Dump_serport_out_byte
                  PUSH HL
                  PUSH IX
                  PUSH AF

                  LD   HL,(serfile_out_handle)
                  LD   A,H
                  OR   L
                  JR   Z, exit_Dump_serport_out_byte   ; no dump file...

                  PUSH HL
                  POP  IX                   ; dump file handle
                  POP  AF
                  PUSH AF                   ; get byte to serial port
                  CALL_OZ (Os_Pb)           ; and dump a copy into debug file

.exit_Dump_serport_out_byte
                  POP  AF
                  POP  IX
                  POP  HL
                  RET


; ***********************************************************************
.Check_timeout    CALL ErrHandler
                  CP   RC_Time                       ; timeout?
                  JR   Z,timeout_flag
                  CALL System_error
                  SCF
                  RET                                ; other errors.
.timeout_flag     LD   HL,message2                   ; 'Waiting...'
                  CALL Write_message
                  XOR  A                             ; no system error, only timeout
                  RET                                ; Carry = 0, Zero = 1


; ***********************************************************************
; byte in A.
;
.TranslateByte    PUSH BC                            ; HL >> Translation Table
                  EX   AF,AF'                        ; save byte to/from serial port
                  LD   A,(tra_flag)
                  CP   $FF
                  JR   Z,tra_byte
                  EX   AF,AF'
                  POP  BC
                  RET
.tra_byte         EX   AF,AF'
                  LD   B,0
                  LD   C,A
                  ADD  HL,BC                         ; Offset calculated
                  LD   A,(HL)                        ; Translated byte...
                  POP  BC
                  RET


; ***********************************************************************
; Send sequense of bytes, untranslated.
;
.SendString_ackn  PUSH BC                            ; HL >> string, 0 terminated...
                  PUSH AF
.SendLoop_ackn    LD   A,(HL)
                  CP   0                             ; check for terminator
                  JR   Z,end_SendString_ackn
                  CALL Putbyte_ackn                  ; put byte to serial port
                  JR   C,err_SendString_ackn         ; error - stop transmit...
                  JR   Z,err_SendString_ackn
                  INC  HL                            ; byte sent , continue
                  JR   SendLoop_ackn
.end_SendString_ackn
                  POP  AF
                  LD   B,A
                  SET  0,A
                  OR   A                             ; reset Z flag.
                  LD   A,B                           ; restore original contents of A
                  POP  BC                            ; restore original contents of BC
                  RET
.err_SendString_ackn
                  EX   AF,AF'                        ; save contents of F register
                  POP  AF
                  LD   B,A
                  EX   AF,AF'                        ; restore F register
                  LD   A,B                           ; restore original contents of A
                  POP  BC                            ; restore original contents of BC
                  RET


; ***********************************************************************
; Send sequense of bytes
;
.SendString       PUSH BC                            ; HL >> string, 0 terminated...
                  PUSH AF
.SendLoop         LD   A,(HL)                        ; Carry if transmit error...
                  CP   0                             ; check for terminator
                  JR   Z,end_SendString
                  CALL Putbyte                       ; put byte to serial port
                  JR   C,err_SendString              ; error - stop transmit...
                  JR   Z,err_SendString
                  INC  HL                            ; byte sent , continue
                  JR   SendLoop
.end_SendString   POP  AF
                  LD   B,A
                  SET  0,A
                  OR   A                             ; reset Z flag.
                  LD   A,B                           ; restore original contents of A
                  POP  BC                            ; restore original contents of BC
                  RET
.err_SendString   EX   AF,AF'                        ; save contents of F register
                  POP  AF
                  LD   B,A
                  EX   AF,AF'                        ; restore F register
                  LD   A,B                           ; restore original contents of A
                  POP  BC                            ; restore original contents of BC
                  RET


; ***********************************************************************
.Send_ESC         PUSH HL
                  LD   HL,ESC_ESC
                  CALL SendString
                  POP  HL
                  RET


; ***********************************************************************
; send ESC B HH sequence of byte in A, acknowledged (PCLINK II protocol).
;
.Send_ESC_byte_ackn
                  PUSH BC
                  PUSH HL
                  LD   B,A

                  LD   A,$1B
                  CALL Putbyte_raw_ackn        ; send ESC
                  JR   C,exit_Send_ESC_byte_ackn
                  JR   Z,exit_Send_ESC_byte_ackn
                  LD   A,'B'
                  CALL Putbyte_raw_ackn        ; send 'B'
                  JR   C,exit_Send_ESC_byte_ackn
                  JR   Z,exit_Send_ESC_byte_ackn

                  LD   A,B
                  AND  $F0
                  RRCA
                  RRCA
                  RRCA
                  RRCA
                  CALL HexNibble
                  CALL Putbyte_raw_ackn        ; send high nibble in HEX of byte
                  JR   C,exit_Send_ESC_byte_ackn
                  JR   Z,exit_Send_ESC_byte_ackn

                  LD   A,B
                  AND  $0F
                  CALL HexNibble
                  CALL Putbyte_raw_ackn        ; send low nibble in HEX of byte

.exit_Send_ESC_byte_ackn
                  POP  HL
                  POP  BC
                  RET

.HexNibble        CP   $0A
                  JR   NC, HexNibble_16
                  ADD  A,$30
                  RET
.HexNibble_16     ADD  A,$37
                  RET

