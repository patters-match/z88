; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $1b0d
;
; $Id$
; -----------------------------------------------------------------------------

        Module Kbd

        org     $db0d                           ; 1045 bytes

        include "all.def"
        include "sysvar.def"
        include "bank7.def"

;       !! do not modify this code
;       !! it's all rewritten already

xdef    KbdMain
xdef    ApplyQualifiers
xdef    DoLocalized

xref    MS2BankK1
xref    UpdateRnd
xref    MS2BankA
xref    MaySetEsc
xref    BufWriteC
xref    DrawOZwd
xref    SwitchOff

.KbdMain
        ld      a, (BLSC_SR2)
        push    af
        call    MS2BankK1

        exx
        push    bc
        push    de
        push    hl
        push    iy
        push    hl
        push    hl
        push    hl
        push    hl
        push    hl
        ld      iy, 0
        add     iy, sp
        ld      ix, KbdData                     ; keyboard data
        call    RdKbdMatrix

        jp      c, loc_DC12

        bit     0, (ix+kbd_keyflags)            ; key active
        jp      z, loc_DBB5

        ld      a, (ix+kbd_rawkey)
        call    KbdTestKey

        jr      z, loc_DB9C                     ; has been released

        bit     1, (ix+kbd_keyflags)            ; hold
        res     2, (ix+kbd_keyflags)            ; release
        jr      nz, loc_DB53

        set     1, (ix+kbd_keyflags)            ; hold
        call    UpdateRnd

        ld      a, 60
        jr      loc_DB89


.loc_DB53                                       
        ld      a, (ix+kbd_rawkey)
        call    FindOtherKey

        jr      c, loc_DB75

        bit     0, (ix+kbd_prevflags)           ; active
        jr      nz, loc_DB75

        ld      b, (ix+kbd_rawkey)
        ld      (ix+kbd_prevkey), b
        ld      (ix+kbd_prevflags), 1
        ld      (ix+kbd_rawkey), a
        ld      (ix+kbd_keyflags), 1
        jp      loc_DC11


.loc_DB75                                       
        ld      a, (ubRepeat)                   ; repeat
        or      a
        jr      z, loc_DBE4

        bit     7, (ix+kbd_repeatcnt)
        jr      nz, loc_DBE4

        dec     (ix+kbd_repeatcnt)
        jr      nz, loc_DBE4

        ld      a, (ubRepeat)                   ; repeat

.loc_DB89                                       
        ld      (ix+kbd_repeatcnt), a
        ld      a, (cKeyclick)                  ; keyclick
        cp      'Y'
        jr      nz, loc_DB97

        set     KBF_B_BEEP, (ix+kbd_flags)

.loc_DB97                                       
        call    loc_DC61

        jr      loc_DBE4


.loc_DB9C                                       
        bit     2, (ix+kbd_keyflags)
        jr      nz, loc_DBAC

        ld      (ix+kbd_rlscnt), 3
        ld      (ix+kbd_keyflags), 5
        jr      loc_DBB5


.loc_DBAC                                       
        dec     (ix+kbd_rlscnt)
        jr      nz, loc_DBB5

        ld      (ix+kbd_keyflags), 0

.loc_DBB5                                       
        ld      a, (ix+kbd_prevkey)
        bit     0, (ix+kbd_prevflags)           ; active
        jr      nz, loc_DBC0

        ld      a, $0FF

.loc_DBC0                                       
        call    FindOtherKey

        jr      c, loc_DBE4

        bit     0, (ix+kbd_prevflags)
        jr      nz, loc_DBDD

        ld      b, (ix+kbd_rawkey)
        ld      (ix+kbd_prevkey), b
        ld      b, (ix+kbd_keyflags)
        ld      (ix+kbd_prevflags), b
        ld      b, (ix+kbd_rlscnt)
        ld      (ix+kbd_prevrlscnt), b

.loc_DBDD                                       
        ld      (ix+kbd_rawkey), a
        ld      (ix+kbd_keyflags), 1

.loc_DBE4                                       
                                                
        bit     0, (ix+kbd_prevflags)
        jr      z, loc_DC11

        ld      a, (ix+kbd_prevkey)
        call    KbdTestKey

        jr      nz, loc_DC0D

        bit     2, (ix+kbd_prevflags)
        jr      nz, loc_DC02

        ld      (ix+kbd_prevrlscnt), 3
        ld      (ix+kbd_prevflags), 5
        jr      loc_DC0B


