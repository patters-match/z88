; **************************************************************************************************
; Panel & PrintedEd
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; Source code was reverse engineered from OZ 4.0 (UK) ROM and made compilable by Jorma Oksanen.
; Additional development improvements, comments, definitions and new implementations by
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005
; (C) Gunther Strube (gbs@users.sf.net), 2005
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module  PanelPEd

        include "blink.def"
        include "char.def"
        include "director.def"
        include "error.def"
        include "fileio.def"
        include "fpp.def"
        include "integer.def"
        include "memory.def"
        include "stdio.def"
        include "syspar.def"
        include "sysvar.def"
        include "sysapps.def"


;       !! get rid of IY-based variables, use absolute addressing

defc    p_Vars = PRTED_SAFE_WS_START

defc    PRED_PAGE1              =$20
defc    PRED_PAGE2              =$21
defc    PRED_PAGE3              =$22
defc    PANELPAGE               =$2a

defc    ERR_OutOfMemory         =1
defc    ERR_BadFile             =2
defc    ERR_Escape              =3
defc    ERR_BadCodeString       =4
defc    ERR_StringTooLong       =5
defc    ERR_BadValue            =6
defc    ERR_BadName             =7

defvars p_Vars
        p_ubEntryID             ds.b    1
        p_ubPageID              ds.b    1
        p_pSettings             ds.w    1
        p_pSettingPool          ds.w    1
        p_pMemPool              ds.w    1
        p_pMem_Buffer_100       ds.w    1
        p_pPrFileName_33        ds.w    1
        p_pPrinterFileHandle    ds.w    1
        p_pPrinterName_20       ds.w    1
        p_ubFlags               ds.b    1
enddef

        org ORG_PRINTERED

.PrinterEd
        ld      iy, p_ubEntryID
        ld      (iy+p_ubPageID-p_Vars), PRED_PAGE1
        jr      Main

.Panel
        ld      iy, p_ubEntryID
        ld      (iy+p_ubPageID-p_Vars), PANELPAGE

.Main
        ld      a, SC_ENA
        OZ      OS_Esc
        xor     a
        ld      hl, ErrorHandler
        OZ      OS_Erh

        ld      hl, 0
        ld      (p_pSettingPool), hl

        ld      a, $80
        ld      bc, 0
        OZ      OS_Mop
        jr      c, init_2
        ld      (p_pMemPool), ix

        ld      bc, $100
        call    AllocMem
        jr      nc, init_4

.init_1
        ld      ix, (p_pMemPool)
        OZ      OS_Mcl
.init_2
        ld      a, RC_Room
        OZ      OS_Bye
        jr      $PC                             ; never reached

.init_4
        ld      (p_pMem_Buffer_100), hl
        ld      c, MS_S2
        rst     OZ_MPB

        ld      bc, $33
        call    AllocMem
        jr      c, init_1
        ld      (p_pPrFileName_33), hl

        ld      bc, $20
        call    AllocMem
        jr      c, init_1
        ld      (p_pPrinterName_20), hl

        call    StoreDefSettings
        jr      c, init_1
        call    DrawScreenLabels

.MainLoop
        ld      hl, (p_pMem_Buffer_100)
        ld      (hl), 0
.main_1
        ld      bc, (p_ubEntryID)               ; copy entry data into buffer
        call    GetEntryData
        call    nc, StrcpyIX_Buffer
.main_2
        ld      bc, (p_ubEntryID)               ; move cursor to setting
        call    GetEntryData
        call    MoveTo_HL

        push    bc
        ld      b, d                            ; fill field with spaces
        ld      a, ' '
.main_3
        OZ      OS_Out                          ; write a byte to std. output
        djnz    main_3

        ld      b, d                            ; move back to start
        ld      a, BS
.main_4
        OZ      OS_Out                          ; write a byte to std. output
        djnz    main_4
        pop     bc

        call    GetEntryData                    ; move back to start (again?)
        call    MoveTo_HL                       ; !! just push/pop af to get flags

        cp      $40                             ; combo box?
        push    af
        call    z, HandleComboBox
        pop     af
        push    af
        call    nz, HandleInputLine
        pop     af

        ld      a, c
        sub     $20
        jr      c, main_1
        cp      $0F
        jr      nc, main_1

        push    af
        call    ClrLine3
        call    ValidateInput
        rr      c                               ; save carry
        ld      b, a                            ; and error
        pop     af
        or      a
        jr      z, main_5                       ; escape
        cp      6
        jr      z, main_5                       ; next option
        cp      12
        jr      z, main_5                       ; new
        rl      c
        jr      nc, main_5                      ; no error?
        ld      a, b
        call    PrintError
        jr      main_2

.main_5
        add     a, a
        ld      e, a
        ld      d, 0
        ld      hl, CommandTable
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl
        ld      de, MainLoop
        push    de
        jp      (hl)

;       ----

;IN:    A=entry flags, D=field width, HL=entrydata+2
;OUT:   C=command code


.HandleInputLine
        ld      e, d                            ; line width
        ld      d, 9                            ; has data, return special
        cp      $80
        jr      nz, hil_1                       ; not number? skip
        ld      d, $0F                          ; force overwrite
.hil_1
        inc     hl
        bit     4, (hl)
        jr      z, hil_2                        ; not string? skip
        set     5, d                            ; single line lock
.hil_2
        ex      de, hl
        ld      de, (p_pMem_Buffer_100)         ; buffer
        ld      c, 0                            ; cursor pos
.hil_3
        push    hl
        ld      b, 255                          ; buffer size
        bit     5, h                            ; single line lock?
        jr      nz, hil_4
        ld      b, l                            ; use field width +1
        inc     b
.hil_4
        call    CursorOn
        ld      a, h
        OZ      GN_Sip                          ; input line
        pop     hl
        push    bc
        call    CursorOff
        call    c, MayRedraw
        pop     bc
        jr      c, hil_3                        ; error? loop

                                                ; else drop thru
;       ----

;IN:    A=input char
;OUT:   C=command code

.TranslateCmdKey
        ld      c, $20
        cp      ESC                             ; esc - 20
        ret     z
        inc     c
        cp      CR                              ; enter - 21
        ret     z
        inc     c
        cp      $FC                             ; left - 22
        ret     z
        inc     c
        cp      $FD                             ; right - 23
        ret     z
        ld      c, a
        ret

;       ----

;IN:    D=field width

.HandleComboBox
        ld      b, d
.hcb_1
        call    GetComboBoxBuf                  ; print current selection
        call    PrintComboEntry
        call    CursorOn
        OZ      OS_In
        call    CursorOff
        call    c, MayRedraw
        jr      c, hcb_1                        ; error? loop

        or      a
        jr      z, hcb_ext                      ; extended char
        cp      $20
        jr      c, hcb_ctrl                     ; control char
        cp      $80
        jr      nc, hcb_ctrl                    ; ditto

        call    FindComboByChar
        jr      nc, hcb_set                     ; found? set combo box entry

.hcb_err
        call    PrntBell                        ; beep and loop
        jr      hcb_1

.hcb_ext
        OZ      OS_In
        call    c, MayRedraw
        jr      c, hcb_err

.hcb_ctrl
        call    TranslateCmdKey
        cp      $26                             ; Next option?
        ret     nz

        call    GetComboBoxBuf
        call    FindComboByChar
        call    GetNextComboOption

.hcb_set
        ld      hl, (p_pMem_Buffer_100)         ; set new selection and loop
        ld      (hl), a
        inc     hl
        ld      (hl), 0
        jr      hcb_1

;       ----

;IN:    -
;OUT:   A=optionChar, IX=savedEntry

.GetComboBoxBuf
        push    bc
        ld      bc, (p_ubEntryID)
        call    GetComboBox
        pop     bc
        ld      hl, (p_pMem_Buffer_100)         ; use buffer entry if it's present
        ld      c, (hl)
        inc     c
        dec     c
        ret     z                               ; use default entry is empty
        call    SearchUpper                     ; get OptionChar
        ret

;       ----

;IN:    B=pageID, C=entryID
;OUT:   A=optionChar, HL=IX=optionList

.GetComboBox
        call    GetEntryData                    ; for E(flags 0-3) and IX(saved data i.e. the 5 bytes settings)
        push    af                              ; save Fc (Fc=1 if eof i.e. entry does not exist)

        ld      d, 0
        ld      hl, ComboBox_tbl                ; the option list pointers
        add     hl, de                          ; +0, +2, +4, +6, +8, +10
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl                          ; HL=option list

        pop     af
        ld      a, (hl)                         ; Fc=1? use default
        jr      c, gcl_1
        ld      a, (ix+0)                       ; else use saved setting

.gcl_1
        push    hl
        pop     ix
        ret

;       ----

;IN:    A=optionChar, IX=optionList (each entry is defined by its first upper char)
;OUT:   Fc=0, HL=optionText
;       Fc=1 if not found

.FindComboByChar
        call    ToUpper                         ; upper char is the entry def in list
        push    ix
        pop     hl                              ; list in hl
        ld      c, a                            ; the upper option char

