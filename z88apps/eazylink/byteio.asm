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

    INCLUDE "rtmvars.def"
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
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
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
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  PUSH DE
                  LD   D,A
                  XOR  A                             ; acknowledge byte...
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
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
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  PUSH DE
                  LD   D,A
                  XOR  A                             ; acknowledge byte...
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  CALL SxByte
                  LD   A,D
                  POP  DE
                  RET


; ***********************************************************************
.Putbyte          PUSH HL
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  LD   HL,TraTableIn
                  CALL TranslateByte                 ; A contains translated byte
                  POP  HL
                  CALL SxByte
                  RET


; ***********************************************************************
.Putbyte_ackn
                  PUSH HL                            ; save counter
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  LD   HL,TraTableIn
                  CALL TranslateByte                 ; A contains translated byte
                  POP  HL
                  CALL SxByte
                  RET  C
                  RET  Z
                  CALL RxByte                        ; receive acknowledge byte from serial port (OZ or hardware interface)
                  RET  C
                  RET  Z
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  RET


; ***********************************************************************
; Send byte to serial port without translation
.Putbyte_raw_ackn
                  CALL Dump_serport_out_byte         ; dump to debugging serport output file (if enabled)
                  CALL SxByte
                  RET  C
                  RET  Z
                  CALL RxByte                        ; receive a byte from serial port (OZ or hardware interface)
                  RET  C
                  RET  Z
                  CALL Dump_serport_in_byte          ; dump to debugging serport input file (if enabled)
                  RET

; ***********************************************************************
.RxByte           PUSH BC
                  LD   A,(HWSER_flag)                ; use fast serial port I/O?
                  OR   A
                  JR   Z, use_oz_gbt
                  LD   A,30                          ; 30 sek. timeout
                  CALL hw_rxbt                       ; get a byte from serial port, using direct hardware
                  JR   io_check
.use_oz_gbt       LD   BC,3000
                  LD   IX,(serport_handle)
                  OZ   Os_Gbt                        ; get a byte from serial port, using OZ standard interface
.io_check         CALL C,Check_timeout
                  POP  BC
                  RET

; ***********************************************************************
.SxByte           PUSH BC
                  PUSH AF
                  LD   A,(HWSER_flag)                ; use fast serial port I/O?
                  OR   A
                  JR   Z, use_oz_pbt
                  POP  AF
                  CALL hw_txbt                       ; send byte to serial port, using direct hardware
                  JR   io_check
.use_oz_pbt       POP  AF
                  LD   BC,3000
                  LD   IX,(serport_handle)
                  OZ   Os_Pbt                        ; send byte to serial port, using OZ interface
                  JR   io_check


; ***********************************************************************
; Transmit byte using Serial Port Hardware using 30 second timeout.
; (Based on original routine kindly provided by Dennis Gröning)
;
; IN:
;       A = byte to send
; OUT:
;         Success:
;              Fc = 0, Fz = 0
;         Failure:
;              Fc = 1, couldn't transmit byte within timeout
;              A = RC_Time
;
; Registers changed on return:
;    A.BCDEHL/IXIY ........ same
;    .F....../.... afbc.... different
;
.hw_txbt            exx
                    ex   af,af'                        ; preserve byte to send in A'
                    ld   b,30
                    call get_timeout_sec               ; return B to be 31 seconds ahead of current BL_TIM1
.hw_pollsend
                    in   a,(bl_uit)                    ; check TDRE
                    bit  bb_uittdre,a
                    jr   nz,tx                         ; hardware ready to transmit a new byte..
.tx_check_timeout
                    call get_sec                       ; get current second counter from Blink hardware
                    cp   b                             ; reached timeout?
                    jr   z,signal_fail                 ; couldn't transmit byte within timeout

                    ld   a,@01111111                   ; Read row A15 (containing ESC key)
                    in   a,(bl_kbd)
                    cp   @11011111                     ; ESC pressed?
                    jr   z, esc_pressed
                    jr   hw_pollsend                   ; still time left to poll for transmit ready state...
