; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $0206
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Process2

        include "blink.def"
        include "director.def"
        include "error.def"
        include "fileio.def"
        include "lowram.def"
        include "memory.def"
        include "syspar.def"
        include "sysvar.def"


        org     $c206                           ; 1515 bytes

;       mostly bad application memory routines

xdef    InitHlpActiveCmd
xdef    InitHlpActiveHelp
xdef    NQAin
xdef    OSBye
xdef    OSDom
xdef    OSEnt
xdef    OSExit
xdef    OSNqProcess
xdef    OSPoll
xdef    OSStk
xdef    OSUse
xdef    SetHlpActiveHelp


xref    AllocMemFile_SizeHL
xref    CancelOZcmd
xref    Chk128KB
xref    Chk128KBslot0
xref    CopyMemBHL_DE
xref    CopyMTHApp_Help
xref    CopyMTHHelp_App
xref    DORHandleFreeDirect
xref    DrawOZwd
xref    DrawTopicWd
xref    FirstFreeRAM
xref    FollowPageN
xref    fsMS2BankB
xref    fsRestoreS2
xref    GetAppDOR
xref    GetFileSize
xref    InitApplWd
xref    InitUserAreaGrey
xref    loc_EECE
xref    MarkPageAsAllocated
xref    MATPtrToPagePtr
xref    MS1BankA
xref    MS1BankB
xref    MS2BankA
xref    MS2BankK1
xref    OpenAppHelpFile
xref    OSFramePush
xref    OSSr_Fus
xref    ostin_4
xref    PageNToPagePtr
xref    PutOSFrame_BC
xref    PutOSFrame_BHL
xref    PutOSFrame_DE
xref    RestoreAllAppData
xref    SaveAllAppData
xref    ScreenClose
xref    ScreenOpen
xref    SetActiveAppDOR


defc    FREE_THIS       =7

;       ----

;IN:    IX=application ID
;OUT:   application data: A=flags, C=key, BHL=name, BDE=DOR

.NQAin
        push    ix
        pop     bc
        ld      a, c                            ; <IX
        call    GetAppDOR               
        ld      a, RC_Hand
        jr      c, nqain_x                      ; not found? exit

        ex      de, hl
        call    PutOSFrame_DE                   ; appl DOR
        ld      hl, ADOR_NAME
        add     hl, de
        call    PutOSFrame_BHL                  ; application name

        ex      de, hl                          ; bind in BHL
        OZ      OS_Bix
        push    de                              ; !! unnecessary

        push    ix
        push    hl                              ; IX=HL
        pop     ix
        ld      a, (ix+ADOR_FLAGS)
        ld      (iy+OSFrame_A), a               ; flags1 - good, bad, ugly etc
        ld      a, (ix+ADOR_APPKEY)
        ld      (iy+OSFrame_C), a               ; code letter
        pop     ix

        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix
        or      a
.nqain_x
        jp      CopyMTHApp_Help                 ; copy app pointers over help pointers

;       ----

.OSDom
        ld      a, MM_S1|MM_MUL|MM_FIX
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool, A=mask
        ret

;       ----

.AllocBadRAM1
        call    IsBadUgly
        ret     z                               ; nice? exit with Fc=0
        ld      a, (ubAppContRAM)
        or      a
        jr      nz, acr_1

        ld      a, (ubBadSize)                  ; default bad process size in kb
        add     a, a                            ; translate into pages, max 160 pages
        jr      c, acr_2
        add     a, a
        jr      c, acr_2
.acr_1
        cp      40*4                            ; max 160 pages, 40 KB
        jr      c, acr_3
.acr_2
        ld      a, 40*4

.acr_3
        ld      b, a                            ; remember size
        call    FirstFreeRAM
        ld      c, a                            ; remember bank

        call    Chk128KB                        ; limit size to 32 pages on unexpanded machine
        ld      a, b
        jr      nc, acr_4
        cp      8*4
        jr      c, acr_4
        ld      a, 8*4
.acr_4
        ld      (ubAppContRAM), a
        add     a, 8*4                          ; 8K more
        ld      ($1855), a

