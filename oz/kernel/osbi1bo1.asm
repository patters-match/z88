        Module Bi1Bo1

        org     $d555                           ; 53 bytes

        include "blink.def"
        include "sysvar.def"
        include "lowram.def"

xdef    OSBi1
xdef    OSBo1

xref    MS1BankA

;	OS_Bi1/OS_Bo1
;
;	same as OS_Bix/OS_Box, but doesn't touch S2

.OSBi1
        exx
        ld      de, (BLSC_SR1)                  ; remember S2S1 in de
        push    bc
        inc     b
        dec     b
        jr      nz, bix_far                     ; bind in BHL

        bit     7, h
        jr      z, bix_4                        ; not kernel space, no bankswitching

        ld      c, (iy+OSFrame_S2)
        bit     6, h
        jr      z, bix_S2                       ; HL in S2 - S1=caller S2
        ld      b, (iy+OSFrame_S3)		; HL in S3 - S1=caller S3

.bix_far
        ld      c, b                            ; S1=B
.bix_S2
	ld	a, b
	ld	(BLSC_SR1), a
        pop     bc

        ld      b, 0                            ; HL=local
        res     7, h                            ; S1 fix
        set     6, h
.bix_3
        push    bc
        call    MS1BankA

.bix_4
        pop     bc
        ex      af, af'
        or      a
        jp      OZCallReturn1

.OSBo1
        exx
	ld	a, e
        ld      (BLSC_SR1), a
        jr      bix_3

