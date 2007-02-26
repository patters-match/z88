; **************************************************************************************************
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
; Source code was reverse engineered from OZ 4.0 (UK) ROM and made compilable by Jorma Oksanen.
; Additional development improvements, comments, definitions and new implementations by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
;***************************************************************************************************

        Module Keyboard

include "blink.def"
include "stdio.def"
include "sysvar.def"
include "memory.def"
include "interrpt.def"

xdef    ExtKbMain                               ; was KbMain
xdef    ExtQualifiers                           ; was ApplyQualifiers
xdef    IsForeignKey                            ; is char capsable

xref    BufWrite                                ; bank0/buffer.asm
xref    SwitchOff                               ; bank0/nmi.asm
xref    MaySetEsc                               ; bank0/esc.asm
xref    MS2BankA                                ; bank0/misc5.asm
xref    UpdateRnd                               ; bank0/random.asm
xref    DrawOZWd                                ; bank0/ozwindow.asm

;       Stubs to bind keyboard data in/out S1

.ExtKbMain                                      ; called from Int.asm
        call    ExtCallForKbd
        defw    KbMain

.ExtQualifiers                                  ; called from OsCli.asm and OSIn.asm
        call    ExtCallForKbd
        defw    ApplyQualifiers

.ExtCallForKbd
        ex      (sp), hl                        ; push hl, get PC
        push    bc
        ld      c, a

        ld      a, (BLSC_SR2)                       ; remember S2
        push    af
        ld      a, (ubKmBank)                    ; bind in keymap data
        call    MS2BankA

        ld      a, (hl)                         ; get function in HL
        inc     hl
        ld      h, (hl)
        ld      l, a

        ld      a, c
        call    jpHL                            ; and call it with AB intact

        push    af
        pop     bc

        pop     af                              ; restore S2
        call    MS2BankA

        push    bc                              ; return with AF intact
        pop     af
        pop     bc
        pop     hl
        ret

.jpHL   jp      (HL)


; Main keyboard routine
.KbMain
        exx
        push    bc
        push    de
        push    hl
        push    iy

        push    hl                              ; working space for keyboard matrix
        push    hl                              ; 8 rows + or'ed key mask
        push    hl
        push    hl
        push    hl

        ld      iy, 0                           ; iy points to kbd matrix in stack
        add     iy, sp
        ld      ix, KbdData                     ; ix points to OZ kbd data

        call    RdKeymatrix
        jp      c, loc_0_DBE4                   ; no kbd collisions

        bit     KB_ACTIVE, (ix+kbd_keyflags)
        jp      z, kb_prv

        ld      a, (ix+kbd_rawkey)
        call    KbdTestKey
        jr      z, kb_rls                       ; has been released

        bit     KB_HOLD, (ix+kbd_keyflags)
        res     KB_RELEASE, (ix+kbd_keyflags)
        jr      nz, kb_1

        set     KB_HOLD, (ix+kbd_keyflags)      ; init hold
        call    UpdateRnd
        ld      a, 60                           ; initial repeat delay
        jr      kb_3                            ; init rpt counter
; ---------------------------------------------------------------------------

.kb_1   ld      a, (ix+kbd_rawkey)
        call    FindOtherKey
        jr      c, kb_2
        bit     KB_ACTIVE, (ix+kbd_prevflags)
        jr      nz, kb_2

        ld      b, (ix+kbd_rawkey)
        ld      (ix+kbd_prevkey),b
        ld      (ix+kbd_prevflags),K_ACTIVE

        ld      (ix+kbd_rawkey), a
        ld      (ix+kbd_keyflags), K_ACTIVE
        jp      loc_0_DBE3
; ---------------------------------------------------------------------------

.kb_2   ld      a, (ubRepeat)
        or      a
        jr      z, loc_0_DBB6

        bit     7, (ix+kbd_repeatcnt)           ; repeat disabled?
        jr      nz, loc_0_DBB6
        dec     (ix+kbd_repeatcnt)
        jr      nz, loc_0_DBB6
        ld      a, (ubRepeat)