;       set bindings as needed

        ld      hl, ubAppBindings
        ld      (hl), $21                       ; S0 b20 upper half - first 8KB of bad app RAM
        cp      16*4
        jr      c, acr_5                        ; less than 16KB? done
        inc     hl
        inc     c
        ld      (hl), c                         ; 16KB more in seg1
        cp      32*4
        jr      c, acr_5                        ; less than 32KB? done
        inc     hl
        inc     c
        ld      (hl), c                         ; total 40KB

.acr_5
        push    ix
        ld      a, MM_S1|MM_MUL|MM_FIX
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool
        jr      c, acr_x                        ; error? exit
        ld      (pAppBadMemHandle), ix

        call    AllocBadRAM2
        call    c, FreeBadRAM                   ; didn't get all RAM needed? free what we got

.acr_x
        pop     ix
        ret

;       ----

.FreeBadRAM
        push    af
        call    IsBadUgly
        jr      z, fcr_x                        ; nice? exit

        push    ix
        ld      ix, (pAppBadMemHandle)          ; free all bad app memory
        OZ      OS_Mcl
        pop     ix

.fcr_x
        pop     af
        ret

;       ----

.BadAllocAndSwap
        call    IsBadUgly
        ret     z                               ; nice? exit
        call    AllocBadRAM2

;       swap all memory between swap banks and IY table

.BadSwapAll
        push    af
        call    BadSetup

;       do until b=0

.bsa_1
        push    bc
        push    hl

        call    sub_C3F8                        ; ld a,bank; cp 1
        jr      c, bsa_3                        ; bank zero? skip
        jr      z, bsa_3                        ; bank 1? skip
        call    FollowPageN
        jr      nz, bsa_2                       ; part of chain, don't tag

        call    MarkPageAsAllocated
        set     FREE_THIS, (iy+0)

;       swap memory between AHL=MATPtr and page pointed by IY

.bsa_2
        call    MATPtrToPagePtr
        call    CopyPageFromAH0                 ; copy into stack buffer
        push    af
        push    hl
        call    GetPageAndBank
        or      a                               ; Fc=0, copy HL -> DE
        call    CopyPage                        ; copy after first page
        call    CopyPageToAH0                   ; then copy first over the second
        pop     hl
        pop     af
        scf                                     ; Fc=1, copy DE -> HL
        call    CopyPage                        ; copy second page over the first one

.bsa_3
        call    BadAdvance
        jr      nz, bsa_1                       ; not done? loop

        call    BadRestore
        pop     af
        ret

;       ----

.sub_C2F3
        xor     a
        ld      b, a
        ld      c, a
        ld      d, a
        ld      e, a

;       ----

.BadSwapAndFree
        call    IsBadUgly
        ret     z
        push    bc
        push    de
        call    BadSwapAll
        pop     af
        pop     bc
        ld      hl, $FF
        add     hl, bc
        ld      e, h

.bsf_1
        sub     e
        ret     z
        ret     c
        call    BadSetup
 IF	OZ40001=0
        ld      c, a
        add     a, e
        sub     l
        ld      b, a

.bsf_2
        push    bc
        push    hl

        ld      a, c
        cp      b
 ELSE
        add     a, e
        sub     l
        ld      b, a
        ld      c, e

.bsf_2
        push    bc
        push    hl

        ld      a, l
        cp      c
 ENDIF
        jr      c, bsf_4
        call    sub_C3F8                        ; ld a,bank; cp 1
        jr      c, bsf_4                        ; bank 0? don't free

        call    nz, GetPageAndBank              ; bank>1? get page too
        call    z, PageNToPagePtr               ; bank=1? convert HL into ptr
        ld      bc, $100
        ld      l, c                            ; L=0
        OZ      OS_Mfr                          ; Free page AH0
        jr      c, $PC                          ; error? crash
        ld      (iy+1), c                       ; clear bank

.bsf_4
        call    BadAdvance
        jr      nz, bsf_2                       ; not done? loop
        call    BadRestore
        ret

;       ----

.AllocBadRAM2
        call    BadSetup
