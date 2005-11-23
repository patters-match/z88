; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $045f
;
; $Id$
; -----------------------------------------------------------------------------

        Module Buffer

        include "director.def"
        include "error.def"
        include "sysvar.def"
        include "../bank7/lowram.def"

xdef    BfGbt                                   ; OsTin
xdef    BfPbt
xdef    BfPur
xdef    BfSta
xdef    BufRead
xdef    BufWrite
xdef    BufWriteC                               ; KbdMain
xdef    InitBufKBD_RX_TX                        ; Reset2
xdef    OsDly
xdef    OSPur
xdef    OSXin


xref    CancelOZcmd                             ; bank0/osin.asm
xref    OSWaitMain                              ; bank0/nmi.asm
xref    DoAlarms                                ; bank0/alarm2.asm
xref    TestEsc                                 ; bank0/esc.asm
xref    MayDrawOZwd                             ; bank0/misc3.asm
xref    PutOSFrame_BC                           ; bank0/misc5.asm


;       ----

; delay a given period
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

;       ----

; get buffer status
;
;IN:    IX = buffer
;OUT:   H = number of databytes in buffer
;       L = number of free bytes in buffer
;chg:   ......HL/....

.BfSta
        call    OZ_DI
        call    BfSTAMain
        call    OZ_EI
        or      a
        ret

.BfSTAMain
        push    af
        ld      a, (ix+buf_end)
        sub     (ix+buf_start)
        ld      l, a                            ; bufsize

        ld      a, (ix+buf_wrpos)               ; used=wrpos-rdpos
        sub     (ix+buf_rdpos)
        jr      nc, bfsta_1                     ; handle buffer wrap
        add     a, l

.bfsta_1
        ld      h, a                            ; used bytes
        ld      a, l                            ; free=bufsize-used-1
        sub     h
        dec     a
        ld      l, a
        pop     af
        ret

;       ----

; purge buffer
;
;IN:    IX = buffer
;OUT:   Fc=0
;chg:   F

.BfPur
        call    OZ_DI
        ex      af, af'
        ld      a, (ix+buf_rdpos)
        ld      (ix+buf_wrpos), a
        ex      af, af'
        call    OZ_EI
        or      a
        ret

;       ----

; check if there's data in buffer
;
;IN:    IX = buffer
;       HL = ubIntTaskToDo
;OUT:   Fc=0 if data is ready
;       Fc=1 if buffer is empty or there's pending escape condition
;
;chg:   AF

.Bf_Check
        call    OZ_DI
        ex      af, af'
        bit     ITSK_B_ESC, (hl)                ; Fc=1 if ESC pending
        scf
        jr      nz, bfchk_1
        ld      a, (ix+buf_wrpos)               ; this is *NOT* necessarily #data bytes,
        sub     (ix+buf_rdpos)                  ; buffer wrap isn't handled
        cp      1                               ; Fc=1 if buffer empty
.bfchk_1
        ex      af, af'
        call    OZ_EI
        ex      af, af'
        ret

;       ----

; get byte with timeout
;
;IN:    BC = timeout, $FFFF for default
;       IX = buffer
;OUT:   Fc=0, A=data, BC=remaining time if success
;       Fc=1, A=error if fail
;chg:   AFBC..HL/....

.BfGbt
        call    OZ_DI
        push    af
        ei
        push    de

        ld      de, 0
        ld      hl, ubIntTaskToDo
        ld      (uwSmallTimer), de              ; zero timer, then disable it, then write new value
        res     ITSK_B_TIMER, (hl)
        ld      (uwSmallTimer), bc

        call    Bf_Check
        jr      nc, bfgbt_get                   ; if there's data we can exit right away

        ld      hl, ubIntTaskToDo                 ; !! unnecessary
        bit     ITSK_B_PREEMPTION, (hl)
        jr      nz, bfgbt_susp0                 ; pre-empted? exit
        bit     ITSK_B_ESC, (hl)
        jr      nz, bfgbt_esc                   ; ESC pending? exit

        ld      a, b                            ; wait if timeout not 0
        or      c
        jr      nz, bfgbt_9

.bfgbt_to
        ld      a, RC_Time
.bfgbt_err
        scf
        jr      bfgbt_x

.bfgbt_get
        call    BufRead
        jr      c, bfgbt_9                      ; error, wait for more
        ld      a, c                            ; !! unnecessary

.bfgbt_x
        push    hl                              ; !! unnecessary, HL already lost
        ld      hl, ubIntTaskToDo

        res     ITSK_B_BUFFER, (hl)             ; cancel buffer task
        pop     hl
        pop     de
        ex      af, af'
        pop     af
        call    OZ_EI
        ex      af, af'
        ld      bc, (uwSmallTimer)
        ret

