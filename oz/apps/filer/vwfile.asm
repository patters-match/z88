; **************************************************************************************************
; Filer Popdown, View File functionality (Binary file Viewer Ported from Zprom & edited for Filer).
; Implemented by Gunther Strube, Copyright 1993-2008
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

        module  ViewFile

        xref    GetKey
        xdef    ViewFile

        include "error.def"
        include "stdio.def"
        include "fileio.def"
        include "sysapps.def"
        include "rtmvars.def"


; *********************************************************************************
; View File as binary dump. Main keyboard input & cursor movement logic loop
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

        call    MemDump
        pop     iy
        ld      a,SC_Ack
        oz      OS_Esc                          ; Acknowledge ESC key, so that Filer is not exited
        ret                                     ; in main input loop.

.MemDump
        call    ResetCurPos                     ; intialise cursor pos. in window
        call    InitView                        ; Setup Dump windows and display initial dump
.mem_view_loop
        call    DisplayCurPos                   ; then display the cursor
        call    GetKey
        ret     c                               ; user aborted with ESC key...
        cp      $20                             ; TAB pressed?
        jp      z, HexAscii_Cursor              ; toggle between Hex & ASCII cursor
        cp      IN_LFT                          ; <Left Cursor>?
        jp      z, mv_cursor_left               ;
        cp      IN_RGT                          ; <Right Cursor>?
        jp      z, mv_cursor_right              ;
        cp      IN_DWN                          ; <Down Cursor> ?
        jr      z, next_16_bytes
        cp      IN_UP                           ; <Up Cursor>   ?
        jr      z, prev_16_bytes
        cp      $32                             ; <SHIFT> <Down Cursor> ?
        jr      z, next_128_bytes
        cp      $31                             ; <SHIFT> <Up Cursor> ?
        jp      z, prev_128_bytes
        cp      IN_DDWN                         ; <DIAMOND> <Down Cursor> ?
        jp      z, page_eoffile
        cp      IN_DUP                          ; <DIAMOND> <Up Cursor> ?
        jp      z, page_startfile
        jr      mem_view_loop

.next_16_bytes
        ld      bc,16
        call    ValidateNewCursorOffset         ; cursor in buffer + 16 bytes > EOF?
        jr      c, mem_view_loop
        ld      a,(vf_CY)                       ; get CY
        cp      7                               ; cursor at bottom line?
        jr      z, scroll_16_up                 ; Yes - display a new line of bytes
        ld      hl, vf_CY
        inc     (hl)                            ; move cursor one line down
        jp      mem_view_loop                   ;
.scroll_16_up
        ld      bc,16
        call    ValidateIncreaseFptr            ; [vf_fptr] + 16 ?
        jp      c, mem_view_loop                ; cannot - beyond end of file...

        call    IncreaseFptr                    ; [vf_fptr] += 16
        call    LoadBuffer
        oz      OS_Pout
        defm    1, $FF, 0                       ; scroll up
        ld      bc,$0700
        call    Set_CurPos                      ; set print position at (0,7)
        ld      de,vf_EditBuffer+112            ; offset from file pointer of buffer is 6 lines down...
        call    Dump_16_bytes                   ; display bottom row only
        jp      mem_view_loop

; reload view buffer with new file contents from current file pointer (top of buffer + 128 bytes)
.next_128_bytes
        ld      bc,128
        call    ValidateIncreaseFptr            ; [vf_fptr] + 128 ?
        jp      c, mem_view_loop                ; cannot - beyond end of file...

        call    IncreaseFptr                    ; [vf_fptr] += 128
        ld      bc,$0700
        call    Set_CurPos                      ; set print position at (0,7)
        call    Dump_128_bytes
        jp      mem_view_loop

.prev_16_bytes
        ld      a,(vf_CY)                       ; get CY
        or      a                               ; cursor at top line?
        jr      z, scroll_16_down               ; Yes - display a new line of bytes
        ld      hl, vf_CY
        dec     (hl)                            ; move cursor one line down (-16 bytes)
        jp      mem_view_loop

