; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $30df
;
; $Id$
; -----------------------------------------------------------------------------

        Module MTH3

        include "sysvar.def"

xdef    FindCmd                                 ; osin

xdef    Get2ndTopicHelp                         ; mth1, mth2
xdef    GetNextTopicHelp                        ; mth1
xdef    GetFirstTopicHelp                       ; mth1
xdef    GetNextNonInfoTopic                     ; mth1
xdef    GetFirstNonInfoTopic                    ; mth1
xdef    GetNonInfoTopicByNum                    ; mth1
xdef    GetTpcAttrByNum                         ; mth1, mth2

xref    OSBixS1                                 ; bank0/misc4.asm
xref    OSBoxS1                                 ; bank0/misc4.asm
xref    PutOZwdBuf                              ; bank0/osin.asm
xref    GetAppCommands                          ; bank0/mth2.asm
xref    GetHlpTopics                            ; bank0/mth2.asm
xref    SkipNTopics                             ; bank0/mth2.asm
xref    GetAttr                                 ; bank0/mth2.asm

; ;OUT: Fc=1 - no command matches
; ;Fc=0, Fz=0, A=code - partial match, buffer not ready yet
; ;Fc=0, Fz=1, A=code - perfect match

.FindCmd
        call    PutOZwdBuf
        ret     c

        call    GetAppCommands
        call    OSBixS1
        push    de

        inc     hl                              ; skip start mark
.fcmd_1
        ld      a, (hl)
        cp      1
        jr      c, fcmd_4                       ; end of list
        jr      z, fcmd_2                       ; end of topic? skip it
        push    hl
        inc     hl
        ld      c, (hl)                         ; command code
        inc     hl
        ld      de, OZcmdBuf
        call    CompareCmd
        pop     hl
        jr      nc, fcmd_3                      ; match? return C

.fcmd_2
        ld      e, (hl)                         ; get length
        ld      d, 0
        add     hl, de                          ; skip command
        jr      fcmd_1                          ; compare next command
.fcmd_3
        ld      a, c                            ; get command code
.fcmd_4
        pop     de
        call    OSBoxS1
        ret

;       ----

.CompareCmd
        ld      a, (hl)
        or      a
        scf
        ret     z                               ; cmd end? Fc=1
        ld      a, (de)
        or      a
        jr      nz, cc_1                        ; buffer not end yet? skip
        ld      a, (hl)                         ; cmd char
        cp      '@'
        ret     z                               ; '@'? Fc=0, Fz=1
        scf
        ret                                     ; otherwise Fc=1
.cc_1
        push    de
        push    hl
.cc_2
        ld      a, (de)
        or      (hl)
        jr      z, cc_4                         ; end? return Fc=0, Fz=1
        ld      a, (de)
        or      a
        jr      z, cc_3                         ; buf end? Fc=0, A=1
        cp      (hl)
        inc     de
        inc     hl
        jr      z, cc_2                         ; same? continue compare
        scf                                     ; different? Fc=1
.cc_3
        inc     a
.cc_4
        pop     hl
        pop     de
        ret

;       ----


;       ----

.Get2ndTopicHelp
        call    GetFirstTopicHelp
.GetNextTopicHelp
        inc     a
        jr      gth_1
.GetFirstTopicHelp
        ld      a, 1
.gth_1
        call    GetTpcAttrByNum
        ret     c
        bit     CMDF_B_HELP, d
        ret     nz
        inc     a
        jr      gth_1

;       ----
; !!
;
; xor a
; inc a
;
; avoids jr and allows loop into 'inc a'
.GetNextNonInfoTopic
        inc     a
        jr      GetNonInfoTopicByNum
.GetFirstNonInfoTopic
        ld      a, 1
.GetNonInfoTopicByNum
        call    GetTpcAttrByNum
        ret     c
        bit     TPCF_B_INFO, d
        ret     z                               ; not info, ret
        inc     a                               ; inc count and loop
        jr      GetNonInfoTopicByNum

;       ----

; IN: A=command/topic index
; OUT: Fc=0, D=attribute byte
;
;
.GetTpcAttrByNum
        push    af
        call    GetHlpTopics
        pop     af
        call    OSBixS1                          ; bind in BHL
        push    de
        call    SkipNTopics
        push    af
        call    GetAttr
        ld      b, a
        pop     af
        pop     de
        call    OSBoxS1
        ld      d, b
        ret

;       ----


