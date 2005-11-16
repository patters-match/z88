; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $18d0
;
; $Id$
; -----------------------------------------------------------------------------

        Module Int

        include "blink.def"
        include "serintfc.def"
        include "sysvar.def"
        include "bank7\lowram.def"

xdef    INTEntry
xdef    IntSecond
xdef    IncActiveAlm
xdef    DecActiveAlm
xdef    MaySetPendingAlmTask

xref    ResetTimeout                            ; bank0/nmi.asm
xref    BothShifts                              ; bank0/nmi.asm
xref    ExtKbMain                               ; bank0/kbd.asm
xref    IntUART                                 ; bank0/ossi.asm
xref    IntFlap                                 ; bank0/cardmgr.asm
xref    MS2BankA                                ; bank0/misc5.asm
xref    ReadRTC                                 ; bank0/time.asm


;IN:    A= interrupt status

.INTEntry
        push    bc
        push    de
        push    hl
        push    ix
        ex      af, af'
        push    af

        ld      hl, 0                           ; stack above $2000? use system stack
        add     hl, sp
        ld      a, h
        cp      $20
        jr      c, int_1
        ld      sp, ($1FFE)                     ; read new SP
.int_1
        push    hl                              ; remember original SP

        ex      af, af'                         ; int status
        ld      hl, BLSC_INT                    ; mask out disabled ones
        and     (hl)
        bit     BB_INTUART, a                   ; UART
        jp      nz, int_uart
        rra
        jp      nc, int_6                       ; BB_INTGINT=0? skip

        bit     BB_INTTIME, (hl)
        jp      z, int_6                        ; RTC disabled? skip

        ld      l, BL_TSTA                      ; point softcopy to RTC enable
        in      a, (BL_TSTA)                    ; RTC int status
        and     (hl)                            ; mask out disabled ones

        ld      hl, ubIntTaskToDo
        bit     BB_TACKTICK, a
        jr      z, int_RTCS                     ; no TICK? skip

;       TICK handles beeper, updates smaal timer and does keyboard scan

        ld      a, BM_TACKTICK
        out     (BL_TACK), a                    ; ack TICK
        bit     ITSK_B_PREEMPTION, (hl)
        call    z, IntBeeper

        ld      de, (uwSmallTimer)
        ld      a, d
        and     e
        inc     a
        jr      z, int_2                        ; timer=-1, skip
        ld      a, d
        or      e
        jr      z, int_2                        ; timer=0, skip
        call    ResetTimeout
        dec     de
        ld      (uwSmallTimer), de
        ld      a, d                            ; if timer=0 set pending SMT
        or      e
        jr      nz, int_2
        set     ITSK_B_TIMER, (hl)

.int_2
        ld      ix, KbdData
        bit     KBF_B_SCAN, (ix+kbd_flags)
        jr      nz, int_5                       ; scan active? exit int

        bit     KBF_B_LOCKED, (ix+kbd_flags)
        jr      z, int_3

;       if lockout we just check for both shifts

        xor     a
        ld      (ix+kbd_keyflags), a            ; cancel current
        ld      (ix+kbd_prevflags), a           ; and prev
        in      a, (BL_KBD)                     ; check if any key pressed
        inc     a
        jr      z, int_5                        ; no keys? exit
        call    BothShifts
        jr      c, int_5                        ; no shifts? exit
        res     KBF_B_LOCKED, (ix+kbd_flags)    ; remove flag before switching off
        jr      int_5                           ; exit interrupt

;       keyboard scan is done with interrupts enabled - be nice to UART

.int_3
        set     KBF_B_SCAN, (ix+kbd_flags)
        ei
        xor     a                               ; read all columns
        in      a, (BL_KBD)
        inc     a
        call    nz, ResetTimeout                ; key pressed? reset timeout
        jr      nz, int_4                       ; key pressed? force keyboard scan

        ld      a, (ix+kbd_flags)               ; check if we have active keys
        and     KBF_DMND|KBF_KEY|KBF_SQR
        or      (ix+kbd_keyflags)               ; current
        or      (ix+kbd_prevflags)              ; prev