.kb_3   ld      (ix+kbd_repeatcnt), a           ; restart counter

        ld      a, (cKeyclick)
        cp      'Y'                             ; !! 'N'=4E, 'Y'=59 -> "rrca; jr nc, ..." would work
        jr      nz, kb_4
        set     KBF_B_BEEP, (ix+kbd_flags)      ; click pending

.kb_4   call    GetKey
        jr      loc_0_DBB6
; ---------------------------------------------------------------------------

.kb_rls bit     KB_RELEASE, (ix+kbd_keyflags)
        jr      nz, kb_rl1

        ld      (ix+kbd_rlscnt), 3              ; initialize release
        ld      (ix+kbd_keyflags), K_ACTIVE|K_RELEASE
        jr      kb_prv

;       finish key release

.kb_rl1 dec     (ix+kbd_rlscnt)
        jr      nz, kb_prv
        ld      (ix+kbd_keyflags), 0            ; not active

;       bring back previous key

.kb_prv ld      a, (ix+kbd_prevkey)
        bit     KB_ACTIVE, (ix+kbd_prevflags)
        jr      nz, kb_pr1
        ld      a, -1                           ; no key

.kb_pr1 call    FindOtherKey                    ; see if any other key pressed
        jr      c, loc_0_DBB6
        bit     KB_ACTIVE, (ix+kbd_prevflags)
        jr      nz, loc_0_DBAF

        ld      b, (ix+kbd_rawkey)              ; previous = current
        ld      (ix+kbd_prevkey), b
        ld      b, (ix+kbd_keyflags)
        ld      (ix+kbd_prevflags), b
        ld      b, (ix+kbd_rlscnt)
        ld      (ix+kbd_prevrlscnt), b

.loc_0_DBAF
        ld      (ix+kbd_rawkey), a
        ld      (ix+kbd_keyflags), K_ACTIVE

.loc_0_DBB6
        bit     KB_ACTIVE, (ix+kbd_prevflags)
        jr      z, loc_0_DBE3
        ld      a, (ix+kbd_prevkey)
        call    KbdTestKey                      ; is a key pressed ?
        jr      nz, loc_0_DBDF                  ; released
        bit     KB_RELEASE, (ix+kbd_prevflags)
        jr      nz, PreviousWasReleased         ; previous was released

        ld      (ix+kbd_prevrlscnt), 3          ; initialize release
        ld      (ix+kbd_prevflags), K_ACTIVE|K_RELEASE
        jr      loc_0_DBE3

.PreviousWasReleased
        dec     (ix+kbd_prevrlscnt)
        jr      nz, loc_0_DBE3
        ld      (ix+kbd_prevflags), 0           ; not active
        jr      loc_0_DBE3
; ---------------------------------------------------------------------------

.loc_0_DBDF
        res     KB_RELEASE, (ix+kbd_prevflags)
.loc_0_DBE3
        or      a
.loc_0_DBE4
        ld      a, (iy+8)                       ; key mask
        or      (ix+kbd_keyflags)               ; current active
        or      (ix+kbd_prevflags)              ; prev active
        jr      nz, PurgeStack

        ld      a, (ix+kbd_flags)
        bit     KBF_B_KEY, a                    ; any key (not <> [])
        jr      nz, loc_0_DC1C
        and     KBF_DMND|KBF_SQR                ; <> & []
        jr      z, loc_0_DC1C                   ; neither down
        xor     KBF_DMND|KBF_SQR
        jr      z, loc_0_DC1C                   ; both down

        bit     KBF_B_DMND, a
        jr      nz, loc_0_DC08

        ld      a, IN_DIA
        ld      b, $34                          ; <>
        jr      loc_0_DC10
.loc_0_DC08
        bit     KBF_B_SQR, a
        jr      nz, loc_0_DC10
        ld      a, IN_SQU
        ld      b, $3E                          ; []

