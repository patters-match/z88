;          ZZZZZZZZZZZZZZZZZZZZ
;        ZZZZZZZZZZZZZZZZZZZZ
;                     ZZZZZ
;                   ZZZZZ
;                 ZZZZZ           PPPPPPPPPPPPPP     RRRRRRRRRRRRRR       OOOOOOOOOOO     MMMM       MMMM
;               ZZZZZ             PPPPPPPPPPPPPPPP   RRRRRRRRRRRRRRRR   OOOOOOOOOOOOOOO   MMMMMM   MMMMMM
;             ZZZZZ               PPPP        PPPP   RRRR        RRRR   OOOO       OOOO   MMMMMMMMMMMMMMM
;           ZZZZZ                 PPPPPPPPPPPPPP     RRRRRRRRRRRRRR     OOOO       OOOO   MMMM MMMMM MMMM
;         ZZZZZZZZZZZZZZZZZZZZZ   PPPP               RRRR      RRRR     OOOOOOOOOOOOOOO   MMMM       MMMM
;       ZZZZZZZZZZZZZZZZZZZZZ     PPPP               RRRR        RRRR     OOOOOOOOOOO     MMMM       MMMM


; **************************************************************************************************
; This file is part of Zprom.
;
; Zprom is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Zprom is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the Zprom;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************


    MODULE ViewEdit_Memory

    LIB ToUpper

    XREF EditMem_banner, ViewMem_banner, ViewEpr_banner
    XREF addr_prompt
    XREF Get_constant, InthexDisp, InthexDisp_H, Display_char, Display_string
    XREF ReadKeyboard, Conv_to_nibble
    XREF InpLine
    XREF Bind_in_bank
    XREF PresetBuffer_hex16
    XREF Out_of_Bufrange
    XREF DumpWindows, DispEditinfo

    XDEF ME_command, MV_command, EV_command
    XDEF ViewEditDump, Memory_View, Memory_Edit

    INCLUDE "defs.asm"
    INCLUDE "stdio.def"


; ************************************************************************************************
; CC_me     -   Memory Edit
;
.ME_command         LD   A,$20
                    LD   (BaseAddr),A                   ; High byte of Memory buffer Base address
                    LD   HL, EditMem_banner
                    LD   IX, Memory_Edit
                    CALL ViewEditDump
                    RET



; ************************************************************************************************
; CC_mv     -   Memory View
;
.MV_command         LD   A,$20
                    LD   (BaseAddr),A                   ; High byte of Memory buffer Base address
                    LD   HL, ViewMem_banner
                    LD   IX, Memory_View
                    CALL ViewEditDump
                    RET



; ************************************************************************************************
; CC_ev     -   Eprom View Bank
;
.EV_command         LD   A,$80
                    LD   (BaseAddr),A                   ; Base dump address at segm. 2
                    LD   HL, ViewEpr_banner
                    LD   IX, Memory_View
                    LD   A,(EprBank)                    ; get current EPROM bank
                    LD   B,A
                    CALL Bind_in_bank
                    CALL ViewEditDump                   ; dump bank to screen...
                    RET



; ************************************************************************************************
;
; Standard setup for all three dump variations: View/Edit Buffer, View Eprom
;
;   IN: HL pointer to banner for menu window
;       IX pointer to View/Edit subroutine
;
.ViewEditDump       LD   (Banner),HL                    ; save menu banner
                    PUSH HL
                    LD   HL,(RangeStart)                ; get Start Prog. Range
                    CALL PresetBuffer_Hex16             ; preset buffer with ...
                    LD   A,4                            ; cursor at end of hex address
                    LD   BC,$0310                       ; display menu at (16,3)
                    POP  HL
                    LD   DE,addr_prompt                 ; prompt 'Enter address:'
                    CALL InpLine                        ; enter a filename
                    CP   IN_ESC                         ; <ESC> pressed during input?
                    RET  Z                              ; Yes, abort command.
                    EX   DE,HL                          ; HL points at start of buffer
                    LD   C,16
                    CALL Get_constant                   ; convert ASCII to 16 bit integer
                    RET  C                              ; return if an error occurred
                    LD   A,D                            ; get high byte of start address
                    AND  @11000000                      ; bank range 0000h - 3FFFh
                    JP   NZ, Out_of_Bufrange            ; 'out of buffer/bank range'
                    LD   (TopAddr),DE                   ; begin editing at specified address
                    JP   (IX)