.int_4
        call    nz, ExtKbMain
        di
        res     KBF_B_SCAN, (ix+kbd_flags)
.int_5
        jp      int_x


.int_RTCS
        bit     BB_TACKSEC, a
        jr      z, int_RTCM                     ; no SEC? skip

;       SEC just calls IntSecond

        ld      a, BM_TACKSEC                   ; ack SEC
        out     (BL_TACK), a
        call    IntSecond
        jp      int_x

.int_RTCM
        bit     BB_TACKMIN, a
        jr      z, int_x

;       MIN calls IntMinute and does timeout


        ld      a, BM_TACKMIN                   ; ack MIN
        out     (BL_TACK), a
        call    IntMinute

        ld      hl, ubIntTaskToDo
        bit     ITSK_B_SHUTDOWN, (hl)
        jr      nz, int_x                       ; already shutting down? exit

        ld      hl, ubTimeoutCnt
        dec     (hl)
        jp      m, int_RTCM1                    ; negative? restore - no timeout
        jr      nz, int_x

        ld      hl, ubIntTaskToDo               ; request shutdown
        set     ITSK_B_SHUTDOWN, (hl)
        jr      int_x
.int_RTCM1
        inc     (hl)
        jp      int_x

;       no ints outside blink or RTC disabled

.int_6
        rra
        rra                                     ; column gone low
        jr      nc, int_7
        ld      a, BM_ACKKEY
        out     (BL_ACK), a                     ; ack keyboard and exit
        jp      int_x

.int_7
        rra                                     ; bat low
        jr      nc, int_8

        res     BB_INTBTL, (hl)                 ; disable int
        ld      a, (hl)
        out     (BL_INT), a                     ; really
        ld      a, BM_ACKBTL
        out     (BL_ACK), a                     ; ack BATLOW
        ld      hl, ubIntStatus
        set     IST_B_BATLOW, (hl)
        dec     hl                              ; request OZ window update
        set     ITSK_B_OZWINDOW, (hl)
        jp      int_x

.int_8
        rra                                     ; always handle UART ints
        jr      nc, int_9

.int_uart
        ld      l, SI_INT
        call    IntUART
        jp      int_12

.int_9
        rra                                     ; flap
        jr      nc, int_10
        call    IntFlap
        jp      int_x

.int_10
        rra                                     ; A19
        jr      nc, int_x
        ld      a, BM_ACKA19
        out     (BL_ACK), a                     ; (w) main int. mask
        jp      int_x

;       uart exits thru this

.int_12
        ld      hl, 0
        ld      (ubWaitCount1), hl              ; ubWaitCount1, ubWaitCount1
        call    ResetTimeout

.int_x
        pop     hl
        ld      sp, hl
        pop     af
        ex      af, af'
        pop     ix
        pop     hl
        pop     de
        pop     bc
        jp      INTReturn

;       ----

.IntBeeper
        ld      ix, KbdData
        ld      hl, ubSoundCount                ; beep active
        ld      a, (hl)
        or      a
        jr      nz, intb_beep1
        bit     KBF_B_BEEP, (ix+kbd_flags)      ; keyclick pending?
        jr      nz, intb_kclick
        ld      hl, BLSC_COM                    ; silence beeper if not already
        bit     BB_COMSRUN, (hl)
        ret     z
        res     BB_COMSRUN, (hl)
        jr      intb_out

.intb_kclick
        res     KBF_B_BEEP, (ix+kbd_flags)
        jr      intb_on                         ; do keyclick

.intb_beep1
        rr      a
        push    hl
        call    intb_beep4
        pop     hl
        dec     hl                              ; ubSoundActive
        dec     (hl)
        ret     nz