.loc_0_DC10
        ld      (ix+kbd_prevkey), b
        ld      (ix+kbd_prevflags), K_ACTIVE
        call    PutKey
        jr      PurgeStack
; ---------------------------------------------------------------------------

.loc_0_DC1C
        ld      a, (ix+kbd_flags)
        and     255-(KBF_DMND|KBF_KEY|KBF_SQR)  ; remove <> []
        ld      (ix+kbd_flags), a

.PurgeStack
        pop     hl                              ; purge stack
        pop     hl
        pop     hl
        pop     hl
        pop     hl

        pop     iy
        pop     hl
        pop     de
        pop     bc
        exx
        ret
; ---------------------------------------------------------------------------
; --------------- S U B R O U T I N E S -------------------------------------
; ---------------------------------------------------------------------------

.GetKey
        call    GetQual
        ld      d, a                            ; qualifiers in d
        ld      a, KMT_MATRIX
        call    GetKbdPtr
        ld      b, 0
        ld      c, (ix+kbd_rawkey)              ; current key
        add     hl, bc
        ld      a, (hl)                         ; internal keycode
        call    ProcessKey
        ret     c                               ; key canceled

.PutKey
        cp      ESC
        call    z, MaySetEsc                    ; set ESC flag if enabled
        call    DeadKeys
        ret     c                               ; exit if key swallowed
        di                                      ; put key into buffer
        set     KBF_B_KEY,(ix+kbd_flags)
        call    BufWrite
        ei
        ret

.ProcessKey                                     ; a=key, d=qualifiers

        cp      IN_CAPS                         ; process caps lock
        jr      nz, spec3

;       if <> or [] down force CAPS/caps, otherwise toggle

        set     7, (ix+kbd_repeatcnt)           ; disable repeat
        ld      a, (ix+kbd_flags)
        bit     QB_DIAMOND, d
        jr      z, spec1
        and     255-(KBF_CAPSE|KBF_CAPS)        ; force CAPS

.spec1  bit     QB_SQUARE, d
        jr      z, spec2
        or      KBF_CAPS                        ; force caps
        and     255-KBF_CAPSE

.spec2  xor     KBF_CAPSE                       ; toggle enable
        ld      (ix+kbd_flags), a
        call    DrawOZWd
        jr      SetKeyDown

.spec3  cp      ESC                             ; ESC signal, is it SHIFT(CLI) or <>(CLI) ?
        jr      nz, ApplyQualifiers             ; all other key go there

        set     7, (ix+kbd_repeatcnt)           ; disable repeat
        ld      hl, ubIntStatus                 ; interrupt status
        ld      a, (ubCLIActiveCnt)
        ld      e, a                            ; CLI count
        ld      a, d                            ; qualifiers
        and     QB_SHIFT|QB_DIAMOND
        jr      z, ApplyQualifiersToESC
        inc     e                               ; is CLI active
        dec     e
        jr      z, SetKeyDown                   ; CLI byte counter=0

        or      (hl)                            ; low 2 bits match exactly (qualifiers/intstatus)
        ld      (hl), a                         ; set/res bit 0 (CLISHIFT) and 1 (CLIDMND)
        dec     hl                              ; hl = ubIntTaskToDo
        set     ITSK_B_OZWINDOW, (hl)           ; update OZ window

.SetKeyDown
        push    hl
        ld      hl, KbdData+kbd_flags
        set     KBF_B_KEY, (hl)                 ; any (not <>/[]) key down
        pop     hl
        scf
        ret

; ---------------------------------------------------------------------------
; get the translation table pointer
;       In:     A = keymap table ID (matrix, shift, caps, diamond, square)
;       Out:    HL = keymap table
;
;       AF....HL/....
; ---------------------------------------------------------------------------
.GetKbdPtr
        cp      KMT_CAPS                        ; =2
        jr      c, gkp_1

        ld      hl, ubKmBank                    ; start of keymap table pointers
        add     a, l
        ld      l, a
        ld      l, (hl)
        jr      gkp_x

