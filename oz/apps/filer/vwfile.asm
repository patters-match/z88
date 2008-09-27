; **************************************************************************************************
; Filer Popdown, View File functionality (Binary file Viewer Ported from Zprom & edited for Filer).
; Original implementation by Gunther Strube, Copyright 1993-2008
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; $Id$
; ***************************************************************************************************


        module  ViewEditFile

        xref    GetKey
        xdef    ViewFile

        include "error.def"
        include "stdio.def"
        include "fileio.def"
        include "sysapps.def"
        include "rtmvars.def"



; *********************************************************************************
; View File as binary dump
;
.ViewFile
        push    iy
        ld      iy, vf_Statusbyte

        ld      a,FA_PTR
        ld      de,0
        oz      OS_Frm
        ld      (vf_fptr),bc
        ld      (vf_fptr+2),de                  ; get initial file pointer (and top of view buffer)
        ld      a,FA_EXT
        ld      de,0
        oz      OS_Frm
        ld      (vf_fsize),bc
        ld      a,e
        ld      (vf_fsize+2),a                  ; get file size (only 24bit size needed...)

        res     ViewEdit,(iy+0)                 ; indicate memory view only
        jr      mem_dump
.exit_ViewFile
        pop     iy
        ld      a,SC_Ack
        oz      OS_Esc
        ret

.EditFile
        set     ViewEdit,(iy+0)
.Mem_dump
        call    ResetCurPos                     ; intialise cursor pos. in window
        call    EditWindows                     ; Setup Dump windows and display initial dump
.mem_view_loop
        call    DisplayCurPos                   ; then display the cursor (reset to 0,0)
        call    GetKey
        jr      c, exit_ViewFile                ; user aborted with ESC key...
        cp      IN_TAB                          ; TAB pressed?
        jp      z, HexAscii_Cursor              ; toggle between Hex & ASCII cursor
        cp      IN_LFT                          ; <Left Cursor>?
        jp      z, mv_cursor_left               ;
        cp      IN_RGT                          ; <Right Cursor>?
        jp      z, mv_cursor_right              ;
        cp      IN_DWN                          ; <Down Cursor> ?
        jr      z, next_16_bytes
        cp      IN_UP                           ; <Up Cursor>   ?
        jp      z, prev_16_bytes
        cp      IN_SDWN                         ; <SHIFT> <Down Cursor> ?
        jp      z, next_128_bytes
        cp      IN_SUP                          ; <SHIFT> <Up Cursor> ?
        jp      z, prev_128_bytes
        cp      IN_DDWN                         ; <DIAMOND> <Down Cursor> ?
        jp      z, top_bank_addr
        cp      IN_DUP                          ; <DIAMOND> <Up Cursor> ?
        jp      z, bottom_bank_addr

        cp      126                             ;
        jp      p, mem_view_loop                ; char > 126, illegal
        cp      32                              ;
        jp      m, mem_view_loop                ; char < 32, illegal...

        bit     ViewEdit,(iy+0)
        jr      z, mem_view_loop                ; view mode - no memory editing...

        bit     HexAscii,(iy+0)                 ; allowed input decided by current cursor
        jr      z, put_ascii_byte               ; - put ASCII byte into memory
        or      $DF                             ; get HEX byte...
        call    Display_Char
        call    Conv_to_nibble                  ; ASCII to value 0 - 15.
        cp      16                              ; legal range 0 - 15
        jr      nc, illegal_byte                ;
        rlca
        rlca
        rlca
        rlca                                    ; into bit 7 - 4.
        ld      b,a
        call    GetKey
        ret     c
        cp      126                             ;
        jp      p, illegal_byte                 ; char > 126, illegal
        cp      32                              ;
        jp      m, illegal_byte                 ; char < 32, illegal...
        or      $df
        call    Display_Char
        call    Conv_to_nibble                  ; ASCII to value 0 - 15.
        cp      16                              ; legal range 0 - 15
        jr      nc, illegal_byte
        or      b                               ; merge the two nibbles
        call    Alter_Memory                    ; HEX byte into memory...
        jp      mv_cursor_right                 ; auto move to next memory cell...