; *********************************************************************************
;
; Memory Dump
;
.Memory_View        RES  ViewEdit,(IY+0)                ; indicate memory view only
                    JR   mem_dump
.Memory_Edit        SET  ViewEdit,(IY+0)

.Mem_dump           CALL ResetCurPos                    ; intialise cursor pos. in window
                    CALL EditWindows                    ; Setup Dump windows and display initial dump
.mem_view_loop      CALL DisplayCurPos                  ; then display the cursor (reset to 0,0)
                    CALL ReadKeyboard                   ; and wait for a key to be pressed
                    CP   IN_ESC
                    RET  Z                              ; ESC pressed - abort...
                    CP   IN_TAB                         ; TAB pressed?
                    JP   Z, HexAscii_Cursor             ; toggle between Hex & ASCII cursor
                    CP   IN_LFT                         ; <Left Cursor>?
                    JP   Z, mv_cursor_left              ;
                    CP   IN_RGT                         ; <Right Cursor>?
                    JP   Z, mv_cursor_right             ;
                    CP   IN_DWN                         ; <Down Cursor> ?
                    JR   Z, next_16_bytes
                    CP   IN_UP                          ; <Up Cursor>   ?
                    JP   Z, prev_16_bytes
                    CP   IN_SDWN                        ; <SHIFT> <Down Cursor> ?
                    JP   Z, next_128_bytes
                    CP   IN_SUP                         ; <SHIFT> <Up Cursor> ?
                    JP   Z, prev_128_bytes
                    CP   IN_DDWN                        ; <DIAMOND> <Down Cursor> ?
                    JP   Z, top_bank_addr
                    CP   IN_DUP                         ; <DIAMOND> <Up Cursor> ?
                    JP   Z, bottom_bank_addr

                    CP   126                            ;
                    JP   P, mem_view_loop               ; char > 126, illegal
                    CP   32                             ;
                    JP   M, mem_view_loop               ; char < 32, illegal...

                    BIT  ViewEdit,(IY+0)
                    JR   Z, mem_view_loop               ; view mode - no memory editing...

                    BIT  HexAscii,(IY+0)                ; allowed input decided by current cursor
                    JR   Z, put_ascii_byte              ; - put ASCII byte into memory
                    CALL ToUpper                        ; get HEX byte...
                    CALL Display_Char
                    CALL Conv_to_nibble                 ; ASCII to value 0 - 15.
                    CP   16                             ; legal range 0 - 15
                    JR   NC, illegal_byte               ;
                    RLCA
                    RLCA
                    RLCA
                    RLCA                                ; into bit 7 - 4.
                    LD   B,A
                    CALL ReadKeyboard
                    CP   126                            ;
                    JP   P, illegal_byte                ; char > 126, illegal
                    CP   32                             ;
                    JP   M, illegal_byte                ; char < 32, illegal...
                    CALL ToUpper
                    CALL Display_Char
                    CALL Conv_to_nibble                 ; ASCII to value 0 - 15.
                    CP   16                             ; legal range 0 - 15
                    JR   NC, illegal_byte
                    OR   B                              ; merge the two nibbles
                    CALL Alter_Memory                   ; HEX byte into memory...
                    JP   mv_cursor_right                ; auto move to next memory cell...

.put_ascii_byte     CALL Alter_Memory                   ; put into memory and display i window
                    JP   mv_cursor_right                ; auto move to next memory cell...

.illegal_byte       CALL DisplayCurLine                 ; reset cursor at current position
                    JP   mem_view_loop                  ; and re-display memory dump at cur. line

.next_16_bytes      LD   A,(CY)                         ; get CY
                    CP   7                              ; cursor at bottom line?
                    JR   Z, scroll_16_up                ; Yes - display a new line of bytes
                    LD   HL, CY
                    INC  (HL)                           ; move cursor one line down
                    JP   mem_view_loop                  ;
