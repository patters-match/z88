; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $1526
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSSi

        include "blink.def"
        include "sysvar.def"
        include "../bank7/lowram.def"

xdef    OSSi
xdef    IntUART

xref    MS2BankA                                ; bank0/misc5.asm



;IN:    L=reason code - see rs232.asm for arguments

.OSSi
        call    OSSiMain
        jp      OZCallReturn1

.IntUART
        exx
.OSSiMain
        push    ix
        ld      ix, (SerRXHandle)
        exx
        ld      a, l
        or      a
        ld      a, (BLSC_SR2)
        push    af                              ; remember S2 and (L=SI_HRD)

        ld      a, OZBANK_RS232                 ; bind in serial code  !!move to b00
        call    MS2BankA
        ex      af, af'
        ld      h, >RS232code
        call    ossi_2                          ; call $A5op in b02
        ex      af, af'

        pop     af
        jr      nz, ossi_1
        ld      (SerRXHandle), ix               ; set handle if SI_HRD

.ossi_1
        call    MS2BankA                        ; restore S2
        ex      af, af'
        pop     ix
        ret

.ossi_2
        jp      (hl)                            ; !! use jpHL in low RAM (let's put one permanently at $0007)

