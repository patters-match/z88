; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1e6d9
;
; $Id$
; -----------------------------------------------------------------------------

        Module NqSp

        include "director.def"
        include "error.def"
        include "syspar.def"
        include "sysvar.def"

xdef    OSSpMain
xdef    OSNqMain
xdef    RstRdPanelAttrs

;       bank 0

xref    ClearMemHL_A
xref    CopyMemDE_HL
xref    FreeMemData
xref    GetOSFrame_DE
xref    GetOSFrame_HL
xref    GetWdStartXY
xref    GetWindowFrame
xref    InitFsMemHandle
xref    NqRDS
xref    NqSp_ret
xref    OSNqMemory
xref    OSSp_89
xref    OSSp_PAGfi
xref    PeekHLinc
xref    PokeHLinc
xref    PutOSFrame_BC
xref    PutOSFrame_DE
xref    PutOSFrame_HL
xref    RdFileByte
xref    ScreenClose
xref    ScreenOpen
xref    SetMemHandlePos
xref    WrFileByte

;       bank 7

xref    ScrD_GetMargins
xref    GetCrsrYX
xref    OSNqProcess

;       ----

.OSNqWindow
        cp      9                               ; range check
        ccf
        ld      a, RC_Unk
        ret     c

        call    ScreenOpen
        ld      a, (iy+OSFrame_A)
        ld      hl, OSNqWndwTable
        add     hl, bc
        jp      (hl)

.OSNqWndwTable
        jp      NqWBOX
        jp      NqWCUR
        jp      NqRDS

;       ----

;       return window information


.NqWBOX
        push    ix
        call    GetWindowFrame
        push    af
        call    GetWdStartXY                    ; HL=yx_start
        call    ScrD_GetMargins                 ; !! BC=0000
        push    bc
        pop     de

        ld      a, (ix+wdf_endx)                ; C=width
        sub     (ix+wdf_startx)
        srl     a
        inc     a
        ld      c, a

        ld      a, (ix+wdf_endy)                ; B=height
        sub     (ix+wdf_starty)
        inc     a
        ld      b, a
        jr      NqWret

;       return cursor information

.NqWCUR
        push    ix
        call    GetWindowFrame
        push    af
        call    GetCrsrYX                       ; HL=yx
        call    ScrD_GetMargins                 ; BC=yx_margin
        ld      d, (ix+wdf_flagsHi)             ; high flags


.NqWret pop     af
        jr      nc, nqw_1                       ; GetWindowFrame succeeded? continue
        ld      a, RC_Bad
        scf

.nqw_1
        ld      (iy+OSFrame_A), a
        call    PutOSFrame_BC
        call    PutOSFrame_DE
        call    PutOSFrame_HL
        pop     ix
        ex      af, af'
        call    ScreenClose
        ex      af, af'
        ret

;       ----

.OSSpMain
        ld      a, b                            ; reason $80xx-$8exx
        cp      $80
        jr      c, ossp_err
        cp      $8F
        jr      nc, ossp_err

        ld      hl, NqSp_ret                    ; push return address
        push    hl
        ld      c, b                            ; reason high byte
        ld      b, 0
        ld      hl, OSSpTable-$80
        add     hl, bc
        push    hl                              ; push function address

        ld      b, 0
        ld      c, (iy+OSFrame_C)
        ld      a, c
        ret

.ossp_err
        ld      a, RC_Unk
        scf                                     ; !!BUG: missing ret

.OSSpTable
        jp      SpPanel
        jp      Sp_nop
        jp      Sp_nop
        jp      OSSp_89
        jp      OSSp_DC

.Sp_nop         ret

.OSSp_DC
        push    iy
        pop     hl
        OZ      DC_Sp                           ; Handle Director/CLI settings
        ret

;       ----

.OSNqMain
        ld      a, b                            ; reason $80xx-8exx  !! re-use code with OSSp jumper
        cp      $80
        jr      c, osnq_err
        cp      $8F
        jr      nc, osnq_err

        ld      hl, NqSp_ret                    ; push return address
        push    hl

        ld      c, b                            ; reason high byte
        ld      b, 0
        ld      hl, OSNqTable-$80
        add     hl, bc
        push    hl                              ; push function address
        ld      b, 0
        ld      c, (iy+OSFrame_C)
        ld      a, c
        ret

.osnq_err
        ld      a, RC_Unk
        scf
        ret

.OSNqTable
        jp      NqPanel
        jp      OSNqWindow
        jp      OSNqProcess
        jp      OSNqMemory
        jp      OSNqDirector

.OSNqDirector
        push    iy
        pop     hl
        OZ      DC_Nq                           ; Handle Director/CLI enquiries
        ret

;       ----