.bfgbt_esc
        ld      a, RC_Esc
        jr      bfgbt_err

.bfgbt_susp0
        res     ITSK_B_PREEMPTION, (hl)         ; cancel buffer task

.bfgbt_susp
        ld      a, RC_Susp
        jr      bfgbt_err

.bfgbt_8
        res     ITSK_B_BUFFER, (hl)             ; if there's data in buffer go and get it
        call    Bf_Check
        jr      nc, bfgbt_get

.bfgbt_9
        call    OSWaitMain                      ; wait for data

        bit     ITSK_B_PREEMPTION, a
        jr      nz, bfgbt_susp0                 ; pre-empted? cancel buffer task and exit
        bit     ITSK_B_ESC, a
        jr      nz, bfgbt_esc                   ; ESC pending? exit
        bit     ITSK_B_BUFFER, a
        jr      nz, bfgbt_8                     ; buffer job?  check for data
        bit     ITSK_B_TIMER, a
        jr      nz, bfgbt_to                    ; timeout? exit
        jr      bfgbt_susp                      ; otherwise exit with pre-emption

;       ----

; Check is buffer has room for one more byte
;
;IN:    IX = buffer
;OUT:   Fc=0, A=free space if room
;       Fc=1, A=0 if buffer full
;chg:   AF....../....

.BufHasRoom
        call    OZ_DI
        ex      af, af'
        call    BfSTAMain
        ld      a, l
        ex      af, af'
        call    OZ_EI
        ex      af, af'
        cp      1                               ; Fc=1 if buffer full
        ret

;       ----

; put byte with timeout
;
;IN:    IX = buffer
;       A  = data
;       BC = timeout
;OUT:   Fc=0, BC=remaining time if success
;       Fc=1, A=error if fail
;cfg:   AFBC

.BfPbt
        ex      af, af'
        call    OZ_DI
        push    af
        ei
        ex      af, af'
        push    de
        push    af                              ; save data

        ld      de, 0                           ; reset timer, disable it, then set new value
        ld      hl, ubIntTaskToDo
        ld      (uwSmallTimer), de
        res     ITSK_B_TIMER, (hl)
        ld      (uwSmallTimer), bc

        call    BufHasRoom
        jr      nc, bfpbt_put                   ; there's room, just put byte

        ld      hl, ubIntTaskToDo
        bit     ITSK_B_PREEMPTION, (hl)
        jr      nz, bfpbt_susp0                 ; pre-empted? cancel buffer task and exit
        bit     ITSK_B_ESC, (hl)
        jr      nz, bfpbt_esc                   ; ESC pending? exit

        ld      a, b                            ; if timeout not zero go wait
        or      c
        jr      nz, bfpbt_9

.bfpbt_to
        ld      a, RC_Time
.bfpbt_err
        scf
        jr      bfpbt_x

.bfpbt_put
        pop     af                              ; write data into buffer
        push    af
        ld      c, a                            ; !! use BufWrite
        call    BufWriteC
        jr      c, bfpbt_9                      ; error? wait more

.bfpbt_x
        pop     de                              ; get rid of data in stack
        jp      bfgbt_x                         ; exit thru BfGbt code

.bfpbt_esc
        ld      a, RC_Esc
        jr      bfpbt_err

.bfpbt_susp0
        res     ITSK_B_PREEMPTION, (hl)         ; cancel buffer task

.bfpbt_susp
        ld      a, RC_Susp
        jr      bfpbt_err

.bfpbt_8
        res     ITSK_B_BUFFER, (hl)             ; cancel buffer task
        call    BufHasRoom
        jr      nc, bfpbt_put                   ; try to put data if room in buffer

.bfpbt_9
        call    OSWaitMain                      ; wait for buffer task

        bit     ITSK_B_PREEMPTION, a
        jr      nz, bfpbt_susp0                 ; pre-emped? exit
        bit     ITSK_B_ESC, a
        jr      nz, bfpbt_esc                   ; ESC pending? exit
        bit     ITSK_B_BUFFER, a
        jr      nz, bfpbt_8                     ; buffer task? try to put byte
        bit     ITSK_B_TIMER, a
        jr      nz, bfpbt_to                    ; timeout? exit
        jr      bfpbt_susp                      ; otherwise exit with pre-emption

;       ----

; examine input
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

        push    ix
        call    GetKbddata                      ; !! should be inline, or use absolute addressing
        ld      a, (ix+buf_wrpos)
        cp      (ix+buf_rdpos)
        pop     ix
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

.GetKbddata
        ld      ix, KbdData                     ; !! only used above
        ret

;       ----

; purge keyboard buffer
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

;       ----

; write byte into buffer
;
;IN:    IX = buffer
;       A  = byte
;OUT:   Fc=0, H=#bytes in buffer, L=#free bytes in buffer, Fz=1 if buffer full after write
;       Fc=1, A=error if fail
;chg:   AF.C..HL/....