.intb_beep2
        or      a
        ld      hl, ubSoundCount
        dec     (hl)
        jr      z, intb_beep4
        bit     0, (hl)                         ; even=space, odd=mark
        inc     hl                              ; space count
        jr      z, intb_beep3
        inc     hl                              ; mark count
        scf

.intb_beep3
        ld      a, (hl)
        ld      (ubSoundActive), a
        inc     a
        dec     a
        jr      z, intb_beep2                   ; zero count? ignore it

.intb_beep4
        ld      hl, BLSC_COM
        res     BB_COMSRUN, (hl)                ; speaker source SBIT
        jr      nc, intb_out
        ld      a, (cSound)
        cp      'Y'
        jr      nz, intb_out

.intb_on
        ld      hl, BLSC_COM
        set     BB_COMSRUN, (hl)                ; speaker source 3K2

.intb_out
        ld      a, (hl)
        out     (BL_COM), a                     ; (w) command register
        ret

;       ----

.IntMinute
        call    ReadHWClock
        ret     z                               ; no alarms? exit

        ld      hl, uwNextAlmMinutes+2
        ld      a, (hl)
        dec     hl
        or      (hl)
        dec     hl
        or      (hl)
        ret     z                               ; no next alarm

        inc     (hl)                            ; otherwise 24bit increment
        ret     nz
        inc     hl
        inc     (hl)
        ret     nz
        inc     hl
        inc     (hl)
        ret     nz

        ld      a, (ubNextAlmSeconds)
        or      a
        ret     nz

        ld      hl, ubIntStatus
        jr      intsec_1

;       ----

.IntSecond
        call    ReadHWClock
        ret     z                               ; no alarms? exit

        ld      ix, ubNextAlmSeconds            ; !! use HL instead, load it again at intsec_1
        ld      a, (ix+1)                       ; uwNextAlmMinutes+ubNextAlmMinutesB
        or      (ix+2)
        or      (ix+3)
        ret     nz                              ; still minutes to go

        ld      a, (ix+0)                       ; ubNextAlmSeconds
        or      a
        jr      z, intsec_1                     ; do alarm if 0 or -1 seconds left
        inc     (ix+0)
        ret     nz

.intsec_1
        res     IST_B_ALARM, (hl)
        ld      ix, (pNextAlmHandle)
        set     ALMF_B_ACTIVE, (ix+ahnd_Flags)

.IncActiveAlm
        ld      hl, ubNumActiveAlm
        inc     (hl)
        jr      MaySetPendingAlmTask

.DecActiveAlm
        ld      hl, ubNumActiveAlm
        dec     (hl)

.MaySetPendingAlmTask
        ld      hl, ubIntTaskToDo
        ld      a, (ubAlmDisableCnt)
        or      a
        jr      nz, intsec_cncalm               ; disabled? remove alarm task

        ld      a, (ubNumActiveAlm)
        or      a
        jr      z, intsec_cncalm                ; none active? remove alarm task

        bit     ITSK_B_PREEMPTION, (hl)
        jr      z, intsec_setalm                ; no wake up? skip

        ex      de, hl                          ; else lockout
        ld      hl, KbdData+kbd_flags
        set     KBF_B_LOCKED, (hl)
        ex      de, hl

.intsec_setalm
        set     ITSK_B_ALARM, (hl)
        ret

.intsec_cncalm
        res     ITSK_B_ALARM, (hl)
        ret

.ReadHWClock
        ld      hl, ubTimeBufferSelect          ; read hardware clock to either buffer A or B
        ld      a, (ubTIM0_A)                   ; bit 0 selects buffer
        rrca
        jr      c, rhwc_1
        ld      l, ubTIM0_B&255                 ; 80a6

.rhwc_1
        call    ReadRTC
        ld      hl, ubTimeBufferSelect
        inc     (hl)                            ; switch memory to read
        ld      hl, ubIntStatus
        set     IST_B_ALMTIMEOK, (hl)
        bit     IST_B_ALARM, (hl)               ; return alarms status
        ret

