; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $1526
;
; $Id$
; -----------------------------------------------------------------------------

        Module OSSi

        org     $d526                           ; 47 bytes

        include "blink.def"
        include "sysvar.def"
        include "lowram.def"

xdef    OSSi
xdef    IntUART

xref    MS2BankA


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

        ld      a, OZBANK_RS232                 ; bind in serial code  !!move to OZBANK_HI
        call    MS2BankA
        ex      af, af'
        ld      h, >RS232code
        call    JpHL                            ; call $A5op in b02
        ex      af, af'

        pop     af
        jr      nz, ossi_1
        ld      (SerRXHandle), ix               ; set handle if SI_HRD

.ossi_1
        call    MS2BankA                        ; restore S2
        ex      af, af'
        pop     ix
        ret