.fcc_1
        push    hl                              ; save entry start
.fcc_2
        ld      a, (hl)
        or      a
        jr      z, fcc_next                     ; separator found, skip to next
        cp      -1
        jr      z, fcc_not_found                ; end of list, ret with error
        cp      c
        jr      z, fcc_found                    ; upper char matches, ret
        inc     hl                              ; test next char in entry
        jr      fcc_2

.fcc_next
        inc     sp                              ; destroy hl
        inc     sp
        inc     hl                              ; skip zero separator
        jr      fcc_1

.fcc_not_found
        scf
.fcc_found
        pop     hl                              ; entry start
        ret

;       ----

;IN:    A=optionChar, B=maxWidth, IX=optionList

.PrintComboEntry
        call    FindComboByChar
        push    hl

        ld      c, 0                            ; char count
.pce_1
        ld      a, (hl)
        or      a
        jr      z, pce_2                        ; null or -1? exit loop
        jp      m, pce_2                        ; !! unnecessary
        OZ      OS_Out                          ; write a byte to std. output
        inc     hl
        inc     c
        jr      pce_1

.pce_2
        ld      a, b                            ; pad with (b-c) spaces
        sub     c
        jr      z, pce_3
        add     a, $20
        push    af
        call    KPrint
        defm    1,"3N",0
        pop     af
        OZ      OS_Out
        ld      a, ' '
        OZ      OS_Out

.pce_3
        push    bc                              ; move cursor to start of string
.pce_4
        ld      a, BS
        OZ      OS_Out
        djnz    pce_4
        pop     bc

        pop     hl
        ret

.CommandTable
        defw    CmdEscape                       ; $20
        defw    CmdEnter                        ; $21
        defw    CmdLeft                         ; $22
        defw    CmdRight                        ; $23
        defw    CmdUp                           ; $24
        defw    CmdDown                         ; $25
        defw    CmdNextOption                   ; $26
        defw    CmdChgPage                      ; $27
        defw    CmdChgPage                      ; $28
        defw    CmdLoad                         ; $29
        defw    CmdSave                         ; $2A
        defw    CmdName                         ; $2B
        defw    CmdNew                          ; $2C
        defw    CmdUpdate                       ; $2D
        defw    CmdTranslations                 ; $2E

;       ----

.CmdEnter
        call    IsPanel                         ; panel? handle as escape
        jr      nz, CmdDown                     ; else handle as cursor down
        call    CmdUpdate                       ; apply and exit if panel
.ce_x
        jp      Exit

;       ----

.CmdEscape
        call    ClearEsc
        call    IsPanel                         ; panel? exit
        ret     nz
        jr      ce_x

;       ----

.ClearEsc
        push    af
        ld      a, SC_ACK
        OZ      OS_Esc
        pop     af
        ret

;       ----

.CmdUp
        ld      a, (iy+p_ubEntryID-p_Vars)      ; !! ld c,a, then jr z below
        cp      $20
        jr      z, up_1                         ; first entry on page? wrap
        dec     (iy+p_ubEntryID-p_Vars)
        ret

.up_1
        ld      b, (iy+p_ubPageID-p_Vars)
        ld      c, $20-1
.up_2
        inc     c
        call    GetEntryData
        jr      nz, up_2                        ; had more? loop
        dec     c
        ld      (iy+p_ubEntryID-p_Vars), c
        ret

;       ----

.CmdDown
        ld      bc, (p_ubEntryID)
        inc     c
        call    GetEntryData
        jr      nz, dn_1                        ; had more? don't wrap
        ld      c, $20
.dn_1
        ld      (iy+p_ubEntryID-p_Vars), c
        ret

;       ----

.CmdChgPage
        call    IsPanel
        ret     z
        cp      PRED_PAGE3
        jr      nz, ccp_1
        ld      a, PRED_PAGE1^1

.ccp_1
        xor     1
        ld      (iy+p_ubPageID-p_Vars), a
        ld      (iy+p_ubEntryID-p_Vars), $20
        jp      DrawScreenLabels

;       ----

.CmdTranslations
        ld      bc, PRED_PAGE3<<8|$20
        ld      (p_ubEntryID), bc
        jp      DrawScreenLabels

;       ----

;       !! this could be made much shorter if we relied on correct list order


.CmdRight
        ld      bc, (p_ubEntryID)
        call    GetEntryData
        ld      e, (hl)                         ; x
        inc     hl
        ld      d, (hl)                         ; y
        push    de
        ld      de, -1
        push    de
        push    de
        ld      ix, 0
        add     ix, sp                          ; [-1,-1,-1,-1,x,y]

        ld      b, (iy+p_ubPageID-p_Vars)
        ld      c, $20-1
.cr_1
        inc     c                               ; next entry
        push    ix
        call    GetEntryData
        pop     ix
        jr      z, cr_5                         ; no more? end

        ld      e, (hl)                         ; x
        inc     hl
        ld      d, (hl)                         ; y
        ld      a, d
        cp      (ix+5)
        jr      c, cr_1
        jr      nz, cr_2
        ld      a, e
        cp      (ix+4)
        jr      c, cr_1
        jr      z, cr_1

.cr_2                                           ; we are down/right of current
        ld      a, d
        cp      (ix+3)
        jr      z, cr_3
        jr      nc, cr_1
        jr      cr_4

.cr_3
        ld      a, e
        cp      (ix+2)
        jr      nc, cr_1

.cr_4                                           ; we are up/left of stored
        ld      (ix+2), e                       ; so store this
        ld      (ix+3), d
        ld      (ix+0), c
        ld      (ix+1), b
        jr      cr_1                            ; and loop

.cr_5
        bit     7, (ix+3)
        ld      b, (iy+p_ubPageID-p_Vars)       ; prepare for wrap
        ld      c, $20
        jr      nz, cr_6
        ld      c, (ix+0)                       ; otherwise use stored
        ld      b, (ix+1)

.cr_6
        pop     de
        pop     de
        pop     de
        ld      (p_ubEntryID), bc
        ret

;       ----

.CmdLeft
        ld      bc, (p_ubEntryID)
        call    GetEntryData
        ld      e, (hl)                         ; x
        inc     hl
        ld      d, (hl)                         ; y
        push    de
        ld      de, 0
        push    de
        push    de
        ld      ix, 0
        add     ix, sp                          ; [0,0,0,0,x,y]
        ld      b, (iy+p_ubPageID-p_Vars)
        ld      c, $20-1

.cl_1
        inc     c                               ; next entry
        push    ix
        call    GetEntryData
        pop     ix
        jr      z, cl_5                         ; no more? end
        ld      e, (hl)                         ; x
        inc     hl
        ld      d, (hl)                         ; y
        ld      a, d
        cp      (ix+5)
        jr      z, cl_2
        jr      nc, cl_1
        jr      cl_3

.cl_2
        ld      a, e
        cp      (ix+4)
        jr      nc, cl_1

.cl_3                                           ; we are down/right of current
        ld      a, d
        cp      (ix+3)
        jr      c, cl_1
        jr      nz, cl_4
        ld      a, e
        cp      (ix+2)
        jr      c, cl_1

.cl_4                                           ; we are up/left of stored
        ld      (ix+2), e                       ; so store this
        ld      (ix+3), d
        ld      (ix+0), c
        ld      (ix+1), b
        jr      cl_1                            ; and loop

.cl_5
        ld      c, (ix+0)                       ; prepare for wrap
        ld      b, (ix+1)
        ld      a, (ix+3)
        or      a
        jr      nz, cr_6
        ld      b, (iy+p_ubPageID-p_Vars)       ; otherwise use stored
        ld      c, $20-1
.cl_6
        inc     c
        call    GetEntryData
        jr      nz, cl_6
        dec     c
        jr      cr_6

;       ----

.CmdNextOption
        ld      bc, (p_ubEntryID)
        call    GetEntryData
        inc     e
        dec     e
        ret     z                               ; yes/no? exit
        call    MatchComboOption
        call    GetNextComboOption

        ld      de, (p_pMem_Buffer_100) ;       copy entry text into buffer
.cno_1
        ld      a, (hl)
        ld      (de), a
        inc     hl
        inc     de
        or      a
        jr      nz, cno_1

        call    ValidateInput
        call    c, PrintError
        ret

;       ----

;IN:
;OUT:   Fc=0, HL=optionText
;       Fc=1, HL=first option if not found

.MatchComboOption
        ld      bc, (p_ubEntryID)
        call    GetComboBox

.mco_1
        ld      c, l
        ld      b, h
        ld      de, (p_pMem_Buffer_100)
        dec     de

;       compare buffer with current optionText

.mco_2
        inc     de                              ; skip leading spaces
        ld      a, (de)
        cp      ' '
        jr      z, mco_2

.mco_3
        ld      a, (de)
        cp      ' '                             ; end at space
        jr      nz, mco_4
        xor     a

.mco_4
        call    ToUpper
        cp      (hl)
        inc     de
        inc     hl
        jr      nz, mco_6                       ; not same? try next option
        or      a
        jr      nz, mco_3                       ; not end? continue compare

        ld      l, c                            ; return matched entry
        ld      h, b
        ret