.loc_DC02                                       
        dec     (ix+kbd_prevrlscnt)
        jr      nz, loc_DC0B

        ld      (ix+kbd_prevflags), 0

.loc_DC0B                                       
        jr      loc_DC11


.loc_DC0D                                       
        res     2, (ix+kbd_prevflags)

.loc_DC11                                       
        or      a

.loc_DC12                                       
        ld      a, (iy+kbd_lastkey)
        or      (ix+kbd_keyflags)
        or      (ix+kbd_prevflags)
        jr      nz, loc_DC52

        ld      a, (ix+kbd_flags)
        bit     KBF_B_KEY, a
        jr      nz, loc_DC4A

        and     $50
        jr      z, loc_DC4A

        xor     $50
        jr      z, loc_DC4A

        bit     KBF_B_DMND, a
        jr      nz, loc_DC36

        ld      a, IN_DIA
        ld      b, $34
        jr      loc_DC3E


.loc_DC36                                       
        bit     KBF_B_SQR, a
        jr      nz, loc_DC4A

        ld      a, IN_SQU
        ld      b, $3E

.loc_DC3E                                       
        ld      (ix+kbd_prevkey), b
        ld      (ix+kbd_prevflags), 1
        call    loc_DC73

        jr      loc_DC52


.loc_DC4A                                       
                                                
        ld      a, (ix+kbd_flags)
        and     $8F
        ld      (ix+kbd_flags), a

.loc_DC52                                       
        pop     hl
        pop     hl
        pop     hl
        pop     hl
        pop     hl
        pop     iy
        pop     hl
        pop     de
        pop     bc
        exx
        pop     af
        jp      MS2BankA


.loc_DC61                                       
        call    GetQual

        ld      d, a
        ld      c, (ix+kbd_rawkey)
        ld      b, 0
        ld      hl, Key2Code
        add     hl, bc
        ld      a, (hl)
        call    loc_DC86

        ret     c

.loc_DC73                                       
        cp      IN_ESC
        call    z, MaySetEsc

        call    KbdDeadKeys

        ret     c
        di
        set     KBF_B_KEY, (ix+kbd_flags)
        call    BufWriteC

        ei
        ret


.loc_DC86                                       
        cp      IN_LOCK
        jr      nz, loc_DCA9

        set     7, (ix+kbd_repeatcnt)
        ld      a, (ix+kbd_flags)
        bit     1, d                            ; <>
        jr      z, loc_DC97

        and     $0FC                            ; force normal CAPS

.loc_DC97                                       
        bit     2, d                            ; []
        jr      z, loc_DC9F

        or      KBF_CAPS                        ; force inverse caps
        and     $0FE

.loc_DC9F                                       
        xor     KBF_CAPSE                       ; toggle CAPS enable
        ld      (ix+kbd_flags), a
        call    DrawOZwd

        jr      loc_DCCE


.loc_DCA9                                       
        cp      IN_ESC
        jr      nz, ApplyQualifiers

        set     7, (ix+kbd_repeatcnt)
        ld      hl, ubIntStatus
        ld      a, (ubCLIActiveCnt)
        ld      e, a
        ld      a, d
        and     3
        jr      z, loc_DCD7

        inc     e
        dec     e
        jr      z, loc_DCCE

        srl     a
        jr      nc, loc_DCC7

        set     IST_B_CLISHIFT, (hl)

.loc_DCC7                                       
        jr      z, loc_DCCB

        set     IST_B_CLIDMND, (hl)

.loc_DCCB                                       
        dec     hl
        set     ITSK_B_OZWINDOW, (hl)

.loc_DCCE                                       
        push    hl
        ld      hl, ubKbdFlags
        set     KBF_B_KEY, (hl)
        pop     hl
        scf
        ret


.loc_DCD7                                       
        ld      a, IN_ESC

.ApplyQualifiers
        call    ToUpper

        bit     1, d
        jr      z, loc_DD00

        rla
        and     $3F
        rra
        ret     nc
        ld      a, c
        cp      IN_LFT
        jr      c, loc_DCEE

        sub     8
        ld      c, a
        ret


