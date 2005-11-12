; Bank 0 @ S3           ROM offset $1b0d-$1f21


        Module Keyboard

; Generic new routine from Jorma Oksanen adapted and modified by Thierry Peycru
;
; Originally OZ2.5 keyboard routines fitted into OZ4 ROM, later mostly
; rewritten from ApplyQualifiers() to the end.
; Deadkeys is here, 9d6e-9dc2 free (85 bytes)
;
; Changes
;
;02     KbdMaskTable[] truncating
;03     Tables at $b300
;04     back to "jr caps_0" in CapsTable handling
;05     undid 04, clear Fc in CapsTable - works!
;06     deadkeys - works
;07     DrawOZWindow() patch - nothing here
;08     added call to DrawOZWindow(), changed OZwd-char to hires font
;09     killed "or a" at RdKeymatrix() - Fc was 0 already
;       added reset patch for RAM pointers (00d1)
;10     uses RAM pointers
;11     enter/tab/del/menu/index/help handling internal to save keymap table space
;12     fixed scf->ccf in SpecInternal(), fixed keymap table order (ouch!)
;13     fixed TranslateTable()
;14     [] table modified to remove unnecessary code, cursor keys in SpecInternal(), <> [] logic
;16     RAM binding! crsr_up still doesn't work
;17     Workaround for crsr_up, needs real fix
;18     ExtCall() added, shortened code by some bytes.  crsr_up bug was because of empty table, fixed
;       RAM binding in KbMain() removed, done in ExtKbMain()
;19     T.Peycru
;       Complete rewrite of the ApplyQualifiers (shift/caps/CAPS sections)
;       Remove of the CapsTable causing incompatibilities with complex keyboard (the frenchy off course)
;       Removed ExtCapsable/DoCzpsable/DoLocalized routines
;       Revert to OZ4 routine now called 'IsForeignKey' externally called by 'ExtIsForeignKey'
;20     Fix Shift/CAPS/caps behaviour
;       NB: IsForeignKey depends on the font mapping
;21     Clean source and revert 
;
; Keymap structure
;
;km_matrix / km_shift always has addresses XX00 / XX40, these are taken care of in GetKbdPtr
;

include "blink.def"
include "stdio.def"
include "sysvar.def"

xdef    ExtKbMain                       ; was KbMain
xdef    ExtQualifiers                   ; was ApplyQualifiers
xdef    ExtIsForeignKey                 ; is key a special foreign char
xdef    InitKbdPtrs

xref    BufWrite
xref    SwitchOff
xref    MaySetEsc
xref    MS2BankA
xref    UpdateRnd
xref    DrawOZWd


;       Stubs to bind keyboard data in/out S1

.ExtKbMain                                      ; called from Int.asm $d96e (196e)
        call    ExtCall
        defw    KbMain

.ExtQualifiers                                  ; called from OsCli.asm $99E9 and OSIn.asm $EF86 (1d9e9 & 2f86)
        call    ExtCall
        defw    ApplyQualifiers

.ExtIsForeignKey                                ; called from OSIn.asm $f073 (3073)
        call    ExtCall
        defw    IsForeignKey

.ExtCall
        ex      (sp), hl                        ; push hl, get PC
        push    bc
        ld      c, a

        ld      a, ($4d2)                       ; remember S2
        push    af
        ld      a, (km_bank)                    ; bind in keymap data
        call    MS2BankA

        ld      a, (hl)                         ; get function in HL
        inc     hl
        ld      h, (hl)
        ld      l, a

        ld      a, c
        call    jpHL                            ; and call it with AB intact

        push    af
        pop     bc

        pop     af                              ; restore S2
        call    MS2BankA

        push    bc                              ; return with AF intact
        pop     af
        pop     bc
        pop     hl
        ret

.jpHL   jp      (HL)


