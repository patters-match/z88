; -----------------------------------------------------------------------------
; Bank 3 @ S3
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNWild

        include "handle.def"
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "memory.def"

        include "gndef.def"
        include "sysvar.def"

;       ----

xdef    GNOpw
xdef    GNWcl
xdef    GNWfn

;       ----

xref    AllocFsNode
xref    CompressFN
xref    FindMatchingFsNode
xref    FreeDOR
xref    FreeTopFsNode
xref    GetOsf_BHL
xref    Ld_A_BHL
xref    LdFsnDOR_IX
xref    LdIX_FsnDOR
xref    LeaHL_FsnBuffer
xref    MatchFsNode
xref    NextFsNode
xref    PutOsf_Err

;       ----

;       open wildcard handler
;
;IN:    BHL=wildcard string, A=flags
;         A0: backward scan
;         A1: return full path
;OUT:   IX=wildcard handle
;       Fc=1, A=error
;
;CHG:   AF....../IX..

.GNOpw
        OZ      OS_Bix                          ; bind wildcard string in
        push    de

        OZ      GN_Prs                          ; parse it
        ld      b, 0                            ; BC=length
        push    bc

        ld      a, MM_S1|MM_MUL                 ; allcate mempool for data
        ld      c, b                            ; BC=0
        OZ      OS_Mop
        pop     bc
        jr      c, opw_err                      ; no mem?

        xor     a
        ld      hl, wc_Buffer                   ; !! could do this above, saves push/pop
        add     hl, bc
        ld      b, h                            ; BC=wc_SIZEOF+strlen()
        ld      c, l
        push    bc
        OZ      OS_Mal                          ; allocate memory for data
        pop     de                              ; length to DE
        jr      c, opw_1                        ; no mem?

        ld      a, h                            ; S2 fix
        and     $3F                             ; !! 'set 7,h; res 6,h'
        or      $80
        ld      h, a
        push    ix
        ld      a, TH_WMG
        OZ      OS_Gth                          ; allocate wildcard handle
        jr      nc, opw_2

        pop     ix
.opw_1
        push    af                              ; close mempool and error
        OZ      OS_Mcl
        pop     af
        jr      opw_err

.opw_2
        ld      c, MS_S2                        ; wildcard data into S2
        rst     OZ_MPB
        exx
        pop     de                              ; de'=memory pool
        exx
        push    bc

;       clear data

        ld      b, e                            ; length
        push    hl
.opw_3
        ld      (hl), 0                         ; !! 'xor a; ld (hl),a'
        inc     hl
        djnz    opw_3

        ld      a, (iy+OSFrame_A)               ; save flags
        and     3
        ex      (sp), iy
        ld      (iy+wc_Flags), a
        exx
        ld      (iy+wc_pMemPool+1), d           ; save memory pool
        ld      (iy+wc_pMemPool), e
        exx
        ld      a, e                            ; save allocation size
        ld      (iy+wc_AllocSize), e
        sub     wc_Buffer                       ; data buffer size
        ld      c, a

;       copy wildcard string into buffer

        push    iy
        pop     hl
        ld      de, wc_Buffer
        add     hl, de
        ex      de, hl
        ex      (sp), iy                        ; !! no reason to keep IY anymore, just pop
        call    GetOsf_BHL
        ex      (sp), iy
.opw_4
        call    Ld_A_BHL
        ld      (de), a
        inc     de
        inc     hl
        dec     c
        jr      nz, opw_4
        pop     iy                              ; OSFrame
        pop     bc                              ; restore S2
        rst     OZ_MPB
        jr      opw_6

.opw_err
        call    PutOsf_Err
.opw_6
        pop     de
        OZ      OS_Box
        ret

;       ----

;       close wildcard handle
;
;IN:    IX=wildcard handle
;OUT:   IX=0
;       Fc=1, A=error
;CHG:   AF....../IX..