.mco_5
        inc     hl                              ; skip rest of option text
.mco_6
        ld      a, (hl)
        or      a
        jr      nz, mco_5

        inc     hl
        bit     7, (hl)
        jr      z, mco_1                        ; not end of list? compare next

        push    ix                              ; return first entry
        pop     hl
        scf                                     ; and carry
        ret

;       ----

;IN:    HL=optionText, IX=optionList
;OUT:   HL=optionText, A=optionChar

.GetNextComboOption

.gnco_1 inc     hl
        ld      a, (hl)
        cp      -1
        jr      z, gnco_2
        or      a
        jr      nz, gnco_1
        inc     hl
        ld      a, (hl)
        cp      -1
        jr      nz, SearchUpper                 ; else ret default
.gnco_2
        push    ix
        pop     hl                              ; and get OptionChar


;       ----

;IN:    HL=optionText
;OUT:   HL=optionText, A=optionChar

.SearchUpper
        push    hl
        dec     hl

.gu_loop
        inc     hl
        ld      a, (hl)
        or      a
        jr      z, gu_default                   ; ret if separator
        cp      -1
        jr      z, gu_default                   ; ret if end of table
        call    IsNum
        jr      c, gu_x                         ; ret if number
        call    IsAlpha
        jr      nc, gu_x                        ; ret if not alpha
        cp      '['
        jr      nc, gu_loop                     ; loop if not upper

.gu_x
        pop     hl
        ret

.gu_default
        pop     hl
        ld      a, (hl)                         ; ret with first char as OptionChar
        ret


;       ----

.CmdNew
        call    InitPagePtrs

.cnew_1
        call    GetEntryData
        jr      z, cnew_2                       ; no more entries?
        push    bc
        call    GetReason
        ld      a, 255
        OZ      OS_Sp                           ; set parameter
        pop     bc
        inc     c
        jr      cnew_1

.cnew_2
        call    NextPage
        jr      nz, cnew_1                      ; do next page

        call    IsPanel
        jr      z, cnew_3                       ; panel? skip

        ld      a, 255
        ld      bc, PA_Ptr
        OZ      OS_Sp                           ; set printer name

.cnew_3
        call    StoreDefSettings
        jp      DrawScreenLabels

;       ----

.CmdLoad
        call    AskFilename
        jp      c, PrintError

        call    is_1                            ; init settings
        ld      a, ERR_OutOfMemory
        jr      c, load_2                       ; error? exit

        ld      a, OP_IN
        ld      bc, 50
        ld      de, (p_pPrFileName_33)
        ld      hl, (p_pPrFileName_33)
        OZ      GN_Opf                          ; open file
        ld      a, 0
        jr      c, load_2                       ; error? exit
        ld      (p_pPrinterFileHandle), ix

.load_1
        call    ReadLn
        jr      c, load_2
        inc     e
        dec     e
        jr      z, save_5                       ; length=0? exit

        ld      hl, (p_pMem_Buffer_100)
        ld      a, (hl)
        cp      ' '
        ld      c, a                            ; entryID
        ld      a, ERR_BadFile
        jr      c, load_2                       ; error? exit

        inc     hl
        ld      a, (hl)
        cp      ' '
        ld      b, a                            ; pageID
        ld      a, ERR_BadFile
        jr      c, load_2                       ; error? exit

        inc     hl
        call    vi_4                            ; store setting
        jr      nc, load_1                      ; and loop

.load_2
        ld      hl, (p_pPrFileName_33)
        ld      (hl), 0
        push    af
        call    StoreAllSettings
        pop     af
        jr      save_5

;       ----

.CmdSave
        call    AskFilename
        jp      c, PrintError

        ld      a, OP_OUT
        ld      bc, 0<<8|17
        ld      de, 3                           ; ??
        ld      hl, (p_pPrFileName_33)
        OZ      GN_Opf                          ; open file/stream (or device)
        ld      a, 0
        jr      c, save_5                       ; error? exit
        ld      (p_pPrinterFileHandle), ix
        call    InitPagePtrs

.save_1
        push    bc
        call    GetEntryData
        jr      z, save_4                       ; no more? try next page

        ccf
        jr      nc, save_3                      ; not found? skip

        pop     bc
        push    bc
        ld      hl, (p_pMem_Buffer_100)
        ld      (hl), c                         ; entryID
        inc     hl
        ld      (hl), b                         ; pageID
        inc     hl

        push    ix                              ; copy data from IX to HL
        pop     de
.save_2
        ld      a, (de)
        ld      (hl), a
        inc     de
        inc     hl
        or      a
        jr      nz, save_2                      ; have more? loop
        call    SaveBuffer

.save_3
        pop     bc
        jr      c, save_5                       ; error? exit
        inc     c                               ; next entry
        jr      save_1                          ; and loop

.save_4
        pop     bc
        call    NextPage
        jr      nz, save_1                      ; have more? loop
        or      a                               ; Fc=0

.save_5
        push    af

        ld      de, (p_pPrinterFileHandle)      ; close file if it's open
        ld      a, e
        or      d
        jr      z, save_6
        push    de
        pop     ix
        OZ      OS_Cl
        jr      nc, save_8                      ; no error? skip

.save_6
        pop     af
        jr      c, save_7                       ; program error? print it
        ld      a, 0                            ; else system error
        scf
.save_7
        push    af

.save_8
        call    DrawScreenLabels
        pop     af
        call    c, PrintError
        ret

;       ----

.CmdName
        call    AskFilename
        push    af
        call    nc, DrawScreenLabels
        pop     af
        call    c, PrintError
        ret

;       ----

.InitSettings
        ld      hl, (p_pPrFileName_33)
        xor     a
        ld      (hl), a
        ld      (iy+p_ubFlags-p_Vars), a        ; not bound in yet

.is_1
        call    InitPagePtrs
        ld      (p_ubEntryID), bc

        ld      hl, (p_pSettingPool)            ; free memory if it's allocated
        ld      a, l
        or      h
        jr      z, is_2
        push    hl
        pop     ix
        OZ      OS_Mcl
        ld      hl, 0
        ld      (p_pSettingPool), hl

.is_2
        ld      a, MM_S1                        ; open new pool, segment 1
        ld      bc, 0
        OZ      OS_Mop
        ret     c                               ; error? exit
        ld      (p_pSettingPool), ix            ; !! move this above ret to save clearing above
        ld      hl, 0
        ld      (p_pSettings), hl               ; no setting memory allocated
        ret

;       ----

.SaveBuffer
        call    StrLen_Buffer
        dec     hl
        ld      (hl), CR                        ; terminate with linefeed
        ld      c, a
        ld      b, 0
        inc     bc
        ld      hl, (p_pMem_Buffer_100)
        ld      de, 0
        ld      ix, (p_pPrinterFileHandle)
        OZ      OS_Mv                           ; save buffer
        ld      a, 0                            ; system error (if Fc=1)
        ret

;       ----

;OUT:   E=length
;       Fc=1, A=error

.ReadLn
        ld      hl, (p_pMem_Buffer_100)
        ld      e, 0

.rdln_1
        ld      ix, (p_pPrinterFileHandle)
        OZ      OS_Gb                           ; get byte
        jr      nc, rdln_2                      ; no error? save byte

        cp      RC_Eof
        scf
        ld      a, 0                            ; system error
        ret     nz

        inc     e
        dec     e
        ld      a, ERR_BadFile
        scf
        ret     nz                              ; bytes without CR? error

        or      a                               ; Fc=0
        ret

.rdln_2
        inc     e                               ; bump length
        cp      CR                              ; end at CR
        jr      nz, rdln_3
        xor     a
.rdln_3
        ld      (hl), a
        or      a
        ret     z                               ; NULL? end
        cp      ' '
        jr      c, rdln_1                       ; ctrl char? ignore
        inc     hl
        jr      rdln_1

;       ----

;OUT:   Fc=status

.AskFilename
        ld      hl, 0
        ld      (p_pPrinterFileHandle), hl

        ld      hl, (p_pPrFileName_33)
        xor     a
        ld      (hl), a
        ld      c, a

.afn_1
        push    bc
        call    DrawFilenameWd
        pop     bc
        call    KPrint
        defm    $a0+1,$20+11,0

.afn_2
        ld      de, (p_pPrFileName_33)
        ld      a, 9                            ; has data, return special
        ld      b, $33
        call    CursorOn
        OZ      GN_Sip                          ; input line
        call    CursorOff
        call    c, MayRedraw
        jr      c, afn_1                        ; error? redraw

        cp      CR
        jr      z, afn_3                        ; enter? ok
        cp      ESC
        jr      nz, afn_2                       ; not esc? loop
        scf
        ld      a, ERR_Escape

.afn_3
        push    af
        call    UndrawFilenameWd
        pop     af
        push    af
        call    c, DrawScreenLabels
        pop     af
        ret

;       ----

