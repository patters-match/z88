; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $39d2
;
; $Id$
; -----------------------------------------------------------------------------

        module  OZWindow

        include "all.def"
        include "sysvar.def"

        org     $f9d2           ; 280 bytes

xdef    OZwd_card
xdef    OZwd_index
xdef    OZwd__fail
xdef    OZwd_fail
xdef    DrawOZwd

defc    ScreenOpen              =$faea
defc    ScreenClose             =$faf6


.OZwd_card
        ld      bc, $9495                       ; "card"
        jr      loc_F9DA

.OZwd_index
        ld      bc, $9697                       ; "index"

.loc_F9DA
        call    ScreenOpen

        ld      hl, LCD_ozrow1
        call    ozoz_1

        call    ScreenClose

        ret


.OZwd__fail
        call    ScreenOpen


.OZwd_fail
        ld      hl, LCD_ozrow1
        ld      bc, $8A8B                       ; "fail"
        call    ozoz_1
        jr      OZwd_fail

;       ----

.OZwd_oz
        ld      hl, LCD_ozrow1
        ld      a, LCDA_HIRES|LCDA_GREY|LCDA_UNDERLINE|LCDA_CH8

        ld      bc, $8081                       ; "OZ"

        ld      de, (ubKbdFlags)                ; show "lock out" if locked
        bit     KBF_B_LOCKED, e
        jr      z, ozoz_2
        ld      bc, $8283                       ; "lock out"
.ozoz_1
        ld      a, LCDA_HIRES|LCDA_FLASH|LCDA_UNDERLINE|LCDA_CH8

.ozoz_2
        jp      VDUputBCA

;       ----

.DeadkeyChars
        defb    $bf                             ; bold ?
        defb    $bf                             ; bold ?
        defb    $de                             ; bold ^
        defb    $9e                             ; c,


.DrawOZwd
        call    ScreenOpen

        ld      hl, ubIntTaskToDo
        res     ITSK_B_OZWINDOW, (hl)

        call    OZwd_oz
        call    OZwd_bell
        call    OZwd_cli
        call    OZwd_batlow
        call    OZwd_caps

        ld      c, $a0                          ; default char

        ld      a, (ubKbdLastkey)               ; dead key !! this is changed in new routines
        or      a
        jr      z, droz_1

        cp      $ac
        jr      c, droz_1
        cp      $b0
        jr      nc, droz_1

        add     a, <DeadkeyChars-$ac
        ld      l, a
        ld      h, >DeadkeyChars
        ld      c, (hl)

.droz_1
        call    OZcmdActive
        jr      c, droz_2

        ld      hl, ubSysFlags1
        ld      c, $91                          ; '[]'
        bit     SF1_B_OZSQUARE, (hl)
        jr      nz, droz_2
        ld      c, $90                          ; '<>'  !! dec c

.droz_2
        ld      hl, LCD_ozrow5
        ld      (hl), c

        ld      b, 4
        ld      de, OZcmdBuf
        ld      hl, LCD_ozrow5+2                ; column 2 in OZ window
        ld      (hl), $a0
        jr      c, droz_4

.droz_3
        ld      a, (de)                         ; cmd char
        or      a
        jr      z, droz_4                       ; end of command? exit

        or      $80                             ; into char
        ld      (hl), a                         ; onto screen
        inc     l
        ld      (hl), LCDA_HIRES|LCDA_UNDERLINE|LCDA_CH8
        dec     l
        inc     de                              ; next char
        inc     h                               ; next line
        djnz    droz_3

.droz_4
        call    ScreenClose

        or      a                               ; Fc=0 !! why?
        ret

;       ----


.OZcmdActive
        ld      a, (ubSysFlags1)
        and     SF1_OZDMND|SF1_OZSQUARE         ; <> or [] in OZ wd
        ld      hl, OZcmdBuf
        or      (hl)                            ; first app/command char
        scf
        ld      a, LCDA_HIRES|LCDA_UNDERLINE|LCDA_CH8
        ret     z                               ; Fc=1 if no command
        ld      a, LCDA_HIRES|LCDA_GREY|LCDA_UNDERLINE|LCDA_CH8 ; !! do this with 'or LCDA_GREY', eliminates 'or a'
        or      a                               ; Fc=0 if command
        ret

;       ----

.OZwd_caps
        ld      hl, LCD_ozrow8
        ld      bc, $a0a0                       ; blank

        ld      a, (ubKbdFlags)
        bit     KBF_B_CAPSE, a
        jr      z, ozcaps_1
        ld      bc, $8485                       ; "CAPS"
        bit     KBF_B_CAPS, a
        jr      z, ozcaps_1
        ld      bc, $8687                       ; "caps"

.ozcaps_1
        ld      a, LCDA_HIRES|LCDA_UNDERLINE|LCDA_CH8

.VDUputBCA
        ld      (hl), b
        inc     l
        ld      (hl), a
        inc     l
        ld      (hl), c
        inc     l
        ld      (hl), a
        ret

;       ----

.OZwd_batlow
        ld      bc, $a0a0                       ; blank
        ld      d, b
        ld      e, c

        ld      a, (ubIntStatus)
        bit     IST_B_BATLOW, a
        jr      z, ozbat_1
        ld      bc, $8C8D                       ; "bat"
        ld      de, $8E8F                       ; "low"

.ozbat_1
        call    OZcmdActive                     ; get attributes
        ld      hl, LCD_ozrow6
        call    VDUputBCA
        ld      hl, LCD_ozrow7
        ld      b, d
        ld      c, e
        jr      VDUputBCA

;       ----

.OZwd_bell
        ld      hl, LCD_ozrow2
        ld      bc, $a0a0                       ; blank
        ld      a, (ubAlmDisplayCnt)
        or      a
        jr      z, ozbell_1
        ld      bc, $9293                       ; bell symbol

.ozbell_1
        ld      a, LCDA_HIRES|LCDA_FLASH|LCDA_UNDERLINE|LCDA_CH8
        jr      VDUputBCA

;       ----

.OZwd_cli
        ld      hl, LCD_ozrow3
        ld      bc, $a0a0                       ; blank

        ld      a, (ubCLIActiveCnt)
        or      a
        jr      z, ozcli_1
        ld      bc, $8889                       ; "cli"

.ozcli_1
        jr      ozcaps_1