.scroll_16_up       LD   HL, scroll_up
                    CALL Display_String
                    LD   BC,$0700
                    CALL Set_CurPos                     ; set print position at (0,7)
                    LD   DE,(BotAddr)                   ; get Bottom Pointer in DE
                    CALL Dump_16_bytes
                    EX   DE,HL
                    LD   (BotAddr),HL                   ; HL = new Bottom pointer
                    CP   A
                    LD   BC,128
                    SBC  HL,BC
                    EX   DE,HL
                    CALL AdjustAddress                  ; new TOP pointer
                    LD   (TopAddr),DE
                    JP   mem_view_loop

.next_128_bytes     LD   BC,$0700
                    CALL Set_CurPos                     ; set print position at (0,7)
                    LD   DE,(BotAddr)                   ; get Bottom Pointer in DE
                    CALL Dump_128_bytes
                    EX   DE,HL                          ; HL = new Bottom pointer
                    LD   (BotAddr),HL
                    CP   A
                    LD   BC,128
                    SBC  HL,BC
                    EX   DE,HL
                    CALL AdjustAddress                  ; new TOP pointer
                    LD   (TopAddr),DE
                    JP   mem_view_loop

.prev_16_bytes      LD   A,(CY)                         ; get CY
                    CP   0                              ; cursor at top line?
                    JR   Z, scroll_16_down              ; Yes - display a new line of bytes
                    LD   HL, CY
                    DEC  (HL)                           ; move cursor one line down
                    JP   mem_view_loop                  ;
.scroll_16_down     LD   HL,(TopAddr)
                    CP   A                              ; Fc = 0
                    LD   BC,16
                    SBC  HL,BC                          ; move 16 bytes back
                    EX   DE,HL
                    CALL AdjustAddress                  ; execute addr. wrap if necessary...
                    EX   DE,HL
                    LD   (TopAddr),HL
                    LD   BC,128
                    ADD  HL,BC                          ; calculate new BOTTOM addr.
                    EX   DE,HL
                    CALL AdjustAddress                  ;
                    LD   (BotAddr),DE                   ; new BOTTOM dump address
                    LD   HL, scroll_down
                    CALL Display_String
                    LD   BC,0
                    CALL Set_CurPos                     ; set print position at (0,0)
                    LD   DE,(TopAddr)
                    CALL Dump_16_bytes
                    JP   mem_view_loop

.prev_128_bytes     LD   HL,(TopAddr)                   ; TOP pointer in HL
                    CP   A                              ; Fc = 0
                    LD   BC,128
                    SBC  HL,BC                          ; move 128 bytes back
                    EX   DE,HL
                    CALL AdjustAddress                  ; execute addr. wrap if necessary...
                    LD   (TopAddr),DE                   ; new TOP pointer
                    CALL Dump_128_bytes
                    LD   (BotAddr),DE                   ; new BOTTOM pointer
                    JP   mem_view_loop

.bottom_bank_addr   LD   DE,0
                    LD   (TopAddr),DE
                    CALL Dump_128_bytes
                    LD   (BotAddr),DE
                    JP   mem_view_loop

.top_bank_addr      LD   DE,$3F80                       ; 128 bytes before top of bank...
                    LD   (TopAddr),DE
                    CALL Dump_128_bytes
                    LD   (BotAddr),DE
                    JP   mem_view_loop

.HexAscii_Cursor    BIT  HexAscii,(IY+0)
                    JR   Z, set_HexCursor               ; ASCII cursor active, set HEX cursor
                    RES  HexAscii,(IY+0)                ; HEX cursor active, set ASCII cursor
                    LD   A,56
                    LD   (SC),A                         ; SC = 56
                    LD   A,1
                    LD   (CI),A                         ; CI = 1
                    JP   mem_view_loop                  ;
.set_HexCursor      SET  HexAscii,(IY+0)
                    LD   A,7
                    LD   (SC),A                         ; SC = 7
                    LD   A,3
                    LD   (CI),A                         ; CI = 3
                    JP   mem_view_loop                  ;

.mv_cursor_left     LD   A,(CX)                         ; get CX
                    CP   0                              ; cursor reached left boundary?
                    JR   Z, wrap_curs_right             ; Yes - wrap to right boundary
                    LD   HL, CX
                    DEC  (HL)                           ; move cursor 1 byte left
                    JP   mem_view_loop                  ;
.wrap_curs_right    LD   A,15
                    LD   (CX),A
                    JP   prev_16_bytes                  ;