.GNWcl
        ld      a, TH_WMG
        OZ      OS_Vth
        jr      c, wcl_err                      ; bad handle?

        ld      c, MS_S1                        ; remember S1/S2 bindings
        call    OZ_MGB
        push    bc
        inc     c                               ; MS_S2
        call    OZ_MGB
        push    bc

        push    iy
        ld      a,TH_WMG
        OZ      OS_Fth                          ; free handle

        ld      c, MS_S2                        ; !! C already 2
        rst     OZ_MPB                          ; bind data in S2
        push    hl                              ; IX=data
        pop     ix
        push    ix                              ; IY=node !! push hl
        pop     iy

;       free all DORs

.wcl_1
        call    NextFsNode
        jr      c, wcl_2
        push    ix
        call    LdIX_FsnDOR
        call    FreeDOR
        pop     ix
        jr      wcl_1

.wcl_2
        ld      d, (ix+wc_pMemPool+1)           ; IX=mempool
        ld      e, (ix+wc_pMemPool)
        push    de
        pop     ix

        pop     iy
        pop     bc                              ; restore S1/S2
        rst     OZ_MPB
        pop     bc
        rst     OZ_MPB

        OZ      OS_Mcl                          ; close mempool, free all memory
        ret     nc
.wcl_err
        jp      PutOsf_Err

;       ----

;       fetch next wildcard match
;
;IN:    IX=wildcard handle, DE=buffer for explicit name, C=buffer size
;OUT:   DE=end of name, B=#segments in name, C=#chars in name,
;       A = DOR type
;       Fc=1, A=error
;
;CHG:   AFBCDE../....

.GNWfn
        push    ix
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        push    bc
        ld      a, TH_WMG
        OZ      OS_Vth
        jp      c, wfn_21                       ; bad handle? exit

        ld      c, MS_S2                        ; bind data into S2
        rst     OZ_MPB
        push    bc
        push    iy

        push    hl                              ; IX=data
        pop     ix
.wfn_1
        push    ix                              ; IY=node
        pop     iy
        call    NextFsNode
        jr      nc, wfn_2                       ; has first node

;       allocate first node if not done already

        bit     WCF_B_HASFILENODE, (ix+wc_Flags)
        jp      nz, wfn_x                       ; EOF
        call    AllocFsNode
        jp      c, wfn_x
        set     WCF_B_HASFILENODE, (ix+wc_Flags)
        jr      wfn_6

.wfn_2
        ld      a, (ix+wc_Flags)
        bit     WCF_B_BACKWARD, a
        jr      nz, wfn_backw                   ; backward scan?

;       forward scan

        res     WCF_B_BRANCHDONE, (ix+wc_Flags) ; !! move this below test/branch
        bit     WCF_B_BRANCHDONE, a
        jr      z, wfn_3
        bit     FSNF_B_WILDDIR, (iy+fsn_ubFlags)
        jr      z, wfn_6
        call    MatchFsNode
        jr      nz, wfn_6
.wfn_3
        bit     FSNF_B_HADMATCH, (iy+fsn_ubFlags)
        jr      nz, wfn_6
        jp      wfn_match

;       bacward scan

.wfn_backw
        bit     WCF_B_BRANCHDONE, (ix+wc_Flags) ; !! 'bit n,a'
        jr      z, wfn_6
        res     WCF_B_BRANCHDONE, (ix+wc_Flags)
        bit     FSNF_B_WILDDIR, (iy+fsn_ubFlags)
        jr      z, wfn_5
        call    MatchFsNode
        jr      z, wfn_match
.wfn_5
        bit     WCF_B_FULLPATH, (ix+wc_Flags)
        jr      z, wfn_6
        bit     FSNF_B_HADMATCH, (iy+fsn_ubFlags)
        jr      nz, wfn_match

.wfn_6
        call    FindMatchingFsNode
        jr      nc, wfn_7
        cp      RC_Eof
        scf
        jp      nz, wfn_x                       ; not EOF? exit

        set     WCF_B_BRANCHDONE, (ix+wc_Flags) ; this branch done, try next
        call    FreeTopFsNode
        jr      nc, wfn_1
        jp      wfn_x

