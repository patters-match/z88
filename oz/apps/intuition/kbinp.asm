; **************************************************************************************************
; This file is part of Intuition.
;
; Intuition is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation; either version 2, or
; (at your option) any later version.
; Intuition is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Intuition;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;***************************************************************************************************

        MODULE KeyboardInput

        include "blink.def"
        include "stdio.def"

        XDEF InputLine,WaitKey


; *************************************************************************
; Intuition Input line (API compatible with GN_Sip, except no functionality flags in A).
; Cursor always reside at end of line.
;
; The routine exits when following 'special' keys are pressed:
;       IN_SQU, IN_DIA
;       IN_CAPS, IN_MEN, IN_IDX, IN_HLP
;       IN_ENT, IN_ESC, IN_TAB, IN_STAB
;       IN_LFT, IN_RGT, IN_DWN, IN_UP
;       IN_SDWN, IN_SUP
;
; IN:
;     B = max length of buffer
;     DE = Start of buffer
;     (DE) = buffer contents, null-terminated.
;
; OUT:
;     B = length of line entered, including terminating null
;     C = cursor position on exit (= B)
;     A = character which caused end of input

; Register status after return:
;       ....DEHL/IXIY  same
;       AFBC..../....  different
;
.InputLine
        push    de
        push    hl
        
        ld      l,b                               
        dec     l                                
        push    hl
        
        push    de
        ex      de,hl
        oz      GN_Sop                           ; display contents, cursor at end of line
        pop     de
        push    hl
        sbc     hl,de
        ld      b,l
        ld      c,l                              ; B = C = length of line & cursor position
        pop     de                               ; DE points at null
        pop     hl                               ; L = Max length of buffer - 1 (to store null-terminator)
        
        call    inpline_loop
        
        pop     hl
        pop     de
        ret
.inpline_loop
        call    WaitKey
        cp      IN_STAB                          ; <SHIFT><TAB> ?
        ret     z
        cp      IN_SQU                           ; <SQUARE>?
        ret     z
        cp      IN_DIA                           ; <DIAMOND>?
        ret     z
        cp      IN_CAPS                          ; <CAPS LOCK>?
        ret     z
        cp      IN_MEN                           ; <MENU>?
        ret     z
        cp      IN_IDX                           ; <INDEX>?
        ret     z
        cp      IN_HLP                           ; <HELP>?
        ret     z
        cp      IN_ENT                           ; <ENTER>?
        ret     z
        cp      IN_TAB                           ; <TAB>?
        ret     z
        cp      IN_ESC                           ; <ESC>? 
        ret     z
        cp      IN_LFT                           ; <LEFT>? 
        ret     z
        cp      IN_RGT                           ; <RIGHT>? 
        ret     z
        cp      IN_DWN                           ; <DOWN>? 
        ret     z
        cp      IN_UP                            ; <UP>? 
        ret     z
        cp      IN_SDWN                          ; <DOWN>? 
        ret     z
        cp      IN_SUP                           ; <UP>? 
        ret     z
        cp      BS                               ; DEL?
        jr      z,delchar

        ex      af,af'
        ld      a,l
        cp      b
        jr      z,inpline_loop                   ; buffer full, ignore input
        ex      af,af'
        inc     b 
        inc     c
        ld      (de),a
        oz      OS_Out                           ; display char from keyboard
        inc     de
        xor     a
.savekey        
        ld      (de),a
        jr      inpline_loop
.delchar
        inc     b
        dec     b
        jr      z,inpline_loop                   ; start of line, ignore DEL

        oz      OS_Out
        ld      a,32
        oz      OS_Out
        ld      a,8
        oz      OS_Out                           ; clear char from screen
        dec     b
        dec     c
        xor     a
        dec     de
        jr      savekey

; *************************************************************************
; Wait for a single key-press, and return key-code
;
; Register status after return:
;       ..BCDEHL/IXIY  same
;       AF....../....  different
;
.WaitKey
        di                                      ; no interrupts while doing HW keyboard...        
        push    bc
        
        ld      bc,BLSC_INT                     ; get soft copy address of Blink INT 
        ld      a,(bc)
        ld      b,a
        push    bc                              ; remember INT from OZ
        set     BB_INTKWAIT,a                   ; ensure snooze while reading KB
        res     BB_INTKEY,a                     ; but we don't need keyboard interrupts...
        out     (c),a

.getkey_loop
        call    GetKeyCode
        or      a
        jr      z, getkey_loop                  ; 0 returned - wait for key presses

        ld      b,a
.wait_keyreleased
        call    GetKeyCode
        or      a
        jr      nz, wait_keyreleased
        
        ld      a,b                             ; return key that was just released
        pop     bc                              ; 
        out     (c),b                           ; restore INT from OZ (soft copy is the same)

        pop     bc
        ei
        ret