.DrawFilenameWd
        call    KPrint
        defm    1,"7#2",$20+10,$20+0,$20+60,$20+8,$81
        defm    1,"2I2"
        defm    FF
        defm    $a0+1,$20+2,"Filename",0
        ret

;       ----

.UndrawFilenameWd
        call    KPrint
        defm    1,"2I1"
        defm    1,"2D2",0
        ret

;       ----

.ClearEscLdEsc
        call    ClearEsc
        ld      a, ESC
        or      a
        ret

;       ----

;IN:    A=error code
;OUT:   Fc=status, A=error code

.MayRedraw
        cp      RC_Quit
        jr      z, Exit
        cp      RC_Esc
        jr      z, ClearEscLdEsc
        cp      RC_Susp
        jr      z, mrd_1
        cp      RC_Draw
        scf
        ret     nz

.mrd_1
        push    bc
        push    de
        push    hl
        push    ix
        cp      RC_Draw
        jr      nz, mrd_2
        call    ValidateInput
        call    DrawScreenLabels

.mrd_2
        ld      bc, (p_ubEntryID)               ; reposition cursor
        call    GetEntryData
        call    MoveTo_HL
        pop     ix
        pop     hl
        pop     de
        pop     bc
        scf
        ret

.Exit
        ld      ix, (p_pSettingPool)
        OZ      OS_Mcl
        ld      ix, (p_pMemPool)
        OZ      OS_Mcl
        xor     a
        OZ      OS_Bye
        jr      $PC                             ; never reached

;       ----

.ErrorHandler
        ret     z
        cp      $46                             ; return FPP errors ($46-$4c) to system
        jr      c, errh_1
        cp      $4D
        ret     c                               ; c=1, z=0

.errh_1
        cp      RC_Quit
        jr      z, Exit
        cp      a                               ; c=0, z=1
        ret

;       ----

.PrintSysError2
        call    KPrint                          ; position
        defm    $20+0,$20+2,0

        OZ      OS_Erc
        OZ      GN_Esp
        ld      c, 16                           ; max 16 chars

.pse_1
        OZ      GN_Rbe                          ; read byte from error string
        or      a
        jr      z, pse_2                        ; end? exit
        OZ      OS_Out
        inc     hl
        dec     c
        jr      nz, pse_1

.pse_2
        scf
        ret

;       ----

.PrintSysError
        xor     a

;       ----

;IN:    A=error code


.PrintError
        push    af
        call    KPrint
        defm    BEL
        defm    1,"3@",0
        pop     af
        or      a
        jr      z, PrintSysError2
        dec     a
        add     a, a
        ld      e, a
        ld      d, 0
        ld      hl, ErrorTxt_tbl
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl

        push    hl
        ld      c, 0                            ; strlen
.prerr_1
        ld      a, (hl)
        inc     hl
        inc     c
        or      a
        jp      p, prerr_1

        ld      a, 16                           ; center to 16 char field
        sub     c
        jr      nc, prerr_2
        xor     a
.prerr_2
        srl     a
        add     a, $20
        OZ      OS_Out                          ; x position
        ld      a, $20+2
        OZ      OS_Out

        pop     hl
.prerr_3
        ld      a, (hl)
        push    af
        and     $7F
        OZ      OS_Out
        inc     hl
        pop     af
        bit     7, a                            ; !! or a; jr p
        jr      z, prerr_3

        scf
        ret

.ErrorTxt_tbl
        defw    OutOfMemory_txt
        defw    BadFile_txt
        defw    Escape_txt
        defw    BadCodeString_txt
        defw    StringTooLong_txt
        defw    BadValue_txt
        defw    BadName_txt

.OutOfMemory_txt
        defm    "Out of memor",'y'|$80
.BadFile_txt
        defm    "Bad fil",'e'|$80
.Escape_txt
        defm    "Escap",'e'|$80
.BadCodeString_txt
        defm    "Bad code strin",'g'|$80
.StringTooLong_txt
        defm    "String too lon",'g'|$80
.BadValue_txt
        defm    "Bad valu",'e'|$80
.BadName_txt
        defm    "Bad nam",'e'|$80

;       ----

.PrntBell
        ld      a, BEL
        OZ      OS_Out
        ret

;       ----

.CursorOff
        push    bc
        ld      c, '-'
        jr      CursorOnOff

.CursorOn
        push    bc
        ld      c, '+'

.CursorOnOff
        push    af
        ld      a, 1
        OZ      OS_Out
        ld      a, '2'
        OZ      OS_Out
        ld      a, c
        OZ      OS_Out
        ld      a, 'C'
        OZ      OS_Out
        pop     af
        pop     bc
        ret

;       ----

.ClrLine3
        call    KPrint
        defm    $a0+2,$20+0,1,"3N",$20+15," ",0
        ret

;       ----

.KPrint
        ex      (sp), hl

.kpr_1
        ld      a, (hl)
        or      a
        call    m, KprintSpecial
        inc     hl
        or      a
        jr      z, kpr_2
        OZ      OS_Out                          ; write a byte to std. output
        jr      kpr_1

.kpr_2
        ex      (sp), hl
        ret

.KprintSpecial
        cp      $A0
        ret     c
        cp      $C0
        ret     nc
        call    KPrint
        defm    1,"3@",0                        ; MoveTo
        ld      a, (hl)
        and     $7F                             ; 20-3F
        push    af
        inc     hl
        ld      a, (hl)
        OZ      OS_Out                          ; x
        pop     af
        OZ      OS_Out                          ; y
        inc     hl
        ld      a, (hl)
        ret

;       ----

;IN:    A=char
;OUT:   A=char

.ToUpper
        call    IsAlpha
        ret     nc
        and     $DF
        ret

;       ----

;IN:    A=char
;OUT:   Fc=1 if A is alphabetic

.IsAlpha
        cp      'A'
        ccf
        ret     nc
        cp      '['
        ret     c
        cp      'a'
        ccf
        ret     nc
        cp      '{'
        ret

;       ----

;IN:    A=char
;OUT:   Fc=1 if A is numeric

.IsNum
        cp      '0'
        ccf
        ret     nc
        cp      ':'
        ret

;       ----

.DrawScreenLabels
        call    KPrint
        defm    1,"7#1",$20+1,$20+0,$20+92,$20+8,$81
        defm    1,"2I1"
        defm    12,0

        call    IsPanel                         ; select between different pages
        jr      z, dsl_2
        sub     PRED_PAGE1
        jr      z, dsl_3
        dec     a
        jr      nz, dsl_1
        call    ShowPrEdPg2
        jr      dsl_4
.dsl_1
        call    ShowPrEdTrans
        jr      dsl_4
.dsl_2
        call    ShowPanel
        jr      dsl_4
.dsl_3
        call    ShowPrEdPg1

.dsl_4
        ld      b, (iy+p_ubPageID-p_Vars)
        ld      c, $20                          ; !! ld c, $20-1
        dec     c

.dsl_5
        inc     c
        call    PrintStrData
        jr      nz, dsl_5                       ; has more? loop
        call    IsPanel
        ret     z                               ; panel? we're done

        ld      hl, (p_pPrFileName_33)
        call    StrLen
        or      a
        ret     z                               ; no printer name? end

        ld      e, a
        call    TinyRvrs
        call    KPrint
        defm    $a0+4,$20+3," PRINTER ",0
        call    TinyRvrs

        ld      a, 16                           ; print centered
        sub     e
        jr      nc, dsl_6
        xor     a
.dsl_6
        srl     a
        push    af
        call    KPrint
        defm    1,"3@",0
        pop     af
        add     a, $20
        OZ      OS_Out
        ld      a, $20+5
        OZ      OS_Out

        ld      hl, (p_pPrFileName_33)
        ld      b, 15
.dsl_7
        ld      a, (hl)
        or      a
        jr      z, dsl_8                        ; end? done
        OZ      OS_Out
        inc     hl
        djnz    dsl_7

.dsl_8
        ld      hl, (p_pPrFileName_33)          ; extract filename part
        xor     a
        ld      bc, $FF20
        ld      de, (p_pPrinterName_20)
        OZ      GN_Esa                          ; read/write filename segments

        ld      hl, (p_pPrinterName_20)         ; name application
        OZ      DC_Nam
        ret

;       ----

.TinyRvrs
        call    KPrint
        defm    1,"T"
        defm    1,"R",0
        ret

;       ----

;       print comboox/number data

.PrintStrData
        call    GetEntryData
        ret     z                               ; done? exit
        push    bc
        push    af
        call    MoveTo_HL
        cp      $40
        jr      nz, psd_1                       ; not combo? skip
        pop     af

        push    de                              ; remember width
        call    GetComboBox                     ; a=selected
        pop     bc                              ; b=width
        call    PrintComboEntry
        jr      psd_4

.psd_1
        pop     af
        ld      b, d                            ; max width
        jr      c, psd_3                        ; not string? skip

        push    ix                              ; print saved data
        pop     hl
.psd_2
        ld      a, (hl)
        or      a
        jr      z, psd_3
        OZ      OS_Out
        inc     hl
        djnz    psd_2

