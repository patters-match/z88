; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $e4da
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNAlarm

        org $e4da                               ; 871 bytes

	include "alarm.def"
	include "ctrlchar.def"
	include "director.def"
	include "error.def"
	include "memory.def"
	include "syspar.def"
	include "time.def"
        include "sysvar.def"

;       ----

xdef    GNAab
xdef    GNAlp
xdef    GNFab
xdef    GNLab
xdef    GNUab

;       ----

xref    GetOsf_BHL
xref    NormalizeCDEcsec
xref    PutOsf_BHL
xref    PutOsf_Err

;       ----

;       allocate alarm block
;
;IN:    -
;OUT:   BHL=alarm
;       Fc=1, A=error
;
;CHG:   AFB...HL/....
;
;       !! could clear it for caller

.GNAab
        push    ix
        ld      bc, NQ_Dmh                      ; get Index mempool
        OZ      OS_Nq
        xor     a
        ld      bc, alm_SIZEOF
        OZ      OS_Mal                          ; allocate alarm
        jr      nc, aab_1                       ; !! 'call nc, PutOsf_BHL'
        call    PutOsf_Err                      ; !! 'call c, PutOf_Err'
        jr      aab_2
.aab_1
        call    PutOsf_BHL                      ; return alarm to caller
.aab_2
        pop     ix
        ret

;       ----

;       free alarm block
;
;IN:    BHL=alarm
;OUT:   -
;       Fc=1, A=error
;
;CHG:   AF....../....

.GNFab
        push    ix
        ld      bc, NQ_Dmh                      ; get index mempool
        OZ      OS_Nq
        call    GetOsf_BHL                      ; get alarm
        ld      a, b                            ; and free it
        ld      bc, alm_SIZEOF
        OZ      OS_Mfr
        call    c, PutOsf_Err
        pop     ix
        ret

;       ----

;       link alarm into alarm list
;
;IN:    BHL=alarm
;OUT:   -
;       Fc=1, A=error
;
;CHG:   AF....../....

.GNLab
        push    ix
        ld      c, 1                            ; bind alarm in S1
        OZ      OS_Mpb
        push    bc
        push    hl
        pop     ix

        ld      hl, -6                          ; reserve six bytes from stack
        add     hl, sp                          ; !! 3*'push hl'
        ld      sp, hl

        ex      de, hl                          ; !! 'ld d,h; ld e,l'
        ld      hl, 0                           ; !! (this is what you get if you
        add     hl, sp                          ; !! don't know numeric values of
        ex      de, hl                          ; !! structure members)

        push    ix
        pop     hl
        ld      bc, alm_Time                    ; !! 3*'inc hl'
        add     hl, bc

;       copy time/date from alarm to stack !! use ldir

        ld      b, 6
.lab_1
        ld      a, (hl)
        ld      (de), a
        inc     hl
        inc     de
        djnz    lab_1

;       find place to insert alarm into

        ld      ix, pAlarmList
        ld      b, 0                            ; #alarms skipped
.lab_2
        push    bc
        call    GetNextAlarm
        jr      c, lab_insert                   ; no more alarms?

        push    ix
        pop     de
        ld      hl, alm_Date+2
        add     hl, de
        ex      de, hl                          ; DE=IX+alm_Date+2

        ld      hl, 7
        add     hl, sp                          ; HL=SP+5+2

        ld      b, 6                            ; compare six bytes
.lab_3
        ld      a, (de)
        cp      (hl)
        jr      c, lab_4                        ; smaller? try next alarm
        jr      nz, lab_insert                  ; larger? found
        dec     de
        dec     hl
        djnz    lab_3

.lab_4
        pop     bc
        inc     b
        jr      lab_2

;       insert after B alarms

.lab_insert
        pop     bc
        jr      c, lab_8                        ; end of list? IX ok

;       skip B alarms from start of list

        ld      ix, pAlarmList
        ld      a, b
        or      a
        jr      z, lab_8                        ; add to beginning of list
.lab_7
        push    bc                              ; find previous alarm
        call    GetNextAlarm
        pop     bc
        djnz    lab_7

;       insert after IX

.lab_8
        push    ix
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc

;       find free AlarmID

        ld      de, (uwNextAlarmID)
.lab_9
        inc     de
        ld      ix, pAlarmList
.lab_10
        call    GetNextAlarm
        jr      c, lab_11                       ; end of list? ok
        ld      a, (ix+alm_ID+1)
        cp      d
        jr      nz, lab_10
        ld      a, (ix+alm_ID)
        cp      e
        jr      z, lab_9                        ; ID used, try next ID
        jr      lab_10                          ; else compare with next alarm