.tx
                    ex   af,af'                        ; send byte in A to serial port
                    ld   bc, [6<<8] | bl_txd
                    out  (c),a
                    ld   b,a
                    or   $ff                           ; signal success, Fc = 0, Fz = 0
                    ld   a,b
                    exx
                    ret
.signal_fail
                    exx
                    ld   a, RC_Time                    ; report time out error code
                    scf
                    ret
.esc_pressed
                    exx
                    ld   a, RC_Esc                     ; report ESC error code
                    scf
                    ret


; ***********************************************************************
; Receive byte using Serial Port Hardware, wait until available.
; (Based on original routine kindly provided by Dennis Gröning)
;
; IN:
;       -
; OUT:
;      Success:
;      Fc = 0
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbc.... different
;
;
.hw_rxb             exx
.hw_rxwait          in   a,(bl_uit)
                    bit  bb_uitrdrf,a
                    jr   z,hw_rxwait                    ; wait until byte is available.
                    jr   rx

; **********************************************************************
; Receive byte with timeout using Serial Port Hardware
; (Based on original routine kindly provided by Dennis Gröning)
;
; IN:
;       A = timeout in seconds (<=59)
; OUT:
;         Success:
;              Fc = 0, A = received byte
;         Failure:
;              Fc = 1, couldn't receive a byte within timeout
;              A = RC_Time
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbc.... different
;
.hw_rxbt
                    exx
                    ld   b,a                           ; timeout in seconds
                    call get_timeout_sec               ; return B to be 31 seconds ahead of current BL_TIM1
.hw_pollreceive
                    in   a,(bl_uit)
                    bit  bb_uitrdrf,a                  ; byte ready in serial port hw register?
                    jr   nz,rx                         ; yes, go fetch it...
.rx_check_timeout
                    call get_sec                       ; get current second counter from Blink hardware
                    cp   b                             ; reached timeout?
                    jr   z,signal_fail                 ; couldn't receive byte within timeout

                    ld   a,@01111111                   ; Read row A15 (containing ESC)
                    in   a,(bl_kbd)
                    cp   @11011111                     ; ESC pressed?
                    jr   z, esc_pressed
                    jr   hw_pollreceive
.rx
                    in   a,(bl_rxd)                    ; get byte from serial port hardware
                    ld   b,a
                    or   $ff                           ; signal success, Fc = 0, Fz = 0
                    ld   a,b
                    exx
                    ret

; ***********************************************************************
.get_timeout_sec    call get_sec
                    add  a,b
                    cp   60
                    jr   nc,sec_too_big
                    ld   b,a
                    ret
.sec_too_big        sub  60
                    ld   b,a
                    ret
.get_sec            in   a,(bl_tim1)
.get_sec_again      ld   c,a
                    in   a,(bl_tim1)
                    cp   c
                    ret  z
                    jr   get_sec_again

; ***********************************************************************
.UseHWSerPort
                    push af
                    push bc
                    ld   a,$ff
                    ld   (HWSER_flag),a

                    ld   bc, [4<<8] | BL_INT
                    ld   a,(bc)
                    res  BB_INTUART,a             ; disable UART interrupts
                    res  BB_INTTIME,a             ; disable RTC interrupts
                    ld   (bc),a
                    out  (c),a
                    pop  bc
                    pop  af
                    ret

; ***********************************************************************
.UseOZSerPort
                    push af
                    push bc
                    xor  a
                    ld   (HWSER_flag),a

                    ld   bc, [4<<8] | BL_INT
                    ld   a,(bc)
                    set  BB_INTUART,a             ; enable UART interrupts
                    set  BB_INTTIME,a             ; enable RTC interrupts
                    ld   (bc),a
                    out  (c),a
                    pop  bc
                    pop  af
                    ret

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