.abr2_1
        push    bc
        push    hl

        call    sub_C3F8
        jr      nc, abr2_6

        call    FollowPageN
        jr      nz, abr2_2                      ; part of chain? skip

        call    MarkPageAsAllocated
        ld      h, 0                            ; page=0
        ld      a, 1                            ; bank=1
        jr      abr2_3

.abr2_2
        xor     a                               ; allocate new page
        ld      bc, $100
        OZ      OS_Mal
        jr      c, abr2_7                       ; error? exit
        ld      a, b                            ; bank

.abr2_3
        pop     de
        pop     bc
        inc     c
        dec     c
        jr      nz, abr2_5                      ; not zero? skip

 IF	OZ40001=0
        push    af
        ld      a, (ubAppContRAM)
        sub     b
        cp      8*4                             ; below 8KB of bad app RAM
        call    nc, Chk128KBslot0               ; yes? Fc=0 if slot 0 expanded
        ld      a, e
        jr      c, abr2_4                       ; <8KB or slot 1 expanded
        sub     $40                             ; skip b21
.abr2_4
        ld      c, a
        pop     af
 ELSE
        ld      c, e
 ENDIF
.abr2_5
        push    bc
        push    de
        ld      (iy+0), h                       ; remember page
        ld      (iy+1), a                       ; and bank

.abr2_6
        call    BadAdvance
        jr      nz, abr2_1                      ; not done yet? loop

        or      a                               ; Fc=0
        jr      abr2_8

.abr2_7
        pop     hl
        pop     de

        push    af
 IF     OZ40001=0
        ld      a, (ubAppContRAM)
        sub     d
        add     a, $20
 ELSE
        ld      a, l
 ENDIF
        inc     e
        dec     e
        call    nz, bsf_1                       ; free all allocated blocks
        pop     af

;       clear all flags in table

.abr2_8
        ld      bc, (ubAppContRAM-1)            ; ld b,(ubAppContRAM)
        ld      hl, (pAppBadMemTable)
.abr2_9
        res     FREE_THIS, (hl)
        inc     hl
        inc     hl
        djnz    abr2_9

        call    BadRestore
        ret

;       ----

;       E=0 - free each page from table

.sub_C39F
        call    IsBadUgly
        ret     z
        call    BadSetup
        ld      c, e
.u1_1
        push    bc
        push    hl

        bit     FREE_THIS, (iy+0)
        jr      z, u1_3                         ; flag=0? skip

        call    PageNToPagePtr
        inc     c
        dec     c
        call    z, GetPageAndBank               ; free each page
        ld      bc, $100
        ld      l, c
        OZ      OS_Mfr                          ; free page AH0
        jr      c, $PC                          ; crash

        ld      (iy+0), c                       ; 0
        ld      (iy+1), 1

.u1_3
        call    BadAdvance
        jr      nz, u1_1
        call    BadRestore
        ret

;       ----

.CopyPageFromAH0
        or      a
        jr      copy

.CopyPageToAH0
        scf
.copy   ld      de, ($185B)

; copy 256 bytes
;
; IN: A=MS1 bank
; Fc=0 - copy HL -> DE
; Fc=1 - copy DE -> HL
;
; OUT: DE advanced by 256 bytes

.CopyPage
        call    MS1BankA
        ld      bc, $100
        ld      l, c
        push    af
        push    bc
        push    hl

        jr      nc, cpg_1                       ; Fc=1? copy DE->HL
        ex      de, hl
.cpg_1
        ldir
        jr      nc, cpg_2
        ex      de, hl

.cpg_2
        pop     hl
        pop     bc
        pop     af
        ret

;       ----

.IsBadUgly
        ld      a, (ubAppDORFlags)
        and     AT_BAD|AT_UGLY
        ret

;       ----
.GetPageAndBank
        ld      h, (iy+0)                       ; page
        res     FREE_THIS, h

.sub_C3F8
        ld      a, (iy+1)                       ; bank
        cp      1                               ; Fc=1 if A=0
        ret

;       ----

;       push ix-iy-S1/S2, bind b21 into S2, return with HL=$20