; Main keyboard routine
.KbMain
        exx
        push    bc
        push    de
        push    hl
        push    iy

        push    hl                              ; working space for keyboard matrix
        push    hl                              ; 8 rows + or'ed key mask
        push    hl
        push    hl
        push    hl

        ld      iy, 0                           ; iy points to kbd matrix in stack
        add     iy, sp
        ld      ix, KbdData                     ; ix points to OZ kbd data

        call    RdKeymatrix
        jp      c, loc_0_DBE4                   ; no kbd collisions

        bit     KB_ACTIVE, (ix+kbd_keyflags)
        jp      z, kb_prv

        ld      a, (ix+kbd_rawkey)
        call    KbdTestKey
        jr      z, kb_rls                       ; has been released

        bit     KB_HOLD, (ix+kbd_keyflags)
        res     KB_RELEASE, (ix+kbd_keyflags)
        jr      nz, kb_1

        set     KB_HOLD, (ix+kbd_keyflags)      ; init hold
        call    UpdateRnd
        ld      a, 60                           ; initial repeat delay
        jr      kb_3                            ; init rpt counter
; ---------------------------------------------------------------------------

.kb_1   ld      a, (ix+kbd_rawkey)
        call    FindOtherKey
        jr      c, kb_2
        bit     KB_ACTIVE, (ix+kbd_prevflags)
        jr      nz, kb_2

        ld      b, (ix+kbd_rawkey)
        ld      (ix+kbd_prevkey),b
        ld      (ix+kbd_prevflags),K_ACTIVE

        ld      (ix+kbd_rawkey), a
        ld      (ix+kbd_keyflags), K_ACTIVE
        jp      loc_0_DBE3
; ---------------------------------------------------------------------------

.kb_2   ld      a, (ubRepeat)
        or      a
        jr      z, loc_0_DBB6

        bit     7, (ix+kbd_repeatcnt)           ; repeat disabled?
        jr      nz, loc_0_DBB6
        dec     (ix+kbd_repeatcnt)
        jr      nz, loc_0_DBB6
        ld      a, (ubRepeat)

.kb_3   ld      (ix+kbd_repeatcnt), a           ; restart counter

        ld      a, (cKeyclick)
        cp      'Y'                             ; !! 'N'=4E, 'Y'=59 -> "rrca; jr nc, ..." would work
        jr      nz, kb_4
        set     KBF_B_BEEP, (ix+kbd_flags)      ; click pending

.kb_4   call    sub_0_DC30
        jr      loc_0_DBB6
; ---------------------------------------------------------------------------

.kb_rls bit     KB_RELEASE, (ix+kbd_keyflags)
        jr      nz, kb_rl1

        ld      (ix+kbd_rlscnt), 3              ; initialize release
        ld      (ix+kbd_keyflags), K_ACTIVE|K_RELEASE
        jr      kb_prv

;       finish key release

.kb_rl1 dec     (ix+kbd_rlscnt)
        jr      nz, kb_prv
        ld      (ix+kbd_keyflags), 0            ; not active

;       bring back previous key

.kb_prv ld      a, (ix+kbd_prevkey)
        bit     KB_ACTIVE, (ix+kbd_prevflags)
        jr      nz, kb_pr1
        ld      a, -1                           ; no key

.kb_pr1 call    FindOtherKey                    ; see if any other key pressed
        jr      c, loc_0_DBB6
        bit     KB_ACTIVE, (ix+kbd_prevflags)
        jr      nz, loc_0_DBAF

        ld      b, (ix+kbd_rawkey)              ; previous = current
        ld      (ix+kbd_prevkey), b
        ld      b, (ix+kbd_keyflags)
        ld      (ix+kbd_prevflags), b
        ld      b, (ix+kbd_rlscnt)
        ld      (ix+kbd_prevrlscnt), b

.loc_0_DBAF
        ld      (ix+kbd_rawkey), a
        ld      (ix+kbd_keyflags), K_ACTIVE

.loc_0_DBB6
        bit     KB_ACTIVE, (ix+kbd_prevflags)
        jr      z, loc_0_DBE3
        ld      a, (ix+kbd_prevkey)
        call    KbdTestKey
        jr      nz, loc_0_DBDF
        bit     KB_RELEASE, (ix+kbd_prevflags)
        jr      nz, loc_0_DBD4

        ld      (ix+kbd_prevrlscnt), 3          ; initialize release
        ld      (ix+kbd_prevflags), K_ACTIVE|K_RELEASE
        jr      loc_0_DBE3