.put_ascii_byte
        call    Alter_Memory                    ; put into memory and display i window
        jp      mv_cursor_right                 ; auto move to next memory cell...
.illegal_byte
        call    DisplayCurLine                  ; reset cursor at current position
        jp      mem_view_loop                   ; and re-display memory dump at cur. line
.next_16_bytes
        ld      a,(vf_CY)                       ; get CY
        cp      7                               ; cursor at bottom line?
        jr      z, scroll_16_up                 ; Yes - display a new line of bytes
        ld      hl, vf_CY
        inc     (hl)                            ; move cursor one line down
        jp      mem_view_loop                   ;
.scroll_16_up
        oz      OS_Pout
        defm    1, $FF, 0                       ; scroll up
        ld      bc,$0700
        call    Set_CurPos                      ; set print position at (0,7)
        ld      de,(vf_BotAddr)                 ; get Bottom Pointer in DE
        call    Dump_16_bytes
        ex      de,hl
        ld      (vf_botaddr),hl                 ; HL = new Bottom pointer
        cp      a
        ld      bc,128
        sbc     hl,bc
        ex      de,hl
        call    AdjustAddress                   ; new TOP pointer
        ld      (vf_topaddr),de
        jp      mem_view_loop

.next_128_bytes
        ld      bc,$0700
        call    Set_CurPos                      ; set print position at (0,7)
        ld      de,(vf_BotAddr)                 ; get Bottom Pointer in DE
        call    Dump_128_bytes
        ex      de,hl                           ; HL = new Bottom pointer
        ld      (vf_botaddr),hl
        cp      a
        ld      bc,128
        sbc     hl,bc
        ex      de,hl
        call    AdjustAddress                   ; new TOP pointer
        ld      (vf_TopAddr),de
        jp      mem_view_loop

.prev_16_bytes
        ld      a,(vf_CY)                       ; get CY
        or      a                               ; cursor at top line?
        jr      z, scroll_16_down               ; Yes - display a new line of bytes
        ld      hl, vf_CY
        dec     (hl)                            ; move cursor one line down
        jp      mem_view_loop                   ;

.scroll_16_down
        ld      hl,(vf_TopAddr)
        cp      a                               ; Fc = 0
        ld      bc,16
        sbc     hl,bc                           ; move 16 bytes back
        ex      de,hl
        call    AdjustAddress                   ; execute addr. wrap if necessary...
        ex      de,hl
        ld      (vf_topAddr),HL
        ld      bc,128
        add     hl,bc                           ; calculate new BOTTOM addr.
        ex      de,hl
        call    AdjustAddress
        ld      (vf_BotAddr),de                 ; new BOTTOM dump address
        oz      OS_Pout
        defm    1, $FE, 0                       ; scroll down
        ld      bc,0
        call    Set_CurPos                      ; set print position at (0,0)
        ld      de,(vf_TopAddr)
        call    Dump_16_bytes
        jp      mem_view_loop

.prev_128_bytes
        ld      hl,(vf_TopAddr)                 ; TOP pointer in HL
        cp      a                               ; Fc = 0
        ld      bc,128
        sbc     hl,bc                           ; move 128 bytes back
        ex      de,hl
        call    AdjustAddress                   ; execute addr. wrap if necessary...
        ld      (vf_TopAddr),de                 ; new TOP pointer
        call    Dump_128_bytes
        ld      (vf_BotAddr),de                 ; new BOTTOM pointer
        jp      mem_view_loop

.bottom_bank_addr
        ld      de,0
        ld      (vf_TopAddr),DE
        call    dump_128_bytes
        ld      (vf_BotAddr),de
        jp      mem_view_loop

.top_bank_addr
        ld      de,$3f80                        ; 128 bytes before top of bank...
        ld      (vf_topaddr),de
        call    Dump_128_bytes
        ld      (vf_BotAddr),de
        jp      mem_view_loop

.HexAscii_Cursor
        bit     HexAscii,(iy+0)
        jr      z, set_HexCursor                ; ASCII cursor active, set HEX cursor
        res     HexAscii,(iy+0)                 ; HEX cursor active, set ASCII cursor
        ld      a,56
        ld      (vf_SC),A                       ; SC = 56
        ld      a,1
        ld      (vf_CI),A                       ; CI = 1
        jp      mem_view_loop
