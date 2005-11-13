; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d816
;
; $Id$
; -----------------------------------------------------------------------------

        Module Reset5

        include "director.def"
        include "serintfc.def"
        include "screen.def"
        include "sysvar.def"

xdef    Reset5

xref    MountAllRAM                             ; bank0/resetx.asm
xref    OSSp_PAGfi                              ; bank0/pagfi.asm

xref    TimeReset                               ; bank7/timeres.asm

;       ----

.Reset5
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