.loc_0_DBD4
        dec     (ix+kbd_prevrlscnt)
        jr      nz, loc_0_DBE3
        ld      (ix+kbd_prevflags), 0           ; not active
        jr      loc_0_DBE3
; ---------------------------------------------------------------------------

.loc_0_DBDF
        res     KB_RELEASE, (ix+kbd_prevflags)
.loc_0_DBE3
        or      a
.loc_0_DBE4
        ld      a, (iy+8)                       ; key mask
        or      (ix+kbd_keyflags)               ; current active
        or      (ix+kbd_prevflags)              ; prev active
        jr      nz, loc_0_DC24

        ld      a, (ix+kbd_flags)
        bit     KBF_B_KEY, a                    ; any key (not <> [])
        jr      nz, loc_0_DC1C
        and     KBF_DMND|KBF_SQR                ; <> & []
        jr      z, loc_0_DC1C                   ; neither down
        xor     KBF_DMND|KBF_SQR
        jr      z, loc_0_DC1C                   ; both down

        bit     KBF_B_DMND, a
        jr      nz, loc_0_DC08

        ld      a, $C8
        ld      b, $34                          ; <>
        jr      loc_0_DC10
.loc_0_DC08
        bit     KBF_B_SQR, a
        jr      nz, loc_0_DC10
        ld      a, $B8
        ld      b, $3E                          ; []

.loc_0_DC10
        ld      (ix+kbd_prevkey), b
        ld      (ix+kbd_prevflags), K_ACTIVE
        call    PutKey
        jr      loc_0_DC24
; ---------------------------------------------------------------------------

.loc_0_DC1C
        ld      a, (ix+kbd_flags)
        and     255-(KBF_DMND|KBF_KEY|KBF_SQR)  ; remove <> []
        ld      (ix+kbd_flags), a

.loc_0_DC24
        pop     hl                              ; purge stack
        pop     hl
        pop     hl
        pop     hl
        pop     hl

        pop     iy
        pop     hl
        pop     de
        pop     bc
        exx
        ret

; --------------- S U B R O U T I N E ---------------------------------------


.sub_0_DC30
        call    GetQual
        ld      d, a                            ; qualifiers in d
        ld      a, KMT_MATRIX
        call    GetKbdPtr
        ld      b, 0
        ld      c, (ix+kbd_rawkey)              ; current key
        add     hl, bc
        ld      a, (hl)                         ; internal keycode
        call    ProcessKey
        ret     c                               ; key canceled

.PutKey cp      ESC
        call    z, MaySetEsc                    ; set ESC flag if enabled

;       cp      $f0                             ; cursor key
        call    DeadKeys
        ret     c                               ; exit if key swallowed

        di                                      ; put key into buffer
        set     KBF_B_KEY,(ix+kbd_flags)
        call    BufWrite
        ei
        ret

; --------------- S U B R O U T I N E ---------------------------------------

.ProcessKey

        cp      $E8                             ; caps lock !! $A8 in OZ2.2/2.5 - $A8 used
        jr      nz, spec3                       ; in Norwegian OZ so needed changing

;       if <> or [] down force CAPS/caps, otherwise toggle

        set     7, (ix+kbd_repeatcnt)           ; disable repeat
        ld      a, (ix+kbd_flags)
        bit     QB_DIAMOND, d
        jr      z, spec1
        and     255-(KBF_CAPSE|KBF_CAPS)        ; force CAPS

.spec1  bit     QB_SQUARE, d
        jr      z, spec2
        or      KBF_CAPS                        ; force caps
        and     255-KBF_CAPSE

.spec2  xor     KBF_CAPSE                       ; toggle enable
        ld      (ix+kbd_flags), a
        call    DrawOZWd
        jr      SetShift

