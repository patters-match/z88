; -----------------------------------------------------------------------------
; Bank 2 @ S3           ROM offset $A7F0-$A997
;
; $Id$
; -----------------------------------------------------------------------------

        Module Terminal

        include "char.def"
        include "director.def"
        include "error.def"
        include "fileio.def"
        include "stdio.def"
        include "syspar.def"

        org     $e7f0                           ; $e7f0-$e997

.Terminal
        ld      hl, WndwInit_txt
        OZ      GN_Sop                          ; write string to std. output

        ld      hl, aVt52                       ; "VT52"
        OZ      DC_Nam                          ; Name current application

        ld      bc, NQ_Chn                      ; get :COM handle
        OZ      OS_Nq                           ; enquire (fetch) parameter

        ld      iy, $1FF4

; loop to handle keyboard input

.loop
        ld      bc, 0
        OZ      OS_Tin                          ; read a byte from std. input, with timeout
        jr      nc, t_1

.error
        cp      RC_Time                         ; Timeout
        jr      z, serial                       ; go handle serial input
        cp      RC_Susp                         ; Suspicion of pre-emption
        jr      z, loop
        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      nz, exit
        ld      hl, byte_0_E989
        OZ      GN_Sop                          ; write string to std. output
        jr      loop

.exit
        xor     a
        OZ      OS_Bye                          ; Application exit

.t_1
        or      a
        jr      nz, t_4

; it was special char, get second byte

        OZ      OS_In
        jr      c, error

        dec     a
        jr      z, exit                         ; 01 - exit
        dec     a
        jr      nz, t_2
        ld      a, $7F                          ; 02 -> 7F
        jr      t_4

.t_2
        dec     a
        jr      nz, t_3
        ld      a, 8                            ; 03 -> 08
        jr      t_4

.t_3
        dec     a
        cp      8
        jr      nc, loop
        ld      c, a
        ld      b, 0
        ld      hl, abcdpqrs_txt ; udrl, sh-udrl
        add     hl, bc
        ld      a, ESC
        call    putkey
        jr      c, loop
        ld      a, (hl)
.t_4
        call    putkey
        jr      loop

.putkey
        ld      bc, 0
        OZ      OS_Pbt                          ; write byte A to handle IX, BC=timeout
        ret     nc

        cp      RC_Time                         ; Timeout
        scf
        ret     nz

        ld      a, 7
        OZ      OS_Out                          ; write a byte to std. output
        ret

; serial input

.serial
        ld      a, 4                            ; get buffer status
        OZ      OS_Frm

        ld      a, h
        or      a
        jr      z, ser_2                        ; no  bytes in receive queue

        ld      b, a
        ld      a, 0                            ; test  for ESC
        OZ      OS_Esc                          ; Examine special condition

.ser_1
        push    bc
        call    sub_0_E884
        pop     bc
        jr      c, loop
        djnz    ser_1
        jr      loop

.ser_2
        ld      a, $FF
        ld      bc, 0
        OZ      OS_Wait                         ; Wait for event
        jr      loop

.sub_0_E884
        ld      bc, 0
        OZ      OS_Gbt                          ; get byte with timeout
        ret     c

        call    loc_0_E88F
        xor     a
        ret

.loc_0_E88F
        ld      h, (iy+0)
        cp      $18                             ; CAN
        jr      z, loc_0_E89A
        cp      $1A                             ; ^Z
        jr      nz, loc_0_E8A1
.loc_0_E89A
        ld      a, $C1                          ; clear b54321
        and     h
        ld      (iy+0), a
        ret

.loc_0_E8A1
        bit     0, h                            ; SOH disabled?
        jr      nz, loc_0_E8D3
        bit     2, h                            ; SOH?
        jr      z, loc_0_E8BD
        res     2, (iy+0)
        OZ      GN_Cls                          ; Classify a character
        ret     c
        ret     nz

        sub     '0'                             ; 0-9
        ret     z
        ld      (iy+1), a
        set     3, (iy+0)                       ; got num
        ret

;       skip (iy+1) chars

.loc_0_E8BD
        bit     3, h
        jr      z, loc_0_E8CA
        dec     (iy+1)                          ; if so, ignore so many bytes
        ret     nz
        res     3, (iy+0)
        ret

.loc_0_E8CA
        cp      1                               ; SOH
        jr      nz, loc_0_E8D3
        set     2, (iy+0)
        ret

.loc_0_E8D3
        bit     1, h                            ; got ESC?
        jr      z, loc_0_E8FF
        bit     4, h                            ; got identifier?
        jr      z, loc_0_E90B
        bit     5, h                            ; got row?
        jr      nz, loc_0_E8E7
        ld      (iy+2), a
        set     5, (iy+0)
        ret

; ESC Y row+32 col+32

.loc_0_E8E7
        push    af
        ld      hl, MoveTo_txt
        OZ      GN_Sop                          ; write string to std. output
        pop     af                              ; row+32
        OZ      OS_Out
        ld      a, (iy+2)                       ; col+32
        OZ      OS_Out
        ld      a, $CD                          ; clear b541
        and     (iy+0)
        ld      (iy+0), a
        ret

.loc_0_E8FF
        cp      ESC
        jr      nz, loc_0_E908
        set     1, (iy+0)                       ; esc
        ret

.loc_0_E908
        OZ      OS_Out                          ; write a byte to std. output
        ret

.loc_0_E90B
        cp      'Y'
        jr      nz, loc_0_E918
        set     4, (iy+0)                       ; ESC Y row+32 col+32
        res     5, (iy+0)
        ret

.loc_0_E918
        cp      'F'
        jr      nz, loc_0_E922
        set     0, (iy+0)                       ; disable SOH
        jr      loc_0_E942

.loc_0_E922
        cp      'G'
        jr      nz, loc_0_E92C
        res     0, (iy+0)                       ; enable SOH
        jr      loc_0_E942

.loc_0_E92C
        ld      hl, CtrlTable
        ld      c, a
.loc_0_E930
        ld      a, (hl)
        inc     hl
        cp      c
        jr      z, loc_0_E93F
        or      a
        jr      z, loc_0_E942
.loc_0_E938
        ld      a, (hl)
        inc     hl
        or      a
        jr      nz, loc_0_E938
        jr      loc_0_E930

.loc_0_E93F
        OZ      GN_Sop                          ; write string to std. output
.loc_0_E942
        res     1, (iy+0)                       ; no ESC
        ret

.CtrlTable
        defm    "A"                             ; ESC A - up
        defb    11,0
        defm    "B"                             ; ESC B - down
        defb    10,0
        defm    "C"                             ; ESC C - right
        defb    9,0
        defm    "D"                             ; ESC D - left
        defb    8,0
        defm    "H"                             ; ESC H - cursor home
        defm    1,"3@  ",0
        defm    "I"                             ; ESC I - reverse lf
        defb    11,0
        defm    "J"                             ; ESC J - erase EOS
        defb    1,$32,$43,$FE,0
        defm    "K"                             ; ESC K - erase EOL
        defb    1,$32,$43,$FD,0
        defb    0

.abcdpqrs_txt
        defm    "ABCDPQRS"

.WndwInit_txt
        defb    1,$37,$23,$31,$21,$20,$70,$28,$81
        defb    1,$32,$43,$31
        defb    1,$33,$2B,$53,$43
        defb    0

.MoveTo_txt
        defm    1,"3@",0

.byte_0_E989
        defb    1,$33,$40,$20,$20
        defb    1,$32,$43,$FE
        defb    0

.aVt52
        defm    "VT52",0