.mv_cursor_right    LD   A,(CX)                         ; get CX
                    CP   15                             ; cursor reached right boundary?
                    JR   Z, wrap_curs_left              ; Yes - wrap to left boundary
                    LD   HL, CX
                    INC  (HL)                           ; move cursor 1 byte right
                    JP   mem_view_loop                  ;
.wrap_curs_left     LD   A,0
                    LD   (CX),A
                    JP   next_16_bytes                  ;

.scroll_down        DEFM 1, $FE, 0
.scroll_up          DEFM 1, $FF, 0


;
; A = byte to be put into the memory location the cursor is currently pointing at
;
.Alter_Memory       PUSH AF
                    CALL Get_CurOffset                  ; cursor offset in A
                    CALL Get_OffsetPtr                  ; added with TOP pointer
                    LD   A,(BaseAddr)                   ; get high byte of base addr. of memory
                    LD   H,A
                    LD   L,0
                    ADD  HL,DE                          ; add (bank) offset
                    POP  AF                             ; returns cursor pointer to memory...
                    LD   (HL),A                         ; put byte into memory
                    CALL DisplayCurLine
                    RET

;
; display memory dump at current cursor line
;
.DisplayCurLine     CALL Get_CurOffset                  ; get cursor offset
                    LD   HL,CX
                    SUB  (HL)                           ; to start of line, (CY*16-CX)
                    CALL Get_OffsetPtr                  ; pointer in DE
                    LD   A,(CY)                         ; get CY (current cursor line)
                    LD   B,A
                    LD   C,0                            ; start of line
                    CALL Set_CurPos                     ; set cursor position
                    CALL Dump_16_bytes                  ; dump memory from DE (start of line)=
                    RET

;
; calculate cursor offset from top corner of screen in A
; (also referenced as offset from TOP pointer)
;
.Get_CurOffset      LD   A,(CY)                         ; get CY
                    SLA  A
                    SLA  A
                    SLA  A
                    SLA  A                              ; CY * 16
                    LD   HL,CX
                    ADD  A,(HL)                         ; CY*16+CX = cursor offset from TOP
                    RET

;
; Calculate absolute pointer from TOP pointer with cursor offset returned into DE
;
.Get_OffsetPtr      LD   C,A
                    LD   B,0
                    LD   DE,(TopAddr)                   ; get TOP pointer
                    EX   DE,HL
                    ADD  HL,BC                          ; add offset to base...
                    EX   DE,HL
                    CALL AdjustAddress                  ; adjust for address wrap...
                    RET


; *********************************************************************************
;
; Reset cursor position in window                       V0.24d
;
; - No registers affected
;
.ResetCurPos        LD   A,7
                    LD   (SC),A                           ; cursor begins at tab 6
                    LD   A,3
                    LD   (CI),A                           ; CI = 3 with Hex cursor
                    LD   A,0
                    LD   (CX),A                           ; CX = 0
                    LD   (CY),A                           ; CY = 0
                    SET  HexAscii,(IY+0)                  ; Indicate Hex cursor
                    RET


; *********************************************************************************
;
; display cursor in window (with VDU 1,"3","@",32+CX,32+CY)
;
; - No registers affected
;
.DisplayCurPos      PUSH AF
                    PUSH BC
                    PUSH HL
                    LD   A,(CX)
                    LD   HL, CI
                    LD   B,(HL)
                    DEC  B
                    JR   Z, CX_calculated
                    LD   C,A
.tab_loop           ADD  A,C                              ; CX*CI
                    DJNZ,tab_loop
.CX_calculated      LD   HL, SC
                    ADD  A,(HL)                           ; add rel. horisontal start in window
                    LD   C,A                              ; CX position in window ready.
                    LD   HL, CY
                    LD   B,(HL)                           ; get CY
                    CALL Set_CurPos                       ; display cursor at CX,CY
                    POP  HL
                    POP  BC
                    POP  AF
                    RET


; *********************************************************************************
;
; Dump 128 bytes in Hex and ASCII format from current address in DE
; DE will point +128 bytes on return
;
.Dump_128_bytes     LD   A,12
                    CALL Display_Char                    ; CLS
                    LD   B,8                             ; display 8 lines
