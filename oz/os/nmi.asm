; **************************************************************************************************
; Non maskable Interrupt Handler, called from 0066H.
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
; (C) Thierry Peycru (pek@users.sf.net), 2006
; (C) Gunther Strube (gbs@users.sf.net), 2006
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
;***************************************************************************************************

        Module NMI

        include "blink.def"
        include "error.def"
        include "sysvar.def"
        include "interrpt.def"
        include "keyboard.def"

        include "lowram.def"
        include "boot.def"


xdef    BothShifts
xdef    OSOff
xdef    SwitchOff
xdef    ResetTimeout
xdef    OSWait
xdef    OSWaitMain
xdef    NMIMain
xdef    nmi_5
xdef    HW_NMI2
xdef    NMIEntry

xref    DrawOZwd                                ; [Kernel0]/ozwindow.asm
xref    OSFramePush                             ; [Kernel0]/misc4.asm
xref    osfpop_1                                ; [Kernel0]/misc4.asm
xref    MayDrawOZwd                             ; [Kernel0]/misc3.asm


defc    NMI_HALT        =1
defc    NMI_B_HALT      =0

; out: Fc=0, A4=shift lock - if only both shifts (and maybe shift lock) down

.BothShifts
        ld      bc, $7f<<8 | BL_KBD             ; row7, kbd port
        in      a, (c)
        rlca                                    ; we rotate shifts to bit0 to use inc near the end
        ld      d, a                            ; SQR ESC IDX LCK  .   /   £  SHR

        ld      b, $bf                          ; row6
        in      a, (c)
        rlca
        rlca
        ld      e, a                            ; TAB DMN MNU  ,   ;   '  HLP SHL

;       check other rows, exit if any key down

.bs_1
        rrc     b                               ; row5-row0
        jr      nc, bs_2                        ; shifted zero out? end of rows
        in      a, (c)                          ; A=$ff if no keys
        inc     a
        ret     nz                              ; other keys down Fc=1 Fz=0
        jr      bs_1

;       check row6 & 7 for keys other than shift/capslock
;       !! check these before trying other rows

.bs_2
        ld      a, e
        cp      $fe                             ; SHL
        ret     c                               ; other keys down, Fc=1 Fz=0

        ld      a, d
        or      $10                             ; LCK
        cp      $fe                             ; SHR
        ret     c                               ; other keys down, Fc=1 Fz=0

;       combine last two rows

        or      e
        inc     a
        ld      a, d                            ; shift lock status
        ret     nz                              ; Fc=0 Fz=0 - both shifts down

        scf
        ret                                     ; Fc=1 Fz=1 - one shift down

;       ----

;       snooze until next TICK (maybe other ints in H) and return keyboard status
;       Fz=1 if no keys

.SnoozeTICK
        ld      l, BM_TACKTICK
        call    DoSnooze
        xor     a                               ; A8-A5=0 - read all rows
        in      a, (BL_KBD)
        inc     a                               ; Fz=1 if no keys down
        ret

;       ----

.NMI_Off0
        ld      h, BM_INTTIME|NMI_HALT

.noff0_1
        call    SnoozeTICK
        jr      nz, noff0_1                     ; keys down? loop

;       ----


.NMI_Off
        ld      hl, [BM_INTTIME|NMI_HALT]<<8|[BM_TACKTICK]

.noff_1
        call    DoSnooze
        ld      h, BM_INTKWAIT|BM_INTKEY|NMI_HALT
        call    DoSnooze                        ; switch off until kbd
        call    BothShifts
        ld      hl, [BM_INTTIME|NMI_HALT]<<8|[BM_TACKSEC]
        jr      c, noff_1                       ; not both shifts? stay off

.noff_2
        ld      h, BM_INTFLAP|BM_INTTIME
        call    SnoozeTICK
        ret     z                               ; no keys? exit
        ld      hl, [BM_INTTIME|NMI_HALT]<<8|[BM_TACKSEC]
        call    BothShifts
        jr      nc, noff_2                      ; both shifts? loop
        jr      z, noff_2                       ; one shift? loop
        jr      NMI_Off0                        ; some other key, wait until released

;       ----

; switch machine off

.OSOff
        ld      a, (ubSoundCount)
        or      a
        ld      a, RC_Fail
        scf
        ret     nz                              ; sound active? don't switch off
        call    SwitchOff
        or      a                               ; Fc=0
        ret