.lab_11
        ld      (uwNextAlarmID), de

        pop     bc                              ; restore S1
        OZ      OS_Mpb
        call    GetOsf_BHL

        ld      c, 1                            ; bind new alarm in S1
        OZ      OS_Mpb
        push    bc

        ld      b, (iy+OSFrame_B)
        push    hl
        pop     ix                              ; BIX=new alarm
        ex      de, hl                          ; store alarm ID
        ld      (ix+alm_ID+1), h
        ld      (ix+alm_ID), l

        push    ix                              ; ex HL, IX
        ex      (sp), hl                        ; HL=alarm, IX=ID
        pop     ix

        push    hl
        ld      de, alm_Time
        add     hl, de
        push    ix                              ; DE=IX=ID
        pop     de
        ld      b, 0                            ; call OS_Alm on expiry
        ld      a, AH_SET
        OZ      Os_Alm
        pop     hl
        jr      z, lab_12                       ; ok? continue

        scf                                     ; already passed
        jr      lab_13

.lab_12
        push    ix                              ; ex HL, IX
        ex      (sp), hl                        ; HL=handle, IX=alarm
        pop     ix

        ld      (ix+alm_Handle+1), h
        ld      (ix+alm_Handle), l
        set     ALMF_B_ADDED, (ix+alm_Flags)

.lab_13
        pop     bc                              ; restore S1
        push    af
        OZ      OS_Mpb
        pop     af

        pop     ix                              ; previous alarm
        jr      c, lab_14                       ; no error? link alarms
        call    GetOsf_BHL
        ld      e, (ix+alm_Next)                ; CDE=prev.next
        ld      d, (ix+alm_Next+1)
        ld      c, (ix+alm_Next+2)
        ld      (ix+alm_Next), l                ; prev.next=new
        ld      (ix+alm_Next+1), h
        ld      (ix+alm_Next+2), b

        push    bc                              ; bind new alarm in
        ld      c, 1
        OZ      OS_Mpb
        pop     bc

        push    hl
        pop     ix
        ld      (ix+alm_Next), e                ; new.next=CDE
        ld      (ix+alm_Next+1), d
        ld      (ix+alm_Next+2), c

.lab_14
        ex      af, af'                         ; remember Fc
        ld      hl, 6                           ; restore stack
        add     hl, sp                          ; !! 3*'pop hl'
        ld      sp, hl
        ex      af, af'

        pop     bc                              ; restore S1
        push    af
        OZ      OS_Mpb

        pop     af
        pop     ix
        call    c, PutOsf_Err
        ret

;       ----

; IX:alarm=(IX:alarm)

.GetNextAlarm
        ld      a, (ix+alm_Next)                ; BHL=next alarm
        ld      h, (ix+alm_Next+1)
        ld      b, (ix+alm_Next+2)
        ld      l, a
        or      h
        or      b
        scf
        ret     z                               ; BHL=0? Fc=1

        push    hl
        pop     ix
        ld      c, 1                            ; bind alarm in S1
        push    bc
        OZ      OS_Mpb
        pop     bc
        or      a                               ; Fc=0 !! unnecessary
        ret


;       ----

;       !! unused or called from OS_Alm? ($e62a)

        OZ      GN_Alp                          ; Process an expired alarm
        ret

;       ----

;       unlink alarm from alarm list
;
;IN:    BHL=alarm
;OUT:   Fz=1, alarm removed
;       Fc=1, A=error
;
;CHG:   AF....../....

.GNUab
        push    ix
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc

;       find alarm in list

        ld      ix, pAlarmList                  ; !! what about B?
.uab_1
        ld      c, (ix+alm_Next+2)              ; CDE=next alarm
        ld      d, (ix+alm_Next+1)
        ld      e, (ix+alm_Next)
        ld      a, c
        or      e
        or      d
        jr      nz, uab_2
        ld      (iy+OSFrame_A), RC_Bad          ; end of list, error
        set     Z80F_B_C, (iy+OSFrame_F)
        jp      uab_x
.uab_2
        ld      a, b                            ; compare with prev
        cp      c
        jr      nz, uab_3
        ld      a, h
        cp      d
        jr      nz, uab_3
        ld      a, l
        cp      e
        jr      z, uab_4                        ; found
.uab_3
        push    bc
        ld      b, c
        push    de                              ; IX=current
        pop     ix
        ld      c, 1                            ; bind it in
        OZ      OS_Mpb
        pop     bc
        jr      uab_1