.psd_3
        inc     b                               ; pad with spaces
        dec     b
        jr      z, psd_4
        call    KPrint
        defm    1,"3N",0
        ld      a, b
        add     a, $20
        OZ      OS_Out
        ld      a, ' '
        OZ      OS_Out

.psd_4
        inc     b                               ; Fz=0
        pop     bc
        ret

;       ----

;       move cursor

.MoveTo_HL
        push    af
        call    KPrint
        defm    1,"3@",0
        ld      a, (hl)                         ; x
        OZ      OS_Out
        inc     hl
        ld      a, (hl)                         ; y
        OZ      OS_Out
        inc     hl
        pop     af
        ret

;       ----

.StrcpyIX_Buffer
        push    af
        push    de
        ld      de, (p_pMem_Buffer_100)
        push    ix
.strc_1
        ld      a, (ix+0)
        ld      (de), a
        inc     ix
        inc     de
        or      a
        jr      nz, strc_1
        pop     ix
        pop     de
        pop     af
        ret

;       ----

;IN:    B=pageID, C=entryID
;OUT:   A=flags67, D=field width, E=flags0-3, HL=entrydata, IX=saved data
;       Fz=1 if not found

.GetEntryData
        ld      a, c
        sub     $20
        ld      l, a
        ld      h, 0
        ld      e, l
        ld      d, h
        add     hl, hl
        add     hl, hl
        add     hl, de                          ; (c-$20)*5
        ex      de, hl                          ; de=entry offset
        ld      hl, PrEdPg1Tbl                  ; select page data
        ld      a, b
        cp      PRED_PAGE1
        jr      z, ged_1
        ld      hl, PrEdPg2Tbl
        cp      PRED_PAGE2
        jr      z, ged_1
        ld      hl, PrEdTransTbl                ; just below
        cp      PRED_PAGE3
        jr      z, ged_1
        ld      hl, PanelTbl

.ged_1
        add     hl, de
        push    hl
        ld      hl, p_pSettings
        call    FindSetting
        push    hl
        pop     ix
        pop     hl
        push    hl
        ld      a, (hl)                         ; x
        inc     a
        push    af                              ; -1? Fz=1 and Fc=1
        inc     hl
        inc     hl
        ld      d, (hl)                         ; field width
        inc     hl
        ld      e, (hl)                         ; flags
        ld      a, e
        and     $C0                             ; bits 6&7
        ex      (sp), hl
        ld      h, a
        ex      (sp), hl
        ld      a, e
        and     $0F
        ld      e, a                            ; byte4, bits3-0
        pop     af
        pop     hl
        ret

;       ----

;OUT:   B=pageID, C=entryID

.InitPagePtrs
        push    af
        ld      bc, PRED_PAGE1<<8|$20           ; force PrEd page 1
        call    IsPanel
        jr      nz, ipp_1
        ld      b, a                            ; BC=PANELPAGE|$20
.ipp_1
        pop     af
        ret

;       ----

;IN:    B=pageID
;OUT:   B=pageID, C=entryID
;       Fc=1 if no more pages

.NextPage
        ld      a, b
        cp      PANELPAGE
        ret     z                               ; panel? exit
        inc     b
        ld      c, $20                          ; first entry
        ld      a, b
        cp      PRED_PAGE3+1                    ; wrap to PrEdPg1? set Z
        scf
        ret

;       ----

.IsPanel
        ld      a, (iy+p_ubPageID-p_Vars)
        cp      PANELPAGE
        ret

;       ----

.GetReason
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      c, (hl)
        ld      b, $80
        ret

;       ----

.ValidateInput
        ld      bc, (p_ubEntryID)
        call    GetEntryData
        cp      $40
        jr      z, vi_3                         ; combo?
        inc     e
        dec     e
        jr      z, vi_1                         ; yes/no? skip
        call    MatchComboOption                ; validate (only for baud rate)
        ld      a, ERR_BadValue
        ret     c

.vi_1
        ld      hl, (p_pMem_Buffer_100)
        call    IsPanel
        jr      nz, vi_2                        ; printered? check number
        call    CheckName                       ; else check device/dir
        ret     c
        jr      vi_3

.vi_2
        call    EncodeTranslate
        ret     c

.vi_3                                           ; store this setting
        ld      hl, (p_pMem_Buffer_100)
        ld      bc, (p_ubEntryID)

.vi_4
        push    hl
        push    bc
        call    StrLen
        pop     bc
        push    af
        ld      hl, p_pSettings
        call    StoreSetting
        pop     bc
        pop     de
        jr      c, vi_5                         ; error? exit
        inc     b
        dec     b
        ret     z                               ; no data? end

        ld      c, b                            ; else copy to allocated memory
        ld      b, 0
        inc     bc
        ex      de, hl
        ldir
        ret

.vi_5
        ld      a, ERR_OutOfMemory
        jp      PrintError

;       ----


.StrLen_Buffer
        ld      hl, (p_pMem_Buffer_100)

; a=stren(hl)

.StrLen
        xor     a
        ld      c, a
        ld      b, a
        cpir
        inc     bc
        ld      a, c
        neg
        ret

;       ----

;IN:    B=pageID, C=entryID, HL
;OUT:   DE=prev, HL=data
;       Fc=1 if not found

.FindSetting
        ld      e, l                            ; de=this
        ld      d, h
        ld      a, (de)                         ; hl=next(this)
        ld      l, a
        inc     de
        ld      a, (de)
        ld      h, a
        dec     de
        or      a
        scf
        ret     z
        push    hl                              ; do pageID & entryID match?
        pop     ix
        ld      a, b
        cp      (ix+4)                          ; pageID
        jr      nz, FindSetting
        ld      a, c
        cp      (ix+3)                          ; entryID
        jr      nz, FindSetting                 ; no, loop
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ret

;       ----

;IN:    A=length, B=pageID, C=entryID, HL=list, (Buffer)=data
;OUT:   HL=entrydata, IX=saved data
;       Fc=1 if error

.StoreSetting
        ld      d, a                            ; length
        or      a
        jr      z, sts_1                        ;zero? skip allocate

        push    hl
        push    bc
        add     a, 6                            ; overhead
        push    af
        ld      c, a
        ld      b, 0
        call    AllocSetting
        jr      c, sts_4                        ; error? exit
        ex      de, hl                          ; de=memory
        pop     af
        pop     bc
        pop     hl

.sts_1
        push    af
        push    bc
        push    de
        push    hl
        call    FindSetting
        jr      c, sts_2                        ; no saved setting
        push    ix
        pop     hl
        ld      a, (hl)                         ; prev.next=this.next
        ld      (de), a
        inc     hl
        inc     de
        ld      a, (hl)
        ld      (de), a
        inc     hl
        ld      c, (hl)                         ; bc=length
        ld      b, 0
        dec     hl
        dec     hl
        call    FreeSetting                     ; free saved setting

.sts_2
        pop     hl
        ld      bc, -1                          ; seek till end
        call    FindSetting                     ; de=last
        pop     hl
        pop     bc
        inc     h
        dec     h
        jr      z, sts_3                        ; not allocated? end

        ld      a, l                            ; last.next=hl
        ld      (de), a
        inc     de
        ld      a, h
        ld      (de), a

        push    hl                              ; ix=hl
        pop     ix

        inc     hl                              ; skip header
        inc     hl
        inc     hl
        inc     hl
        inc     hl
        ld      (ix+1), 0                       ; no next
        pop     af
        push    af
        ld      (ix+2), a                       ; length
        ld      (ix+3), c                       ; entry#
        ld      (ix+4), b                       ; page#

.sts_3
        pop     af
        or      a
        ret

.sts_4
        pop     hl
        pop     hl
        pop     hl
        ret

;       ----

;IN:    BC=size
;OUT:   HL=memory
;       Fc=1 if error

.AllocSetting
        ld      hl, (p_pSettingPool)
        ld      a, l
        or      h
        scf
        ret     z                               ; no mempool? error
        push    hl
        pop     ix
        call    AllocMem
        ret     c
        bit     0, (iy+p_ubFlags-p_Vars)
        ret     nz                              ; already bound in
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind it in S1
        set     0, (iy+p_ubFlags-p_Vars)
        or      a
        ret

;       ----

;IN:    BC=allocation size, IX=memory handle
;OUT:   BHL=memory
;       Fc=1 if no memory

.AllocMem
        xor     a
        OZ      OS_Mal
        ret

;       ----

;IN:    BC=size, HL=memory

.FreeSetting
        push    bc
        ld      c, MS_S1
        call    OZ_MGB
        ld      a, b
        pop     bc
        ld      ix, (p_pSettingPool)
        OZ      OS_Mfr
        ret

;       ----

.CmdUpdate
        call    InitPagePtrs

