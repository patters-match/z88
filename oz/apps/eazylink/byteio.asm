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

    MODULE Serialport_IO

    XREF ErrHandler
    XREF System_Error
    XREF Write_Message, Message2, ESC_B, ESC_ESC

    XDEF Check_synch, Send_Synch, Check_timeout, SendString, SendString_ackn
    XDEF Send_ESC, Send_ESC_byte_ackn
    XDEF GetByte, GetByte_ackn, PutByte, PutByte_ackn, TranslateByte
    XDEF Getbyte_raw_ackn
    XDEF Dump_serport_in_byte
    XDEF UseHWSerPort, UseOZSerPort

    INCLUDE "defs.asm"
    INCLUDE "fileio.def"
    INCLUDE "screen.def"
    INCLUDE "error.def"
    INCLUDE "blink.def"


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
.Getbyte
                  CALL RxByte                        ; receive a byte from serial port (OZ or hardware interface)
                  RET  C
                  RET  Z
                  PUSH HL
                  LD   HL,TraTableOut
                  CALL TranslateByte                 ; A = byte received & translated
                  POP  HL
.Getbyte_error    RET


; ***********************************************************************
; Get byte from serial port and acknowledge
;
.Getbyte_ackn
                  CALL RxByte                        ; receive a byte from serial port (OZ or hardware interface)
                  RET  C
                  RET  Z
                  PUSH DE
                  LD   D,A
                  XOR  A                             ; acknowledge byte...
                  CALL SxByte
                  LD   A,D
                  POP  DE
                  RET  C
                  RET  Z                             ; system error, e.g. ESC pressed...
                  PUSH HL
                  LD   HL,TraTableOut
                  CALL TranslateByte
                  POP  HL
                  RET


; ***********************************************************************
; Get byte and acknowledge (no translation)...
;
.Getbyte_raw_ackn
                  CALL RxByte                        ; receive a byte from serial port (OZ or hardware interface)
                  RET  C
                  RET  Z
                  PUSH DE
                  LD   D,A
                  XOR  A                             ; acknowledge byte...
                  CALL SxByte
                  LD   A,D
                  POP  DE
                  RET


; ***********************************************************************
.Putbyte          PUSH HL
                  LD   HL,TraTableIn
                  CALL TranslateByte                 ; A contains translated byte
                  POP  HL
                  CALL SxByte
                  RET


; ***********************************************************************
.Putbyte_ackn
                  PUSH HL                            ; save counter
                  LD   HL,TraTableIn
                  CALL TranslateByte                 ; A contains translated byte
                  POP  HL
                  CALL SxByte
                  RET  C
                  RET  Z
                  CALL RxByte                        ; receive acknowledge byte from serial port (OZ or hardware interface)
                  RET  C
                  RET  Z
                  RET


; ***********************************************************************
; Send byte to serial port without translation
.Putbyte_raw_ackn
                  CALL SxByte
                  RET  C
                  RET  Z
                  CALL RxByte                        ; receive a byte from serial port (OZ or hardware interface)
                  RET  C
                  RET  Z
                  RET

; ***********************************************************************
.RxByte           PUSH BC
                  LD   BC,3000
                  LD   IX,(serport_Inp_handle)
                  OZ   Os_Gbt                        ; get a byte from serial port, using OZ standard interface
.io_check         CALL C,Check_timeout
                  POP  BC
                  RET

; ***********************************************************************
.SxByte           PUSH BC
                  PUSH AF
                  POP  AF
                  LD   BC,3000
                  LD   IX,(serport_Out_handle)
                  OZ   Os_Pbt                        ; send byte to serial port, using OZ interface
                  JR   io_check


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
                  ADD  HL,BC                         ; Offset calculated to translated byte...
                  SET  0,A
                  OR   A                             ; reset C/Z flag, indicate no error, timeout
                  LD   A,(HL)                        ; get translated byte...
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

