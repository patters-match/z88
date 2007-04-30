; -----------------------------------------------------------------------------
; Bank 3 @ S3
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNSopSoe


        include "memory.def"
        include "sysvar.def"

;       ----

xdef    GNSoe
xdef    GNSop

;       ----

xref    PrintStr

;       ----

;       write local string to standard output
;
;IN:    HL=pointer to null-terminated string
;OUT:   HL=pointer to null
;
;CHG:   AF....HL/....

.GNSop
        ld      b, 0
        push    hl
        OZ      OS_Bix                          ; bind BHL in
        ex      de, hl                          ; DE=HL(in)
        ex      (sp), hl
        ex      de, hl

        call    PrintStr
        ld      (iy+OSFrame_H), d               ; return ptr to null
        ld      (iy+OSFrame_L), e

        pop     de                              ; restore binding
        OZ      OS_Box
        ret

;       ----

;       write string at extended address to standard output
;
;IN:    BHL=pointer to null-terminated string (B=0 isn't local, it's bank 0)
;OUT:   HL=pointer to null
;
;CHG:   AF....HL/....

.GNSoe
        ld      c, MS_S1                        ; bind  BHL into S1
        rst     OZ_MPB
        push    bc
        ld      b, (iy+OSFrame_B)               ; bind  next bank in S2
        inc     b                               ; in case of bank cross
        ld      c, MS_S2
        rst     OZ_MPB
        push    bc

        ld      d, h                            ; DE=HL(in)
        ld      e, l
        ld      a, h                            ; S1 fix HL
        and     $3F
        or      $40
        ld      h, a
        call    PrintStr
        ld      (iy+OSFrame_H), d               ; return ptr to null
        ld      (iy+OSFrame_L), e               ; !! no bank change

        pop     bc                              ; restore S2
        rst     OZ_MPB
        pop     bc                              ; restore S1
        rst     OZ_MPB
        ret