.cu_1
        call    GetEntryData
        jr      z, cu_10
        push    bc
        push    hl
        push    ix
        pop     hl
        rr      c                               ; save Fc from FindSetting()
        cp      $80
        jr      nz, cu_3                        ; not num? skip
        call    IsPanel
        jr      nz, cu_6                        ; not panel? jump
        rl      c
        jr      c, cu_2                         ; no saved data? skip

        FPP     FP_VAL                          ; str->num
        FPP     FP_ABS
        FPP     FP_FIX                          ; fix(abs(val(str))) !! might use int() instead of fix()
        exx
        ex      de, hl
        ld      hl, (p_pPrinterName_20)
        ld      (hl), e
        inc     hl
        ld      (hl), d
        dec     hl
        ld      a, 2                            ; return 2 bytes for word, 1 for byte
        inc     d
        dec     d
        jr      nz, cu_4
        dec     a
        jr      cu_4

.cu_2
        ld      a, -1
        jr      cu_4

.cu_3
        rl      c
        jr      c, cu_2                         ; no saved data? skip
        push    hl
        call    StrLen
        pop     hl

.cu_4
        ex      (sp), hl
        call    GetReason
        pop     hl

.cu_5
        jr      cu_9

.cu_6
        rl      c
        ld      bc, 0
        call    nc, EncodeTranslate             ; has saved data?
        pop     hl
        push    bc
        call    GetReason
        dec     hl
        bit     5, (hl)
        jr      z, cu_8
                                                ; handle placeholder
        push    bc                              ; placeholder, length
        ld      hl, 2
        add     hl, sp
        ld      a, (hl)                         ; placeholder
        or      a
        jr      z, cu_7                         ; no placeholder? skip !! should there be way to disable it?
        ld      a, 1                            ; single byte
        inc     c                               ; reason+3
        inc     c
        inc     c
        OZ      OS_Sp
        call    c, PrintSysError

.cu_7
        pop     bc

.cu_8
        pop     hl
        ld      a, h
        ld      hl, (p_pPrinterName_20)
.cu_9
        OZ      OS_Sp
        call    c, PrintSysError
        pop     bc
        inc     c                               ; entryID++
        jr      cu_1

.cu_10
        call    NextPage                        ; pageID++
        jr      nz, cu_1                        ; has more? loop
        jr      nc, cu_11                       ; panel? skip

        ld      hl, (p_pPrFileName_33)
        push    hl
        call    StrLen
        inc     a
        pop     hl
        ld      bc, PA_Ptr
        OZ      OS_Sp
        call    c, PrintSysError

.cu_11
        xor     a
        ld      bc, PA_Gfi
        OZ      OS_Sp                           ; install changed settings
        ret

;       ----

;OUT:   B=length, C=wild
;       Fc=1, A=error

.EncodeTranslate
        ld      ix, (p_pPrinterName_20)         ; output buffer
        ld      bc, 32<<8|0                     ; max 32 bytes, no wildchar

.etr_1
        dec     hl

.etr_2
        inc     hl
        ld      a, (hl)
        or      a
        jp      z, a2c_19                       ; end?

        cp      ','
        jr      z, etr_2                        ; comma? skip
        cp      ' '
        jr      z, etr_2                        ; space? skip
        call    IsNum
        jr      c, a2c_dec                      ; digit? number
        cp      '"'
        jr      z, a2c_asc                      ; quote? string
        cp      '$'
        jr      z, a2c_hex                      ; $? hhex
        cp      '?'
        jr      z, a2c_wild                     ; '?'? wildcard
        cp      '^'
        jr      z, a2c_ctrl                     ; ^? control char
        call    IsAlpha
        jr      c, a2c_name                     ; alpha? name

.a2c_err
        ld      a, ERR_BadCodeString
        scf
        ret

.a2c_dec
        push    bc
        ld      de, 2                           ; return integer in BC
        ld      b, 10
        OZ      GN_Gdn                          ; ASCII to integer conversion
        pop     de
        jr      nz, a2c_err                     ; not number?
        inc     b
        dec     b
        jr      nz, a2c_err                     ; >255?
        ld      a, c
        ld      c, e
        ld      b, d
        jr      a2c_10                          ; store char

.a2c_asc
        inc     hl
        ld      a, (hl)
        or      a
        jr      z, a2c_err                      ; end?
        cp      '"'
        jr      z, etr_2                        ; quote? done
        ld      (ix+0), a                       ; store and loop
        inc     ix
        djnz    a2c_asc

.a2c_6
        ld      a, ERR_StringTooLong
        jr      a2c_err

.a2c_hex
        inc     hl
        ld      a, (hl)
        call    AtoH
        jr      c, a2c_err                      ; not hex?
        ld      e, a
        inc     hl
        ld      a, (hl)
        call    AtoH
        jr      c, a2c_8                        ; single digit hex?
        sla     e
        sla     e
        sla     e
        sla     e
        add     a, e
        ld      e, a
        inc     hl

.a2c_8
        ld      a, e
        jr      a2c_10                          ; store char

.a2c_wild
        inc     hl
        ld      c, b                            ; has wildchar
        xor     a

.a2c_10
        ld      (ix+0), a                       ; store and loop if room
        inc     ix
        djnz    etr_1
        jr      a2c_6                           ; else error

.a2c_11
        pop     hl
        jr      a2c_err

.a2c_ctrl
        inc     hl
        ld      a, (hl)
        call    ToUpper                         ; only allow $00-$1f
        sub     $40
        jr      c, a2c_err                      ; !! unnecessary
        cp      $20
        jr      nc, a2c_err
        inc     hl
        jr      a2c_10

.a2c_name
        ld      de, ASCnames_txt
        push    hl
        dec     de
.a2c_14
        dec     hl
.a2c_15
        inc     hl
        inc     de
        ld      a, (de)
        cp      ' '
        jr      c, a2c_18                       ; control char? jump
        or      a
        jp      m, a2c_11                       ; negative? exit
        push    de
        ld      e, a
        ld      a, (hl)
        call    ToUpper
        cp      e
        pop     de
        jr      z, a2c_15                       ; same? continue compare

.a2c_16
        inc     de                              ; skip current ASCII name
        ld      a, (de)
        cp      ' '
        jr      nc, a2c_16

.a2c_17
        pop     hl                              ; restore string pointer and loop
        push    hl
        jr      a2c_14

.a2c_18
        ld      a, (hl)
        call    IsAlpha
        jr      c, a2c_17                       ; was alpha? try next

        ld      a, (de)                         ; get control char
        pop     de
        jr      a2c_10                          ; and store it

.a2c_19
        ld      a, 32
        sub     b
        ld      d, a                            ; length of data
        inc     c
        dec     c
        jr      z, a2c_22                       ; no wild? skip

;                                               ; fin placeholder $ff..$00 until we find unused char
        ld      e, 0
.a2c_20
        dec     e
        ld      b, d                            ; length
        ld      hl, (p_pPrinterName_20)
.a2c_21
        ld      a, (hl)
        inc     hl
        cp      e
        jr      z, a2c_20                       ; match? try smaller one
        djnz    a2c_21                          ; loop until done

        ld      hl, (p_pPrinterName_20)         ; replace wild with e
        ld      a, 32
        sub     c
        ld      c, a
        ld      b, 0
        add     hl, bc
        ld      (hl), e
        ld      c, e                            ; and return placeholder

.a2c_22
        ld      b, d
        or      a
        ret

;       ----

;IN:    A=char
;OUT:   A=nibble
;       Fc=1 if not hex
;
;!! bug $: -> $3a-$30=10 -> 10-7=3 -> valid hex?

.AtoH
        call    ToUpper
        sub     '0'
        ret     c
        cp      10
        ccf
        ret     nc
        sub     7
        cp      16
        ccf
        ret

;       ----

;IN:    HL=path
;OUT:   Fc=0 if ok
;       Fc=1, A=error

.CheckName
        ld      b, 0
        ld      a, (p_ubEntryID)
        cp      $23                             ; default device
        jr      z, chkn_dev
        cp      $24                             ; default directory
        scf
        ccf
        ret     nz

        dec     hl
.chkn_dir
        inc     hl
        ld      a, (hl)
        cp      ' '
        jr      z, chkn_dir                     ; space? skip
        or      a
        ret     z                               ; null? exit

        OZ      GN_Prs                          ; parse filename
        jr      c, chkn_err
        and     $F8
        jr      nz, chkn_err                    ; dir/device/wildcards? error
        ret                                     ; Fc=0

.chkn_dev
        OZ      GN_Pfs                          ; parse filename segment
        jr      c, chkn_err
        and     $BE
        ret     z                               ; no filename/directory/wildcards? Fc=0

.chkn_err
        ld      a, ERR_BadName
        scf
        ret

;       ----

;       !! it's possible to crash by overflowing stack buffer
;       with translation string like "zzzzz" where there are
;       more than 63 characters

.StoreDefSettings
        call    InitSettings
        ret     c

.StoreAllSettings
        call    IsPanel
        jr      z, sas_1
        ld      a, 49
        ld      bc, PA_Ptr
        ld      de, (p_pPrFileName_33)
        OZ      OS_Nq                           ; get printer name
.sas_1
        call    InitPagePtrs

