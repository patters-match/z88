; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d9cb
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSCli

        org $99cb                               ; 288 bytes

        include "all.def"
        include "sysvar.def"
        include "bank0.def"

xdef    OSCliMain



.OSCliMain
        ld      hl, ubCLIActiveCnt
        or      a                               ; Fc=0

.oscli_rim
        djnz    oscli_mbc
        ld      b, a
        call    RdKbBuffer                      ; get raw input
        call    PutOSFrame_BC                   ; return timeout
        jr      climbc_1

.oscli_mbc
        djnz    oscli_cmb
        ld      a, e                            ; meta/base to character conversion
        cp      $20                             ; if ctlr char, translate to keycode
        call    c, CLIchar2key                  ; !! nop, all inchars alphabetic
        bit     QUAL_B_SPECIAL, d
        call    nz, CLIchar2key                 ; special key? translate to keycode
        ld      b, -1                           ; external call identifier
        call    ApplyQualifiers                 ; translate A with qualifiers D

.climbc_1
        ld      d, 0                            ; clear qualifiers
.climbc_2
        ret     c                               ; return error
        ld      e, a                            ; else char just read/translated
        jp      PutOSFrame_DE

.oscli_cmb
        djnz    oscli_inc
        ld      a, e                            ; character to meta/base conversion
        call    Key2Meta
        jr      climbc_2                        ; return key and qualifiers

.oscli_inc
        djnz    oscli_dec
        ld      a, (hl)                         ; increment CLI use count
        or      a
        jr      nz, cliinc_1

        push    hl                              ; first active CLI, reset flags
        ld      hl, ubIntStatus
        res     IST_B_CLISHIFT, (hl)
        res     IST_B_CLIDMND, (hl)
        pop     hl

.cliinc_1
        inc     (hl)
        jr      clires_1

.oscli_dec
        djnz    oscli_res
        dec     (hl)                            ; decrement CLI use count
        jr      clires_1

.oscli_res
        djnz    oscli_ack
        ld      (hl), 0                         ; reset CLI use count !! ld (hl), b

.clires_1
        jp      SetPendingOZwd

.oscli_ack
        djnz    oscli_x
        ld      hl, ubIntStatus                 ; acknowledge CLI/Escape
        bit     QUAL_B_CTRL, d                  ; !! bits match, use ld a,d; and 3; cpl; and (hl); ld (hl),a
        jr      z, cliack_1
        res     IST_B_CLIDMND, (hl)
.cliack_1
        bit     QUAL_B_SHIFT, d
        jr      z, cliack_2
        res     IST_B_CLISHIFT, (hl)
.cliack_2
        ld      a, (hl)                         ; return A=resulting shift/ctrl status, Fz=1 if neither active
        and     3
        ld      (iy+OSFrame_D), a
        ret     nz
        set     6, (iy+OSFrame_F)
        ret

.oscli_x
        ld      a, RC_Unk
        scf
        ret

;       ----

;       this is branched into from below

.cc2k_1
        ld      a, (hl)
        or      a
        ret

;       translate char after '~' into keycode
;       A=translate(A)

.CLIchar2key
        call    AtoN_upper
        ld      bc, 24
        ld      hl, CLI2key_tab
.cc2k_2
        cpir
        ret     nz
        bit     0, c
        jr      nz, cc2k_1                      ; found at even offset, return byte
        jp      pe, cc2k_2                      ; loop if not end
        ret

.CLI2key_tab
        defb    'D',$FE                         ; D down
        defb    'E',$E1                         ; E enter
        defb    'H',$E7                         ; H help
        defb    'I',$E6                         ; I index
        defb    'L',$FC                         ; L left
        defb    'M',$E5                         ; M menu
        defb    'R',$FD                         ; R right
        defb    'T',$E2                         ; T tab
        defb    'U',$FF                         ; U up
        defb    'X',$E3                         ; X del
        defb    'C',$C8                         ; C ctrl
        defb    'A',$B8                         ; A alt

;       ----

;       translate keyboard code into meta char
;       A,D=translate(A)

.Key2Meta
        ld      hl, Key2Meta_tbl                ; !! ld hl,tbl-2; inc hl; inc hl
.k2m_1
        cp      (hl)
        inc     hl
        jr      nc, k2m_2                       ; found key area, translate
        inc     hl                              ; try next
        inc     hl
        jr      k2m_1
.k2m_2
        ld      d, (hl)                         ; qualifier
        inc     hl
        ld      l, (hl)                         ; address low byte
        ld      h, >crsr                        ; address high byte
        inc     l
        dec     l
        ret     z                               ; return if no table
        and     (hl)                            ; mask to range
        add     a, l                            ; and point to char
        ld      l, a
        inc     hl                              ; skip mask byte
        ld      a, (hl)                         ; return meta char
        ret

;       entries in descending order
;       low limit, meta key, key table

.Key2Meta_tbl
        defb    $FC, QUAL_SPECIAL, <crsr
        defb    $F8, QUAL_SPECIAL|QUAL_SHIFT, <crsr
        defb    $F4, QUAL_SPECIAL|QUAL_CTRL, <crsr
        defb    $F0, QUAL_SPECIAL|QUAL_ALT, <crsr
        defb    $E9, 0, 0
        defb    $E0, QUAL_SPECIAL, <spec
        defb    $D9, 0, 0
        defb    $D0, QUAL_SPECIAL|QUAL_SHIFT, <spec
        defb    $C9, 0, 0
        defb    $C8, QUAL_SPECIAL, <c
        defb    $C0, QUAL_SPECIAL|QUAL_CTRL, <spec
        defb    $B9, 0, 0
        defb    $B8, QUAL_SPECIAL, <a
        defb    $B0, QUAL_SPECIAL|QUAL_ALT, <spec
        defb    $A0, 0, 0
        defb    $80, QUAL_ALT, <ctrl
        defb    $20, 0, 0
        defb    $00, QUAL_CTRL, <ctrl

;       length mask, character codes
;       !! careful - can't cross page boundary

.crsr   defb    3                               ; cursor keys
        defm    "LRDU"

.spec   defb    7                               ; enter tab del (esc) menu index help
        defm    " ETX?MIH"

.ctrl   defb    $1F                             ; control chars
        defm    "=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        defb    $5B,$5C,$5D,$A3,$2D             ; [\]£-

.c      defb    0                               ; ctrl
        defm    "C"

.a      defb    0                               ; alt
        defm    "A"
