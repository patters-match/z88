; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $30df
;
; $Id$
; -----------------------------------------------------------------------------

        Module MTH3

        org     $f0df                           ; 205 bytes

        include "all.def"
        include "sysvar.def"
        include "bank7.def"

xdef    FindCmd
xdef    Get2ndCmdHelp
xdef    GetNextCmdHelp
xdef    GetFirstCmdHelp
xdef    Get2ndTopicHelp
xdef    GetNextTopicHelp
xdef    GetFirstTopicHelp
xdef    GetNextNonInfoTopic
xdef    GetFirstNonInfoTopic
xdef    GetNonInfoTopicByNum
xdef    GetTpcAttrByNum
xdef    GetNextCmdAttr
xdef    GetCmdAttrByNum

xref    PutOZwdBuf
xref    GetAppCommands
xref    GetHlpTopics
xref    SkipNTopics
xref    GetAttr
xref    GetHlpCommands
xref    GetCmdTopicByNum
xref    GetRealCmdPosition

; ;OUT: Fc=1 - no command matches
; ;Fc=0, Fz=0, A=code - partial match, buffer not ready yet
; ;Fc=0, Fz=1, A=code - perfect match

.FindCmd
        call    PutOZwdBuf
        ret     c

        call    GetAppCommands
        OZ      OS_Bix
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
        push    af
        OZ      OS_Box
        pop     af
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

.Get2ndCmdHelp
        call    GetFirstCmdHelp
.GetNextCmdHelp
        inc     a
        jr      gch_1
.GetFirstCmdHelp
        ld      a, 1
.gch_1
        call    GetCmdAttrByNum
        ret     c
        bit     CMDF_B_HELP, b
        ret     nz
        inc     a
        jr      gch_1

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
        OZ      OS_Bix                          ; bind in BHL
        push    de
        call    SkipNTopics
        push    af
        call    GetAttr
        ld      b, a
        pop     af
        pop     de
        push    af
        OZ      OS_Box                          ; restore S2/S3
        pop     af
        ld      d, b
        ret

;       ----

        xor     a                               ; !! unused

;       ----

.GetNextCmdAttr
        inc     a

.GetCmdAttrByNum
        push    af
        call    GetHlpCommands
        pop     af
        OZ      OS_Bix                          ; Bind in extended address
        push    de
        ld      c, a                            ; c=count
        ld      a, (ubHlpActiveTpc)
        call    GetCmdTopicByNum
        ld      a, 0
        jr      c, gcabn_1                      ; error? Fc=1, A=0
        ld      a, c                            ; a=count
        call    GetRealCmdPosition
        push    af
        push    hl                              ; !! inc hl; ld c,(hl); dec hl
        ld      bc, 1
        add     hl, bc
        ld      c, (hl)                         ; command code
        pop     hl
        pop     af                              ; !! unnecessary pop/push
        push    af
        call    GetAttr
        ld      b, a                            ; attributes
        pop     af
        push    de                              ; IX=DE
        pop     ix
.gcabn_1
        pop     de
        push    af
        OZ      OS_Box                          ; Restore bindings after OS_Bix
        pop     af
        push    ix                              ; DE=IX
        pop     de
        ret