.wfn_7
        ld      a, (ix+wc_MatchDepth)
        cp      (ix+wc_NodeCount)
        jr      c, wfn_8
        ld      a, (ix+wc_NodeCount)
        dec     a
        ld      (ix+wc_MatchDepth), a
.wfn_8
        bit     FSNF_B_WILDDIR, (iy+fsn_ubFlags)
        jr      z, wfn_9

        call    AllocFsNode                     ; "//" used, try every level
        jr      nc, wfn_6                       ; below current
        call    RdFsNodeSegChar
        jr      nc, wfn_6
        call    MatchFsNode
        jr      nz, wfn_6
        jr      wfn_match
.wfn_9
        call    RdFsNodeSegChar                 ; go one level down until end of string
        jr      c, wfn_match
        call    AllocFsNode
        jr      wfn_6

;       we have match, return it

.wfn_match
        push    ix
        pop     iy
        pop     de
        call    NextFsNode
        bit     WCF_B_BACKWARD, (ix+wc_Flags)
        jr      nz, wfn_12                      ; return deepest first
        bit     WCF_B_FULLPATH, (ix+wc_Flags)
        jr      z, wfn_12
        inc     (ix+wc_MatchDepth)
        ld      a, (ix+wc_NodeCount)
        sub     (ix+wc_MatchDepth)
        jr      z, wfn_12

        ld      c, a                            ; skip this many levels
.wfn_11
        call    NextFsNode
        dec     c
        jr      nz, wfn_11

;       get brother here in case match gets deleted by caller

.wfn_12
        bit     FSNF_B_HASNEWDOR, (iy+fsn_ubFlags)
        jr      nz, wfn_13
        push    bc
        call    LdIX_FsnDOR
        ld      a, DR_SIB
        OZ      OS_Dor                          ; get brother DOR
        push    af
        call    LdFsnDOR_IX
        pop     bc
        ld      (iy+fsn_ubNewDorType), b
        ld      (iy+fsn_ubNewDorFlags), c
        set     FSNF_B_HASNEWDOR, (iy+fsn_ubFlags)
        pop     bc

.wfn_13
        ld      a, (iy+fsn_ubType)
        push    de
        ex      (sp), iy
        ld      (iy+OSFrame_A), a               ; return DOR type
        ex      (sp), iy
        pop     de

        ld      c, 0
.wfn_14
        call    LeaHL_FsnBuffer
        set     FSNF_B_HADMATCH, (iy+fsn_ubFlags)
        push    bc                              ; push segment part string BHL and count C
        push    hl
        inc     c
        call    NextFsNode
        jr      nc, wfn_14

        push    de                              ; IY=OSFrame
        pop     iy

        ld      de, GnFnameBuf
        ld      a, ':'                          ; start with device
        jr      wfn_16
.wfn_15
        ld      a, c
        or      a
        jr      z, wfn_18                       ; all done? exit
        ld      a, '/'                          ; add segment separator
.wfn_16
        ld      (de), a
        inc     de
        pop     hl                              ; pop next segment into BHL
        pop     bc
        push    bc                              ; bind in S1
        ld      c, MS_S1
        rst     OZ_MPB
        pop     bc
.wfn_17
        ld      a, (hl)                         ; copy segment name into buffer
        inc     hl
        cp      $21
        jr      c, wfn_15                       ; end? add new segment
        ld      (de), a
        inc     de
        jr      wfn_17

.wfn_18
        xor     a                               ; zero terminate
        ld      (de), a
        jr      wfn_20

.wfn_x
        pop     iy
.wfn_20
        pop     bc
        push    af
        rst     OZ_MPB                          ; restore S1
        pop     af
.wfn_21
        pop     bc                              ; restore S2
        push    af
        rst     OZ_MPB                          ; Bind bank B in slot C
        pop     af
        ld      b, 0
        ld      hl, GnFnameBuf
        call    nc, CompressFN
        call    c, PutOsf_Err
        pop     ix
        ret

;       ----

.RdFsNodeSegChar
        ld      h, (iy+fsn_pWcEndPtr+1)
        ld      l, (iy+fsn_pWcEndPtr)
        ld      a, (hl)
        cp      $21
        ret