;       ----

.SwitchOff
        push    de
        push    hl
        ld      hl, KbdData+kbd_flags
        res     KBF_B_LOCKED, (hl)
        ld      a, (hl)
        push    af
        set     KBF_B_SCAN, (hl)                ; disable kbd reading from interrupt

.swoff_1
        ld      hl, KbdData+kbd_flags
        res     KBF_B_LOCKED, (hl)
        ld      a, (BLSC_COM)                   ; LCD off
        and     ~BM_COMLCDON
        ld      (BLSC_COM), a
        out     (BL_COM), a

        ld      h, BM_INTFLAP|BM_INTTIME|NMI_HALT

.swoff_2
        call    SnoozeTICK
        jr      nz, swoff_2                     ; keys down
        ld      hl, [BM_INTFLAP|BM_INTTIME|NMI_HALT]<<8|[BM_TACKTICK]

.swoff_3
        call    DoSnooze

.swoff_4
        ld      de, [BM_INTKWAIT|BM_INTFLAP|BM_INTKEY|BM_INTTIME|NMI_HALT]<<8|[BM_TACKMIN]
        ld      hl, ubIntStatus
        di
        bit     IST_B_ALARM, (hl)
        jr      z, swoff_5
        ld      hl, ubNextAlmMinutesB
        ld      a, (hl)
        dec     hl
        or      (hl)
        dec     hl
        or      (hl)
        jr      nz, swoff_5                     ; minutes to next alarm
        ld      e, BM_TACKSEC                   ; sec !! reverse check below to  save one ld
        dec     hl
        ld      a, (hl)                         ; !! cp (hl)
        or      a
        jr      nz, swoff_5                     ; seconds to next alarm
        ld      e, BM_TACKMIN

.swoff_5
        ei
        ld      hl, ubIntTaskToDo
        bit     ITSK_B_ALARM, (hl)
        jr      nz, swoff_8
        ex      de, hl
        call    DoSnooze
        ld      hl, ubIntTaskToDo
        bit     ITSK_B_ALARM, (hl)
        jr      nz, swoff_8
        xor     a
        in      a, (BL_KBD)
        inc     a
        jr      z, swoff_4                      ; no keys? check alarms
        ld      hl, [BM_INTFLAP|BM_INTTIME|NMI_HALT]<<8 | BM_TACKSEC
        call    BothShifts
        jr      c, swoff_3

        push    af
        ld      a, (BLSC_COM)                   ; LCD on
        or      BM_COMLCDON
        ld      (BLSC_COM), a
        out     (BL_COM), a
        pop     af

.swoff_6
        bit     4, a
        jr      nz, swoff_7                     ; no caps lock? don't lock

        ld      hl, KbdData+kbd_flags
        set     KBF_B_LOCKED, (hl)
        call    DrawOZwd

.swoff_7
        ld      h, BM_INTA19|BM_INTTIME
        call    SnoozeTICK
        jr      z, swoff_8
        ld      hl, [BM_INTFLAP|BM_INTTIME|NMI_HALT]<<8 | BM_TACKSEC
        call    BothShifts
        jr      nc, swoff_6                     ; both shifts? loop
        jr      z, swoff_7                      ; one shift? loop
        jp      swoff_1

.swoff_8
        ld      hl, KbdData+kbd_flags
        pop     af
        bit     KBF_B_LOCKED, (hl)
        ld      (hl), a
        jr      z, swoff_9
        set     KBF_B_LOCKED, (hl)              ; !! set this in A before store

.swoff_9
        call    ResetTimeout

        ld      hl, ubIntTaskToDo
        res     ITSK_B_SHUTDOWN, (hl)

        ld      a, (BLSC_COM)                   ; LCD on
        or      BM_COMLCDON
        ld      (BLSC_COM), a
        out     (BL_COM), a

        pop     hl
        pop     de
        ret

;       ----

.ResetTimeout
        push    af
        ld      a, (ubTimeout)
        or      a
        jr      z, rt_1
        inc     a
.rt_1
        ld      (ubTimeoutCnt), a
        pop     af
        ret

;       ----

.OSWait
        call    OSFramePush
        call    OSWaitMain
        ld      hl, ubIntTaskToDo              ; ack buffer task
        res     ITSK_B_BUFFER, (hl)
        jp      osfpop_1                        ; pop without error