.dump_loop          PUSH BC
                    CALL Dump_16_bytes                   ; dump 1 line (16 bytes)
                    POP  BC
                    DJNZ,dump_loop
                    RET


; *********************************************************************************
;
; Dump 16 bytes in Hex and ASCII format from current address in DE
; DE will point +16 bytes on return
;
; AF, B, DE, L  different on return
;
.Dump_16_bytes      EX   DE,HL                          ; Dump address in HL
                    SCF                                 ; display 16bit hex
                    CALL IntHexDisp_H                   ; - the current dump address
                    EX   DE,HL                          ; back in DE
                    LD   A,32
                    CALL Display_Char
                    CALL Display_Char
                    LD   B,16
                    PUSH DE                             ; save a copy for ASCII dump
.dump_hex_loop      PUSH BC
                    CALL Get_dump_byte                  ; fetch byte at dump address
                    CP   A                              ; display in 8bit HEX
                    LD   L,A
                    CALL IntHexDisp
                    LD   A,32
                    CALL Display_Char
                    POP  BC
                    DJNZ,dump_hex_loop
                    POP  DE
                    LD   B,16                            ; now dump same bytes in ASCII format
                    LD   A,32
                    CALL Display_char                    ; make an extra space
.dump_ascii_loop    PUSH BC
                    CALL Get_dump_byte                   ; fetch byte at dump address
                    CP   32
                    JP   M, disp_dot
                    CP   127
                    JP   M, disp_ascii_byte
.disp_dot           LD   A, '.'                          ; display '.' if A = [0;31] [128;255]
.disp_ascii_byte    CALL Display_Char
                    POP  BC
                    DJNZ,dump_ascii_loop
                    CALL_OZ (Gn_Nln)
                    RET



; *********************************************************************************
;
; Return in A the byte from current Dump address and increase dump address for next fetch.
;
; DE, AF  different on return
;
.Get_dump_byte      PUSH HL
                    LD   A,(BaseAddr)
                    LD   H,A                            ; get high byte of base addr. of memory
                    LD   L,0
                    ADD  HL,DE                          ; add (bank) offset
                    LD   A,(HL)                         ; get byte at true dump address
                    INC  DE                             ; dump address ready for next fetch
                    CALL AdjustAddress                  ; DE only in 16K range...
                    POP  HL
                    RET


; *********************************************************************************
; - This routine will automatically executed wrap around if dump is executed in
; a bank and the dump address is about to go beyond the bank.
;
.AdjustAddress      EX   AF,AF'
                    LD   A,D
                    AND  @00111111                      ; DE only in range 0000h - 3FFFh
                    LD   D,A
                    EX   AF,AF'
                    RET


; *********************************************************************************
;
;
.EditWindows        PUSH DE
                    PUSH HL
                    LD   HL,EditWindows                 ; pointer to subroutine...
                    LD   (MainWindow),HL                ; rel. pointer to variable
                    LD   HL,0
                    LD   (MenuWindow),HL
                    LD   HL, DumpWindows
                    CALL Display_string                 ; display dump windows
                    LD   HL,(Banner)                    ; rel. pointer to variable
                    CALL Display_string                 ; display banner in info window
                    LD   HL, DispEditInfo
                    CALL Display_string                 ; display help information
                    LD   DE,(TopAddr)                    ; rel. pointer to variable
                    CALL Dump_128_bytes                 ; begin dump from nn
                    LD   (BotAddr),DE
                    CALL DisplayCurPos                  ; then display the cursor
                    POP  HL
                    POP  DE
                    RET


; *************************************************************************************
;
; Set cursor at X,Y position in current window          V0.18
;
; IN:
;         C,B  =  (X,Y)
;
; Register status after return:
;
;       ..BCDEHL/IXIY  same
;       AF....../....  different
;
.Set_CurPos       PUSH BC
                  PUSH HL
                  LD   HL, xypos                        ; VDU 1,'3','@',32+C,32+B
                  CALL Display_string                   ; send VDU to screen driver
                  POP  HL
                  POP  BC
                  LD   A,C
                  ADD  A,32
                  CALL Display_char
                  LD   A,B
                  ADD  A,32
                  CALL Display_char
                  RET
.xypos            DEFM 1, "3@", 0
