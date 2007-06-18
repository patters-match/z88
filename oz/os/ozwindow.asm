; **************************************************************************************************
; The OZ window display routines
;
; This table was extracted out of Font bitmaps from original V3.x and V4.0 ROMs using FontBitMap tool,
; and combined/re-arranged into the new international font bitmap by Thierry Peycru.
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
; Additional development improvements, comments, definitions and new implementations by
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; $Id$
; **************************************************************************************************
;
; OZ window layout
; ROW MESSAGE
; 1     OZ / INDEX / FAIL / LOCKOUT
; 2     localisation (2 letters)
; 3     CLI
; 4     alarm bell
; 5     command
; 6     bat  / command
; 7     low  / command
; 8     caps / command
;

        module  OZWindow

        include "screen.def"
        include "sysvar.def"
        include "interrpt.def"
        include "keyboard.def"

xdef    OZwd_card
xdef    OZwd_index
xdef    OZwd__fail
xdef    OZwd_fail
xdef    DrawOZwd
xdef    MayDrawOZwd
xdef    SetPendingOZwd

xref    ScreenOpen                              ; [Kernel0]/srcdrv4.asm
xref    ScreenClose                             ; [Kernel0]/srcdrv4.asm



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

        ld      de, (KbdData+kbd_flags)         ; show "lock out" if locked
        bit     KBF_B_LOCKED, e
        jr      z, ozoz_2
        ld      bc, $8283                       ; "lock out"
.ozoz_1
        ld      a, LCDA_HIRES|LCDA_FLASH|LCDA_UNDERLINE|LCDA_CH8

.ozoz_2
        jp      VDUputBCA

.DrawOZwd
        call    ScreenOpen

        ld      hl, ubIntTaskToDo
        res     ITSK_B_OZWINDOW, (hl)

        call    OZwd_oz
        call    OZwd_loc
        call    OZwd_bell
        call    OZwd_cli
        call    OZwd_batlow
        call    OZwd_caps
        ld      a, (ubKmDeadchar)
        or      a
        jr      nz,droz_1
        ld      a,$a0                           ; default char is a space in OZ font (8 bits width)
.droz_1
        ld      c,  a
        call    OZcmdActive
        jr      c, droz_2

        ld      hl, ubSysFlags1
        ld      c, $91                          ; '[]'
        bit     SF1_B_OZSQUARE, (hl)
        jr      nz, droz_2
        dec     c                               ; '<>'  (was ld c, $90)

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

        or      a                               ; Fc=0, why?
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
        or      LCDA_GREY                       ; Fc=0 if command
        ret

;       ----

.OZwd_caps
        ld      hl, LCD_ozrow8
        ld      bc, $a0a0                       ; blank

        ld      a, (KbdData+kbd_flags)
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
        ld      hl, LCD_ozrow4
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
        jr      ozbell_1


;       ----

.OZwd_loc
        ld      bc, (aKmCountry)
        ld      hl, LCD_ozrow2
        ld      a, LCDA_HIRES|LCDA_GREY|LCDA_UNDERLINE|LCDA_CH8
        jr      VDUputBCA

;       ----

;       draw OZ window if needed

.MayDrawOZwd
        push    bc
        push    de
        ld      hl, ubIntTaskToDo
        bit     ITSK_B_OZWINDOW, (hl)
        call    nz, DrawOZwd
        pop     de
        pop     bc
        ret

;       ----

;       request OZ window redraw

.SetPendingOZwd
        ld      hl, ubIntTaskToDo
        set     ITSK_B_OZWINDOW, (hl)
        ret