;       ----

.OSWaitMain
        ld      de, ubIntTaskToDo

;       wait counts get cleared after UART int (unimplemented: spurious ints)

.waitm_1
        ld      hl, ubWaitCount1
        ld      a, (de)
        or      a
        jr      nz, waitm_2                     ; have something to do? return

        dec     (hl)
        jr      nz, waitm_1                     ; count not zero? try again

        inc     (hl)                            ; make it 1
        call    waitm_3                         ; call every time after 256 loops
        jr      waitm_1

.waitm_2
        ex      de, hl
        ld      a, (hl)                         ; ubIntTaskToDo
        ret

.waitm_3
        ld      hl, ubWaitCount2
        dec     (hl)
        jr      z, waitm_5                      ; reached 0? go snooze

        ld      hl, BLSC_INT
        di
        set     BB_INTKWAIT, (hl)
        ld      a, (hl)
        out     (BL_INT), a
        xor     a                               ; read all rows
        bit     BB_INTKEY, (hl)                 ; KBD
        jr      nz, waitm_4
        ld      a, $fb                          ; read only row2

.waitm_4
        in      a, (BL_KBD)                     ; snooze
        res     BB_INTKWAIT, (hl)
        ld      a, (hl)
        out     (BL_INT), a
        ei
        ret

.waitm_5
        ld      hl, (BLSC_COM)                  ; !! just H,(BLSC_INT)
        set     BB_INTKWAIT, h
        res     NMI_B_HALT, h
        ld      a, (BLSC_TMK)                   ; use whatever RTC int we have
        ld      l, a

;       ----


.DoSnooze
        push    hl
        jr      nmi_1

;       from NMIEntry

.NMIMain
        push    hl
        ld      hl, [BM_INTTIME|NMI_HALT]<<8|[BM_TACKTICK]

.nmi_1
        push    af
        call    OZ_DI
        push    af
        push    bc
        push    de
        ex      af, af'
        push    af
        exx
        push    bc
        push    de
        push    hl
        push    ix
        push    iy

        ld      hl, (pNMIStackPtr)              ; remember SP
        push    hl
        ld      (pNMIStackPtr), sp
        ld      hl, 0                           ; if caller stack above $2000 then use $0c33
        add     hl, sp
        ld      a, h
        cp      $20
        jr      c, nmi_2
        ld      sp, NMIStackTop

.nmi_2
        ld      ix, 0                           ; IX=SP
        add     ix, sp
        exx
        ld      a, (BLSC_COM)
        bit     NMI_B_HALT, h
        set     BB_INTGINT, h
        jr      z, nmi_3                        ; bit0 was zero? leave speaker alone
        res     BB_COMSRUN, a                   ; speaker=SBIT
        ld      (BLSC_COM), a

.nmi_3
        res     BB_COMVPPON, a                  ; VPP off
        out     (BL_COM), a
        call    setComaInts                     ; patch INT 38H and NMI 66H vectors in LOWRAM to HW_INT and HW_NMI

        ld      bc, (ubTimecounterSoft-1)       ; ld b,(ubTimecounterSoft)
        ld      de, (uwTimecounter)
        ld      c, 0
        jp      nz, nmi2_2                      ; NMI_B_HALT set? halt

        ld      a, h
        out     (BL_INT), a
        ld      a, l
        out     (BL_TMK), a

        ld      a, OZBANK_KNL0
        out     (BL_SR0), a                     ; KERNEL0 in 2000 - 3FFF (upper 8K of S0)!
        out     (BL_SR1), a
        out     (BL_SR2), a
        out     (BL_SR3), a

        bit     BB_INTKEY, h
        jr      nz, nmi_4                       ; kbd enabled? wake up on any key
        ld      a, $fb                          ; wake up on row2?
.nmi_4
        in      a, (BL_KBD)                     ; snooze or coma
        or      a                               ; Fc=0

;       entry point from wakeup int - Fc=1

.nmi_5
        di
        ld      a, BM_COMRAMS|BM_COMLCDON
        out     (BL_COM), a                     ; LCD on, RAM at $0000
        call    setAwakeInts                    ; restore INT 38H and NMI 66H vectors in LOWRAM to LOWRAM_INT and LOWRAM_NMI

        ld      (uwTimecounter), de             ; store BDE into time counter
        ld      a, b
        ld      (ubTimecounterSoft), a
        jr      nc, nmi_6                       ; not wakeup from coma? skip