.BadSetup
        pop     hl                              ; return address
        push    ix
        push    iy
        ld      bc, (ubSlotRAMoffset-1)         ; ld b,(ubSlotRAMoffset)
        inc     b                               ; $21 always?
        call    fsMS2BankB                      ; remember S1/S2 and do MS2BankB
        ld      bc, (ubAppContRAM-1)            ; ld b,(ubAppContRAM)
        ld      c, 0
        ld      ix, (pAppBadMemHandle)
        ld      iy, (pAppBadMemTable)
        jr      loc_C423

;       undo previous

.BadRestore
        pop     hl                              ; return address
        call    fsRestoreS2
        pop     iy
        pop     ix

.loc_C423
        push    hl                              ; return address
        ld      hl, $20
        ret

;       ----

.BadAdvance
        pop     de                              ; return address

        inc     iy                              ; next entry in table
        inc     iy

        pop     hl                              ; PageN
        pop     bc
        inc     hl
        ld      a, l
        cp      $40
        jr      c, badv_1                       ; still in b20 SWAP area? skip

        call    FirstFreeRAM                    ; bind first RAM bank in S2
        call    MS2BankA
        cp      $40
        jr      z, badv_1                       ; slot 1
        ld      a, l
        cp      $40
        jr      nz, badv_1
        ld      l, $80                          ; skip b21
.badv_1
        dec     b                               ; decrement page count
        push    de                              ; return address
        ret

; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $06e4
;
; $Id$
; -----------------------------------------------------------------------------

;       quit process (application)

.OSExit
        ld      a, RC_Quit                      ; exit
        jr      osent_1

;       enter an application

.OSEnt
        ld      a, RC_Draw                      ; enter

.osent_1
        push    ix
        push    iy
        ex      af, af'                         ; save Fc

        exx
        ld      de, $1ffe                       ; BC=used stack size
        ld      hl, 0
        add     hl, sp
        ex      de, hl
        sbc     hl, de
        ld      b, h
        ld      c, l

        ex      de, hl
        ld      de, stkBottom
        ld      (pStkEntUsedStkBottom), hl      ; used stack low limit
        ld      (uwStkEntUsedStkSize), bc       ; used stack size
        ldir                                    ; move down to stkBottom

        ex      de, hl                          ; reserve 256 bytes for temp stack
        ld      de, 256
        add     hl, de
        ld      (pStkTempStkTop), hl
        ld      sp, hl
        exx

        ex      af, af'                         ; restore Fc
        inc     b
        dec     b
        jp      z, osent_12                     ; enter/exit new process

        scf
        push    af                              ; A=RC, Fc=1, Fz=0

        ld      (pOSEntHandle), hl              ; IX=(pOSEntHandle)
        push    hl
        pop     ix
        call    RestoreAllAppData
        jr      z, osent_3                      ; didn't restore screen? skip

        pop     bc                              ; pop AF - we do this in BC to  keep flags
        ld      a, b
        cp      RC_Draw
        jr      nz, osent_2                     ; not OS_Ent? skip
        ld      b, RC_Susp                      ; change RC_Draw into RC_Susp as screen is OK
.osent_2
        push    bc                              ; push AF

.osent_3
        pop     af                              ; prepare for call point at osent_4
        ld      ix, (uwAppStaticHnd)

.osent_4
        ld      sp, (pAppStackPtr)
        push    af

        ld      (uwAppStaticHnd), ix
        ld      a, (uwAppStaticHnd)
        call    InitAppMTH

        ld      a, SC_RES
        OZ      OS_Esc                          ; reset escape without flushing the input buffer
        call    ClearUnsafeArea                 ; always cleared

        pop     af
        push    af
        cp      RC_Quit
        jr      z, osent_5                      ; OS_Exit? skip

        ld      hl, (uwAppEnvOverhead)          ; allocate env file
        call    AllocMemFile_SizeHL
        call    MS2BankK1
        call    SetAppEnvHandle                 ; ld (pAppEnvHandle),ix  !! do it here
        jr      c, osent_10                     ; no file? cleanup and exit

