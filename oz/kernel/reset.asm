; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $007b
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Reset


        include "blink.def"
        include "director.def"
        include "memory.def"
        include "screen.def"
        include "serintfc.def"
        include "sysvar.def"
        include "time.def"



        org     $c07b                           ; 134 bytes

xdef    Bootstrap2
xdef    Bootstrap3
xdef    ExpandMachine
xdef    Reset1

;       bank 0

xref    Chk128KB
xref    FirstFreeRAM
xref    InitBufKBD_RX_TX
xref    InitRAM
xref    IntSecond
xref    KPrint
xref    LowRAMcode
xref    LowRAMcode_e
xref    MarkSwapRAM
xref    MarkSystemRAM
xref    MountAllRAM
xref    MS1BankA
xref    MS2BankK1
xref    OSSp_PAGfi
xref    ResetHandles
xref    ResetTimeout
xref    RstRdPanelAttrs
xref    TimeReset
xref    VerifySlotType

;       ----

;       code in ROM, SP points to ROM too

.Reset1
        pop     de                              ; return to Bootstrap2
        ld      de, 1<<8|$3f                    ; check slot 1, max size 63 banks
        call    VerifySlotType                  ; !! 'jp' here, aliminates pop above

.Bootstrap2
        bit     1, d                            ; check for bootable ROM in slot 1
        jr      z, Bootstrap3                   ; not application ROM? skip
        ld      a, ($bffd)                      ; subtype
        cp      'Z'
        jp      z, $bff8                        ; enter ROM

.Bootstrap3
        ld      a, OZBANK_LO
        out     (BL_SR2), a

        xor     a
        ex      af, af'                         ; interrupt status
        bit     BB_STAFLAPOPEN, a
        ld      a, $21
        jr      nz, rst2_1                      ; flap? hard reset

        out     (BL_SR1), a                     ; b21 into S1
        ld      hl, ($4000)
        ld      bc, $A55A
        or      a
        sbc     hl, bc
        jr      nz, rst2_1                      ; not tagged? hard reset

        ex      af, af'                         ; soft reset - a' = $FF, fc'=1
        cpl
        scf
        ex      af, af'
        dec     a                               ; only clear b20

.rst2_1
        out     (BL_SR1), a                     ; bind A into S1
        ld      bc, $3FFF                       ; fill bank with 00
        ld      de, $4001
        ld      hl, $4000
        ld      (hl), 0
        ldir
        dec     a
        cp      $20
        jr      z, rst2_1                       ; loop if hard reset

        ex      af, af'
        ld      ($4000+ubResetType), a

;       init BLINK

        ld      hl, InitData
.rst2_2
        ld      c, (hl)                         ; port
        inc     hl
        inc     c
        dec     c
        jr      z, rst2_3                       ; end of init data
        ld      a, (hl)                         ; data byte
        inc     hl
        ld      b, 0
        out     (c), a                          ; write blink
        ld      b, $40+BLSC_PAGE                ; softcopy in S1
        ld      (bc), a
        jr      rst2_2

;       copy low RAM code

.rst2_3
        ld      bc, ?LowRAMcode_e-LowRAMcode
        ld      de, $4000                       ; destination b20 in S1
        ldir
        ld      a, 1
        ld      ($4000+ubAppCallLevel), a
        ld      a, BM_COMRAMS|BM_COMLCDON
        ld      ($4000+BLSC_COM), a
        out     (BL_COM), a
        ld      sp, $2000                       ; init stack
        ld      b, NUMHANDLES                   ; !! move this ld into ResetHandles
        call    ResetHandles

;       init screen file for unexpanded machine

        ld      b, $21
        ld      h, $22
        ld      a, 1
        OZ      OS_Sci                          ; LORES0 at 21:2200-22FF
        ld      b, 7
        ld      h, 0
        inc     a
        OZ      OS_Sci                          ; LORES1 at 07:0000-07FF
        ld      b, $21
        ld      h, $20
        inc     a
        OZ      OS_Sci                          ; HIRES0 at 21:2200-23FF
        ld      b, 7
        ld      h, 8
        inc     a
        OZ      OS_Sci                          ; HIRES1 at 07:0800-0FFF
        ld      b, $20
        ld      h, SBF_PAGE
        inc     a
        OZ      OS_Sci                          ; SBF at 20:7800-7FFF - this inits memory

        call    ResetTimeout
        call    InitBufKBD_RX_TX

        ld      a, (ubResetType)                ; print reset string
        or      a
        jr      nz, rst2_4

        call    KPrint
        defm    1,"B"
        defm    "HARD",0
        jr      rst2_5

.rst2_4
        call    KPrint
        defm    1,"T"
        defm    "SOFT",0

