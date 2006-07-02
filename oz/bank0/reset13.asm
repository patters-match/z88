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

xref    Chk128KB                                ; bank0/resetx.asm
xref    FirstFreeRAM                            ; bank0/resetx.asm
xref    InitRAM                                 ; bank0/memory.asm
xref    MarkSwapRAM                             ; bank0/memory.asm
xref    MarkSystemRAM                           ; bank0/memory.asm
xref    VerifySlotType                          ; bank0/memory.asm
xref    MS2BankK1                               ; bank0/misc5.asm
xref    InitKbdPtrs                             ; bank0/kbd.asm

xref    Reset5                                  ; bank7/reset5.asm
xref    RstRdPanelAttrs                         ; bank7/nqsp.asm
xref    KeymapTable                             ; bank7/keymap.asm

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
        ld      hl, KeymapTable | $07           ; page | bank
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

        ld      h, LORES0_PAGE_EXP              ; 8
        ld      a, SC_LR0
        OZ      OS_Sci                          ; LORES0 at $xx 0800

        ld      b,c
        ld      h, HIRES0_PAGE_EXP              ; 0
        ld      a, SC_HR0
        OZ      OS_Sci                          ; HIRES0 at $xx 0000

        ld      d,c
        dec     d
        dec     d
        ld      bc, $80
        jp      MarkSwapRAM                     ; b22/b41, 0000-7fff - 32KB more for bad apps