.NqPanel
        push    ix
        ld      a, (iy+OSFrame_A)               ; clear buffer
        ex      de, hl
        call    ClearMemHL_A

        ld      a, c                            ; reason low byte $00-59 or $80-b7
        cp      $B8
        jr      nc, nqp_1
        cp      $80
        jr      nc, nqp_2
        cp      $5A
.nqp_1  ccf
        ld      a, RC_Unk
        jr      c, nqp_ret

.nqp_2
        call    GetPrefsData
        jr      c, nqp_def                      ; no saved data, use default value

        call    SetMemHandlePos

.nqp_3
        call    RdFileByte                          ; attribute ID
        jr      c, nqp_ret                      ; error? exit
        or      a
        jr      z, nqp_def                      ; end of data? use default value
        cp      (iy+OSFrame_C)
        jr      z, nqp_4                        ; match? read data
        call    SkipAttr                        ; else skip attribute and try again
        jr      c, nqp_ret
        jr      nqp_3

.nqp_4
        call    RdFileByte                          ; attribute length
        jr      c, nqp_ret
        ld      c, a                            ; store
        call    NqGetDest                       ; get destination buffer
        call    NqRetSize                       ; return size of data, EOF if it fits
        inc     c
        dec     c
        jr      z, nqp_ret                      ; size=0? done

        push    af                              ; remember return code
.nqp_5
        call    RdFileByte                          ; read byte and put it into buffer
        call    PokeHLinc
        dec     c
        jr      nz, nqp_5                       ; loop until C bytes done

        pop     af
        jr      nqp_ret

;       return default value

.nqp_def
        call    GetDefPrefDest
        call    NqRetSize
        call    CopyMemDE_HL

.nqp_ret
        pop     ix
        ret

;       ----

.GetDefPrefDest
        call    GetDefaultPref                  ; source data at (DE)
        ld      c, a                            ; source length

.NqGetDest
        ex      de, hl
        call    GetOSFrame_DE                   ; get destination buffer
        ex      de, hl
        dec     hl
        dec     hl
        ld      a, h
        or      l
        inc     hl
        inc     hl
        ld      a, (iy+OSFrame_A)               ; buffer size
        ret     nz                              ; buffer not 0002? exit

;       return data in DE

        push    de
        ld      de, 0                           ; !! DE=2, so ld e,d
        call    PutOSFrame_DE                   ; clear DE
        push    iy
        pop     hl
        ld      de, OSFrame_E
        add     hl, de
        pop     de
        ld      a, 2                            ; 2 bytes
        ret

;       ----

;       if wanted size is smaller than attribute size we return EOF

.NqRetSize
        ld      (iy+OSFrame_A), c
        cp      c
        jr      nc, nqcs_1                      ; !! ret nc
        ld      c, a
        ld      a, RC_Eof
.nqcs_1
        ret

;       ----

;OUT:   A=length, DE=data

.GetDefaultPref
        ld      b, 0
        ld      c, (iy+OSFrame_C)

        ld      hl, PrefTbl1
        ld      a, c                            ; !! bit 7,c; jr z,...
        cp      $80
        jr      c, gdp_1
        res     7, c                            ; 00-7F
        ld      hl, PrefTbl2

.gdp_1
        push    hl
        add     hl, bc
        ld      c, (hl)                         ; offset to data
        inc     hl
        ld      a, (hl)                         ; offset to next-offset=length
        sub     c
        pop     hl
        ret     z                               ; length=0? done

        add     hl, bc                          ; return pointer in DE
        ex      de, hl
        ret

;       ----

.SkipAttr
        call    RdFileByte
        ret     c                               ; error? exit
        ld      b, a                            ; length to B, exit if 0
        or      a
        ret     z

.ska_1
        call    RdFileByte
        ret     c
        djnz    ska_1
        ret

;       ----

.CheckFit
        call    GetDefPrefDest
        call    GetOSFrame_HL
        inc     a
        ret     z                               ; dest buffer length-1, Fc=0
        dec     a
        cp      c
        ret     nz                              ; Fc=0 if data fits dest
        or      a
        ret     

;       ----

.CopyByte
        call    SaveRdByte
        ret     c
.RestoreWrByte
        call    RestoreVars
        jp      WrFileByte

.SaveRdByte
        call    SaveVars
        jp      RdFileByte

;       ----

.SaveVars
        push    bc
        ld      hl, word_024A
        ld      de, pMTHScreenSave
        ld      bc, 4
        ldir                                    ; 24a-24d -> 24e-251
        ld      hl, word_0252
        ld      de, word_024A
        ld      bc, 4
        ldir                                    ; 252-255 -> 24a-24d
        pop     bc
        ret

.RestoreVars
        push    bc
        ld      hl, word_024A
        ld      de, word_0252
        ld      bc, 4
        ldir                                    ; 24a-24d -> 252-255
        ld      hl, pMTHScreenSave
        ld      de, word_024A
        ld      bc, 4
        ldir                                    ; 24e-251 -> 24a-24d
        pop     bc
        ret

