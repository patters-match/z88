; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1f1a2
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSSr

        org $b1a2                               ; 269 bytes

        include "all.def"
        include "sysvar.def"
        include "bank0.def"

xdef    OSSr_Sus
xdef    OSSr_Fus                                ; OS_Ent
xdef    FreeMemHandle                           ; OpenMem, sub_F669

xref	GetCurrentWdInfo
xref	InitTopicWd
xref	DrawTopicWd
xref	RestoreActiveWd

.OSSr_Err
        ld      a, RC_Fail
        scf
        ret
;
;save & restore screen file
;
;A = reason code:
; SR_SUS ($01) Save user screen
; SR_WPD ($03) Write parameter data (mailbox)
; SR_RPD ($04) Read parameter data (mailbox)
; SR_FUS ($05) Free user screen
; SR_CRM ($06) Remove card (not implemented)
; SR_CIN ($07) Insert card (not implemented)
; SR_PWT ($08) Page wait
; SR_RND ($09) Occasionally a random number (system use)
.OSSR_main
        or      a
        djnz    rus

;save user screen
;
;in:  -
;out: IX = screen image handle

.OSSr_Sus
        ld      a, HND_PROC
        call    AllocHandle
        ret     c
        call    InitMemHandle
        jp      c, sr_1
        call    SaveScreen
        ret     nc
.sr_1
        jp      FreeMemHandle

.rus
        djnz    wpd

;restore user screen
;
;in:  IX = screen image handle

        ld      a, HND_PROC
        call    VerifyHandle
        ret     c
        call    loc_F245
        call    RestoreScreen
        or      a
        jr      sr_1

.wpd
        djnz    rpd

;write mailbox
;
;DE = name of information type, 0=clear mailbox
;BHL = data
;C = data length

        ld      b, a
        inc     b
        dec     b
        call    z, FixPtr
        ld      (ubMailboxSize), bc             ; length/bank
        ld      (pMailbox), hl                  ; data
        ex      de, hl
        ld      bc, $11
        ld      de, $1800
        xor     a
        ld      ($1852), a                      ; mailbox control, store
        jp      CopyMemBHL_DE

.rpd
        djnz    fus

;read mailbox
;DE = name
;BHL = buffer
;C = bufsize
        ld      b, a
        ld      a, ($1852)
        cp      $0AA
        jr      nz, OSSr_Err                    ; no mail, exit
        push    bc
        push    hl
        ex      de, hl                          ; compare mailbox name
        call    FixPtr
        ld      de, $1800
        OZ      GN_Cme                          ; compare null-terminated strings
        pop     hl
        pop     bc
        jr      nz, OSSr_Err
        ld      a, ($1811)                      ; length
        ld      c, a
        ld      a, (iy+OSFrame_C)
        ld      (iy+OSFrame_C), c
        cp      c
        jr      nc, sr_5
        ld      c, a
.sr_5
        xor     a
        ld      ($1852), a
        ld      de, $1812
        jp      CopyMemDE_BHL
.fus
        djnz    crm

;free user screen
;
;IX = screen image handle

.OSSr_FUS
        ld      a, HND_PROC
        call    VerifyHandle
        ret     c

.FreeMemHandle
        push    af
        call    sub_F25D
        ld      a, (ix+hnd_Type)
        call    FreeHandle
        pop     af
        ret

.crm
        djnz    cin
        ret

.cin
        djnz    pwt
        ret

.pwt
        djnz    rnd

;page wait
        OZ      OS_Pur                          ; purge keyboard buffer
.sr_11
        ld      a, (ubCLIActiveCnt)
        or      a
        ret     nz                              ; CLI active? exit

        call    GetCurrentWdInfo
        call    InitTopicWd
        call    MTHPrint
        defm    1,"2I7"
        defm    1,"2C",$FE
        defm    1,"3@",$20+0,$20+2
        defm    $7F,"C"
        defm    1,"G"
        defm    1,"T"
        defm    1,"B"
        defm    "PAGE WAIT"
        defm    1,"T"
        defm    1,"B"
        defm    10,10
        defm    1,$E0
        defm    10
        defm    "CONTINUE"
        defm    10
        defm    1,$E4
        defm    10
        defm    "RESUME"
        defm    $7F,"N"
        defm    0

        xor     a

.sr_12
        or      a
        jr      nz, sr_13
        OZ      OS_In
        jr      nc, sr_12                       ; go see if it's extended char
.sr_13
        push    af
        call    DrawTopicWd
        pop     af
        call    RestoreActiveWd
        ret     nc
        cp      RC_Susp
        scf
        jr      z, sr_11                        ; if pre-emption just redraw and wait more
        ret

.rnd
        djnz    sr_15

;random number
;out DEBC = random number

        ld      bc, (uwRandom1)
        ld      de, (uwRandom2)
        call    PutOSFrame_BC
        jp      PutOSFrame_DE

.sr_15
        ld      a, RC_Unk
        scf
        ret