.sas_2
        call    GetEntryData
        jr      z, sas_4                        ; end of page? skip

        push    bc

        push    af
        call    GetReason
        ld      a, 255
        ld      de, (p_pMem_Buffer_100)
        OZ      OS_Nq                           ; get parameter
        ld      b, a                            ; save #bytes
        pop     af

        cp      $80
        ld      a, b
        jr      nz, sas_9                       ; not number? skip

        or      a
        jr      z, sas_9                        ; no data? skip

        call    IsPanel
        jr      nz, sas_5                       ; not panel? show chr list

        ex      de, hl                          ; get byte/word into DE
        ld      d, 0
        ld      e, (hl)
        dec     b
        jr      z, sas_3
        inc     hl
        ld      d, (hl)
.sas_3                                          ; why not GN_Pdn here?
        ex      de, hl
        ld      de, 0                           ; de=00=general format, no digits
        exx
        ld      hl, 0
        ld      c, l                            ; HLhlC=00hl0=integer hl
        ld      de, (p_pMem_Buffer_100)
        FPP     FP_STR                          ; integer to ASCII
        jr      sas_8

.sas_4
        call    NextPage
        jr      nz, sas_2                       ; has more pages? loop
        or      a
        ret

;       character list into buffer

.sas_5
        ld      hl, -256                        ; reserve 256 bytes from stack
        add     hl, sp                          ; for comma-separated numbers
        ld      sp, hl
        ex      de, hl
        ld      hl, (p_pMem_Buffer_100)

.sas_6
        push    bc
        xor     a
        ld      c, (hl)
        ld      b, a
        push    hl
        ld      hl, 2
        OZ      GN_Pdn                          ; BC to (DE) as ASCII
        pop     hl
        pop     bc
        dec     b
        jr      z, sas_7                        ; end of data? stop
        ld      a, ','
        ld      (de), a                         ; comma delimeter and loop
        inc     de
        inc     hl
        jr      sas_6

.sas_7
        xor     a                               ; zero terminate
        ld      (de), a
        inc     de
        ld      hl, 0                           ; copy stack data into buffer
        add     hl, sp
        push    hl
        ex      de, hl
        sbc     hl, de
        ld      c, l
        ld      b, h                            ; BC=length
        pop     hl
        push    hl
        ld      de, (p_pMem_Buffer_100)
        ldir                                    ; copy into buffer
        pop     hl
        inc     h
        ld      sp, hl                          ; restore stack

.sas_8
        call    StrLen_Buffer

.sas_9
        pop     bc
        push    bc
        push    af
        ld      hl, p_pSettings
        call    StoreSetting
        pop     bc
        ex      de, hl
        jr      c, sas_11
        inc     b
        dec     b
        jr      z, sas_10
        ld      hl, (p_pMem_Buffer_100)
        ld      c, b
        ld      b, 0
        ldir
        xor     a
        ld      (de), a

.sas_10
        pop     bc
        inc     c
        jp      sas_2

.sas_11
        pop     bc
        ret

;       ----

.ASCnames_txt
        defm    "NUL",NUL
        defm    "NULL",NUL
        defm    "SOH",SOH
        defm    "STX",STX
        defm    "ETX",ETX
        defm    "EOT",EOT
        defm    "ENQ",ENQ
        defm    "ACK",ACK
        defm    "BEL",BEL
        defm    "BELL",BEL
        defm    "BS",BS
        defm    "TAB",HT
        defm    "HT",HT
        defm    "LF",LF
        defm    "VT",VT
        defm    "FF",FF
        defm    "CR",CR
        defm    "SO",SO
        defm    "SI",SI
        defm    "DLE",DLE
        defm    "DC1",DC1
        defm    "XON",DC1
        defm    "DC2",DC2
        defm    "DC3",DC3
        defm    "XOFF",DC3
        defm    "DC4",DC4
        defm    "NAK",NAK
        defm    "SYN",SYN
        defm    "ETB",ETB
        defm    "CAN",CAN
        defm    "EM",EM
        defm    "SUB",SUB
        defm    "ESC",ESC
        defm    "FS",FS
        defm    "GS",GS
        defm    "RS",RS
        defm    "US",US
        defm    -1

;Entry table format