;       ----

;       IN: A=reason low byte

.SpPanel
        or      a
        jp      z, OSSp_PAGfi
        push    ix

        cp      $B8                             ; reason low byte $00-59 or $80-b7
        jr      nc, spp_1
        cp      $80
        jr      nc, spp_2                       ; ISO translations
        cp      $5A
.spp_1
        ccf
        ld      a, RC_Unk
        jp      c, spp_12

.spp_2
        call    InitFsMemHandle
        jp      c, spp_12                       ; error? exit
        ld      (uwPanelFilePtr), de

        call    SaveVars
        call    GetPrefsData
        jr      c, spp_7                        ; no saved data, skip copy

;       copy data from one memory into another, skip current attribute

        call    SetMemHandlePos
        ld      c, 0
.spp_3
        call    RestoreVars

.spp_4
        call    SaveRdByte
        jr      c, spp_11                       ; error? exit
        or      a
        jr      z, spp_8                        ; end mark? go append data
        cp      (iy+OSFrame_C)
        jr      nz, spp_5                       ; not current attr? copy

        call    SkipAttr
        jr      c, spp_11
        jr      spp_3

.spp_5
        ld      c, -1
        call    RestoreWrByte
        jr      c, spp_11
        call    CopyByte
        jr      c, spp_11
        ld      b, a                            ; length
        or      a
        jr      z, spp_4                        ; length zero? done

.spp_6
        call    CopyByte
        jr      c, spp_11
        djnz    spp_6
        jr      spp_4

.spp_7
        ld      c, 0

;       append to file

.spp_8
        call    RestoreVars
        push    bc
        call    CheckFit
        pop     bc
        jr      z, spp_10                       ; length zero? done

        ld      c, -1
        ld      a, (iy+OSFrame_C)                ; reason
        call    WrFileByte
        jr      c, spp_11

        ld      a, (iy+OSFrame_A)               ; length
        call    WrFileByte
        jr      c, spp_11
        or      a
        jr      z, spp_10                       ; length zero? done

        ld      b, a
        call    GetOSFrame_HL                   ; data ptr
.spp_9
        push    bc
        call    PeekHLinc                       ; read data
        call    WrFileByte                          ; write to file
        pop     bc
        jr      c, spp_11
        djnz    spp_9                           ; until all done

.spp_10
        xor     a                               ; trailing zero
        call    WrFileByte
        jr      c, spp_11

        ld      de, (uwPanelFilePtr)
        call    PutPrefsData
        or      a
        inc     c
        dec     c
        jr      nz, spp_12

        call    GetPrefsData
        res     IST_B_HASPREFS, (hl)
        call    FreeMemData
        jr      spp_12

.spp_11
        push    af
        ld      de, (uwPanelFilePtr)
        call    FreeMemData
        pop     af

.spp_12
        pop     ix
        ret

;       ----

;       get pointer to current prefs data

.GetPrefsData
        ld      hl, ubIntStatus
        bit     IST_B_HASPREFS, (hl)
        scf
        ret     z
        ccf
        bit     IST_B_2, (hl)
        ld      de, (pPrefs1)
        ret     z
        ld      de, (pPrefs2)
        ret

;       put pointer to current prefs data, free the other one

.PutPrefsData
        ld      hl, ubIntStatus
        bit     IST_B_2, (hl)
        call    z, SetPrefs2
        call    nz, SetPrefs1
        bit     IST_B_HASPREFS, (hl)
        set     IST_B_HASPREFS, (hl)
        ret     z
        push    bc
        call    FreeMemData
        pop     bc
        ret

.SetPrefs1
        ld      (pPrefs1), de
        res     IST_B_2, (hl)
        ld      de, (pPrefs2)
        ret

.SetPrefs2
        ld      (pPrefs2), de
        set     IST_B_2, (hl)
        ld      de, (pPrefs1)
        ret

;       pointer to default value - data length is next_ptr-ptr

