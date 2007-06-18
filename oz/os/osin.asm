; **************************************************************************************************
; The OS_In/OS_Tin main entry. The routines are located in Kernel 0.
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


        Module OSIn

        include "buffer.def"
        include "blink.def"
        include "director.def"
        include "error.def"
        include "stdio.def"
        include "sysvar.def"
        include "interrpt.def"
        include "keyboard.def"

        include "lowram.def"

xdef    OSIn
xdef    OSTin
xdef    OSPur
xdef    OSXin
xdef    OSDly
xdef    CancelOZcmd

xdef    ostin_4
xdef    PutOZwdBuf
xdef    RdKbBuffer
xdef    RdStdin
xdef    RdStdinNoTO
xdef    sub_EF92
xdef    sub_EFBB

xref    ResetTimeout                            ; [Kernel0]/nmi.asm
xref    ExtQualifiers                           ; [Kernel0]/kbd.asm
xref    IsForeignKey                            ; [Kernel0]/kbd.asm
xref    MayDrawOZwd                             ; [Kernel0]/misc3.asm
xref    OSFramePop                              ; [Kernel0]/misc4.asm
xref    OSFramePush                             ; [Kernel0]/misc4.asm
xref    AtoN_upper                              ; [Kernel0]/misc5.asm
xref    PutOSFrame_BC                           ; [Kernel0]/misc5.asm
xref    BfGbt                                   ; [Kernel0]/buffer.asm
xref    BfPur                                   ; [Kernel0]/buffer.asm
xref    DoAlarms                                ; [Kernel0]/osalm0.asm
xref    DrawOZwd                                ; [Kernel0]/ozwindow.asm
xref    FindCmd                                 ; [Kernel0]/mth0.asm
xref    MaySetEsc                               ; [Kernel0]/esc.asm
xref    TestEsc                                 ; [Kernel0]/esc.asm
xref    UpdateRnd                               ; [Kernel0]/random.asm

xref    Chr2ScreenCode                          ; [Kernel1]/scrdrv1.asm
xref    DoHelp                                  ; [Kernel1]/mth1.asm
xref    Key2Chr_tbl                             ; [Kernel1]/key2chrt.asm



; ---------------------------------------------------------------------------------------------
; Delay a given period
;
;IN:    BC = delay in centiseconds
;OUT:   Fc=1, BC remaining time, A=error
;       RC_ESC ($01), escape was pressed
;       RC_SUSP ($69), process suspended
;       RC_TIME ($02), timeout
;
;chg:   (BfGbt)-IX

.OSDly
        push    ix
        ld      ix, fakehnd+2
        call    BfGbt
        call    PutOSFrame_BC
        pop     ix
        ret
.fakehnd
        defb 0, 0


; ---------------------------------------------------------------------------------------------
; Purge keyboard buffer
;
;IN:    -
;OUT:   Fc=0
;chg:   F

.OSPur
        push    af
        push    ix
        ex      af, af'
        exx
        call    CancelOZcmd                     ; cancel any [] or <> command
        exx
        ex      af, af'
        ld      ix, KbdData
        call    BfPur
        pop     ix
        pop     af
        or      a                               ; Fc=0
        jp      OZCallReturn2                   ; return AF and undo exx


; ---------------------------------------------------------------------------------------------
; Examine input
;
;IN: IX = stream handle
;OUT:   Fc = 0, OS_In will return immediately - possibly with error!
;       Fc = 1, A=RC_EOF ($09), OS_In   will wait
;chf:   AF....HL/.... +DC_Xin?

.OSXin
        ex      af, af'
        or      a                               ; Fc=0
        ex      af, af'

        call    DoAlarms                        ; check for alarms
        call    MayDrawOZwd                     ; and draw OZwd if necessary

        ld      a, (ubSysFlags1)
        bit     SF1_B_XTNDCHAR, a
        jr      nz, osxin_1                     ; have extended char? exit

        ld      a, (ubIntTaskToDo)
        bit     ITSK_B_PREEMPTION, a
        jr      nz, osxin_1                     ; pre-empted? exit

        call    TestEsc
        jr      c, osxin_1                      ; ESC pending? exit

        ld      a, (KbdData + buf_wrpos)
        ld      hl, KbdData + buf_rdpos         ; hl is already destroyed by DoAlarms
        cp      (hl)
        jr      nz, osxin_1                     ; keyboard buffer not empty? exit

        ld      a, (ubCLIActiveCnt)
        or      a
        jr      nz, osxin_2                     ; CLI active? check it's input

        ex      af, af'                         ; Fc=1, no input available
        ld      a, RC_Eof
        scf
        ex      af, af'
.osxin_1
        jp      OZCallReturn3                   ; return af'
.osxin_2
        ex      af, af'
        exx
        OZ      DC_Xin                          ; Examine CLI input
        jp      OZCallReturn1                   ; return AF


;       ----

.RdStdinNoTO
        ld      bc, -1