.set_HexCursor
        set     HexAscii,(iy+0)
        ld      a,7
        ld      (vf_SC),a                       ; SC = 7
        ld      a,3
        ld      (vf_CI),a                       ; CI = 3
        jp      mem_view_loop                   ;

.mv_cursor_left
        ld      a,(vf_CX)                       ; get CX
        or      a                               ; cursor reached left boundary?
        jr      z, wrap_curs_right              ; Yes - wrap to right boundary
        ld      hl, vf_CX
        dec     (hl)                            ; move cursor 1 byte left
        jp      mem_view_loop
.wrap_curs_right
        ld      a,15
        ld      (vf_CX),a
        jp      prev_16_bytes

.mv_cursor_right
        ld      a,(vf_cx)                       ; get CX
        cp      15                              ; cursor reached right boundary?
        jr      z, wrap_curs_left               ; Yes - wrap to left boundary
        ld      hl, vf_CX
        inc     (hl)                            ; move cursor 1 byte right
        jp      mem_view_loop
.wrap_curs_left
        xor     a                               ; A=0
        ld      (vf_CX),A
        jp      next_16_bytes


;
; A = byte to be put into the memory location the cursor is currently pointing at
;
.Alter_Memory
        push    af
        call    Get_curOffset                   ; cursor offset in A
        call    Get_offsetPtr                   ; added with TOP pointer
        ld      a,(vf_BaseAddr)                 ; get high byte of base addr. of memory
        ld      h,a
        ld      l,0
        add     hl,de                           ; add (bank) offset
        pop     af                              ; returns cursor pointer to memory...
        ld      (hl),a                          ; put byte into memory
        call    DisplayCurLine
        ret

;
; display memory dump at current cursor line
;
.DisplayCurLine
        call    Get_CurOffset                   ; get cursor offset
        ld      hl,vf_CX
        sub     (hl)                            ; to start of line, (CY*16-CX)
        call    Get_OffsetPtr                   ; pointer in DE
        ld      a,(vf_CY)                       ; get CY (current cursor line)
        ld      b,a
        ld      c,0                             ; start of line
        call    Set_CurPos                      ; set cursor position
        call    Dump_16_bytes                   ; dump memory from DE (start of line)=
        ret

;
; calculate cursor offset from top corner of screen in A
; (also referenced as offset from TOP pointer)
;
.Get_CurOffset
        ld      a,(vf_CY)                       ; get CY
        sla     a
        sla     a
        sla     a
        sla     a                               ; CY * 16
        ld      hl,vf_CX
        add     a,(hl)                          ; CY*16+CX = cursor offset from TOP
        ret

;
; Calculate absolute pointer from TOP pointer with cursor offset returned into DE
;
.Get_OffsetPtr
        ld      b,0
        ld      c,a
        ld      de,(vf_TopAddr)                 ; get TOP pointer
        ex      de,hl
        add     hl,bc                           ; add offset to base...
        ex      de,hl
        call    AdjustAddress                   ; adjust for address wrap...
        ret


; *********************************************************************************
;
; Reset cursor position in window                       V0.24d
;
; - No registers affected
;
.ResetCurPos
        ld      a,7
        ld      (vf_SC),a                        ; cursor begins at tab 6
        ld      a,3
        ld      (vf_CI),a                        ; CI = 3 with Hex cursor
        ld      a,0
        ld      (vf_CX),a                        ; CX = 0
        ld      (vf_CY),a                        ; CY = 0
        set     hexAscii,(iy+0)                  ; Indicate Hex cursor
        ret


; *********************************************************************************
;
; display cursor in window (with VDU 1,"3","@",32+CX,32+CY)
;
; - No registers affected
;
.DisplayCurPos
        push    af
        push    bc
        push    hl
        ld      a,(vf_CX)
        ld      hl, vf_CI
        ld      b,(hl)
        dec     b
        jr      z, cx_calculated
        ld      c,a