.osent_5
        call    CancelOZcmd
        call    ScreenOpen
        xor     a                               ; clear these for first entry
        ld      (sbf_CtrlPrefix), a
        ld      (PrtSeqPrefix), a
        call    ScreenClose

        call    BadAllocAndSwap
        jr      nc, osent_6                     ; got memory? ok
        pop     af
        push    af
        cp      RC_Quit
        jr      nz, osent_9                     ; OS_Ent? cleanup and exit with Fc=1

.osent_6
        pop     af
        push    af
        xor     RC_Draw                         ; Fc=0 for ApplCaps, Fz=need_redraw flag
        ld      a, (ubAppDORFlags)
        jr      nz, osent_7                     ; no redraw needed? skip

        bit     AT_B_Popd, a
        call    z, InitApplWd                   ; not popdown? init window
.osent_7
        bit     AT_B_Popd, a
        call    z, ApplCaps                     ; not popdown? restore flags (Fc=0)

        call    DrawTopicWd

        ld      e, 0                            ; free bad app extra swap memory
        call    sub_C39F

        ld      ix, (pOSEntHandle)              ; free saved screen
        call    OSSr_Fus

        pop     af
.osent_8
        call    OSEntSub                        ; prepare for enter
        jp      ostin_4                         ; enter thru OS_Tin

.osent_9
        call    sub_C2F3                        ; free all bad memory
        ld      e, -1                           ; free memory marked SWAP
        call    sub_C39F
        call    CloseAppEnvHandle               ; close AppEnvHandle

.osent_10
        pop     hl
        inc     h
        dec     h
        call    z, FreeBadRAM                   ; RC_OK? free

.osent_11
        ld      hl, stkBottom                   ; restore stack
        ld      de, (pStkEntUsedStkBottom)
        ld      bc, (uwStkEntUsedStkSize)
        ldir
        ld      sp, (pStkEntUsedStkBottom)      ; restore SP, IY, IX
        pop     iy
        pop     ix
        scf
        ret

;       enter/exit new process

.osent_12
        cp      RC_Draw
        scf
        jr      nz, osent_8                     ; OS_Exit? return with Fc=1

        push    bc                              ; clear 64 bytes of app variables
        ld      bc, $3F
        ld      de, uwAppStaticHnd+1
        ld      hl, uwAppStaticHnd
        ld      (hl), 0                         ; !! ld (hl), b
        ldir
        pop     bc

        ld      a, 1
        ld      (ubAppCallLevel), a
        ld      a, c
        ld      (ubAppDynID), a
        ld      (uwAppStaticHnd), ix
        ld      a, (uwAppStaticHnd)
        call    SetActiveAppDOR
        call    CopyMTHHelp_App
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; enquire (fetch) parameter
        ld      (ubAppDORFlags), a
        bit     AT_B_Popd, a
        call    nz, InitUserAreaGrey            ; popdown? init screen
        call    MS1BankB
        set     6, d                            ; DOR in S1
        push    de
        set     6, h                            ; name in S1
        call    OpenAppHelpFile
        jr      c, osent_13                     ; no help file? skip
        ld      (pAppHelpHandle), ix
        ld      a, (ix+fhnd_Bank)
        ld      (ubAppHelpBank), a
        call    CopyMTHHelp_App
.osent_13
        pop     ix
        ld      hl, $1FFE
        ld      e, (ix+ADOR_UNSAFE)             ; DE=unsafe needed
        ld      d, (ix+ADOR_UNSAFE+1)
        or      a
        sbc     hl, de
        ld      (pAppUnSafeArea), hl
        ld      c, (ix+ADOR_SAFE)               ; BC=safe needed
        ld      b, (ix+$16)
        sbc     hl, bc
        call    IsBadUgly
        jr      z, osent_14                     ; nice? no extra stack
        ld      de, -320                        ; 40*PAGES_PER_KB*WORD_SIZEOF
        add     hl, de
        ld      (pAppBadMemTable), hl