;       KMT_MATRIX (0) -> 00, KMT_SHIFT (1) -> 40
.gkp_1
        rrca
        rrca
        ld      l, a

.gkp_x
        ld      a, (ubKmPage)
        ld      h, a
        ret

; ---------------------------------------------------------------------------
;       Generic pair-matching routine, ascending order tables
;       Faster than CPIR as we skip odd bytes and can exit prematurely
;       without finding match
;
;       in:     A=keycode, L=table
;       out:    Fc=0, A=newcode         translated
;               Fc=1, A=in(A)           not translated
;
;       ..BCDE.. IXIY
;       AF....HL ....
; ---------------------------------------------------------------------------
.TranslateTable                                 ; translate using table L
        push    bc
        push    af
        ld      a, l
        call    GetKbdPtr
        pop     af
        call    TranslateKey
        pop     bc
        ret
        
.TranslateKey
        ld      b, (hl)                         ; table length
        inc     b                               ; take care of empty table
        jr      tr_s
.tr_l   inc     hl
        cp      (hl)
        ret     c                               ; entries sorted, shortcut false
        inc     hl
        jr      z, tr_ok
.tr_s   djnz    tr_l
        scf
        ret
.tr_ok  ld      a, (hl)                         ; get translated char, exit with Fc=0
        ret

; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
.ApplyQualifiersToESC
        ld      a, ESC

; ---------------------------------------------------------------------------
;       Handle qualifier translations
;
;       Fc=0, A=outchar if no error
;       Fc=1, ignore key
; ---------------------------------------------------------------------------
.ApplyQualifiers
        call    SpecInternal                    ; enter/tab/del/menu/index/help or cursor key
        ret     nc                              ; done

;       A=upper(A), Fc=0 : IsAlpha()

        ld      c, a                            ; remember key
        and     $df                             ; to uppercase
        cp      'Z'+1
        jr      nc, not_alpha
        cp      'A'
        jr      nc, is_alpha

.not_alpha
        ld      a, c                            ; restore key
        scf                                     ; not alpha
.is_alpha                                       ; A is upper alpha, C is alpha
        bit     QB_DIAMOND, d
        jr      z, TestShift

; -----------------
; do <> translation
; -----------------

        ld      l, KMT_DIAMOND
        jr      c, TranslateTable               ; non-alpha, use table
        and     $1f                             ; otherwise A-Z = $01-$1A
        ret

.TestShift
        bit     QB_SHIFT, d
        jr      z, TestSquare

; --------------------
; do shift translation
; --------------------
        jr      c, Shift_non_alpha

; shift alpha
; -----------
        push    af
        xor     $20                             ; swap case
        ex      af, af'                         ; a is lower alpha
        pop     af                              ; A is upper alpha

.DoShiftCAPS
        inc     b
        ret     z                               ; external call if b=-1

        bit     KBF_B_CAPSE, (ix+kbd_flags)     ; is caps or CAPS ?
        ret     z                               ; no CAPS/caps, return upper alpha
        bit     KBF_B_CAPS, (ix+kbd_flags)      ; is CAPS enabled ?
        ret     z                               ; dont process shift if CAPS
        ex      af, af'                         ; shift can be applied to caps, return lower
        ret

; shift non alpha
; ---------------
.Shift_non_alpha
        call    DoCapsable
        jr      nc, DoShiftCAPS                 ; is capsable
        ld      l, KMT_SHIFT
        jr      TranslateTable                  ; not capsable, use shift table (no need to process CAPS here)

.TestSquare
        bit     QB_SQUARE, d
        jr      z, NoQual                       ; No qualifier

; -----------------
; do [] translation
; -----------------
        ld      l, KMT_SQUARE
        jp      c, TranslateTable               ; non-alpha, use table
        or      $80                             ; otherwise A-Z = $81-$9A
        and     $9f                             ; use hires1 char for OZWindow
        ret

