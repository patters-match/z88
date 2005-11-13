; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d83e
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSAlm

        include "error.def"
        include "misc.def"
        include "time.def"
        include "sysvar.def"


xdef    OSAlmMain

xref    AllocHandle                             ; bank0/handle.asm
xref    FreeHandle                              ; bank0/handle.asm
xref    CopyMemHL_DE                            ; bank0/misc5.asm
xref    GetOSFrame_HL                           ; bank0/misc5.asm
xref    DecActiveAlm                            ; bank0/int.asm
xref    IncActiveAlm                            ; bank0/int.asm
xref    MaySetPendingAlmTask                    ; bank0/int.asm

;       ----

;       alarm manipulation
;
;IN:    A=reason
;               AH_SUSP ($01), suspend alarm
;               AH_REV ($02), revive alarms
;               AH_RES ($03), reset alarm enable state
;               AH_SINC ($04), display symbol
;               AH_SDEC ($05), remove symbol (subject to use count)
;               AH_SRES ($06), reset symbol
;               AH_SET ($07), Set a new alarm
;                       BDE = routine address to be called on expiry !! needs more documentation
;                       HL = 6 byte date, time
;               AH_CNC ($08), Cancel an alarm:
;                       IX = alarm handle
;               AH_DG1 ($09), Ding-dong type 1
;               AH_DG2 ($0A), Ding-dong type 2
;               AH_AINC ($0B), action count increment
;               AH_ADEC ($0C), action count decrement
;               AH_ARES ($0D), action count reset
;
;OUT:   Fc=0 if ok                      SUSP-SRES, DG1-ARES always return this
;       Fc=1, A=error if fail
;       AH_SET returns Fc=1, A=0 in case new alarm went active immediately
;chg:   AF....../....
;
;       !! some simple calls end with 'or a' to clear Fc, others don't
;       !! better to do that in beginning to assert Fc=0

.OSAlmMain
        ld      hl, ubAlmDisableCnt
        djnz    osalm_rev
        inc     (hl)                            ; suspend alarms
        jp      osalm_3

.osalm_rev
        djnz    osalm_res
        dec     (hl)                            ; revive alarms
        jr      osalm_3                         ; !! jp directly

.osalm_res
        djnz    osalm_sinc
        ld      (hl), 0                         ; reset alarm enable state !! ld (hl), b
.osalm_3
        jp      MaySetPendingAlmTask

.osalm_sinc
        inc     hl                              ; ubAlmDisplayCnt
        djnz    osalm_sdec
        inc     (hl)                            ; display symbol
        ret

.osalm_sdec
        djnz    osalm_sres
        dec     (hl)                            ; remove symbol (subject to use count)
        ret

.osalm_sres     djnz    osalm_set
        ld      (hl), 0                         ; reset symbol !! ld (hl), b
        ret

.osalm_set
        djnz    osalm_cnc
        ld      b, a                            ; set a new alarm
        ld      a, HND_ALRM
        call    AllocHandle
        jp      c, osalm_x
        ld      (ix+ahnd_Func), e
        ld      (ix+ahnd_Func+1), d
        ld      (ix+ahnd_Func+2), b
        ld      c, 6                            ; copy date/time into handle
        push    ix
        ld      de, ahnd_Date
        add     ix, de
        push    ix
        pop     de
        pop     ix
        call    GetOSFrame_HL
        call    CopyMemHL_DE
        call    AddAlarm
        jp      SetNextAlmTime

.osalm_cnc
        djnz    osalm_dg1
        push    ix                              ; cancel an alarm
        pop     de
        ld      c, (ix+ahnd_NextAlarmL)         ; BC=next from this
        ld      b, (ix+ahnd_NextAlarmH)
        push    de
        ld      hl, pFirstAlarm-ahnd_NextAlarmL

.osalm_9
        push    hl
        pop     ix
        ld      l, (ix+ahnd_NextAlarmL)
        ld      h, (ix+ahnd_NextAlarmH)
        ld      a, h
        or      l
        jr      z, osalm_10                     ; if not found then we got bad handle
        sbc     hl, de
        add     hl, de
        jr      nz, osalm_9                     ; not same? try next
        ld      (ix+ahnd_NextAlarmL), c         ; remove IX from list
        ld      (ix+ahnd_NextAlarmH), b
        push    de
        pop     ix
        bit     ALMF_B_ACTIVE, (ix+ahnd_Flags)
        call    nz, DecActiveAlm                ; decrement active count and remove pending alarm task if needed
        call    SetNextAlmTime
        pop     de
        ld      a, HND_ALRM
        jp      FreeHandle

.osalm_10
        pop     ix
        ld      (iy+OSFrame_A), RC_Hand         ; !! use osalm_x
        res     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=0
        ret

.osalm_dg1
        djnz    osalm_dg2
        ld      a, 7                            ; ding-dong type 1
        ld      bc, 25<<8|75
        OZ      OS_Blp
        ret