.scroll_16_down
        ld      bc,16
        call    ValidateDecreaseFptr            ; [vf_fptr] -= 16?
        jp      c, mem_view_loop                ; cannot - beyond start of file...
        oz      OS_Pout
        defm    1, $FE, 0                       ; scroll current dump window contents down
        call    DecreaseFptr                    ; [vf_fptr] -= 16
        call    LoadBuffer
        ld      bc,0
        call    Set_CurPos                      ; set print position at (0,0)
        call    Dump_16_bytes                   ; display top row only
        jp      mem_view_loop

.prev_128_bytes
        ld      bc,128
        call    ValidateDecreaseFptr            ; [vf_fptr] -= 128?
        jp      c, mem_view_loop                ; cannot - beyond start of file...
        call    DecreaseFptr                    ; [vf_fptr] -= 128
        call    Dump_128_bytes
        jp      mem_view_loop

.page_startfile
        xor     a
        ld      h,a
        ld      l,a
        ld      (vf_fptr),hl
        ld      (vf_fptr+2),a
        call    dump_128_bytes
        jp      mem_view_loop

.page_eoffile
        ld      hl,(vf_fsize)
        ld      a,l
        and     $F0                             ; set the file pointer at modulus 16 bytes (for better view)
        ld      l,a
        ld      (vf_fptr),hl                    ; fptr = size of file (modulus 16)
        ld      a,(vf_fsize+2)
        ld      (vf_fptr+2),a

        ld      b,0
        ld      c,128-16                        ; display last buffer of file in a good modulus 16 display...
        call    DecreaseFptr                    ; [vf_fptr] -= 128
.dump_eof
        call    Dump_128_bytes
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
        ld      a,8
        ld      (vf_SC),a                       ; SC = 8
        ld      a,3
        ld      (vf_CI),a                       ; CI = 3
        jp      mem_view_loop                   ;

.mv_cursor_left
        ld      bc,-1
        call    ValidateNewCursorOffset
        jp      c,mem_view_loop
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
        ld      bc,1
        call    ValidateNewCursorOffset
        jp      c,mem_view_loop
        ld      a,(vf_cx)                       ; get CX
        cp      15                              ; cursor reached right boundary?
        jr      z, wrap_curs_left               ; Yes - wrap to left boundary
        ld      hl, vf_CX
        inc     (hl)                            ; move cursor 1 byte right
        jp      mem_view_loop
.wrap_curs_left
        xor     a
        ld      (vf_CX),A                       ; CX=0
        jp      next_16_bytes



; *********************************************************************************
; In:
;       BC = validate move of cursor X bytes in buffer (-/+)
; Returns:
;       Fc = 1, if cursor + BC offset will go out of file boundary.

.ValidateNewCursorOffset
        call    GetCursorOffset
        add     hl,bc
        ld      bc,vf_EditBuffer
        add     hl,bc
        ex      de,hl
        jp      ValidateDumpByte


; *********************************************************************************
; return cursor offset from top corner of screen in HL, calculated by (CX,CY)
;
.GetCursorOffset
        push    af
        ld      a,(vf_CY)                       ; get CY
        sla     a
        sla     a
        sla     a
        sla     a                               ; CY * 16
        ld      hl,vf_CX
        add     a,(hl)                          ; CY*16+CX = cursor offset from TOP
        ld      h,0
        ld      l,a
        pop     af
        ret


; *********************************************************************************
; Reset cursor position in window to top left corner
;
.ResetCurPos
        ld      a,8
        ld      (vf_SC),a                        ; cursor begins at tab 8
        ld      a,3
        ld      (vf_CI),a                        ; CI = 3 with Hex cursor
        ld      a,0
        ld      (vf_CX),a                        ; CX = 0
        ld      (vf_CY),a                        ; CY = 0
        set     hexAscii,(iy+0)                  ; Indicate Hex cursor
        ret


; *********************************************************************************
; Display cursor in window (with VDU 1,"3","@",32+CX,32+CY)
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
; Load 128 bytes (or less) from file, using current file pointer (vf_fptr),
; into view buffer and reset DE to point at start of buffer.
;
.LoadBuffer
        ld      a,FA_PTR
        ld      hl,vf_fptr
        oz      OS_Fwm                          ; set file pointer to base of view buffer, defined by (vf_fptr)

        ld      bc,128
        ld      h,b
        ld      l,b                             ; HL = 0
        ld      de,vf_EditBuffer
        push    de
        oz      OS_Mv                           ; fetch 128 bytes (or less!) from file and dump into view buffer
        pop     de                              ; EOF is handled automatically via cursor movement...
        ret


