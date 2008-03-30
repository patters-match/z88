; -----------------------------------------------------------------------------
; Kernel 1 @ S2
;
; $Id$
; -----------------------------------------------------------------------------

        Module Process1

        include "error.def"
        include "saverst.def"
        include "sysvar.def"
        include "handle.def"

xdef    OSPoll
xdef    ClearUnsafeArea
xdef    ClearMemDE_HL
xdef    ChkStkLimits
xdef    Mailbox2Stack
xdef    OSNqProcess

xref    GetAppDOR                               ; [Kernel0]/mth0.asm
xref    NQAin                                   ; [Kernel0]/process2.asm
xref    PutOSFrame_BC                           ; [Kernel0]/memmisc.asm
xref    CopyMemBHL_DE                           ; [Kernel0]/memmisc.asm


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
IF OZ_SLOT1
        or      b
        ld      a, c
        jr      nz,next_app_id
        or      $40                             ; first app is in slot 1...
.next_app_id
ENDIF
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
        ld      de, (pAppUnSafeArea)            ; unsafe area start

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

;       read keyboard handle
.NQKhn
        ld      ix, phnd_Khn
        ret

;       read screen handle
.NQShn
        ld      ix, phnd_Shn
        ret

;       read printer indirected handle
.NQPhn
        ld      ix, phnd_Phn
        ret

;       read null handle
.NQNhn
        ld      ix, phnd_Nhn
        ret

;       read comms handle
.NQCom
        ld      ix, phnd_Com
        ret

;       read IN handle
.NQIhn
        ld      ix, phnd_Ihn
        ret

;       read OUT handle
.NQOhn
        ld      ix, phnd_Ohn
        ret

;       read direct printer handle
.NQRhn
        ld      ix, phnd_Rhn
        ret

;       Who am I?
.NQWai
        ld      ix, (uwAppStaticHnd)
        ld      bc, (ubAppDynID)                ; !! just for C
        ld      b, 0
        jp      PutOSFrame_BC