;00     x+$20
;01     y+$20
;02     field width
;03     b7      numeric (if b4 as well then it's list of numbers)
;       b6      combo
;       b5      has placeholder? (only for reasons PA_OnX+3)
;       b4      string
;       b3-b0   combo type 0:[Y|N],2:[Ins|Ovr],4:[Eur|Am],6:[N|S|M|O|E],8:[Baud rates],10:[Localization]
;04     OS_Sp reason code low byte



.PrEdPg1Tbl
        defb    $45,$20,19,$B0,<PA_On1
        defb    $45,$21,19,$B0,<PA_On2
        defb    $45,$22,19,$B0,<PA_On3
        defb    $45,$23,19,$B0,<PA_On4
        defb    $45,$24,19,$B0,<PA_On5
        defb    $45,$25,19,$B0,<PA_On6
        defb    $45,$26,19,$B0,<PA_On7
        defb    $45,$27,19,$B0,<PA_On8

        defb    $61,$20,19,$90,<PA_On1+1
        defb    $61,$21,19,$90,<PA_On2+1
        defb    $61,$22,19,$90,<PA_On3+1
        defb    $61,$23,19,$90,<PA_On4+1
        defb    $61,$24,19,$90,<PA_On5+1
        defb    $61,$25,19,$90,<PA_On6+1
        defb    $61,$26,19,$90,<PA_On7+1
        defb    $61,$27,19,$90,<PA_On8+1

        defb    $79,$20,3,$40,<PA_On1+2
        defb    $79,$21,3,$40,<PA_On2+2
        defb    $79,$22,3,$40,<PA_On3+2
        defb    $79,$23,3,$40,<PA_On4+2
        defb    $79,$24,3,$40,<PA_On5+2
        defb    $79,$25,3,$40,<PA_On6+2
        defb    $79,$26,3,$40,<PA_On7+2
        defb    $79,$27,3,$40,<PA_On8+2
        defb    -1

.ShowPrEdPg1
        call    KPrint
        defm    $A0+0,$20+1,1,"T",1,"R"," PRINTER CODE ",1,"T",1,"R"
        defm    $A0+0,$20+16,"1"
        defm    $A0+0,$20+22,"ON"
        defm    $A0+0,$20+27,"Underline"
        defm    $A0+0,$20+61,"OFF"
        defm    $A0+0,$20+85,"Off"
        defm    $A0+1,$20+4,1,"T",1,"R"," EDITOR ",1,"T",1,"R"
        defm    $A0+1,$20+16,"2"
        defm    $A0+1,$20+18,"String"
        defm    $A0+1,$20+32,"Bold"
        defm    $A0+1,$20+58,"String"
        defm    $A0+1,$20+86,"at"
        defm    $A0+2,$20+16,"3"
        defm    $A0+2,$20+23,"Ext. sequence"
        defm    $A0+2,$20+86,"CR"
        defm    $A0+3,$20+16,"4"
        defm    $A0+3,$20+29,"Italics"
        defm    $A0+4,$20+16,"5"
        defm    $A0+4,$20+27,"Subscript"
        defm    $A0+5,$20+16,"6"
        defm    $A0+5,$20+25,"Superscript"
        defm    $A0+6,$20+5,"Page 1"
        defm    $A0+6,$20+16,"7"
        defm    $A0+6,$20+27,"Alt. font"
        defm    $A0+7,$20+0,1,"R",1,"T","Page 2: SHIFT ",1,$0FA,1,"T",1,"R"
        defm    $A0+7,$20+16,"8"
        defm    $A0+7,$20+24,"User defined"
        defm    0
        ret

.PrEdPg2Tbl
        defb    $3D,$20,20,$90,<PA_Pon
        defb    $3D,$21,20,$90,<PA_Pof
        defb    $3D,$22,20,$90,<PA_Eop
        defb    $3D,$23,3,$40,<PA_Alf
        defb    $3D,$24,20,$90,<PA_Mip
        defb    $3D,$25,20,$90,<PA_Mis
        defb    $3D,$26,20,$90,<PA_Mio

        defb    $60,$21,5,$80,<PA_Tr1
        defb    $60,$22,8,$90,<PA_Tr1+1
        defb    $60,$23,5,$80,<PA_Tr4
        defb    $60,$24,8,$90,<PA_Tr4+1
        defb    $60,$25,5,$80,<PA_Tr7
        defb    $60,$26,8,$90,<PA_Tr7+1

        defb    $69,$21,5,$80,<PA_Tr2
        defb    $69,$22,8,$90,<PA_Tr2+1
        defb    $69,$23,5,$80,<PA_Tr5
        defb    $69,$24,8,$90,<PA_Tr5+1
        defb    $69,$25,5,$80,<PA_Tr8
        defb    $69,$26,8,$90,<PA_Tr8+1

        defb    $72,$21,5,$80,<PA_Tr3
        defb    $72,$22,8,$90,<PA_Tr3+1
        defb    $72,$23,5,$80,<PA_Tr6
        defb    $72,$24,8,$90,<PA_Tr6+1
        defb    $72,$25,5,$80,<PA_Tr9
        defb    $72,$26,8,$90,<PA_Tr9+1
        defb    -1

;       ----

.ShowPrEdPg2
        call    KPrint
        defm    $A0+0,$20+1,1,"T",1,"R"," PRINTER CODE ",1,"T",1,"R"
        defm    $A0+0,$20+18,"Printer on"
        defm    $A0+0,$20+51,"Translations"
        defm    $A0+0,$20+66,1,"T",1,"R"," A "
        defm    $A0+0,$20+75," B "
        defm    $A0+0,$20+84," C ",1,"T",1,"R"
        defm    $A0+1,$20+4,1,"T",1,"R"," EDITOR ",1,"T",1,"R"
        defm    $A0+1,$20+17,"Printer off"
        defm    $A0+1,$20+54,"Character"
        defm    $A0+2,$20+17,"End of page"
        defm    $A0+2,$20+53,"Changes to"
        defm    $A0+3,$20+13,"Allow line feed"
        defm    $A0+3,$20+54,"Character"
        defm    $A0+4,$20+17,"HMI: Prefix"
        defm    $A0+4,$20+53,"Changes to"
        defm    $A0+5,$20+22,"Suffix"
        defm    $A0+5,$20+54,"Character"
        defm    $A0+6,$20+5,"Page 2"
        defm    $A0+6,$20+22,"Offset"
        defm    $A0+6,$20+53,"Changes to"
        defm    $A0+7,$20+0,1,"R",1,"T","Page 1: SHIFT ",1,$0FB,1,"R",1,"T"
        defm    0
        ret

;       ----
.PrEdTransTbl
        defb    $3C, $20, $05, $80, $80
        defb    $3C, $21, $08, $90, $81
        defb    $3C, $22, $05, $80, $8E
        defb    $3C, $23, $08, $90, $8F
        defb    $3C, $24, $05, $80, $9C
        defb    $3C, $25, $08, $90, $9D
        defb    $3C, $26, $05, $80, $AA
        defb    $3C, $27, $08, $90, $AB
        defb    $45, $20, $05, $80, $82
        defb    $45, $21, $08, $90, $83
        defb    $45, $22, $05, $80, $90
        defb    $45, $23, $08, $90, $91
        defb    $45, $24, $05, $80, $9E
        defb    $45, $25, $08, $90, $9F
        defb    $45, $26, $05, $80, $AC
        defb    $45, $27, $08, $90, $AD
        defb    $4E, $20, $05, $80, $84
        defb    $4E, $21, $08, $90, $85
        defb    $4E, $22, $05, $80, $92
        defb    $4E, $23, $08, $90, $93
        defb    $4E, $24, $05, $80, $A0
        defb    $4E, $25, $08, $90, $A1
        defb    $4E, $26, $05, $80, $AE
        defb    $4E, $27, $08, $90, $AF
        defb    $57, $20, $05, $80, $86
        defb    $57, $21, $08, $90, $87
        defb    $57, $22, $05, $80, $94
        defb    $57, $23, $08, $90, $95
        defb    $57, $24, $05, $80, $A2
        defb    $57, $25, $08, $90, $A3
        defb    $57, $26, $05, $80, $B0
        defb    $57, $27, $08, $90, $B1
        defb    $60, $20, $05, $80, $88
        defb    $60, $21, $08, $90, $89
        defb    $60, $22, $05, $80, $96
        defb    $60, $23, $08, $90, $97
        defb    $60, $24, $05, $80, $A4
        defb    $60, $25, $08, $90, $A5
        defb    $60, $26, $05, $80, $B2
        defb    $60, $27, $08, $90, $B3
        defb    $69, $20, $05, $80, $8A
        defb    $69, $21, $08, $90, $8B
        defb    $69, $22, $05, $80, $98
        defb    $69, $23, $08, $90, $99
        defb    $69, $24, $05, $80, $A6
        defb    $69, $25, $08, $90, $A7
        defb    $69, $26, $05, $80, $B4
        defb    $69, $27, $08, $90, $B5
        defb    $72, $20, $05, $80, $8C
        defb    $72, $21, $08, $90, $8D
        defb    $72, $22, $05, $80, $9A
        defb    $72, $23, $08, $90, $9B
        defb    $72, $24, $05, $80, $A8
        defb    $72, $25, $08, $90, $A9
        defb    $72, $26, $05, $80, $B6
        defb    $72, $27, $08, $90, $B7
        defb    $ff

.ShowPrEdTrans
        call    KPrint
        defm    $A0+0,$20+1,1,"T",1,"R"," PRINTER CODE ",1,"T",1,"R"
        defm    $A0+0,$20+18,"Character"
        defm    $A0+1,$20+4,1,"T",1,"R"," EDITOR ",1,"T",1,"R"
        defm    $A0+1,$20+17,"Changes to"
        defm    $A0+2,$20+18,"Character"
        defm    $A0+3,$20+17,"Changes to"
        defm    $A0+4,$20+18,"Character"
        defm    $A0+5,$20+17,"Changes to"
        defm    $A0+6,$20+18,"Character"
        defm    $A0+7,$20+0,1,"R",1,"T","ISO Translations ",1,$0FB,1,"R",1,"T"
        defm    $A0+7,$20+17,"Changes to"
        defm    0
        ret

.PanelTbl
        defb    $42,$20,2,$80|0,<PA_Rep
        defb    $42,$21,3,$40|0,<PA_Kcl
        defb    $42,$22,8,$40|2,<PA_Iov
        defb    $42,$26,57,$10|0,<PA_Dev
        defb    $42,$27,57,$10|0,<PA_Dir

        defb    $5C,$20,2,$80|0,<PA_Mct
        defb    $5C,$21,3,$40|0,<PA_Snd
        defb    $5C,$22,3,$40|0,<PA_Map
        defb    $5C,$23,3,$80|0,<PA_Msz
        defb    $5C,$24,8,$40|4,<PA_Dat

        defb    $76,$20,5,$80|8,<PA_Txb
        defb    $76,$21,5,$80|8,<PA_Rxb
        defb    $76,$22,5,$40|6,<PA_Par
        defb    $76,$23,3,$40|0,<PA_Xon

        defb    $70,$25,14,$40|10,<PA_Loc
        defb    -1

.ShowPanel
        call    KPrint
        defm    $A0+3,$20+2,1,"R",1,"T"," PRESS ENTER ",1,"T",1,"R"
        defm    $A0+4,$20+2,1,"R",1,"T","  TO UPDATE  ",1,"T",1,"R"

        defm    $A0+0,$20+17,"Auto repeat rate"
        defm    $A0+0,$20+45,"Timeout (mins)"
        defm    $A0+0,$20+67,"Transmit baud rate"
        defm    $A0+1,$20+25,"Keyclick"
        defm    $A0+1,$20+54,"Sound"
        defm    $A0+1,$20+68,"Receive baud rate"
        defm    $A0+2,$20+18,"Insert/Overtype"
        defm    $A0+2,$20+56,"Map"
        defm    $A0+2,$20+79,"Parity"
        defm    $A0+3,$20+51,"Map size"
        defm    $A0+3,$20+77,"Xon/Xoff"
        defm    $A0+4,$20+48,"Date format"
        defm    $A0+5,$20+71,"Keyboard"
        defm    $A0+6,$20+19,"Default device"
        defm    $A0+7,$20+16,"Default directory"
        defm    0
        ret

.ComboBox_tbl
        defw    YesNoTxt_tbl
        defw    CursorTxt_tbl
        defw    FormatTxt_tbl
        defw    ParityTxt_tbl
        defw    BaudTxt_tbl
        defw    Keymap_tbl

.YesNoTxt_tbl
        defm    "Yes",0
        defm    "No"
        defm    -1

.CursorTxt_tbl
        defm    "Insert",0
        defm    "Overtype"
        defm    -1

.FormatTxt_tbl
        defm    "European",0
        defm    "American"
        defm    -1

.ParityTxt_tbl
        defm    "None",0
        defm    "Space",0
        defm    "Mark",0
        defm    "Odd",0
        defm    "Even"
        defm    -1

.BaudTxt_tbl
        defm    "9600",0
        defm    "19200",0
        defm    "38400",0
        defm    "75",0
        defm    "300",0
        defm    "600",0
        defm    "1200",0
        defm    "2400",0
        defm    -1

.Keymap_tbl
        defm    "Uk",0                          ; U
        defm    "France",0                      ; F
        defm    "Denmark",0                     ; D
        defm    "Sweden",0                      ; S
        defm    "finLand",0                     ; L
        defm    "Germany",0                     ; G
        defm    "usA",0                         ; A
        defm    "sPain",0                       ; P
        defm    -1

; Gbs 2011/01/29: Uncomment each layout below, when implemented, first "Italy", then "Norway", etc...
;
;        defm    "Italy",0                       ; I
;        defm    "Norway",0                      ; N
;        defm    "sWitzerland",0                 ; W
;        defm    "iCeland",0                     ; C
;        defm    "Japan",0                       ; J
;        defm    "Turkey"                        ; T
;        defm    -1

.endOfPanelData