; *********************************************************************************
; Dump 128 bytes in Hex and ASCII format from current buffer address in DE
; DE will point +128 bytes on return
;
.Dump_128_bytes
        call    LoadBuffer                      ; after return, DE points at start of buffer
        oz      OS_Pout
        defb    12,0                            ; clear view buffer window
        ld      b,8                             ; display 8 x 16 byte lines of hex dump
.dump_loop
        push    bc
        call    dump_16_bytes                   ; dump 1 line (16 bytes)
        pop     bc
        djnz    dump_loop
        ret


; *********************************************************************************
; Dump 16 bytes in Hex and ASCII format from current address in DE
; DE will point +16 (or less if EOF) of view buffer bytes on return.
;
; AF, B, DE, L  different on return
;
.Dump_16_bytes
        call    ValidateDumpByte
        ret     c                               ; the DE dump offset is already beyond EOF..
        push    de
        ld      hl,(vf_fptr)                    ; add base file pointer (BC = converted offset of DE)
        add     hl,bc
        push    hl
        ld      a,(vf_fptr+2)
        jr      nc,disp_highbyte_int
        inc     a                               ; adjust overflow of added DE offset..
.disp_highbyte_int
        ld      l,a
        call    InthexDisp
        pop     hl
        scf                                     ; display 16bit hex
        CALL    IntHexDisp                      ; - the current dump address
        oz      OS_pout
        defm    "h ", 0

        ld      b,16
        pop     de
        push    de                              ; save a copy for ASCII dump
.dump_hex_loop
        push    bc
        call    ValidateDumpByte
        jr      nc, cont_dmph16
        pop     bc
        jr      dump_ascii                      ; also display Ascii section... before EOF is reached..
.cont_dmph16
        ld      a,(de)                          ; get byte at true dump address
        inc     de                              ; dump address ready for next fetch

        cp      a                               ; display in 8bit HEX
        ld      l,a
        call    InthexDisp
        ld      a,32
        oz      Os_Out
        pop     bc
        djnz    dump_hex_loop

.dump_ascii
        pop     de
        ld      b,16                            ; now dump same bytes in ASCII format
        oz      OS_Pout
        defm    1, "2X", 32+(7+16*3+1), 0       ; prepare VDU cursor for Ascii section...
.dump_ascii_loop
        push    bc
        call    ValidateDumpByte
        jr      nc, cont_dmpa16
        pop     bc
        ret
.cont_dmpa16
        ld      a,(de)                          ; get byte at true dump address
        inc     de                              ; dump address ready for next fetch
        cp      32
        jp      m, disp_dot
        cp      127
        jp      m, disp_ascii_byte
.disp_dot
        ld      a, '.'                          ; display '.' if A = [0;31] [128;255]
.disp_ascii_byte
        oz      Os_Out
        pop     bc
        djnz    dump_ascii_loop
        oz      GN_nln
        ret

; *********************************************************************************
; Validate that DE(in) (ptr to current line of buffer to display) is not beyond EOF
; return offset from start of buffer in BC (0 - X).
;
.ValidateDumpByte
        push    de
        push    hl
        ld      hl,vf_EditBuffer                ; before displaying dump, calculate the file
        ex      de,hl                           ; offset to be displayed first in left side
        cp      a
        sbc     hl,de                           ; get display offset from top of buffer

        ld      b,h
        ld      c,l
        inc     bc                              ; BC offset from base of 0 converted to actual bytes
        call    ValidateIncreaseFptr
        dec     bc
        pop     hl
        pop     de                              ; if Fc = 1, then DE offset is beyond EOF!
        ret


; *********************************************************************************
; Setup view file windows and pre-load buffer with start of file.
;
.InitView
        push    de
        push    hl
        call    DumpWindows
        call    dump_128_bytes                  ; begin dump from start of file
        ld      (vf_BotAddr),DE
        call    displayCurPos                   ; then display the cursor
        pop     hl
        pop     de
        ret