.spec3  cp      ESC
        jr      nz, ApplyQualifiers

        set     7, (ix+kbd_repeatcnt)           ; disable repeat
        ld      hl, ubIntStatus                 ; interrupt status
        ld      a, (ubCLIActiveCnt)
        ld      e, a
        ld      a, d
        and     3                               ; shift, <>
        jr      z, loc_0_DCA3
        inc     e
        dec     e
        jr      z, SetShift                     ; CLI byte counter=0

;       by pure coincidence (?) low 2 bits match exactly
 IF 1                                           ; !!
        or      (hl)
        ld      (hl), a

 ELSE                                           ; original OZ code
        srl     a                               ;0000 000d s
        jr      nc, loc_0_DC93
        set     0, (hl)                         ; shift
.loc_0_DC93
        jr      z, loc_0_DC97
        set     1, (hl)                         ; <>
.loc_0_DC97
 ENDIF
        dec     hl
        set     7, (hl)                         ; update OZ window

.SetShift
        push    hl
        ld      hl, KbdData+kbd_flags
        set     KBF_B_KEY, (hl)                 ; any (not <>/[]) key down
        pop     hl
        scf
        ret

; ---------------------------------------------------------------------------
;       In:     A = keymap table ID
;       Out:    HL = keymap table
;
;       AF....HL/....

.GetKbdPtr
        cp      KMT_DIAMOND                 ; =2
        jr      c, gkp_1

        ld      hl, KeymapTblPtrs
        add     a, l
        ld      l, a
        ld      l, (hl)
        jr      gkp_x

;       KMT_MATRIX (0) -> 00, KMT_SHIFT (1) -> 40

.gkp_1  rrca
        rrca
        ld      l, a

.gkp_x  ld      a, (km_page)
        ld      h, a
        ret

; ---------------------------------------------------------------------------
;       Generic pair-matching routine, ascending order tables
;       Faster than CPIR as we skip odd bytes and can exit prematurely
;       without finding match
;
;       in:     A=keycode, L=table
;       out:    Fc=0, A=newcode         translated
;               Fc=1, A=in(A)           not translated
;
;       ...CDE.. IXIY
;       AFB...HL ....

.TranslateTable                                 ; translate using table L

        push    af
        ld      a, l
        call    GetKbdPtr
        pop     af

.TranslateKey
        ld      b, (hl)                         ; table length
        inc     b                               ; take care of empty table
        jr      tr_s
.tr_l   inc     hl
        cp      (hl)
        ret     c                               ; entries sorted, shortcut false
        inc     hl
        jr      z, tr_ok
.tr_s   djnz    tr_l
        scf
        ret
.tr_ok  ld      a, (hl)                         ; get translated char, exit with Fc=0
        ret

; ---------------------------------------------------------------------------

.loc_0_DCA3
        ld      a, ESC

;       Handle qualifier translations
;
;       Fc=0, A=outchar if no error
;       Fc=1, ignore key


.ApplyQualifiers
        call    SpecInternal                    ; enter/tab/del/menu/index/help or cursor key
        ret     nc                              ; done

;       A=upper(A), Fc=0 : IsAlpha()

        ld      c, a                            ; remember key
        and     $df                             ; uppercase
        cp      'Z'+1
        jr      nc, not_alpha
        cp      'A'
        jr      nc, is_alpha

.not_alpha
        ld      a, c                            ; restore key
        scf                                     ; not alpha
.is_alpha
        bit     QB_DIAMOND, d
        jr      z, shift

; do <> translation

        ld      l, KMT_DIAMOND
        jr      c, TranslateTable               ; non-alpha, use table
        and     $1f                             ; otherwise A-Z = $01-$1A
        ret

.Shift  bit     QB_SHIFT, d
        jr      z, square

; do shift translation

        jr      c, Shift_non_alpha

; shift alpha

        push    af
        xor     $20                             ; swap case
        ex      af, af'                         ; in a
        pop     af

.DoShiftCAPS
        inc     b
        ret     z                               ; external call if b=-1

        bit     KBF_B_CAPSE, (ix+kbd_flags)     ; is caps or CAPS ?
        ret     z                               ;
        bit     KBF_B_CAPS, (ix+kbd_flags)      ; is CAPS enabled ?
        ret     NZ                              ; do nothing if caps
        ex      af, af'
        ret