.PrefTbl1
        defb    defMct - PrefTbl1
        defb    defMct - PrefTbl1               ; timeout
        defb    defRep - PrefTbl1               ; repeat
        defb    defKcl - PrefTbl1               ; click
        defb    defSnd - PrefTbl1               ; sound
        defb    defBad - PrefTbl1               ; bad process size
        defb    defIov - PrefTbl1               ; 06-0F unused
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1
        defb    defIov - PrefTbl1               ; insert/overwrite
        defb    defDat - PrefTbl1               ; date format
        defb    defMap - PrefTbl1               ; pipedream map
        defb    defMsz - PrefTbl1               ; map size
        defb    defDev - PrefTbl1               ; default dir ""
        defb    defDev - PrefTbl1               ; default dev
        defb    defTxb - PrefTbl1               ; tx baud rate
        defb    defRxb - PrefTbl1               ; rx baud rate
        defb    defXon - PrefTbl1               ; xon/xoff
        defb    defPar - PrefTbl1               ; parity
        defb    defPtr - PrefTbl1               ; 1a-1f unused
        defb    defPtr - PrefTbl1
        defb    defPtr - PrefTbl1
        defb    defPtr - PrefTbl1
        defb    defPtr - PrefTbl1
        defb    defPtr - PrefTbl1
        defb    defPtr - PrefTbl1               ; printer name
        defb    defAlf - PrefTbl1               ; allow linefeed
        defb    defPon - PrefTbl1               ; printer on
        defb    defPof - PrefTbl1               ; printer off ""
        defb    defPof - PrefTbl1               ; end of page
        defb    defOn1 - PrefTbl1               ; HMI prefix
        defb    defOn1 - PrefTbl1               ; HMI suffix
        defb    defOn1 - PrefTbl1               ; HMI offset
        defb    defOn1 - PrefTbl1               ; underline
        defb    defOff1 - PrefTbl1
        defb    defRes1 - PrefTbl1
        defb    defOn2 - PrefTbl1
        defb    defOn2 - PrefTbl1               ; bold
        defb    defOff2 - PrefTbl1
        defb    defRes2 - PrefTbl1
        defb    defOn4 - PrefTbl1
        defb    defOn4 - PrefTbl1               ; extended
        defb    defOn4 - PrefTbl1
        defb    defOn4 - PrefTbl1
        defb    defOn4 - PrefTbl1
        defb    defOn4 - PrefTbl1               ; italics
        defb    defOff4 - PrefTbl1
        defb    defRes4 - PrefTbl1
        defb    defOn5 - PrefTbl1
        defb    defOn5 - PrefTbl1               ; subscript
        defb    defOff5 - PrefTbl1
        defb    defRes5 - PrefTbl1
        defb    defOn6 - PrefTbl1
        defb    defOn6 - PrefTbl1               ; superscript
        defb    defOff6 - PrefTbl1
        defb    defRes6 - PrefTbl1
        defb    defOn7 - PrefTbl1
        defb    defOn7 - PrefTbl1               ; alt font
        defb    defOff7 - PrefTbl1
        defb    defRes7 - PrefTbl1
        defb    defOn8 - PrefTbl1
        defb    defOn8 - PrefTbl1               ; user defined
        defb    defOff8 - PrefTbl1
        defb    defRes8 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr1
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr2
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr3
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr4
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr5
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr6
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr7
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr8
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1             ; tr9
        defb    PrefTbl2 - PrefTbl1
        defb    PrefTbl2 - PrefTbl1

.defMct         defb    5
.defRep         defb    6
.defKcl         defb    'N'
.defSnd         defb    'Y'
.defBad         defb    40
.defIov         defb    'I'
.defDat         defb    'E'
.defMap         defb    'Y'
.defMsz         defb    'P'
.defDev         defm    ":RAM.0"
.defTxb         defw    9600
.defRxb         defw    9600
.defXon         defb    'Y'
.defPar         defb    'N'
.defPtr         defm    "Epson",0
.defAlf         defb    'Y'
.defPon         defb    27,64, 27,82, 0
.defPof         defb    12
.defOn1         defb    27,45,1
.defOff1        defb    27,45,0
.defRes1        defb    'Y'
.defOn2         defb    27,69
.defOff2        defb    27,70
.defRes2        defb    'Y'
.defOn4         defb    27,52
.defOff4        defb    27,53
.defRes4        defb    'Y'
.defOn5         defb    27,83,1
.defOff5        defb    27,84
.defRes5        defb    'Y'
.defOn6         defb    27,83,0
.defOff6        defb    27,84
.defRes6        defb    'Y'
.defOn7         defb    15
.defOff7        defb    18
.defRes7        defb    'N'
.defOn8         defb    27,120,1
.defOff8        defb    27,120,0
.defRes8        defb    'N'


.PrefTbl2
 IF     OZ40001=0
        defb    defTr10 - PrefTbl2
        defb    Tr10out - PrefTbl2
 ELSE
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
 ENDIF
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
        defb    RstRdPanelAttrs - PrefTbl2
 IF     OZ40001=0
.defTr10        defb    $A3
.Tr10out        defb    27,82,3,35, 27,82, 0
 ELSE
 ENDIF

;       ----
;
; read PA_Gfi - PA_Bad into $0201-0205
;
;
.RstRdPanelAttrs
        push    bc
        ld      bc, PA_Bad
        ld      d, 2

.rrpa_1
        ld      a, 1
        ld      e, c
        OZ      OS_Nq                           ; enquire (fetch) parameter
        dec     c
        jr      nz, rrpa_1
        pop     bc
        ret