.RdStdin
        ld      a, (ubCLIActiveCnt)
        or      a
        jr      z, RdKbBuffer                   ; no cli? read keyborad
        call    UpdateRnd
        call    ResetTimeout
        OZ      DC_In                           ; Read from CLI
        jr      nc, rdin_1                      ;  no error? exit
        cp      RC_Eof                          ; End Of File
        jr      z, RdStdin                      ; EOF? read again
        scf                                     ; return error
        ret
.rdin_1
        ld      a, e
        cp      ESC
        call    z, MaySetEsc
        or      a
        ret
.RdKbBuffer
        push    ix
        ld      ix, KbdData
        call    BfGbt
        pop     ix
        ret

; read character from standard input, with timeout

.OSTin
        call    OSFramePush
        call    OSTinMain
        call    PutOSFrame_BC
        jr      in_sub
; read (wait for) character from standard input
.OSIn
        call    OSFramePush
        ld      bc, -1
        call    OSTinMain
.in_sub
        ld      (iy+OSFrame_A), a
        jp      OSFramePop
;       ----
.OSTinMain
        ld      (uwOSTinTimeout), bc
        push    ix
        push    iy
        ld      (pAppStackPtr), sp              ; remember SP
        ld      hl, BLSC_SR0                    ; remember bindings
        ld      de, ubAppBindings
        ld      bc, 3
        ldir
        ld      a, (ubAppCallLevel)             ; remember call level
        ld      (ubOldCallLevel), a
        call    DoAlarms                        ; handle expired alarm
        call    MayDrawOZwd                     ; update OZ window
        ld      hl, ubSysFlags1
        bit     SF1_B_XTNDCHAR, (hl)
        jr      z, ostin_6
        call    CancelOZcmd
        ld      a, (cExtendedChar)
.ostin_1
        or      a
.ostin_2
        pop     iy
        pop     ix
        ret
.ostin_3
        ld      hl, ubSysFlags1
        bit     SF1_B_OZSQUARE, (hl)
        call    nz, CancelOZcmd                 ; !! should cancel <> too
        call    DoHelp
        jr      nc, ostin_4
        call    CancelOZcmd
        jr      z, ostin_8
.ostin_4
        ld      hl, 0
        ld      (pAppStackPtr), hl
.ostin_5
        jr      nc, ostin_9
        jr      nz, ostin_2
        ld      a, RC_Susp                      ; Suspicion of pre-emption
        scf
        jr      ostin_2
.ostin_6
        ld      bc, (uwOSTinTimeout)
        call    RdStdin                         ; get char
        ld      (uwOSTinTimeout), bc
        jr      nc, ostin_7
        cp      RC_Time                         ; Timeout
        scf
        call    nz, CancelOZcmd
        jr      c, ostin_2                      ; !! unconditional jr
.ostin_7
        ld      hl, ostin_tbl                   ; !! compare without table
        ld      bc, 3
        cpir
        jr      z, ostin_3                      ; menu/help/index
.ostin_8
        call    sub_EF92
        jr      c, ostin_5
.ostin_9
        jr      nz, ostin_1
        ld      (cExtendedChar), a
        ld      hl, ubSysFlags1
        set     SF1_B_XTNDCHAR, (hl)
        pop     iy
        push    iy
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1
        xor     a
        jr      ostin_1

.ostin_tbl
        defb    IN_MEN,IN_HLP,IN_IDX

;       ----

.sub_EF64
        ld      e, a
        ld      a, (hl)
        and     SF1_OZDMND|SF1_OZSQUARE
        ld      a, e
        ret     z                               ; neither [] nor <> in OZwd? exit Fc=0
        cp      IN_DIA
        scf
        ret     z                               ; <>? Fc=1
        cp      IN_SQU
        scf
        ret     z                               ; []? Fc=1
        or      a
        ld      bc, (OZcmdBuf)                  ; ld c,(OZcmdBuf)
        inc     c
        dec     c
        ret     nz                              ; no command? Fc=0
        bit     SF1_B_OZDMND, (hl)
        ld      d, QUAL_CTRL                    ; <>
        jr      nz, loc_EF82                    ; <> active? use it as qualifier
        ld      d, QUAL_ALT                     ; []
.loc_EF82
        push    de
        push    hl
        ld      b, -1
        call    ExtQualifiers                   ; Apply qualifiers
        pop     hl
        pop     de
        call    CancelOZcmd
        ret     nc
        ccf
        ld      a, e
        ret

;       ----

.sub_EF92
        ld      hl, ubSysFlags1
        call    sub_EF64
        jp      c, loc_F067
        cp      IN_DIA
        ld      b, SF1_OZDMND
        jr      z, loc_EFEC
        cp      IN_SQU
        ld      b, SF1_OZSQUARE
        jr      z, loc_EFEC
        bit     SF1_B_OZSQUARE, (hl)
        jr      nz, loc_EFC1
        cp      $80
        jr      z, sub_EFBB
        cp      $9F
        jr      z, sub_EFBB
        cp      $81
        jr      c, loc_EFFD
        cp      $9B
        jr      nc, loc_EFFD

;       ----
.sub_EFBB
        ld      hl, ubSysFlags1
        call    CancelOZcmd