.tab_loop
        add     a,c                              ; CX*CI
        djnz    tab_loop
.CX_calculated
        ld      hl, vf_SC
        add     a,(hl)                           ; add rel. horisontal start in window
        ld      c,a                              ; CX position in window ready.
        ld      hl, vf_CY
        ld      b,(hl)                           ; get CY
        call    set_curPos                       ; display cursor at CX,CY
        pop     hl
        pop     bc
        pop     af
        ret


; *********************************************************************************
;
; Dump 128 bytes in Hex and ASCII format from current address in DE
; DE will point +128 bytes on return
;
.Dump_128_bytes
        ld      a,FA_PTR
        ld      hl,vf_fptr
        oz      OS_Fwm                          ; set file pointer to base of buffer

        ld      bc,128
        ld      hl,0
        ld      de,vf_EditBuffer
        push    de
        oz      OS_Mv                           ; fetch 128 bytes from file to be viewed.
        pop     de

        oz      OS_Pout
        defb    12,0                            ; CLS
        ld      b,8                             ; display 8 lines
.dump_loop
        push    bc
        call    dump_16_bytes                   ; dump 1 line (16 bytes)
        pop     bc
        djnz    dump_loop
        ret


; *********************************************************************************
;
; Dump 16 bytes in Hex and ASCII format from current address in DE
; DE will point +16 bytes on return
;
; AF, B, DE, L  different on return
;
.Dump_16_bytes
        ex      de,hl                           ; Dump address in HL
        scf                                     ; display 16bit hex
        CALL    IntHexDisp_H                    ; - the current dump address
        ex      de,hl                           ; back in DE
        ld      a,32
        call    display_Char
        call    display_Char
        ld      b,16
        push    de                              ; save a copy for ASCII dump
.dump_hex_loop
        push    bc
        call    get_dump_byte                   ; fetch byte at dump address
        cp      a                               ; display in 8bit HEX
        ld      l,a
        call    InthexDisp
        ld      a,32
        call    display_Char
        pop     bc
        djnz    dump_hex_loop
        pop     de
        ld      b,16                            ; now dump same bytes in ASCII format
        ld      a,32
        call    display_char                    ; make an extra space
.dump_ascii_loop
        push    bc
        call    get_dump_byte                   ; fetch byte at dump address
        cp      32
        jp      m, disp_dot
        cp      127
        jp      m, disp_ascii_byte
.disp_dot
        ld      a, '.'                          ; display '.' if A = [0;31] [128;255]
.disp_ascii_byte
        call    display_Char
        pop     bc
        djnz    dump_ascii_loop
        oz      GN_nln
        ret



; *********************************************************************************
;
; Return in A the byte from current Dump address and increase dump address for next fetch.
;
; DE, AF  different on return
;
.Get_dump_byte
        ld      a,(de)                          ; get byte at true dump address
        inc     de                              ; dump address ready for next fetch
        ret


; *********************************************************************************
; - This routine will automatically executed wrap around if dump is executed in
; a bank and the dump address is about to go beyond the bank.
;
.AdjustAddress
        ex      af,af'
        ld      a,d
        and     @00111111                       ; DE only in range 0000h - 3FFFh
        ld      d,a
        ex      af,af'
        ret


; *********************************************************************************
;
;
.EditWindows
        push    de
        push    hl
        call    dumpWindows
        ld      de,(vf_TopAddr)                 ; rel. pointer to variable
        call    dump_128_bytes                  ; begin dump from nn
        ld      (vf_BotAddr),DE
        call    displayCurPos                   ; then display the cursor
        pop     hl
        pop     de
        ret


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
.Set_CurPos
        push    bc
        push    hl
        oz      OS_Pout
        defm    1, "3@", 0                       ; VDU 1,'3','@',32+C,32+B
        pop     hl
        pop     bc
        ld      a,c
        add     a,32
        call    display_char
        ld      a,b
        add     a,32
        call    display_char
        ret


; ******************************************************************************
.Display_Char
        push    af
        oz      Os_Out
        pop     af
        ret


; ******************************************************************************
;
; Display a string in current window at cursor position
;
; IN: HL points at string.
;
;
.Display_String
        push    hl
        oz      GN_Sop                          ; write string
        pop     hl
        ret