.uab_4
        ld      b, c
        ld      c, 2
        OZ      OS_Mpb                          ; bind alarm in S2
        push    bc

        ld      a, d                            ; S2 fix
        and     $3F                             ; !! 'set 7,d; res 6,d'
        or      $80
        ld      d, a

        push    ix
        push    de
        pop     ix                              ; IX=alarm
        ld      a, (ix+alm_Flags)
        and     ALMF_SHOWBELL|ALMF_ADDED
        cp      ALMF_SHOWBELL|ALMF_ADDED
        pop     ix
        jr      z, uab_5

        ld      a, (de)                         ; unlink DE
        ld      (ix+alm_Next), a
        inc     de
        ld      a, (de)
        ld      (ix+alm_Next+1), a
        inc     de
        ld      a, (de)
        ld      (ix+alm_Next+2), a
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1
        dec     de
        dec     de

.uab_5
        push    ix
        push    de                              ; IX=alarm
        pop     ix

        bit     ALMF_B_SHOWBELL, (ix+alm_Flags) ; bell shown?
        res     ALMF_B_SHOWBELL, (ix+alm_Flags)
        ld      d, (ix+alm_Handle+1)
        ld      e, (ix+alm_Handle)
        jr      z, uab_6                        ; nope, skip

        push    de                              ; !! unnecessary as
        pop     ix                              ; !! SDEC doesn't use handle
        ld      a, AH_SDEC                      ; decrement bell count
        OZ      Os_Alm
        jr      uab_7

.uab_6
        bit     ALMF_B_ADDED, (ix+alm_Flags)
        res     ALMF_B_ADDED, (ix+alm_Flags)
        jr      z, uab_7
        push    de
        pop     ix
        ld      a, AH_CNC                       ; cancel alarm
        OZ      Os_Alm

.uab_7
        pop     ix
        pop     bc                              ; restore S2
        OZ      OS_Mpb
        ld      c, (ix+alm_Next+2)              ; !! unnecessary?
        ld      d, (ix+alm_Next+1)
        ld      e, (ix+alm_Next)
.uab_x
        pop     bc                              ; restore S1
        OZ      OS_Mpb
        pop     ix
        ret

;       ----

;       process expired alarm
;
;IN:    IX=alarm ID
;OUT:   -

.GNAlp
        push    ix
        ld      c, 1                            ; remember S1
        OZ      OS_Mgb
        push    bc

;       find alarm in list

        push    ix
        pop     de
        ld      ix, pAlarmList
.alp_1
        call    GetNextAlarm
        jp      c, alp_18

        ld      a, (ix+alm_ID+1)
        cp      d
        jr      nz, alp_1
        ld      a, (ix+alm_ID)
        cp      e
        jr      nz, alp_1                       ; not same, loop

        bit     ALMF_B_SHOWBELL, (ix+alm_Flags) ; increment bell count
        jr      nz, alp_2                       ; if not done already
        ld      a, AH_SINC
        OZ      Os_Alm

.alp_2
        ld      a, (ix+alm_Flags)               ; clear bits 2&3
        and     ~(ALMF_SHOWBELL|ALMF_ADDED)
        ld      (ix+alm_Flags), a

        bit     ALMF_B_BELL, a                  ; select beep if allowed
        jr      z, alp_4
        ld      a, AH_DG1
        bit     ALMF_B_EXECUTE, (ix+alm_Flags)
        jr      z, alp_3
        ld      a, AH_DG2
.alp_3
        OZ      Os_Alm

.alp_4
        ld      d, (ix+alm_Handle+1)            ; cancel alarm
        ld      e, (ix+alm_Handle)
        push    de
        ex      (sp), ix
        ld      a, AH_CNC
        OZ      Os_Alm
        pop     ix

        bit     ALMF_B_EXECUTE, (ix+alm_Flags)
        jr      z, alp_7
        push    ix
        pop     hl
        ld      bc, alm_Reason
        add     hl, bc
        ld      bc, 23<<8|0
        push    hl

;       count command length in C

.alp_5
        ld      a, (hl)
        inc     c
        or      a
        jr      z, alp_6
        inc     hl
        djnz    alp_5
        dec     hl
.alp_6
        ld      (hl), CR                        ; terminate
        ld      b, 0
        pop     hl
        OZ      DC_Icl                          ; and run