; ---------------
; no qualifiers
; apply caps/CAPS
; ---------------
.NoQual inc     b
        jr      z, qend                         ; B was -1, external call

        call    DoCapsable
        or      a                               ; Fc=0
        bit     KBF_B_CAPSE, (ix+kbd_flags)     ; is caps or CAPS ?
        ret     nz                              ; CAPS/caps enabled, return A

.qend
        ld a,c                                  ; return original key
        or      a
        ret

; ---------------------------------------------------------------------------
;       Check if char is affected by caps lock
;
;       In:     A=char
;       Out:    Fc=0, char is capsable and A=upper(char), a=lower(char)
;               Fc=1, char is not capsable and A=char
;
;       AF....../....
; ---------------------------------------------------------------------------
.DoCapsable
        push    bc
        or      a                               ; Fc=0
        push    af
        ex      af, af'
        ld      a, KMT_CAPS
        call    GetKbdPtr                       ; fetch CAPS translation table
        pop     af
        ld      b, (hl)                         ; # entries
        inc     b
        dec     b
        jr      z, caps_xc                      ; handle empty table
.caps_4
        inc     hl
        cp      (hl)
        inc     hl
        jr      z, c_low                        ; lowercase match
        cp      (hl)
        jr      z, c_up                         ; uppercase match
        djnz    caps_4
.caps_xc                                        ; exit with Fc=1
        scf
        jr      caps_x
.c_up
        dec     hl
        ld      a, (hl)
        ex      af, af'                         ; lowercase in a'
        inc     hl                              ; waste one cycle to gain one byte compared to jr caps_0
.c_low
        ld      a, (hl)                         ; uppercase in A
.caps_0
        or      a

.caps_x
        pop     bc
        ret

; ---------------------------------------------------------------------------
;       Dead-key handling
;
;       in:     A=keycode
;       out:    Fc=0, A=newcode         wasn't dead key or was translated
;               Fc=1                    swallowed, ignore key
;
;       AF.CD.HL/....
; ---------------------------------------------------------------------------
.DeadKeys
        ld      c, a                            ; save key

        ld      a, KMT_DEADKEY
        call    GetKbdPtr

        ld      a, (ubKmDeadsub)                ; deadkey active?
        or      a
        jr      z, d_not

;       we were prefixed, try to find the key
;       we check cancelation later, so we can handle things like ^^ here

        push    hl                              ; remember dead key table
        ld      l, a                            ; go to subtable
        ld      a, c                            ; translate this key
        call    TranslateKey
        pop     hl
        jr      nc, dead_tr                     ; return translated key

;       check for cancelation with same key or del

        cp      (ix+kbd_lastkey)
        jr      z, d_cancel
        cp      $e3
        jr      z, d_cancel

;       we were not prefixed or key wasn't found, check if this is dead key

.d_not  ld      a, c
        ld      (ix+kbd_lastkey), a
        call    TranslateKey                    ; find key in deadkey table
        jr      c, dead_not

;       was deadkey, remember and swallow - but only if not in [] or <> sequence

        ld      l, a

        ld      a, (ubSysFlags1)                ; if [] or <> then cancel it
        and     SF1_OZDMND|SF1_OZSQUARE         ; $30
        ld      a, IN_SQU                       ; ($b8) by sending keycode for []
        jr      nz, dead_tr

        ld      a, (hl)                         ; get char
        ld      (ubKmDeadchar), a               ; for OZ window
        inc     hl
        ld      a, l
        jr      d_x                             ; store subtable ptr

;       was translated

.dead_tr
        ld      c, a

;       was not special, clear dead-key and return key

.dead_not
        call    d_cancel
        ld      a, c
        or      a
        ret

.d_cancel
        xor     a                               ; cancel deadkey
        ld      (ubKmDeadchar),a                ; will be a space char in OZ window
.d_x    ld      (ubKmDeadsub), a

        push    bc
        call    DrawOZWd
        pop     bc

        scf
        ret