.rst2_5
        call    KPrint
        defm    " RESET ...",0

        ld      a, MM_S2|MM_MUL|MM_FIX
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool, A=mask
.rst2_6
        jr      c, rst2_6                       ; crash if no memory

        ld      (pFsMemPool), ix                ; filesystem pool

        call    InitRAM
        ld      d, $20
        ld      bc, $10
        call    MarkSystemRAM                   ; b20, 0000-0fff - system variables
        ld      d, $20
        ld      bc, $1008
        call    MarkSwapRAM                     ; b20, 1000-17ff - swap RAM
        ld      d, $20
        ld      bc, $1808
        call    MarkSystemRAM                   ; b20, 1800-1fff - stack
        ld      d, $20
        ld      bc, $2020
        call    MarkSwapRAM                     ; b20, 2000-3fff - 8KB for bad apps
        ld      d, $21
        ld      bc, $3808
        call    MarkSystemRAM                   ; b21, 3800-3fff - SBF
        ld      d, $21
        ld      bc, $2003
        call    MarkSystemRAM                   ; b21, 2000-22ff - Hires0+Lores0

        call    ExpandMachine                   ; move Lores0/Hires0 and mark more swap RAM if expanded

        call    MS2BankK1                       ; bind in more code
        call    RstRdPanelAttrs

        call    TimeReset
        call    MountAllRAM

        ld      b, $21
        ld      h, SBF_PAGE
        ld      a, SC_SBR
        OZ      OS_Sci                          ; SBF at 21:7800-7FFF

        ld      bc, SerRXHandle
        ld      de, SerTXHandle
        ld      l, SI_HRD
        OZ      OS_Si                           ; hard reset serial interface

        call    OSSp_PAGfi
        ei

.rst_5
        ld      b, 0                            ; time to enter new Index process!
        ld      ix, 1
        OZ      OS_Ent                          ; enter an application
        jr      rst_5


;	----

.ExpandMachine
        call    Chk128KB
        ret     c                               ; not expanded? exit

        call    FirstFreeRAM                    ; b21/b40 for un-/expanded machine
        add     a, 3                            ; b24/b43
        push    af
        pop     de                              ; D=bank !! ld d,a

        push    de
        ld      bc, $0A
        call    MarkSystemRAM                   ; b24/b43, 0000-09ff - Hires0+Lores0

        pop     bc                              ; B=bank !! use C to keep bank through Os_Sci
        push    bc
        ld      h, 8
        ld      a, SC_LR0
        OZ      OS_Sci                          ; LORES0

        pop     bc                              ; B=bank
        push    bc
        ld      h, 0
        ld      a, SC_HR0
        OZ      OS_Sci                          ; HIRES0

        pop     de                              ; D=bank
        dec     d
        dec     d
        ld      bc, $80
        jp      MarkSwapRAM                     ; b22/b41, 0000-7fff - 32KB more for bad apps

; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d5a5
;
; $Id$
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d816
;
; $Id$
; -----------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d564
;
; $Id$
; -----------------------------------------------------------------------------

.TimeReset
        ld      a, $21                          ; bind in b21

        call    MS1BankA
        ld      a, (ubResetType)
        or      a
        call    z, SetInitialTime               ; hard reset, init system clock
        jr      z, tr_2                         ; hard reset? skip

        ld      hl, $4000+$A2                   ; use timer @ A2 or A7
        ld      a, ($4000+$A0)                  ; depending of bit 0 of A0
        rrca
        jr      nc, tr_1
        ld      l, $A7

.tr_1
        ld      c, (hl)                         ; ld bhlc, (hl)
        inc     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        ld      b, (hl)
        ex      de, hl

        ld      a, 1                            ; update base time
        OZ      GN_Msc

.tr_2
        jp      IntSecond


.SetInitialTime
        push    af
        ld      de, 1992
 IF     OZ40001=0
        ld      bc, 8<<8|3                      ; August 3rd
 ELSE
        ld      bc, 3<<8|15                     ; March 15th
 ENDIF
        OZ      GN_Dei                          ; convert to internal format
        ld      hl, 2                           ; date in ABC
        OZ      GN_Pmd                          ; set machine date
        xor     a
        ld      b, a
        ld      c, a
        OZ      GN_Pmt                          ; set clock to midnight
        pop     af
        ret

; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1eaa9
;
; $Id$
; -----------------------------------------------------------------------------

.InitData
        defb    BL_SR2, OZBANK_LO
        defb    BL_TMK, BM_TACKTICK|BM_TACKSEC|BM_TACKMIN
        defb    BL_INT, BM_INTFLAP|BM_INTBTL|BM_INTTIME|BM_INTGINT
        defb    BL_TACK, BM_TMKTICK|BM_TMKSEC|BM_TMKMIN
        defb    BL_ACK, BM_ACKA19|BM_ACKFLAP|BM_ACKBTL|BM_ACKKEY
        defb    BL_EPR, 0                       ; reset EPROM port
        defb    0
