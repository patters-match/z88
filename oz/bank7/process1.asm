; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1daeb
;
; $Id$
; -----------------------------------------------------------------------------

        Module Process1

        org $9aeb                               ; 211 bytes

        include "error.def"
        include "sysvar.def"

xdef    OSPoll
xdef    ClearUnsafeArea
xdef    ClearMemDE_HL
xdef    ChkStkLimits
xdef    Mailbox2Stack
xdef    OSNqProcess

;       bank 0

xref    CopyMemBHL_DE
xref    GetAppDOR
xref    NQAin
xref    PutOSFrame_BC

;       ----

;       poll for an application
;IN:    IX=current application, 0 for start of list
;OUT:   IX=next application
;       Fc=0 if ok
;       Fc=1, A=error if fail

.OSPoll
        push    ix
        pop     bc
        ld      a, c
        inc     a                               ; next application
        call    GetAppDOR                       ; go find it
        ld      c, a
        ld      b, 0
        ld      a, RC_Eof
        ret     c
        push    bc
        pop     ix
        ret

;       ----

;       clear unsafe stack area

.ClearUnsafeArea
        ld      hl, $1FFE                       ; stack top
        ld      de, (pAppUnSafeArea)               ; unsafe area start

;       clear memory from DE (inclusive) to HL (exclusive)

.ClearMemDE_HL
        xor     a                               ; A=0, Fc=0
        sbc     hl, de
        ret     z                               ; HL=DE? exit
        add     hl, de                          ; restore HL
        ld      (de), a                         ; clear first byte
        inc     de
        sbc     hl, de
        ret     z                               ; HL=DE? exit
        ld      b, h                            ; BC=end-start
        ld      c, l
        ld      h, d                            ; HL=start
        ld      l, e
        dec     hl                              ; over zero byte
        ldir                                    ; copy forward, ie. zero fill
        ret

;       ----

;       check that stack pointer and unsafe area are within stack limits
;       freeze if either outside limits

.ChkStkLimits
        ld      hl, $1FFE                       ; upper limit
        ld      bc, $1820                       ; lower limit
        ld      de, (pAppStackPtr)
        call    ChkLimits
        jr      c, chkstk_1
        ld      de, (pAppUnSafeArea)
        call    ChkLimits
        ret     nc
.chkstk_1
        xor     a                               ; freeze
        jr      chkstk_1


.ChkLimits
        push    bc
        push    de                              ; !! can do without pushing DE
        push    hl
        or      a
        sbc     hl, de
        jr      c, chklm_1                      ; HL<DE? Fc=1
        ex      de, hl
        sbc     hl, bc                          ; DE<BC? Fc=1
.chklm_1
        pop     hl
        pop     de
        pop     bc
        ret

;       ----

;       copy mailbox data into low stack area
;       if $1852 contains $aa then $1811 is length of data starting at $1812
;       data length can't exceed 64 bytes

;
.Mailbox2Stack
        ld      hl, (pMailbox)
        ld      bc, (ubMailboxSize)             ; B=ubMailboxBank
        ld      a, c
        or      a                               ; !! 'dec a; cp 64; ld a,0; jr nc'
        jr      z, mb2s_1
        cp      MAILBOXMAXLEN+1
        ld      a, 0
        jr      nc, mb2s_1                      ; >64? exit
        ld      (ubMailboxLength), bc
        ld      de, MailboxData
        call    CopyMemBHL_DE
        ld      a, MAILBOXID                    ; mark as valid

.mb2s_1
        ld      (ubMailBoxID), a                ; store identifier
        ret

;       ----

.OSNqProcess
        cp      $1E                             ; range check
        ccf
        ld      a, RC_Unk
        ret     c

        ld      hl, OSNqPrcssTable
        add     hl, bc
        jp      (hl)

.OSNqPrcssTable
        jp      NQAin
        jp      NQKhn
        jp      NQShn
        jp      NQPhn
        jp      NQNhn
        jp      NQWai
        jp      NQCom
        jp      NQIhn
        jp      NQOhn
        jp      NQRhn

;       read keyboard   handle
.NQKhn
        ld      ix, 1
        ret

;       read screen handle
.NQShn
        ld      ix, 2
        ret

;       read printer indirected handle
.NQPhn
        ld      ix, 3
        ret

;       read null handle
.NQNhn
        ld      ix, 4
        ret

;       read comms handle
.NQCom
        ld      ix, 5
        ret

;       read IN handle
.NQIhn
        ld      ix, 6
        ret

;       read OUT handle
.NQOhn
        ld      ix, 7
        ret

;       read direct printer handle
.NQRhn
        ld      ix, 8
        ret

;       Who am I?
.NQWai
        ld      ix, (uwAppStaticHnd)
        ld      bc, (ubAppDynID)                ; !! just for C
        ld      b, 0
        jp      PutOSFrame_BC