.osalm_dg2
        djnz    osalm_ainc
        ld      a, 12                          ; ding-dong type 2
        ld      bc, 8<<8|25
        OZ      OS_Blp
        ret

.osalm_ainc
        ld      hl, ubAlmActionCnt
        djnz    osalm_adec
        inc     (hl)                            ; action count increment
        or      a
        ret

.osalm_adec
        djnz    osalm_ares
        or      a                               ; action count decrement
        dec     (hl)
        ret     nz                              ; !! call z, ...
        call    SetNextAlmTime
        or      a
        ret

.osalm_ares     djnz    osalm_err
        ld      (hl), 0                         ; action count reset !! ld (hl), b
        or      a
        ret

.osalm_err
        ld      a, RC_Unk

.osalm_x
        ld      (iy+OSFrame_A), a
        res     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=0
        ret

;       ----

; insert alarm IX into queue

.AddAlarm
        ld      hl, (pFirstAlarm)
        ld      a, h
        or      l
        jr      nz, ins_1
        ld      (pFirstAlarm), ix
        ret

.ins_1
        ld      hl, pFirstAlarm-ahnd_NextAlarmL

.ins_2
        push    hl
        call    AddHL_4
        ld      c, (hl)                         ; next alarm into BC
        inc     hl
        ld      b, (hl)
        ld      a, b
        or      c
        jr      z, ins_7                        ; end of list
        push    bc
        ld      hl, ahnd_TimeH
        push    hl
        push    ix
        pop     de
        add     hl, de
        ex      de, hl                          ; IX datetime
        pop     hl
        add     hl, bc                          ; BC datetime
        ld      b, 6                            ; compare 6 bytes

.ins_3
        ld      a, (de)
        cp      (hl)

;       !! reorder compares - 'jr c,...; jr nz,...' does the same

        jr      z, ins_4                        ; same, compare next
        jr      c, ins_6                        ; add between HL and BC
        jr      nc, ins_5                       ; try next alarm !! unconditional jr

.ins_4
        dec     de
        dec     hl
        djnz    ins_3

.ins_5
        pop     hl
        pop     bc
        jr      ins_2

.ins_6
        pop     bc

.ins_7
        pop     hl                              ; insert IX after this alarm
        call    AddHL_4
        ld      e, (hl)                         ; DE=next alarm
        inc     hl
        ld      d, (hl)
        dec     hl
        ld      (ix+ahnd_NextAlarmL), e         ; link DE after IX
        ld      (ix+ahnd_NextAlarmH), d
        push    ix                              ; link IX after HL
        pop     de
        ld      (hl), e
        inc     hl
        ld      (hl), d
        ret

;       ----

;       scan alarm list and mark elapsed alarms active,
;       calculate next alarm time from first non-active, non-elapsed alarm

.SetNextAlmTime
        ld      hl, ubIntStatus
        res     IST_B_ALARM, (hl)
        push    ix
        ld      ix, pFirstAlarm-ahnd_NextAlarmL

.st_1
        ld      l, (ix+ahnd_NextAlarmL)         ; IX=nextalm(IX)
        ld      h, (ix+ahnd_NextAlarmH)
        ld      a, h                            ; exit if end of list
        or      l
        scf                                     ; return Fc=1, A=0 from OS_ALM/set
        jr      z, st_5                         ; if alarm is active immediately
        push    hl
        pop     ix
        bit     ALMF_B_ACTIVE, (ix+ahnd_Flags)
        jr      nz, st_1                        ; active? skip
        ld      hl, ubIntStatus

.st_2
        res     IST_B_ALMTIMEOK, (hl)           ; no time set yet
        ei

.st_3
        ld      b, (ix+ahnd_TimeH)
        ld      c, (ix+ahnd_DateH)
        ld      d, (ix+ahnd_DateM)
        ld      e, (ix+ahnd_Date)
        ld      h, (ix+ahnd_TimeM)
        ld      l, (ix+ahnd_Time)
        xor     a
        OZ      GN_Msc                          ; convert source to time to elapse
        ex      de, hl
        ld      hl, ubIntStatus
        di
        jr      nc, st_4                        ; not elapsed
        set     ALMF_B_ACTIVE, (ix+ahnd_Flags)
        call    IncActiveAlm                    ; increment active count, set pending alarm task
        jr      st_1

.st_4
        bit     IST_B_ALMTIMEOK, (hl)
        jr      nz, st_2                        ; time set alredy? next
        ld      (pNextAlmHandle), ix            ; calculate time till next alarm
        push    hl
        xor     a
        ld      h, a
        ld      l, a
        sbc     hl, de
        ld      (uwNextAlmMinutes), hl
        sbc     a, b
        ld      (ubNextAlmMinutesB), a
        pop     hl
        ld      a, c
        neg
        ld      (ubNextAlmSeconds), a
        set     IST_B_ALARM, (hl)

.st_5
        pop     ix
        ret

;       ----

;       bump HL to ahnd_NextAlarmL              !! make this inline

.AddHL_4
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ret