.osent_14
        ld      sp, hl
        ex      de, hl
        ld      hl, (pAppUnSafeArea)
        call    ClearMemDE_HL                   ; clear safe workspace and bad allocation table
        ld      a, (ix+ADOR_FLAGS2)
        ld      b, a
        and     AT2_Cl|AT2_Icl                  ; caps/CAPS state
        ld      (ubAppKbdBits), a
        ld      a, b
        ld      (ubAppDORFlags2), a
        and     AT2_Ie                          ; ignore errors?
        rlca                                    ; defult error handler is either $00e0 or $00e1
        ld      hl, DefErrHandler
        add     a, l
        ld      l, a
        ld      a, 1
        OZ      OS_Erh                          ; Set (install) Error Handler
        ld      (ubOldCallLevel), a
        ld      a, SC_DIS
        OZ      OS_Esc                          ; disable escape detection
        ld      l, (ix+ADOR_ENVSIZE)            ; HL=env overhead
        ld      h, (ix+$12)
        ld      (uwAppEnvOverhead), hl
        ld      a, (ix+ADOR_BADSIZE)
        ld      (ubAppContRAM), a
        ld      l, (ix+ADOR_ENTRY)              ; HL=entry point
        ld      h, (ix+$18)
        push    hl
        ld      (pAppEntrypoint), hl
        push    ix                              ; point HL to bindings
        pop     hl
        ld      de, ADOR_BINDINGS
        add     hl, de
        ld      de, ubAppBindings
        ld      a, (eHlpAppDOR+2)
        and     $c0                            ; slot base
        ld      c, a
        ld      b, 4
.osent_15
        ld      a, (hl)                         ; get wanted binding
        or      a
        jr      z, osent_16                     ; zero? don't care
        and     $3F                             ; mask out slot
        or      c                               ; and replace with correct slot
.osent_16
        ld      (de), a                         ; store fixed bank
        inc     hl
        inc     de
        djnz    osent_15
        call    AllocBadRAM1
        jp      c, osent_11                     ; no memory? exit with Fc=1
        ld      hl, (ubAppBindings+2)           ; S3S2
        push    hl                              ; for OSFramePush
        ld      a, l
        ld      (BLSC_SR2), a
        ld      bc, 0
        ld      h, b
        ld      l, c
        ld      (pOSEntHandle), hl
        ld      de, unk_1864
        exx
        call    OSFramePush
        ld      ix, loc_EECE                    ; jp OSFramePop  !! point to to OSFramePop directly
        push    ix
        ld      hl, word_1853
        push    hl
        ld      (hl), 3                         ; 03 20 .. 00
        inc     hl
        ld      (hl), $20
        inc     hl
        inc     hl
        ld      (hl), 0
        push    iy
        ld      (pAppStackPtr), sp
        ld      ix, (uwAppStaticHnd)            ; !! this is at osent_4-4, jp there
        ld      a, 1                            ; A=0, Fc=0, Fz=0
        or      a
        ld      a, RC_OK
        jp      osent_4                         ; enter thru Os_Ent

;       ----

.OSEntSub
        ex      af, af'
        call    ChkStkLimits
        call    AppBindS012
        ld      a, (ubOldCallLevel)
        ld      (ubAppCallLevel), a
        ld      hl, ubAppResCycle
        inc     (hl)
        ex      af, af'
        pop     hl                              ;  get return address
        ld      sp, (pAppStackPtr)
        jp      (hl)
.AppBindS012
        ld      hl, ubAppBindings+2
        ld      bc, BLSC_SR2
        call    BindSx
        call    BindSx
.BindSx
        ld      a, (hl)
        ld      (bc), a
        out     (c), a
        cpd
        ret

;       ----

; Fc=0 - restore caps flags
; Fc=1 - remember caps flags
.ApplCaps
        ld      hl, KbdData+kbd_flags           ; kbd_flags
        ld      de, ubAppKbdBits                ; application kbd cfg
        jr      nc, apc_1
        ex      de, hl
.apc_1
        ld      a, (de)                         ; !! bits match - and 3; or (hl); ld (hl),a
        res     KBF_B_CAPSE, (hl)
        res     KBF_B_CAPS, (hl)
        rrca
        jr      nc, apc_2
        inc     (hl)                            ; CAPSE