;       allow BATLOW re-read

        ld      hl, ubIntStatus                 ; interrupt status
        res     IST_B_BATLOW, (hl)
        dec     hl                              ; interrupt to_do
        set     ITSK_B_PREEMPTION, (hl)
        set     ITSK_B_OZWINDOW, (hl)           ; update OZ window

        ld      a, BM_INTBTL                    ; ack BAT LOW
        out     (BL_ACK), a
        ld      hl, BLSC_INT                    ; and enable it
        set     BB_INTBTL, (hl)

.nmi_6
        inc     c
        dec     c
        call    nz, NMI_Off                     ; C<>0, switch off

        ld      bc, BLSC_PAGE << 8 | BL_SR3     ; bind S1-S3 after softcopies
.nmi_7
        ld      a, (bc)
        out     (c), a
        dec     c
        ld      a, c
        cp      BL_SR0
        jr      nc, nmi_7                       ; loop until done

        ld      a, (BLSC_COM)                   ; restore COM
        out     (BL_COM), a
        ld      a, (BLSC_INT)                   ; restore INT
        out     (BL_INT), a
        ld      a, (BLSC_TMK)                   ; restore TMK
        out     (BL_TMK), a

        ld      sp, (pNMIStackPtr)              ; restore SP
        pop     hl
        ld      (pNMIStackPtr), hl

        call    MayDrawOZwd
        pop     iy
        pop     ix
        pop     hl
        pop     de
        pop     bc
        exx
        pop     af
        ex      af, af'
        pop     de
        pop     bc
        pop     af
        ld      i, a
        jp      c, nmi_8                        ; int count not zero, ret without EI
        pop     af
        pop     hl
        ei
        ret

.nmi_8
        pop     af
        pop     hl
        ret

;       from snooze/coma NMI stub - no stack

.HW_NMI2
        ld      sp, nmi2_1                      ; return to nmi2_1 thru ROM stack
        ld      a, b
        call    UpdSoftClock
        defw    nmi2_1
.nmi2_1
        ex      de, hl
        ld      b, a
        ld      sp, ix
        ld      h, BM_INTKWAIT|BM_INTKEY|BM_INTGINT
        jr      nc, nmi2_2
        ld      c, 0
        ld      hl, [BM_INTTIME|BM_INTGINT]<<8|[BM_TACKTICK]

.nmi2_2
        ld      a, BM_COMRAMS
        out     (BL_COM), a                     ; reset command register (but keep bank $20 in lower 8K)

        ld      a, $3F
        ld      i, a
        jp      Halt

;       ----

;       Entry point of NMI (executed from LOWRAM RST 66H)
.NMIEntry
        push    bc
        push    de
        push    hl
        ld      a, (ubTimecounterSoft)
        ld      de, (uwTimecounter)
        call    UpdSoftClock
        ld      (uwTimecounter), hl             ; update
        ld      (ubTimecounterSoft), a
        call    c, NMIMain
        call    nc, NMI_Off0
        pop     hl
        pop     de
        pop     bc
        ret

;       ----

.UpdSoftClock
        ld      c, BL_TIM1
        in      l, (c)                          ; seconds
        inc     c
        in      h, (c)                          ; minutes
        or      a
        sbc     hl, de
        jr      z, updsc_1
        ld      a, -1
.updsc_1
        inc     a
        add     hl, de
        cp      3                               ; wrap soft tcnt if necessary
        ret     c
        xor     a
        ret

; Patch LOWRAM INT (0038H) and NMI (0066H) vectors in LOWRAM with subroutines to be used during coma state...
.setComaInts
        push    hl
        ld      hl,HW_INT
        ld      ($0038+1),hl
        ld      hl,HW_NMI
        ld      ($0066+1),hl
        pop     hl
        ret

; Patch (restore) LOWRAM INT (0038H) and NMI (0066H) vectors in LOWRAM with subroutines to be used during awake state...
.setAwakeInts
        push    hl
        ld      hl,LOWRAM_INT
        ld      ($0038+1),hl
        ld      hl,LOWRAM_NMI
        ld      ($0066+1),hl
        pop     hl
        ret