.loc_DCEE                                       
        ld      a, c
        ld      hl, DmndTable
        ld      bc, 34

.loc_DCF5                                       
        cpir
        scf
        ret     nz
        bit     0, c
        jr      z, loc_DCF5

        ld      a, (hl)
        or      a
        ret


.loc_DD00                                       
        bit     0, d
        jr      z, loc_DD39

        jr      c, loc_DD19

        push    af
        xor     $20
        ex      af, af'
        pop     af

.loc_DD0B                                       
        inc     b
        ret     z                               ; external call, dont do caps logic
        bit     KBF_B_CAPS, (ix+kbd_flags)
        ret     z
        bit     KBF_B_CAPSE, (ix+kbd_flags)
        ret     z
        ex      af, af'
        ret


.loc_DD19                                       
        cp      IN_LFT
        jr      c, loc_DD21

        sub     4
        ld      c, a
        ret


.loc_DD21                                       
        ld      hl, ShiftTable
        ld      bc, 58
        cpir
        scf
        jr      nz, loc_DD33

        bit     0, c
        jr      z, loc_DD33

        ccf
        ld      a, (hl)
        ret


.loc_DD33                                       
        call    DoLocalized

        jr      nc, loc_DD0B

        ret


.loc_DD39                                       
        bit     2, d
        jr      z, loc_DD61

        rla
        and     $3F
        scf
        rra
        ret     nc
        ld      a, c
        cp      IN_LFT
        jr      c, loc_DD4C

        sub     $0C
        ld      c, a
        ret


.loc_DD4C                                       
        ld      hl, SqrTable
        ld      bc, 32

.loc_DD52                                       
        cpir
        scf
        ret     nz
        bit     0, c
        jr      z, loc_DD52

        ld      a, (hl)
        cp      $20
        ret     nc
        or      $80
        ret


.loc_DD61                                       
        inc     b
        jr      z, loc_DD6E                     ; external call, don't do localized

        call    DoLocalized

        bit     KBF_B_CAPSE, (ix+kbd_flags)
        scf
        ccf
        ret     nz

.loc_DD6E                                       
        ld      a, c
        or      a
        ret


.ToUpper                                        
        ld      c, a
        and     $0DF
        cp      '['                             ; Z+1
        jr      nc, loc_DD7B

        cp      'A'
        ret     nc

.loc_DD7B                                       
        ld      a, c
        scf
        ret


.DoLocalized                                    
        push    af
        ex      af, af'
        pop     af
        cp      $0A1
        ret     c
        cp      $0A4
        ccf
        jr      nc, loc_DDAF

        cp      $0B9
        ret     c
        cp      $0C0
        ccf
        jr      nc, loc_DDAF

        cp      $0C9
        ret     c
        cp      $0D0
        ccf
        jr      nc, loc_DDAF

        cp      $0D9
        ret     c
        cp      $0E0
        jr      c, loc_DDA7

        cp      $0E9
        ret     c
        cp      $0F0
        ccf
        ret     c

.loc_DDA7                                       
        xor     $30
        cp      $0E9
        ret     nc
        ex      af, af'
        or      a
        ret


.loc_DDAF                                       
        cp      a
        ret


.KbdRdRowA                                      
        push    iy
        and     7
        ld      c, a
        ld      b, 0
        add     iy, bc
        ld      a, (iy+0)
        pop     iy
        or      a
        ret


.KbdTestKey                                     
        push    af
        rrca
        rrca
        rrca
        call    KbdRdRowA

        ld      c, a
        pop     af
        call    GetBitA                         ; 1<<(A&7)

        and     c
        ret


.GetBitA                                        
        and     7
        ld      b, a
        inc     b
        ld      a, $80

.loc_DDD5                                       
        rlca
        djnz    loc_DDD5

        ret


.GetQual                                        
        ld      d, 0
        ld      a, (iy+6)
        bit     6, a
        jr      z, loc_DDE4

        set     0, d

.loc_DDE4                                       
        bit     4, a
        jr      z, loc_DDEA

        set     1, d

.loc_DDEA                                       
        ld      a, (iy+7)
        rlc     a
        jp      p, loc_DDF4

        set     2, d