.loc_EFC1
        cp      $20
        call    c, CancelOZcmd                  ; ctrl char, cancel OZ command
        jr      c, loc_EFFD                     ; handled
        cp      $A0
        call    nc, CancelOZcmd                 ; ctrl char, cancel OZ command
        jr      nc, sub_EF92                    ; handled
        ld      (hl), SF1_OZSQUARE
        and     $7F
        jr      nz, loc_EFD7                    ; 80->'+'
        ld      a, '+'
.loc_EFD7
        cp      $1F
        jr      nz, loc_EFDD                    ; 9f->'-'
        ld      a, '-'
.loc_EFDD
        call    Char2OZwdChar
        call    PutOZwdBuf
        OZ      DC_Alt                          ; Pass an alternative character
.loc_EFE6
        jp      nc, loc_F067
        jp      CancelOZcmd
.loc_EFEC
        push    bc
        call    CancelOZcmd
        xor     a
        OZ      DC_Alt                          ; Pass an alternative character
        pop     bc
        ld      (hl), b
        xor     a
        call    PutOZwdBuf
        jp      loc_F067
.loc_EFFD
        call    Char2OZwdChar
        bit     SF1_B_OZDMND, (hl)
        jr      nz, loc_F009
        inc     h
        ret     nc
        or      a
        jr      z, loc_F00D
.loc_F009
        or      a
        scf
        jr      z, loc_EFE6
.loc_F00D
        push    bc
        call    FindCmd
        pop     bc
        jp      nc, loc_F05F                    ; match? skip
        xor     a
        ld      hl, ubSysFlags1
        bit     SF1_B_OZDMND, (hl)
        jr      nz, loc_F009
        ld      a, b
        call    CancelOZcmd
        or      a                               ; 00 - ret
        ret     z
        cp      $F0
        jr      c, loc_F029                     ; 01-EF -> cont
.loc_F027
        cp      a
        ret
.loc_F029
        cp      $B0
        ccf
        ret     nc                              ; 01-AF -> ret
        and     $0F
        jr      nz, loc_F035
        ld      a, $20                          ; b0 - 20
        or      a
        ret
.loc_F035
        ld      a, b
        cp      $E0
        jr      c, loc_F027
        and     $0F
        cp      9
        jr      nc, loc_F027                    ; E9-EF
        cp      5
        jr      nc, loc_F067                    ; E5-E8
        ld      c, a
        ld      b, 0
        ld      hl, byte_F06D
        add     hl, bc
        ld      a, (hl)                         ; E0-E4 -> space, enter, tab, del, esc
        call    Char2OZwdChar
        inc     a
        dec     a
        ret     nc
        push    bc
        call    FindCmd
        pop     bc
        jr      nc, loc_F05F
        call    CancelOZcmd
        ld      a, b
        or      a
        ret
.loc_F05F
        jp      z, CancelOZcmd                  ; full match? done, return A
        ld      hl, ubSysFlags1
        ld      (hl), SF1_OZDMND
.loc_F067
        call    c, CancelOZcmd
        xor     a                               ; A=0, Fc=1
        scf
        ret

.byte_F06D
        defb    32,13,9,127,27

;       ----
.Char2OZwdChar
        ld      b, a
        call    IsForeignKey
        ld      a, b                            ; restore original char
        jr      c, c2oz_1                       ; it is a system key, do not translate
        push    hl
        ld      hl, Key2Chr_tbl
        call    Chr2ScreenCode                  ; change foreign key to ISO char
        ld      a, (hl)                         ; character code
        pop     hl
        ld      b, a
        or      a
        ret
.c2oz_1
        cp      IN_ESC                          ; $1B
        jr      nc, c2oz_2
        inc     a
        dec     a
        ret     z                               ; 00    - Fc=1
        add     a, $40
        scf
        ret                                     ; 01-1A - Fc=1, A=41-5A
.c2oz_2
        cp      $20
        ret     c                               ; 1B-1F - Fc=1
        cp      $7F
        ccf
        ret     nc                              ; 20-7E - Fc=0
        ret     z                               ; 7F    - Fc=1
        cp      $A3
        ret     z                               ; A3    - Fc=0
        cp      $A0
        ret     z                               ; A0    - Fc=0
        scf
        ret

;       ----

.CancelOZcmd
        push    af
        push    bc
        push    de
        push    hl
        ld      hl, ubSysFlags1
        bit     SF1_B_OZSQUARE, (hl)
        jr      z, cncoz_1
        xor     a
        OZ      DC_Alt                          ; Pass an alternative character
.cncoz_1
        xor     a
        ld      (hl), a
        ld      (KbdData+kbd_lastkey), a        ; dead key
        ld      (OZcmdBuf), a
        call    DrawOZwd
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

;       ----

.PutOZwdBuf
        ld      b, 5
        ld      hl, OZcmdBuf
.poz_1
        inc     (hl)
        dec     (hl)
        inc     hl
        jr      z, poz_2
        djnz    poz_1
        call    CancelOZcmd
        scf
        ret
.poz_2
        push    af
        ld      (hl), 0
        dec     hl
        call    AtoN_upper
        ld      (hl), a
        call    DrawOZwd
        pop     af
        or      a
        ret