; shift non alpha

.Shift_non_alpha
        call    IsCapsable
        ret     nc                              ; do nothing (it is capsable and caps is enabled with shift pressed)

.DoCapsNonAlpha
        ld      l, KMT_SHIFT
        call    TranslateTable                  ; non-alpha, use table
        ret     nc

.IsForeignKey
; test if A is a foreign key
;   Fc=1 if $00-$A0, $A4-$B8, $C0-$C8, $D0-$D8, $E0-$E8 (not a foreign key)
;   Fc=0 if $A1-$A3, $B9-$BF, $C9-$CF, $D9-$DF, $E9-$FF (is a foreign key)
;
; Fix for OZ FI : now A1-AF is foreign, B0-B8 is system
;

        push    af
        ex      af, af'
        pop     af
        cp      $0A1
        ret     c
        cp      $B0                             ; cp $0A4 in previous version
        ccf
        jr      nc, ifk_nc

        cp      $0B9
        ret     c
        cp      $0C0
        ccf
        jr      nc, ifk_nc

        cp      $0C9
        ret     c
        cp      $0D0
        ccf
        jr      nc, ifk_nc

        cp      $0D9
        ret     c
        cp      $0E0
        jr      c, ifk_nc

        cp      $0E9
        ret     c
        cp      $0F0
        ccf
        ret     c
.ifk_nc
        cp      a
        ret

.square bit     QB_SQUARE, d
        jr      z, NoQual                       ; No qualifier

;       do [] translation

        ld      l, KMT_SQUARE
        jp      c, TranslateTable               ; non-alpha, use table
        or      $80                             ; otherwise A-Z = $81-$9A
        and     $9f
        ret

; in case of called from the keyboard
; apply caps/CAPS even if there is no qualifiers

.NoQual inc     b
        jr      z, qend                         ; B was -1, external call

        call    IsCapsable
        jr      nc,DoCapsNonAlpha
        bit     KBF_B_CAPS, (ix+kbd_flags)      ; is caps or CAPS ?
        jr      nz, qend                        ; do nothing it is caps

        call    IsForeignKey
        or      a                               ; fc=0
        bit     KBF_B_CAPSE, (ix+kbd_flags)     ; is CAPS enabled ?
        ret     nz
.qend
        ld a,c                                  ; restore original key
        or      a
        ret

.IsCapsable
        bit     KBF_B_CAPSE, (ix+kbd_flags)
        scf
        ret     z
        push    bc
        push    af
        ld      a,KMT_Shift                     ; is capsable
        call    GetKbdPtr                       ; hl is now start of the shift table
        pop     af
        ld      b,0
        ld      c,(hl)                          ; get length
        sla     c                               ; and multiply by 2
        inc     hl                              ; start of the table
        cpir                                    ; search if entry is in the table
        pop     bc
        scf
        ret     nz                              ; ret with Fc=1, not found
        or      a                               ; Fc=0 found
        ret

;       Dead-key handling
;
;       in:     A=keycode
;       out:    Fc=0, A=newcode         wasn't dead key or was translated
;               Fc=1                    swallowed, ignore key
;
;       AF.CD.HL/....


.DeadKeys
;        ret
        ld      c, a                            ; save key

        ld      a, KMT_DEADKEY
        call    GetKbdPtr

        ld      a, (km_deadsub)                 ; deadkey active?
        or      a
        jr      z, d_not

;       we were prefixed, try to find the key
;       we check cancelation later, so we can handle things like ^^ here

        push    hl                              ; remember dead key table
        ld      l, a                            ; go to subtable
        ld      a, c                            ; translate this key
        call    TranslateKey
        pop     hl
        jr      nc, dead_tr                     ; return translated key

;       check for cancelation with same key or del

        cp      (ix+kbd_lastkey)
        jr      z, d_cancel
        cp      $e3
        jr      z, d_cancel

;       we were not prefixed or key wasn't found, check if this is dead key