; *************************************************************************
; Scan Z88 hardware keyboard and return keycode.
;
; Read hardware keyboard and return keycodes for single key or SHIFT + key
; System key codes returned only as single key for simplicity
;
; -------------------------------------------------------------------------
;  B2      | D7     D6      D5      D4      D3      D2      D1      D0
; -------------------------------------------------------------------------
; A15 (#7) | RSH    SQR     ESC     INDEX   CAPS    .       /       £
; A14 (#6) | HELP   LSH     TAB     DIA     MENU    ,       ;       '
; A13 (#5) | [      SPACE   1       Q       A       Z       L       0
; A12 (#4) | ]      LFT     2       W       S       X       M       P
; A11 (#3) | -      RGT     3       E       D       C       K       9
; A10 (#2) | =      DWN     4       R       F       V       J       O
; A9  (#1) | \      UP      5       T       G       B       U       I
; A8  (#0) | DEL    ENTER   6       Y       H       N       7       8
; -------------------------------------------------------------------------
;
; IN:
;       None
; OUT:
;       A = keycode, or 0 for no key press
;
; Register status after return:
;       ..BCDEHL/IXIY  same
;       AF....../....  different
;
.GetKeyCode
        push    bc
        push    de
        push    hl

        ld      hl, keytable
        call    PollShiftKey                    ; shift keys pressed?
        jr      z,init_scan_kb                  ; no, return single key press

        ld      hl, keytable+64                 ; yes, return key codes for SHIFT
.init_scan_kb
        ld      d, @11111110                    ; begin by polling row A8, towards A15
.scan_kb
        call    scanrow                         ; get key data into E from scanrow D

        bit     7,d
        jr      nz,check_2nd_shift_row
        res     7,e                             ; A15: ignore potential SHIFT key press
.check_2nd_shift_row
        bit     6,d
        jr      nz, get_keycode
        res     6,e                             ; A14: ignore potential SHIFT key press

.get_keycode
        xor     a
        cp      e
        jr      z, scan_next_row                ; no key was pressed in current scan row, poll next one..
.keycode_loop
        bit     0,e
        jr      nz, read_keycode
        srl     e
        inc     hl
        jr      keycode_loop
.read_keycode
        ld      a,(hl)
        jr      return_keycode

.scan_next_row
        push    de
        ld      de,8
        add     hl,de
        pop     de
        rlc     d
        jr      c,scan_kb                       ; scan all 8 rows
        xor     a                               ; return 0 (no key pressed)

.return_keycode
        pop     hl
        pop     de
        pop     bc
        ret


; *************************************************************************
; Scan keyboard row D (A15-A8)
; return keyboard row data in E, as active bits, ie 1 = key pressed
;
; Register status after return:
;       AFBCD.HL/IXIY  same
;       .....E../....  different
;
.scanrow
        push    af
        push    bc
        ld      b, d
        ld      c, $b2                          ; Blink keyboard port
        in      a, (c)
        cpl
        ld      e,a
        pop     bc
        pop     af
        ret


; *************************************************************************
; Check if a SHIFT key has been pressed.
; returns Fz = 0, if a SHIFT key is down
;
; Register status after return:
;       A.BCDEHL/IXIY  same
;       .F....../....  different
;
.PollShiftKey
        push    bc
        ld      bc,$3fb2                        ; poll for shift keys
        in      a, (C)                          ; Blink keyboard port
        cpl
        and     @11000000                       ; one of the SHIFT keys pressed?
        cp      0
        ld      a,b
        pop     bc
        ret


.keytable                                       ; UK: Single key presses
        defb    $38,$37,$6E,$68,$79,$36,$0D,$08 ; A8  (#0) | 8  7  n  h  y  6  ^M ^D
        defb    $69,$75,$62,$67,$74,$35,$FF,$5C ; A9  (#1) | i  u  b  g  t  5  *U \
        defb    $6F,$6A,$76,$66,$72,$34,$FE,$3D ; A10 (#2) | o  j  v  f  r  4  *D =
        defb    $39,$6B,$63,$64,$65,$33,$FD,$2D ; A11 (#3) | 9  k  c  d  e  3  *R -
        defb    $70,$6D,$78,$73,$77,$32,$FC,$5D ; A12 (#4) | p  m  x  s  w  2  *L ]
        defb    $30,$6C,$7A,$61,$71,$31,$20,$5B ; A13 (#5) | 0  l  z  a  q  1  *S [
        defb    $27,$3B,$2C,$E5,$C8,$09,$A9,$E7 ; A14 (#6) | '  ;  ,  #M !D ^T !L #H
        defb    $A3,$2F,$2E,$E8,$E6,$1B,$B8,$A9 ; A15 (#7) | £  /  .  !C #I ^E !S !R

                                                ; UK: SHIFT key
        defb    $2A,$26,$4E,$48,$59,$5E,$0D,$08 ; A8  (#0) | *  &  N  H  Y  ^  ^M ^D
        defb    $49,$55,$42,$47,$54,$25,$FB,$7C ; A8  (#1) | I  U  B  G  T  %  *U |
        defb    $4F,$4A,$56,$46,$52,$24,$FA,$2B ; A10 (#2) | O  J  V  F  R  $  *D +
        defb    $28,$4B,$43,$44,$45,$23,$F9,$5F ; A11 (#3) | (  K  C  D  E  #  *R _
        defb    $50,$4D,$58,$53,$57,$40,$F8,$7D ; A12 (#4) | P  M  X  S  W  2  *L }
        defb    $29,$4C,$5A,$41,$51,$21,$20,$7B ; A13 (#5) | )  L  Z  A  Q  !  *S {
        defb    $22,$3A,$3C,$E5,$C8,$D2,$A9,$E7 ; A14 (#6) | "  :  <  #M !D ^T !L #H
        defb    $7E,$3F,$3E,$E8,$E6,$1B,$B8,$A9 ; A15 (#7) | ~  ?  >  !C #I ^E !S !R

.end