.apc_2
        rrca
        jr      nc, apc_3
        set     KBF_B_CAPS, (hl)
.apc_3
        jp      DrawOZwd

;       ----

; stack file current process

.OSStk
        push    ix
        call    Mailbox2Stack
        call    AppReleaseMem
        scf                                     ; Fc=1, remember caps flags
        call    ApplCaps
        call    SaveAllAppData
        jr      c, osstk_1
        call    UpdEnvOverhead
        or      a                               ; Fc=0
        ld      a, (ubAppHelpBank)
        or      1
        ld      b, a
        push    ix
        pop     hl
        call    PutOSFrame_BHL
.osstk_1
        pop     ix
        ret

;       ----

.UpdEnvOverhead
        call    GetFileSize                     ; HL=size
        ret     c                               ; error? exit
        ld      de, (uwAppEnvOverhead)          ; store size if larger than previous
        sbc     hl, de
        ret     c
        add     hl, de
        ld      (uwAppEnvOverhead), hl
        ret

;       ----

;       exit current application

.OSBye
        call    OSFramePush
        push    af

        xor     a                               ; remove error handler
        ld      h, a
        ld      l, a
        inc     a
        OZ      OS_Erh

        call    Mailbox2Stack

        ld      ix, (pAppHelpHandle)
        call    DORHandleFreeDirect

        call    AppReleaseAllMem
        call    FreeBadRAM

        pop     af
        OZ      DC_Bye
        jr      $PC                             ; crash if we come back here

;       ----

.AppReleaseMem
        call    IsBadUgly
        jr      z, CloseAppEnvHandle
        and     AT_UGLY
        jr      nz, AppReleaseAllMem
        ld      a, RC_Esc
        ex      af, af'

        ld      hl, (pAppEntrypoint)            ; call enquiry function
        inc     hl
        inc     hl
        inc     hl
        ld      a, (ubAppBindings+3)
        call    JpAHL

        ex      af, af'
        jr      nc, arm_1

.AppReleaseAllMem
        ld      bc, $2000                       ; BC-DE is free, ie. none
        ld      d, b
        ld      e, c
.arm_1
        call    BadSwapAndFree

.CloseAppEnvHandle
        ld      ix, (pAppEnvHandle)
        OZ      OS_Cl

.SetAppEnvHandle
        ld      (pAppEnvHandle), ix
        ret

;       ----

;       fetch information about process card usage
;
;IN:    IX,B
;OUT:   A bits0-3

.OSUse
        ld      c, 0
        push    ix
        pop     hl
        call    osuse_1
        ld      l, b
.osuse_1
        ld      h, 0
        add     hl, hl
        add     hl, hl
        ld      a, h
        cp      3
        ccf
        adc     a, 0                            ; A=0/1/2/4
        rlca
        or      c
        ld      c, a
        ld      (iy+OSFrame_A), a
        ret

;       ----

.InitAppMTH
        ld      (ubHlpActiveApp), a

.InitHlpActiveHelp
        ld      a, 1

.SetHlpActiveHelp
        ld      (ubHlpActiveHelp), a
        ld      a, 1
        ld      (ubHlpActiveTpc), a

.InitHlpActiveCmd
        ld      a, 1
        ld      (ubHlpActiveCmd), a
        ret


; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1daeb
;
; $Id$
; -----------------------------------------------------------------------------


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
        or      a				; !! 'dec a; cp 64; ld a,0; jr nc'
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
	ld	c, 1
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

;       read direct printer handle
.NQRhn
	inc	c

;       read OUT handle
.NQOhn
	inc	c

;       read IN handle
.NQIhn
	inc	c

;       read comms handle
.NQCom
	inc	c

;       read null handle
.NQNhn
	inc	c

;       read printer indirected handle
.NQPhn
	inc	c

;       read screen handle
.NQShn
	inc	c

;       read keyboard   handle
.NQKhn
	push	bc
	pop	ix
        ret

;       Who am I?
.NQWai
        ld      ix, (uwAppStaticHnd)
        ld      a, (ubAppDynID)
        ld      c, a
        jp      PutOSFrame_BC