.alp_7
        bit     ALRF_B_NEVER, (ix+alm_RepeatFlags)
        jp      nz, alp_18

        ld      b, (ix+alm_RepeatNum+1)
        ld      c, (ix+alm_RepeatNum)
        ld      a, b
        or      c
        jp      z, alp_18                       ; no more

        push    ix
        pop     hl
        ld      c, 1
        OZ      OS_Mgb                          ; remember S1
        OZ      GN_Uab                          ; unlink alarm block

        set     ALMF_B_SHOWBELL, (ix+alm_Flags)

        ld      b, (ix+alm_RepeatNum+1)         ; decrement RepeatNum if not -1
        ld      c, (ix+alm_RepeatNum)
        inc     bc                              ; !! 'ld a,b;and c;inc a; jr z'
        ld      a, b
        or      c
        dec     bc
        jr      z, alp_8
        dec     bc
.alp_8
        ld      (ix+alm_RepeatNum+1), b
        ld      (ix+alm_RepeatNum), c

        ld      a, (ix+alm_RepeatFlags)
        ld      b, (ix+alm_RepeatDays+2)
        ld      h, (ix+alm_RepeatDays+1)
        ld      l, (ix+alm_RepeatDays)
        and     ALRF_YEAR|ALRF_MONTH|ALRF_WEEK|ALRF_DAY
        jr      z, alp_16                       ; adjust time

        and     ALRF_YEAR|ALRF_MONTH
        jr      z, alp_15                       ; no months
        and     ALRF_YEAR
        jr      nz, alp_11

;       calculate years from months

        ld      de, 0                           ; #years
.alp_9
        ld      a, h                            ; if months>11 then add years
        or      a
        jr      nz, alp_10
        ld      a, l
        cp      12
        jr      c, alp_12
.alp_10
        inc     de                              ; years++
        ld      a, l                            ; months -= 12
        sub     12
        ld      l, a
        jr      nc, alp_9
        dec     h
        jr      alp_9

.alp_11
        xor     a
        ex      de, hl

.alp_12
        push    af
        push    de
        ld      a, (ix+alm_Date+2)
        ld      h, (ix+alm_Date+1)
        ld      l, (ix+alm_Date)
        OZ      GN_Die                          ; convert to zoned format
        pop     hl
        ld      a, c                            ; C=day of month
        and     $1F
        ld      c, a
        pop     af
        push    bc                              ; remember DoM
        add     a, b
        cp      13
        jr      c, alp_13
        sub     12
        inc     hl                              ; years++
.alp_13
        ld      b, a

        add     hl, de
        ex      de, hl
        ld      c, 1                            ; 1st of month
        OZ      GN_Dei                          ; convert to internal format
        pop     hl                              ; restore DoM
        jr      c, alp_18                       ; bad date?

        OZ      GN_Die                          ; convert back to zoned format
        ld      c, l                            ; C=min(L,A)
        cp      c
        jr      nc, alp_14
        ld      c, a
.alp_14
        OZ      GN_Dei                          ; convert to internal format
        jr      c, alp_18                       ; bda date?

        ld      l, c                            ;BHL=ABC
        ld      h, b
        ld      b, a
.alp_15
        ld      a, (ix+alm_Date+2)
        ld      d, (ix+alm_Date+1)
        ld      e, (ix+alm_Date)
        add     hl, de
        adc     a, b
        ld      (ix+alm_Date+2), a
        ld      (ix+alm_Date+1), h
        ld      (ix+alm_Date), l
        jr      alp_17

;       no days, adjust time

.alp_16
        ld      b, (ix+alm_RepeatTime+2)
        ld      h, (ix+alm_RepeatTime+1)
        ld      l, (ix+alm_RepeatTime)
        ld      a, (ix+alm_Time+2)
        ld      d, (ix+alm_Time+1)
        ld      e, (ix+alm_Time)
        add     hl, de
        adc     a, b
        ld      c, a
        ex      de, hl
        call    NormalizeCDEcsec
        ld      (ix+alm_Time+2), c
        ld      (ix+alm_Time+1), d
        ld      (ix+alm_Time), e
        ld      b, 0                            ; !! 'ld hl,1; ld b,h'
        ld      hl, 1
        jr      c, alp_15                       ; carry? date++

.alp_17
        ld      c, 1                            ; get alarm bank
        OZ      OS_Mgb
        push    ix
        pop     hl
        OZ      GN_Lab                          ; link alarm block
        jp      c, alp_2                        ; elapsed? loop !! alarm deadlock

.alp_18
        set     ALMF_B_SHOWBELL, (ix+alm_Flags)

        pop     bc                              ; restore S1
        OZ      OS_Mpb
        pop     ix
        ret