.d_not  ld      a, c
        ld      (ix+kbd_lastkey), a
        call    TranslateKey                    ; find key in deadkey table
        jr      c, dead_not

;       was deadkey, remember and swallow - but only if not in [] or <> sequence

        ld      l, a

        ld      a, (ubSysFlags1)                ; if [] or <> then cancel it
        and     SF1_OZDMND|SF1_OZSQUARE         ; $30
        ld      a, IN_SQU                       ; ($b8) by sending keycode for []
        jr      nz, dead_tr

        ld      a, (hl)                         ; get char
        ld      (km_deadchar), a                ; for OZ window ($DE = ^)
        inc     hl
        ld      a, l
        jr      d_x                             ; store subtable ptr

;       was translated

.dead_tr
        ld      c, a

;       was not special, clear dead-key and return key

.dead_not
        call    d_cancel
        ld      a, c
        or      a
        ret

.d_cancel
        xor     a                               ; cancel deadkey
        ld      (km_deadchar),a                 ; will be a space char in OZ window
.d_x    ld      (km_deadsub), a

        push    bc
        call    DrawOZWd
        pop     bc

        scf
        ret

; ---------------------------------------------------------------------------
;       Test key status
;
;       In:     A = rawkey
;       Out:    Fz= 0 if key not pressed
;               Fz= 1 if key pressed
;
;       AFBC..../....

.KbdTestKey
        push    af
        rrca
        rrca
        rrca
        call    RdKeyRowA                       ; get row (A/8)
        ld      c, a
        pop     af

        and     7
        ld      b, a
        inc     b
        ld      a, $80
.tk1    rlca                                    ; rotate bit into correct position
        djnz    tk1

        and     c                               ; test key
        ret

; ---------------------------------------------------------------------------
;
;       Return keys on given row
;
;       In:     A=row number
;       Out:    Fc=0, A=keyrow
;
;       AFBC..../....

.RdKeyRowA
        push    iy
        and     7
        ld      c, a
        ld      b, 0
        add     iy,bc
        ld      a, (iy+0)
        pop     iy
        ret

; ---------------------------------------------------------------------------
;       Return qualifier status
;
;       Out: A=Qbits (0-shift, 1-diamond, 2-square)
;
;       AF..D.../....

.GetQual
        ld      a, (iy+6)
        and     $50                             ; .  sl .  <>  . . . .
        rlca                                    ; sl .  <> .   . . . .
        ld      d, a
        ld      a, (iy+7)
        and     $c0                             ; sr [] .  .   . . . .
        or      d                               ; sh [] <> .   . . . .

;       we want them in . . . . . [] <> sh

        rla                                     ; Fc=sh
        adc     a, $1f                          ; sets bit 5 if carry was set
        rlca
        rlca
        rlca                                    ; we don't care about extra bits, so skip "and 7"
        ret

; ---------------------------------------------------------------------------
;       Check key matrix for some other key, also update qualifier flags
;
;       In:     A=rawkey
;       Out:    Fc=0, A=rawkey if other key found
;               Fc=1 otherwise

.FindOtherKey
        push    ix
        ld      d, a
        ld      a, (iy+8)
        or      a
        jr      z, fok8                         ; no keys, return with carry

        ld      ix, KbdMaskTable+3
        ld      l, $38                          ; loops 38 to 0 step -8

        ld      bc, $800
        ld      e, b

.fok1   push    bc
        ld      a, b
        cp      6
        jr      c, fok12
        dec     ix

.fok12  dec     a
        call    RdKeyRowA
        pop     bc
        ld      h, a

        cp      (ix+3)                          ; 0,sh-l,sh-r
        jr      z, fok2
        inc     c                               ; we have something else than just shift

.fok2   and     (ix+3)                          ; is shift down
        call    nz, SetShift                    ; set shift flag

        ld      a, h
        and     (ix+6)                          ; is [] or <> down?
        jr      z, fok3

        ld      a, (KbdData+kbd_flags)         ; set flag
        or      (ix+6)
        ld      (KbdData+kbd_flags), a

