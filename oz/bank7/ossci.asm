; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d500
;
; $Id$
; -----------------------------------------------------------------------------

        Module OsSci

        org $9500                               ; 100 bytes

        include "all.def"
        include "sysvar.def"

xdef    OsSci

;       bank 0

xref    InitSBF
xref    ScreenClose
xref    ScreenOpen

;       ----

.Table
        defb 0, 3, 6, 7, 5, 5                   ; #low bits ignored


; alter screen information
;
;IN:    A=reason code
;               SC_LR0  LORES0 (512 bytes granularity, 13 bits width)
;               SC_LR1  LORES1 (4K granularity, 10 bits width)
;               SC_HR0  HIRES0 (8K granularity, 9 bits  width)
;               SC_HR1  HIRES1 (2K granularity, 11 bits width)
;               SC_SBR  screen base (2K granularity, 11 bits width)
;       B=0, get pointer address
;       B<>0, set pointer address
;OUT:   Fc=0, BHL = old pointer address
;       Fc=1, A=error if fail
;chg:   AFBCDEHL/....

.OSSci
        cp      6                               ; !! should check for reason 0
        jr      nc, ossci_4                     ; bad reason
        ld      d, >Table                       ; !! use 'ld de,Table; add a, e' for clarity
        add     a, <Table
        ld      e, a
        add     a, $6F
        ld      c, a                            ; BLINK register

        ld      a, (de)                         ; granularity
        push    bc
        inc     b
        dec     b
        push    af                              ; shift count, B=0 status

        sla     h                               ; H<<2, get rid of segment bits
        sla     h
.ossci_1
        srl     b                               ; BH>>A
        rr      h
        dec     a
        jr      nz, ossci_1

        pop     af                              ; B=0 status
        push    af

        ld      a, h                            ; AB=blink value
        ld      h, BLSC_PAGE                    ; HL=$047x
        ld      l, c
        ld      e, (hl)                         ; old value into DE
        res     4, l                            ; $046x
        ld      d, (hl)                         ; old value
        jr      z, ossci_2                      ; B=0? don't set

        set     4, l                            ; $047x
        ld      (hl), a
        res     4, l                            ; $046x
        ld      (hl), b
        out     (c), a

.ossci_2
        ld      a, c                            ; blink register
        ex      de, hl
        pop     bc                              ; B=shift count

.ossci_3
        add     hl, hl
        djnz    ossci_3
        srl     l                               ; normalize HL
        srl     l
        pop     de
        ld      (iy+OSFrame_B), h
        ld      (iy+OSFrame_H), l
        ld      (iy+OSFrame_L), 0
        xor     BL_SBR                          ; screen base reg.
        ret     nz                              ; not SBR? exit
        bit     6, c                            ; B=0
        ret     nz                              ; read only? exit

        ld      a, d                            ; init screen
        ld      (ubScreenBase), a
        call    ScreenOpen
        call    InitSBF
        call    ScreenClose
        or      a
        ret

.ossci_4
        ld      a, RC_Fail
        scf
        ret