; ---------------------------------------------------------------------------
;       Test key status
;
;       In:     A = rawkey
;       Out:    Fz= 0 if key not pressed
;               Fz= 1 if key pressed
;
;       AFBC..../....
; ---------------------------------------------------------------------------
.KbdTestKey
        push    af
        rrca
        rrca
        rrca
        call    RdKeyRowA                       ; get row (A/8)
        ld      c, a
        pop     af

        and     7
        ld      b, a
        inc     b
        ld      a, $80
.tk1    rlca                                    ; rotate bit into correct position
        djnz    tk1

        and     c                               ; test key
        ret

; ---------------------------------------------------------------------------
;       Return keys on given row
;
;       In:     A=row number
;       Out:    Fc=0, A=keyrow
;
;       AFBC..../....
; ---------------------------------------------------------------------------
.RdKeyRowA
        push    iy
        and     7
        ld      c, a
        ld      b, 0
        add     iy,bc
        ld      a, (iy+0)
        pop     iy
        ret

; ---------------------------------------------------------------------------
;       Return qualifier status
;
;       Out: A=Qbits (0-shift, 1-diamond, 2-square)
;
;       AF..D.../....
; ---------------------------------------------------------------------------
.GetQual
        ld      a, (iy+6)
        and     $50                             ; .  sl .  <>  . . . .
        rlca                                    ; sl .  <> .   . . . .
        ld      d, a
        ld      a, (iy+7)
        and     $c0                             ; sr [] .  .   . . . .
        or      d                               ; sh [] <> .   . . . .

;       we want them in . . . . . [] <> sh

        rla                                     ; Fc=sh
        adc     a, $1f                          ; sets bit 5 if carry was set
        rlca
        rlca
        rlca                                    ; we don't care about extra bits, so skip "and 7"
        ret

; ---------------------------------------------------------------------------
;       Check key matrix for some other key, also update qualifier flags
;
;       In:     A=rawkey
;       Out:    Fc=0, A=rawkey if other key found
;               Fc=1 otherwise
; ---------------------------------------------------------------------------
.FindOtherKey
        push    ix
        ld      d, a
        ld      a, (iy+8)
        or      a
        jr      z, fok8                         ; no keys, return with carry

        ld      ix, KbdMaskTable+3
        ld      l, $38                          ; loops 38 to 0 step -8

        ld      bc, $800
        ld      e, b

.fok1   push    bc
        ld      a, b
        cp      6
        jr      c, fok12
        dec     ix

.fok12  dec     a
        call    RdKeyRowA
        pop     bc
        ld      h, a

        cp      (ix+3)                          ; 0,sh-l,sh-r
        jr      z, fok2
        inc     c                               ; we have something else than just shift

.fok2   and     (ix+3)                          ; is shift down
        call    nz, SetKeyDown                  ; set shift flag

        ld      a, h
        and     (ix+6)                          ; is [] or <> down?
        jr      z, fok3

        ld      a, (KbdData+kbd_flags)         ; set flag
        or      (ix+6)
        ld      (KbdData+kbd_flags), a

.fok3   ld      a, h                            ; any non-qualifier key down?
        and     (ix+0)
        jr      z, fok7                         ; no

        ld      h, a                            ; key mask in shift register
        ld      a, l                            ; raw keycode
.fok4   srl     h
        jr      c, fok6                         ; key found
        jr      z, fok7                         ; no more keys
.fok5   inc     a                               ; bump key
        jr      fok4
.fok6   cp      d
        jr      z,fok5                          ; this was the current key

        or      a                               ; Fc=0
        jr      fok9

.fok7   sbc     hl, de                          ; l=l-8
        djnz    fok1

        inc     c
        dec     c
        call    z,  SwitchOff

.fok8   scf

.fok9   pop     ix
        ret

.KbdMaskTable
        defb    $FF,$AF,$3F
        defb    $00,$40,$80
        defb    $00,KBF_DMND,KBF_SQR


