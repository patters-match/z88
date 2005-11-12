; -----------------------------------------------------------------------------
; $Id$
; -----------------------------------------------------------------------------

        Module Alarm2

        include "alarm.def"
        include "sysvar.def"

xdef    DoAlarms

xref    OSOff

.DoAlarms
        ld      hl, ubIntTaskToDo
        bit     ITSK_B_SHUTDOWN, (hl)           ; process shutdown request
        call    nz, OSOff
        bit     ITSK_B_ALARM, (hl)
        ret     z                               ; no alarm? exit

        push    af
        ex      af, af'
        push    af
        exx
        push    bc
        push    de
        push    hl
        exx
        push    ix

        ld      ix, (pFirstAlarm)
        ld      a, (ix+ahnd_Func+2)
        ld      e, (ix+ahnd_Func)
        ld      d, (ix+ahnd_Func+1)
        push    de
        pop     ix
        or      a
        jr      nz,no_alm
        OZ      GN_Alp                          ; process an expired alarm
.no_alm
        pop     ix
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        pop     af
        ex      af, af'
        pop     af
        ret
        