.loc_DDF4                                       
        jr      nc, loc_DDF8

        set     0, d

.loc_DDF8                                       
        ld      a, d
        ret


.FindOtherKey                                   
        push    ix
        ld      d, a
        ld      a, (iy+8)
        or      a
        jr      z, loc_DE53

        ld      ix, byte_DE57+7
        ld      l, $38
        ld      e, 8
        ld      bc, $800

.loc_DE0E                                       
        push    bc
        ld      a, b
        dec     a
        call    KbdRdRowA

        pop     bc
        cp      (ix+8)
        jr      z, loc_DE1B

        inc     c

.loc_DE1B                                       
        ld      h, a
        and     (ix+8)
        call    nz, loc_DCCE

        ld      a, h
        and     (ix+$10)
        jr      z, loc_DE31

        ld      a, (ubKbdFlags)
        or      (ix+$10)
        ld      (ubKbdFlags), a

.loc_DE31                                       
        ld      a, h
        and     (ix+0)
        jr      z, loc_DE48

        ld      h, a
        ld      a, l

.loc_DE39                                       
        srl     h
        jr      c, loc_DE42

        jr      z, loc_DE48


.loc_DE3F                                       
        inc     a
        jr      loc_DE39


.loc_DE42                                       
        cp      d
        jr      z, loc_DE3F

        or      a
        jr      loc_DE54


.loc_DE48                                       
        sbc     hl, de
        dec     ix
        djnz    loc_DE0E

        inc     c
        dec     c
        call    z, SwitchOff


.loc_DE53                                       
        scf

.loc_DE54                                       
        pop     ix
        ret

.byte_DE57
        defb    $FF,$FF,$FF,$FF,$FF,$FF,$AF,$3F 
        defb    $00,$00,$00,$00,$00,$00,$40,$80
        defb    $00,$00,$00,$00,$00,$00,$10,$40

.RdKbdMatrix                                    
        push    iy
        pop     hl
        ld      b, $0FE
        ld      c, $0B2
        ld      d, 0

.loc_DE78                                       
        in      a, (c)
        cpl
        ld      (hl), a
        or      d
        ld      d, a
        inc     hl
        rlc     b
        jr      c, loc_DE78

        ld      (hl), d
        ld      a, d
        neg
        and     d
        xor     d
        ret     z
        push    iy
        pop     hl
        ld      b, 8

.loc_DE8F                                       
        ld      e, l
        ld      d, (hl)
        ld      a, d
        neg
        and     d
        xor     d
        jr      z, loc_DEB1

        push    de
        exx
        pop     de
        push    iy
        pop     hl
        ld      b, 8

.loc_DEA0                                       
        ld      a, e
        cp      l
        jr      z, loc_DEAD

        ld      a, (hl)
        and     d
        ld      c, a
        neg
        and     c
        xor     c
        ccf
        ret     nz

.loc_DEAD                                       
        inc     hl
        djnz    loc_DEA0

        exx

.loc_DEB1                                       
        inc     hl
        djnz    loc_DE8F

        or      a
        ret

; End of function KbdMain

.ShiftTable
        defb    $31,$21,$32,$40,$33,$23,$34,$24 
        defb    $35,$25,$36,$5E,$37,$26,$38,$2A
        defb    $39,$28,$30,$29,$3B,$3A,$27,$22
        defb    $2C,$3C,$2E,$3E,$2F,$3F,$2D,$5F
        defb    $5B,$7B,$5C,$7C,$5D,$7D,$A3,$7E
        defb    $3D,$2B,$E2,$D2,$1B,$D4,$E1,$D1
        defb    $E3,$D3,$E5,$D5,$E6,$D6,$E7,$D7
        defb    $20,$D0
.DmndTable
        defb $E2,$C2,$1B,$C4,$E1,$C1,$E3,$C3 
        defb $E5,$C5,$E6,$C6,$E7,$C7,$20,$A0
        defb $27,$60
.SqrTable
        defb $5F,$1F,$2D,$1F,$3D,0,$2B,0 
        defb $5B,$1B,$5C,$1C,$5D,$1D,$A3,$1E
        defb $E2,$B2,$1B,$B4,$E1,$B1,$E3,$B3
        defb $E5,$B5,$E6,$B6,$E7,$B7,$20,$B0