; ---------------------------------------------------------------------------
.RdKeymatrix
        push    iy
        pop     hl

        ld      bc, $FEB2                       ; column | port
        ld      d, 0
.rkm1   in      a, (c)
        cpl                                     ; active high
        ld      (hl), a                         ; store row
        inc     hl
        or      d
        ld      d, a                            ; update column mask
        rlc     b
        jr      c, rkm1                         ; loop 8 rows
        ld      (hl), d                         ; store colum mask

        neg
        and     d
        xor     d
        ret     z                               ; only one column active - Fz=1 Fc=0

;       outer loop: find row with multiple keys down

        push    iy
        pop     hl
        ld      b, 7                            ; do 7 rows

.rkm2   ld      a, (hl)
        inc     hl
        ld      d, a
        neg
        and     d
        xor     d
        jr      z, rkm5                         ; no multiple keys

        ld      c, b                            ; remember count
        push    hl

;       inner loop: find another row with common multiple keys down
;       changed to check only remaining B rows, that halves processing time

.rkm3   ld      a, (hl)
        inc     hl
        and     d
        ld      e, a                            ; common keys in two rows
        neg
        and     e
        xor     e
        jr      nz, rkm6                        ; multiple keys in both rows
.rkm4   djnz    rkm3                            ; repeat inner loop

        pop     hl
        ld      b, c

.rkm5   djnz    rkm2                            ; repeat outer loop

        ret                                     ; Fc=0

.rkm6   pop     hl                              ; Fc=1 multiple keys in multiple rows
        ccf
        ret

; ---------------------------------------------------------------------------
;       Handle enter/tab/del/menu/index/help and cursor keys internally
;
;       AF.C..../....
; ---------------------------------------------------------------------------
.SpecInternal

        ld      c, 4
        cp      $fc                             ; IN_LFT
        jr      nc, si_1                        ; cursor key
        ld      c, $10
        cp      $e1                             ; this code relies on fact that (IN_ENTER)
        ret     c                               ; $e4 (internal ESC) is unused
        cp      $e8                             ; IN_CAPS
        ccf
        ret     c
.si_1   bit     QB_DIAMOND, d
        jr      nz, si_dm
        bit     QB_SHIFT, d
        jr      nz, si_sh
        bit     QB_SQUARE, d
        ret     z                               ;    e1-e7 fc-ff
.si_sq  sub     c                               ; [] b1-b7 f0-f3
.si_dm  sub     c                               ; <> c1-c7 f4-f7
.si_sh  sub     c                               ; sh d1-d7 f8-fb
        ret

; ---------------------------------------------------------------------------
; test if A is a foreign or a system key
;
;
;   Fc=1 if $00-$A0, $A4-$B8, $C0-$C8, $D0-$D8, $E0-$E8 (not a foreign key)
;   Fc=0 if $A1-$A3, $B9-$BF, $C9-$CF, $D9-$DF, $E9-$FF (is a foreign key)
;
; Fix for OZ FI : now A1-AF is foreign, B0-B8 is system
; ---------------------------------------------------------------------------
.IsForeignKey
        push    af
        ex      af, af'
        pop     af
        cp      $A1                             ; EXACT is a system key (processed by SD)
        ret     c
        cp      $A9
        ccf
        jr      nc, ifk_nc
        cp      $AB
        ret     c
        cp      $B0                             ; cp $0A4 in previous version
        ccf
        jr      nc, ifk_nc

        cp      $0B9
        ret     c
        cp      $0C0
        ccf
        jr      nc, ifk_nc

        cp      $0C9
        ret     c
        cp      $0D0
        ccf
        jr      nc, ifk_nc

        cp      $0D9
        ret     c
        cp      $0E0
        jr      c, ifk_nc

        cp      $0E9
        ret     c
        cp      $0F0
        ccf
        ret     c
.ifk_nc
        cp      a
        ret