.BufWrite
        ld      c, a
.BufWriteC                                      ; external call from original keybard routines
        call    OZ_DI
        ex      af, af'

        ld      a, (ix+buf_wrpos)               ; bump wrpos, handle wrap
        ld      l, a
        inc     a
        cp      (ix+buf_end)
        jr      nz, bufw_1
        ld      a, (ix+buf_start)
.bufw_1
        cp      (ix+buf_rdpos)
        jr      nz, bufw_2                      ; if not rdpos we can put byte

        ld      a, RC_Eof                       ; oherwise error
        scf
        jr      bufw_4

.bufw_2
        ld      h, (ix+buf_bufpage)             ; put bute into buffer
        ld      (hl), c
        ld      (ix+buf_wrpos), a               ; store new pointer

        inc     a                               ; bump wrpos, handle wrap
        cp      (ix+buf_end)
        jr      nz, bufw_3
        ld      a, (ix+buf_start)
.bufw_3
        cp      (ix+buf_rdpos)                  ; Fz=1 if buffer full at exit
        scf                                     ; Fc=0
        ccf
        ld      hl, ubIntTaskToDo                 ; signal any OS_Wait
        set     ITSK_B_BUFFER, (hl)

.bufw_4
        call    BfSTAMain                       ; get buffer status
        ex      af, af'
        call    OZ_EI
        ex      af, af'
        ret

;       ----

; read byte from buffer
;
;IN:    IX = buffer
;OUT:   Fc=0, A=C=data , H=#data bytes in buffer, L=#free bytes in buffer
;       Fc=1, A=error if fail
;chg:   AF.C..HL/....

.BufRead
        call    OZ_DI
        ex      af, af'
        ld      a, (ix+buf_rdpos)               ; EOF if rdpos=wrpos
        cp      (ix+buf_wrpos)
        jr      nz, bufr_1
        ld      a, RC_Eof
        scf
        jr      bufr_3

.bufr_1
        ld      h, (ix+buf_bufpage)             ; get byte from buffer
        ld      l, a
        ld      c, (hl)

        inc     a                               ; bump rdpos, handle wrap
        cp      (ix+buf_end)
        jr      nz, bufr_2
        ld      a, (ix+buf_start)
.bufr_2
        ld      (ix+buf_rdpos), a               ; write pointer back

        or      a                               ; Fc=0
        ld      hl, ubIntTaskToDo
        set     ITSK_B_BUFFER, (hl)             ; cancel buffer task

.bufr_3
        call    BfSTAMain                       ; get buffer status
        ex      af, af'
        call    OZ_EI
        ex      af, af'
        ret     c                               ; Fc=1? return error code
        ld      a, c                            ; otherwise byte from buffer
        ret

;       ----

; init buffer with no function or data area

.BufInit0
        ld      b, 0
        ld      h, b
        ld      l, b

;       ----

; init buffer
;
;IN:    IX = buffer
;       B  = data area to clear, starting at (IX)
;       C  = end of circular buffer +1, low byte
;       DE = circular buffer
;       HL = buffer function, not used?

.BufInit
        push    ix
        ld      (ix+buf_wrpos), e
        ld      (ix+buf_rdpos), e
        ld      (ix+buf_start), e
        ld      (ix+buf_end), c
        ld      (ix+buf_bufpage), d
        ld      (ix+buf_func), l
        ld      (ix+buf_func+1), h

        inc     b                               ; handle B=0
        jr      bufi_2
.bufi_1
        ld      (ix+0), 0                       ; clear data afteer (IX)
        inc     ix
.bufi_2
        djnz    bufi_1
        pop     ix

.bufi_3
        ld      (ix+buf_f6), 0                  ; unused?  callable thru KbdData function
        ret

;       ----

        ld      l, (ix+buf_func)                ; buffer function caller, unused
        ld      h, (ix+buf_funcH)
        jp      (hl)

;       ----

; init OZ buffers at reset

.InitBufKBD_RX_TX
        ld      ix, KbdData                     ; KBD buffer
        ld      b, kbd_SIZEOF                   ; clear kbd data
        ld      c, <SerTXBuffer
        ld      de, KbdBuffer                   ; 0b00-0b1f
        ld      hl, bufi_3                      ; unused ??
        call    BufInit                         ; KBD buffer

        ld      ix, SerTXHandle                 ; TX buffer
        ld      c, <(SerTXBuffer+$60)
        ld      de, SerTXBuffer                 ; 0b20-0b7f
        call    BufInit0

        ld      ix, SerRXHandle                 ; RX buffer
        ld      c, <(SerRXBuffer+$80)
        ld      de, SerRXBuffer                 ; 0b80-0bff
        jp      BufInit0

