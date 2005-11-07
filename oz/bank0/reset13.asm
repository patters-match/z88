; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $007b
;
; $Id$
; -----------------------------------------------------------------------------

        Module  Reset13

        include "blink.def"
        include "screen.def"
        include "sysvar.def"

xdef    Reset3
xdef    ExpandMachine

;       bank 0

xref    Chk128KB
xref    FirstFreeRAM
xref    InitRAM
xref    MarkSwapRAM
xref    MarkSystemRAM
xref    MS2BankK1
xref    Reset5
xref    VerifySlotType
xref    InitKbdPtrs

;       bank 7

xref    RstRdPanelAttrs


.Reset3
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
        call    MS2BankK1

        ld      hl, $b307                       ; page | bank
        call    InitKbdPtrs
        jp      Reset5                          ; Reset5

.ExpandMachine
        call    Chk128KB
        ret     c                               ; not expanded? exit

        call    FirstFreeRAM                    ; b21/b40 for un-/expanded machine
        add     a, 3                            ; b24/b43
        ld      d,a
        push    de
        ld      bc, $0A
        call    MarkSystemRAM                   ; b24/b43, 0000-09ff - Hires0+Lores0

        pop     bc                              ; B=bank, use C to keep bank through Os_Sci
        ld      c,b

        ld      h, 8
        ld      a, SC_LR0
        OZ      OS_Sci                          ; LORES0

        ld      b,c
        ld      h, 0
        ld      a, SC_HR0
        OZ      OS_Sci                          ; HIRES0

        ld      d,c
        dec     d
        dec     d
        ld      bc, $80
        jp      MarkSwapRAM                     ; b22/b41, 0000-7fff - 32KB more for bad apps