; **********************************************************************************
.Conv_to_nibble
        cp      '@'                             ; digit >= "A"?
        jr      nc,hex_alpha                    ; digit is in interval "A" - "F"
        sub     48                              ; digit is in interval "0" - "9"
        ret
.hex_alpha
        sub     55
        ret


; ****************************************************************************
; INTEGER to HEX conversion
; HL (in) = integer to be converted to an ASCII HEX string
; Fc = 1 convert 16 bit integer, otherwise byte integer
;
; Prints the string to the current window
;
; Register status after return:
;
;       AFBCDEHL/IXIY  same
;       ......../....  different
;
.IntHexDisp
        push    de
        push    bc
        push    af
        call    IntHexConv
        jr      nc, only_byte_int                 ; NC = display only a byte
        ld      a,d
        call    Display_Char
        ld      a,e
        call    Display_Char
.only_byte_int
        ld      a,b
        call    Display_Char
        ld      a,c
        call    Display_Char                      ; string printed...
        pop     af
        pop     bc
        pop     de
        ret

.IntHexDisp_H
        call    IntHexDisp
        push    af
        ld      a, 'h'                            ; same as 'IntHexDisp_H', but with a
        call    display_Char                      ; trailing 'H' hex identifier...
        pop     af
        ret


; ****************************************************************************
; INTEGER to HEX conversion
; HL (in) = integer to be converted to an ASCII HEX string
; Fc = 1 convert 16 bit integer, otherwise byte integer
;
; Returns ASCII representation in DEBC, e.g. '3FFF' -> D='3', E='F', B='F', C='F'
; (8 bit ASCII only in BC)
;
; Register status after return:
;
;       AF....HL/IXIY  same
;       ..BCDE../....  different
;
.IntHexConv
        push    af
        jr      nc, calc_low_byte               ; convert only byte
        ld      a,h
        call    calcHexByte
.calc_low_byte
        push    de
        ld      a,l
        call    calcHexByte                     ; DE = low byte ASCII
        ld      b,d
        ld      c,e
        pop     de
        pop     af
        ret


; ****************************************************************************
; byte in A, will be returned in ASCII form in DE
.CalcHexByte
        push    hl
        ld      h,a                             ; copy of A
        srl     a
        srl     a
        srl     a
        srl     a                               ; high nibble of H
        call    calcHexNibble
        ld      d,a
        ld      a,h
        and     @00001111                       ; low nibble of A
        call    calcHexNibble
        ld      e,a
        pop     hl
        ret


; ******************************************************************
; A(in) = 4 bit integer value, A(out) = ASCII HEX byte
.CalcHexNibble
        push    hl
        ld      hl, hexSymbols
        ld      b,0
        ld      c,a
        add     hl,bc
        ld      a,(hl)
        pop     hl
        ret
.HexSymbols
        defm    "0123456789ABCDEF"


; ******************************************************************
.DumpWindows
        oz      OS_Pout
        defm    1,55,35,'2',32+1,32,32+73,32+8,129   ; Dump window
        defm    1,55,35,'3',108,32,48,40,129         ; Dump Info window
        defm    1, 50, 73, '3'                       ; select info window
        defm    1, "3+TR", 1, "2A", 32+16            ; Tiny & reverse applied at top line
        defm    1, "2JC", 1, "3@", 32, 32            ; Cursor at top left corner - Display banner centre justified
        defm    "View File"

        defm    1, "3-TR", 1, "2JN", 10, 13          ; normal justification
        defm    "Bottom Bank  ", 1, 43, 1, 243
        defm    "Top Bank     ", 1, 43, 1, 242
        defm    "Page Up    ", 1, 45, 1, 243
        defm    "Page Down  ", 1, 45, 1, 242
        defm    "Cursor  ", 1, 240, 1, 241, 1, 242, 1, 243
        defm    "Hex/Ascii    ", 1, 226
        defm    "Quit Dump    ", 1, $E4
        defm    1, "2C2", 1, "2+C", 0                ; select & clear window '2' for dump output
        ret