.fok3   ld      a, h                            ; any non-qualifier key down?
        and     (ix+0)
        jr      z, fok7                         ; no

        ld      h, a                            ; key mask in shift register
        ld      a, l                            ; raw keycode
.fok4   srl     h
        jr      c, fok6                         ; key found
        jr      z, fok7                         ; no more keys
.fok5   inc     a                               ; bump key
        jr      fok4
.fok6   cp      d
        jr      z,fok5                          ; this was the current key

        or      a                               ; Fc=0
        jr      fok9

.fok7   sbc     hl, de                          ; l=l-8
        djnz    fok1

        inc     c
        dec     c
        call    z,  SwitchOff

.fok8   scf

.fok9   pop     ix
        ret

.KbdMaskTable
        defb    $FF,$AF,$3F
        defb    $00,$40,$80
        defb    $00,KBF_DMND,KBF_SQR


; ---------------------------------------------------------------------------
.RdKeymatrix
        push    iy
        pop     hl

        ld      bc, $FEB2                       ; column | port
        ld      d, 0
.rkm1   in      a, (c)
        cpl                                     ; active high
        ld      (hl), a                         ; store row
        inc     hl
        or      d
        ld      d, a                            ; update column mask
        rlc     b
        jr      c, rkm1                         ; loop 8 rows
        ld      (hl), d                         ; store colum mask

        neg
        and     d
        xor     d
        ret     z                               ; only one column active - Fz=1 Fc=0

;       outer loop: find row with multiple keys down

        push    iy
        pop     hl
        ld      b, 7                            ; do 7 rows

.rkm2   ld      a, (hl)
        inc     hl
        ld      d, a
        neg
        and     d
        xor     d
        jr      z, rkm5                         ; no multiple keys

        ld      c, b                            ; remember count
        push    hl

;       inner loop: find another row with common multiple keys down
;       changed to check only remaining B rows, that halves processing time

.rkm3   ld      a, (hl)
        inc     hl
        and     d
        ld      e, a                            ; common keys in two rows
        neg
        and     e
        xor     e
        jr      nz, rkm6                        ; multiple keys in both rows
.rkm4   djnz    rkm3                            ; repeat inner loop

        pop     hl
        ld      b, c

.rkm5   djnz    rkm2                            ; repeat outer loop

        ret                                     ; Fc=0

.rkm6   pop     hl                              ; Fc=1 multiple keys in multiple rows
        ccf
        ret

; ---------------------------------------------------------------------------
;       Handle enter/tab/del/menu/index/help and cursor keys internally
;
;       AF.C..../....

.SpecInternal

        ld      c, 4
        cp      $fc
        jr      nc, si_1                        ; cursor key
        ld      c, $10
        cp      $e1                             ; this code relies on fact that
        ret     c                               ; $e4 (internal ESC) is unused
        cp      $e8
        ccf
        ret     c
.si_1   bit     QB_DIAMOND, d
        jr      nz, si_dm
        bit     QB_SHIFT, d
        jr      nz, si_sh
        bit     QB_SQUARE, d
        ret     z                               ;    e1-e7 fc-ff
.si_sq  sub     c                               ; [] b1-b7 f0-f3
.si_dm  sub     c                               ; <> c1-c7 f4-f7
.si_sh  sub     c                               ; sh d1-d7 f8-fb
        ret

; ---------------------------------------------------------------------------
; init ram vars of keyboard code
;
.InitKbdPtrs
        ld      (KeymapTblPtrs), hl             ; store +0=bank, +1=page   ($01E0)
                                                ; $page00 is matrix, $page40 is shift table

        ld      de, KeymapTblPtrs+KMT_DIAMOND   ; +2
        ld      l, $40                          ; ShiftTable start=length of shift table
        ld      b, KMT_DEADKEY-1                ; 4-1=3 loops, (diamondtable, squaretable and deadtable)
.ikp_1  ld      a, (hl)                         ; table size
        sll     a                               ; *2+1
        add     a, l                            ; skip table
        ld      l, a
        ld      (de), a                         ; and store pointer
        inc     de
        djnz    ikp_1
        ret        
    