; *************************************************************************************
; Set cursor at X,Y position in dump file window
;
; IN:
;         C,B  =  (X,Y)
;
; Register status after return:
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
        oz      Os_Out
        ld      a,b
        add     a,32
        oz      Os_Out
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
; HL(in) = integer to be converted to an ASCII HEX string
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
        oz      OS_Out
        ld      a,e
        oz      OS_Out
.only_byte_int
        ld      a,b
        oz      OS_Out
        ld      a,c
        oz      OS_Out                            ; string sent...
        pop     af
        pop     bc
        pop     de
        ret

.IntHexDisp_H
        call    IntHexDisp
        push    af
        ld      a, 'h'                            ; same as 'IntHexDisp_H', but with a
        oz      OS_Out                            ; trailing 'H' hex identifier...
        pop     af
        ret


; ****************************************************************************
; INTEGER to HEX conversion
; HL(in) = integer to be converted to an ASCII HEX string
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
; Validate that Increase file pointer at (vf_fptr) with BC bytes
; doesn't go beyond end of file. Returns Fc = 1, if "overflow"
;
.ValidateIncreaseFptr
        push    bc
        push    de
        push    hl
        ld      hl,(vf_fptr)                    ; get current file pointer (base of buffer)
        add     hl,bc
        ld      a,(vf_fptr+2)
        ld      c,a
        jr      nc,add16bit_fptr
        inc     c                               ; adjust overflow for 24bit adress
.add16bit_fptr
        ex      de,hl
        ld      c,a                             ; CDE = vf_fptr + BC(in)
        ld      hl,(vf_fsize)
        sbc     hl,de
        ld      a,(vf_fsize+2)                  ; (vf_fptr + BC(in)) > vf_fptr + BC(in)?
        sbc     c                               ; return Fc = 1, if overflow...
.exit_vinfptr
        pop     hl
        pop     de
        pop     bc
        ret


; ******************************************************************
; Increase file pointer at (vf_fptr) with BC bytes
;
.IncreaseFptr
        push    af
        push    hl
        ld      hl,(vf_fptr)                    ; get current file pointer (base of buffer)
        add     hl,bc
        ld      (vf_fptr),hl
        jr      nc,exit_infptr
        ld      hl,vf_fptr+2
        inc     (hl)                            ; adjust overflow for 24bit adress
.exit_infptr
        pop     hl
        pop     af
        ret


; ******************************************************************
; Validate that Decrease file pointer at (vf_fptr) with BC bytes
; doesn't go beyond start of file.
; Returns Fc = 1, BC negative overflow value
;
.ValidateDecreaseFptr
        push    hl
        ld      hl,(vf_fptr)                    ; get current file pointer (base of buffer)
        cp      a
        sbc     hl,bc
        ld      a,(vf_fptr+2)
        sbc     a,b                             ; adjust overflow for 24bit adress (add carry with B always = 0)
        ld      b,h
        ld      c,l                             ; return BC = negative overflow value,
        pop     hl                              ; and Fc = 1, if original BC offset goes beyond Start of file..
        ret


; ******************************************************************
; Decrease file pointer at (vf_fptr) with BC bytes
;
.DecreaseFptr
        call    ValidateDecreaseFptr
        jr      nc,valid_dfptr
        pop     af                              ; remove RET..
        jp      page_startfile                  ; BC decrease goes beyound start of file...
.valid_dfptr
        push    af
        push    hl
        ld      hl,(vf_fptr)                    ; get current file pointer (base of buffer)
        cp      a
        sbc     hl,bc
        ld      (vf_fptr),hl
        jr      nc,exit_dcfptr
        ld      hl,vf_fptr+2
        dec     (hl)                            ; adjust overflow for 24bit adress
.exit_dcfptr
        pop     hl
        pop     af
        ret


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
        defm    "Start File   ", 1, 43, 1, 243
        defm    "End File     ", 1, 43, 1, 242
        defm    "Page Up    ", 1, 45, 1, 243
        defm    "Page Down  ", 1, 45, 1, 242
        defm    "Cursor  ", 1, 240, 1, 241, 1, 242, 1, 243
        defm    "Hex/Ascii    ", 1, 226
        defm    "Quit View    ", 1, $E4
        defm    1, "2C2", 1, "2+C", 0                ; select & clear window '2' for dump output
        ret
