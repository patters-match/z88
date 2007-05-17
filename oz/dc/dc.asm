; **************************************************************************************************
; Index popdown and DC system calls.
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

        Module DC_Calls

        include "blink.def"
        include "char.def"
        include "director.def"
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "integer.def"
        include "memory.def"
        include "serintfc.def"
        include "stdio.def"
        include "syspar.def"
        include "time.def"
        include "printer.def"
        include "sysvar.def"
        include "sysapps.def"
        include "keyboard.def"

        include "../os/lowram/lowram.def"
        include "dc.def"

        org     ORG_INDEX

xdef    InitProc, AddProc, GetNextProc, GetProcHandle, GetProcByHandle, GetProcEnvIDHandle
xdef    PutProcHndl_IX
xdef    ReadDateTime
xdef    GetLinkBHL
xdef    ZeroMem

xref    Index
xref    addHL_2xA
xref    ldIX_DE


.IndexEntry
        jp      Index
        jp      DCRet

        defw    Index
        defw    DCBye
        defw    DCEnt
        defw    DCNam
        defw    DCIn
        defw    DCOut
        defw    DCPrt
        defw    DCIcl
        defw    DCNq
        defw    DCSp
        defw    DCAlt
        defw    DCRbd
        defw    DCXin
        defw    DCGen
        defw    DCPol

.DCRet
        pop     iy
        pop     bc
        ld      a, c
        ld      (BLSC_SR2), a
        out     (BL_SR2), a
        pop     af
        pop     af
        pop     bc
        pop     de
        pop     hl
        jp      OZ_RET1



;       Pass an alternative character
;       Handles keys after []
;
;       IN:     A=char

.DCAlt
        push    ix

        or      a
        jr      z, dcalt_3

;       +       set flag and exit

        cp      '+'
        jr      nz, dcalt_1
        ld      a, (ubIdxFlags2)
        and     ~IDXF2_ALTMINUS
        or      IDXF2_ALTPLUS
        jr      dcalt_5

;       -       set flag and exit

.dcalt_1
        cp      '-'
        jr      nz, dcalt_2
        ld      a, (ubIdxFlags2)
        and     ~IDXF2_ALTPLUS
        or      IDXF2_ALTMINUS
        jr      dcalt_5

.dcalt_2
        OZ      GN_Cls                          ; Classify a character
        jr      nc, dcalt_3                     ; not [a-zA-Z]

        and     $df                             ; upper
        ld      (iy+OSFrame_A), a               ; store for later use
        ld      c, a
        ld      a, (ubIdxFlags2)                ; was it prefixed by + or -
        and     IDXF2_ALTMINUS | IDXF2_ALTPLUS
        ld      a, c
        jp      nz, dcalt_18                    ; yes, go handle P/K/S

;       application key

        cp      'Z'
        jr      nz, dcalt_6                     ; not Z, find it in table
        ld      a, (ubIdxFlags2)                ; get Z count
        and     IDXF2_ZCOUNT
        cp      2
        jr      c, dcalt_4

.dcalt_3
        ld      a, (ubIdxFlags2)                ; clear DC_Alt bits
        and     ~(IDXF2_ALTMINUS|IDXF2_ALTPLUS|IDXF2_ZCOUNT)
        ld      (ubIdxFlags2), a
        jp      dcalt_err2                      ; return syntax error

.dcalt_4
        ld      a, (ubIdxFlags2)                ; add one more Z
        inc     a

.dcalt_5
        ld      (ubIdxFlags2), a                ; store flags and exit
        jp      dcalt_x

;       A-Y, find application

.dcalt_6
        ld      hl, IdxKeyTable                 ; find correct key table
        ld      a, (ubIdxFlags2)
        and     IDXF2_ZCOUNT
        jr      z, dcalt_7
        ld      hl, IdxZKeyTable
        dec     a
        jr      z, dcalt_7
        ld      hl, IdxZZKeyTable

.dcalt_7
        ld      a, (ubIdxFlags2)                ; clear DC_Alt flags
        and     ~(IDXF2_ALTMINUS | IDXF2_ALTPLUS | IDXF2_ZCOUNT)
        ld      (ubIdxFlags2), a

        ld      a, (iy+OSFrame_A)
        sub     'A'
        call    addHL_2xA
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        call    ldIX_DE
        jp      z, dcalt_err2                   ; no application, syntax error

        push    iy
        ld      iy, (eIdxProcList)
        ld      a, (eIdxProcList+2)
        ld      b, a
        ld      c, MS_S1
        rst     OZ_MPB                          ; remember S1
        push    bc
        call    GetProcHandle

        push    de
        ex      (sp), ix                        ; static handle
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        pop     ix

        and     AT_Popd|AT_Ones
        jr      z, dcalt_8

        push    ix                              ; popdown or only once runnable, return
        pop     de                              ; with syntax error if it's running process
        ld      a, d
        cp      (iy+prc_hndl+1)
        jr      nz, dcalt_8
        ld      a, e
        cp      (iy+prc_hndl)
        jr      z, dcalt_9

.dcalt_8
        call    GetProcByHandle                 ; get oldest running copy
        jr      c, dcalt_10                     ; none, start new one

        ld      a, (eIdxProcList+2)             ; if this is running process then
        cp      b                               ; exit with syntax error
        jr      nz, dcalt_11
        ld      a, (eIdxProcList+1)
        cp      h
        jr      nz, dcalt_11
        ld      a, (eIdxProcList)
        cp      l
        jr      nz, dcalt_11

.dcalt_9
        pop     bc
        rst     OZ_MPB                          ; restore S1
        jr      dcalt_er3                       ; syntax error

.dcalt_10
        xor     a                               ; start new process
        ld      b, a
        ld      h, a
        ld      l, a

.dcalt_11
        ld      (pIdxRunProcIX), ix
        ld      a, b
        ld      (eIdxRunProc+2), a
        ld      (eIdxRunProc), hl

        ld      ix, (pIdxCurrentProcHandle)
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        and     AT_Ugly|AT_Popd
        pop     bc
        push    af
        rst     OZ_MPB                          ; restore S1
        pop     af
        jr      z, dcalt_12
        ld      b, 0                            ; ugly application or popdown
        OZ      OS_Exit                         ; exit current process

.dcalt_12
        OZ      OS_Stk                          ; Stack file current process
        jr      nc, dcalt_13

        call    ZeroeIdxRunProc                 ; don't run application
        ld      a, RC_Pre                       ; Cannot pre-empt, or No Room
        OZ      GN_Err
        pop     iy
        jr      dcalt_err1                      ; exit

.dcalt_13
        push    bc
        ld      iy, (eIdxProcList)
        ld      a, (eIdxProcList+2)
        ld      b, a
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind proc in S1
        pop     bc
        ld      (iy+prc_stkProcEnv+2),  b
        ld      (iy+prc_stkProcEnv+1),  h
        ld      (iy+prc_stkProcEnv),    l
        call    ReadDateTime                    ; store suspension date

        ld      hl, (eIdxRunProc)
        ld      a, (eIdxRunProc+2)
        ld      b, a
        ld      ix, (pIdxRunProcIX)
        call    ZeroeIdxRunProc
        OZ      DC_Ent                          ; Enter new application

.dcalt_er3
        pop     iy
.dcalt_err2
        ld      a, RC_Sntx
        set     Z80F_B_Z, (iy+OSFrame_F)
.dcalt_err1
        call    SetOsfError
.dcalt_x
        pop     ix
        ret

;       []+ or []-

.dcalt_18
        push    iy
        ex      af, af'                         ; remember char
        ld      a, (ubIdxFlags2)
        and     IDXF2_ALTPLUS
        push    af                              ; store +/- status
        ex      af, af'                         ; restore char

        cp      'P'
        jr      nz, dcalt_22
        pop     af
        jr      z, dcalt_20

;       []+P

        ld      a, 5                            ; send 5,"[" to printer filter
        OZ      OS_Prt
        ld      a, '['
        OZ      OS_Prt
        call    GetFirstCli                     ; if we have running CLI rebind it's output to printer
        jr      z, dcalt_19

        ld      bc, NQ_Phn
        OZ      OS_Nq                           ; get printer indirected handle
        ld      e, RB_OPT                       ; rebind output tee into it
        jr      dcalt_29

.dcalt_19
        ld      hl, RedirOutPrt_cli             ; start new CLI
        ld      bc, 11
        jr      dcalt_26

;       []-P

.dcalt_20
        ld      a, 5
        OZ      OS_Prt                          ; send 5,"]" to printer filter
        ld      a, ']'
        OZ      OS_Prt

;       []-S

.dcalt_21
        ld      e, RB_OPT                       ; close output tee
        jr      dcalt_28


.dcalt_22
        cp      'S'
        jr      nz, dcalt_24
        pop     af
        jr      z, dcalt_21

;       []+S

        call    GetFirstCli
        jr      z, dcalt_23
        ld      hl, Ssgn_name                   ; rebind CLI's output to SS.sgn
        call    OpenWrite
        jr      c, dcalt_31
        ld      e, RB_OPT
        jr      dcalt_29

.dcalt_23
        ld      hl, RedirOutSsgn_cli            ; start new CLI
        ld      bc, 19
        jr      dcalt_26

.dcalt_24
        cp      'K'
        jr      nz, dcalt_30
        pop     af
        jr      z, dcalt_27

;       []+K

        call    GetFirstCli
        jr      z, dcalt_25
        ld      hl, Ksgn_name                   ; rebind CLI's output to K.sgn
        call    OpenWrite
        jr      c, dcalt_31
        ld      e, RB_INT
        jr      dcalt_29

.dcalt_25
        ld      hl, RedirInKsgn_cli             ; start new CLI
        ld      bc, 19

.dcalt_26
        OZ      DC_Icl                          ; Invoke new CLI
        jr      dcalt_31

;       []-K

.dcalt_27
        ld      e, RB_INT                       ; close input tee

.dcalt_28
        ld      ix,0
        call    GetFirstCli
        jr      z, dcalt_31

.dcalt_29
        ld      a, e
        OZ      DC_Rbd                          ; Rebind streams
        jr      dcalt_31

.dcalt_30
        pop     af

.dcalt_31
        ld      a, (ubIdxFlags2)
        and     ~(IDXF2_ALTPLUS | IDXF2_ALTMINUS)
        ld      (ubIdxFlags2), a
        pop     iy
        jp      dcalt_err2                      ; syntax error

;       ----


.OpenWrite
        ld      a, OP_OUT
        jr      open_1

.OpenRead
        ld      a, OP_IN

.open_1
        push    bc
        push    af

.open_2
        ld      a, (hl)                         ; skip spaces
        cp      ' '
        jr      nz, open_3
        inc     hl
        jr      open_2

.open_3
        pop     af
        ld      de, 3                           ; NUL, ignore name
        ld      bc, $FF
        OZ      GN_Opf
        pop     bc
        ret

;       ----

.RedirOutPrt_cli
        defm    ".T>:PRT",13
        defm    ".S",0

.RedirInKsgn_cli
        defm    ".T<"
.Ksgn_name
        defm    ":Ram.-/K.sgn",13
        defm    ".S",0
.RedirOutSsgn_cli
        defm    ".T>"
.Ssgn_name
        defm    ":Ram.-/S.sgn",13
        defm    ".S",0

;       ----

;       read date and time into process structure

.ReadDateTime
        push    iy
        pop     hl
        ld      de, prc_date
        add     hl, de
        ex      de, hl
        OZ      GN_Gmd                          ; get machine date in (DE)
        push    iy
        pop     hl
        ld      de, prc_time
        add     hl, de
        ex      de, hl
        ld      c, (iy+prc_date)
        OZ      GN_Gmt                          ; get system time in (DE)
        jr      nz, ReadDateTime                ; time  not consistent
        ret

;       ----

;       exiting current application
;       IN:     A=return code

.DCBye
        push    iy
        call    FreeProc                        ; free running process

        pop     iy                              ; set error
        ld      a, (iy+OSFrame_A)
        ld      (ubIdxErrorCode), a
        or      a
        jr      z, dcbye_1

        call    ZeroeIdxRunProc
        ld      hl, ubIdxFlags2
        set     IDXF2_B_ERROR, (hl)
        jr      dcbye_2

.dcbye_1
        ld      ix, (pIdxCurrentProcHandle)
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get appl data
        and     AT_Ugly|AT_Popd
        jr      nz, dcbye_3

.dcbye_2
        OZ      OS_Pout                         ; clear screen and start Index
        defm    1,"6#8",$20+0,$20+0,$20+94,$20+8
        defm    1,"2C8", 0

        ld      b, 0
        ld      ix, (pIdxMyProcHandle)
        jr      dcbye_4

.dcbye_3
        ld      de, (pIdxRunProcIX)             ; ugly or popdown
        push    de
        pop     ix
        ld      a, (eIdxRunProc+2)
        ld      hl, (eIdxRunProc)
        ld      b, a
        call    ZeroeIdxRunProc
        or      d
        or      e
        jr      nz, dcbye_4                     ; enter that process

        ld      ix, (pIdxCurrentProcHandle)
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get appl data
        and     AT_Popd
        jr      z, dcbye_2

        ld      a, (eIdxProcList+2)             ; return to first process
        ld      hl, (eIdxProcList)
        ld      b, a
        or      h
        or      l
        jr      z, dcbye_2

.dcbye_4
        OZ      DC_Ent                          ; Enter new application

;       ----

;       enter new application
;       BHL = points to the process block
;       B = 0, start a new process
;       IX = the application handle

.DCEnt
        push    hl
        ld      hl, ubIdxFlags2
        res     IDXF2_B_6, (hl)
        pop     hl
        ld      a, b
        or      a
        jr      z, dcent_1                      ; start new

        ld      iy, eIdxProcList
        call    RemoveBHL                       ; remove from list
        jr      c, dcent_4                      ; not found
        call    AddProc                         ; and insert at top
        jr      dcent_2

.dcent_1
        push    ix                              ; is this Index?
        ld      de, (pIdxMyProcHandle)
        ex      (sp), hl
        ex      de, hl
        sbc     hl, de
        ex      de, hl
        ex      (sp), hl
        pop     ix
        jr      z, dcent_6                      ; go to Index

        push    ix                              ; allocate memory for process
        ld      ix, (pIdxMemHandle)
        ld      bc, prc_SIZEOF
        xor     a
        OZ      OS_Mal
        pop     ix
        jr      c, dcent_4
        call    AddProc
        call    InitProc
        call    PutProcHndl_IX
        ld      hl, ubIdxFlags2
        set     IDXF2_B_6, (hl)

.dcent_2
        ld      sp, $1FFE
        OZ      OS_Pout
        defm    1,"2.[",0

        call    GetProcEnvIDHandle
        ld      (pIdxCurrentProcHandle), de

        ld      a, (ubIdxFlags2)                ; check if it's quitting time
        bit     IDXF2_B_KILL, a
        jr      z, dcent_3
        res     IDXF2_B_KILL, a
        ld      (ubIdxFlags2), a
        OZ      OS_Exit                         ; Quit process
        jr      dcent_5

.dcent_3
        OZ      OS_Ent                          ; Enter an application

;       program execution doesn't return here!

.dcent_4
        ld      a, RC_Pre                       ; Cannot pre-empt, or No Room

.dcent_5
        ld      (ubIdxErrorCode), a
        ld      hl, ubIdxFlags2
        set     IDXF2_B_ERROR, (hl)
        bit     IDXF2_B_6, (hl)
        call    nz, FreeProc

.dcent_6
        ld      a, (eIdxIndexProc+2)            ; enter Index
        ld      b, a
        ld      hl, (eIdxIndexProc)
        call    AddProc
        ld      ix, (pIdxMyProcHandle)
        ld      (pIdxCurrentProcHandle), ix
        ld      b, 0
        ld      c, (iy+prc_dynid)
        OZ      OS_Ent                          ; Enter an application

.dcent_7
        jr      dcent_7                         ; crash


;       ----

.ZeroeIdxRunProc
        xor     a
        ld      (pIdxRunProcIX), a
        ld      (pIdxRunProcIX+1), a
        ld      (eIdxRunProc+2), a
        ret

;       ----

;       initialize new process

.InitProc
        push    bc
        push    iy
        pop     hl
        inc     hl                              ; skip link
        inc     hl
        inc     hl
        ld      b, prc_SIZEOF-3                 ; clear rest of proc struct
        call    ZeroMem

        ld      (iy+prc_matchstring), '*'

        push    iy                              ; get default device
        pop     hl
        ld      de, prc_dev
        add     hl, de
        ex      de, hl
        ld      a, 18
        ld      bc, PA_Dev
        OZ      OS_Nq

        ld      hl, -255                        ; get default dir
        add     hl, sp
        ld      sp, hl
        ex      de, hl
        xor     a
        ld      (de), a
        ld      bc, PA_Dir
        ld      a, 255
        OZ      OS_Nq
        pop     de
        push    de
        ld      a, e                            ; first byte
        cp      $21                             ; no dir, skip associate block
        jr      c, iprc_1

        call    AllocAssoc

.iprc_1
        ld      hl, 255
        add     hl, sp
        ld      sp, hl

        ld      c, MS_S1                        ; remember S1 binding
        call    OZ_MGB
        push    bc

        push    iy                              ; get unique dynId in range 2-127
.iprc_2
        ld      a, (ubIdxDynamicID)
        inc     a
        jp      p, iprc_3
        xor     a
.iprc_3
        ld      (ubIdxDynamicID), a
        jr      z, iprc_2
        ld      c, a
        ld      iy, eIdxProcList
.iprc_4
        call    GetNextProc
        jr      c, iprc_5                       ; end of list
        ld      a, (iy+prc_dynid)
        cp      c
        jr      z, iprc_2                       ; id in use
        jr      iprc_4
.iprc_5
        ld      a, c
        pop     iy

        pop     bc
        push    af
        rst     OZ_MPB                          ; restore S1

        pop     af
        ld      (iy+prc_dynid), a
        pop     bc
        ret

;       ----

; Bind process HL into S1, add it into eIdxProcList


.AddProc
        push    bc
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind DOM in S1

        push    hl
        pop     iy
        ld      de, (eIdxProcList)
        ld      a, (eIdxProcList+2)
        ld      c, a
        call    PutLinkCDE

        pop     bc
        ld      (eIdxProcList), hl
        ld      a, b
        ld      (eIdxProcList+2), a
        ret

;       ----

;       find last process BHL with static handle IX

.GetProcByHandle
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB                          ; Get current binding
        push    bc

        ld      iy, eIdxProcList
        xor     a
        ld      c, a
        ld      h, a
        ld      l, a

.gph_1
        ld      e, c
        push    de
        call    GetNextProc
        pop     de
        ld      c, e
        jr      c, gph_2                        ; no more entries
        push    ix                              ; compare IX with process handle
        pop     de
        ld      a, (iy+prc_hndl+1)
        cp      d
        jr      nz, gph_1
        ld      a, (iy+prc_hndl)
        cp      e
        jr      nz, gph_1                       ; not same, try next
        push    iy                              ; process in CHL, then loop bak
        pop     hl
        ld      c, b
        jr      gph_1

.gph_2
        ld      b, c
        ld      a, b
        or      h
        or      l
        jr      nz, gph_3
        scf

.gph_3
        pop     de
        push    bc
        push    af
        ld      b, d
        ld      c, e
        rst     OZ_MPB                          ; restore S1
        pop     af
        pop     bc
        ret


;       ----

;       follow IY to next process, ignore Index

.GetNextProc
        push    hl

.nxtact_1
        call    GetLinkBHL
        ld      a, b
        or      l
        or      h
        scf
        jr      z, nxtact_2                     ; no more, exit

        push    hl
        pop     iy
        push    bc
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind node into S1
        pop     bc
        ld      a, (iy+prc_flags)
        and     PRCF_ISINDEX
        jr      nz, nxtact_1                    ; ignore if it's Index

.nxtact_2
        pop     hl
        ret

;       ----

; Name current application
;
; HL = pointer to a null terminated name

.DCNam
        ld      b, 0
        OZ      OS_Bix                          ; Bind in extended address
        push    de

        push    hl
        ld      hl, (eIdxProcList)              ; running proc
        ld      de, prc_Name
        add     hl, de
        ex      de, hl                          ; name buffer in DE
        pop     hl
        ld      a, (eIdxProcList+2)
        ld      b, a
        ld      c, 15                           ; copy 15 bytes until ctrl char
.dcnam_1
        ld      a, (hl)
        inc     hl
        cp      $20
        jr      nc, dcnam_2
        xor     a
.dcnam_2
        OZ      GN_Wbe                          ; write A to BDE
        inc     de
        or      a
        jr      z, dcnam_3
        dec     c
        jr      nz, dcnam_1
        xor     a                               ; !! use code above to save 2 bytes
        OZ      GN_Wbe

.dcnam_3
        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix
        ret

;       ----

; handle Director/CLI enquiries
;
; C = reason code, B = 0, HL=process

.DCNq
        push    hl
        pop     iy
        cp      33                              ; A=C, check reason code range
        ld      a, RC_Unk
        jp      nc, SetOsfError

        ld      hl, dcnq_table
        add     hl, bc
        jp      (hl)

.dcnq_table
        jp      dqdev
        jp      dqdir
        jp      dqfnm
        jp      dqdmh
        jp      dqinp
        jp      dqout
        jp      dqprt
        jp      dqtin
        jp      dqtot
        jp      dqtpr
        jp      dqchn

;       ----

; handle Director/CLI settings
;
; C = reason code, B = 0, HL = arg

.DCSp
        push    hl                              ; argumnet to IY
        pop     iy
        cp      9                               ; A=C, check reason code range
        ld      a, RC_Unk
        jp      nc, SetOsfError

        ld      hl, DCSpJump
        add     hl, bc
        jp      (hl)

.DCSpJump
        jp      dsdev
        jp      dsdir
        jp      dsfnm

;       ----

; Get default device

.dqdev
        push    ix
        ld      c, MS_S1
        call    OZ_MGB
        push    bc                              ; remember S1

        call    GetFilerProc
        ld      de, prc_dev
        add     hl, de
        jr      retBHL

;       ----

; Get default directory

.dqdir
        push    ix
        ld      c, MS_S1
        call    OZ_MGB
        push    bc                              ; remember S1

        call    GetFilerProc
        ld      de, prc_assocptr+2
        add     hl, de
        ld      b, (hl)
        dec     hl
        ld      a, (hl)
        dec     hl
        ld      l, (hl)
        ld      h, a
        or      l
        or      b
        jr      nz, retBHL

        ld      b, 2                            ; copy zero from following byte
        ld      hl, byte_CCAB
        jr      retBHL

.byte_CCAB
        defb 0

;       ----

; Get filename match string

.dqfnm
        push    ix
        ld      c, MS_S1
        call    OZ_MGB
        push    bc                              ; remember S1

        call    GetFilerProc
        ld      de, prc_matchstring
        add     hl, de

;       ----

; put results in Osf and return

.retBHL
        ld      (iy+OSFrame_B), b
        ld      (iy+OSFrame_H), h
        ld      (iy+OSFrame_L), l

        pop     bc
        rst     OZ_MPB                          ; restore S1
        pop     ix
        ret

;       ----

; get the director memory handle

.dqdmh
        ld      ix, (pIdxMemHandle)
        ret

; reset serial port and get NQ_Com

.dqchn
        ld      l, SI_SFT
        OZ      OS_Si                           ; serial soft reset
        ld      bc, NQ_Com
        OZ      OS_Nq                           ; read comms handle
        ret

; get input-T handle

.dqtin
        ld      ix,0
        call    GetFirstCli
        ret     z
        ld      de, cli_instreamT
        jr      ReturnCliHandle

; get output-T handle

.dqtot
        ld      ix,0
        call    GetFirstCli
        ret     z
        ld      de, cli_outstreamT
        jr      ReturnCliHandle

; get printer-T handle

.dqtpr
        ld      ix,0
        call    GetFirstCli
        ret     z
        ld      de, cli_prtstreamT
        jr      ReturnCliHandle

; get IN handle

.dqinp
        ld      bc, NQ_Ihn
        OZ      OS_Nq
        ret

; get OUT handle

.dqout
        ld      bc, NQ_Ohn
        OZ      OS_Nq
        ret
; get printer indirected handle

.dqprt
        ld      bc, NQ_Phn
        OZ      OS_Nq
        ret

.ReturnCliHandle
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind process in S1
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        pop     ix
        rst     OZ_MPB                          ; restore S1

.dcnq_ret
        ret

;       ----

; define default device

.dsdev
        push    ix
        ld      hl, -18
        add     hl, sp
        ld      sp, hl

        ex      de, hl
        call    GetOsfHL
        ld      b, 0
        push    de
        OZ      OS_Bix                          ; Bind in extended address

        ex      (sp), hl
        ex      de, hl
        ex      (sp), hl
        ld      b, 17
        call    CopyUntilSub21                  ; from HL to stack buffer
        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix

        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        push    bc

        call    GetFilerProc
        ld      de, prc_dev
        add     hl, de
        ex      de, hl
        ld      hl, 2
        add     hl, sp

        ld      a, (hl)
        or      a
        jr      nz, dsdev_1                     ; not empty string, copy

        ld      a, 17                           ; get default device into process structire
        ld      bc, PA_Dev
        OZ      OS_Nq
        jr      dsdev_2

.dsdev_1
        ld      b, 17
        call    CopyUntilSub21                  ; from stack buffer

.dsdev_2
        pop     bc                              ; restore S1
        rst     OZ_MPB

        ld      hl, 18
        add     hl, sp
        ld      sp, hl
        pop     ix
        ret

;       ----

; define default directory

.dsdir
        push    iy
        call    GetOsfHL                        ; caller HL
        ld      b, 0
        OZ      OS_Bix                          ; Bind in extended address
        push    de

        ex      de, hl
        ld      hl, -255
        add     hl, sp

        ld      sp, hl
        ex      de, hl
        ld      b, 255
        call    CopyUntilSub21                  ; from HL to stack buffer

        call    GetFilerProc
        push    hl
        pop     iy
        call    AllocAssoc                      ; copy argument into associate block

        ld      hl, 255
        add     hl, sp
        ld      sp, hl

        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix
        pop     iy
        ret

;       ----

; Allocate buffer big enough to hold string in stack and copy it

.AllocAssoc
        push    ix
        ld      ix, (pIdxMemHandle)
        ld      hl, 4                           ; skip IX and return addr
        add     hl, sp

        ld      b, 222                          ; max length of string
.alass_1
        ld      a, (hl)
        inc     hl
        cp      $21
        jr      c, alass_2
        djnz    alass_1
        jr      alass_4                         ; too big, exit

.alass_2
        ld      a, 222                          ; allocate memory for string
        sub     b
        jr      nz, alass_3
        call    FreeAssoc                       ; empty string, free assoc block and exit
        jr      alass_4

.alass_3
        inc     a                               ; allocate new buffer, then free old one
        ld      b, 0
        ld      c, a
        ld      e, a
        ld      a, b
        OZ      OS_Mal
        jr      c, alass_4
        call    FreeAssoc

        ld      (iy+prc_assocptr+2), b
        ld      (iy+prc_assocptr+1), h
        ld      (iy+prc_assocptr), l
        ld      (iy+prc_assoclen), e

        ld      c, MS_S1
        rst     OZ_MPB                          ; bind associate block into S1
        push    bc

        ld      b, e
        ex      de, hl
        ld      hl, 6
        add     hl, sp
        call    CopyUntilSub21                  ; copy string
        pop     bc
        rst     OZ_MPB                          ; restore S1

.alass_4
        pop     ix
        ret

;       ----

; free process's associate block

.FreeAssoc
        push    bc
        push    hl
        push    de
        ld      a, (iy+prc_assocptr+2)
        ld      h, (iy+prc_assocptr+1)
        ld      l, (iy+prc_assocptr)
        or      h
        or      l
        jr      z, frass_1                      ; no associate, exit

        ld      a, (iy+prc_assocptr+2)
        ld      b, 0
        ld      c, (iy+prc_assoclen)
        OZ      OS_Mfr                          ; Free memory

        xor     a
        ld      (iy+prc_assocptr+2), a
        ld      (iy+prc_assocptr+1), a
        ld      (iy+prc_assocptr), a
        ld      (iy+prc_assoclen), a

.frass_1
        pop     de
        pop     hl
        pop     bc
        ret

;       ----

; define filename match string

.dsfnm
        push    ix
        ld      hl, -17
        add     hl, sp
        ld      sp, hl

        ex      de, hl
        call    GetOsfHL
        ld      b, 0
        push    de
        OZ      OS_Bix                          ; bind in extended address

        ex      (sp), hl
        ex      de, hl
        ex      (sp), hl
        ld      b, 17
        call    CopyUntilSub21                  ; from HL to stack buffer

        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix

        ld      c, MS_S1                        ; store S1
        call    OZ_MGB
        push    bc

        call    GetFilerProc
        ld      de, prc_matchstring
        add     hl, de
        ex      de, hl
        ld      hl, 2
        add     hl, sp
        ld      b, 17
        call    CopyUntilSub21                  ; from stack buffer to process structure

        pop     bc                              ; restore S1
        rst     OZ_MPB

        ld      hl, 17
        add     hl, sp
        ld      sp, hl
        pop     ix
        ret

;       ----

; copy B bytes from (HL) into (DE) until chars is <$21

.CopyUntilSub21
        ld      a, (hl)
        ld      (de), a
        inc     de
        inc     hl
        cp      $21
        jr      nc, cus21_1
        dec     b
        ret
.cus21_1
        djnz    CopyUntilSub21
        ret

;       ----

; OUT: HL=proc

.GetFilerProc
        push    ix
        push    de
        ld      ix, eIdxProcList

.gfil_1
        ld      e, b
        ld      b, (ix+2)                       ; get next in BHL, check for NULL
        ld      h, (ix+1)
        ld      l, (ix+0)
        ld      a, l
        or      h
        or      b
        jr      nz, gfil_2

        ld      hl, (eIdxIndexProc)             ; No more entries, return Index
        ld      a, (eIdxIndexProc+2)
        ld      b, a
        ld      e, a
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind Index in S1 and return it
        ld      b, e
        jr      gfil_3

.gfil_2
        ld      e, b
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind process in S1
        ld      b, e
        push    hl
        push    bc
        push    hl
        pop     ix
        ld      d, (ix+prc_hndl+1)
        ld      e, (ix+prc_hndl)
        push    ix
        push    de
        pop     ix
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        pop     ix
        pop     bc
        pop     hl
        and     AT_Film                         ; file manager (Filer)
        jr      nz, gfil_1

.gfil_3
        pop     de
        pop     ix
        ret

;       ----

;       free running process

.FreeProc
        push    ix
        push    bc
        push    hl
        ld      c, MS_S1
        call    OZ_MGB                          ; remember S1 binding
        push    bc

        ld      a, (eIdxProcList+2)             ; active proc at top
        ld      b, a
        ld      hl, (eIdxProcList)
        ld      iy, eIdxProcList
        call    RemoveBHL
        jr      c, frp_3                        ; proc not found, exit (!!never happens)
        ld      de, (eIdxIndexProc)
        ld      a, (eIdxIndexProc+2)
        ex      de, hl
        sbc     hl, de
        ex      de, hl
        jr      nz, frp_1
        sub     b
        jr      z, frp_3                        ; don't free Index process

.frp_1
        push    bc
        push    hl
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind proc in S1

        push    hl                              ; free associated block
        pop     iy
        ld      a, (iy+prc_assoclen)
        or      a
        jr      z, frp_2                        ; nothing to free
        ld      c, a
        ld      b, 0
        ld      a, (iy+prc_assocptr+2)
        ld      h, (iy+prc_assocptr+1)
        ld      l, (iy+prc_assocptr)
        ld      ix, (pIdxMemHandle)
        OZ      OS_Mfr

.frp_2
        pop     hl                              ; free proc itself
        pop     bc
        ld      a, b
        ld      ix, (pIdxMemHandle)
        ld      bc, prc_SIZEOF
        OZ      OS_Mfr

.frp_3
        pop     bc                              ; restore S1
        push    af
        rst     OZ_MPB
        pop     af
        pop     hl
        pop     bc
        pop     ix
        ret

;       ----

; Remove node BHL from list IY

.RemoveBHL
        push    iy
        push    ix
        ld      a, (ubIdxProcRmCount)           ; increment counter
        inc     a
        ld      (ubIdxProcRmCount), a

.rmv_1
        call    GetLinkCDE                      ; get link to next
        ld      a, c
        or      e
        or      d
        ld      a, RC_Eof
        scf
        jr      z, rmv_4                        ; no more entries

        ld      a, b                            ; compare CDE to BHL
        cp      c
        jr      nz, rmv_2
        ld      a, h
        cp      d
        jr      nz, rmv_2
        ld      a, l
        cp      e
        jr      z, rmv_3                        ; match

.rmv_2
        push    bc                              ; follow link to next node and try again
        ld      b, c
        push    de
        pop     iy
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind node in S1
        pop     bc
        jr      rmv_1

.rmv_3
        ld      b, c                            ; bind next into S2
        ld      c, MS_S2
        rst     OZ_MPB
        push    bc
        set     7, d                            ; S2 fix and copy link from next to current
        res     6, d
        ld      a, (de)
        ld      (iy+0), a
        inc     de
        ld      a, (de)
        ld      (iy+1), a
        inc     de
        ld      a, (de)
        ld      (iy+2), a
        pop     bc
        rst     OZ_MPB                          ; restore S2

        call    GetLinkCDE                      ; get link to next

.rmv_4
        pop     ix
        pop     iy
        ret

;       ----

.GetLinkCDE
        ld      c, (iy+2)
        ld      d, (iy+1)
        ld      e, (iy+0)
        ret

;       ----

.GetLinkBHL
        ld      b, (iy+2)
        ld      h, (iy+1)
        ld      l, (iy+0)
        ret                                     ; !! could test for 0:0000 here

;       ----

.ZeroMem
        xor     a
.zm_1
        ld      (hl), a
        inc     hl
        djnz    zm_1
        ret

;       ----

.SetOsfError
        ld      (iy+OSFrame_A), a
        set     Z80F_B_C, (iy+OSFrame_F)
        ret

;       ----

.GetOsfHL
        ld      h, (iy+OSFrame_H)
        ld      l, (iy+OSFrame_L)
        ret

;       ----

.GetProcEnvIDHandle
        ld      b, (iy+prc_stkProcEnv+2)
        ld      c, (iy+prc_dynid)
        ld      h, (iy+prc_stkProcEnv+1)
        ld      l, (iy+prc_stkProcEnv)

;       ----

.GetProcHandle
        ld      d, (iy+prc_hndl+1)
        ld      e, (iy+prc_hndl)
        ret

;       ----

.PutProcHndl_IX
        push    ix
        pop     de
        ld      (iy+prc_hndl+1), d
        ld      (iy+prc_hndl), e
        ret

;       ----

; Invoke new CLI
;
; HL = string, null terminated, B = 0, C = length of string

.DCIcl
        push    ix
        push    iy

        ld      a, b
        or      h
        or      l
        jr      z, dcicl_1                      ; string=NULL

        ld      a, OP_MEM
        OZ      OS_Op                           ; open memory for input
        jp      c, dcicl_7

.dcicl_1
        call    CompareIX_INP
        jp      z, dcicl_7                      ; mem = :INP

        push    ix
        ld      ix, (pIdxMemHandle)
        xor     a
        ld      bc, cli_SIZEOF
        OZ      OS_Mal                          ; Allocate memory
        pop     ix                              ; restore MEM input
        jp      c, dcicl_5

        ld      c, MS_S1
        rst     OZ_MPB                          ; bind mem in S1
        push    bc

        push    hl                              ; clear allocated memory
        pop     iy
        ld      b, cli_SIZEOF
        call    ZeroMem

        push    ix                              ; set default streams
        pop     bc
        ld      (iy+cli_instream+1), b
        ld      (iy+cli_instream), c

        ld      bc, NQ_Shn
        OZ      OS_Nq                           ; read screen handle
        push    ix
        pop     bc
        ld      (iy+cli_outstream+1), b
        ld      (iy+cli_outstream), c

        ld      bc, NQ_Rhn
        OZ      OS_Nq                           ; read direct printer handle
        push    ix
        pop     bc
        ld      (iy+cli_prtstream+1), b
        ld      (iy+cli_prtstream), c

        ld      de, (eIdxCliList)
        ld      a, (eIdxCliList+2)
        ld      c, a
        call    PutLinkCDE
        ld      (iy+cli_StreamFlags), CLIS_INOPEN

        call    GetFirstCli
        jr      z, dcicl_4

; copy stream pointers from existing CLI

        ld      c, MS_S1
        rst     OZ_MPB                          ; bind old CLI into S1

        ld      de, cli_outstream
        add     hl, de
        ld      c, 5                            ; !! this could be simplified to
.dcicl_2
        ld      e, (hl)                         ; !! 10 byte copy
        inc     hl
        ld      d, (hl)
        inc     hl
        push    de                              ; memorize stream pointer
        dec     c
        jr      nz, dcicl_2

        ld      c, MS_S1
        rst     OZ_MPB                          ; restore S1

        push    iy
        pop     hl
        ld      de, cli_prtstreamT+1
        add     hl, de
        ld      c, 5
.dcicl_3
        pop     de                              ; restore stream pointer
        ld      (hl), d
        dec     hl
        ld      (hl), e
        dec     hl
        dec     c
        jr      nz, dcicl_3

.dcicl_4
        pop     bc
        rst     OZ_MPB                          ; restore S1

        push    iy
        pop     hl
        ld      (eIdxCliList), hl
        ld      a, b
        ld      (eIdxCliList+2), a

        ld      a, CL_INC                       ; increment CLI use count
        OZ      OS_Cli
        jr      dcicl_7

.dcicl_5
        push    af                              ; close MEM if it was opened
        ld      a, (iy+OSFrame_B)
        or      (iy+OSFrame_H)
        or      (iy+OSFrame_L)
        jr      z, dcicl_6
        OZ      OS_Cl
.dcicl_6
        pop     af

.dcicl_7
        pop     iy
        pop     ix
        call    c, SetOsfError
        ret

;       ----

.CompareIX_INP
        push    ix
        ld      bc, NQ_Ihn
        OZ      OS_Nq                           ; read IN handle
        ex      (sp), ix                        ; pop ix
        pop     bc                              ; handle into bc
        push    ix
        pop     hl
        or      a
        sbc     hl, bc                          ; compare ix with :INP
        ret

;       ----

; rebind streams

; A = identifier for stream to rebind

.DCRbd
        push    iy
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        push    bc

        ld      c, (iy+OSFrame_A)
        call    GetCLI
        jr      c, dcrbd_8
        ld      a, c                            ; !! use djnz

        cp      RB_IN                           ; input stream
        jr      nz, dcrbd_1
        ld      bc, cli_instream
        ld      a, CLIS_INOPEN
        jr      dcrbd_7

.dcrbd_1
        cp      RB_OUT                          ; output stream
        jr      nz, dcrbd_2
        ld      bc, cli_outstream
        ld      a, CLIS_OUTOPEN
        jr      dcrbd_7

.dcrbd_2
        cp      RB_PRT                          ; printer stream
        jr      nz, dcrbd_3
        ld      bc, cli_prtstream
        ld      a, CLIS_PRTOPEN
        jr      dcrbd_7

.dcrbd_3
        cp      RB_INT                          ; input stream T
        jr      nz, dcrbd_4
        ld      bc, cli_instreamT
        ld      a, CLIS_INTOPEN
        jr      dcrbd_7

.dcrbd_4
        cp      RB_OPT                          ; output stream T
        jr      nz, dcrbd_5
        ld      bc, cli_outstreamT
        ld      a, CLIS_OUTTOPEN
        jr      dcrbd_7

.dcrbd_5
        cp      RB_PTT                          ; printer stream T
        jr      nz, dcrbd_6
        ld      bc, cli_prtstreamT
        ld      a, CLIS_PRTTOPEN
        jr      dcrbd_7

.dcrbd_6
        ld      a, RC_Bad
        scf
        jr      dcrbd_8

.dcrbd_7
        call    sub_D0D1

.dcrbd_8
        pop     bc
        push    af
        rst     OZ_MPB                          ; restore S1
        pop     af
        pop     iy
        call    c, SetOsfError
        ret

;       ----

.sub_D0D1
        call    RebindStream
        ld      a, (iy+cli_StreamFlags)
        and     CLIS_INTOPEN | CLIS_OUTTOPEN | CLIS_PRTTOPEN | CLIS_INOPEN | CLIS_OUTOPEN | CLIS_PRTOPEN
        call    z, FreeCli                      ; call if all streams closed
        ret

;       ----

; examine CLI input

; OUT:  Fc=0 if CLI has input stream

.DCXin
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        push    bc

        push    iy
        call    GetCLI
        jr      c, dcxin_1

        ld      bc, cli_instream                ; return RC_Eof if we don't have input stream
        add     iy, bc
        ld      a, (iy+0)
        or      (iy+1)
        jr      nz, dcxin_1
        ld      a, RC_Eof
        scf

.dcxin_1
        pop     iy
        call    c, SetOsfError

        pop     bc
        rst     OZ_MPB                          ; restore S1
        or      a                               ; Fc = 0
        ret

;       ----

; screen driver SOH call
;
; HL = buffer address in the screen base file
; B = screen base file bank ($21, always)
; C = length of data

.DCGen
        OZ      GN_Rbe                          ; Read byte at extended address

        push    af
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        pop     af
        push    bc
        push    iy

        ld      c, a
        call    GetCLI
        jr      c, dcgen_2

        ld      a, c
        cp      ']'
        jr      nz, dcgen_1
        set     CLIF_B_DISABLEPRT, (iy+cli_Flags)
        jr      dcgen_2

.dcgen_1
        cp      '['
        jr      nz, dcgen_2
        res     CLIF_B_DISABLEPRT, (iy+cli_Flags)

.dcgen_2
        pop     iy
        pop     bc
        rst     OZ_MPB                          ; restore S1
        or      a                               ; Fc = 0
        ret

;       ----

; poll for card usage
;
; IN:   A = card slot (0 to 3), 0 is internal
; OUT:  F<=1 if slot not in use, Fz=0 if in use

.DCPol
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        push    bc
        push    iy

        ld      a, (iy+OSFrame_A)
        and     3                               ; bank into top bits
        rrca
        rrca
        ld      c, a

        ld      iy, eIdxProcList
.dcpol_1
        call    GetNextProc
        ccf
        jr      nc, dcpol_3                     ; no more entries

        ld      a, (iy+prc_hndl)                ; !! should this be prc_assocptr+2?
        and     $C0
        cp      c
        jr      z, dcpol_2
        ld      a, (iy+prc_stkProcEnv+2)        ; stkProcEnv+2
        and     $C0
        cp      c
        jr      nz, dcpol_1

.dcpol_2
        scf

.dcpol_3
        pop     iy
        jr      c, dcpol_4
        set     Z80F_B_Z, (iy+OSFrame_F)        ; Fz=1

.dcpol_4
        pop     bc
        rst     OZ_MPB                          ; restore S1
        or      a                               ; Fc = 0
        ret

;       ----

; read from CLI
;

.DCIn
        push    ix
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        push    bc

        push    iy
        ld      b, (iy+OSFrame_B)
        ld      c, (iy+OSFrame_C)
        call    GetCLI
        jp      c, dcin_16

        ld      (iy+cli_argB), b
        ld      (iy+cli_argC), c
        jr      dcin_2

.dcin_1
        call    GetCLI
        jp      c, dcin_16
.dcin_2
        ld      d, (iy+cli_instream+1)
        ld      e, (iy+cli_instream)
        ld      a, e
        or      d
        jr      nz, dcin_3

        call    ldBC_CliArgBC
        ld      a, CL_RIM
        OZ      OS_Cli                          ; get raw input
        jp      nc, dcin_10
        jp      dcin_13

.dcin_3
        call    ReadCliChar
        jp      c, dcin_13

        bit     CLIF_B_IGNOREMETA, (iy+cli_Flags)       ; .J, skip meta chars
        jr      nz, dcin_9

        cp      CR
        jr      nz, dcin_4
        res     CLIF_B_NOTBOL, (iy+cli_Flags)   ; line start
        jr      dcin_3

;       check for . commands

.dcin_4
        ld      c, (iy+cli_Flags)
        bit     CLIF_B_NOTBOL, c                ; only check . at the line start
        jr      nz, dcin_5
        cp      '.'
        jr      nz, dcin_5
        call    FileControl
        jp      c, dcin_13
        jr      dcin_2

.dcin_5
        set     CLIF_B_NOTBOL, (iy+cli_Flags)   ; not BOL
        cp      '|'
        jr      nz, dcin_6
        set     CLIF_B_DIAMOND, (iy+cli_Flags)
        bit     CLIF_B_DIAMOND, c               ; check for ||
        jr      z, dcin_3
        res     CLIF_B_DIAMOND, (iy+cli_Flags)
        jr      dcin_8

.dcin_6
        cp      '#'
        jr      nz, dcin_7
        set     CLIF_B_SQUARE, (iy+cli_Flags)
        bit     CLIF_B_SQUARE, c                ; check for ##
        jr      z, dcin_3
        res     CLIF_B_SQUARE, (iy+cli_Flags)
        jr      dcin_8

.dcin_7
        cp      '~'
        jr      nz, dcin_8
        set     CLIF_B_META, (iy+cli_Flags)
        bit     CLIF_B_META, c                  ; check for ~~
        jr      z, dcin_3
        res     CLIF_B_META, (iy+cli_Flags)

.dcin_8
        bit     CLIF_B_META, (iy+cli_Flags)
        jr      z, dcin_9

;       handle ~

        OZ      GN_Cls                          ; Classify a character
        jr      nc, dcin_9                      ; not alpha
        and     $df                             ; upper

        cp      'S'                             ; ~S
        jr      nz, dcin_9
        res     CLIF_B_META, (iy+cli_Flags)
        set     CLIF_B_SHIFT, (iy+cli_Flags)
        jr      dcin_3

.dcin_9
        ld      e, a

        ld      a, (iy+cli_Flags)
        and     CLIF_SHIFT | CLIF_DIAMOND | CLIF_SQUARE | CLIF_META
        ld      d, a                            ; meta flags

        ld      a, (iy+cli_Flags)               ; clear meta flags !! xor (iy+cli_Flags)
        and     ~( CLIF_SHIFT | CLIF_DIAMOND | CLIF_SQUARE | CLIF_META )
        ld      (iy+cli_Flags), a

        ld      a, CL_MBC
        OZ      OS_Cli                          ; meta/base to character conversion
        jp      c, dcin_3

.dcin_10
        push    de
        ld      d, (iy+cli_instreamT+1)
        ld      e, (iy+cli_instreamT)
        call    ldIX_DE
        pop     de
        jr      z, dcin_12                      ; no instreamT

        call    KeyToCLI
        jr      nc, dcin_12

        ld      ix,0
        ld      a, CLIS_INTOPEN
        ld      bc, cli_instreamT
        call    RebindStream
        ld      a, (iy+cli_StreamFlags)
        and     CLIS_INTOPEN | CLIS_OUTTOPEN | CLIS_PRTTOPEN | CLIS_INOPEN | CLIS_OUTOPEN | CLIS_PRTOPEN
        jr      z, dcin_15                      ; all streams closed

.dcin_12
        call    ldBC_CliArgBC
        pop     iy
        ld      (iy+OSFrame_B), b
        ld      (iy+OSFrame_C), c
        ld      (iy+OSFrame_D), d
        ld      (iy+OSFrame_E), e

        pop     bc
        rst     OZ_MPB                          ; restore S1
        or      a                               ; Fc = 0
        pop     ix
        ret

.dcin_13
        cp      RC_Eof
        jr      z, dcin_15
        cp      RC_Time                         ; Timeout
        scf
        jr      z, dcin_16
        cp      RC_Susp                         ; Suspicion of pre-emption
        scf
        jr      z, dcin_16
        cp      RC_Esc                          ; Escape condition (e.g. ESC pressed)
        scf
        jr      z, dcin_16
        OZ      GN_Err                          ; Display an interactive error box
        cp      RC_Quit
        jr      z, dcin_14
        scf
        push    af
        call    FreeCli
        pop     af
        jr      dcin_16

.dcin_14
        call    FreeAllCLIs
        jr      dcin_16

.dcin_15
        call    FreeCli
        jp      dcin_1

.dcin_16
        pop     iy
        pop     bc
        push    af
        rst     OZ_MPB                          ; restore S1
        pop     af

        pop     ix
        ld      (iy+OSFrame_A), a
        call    c, SetOsfError
        ret

;       ----

.ldBC_CliArgBC
        ld      b, (iy+cli_argB)
        ld      c, (iy+cli_argC)
        ret

;       ----

.FreeAllCLIs
        call    FreeCli
        jr      nc, FreeAllCLIs
        ccf
        ret

;       ----

; write to CLI

.DCOut
        push    ix
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        push    bc

        push    iy

        ld      c, (iy+OSFrame_A)
        call    GetCLI
        jr      nc, dcout_1

        push    af                              ; no CLI, output to screen
        push    bc
        ld      bc, NQ_Shn
        OZ      OS_Nq                           ; get screen handle
        pop     bc
        ld      a, c
        OZ      OS_Pb                           ; write byte A to screen
        pop     af
        jr      dcout_7

.dcout_1
        ld      b, (iy+cli_Flags)

        ld      d, (iy+cli_outstream+1)
        ld      e, (iy+cli_outstream)
        call    ldIX_DE
        jr      z, dcout_2

        ld      a, c
        call    PutWithTimeout
        jr      nc, dcout_2
        ld      a, CLIS_OUTOPEN                 ; close output if error
        ld      bc, cli_outstream
        jr      dcout_6

.dcout_2
        ld      d, (iy+cli_outstreamT+1)
        ld      e, (iy+cli_outstreamT)
        call    ldIX_DE
        jr      z, dcout_7
        bit     CLIF_B_DISABLEPRT, b
        jr      nz, dcout_7

        ld      a, (iy+cli_outprefix)
        or      a
        jr      nz, dcout_4

        ld      a, c
        cp      ' '
        jr      nc, dcout_5
        cp      ESC
        jr      z, dcout_5
        cp      $0E
        jr      nc, dcout_3
        cp      7
        jr      nc, dcout_5                     ; 07-0D

.dcout_3
        ld      (iy+cli_outprefix), c
        call    GetCLIPrefixBuf
        OZ      OS_Isq                          ; Initialize prefix sequence
        jr      dcout_7

.dcout_4
        push    bc
        call    GetCLIPrefixBuf
        pop     bc
        ld      a, c
        OZ      OS_Wsq                          ; Write to prefix sequence
        dec     hl
        ld      (hl), a
        jr      dcout_7

.dcout_5
        ld      a, c
        call    PutWithTimeout
        jr      nc, dcout_7

        ld      a, CLIS_OUTTOPEN
        ld      bc, cli_outstreamT

.dcout_6
        ld      ix,0                            ; close CLI stream
        call    sub_D0D1

.dcout_7
        pop     iy
        pop     bc
        rst     OZ_MPB                          ; restore S1
        or      a                               ; Fc = 0
        pop     ix
        ret

;       ----

.GetCLIPrefixBuf
        ld      bc, cli_PrefixBuffer
        push    iy
        pop     hl
        add     hl, bc
        ret

;       ----

; print to CLI

.DCPrt
        push    ix
        ld      c, MS_S1                        ; remember S1
        call    OZ_MGB
        push    bc
        push    iy

        ld      c, (iy+OSFrame_A)
        call    GetCLI
        jr      c, dcprt_3

        ld      d, (iy+cli_prtstream+1)
        ld      e, (iy+cli_prtstream)
        call    ldIX_DE
        jr      z, dcprt_1

        ld      a, c
        call    PutWithTimeout
        jr      nc, dcprt_1

        ld      a, CLIS_PRTOPEN
        push    bc
        ld      bc, cli_prtstream
        ld      ix,0                            ; close stream after error
        call    sub_D0D1

        pop     bc
        call    GetCLI
        jr      c, dcprt_3

.dcprt_1
        ld      d, (iy+cli_prtstreamT+1)
        ld      e, (iy+cli_prtstreamT)
        call    ldIX_DE
        jr      z, dcprt_2

        ld      a, c
        call    PutWithTimeout
        jr      nc, dcprt_2

        ld      ix,0                            ; close stream after error
        ld      a, CLIS_PRTTOPEN
        ld      bc, cli_prtstreamT
        call    sub_D0D1

.dcprt_2
        or      a                               ; Fc=0

.dcprt_3
        pop     iy
        pop     bc
        push    af
        rst     OZ_MPB                          ; restore S1
        pop     af
        call    c, SetOsfError
        pop     ix
        ret

;       ----

;       convert input into CLI code

.KeyToCLI
        push    de
        ld      a, CL_CMB
        OZ      OS_Cli                          ; character to meta/base conversion
        ccf
        jr      nc, k2c_5

        bit     QUAL_B_SHIFT, d
        jr      z, k2c_1
        ld      a, '~'
        call    PutWithTimeout
        jr      c, k2c_5
        ld      a, 'S'
        call    PutWithTimeout
        jr      c, k2c_5

.k2c_1
        bit     QUAL_B_CTRL, d                  ; <>
        jr      z, k2c_2
        ld      a, '|'
        call    PutWithTimeout
        jr      c, k2c_5

.k2c_2
        bit     QUAL_B_ALT, d                   ; []
        jr      z, k2c_3
        ld      a, '#'
        call    PutWithTimeout
        jr      c, k2c_5

.k2c_3
        bit     QUAL_B_SPECIAL, d
        jr      z, k2c_4
        ld      a, '~'
        call    PutWithTimeout
        jr      c, k2c_5

.k2c_4
        ld      a, e
        call    PutWithTimeout

.k2c_5
        pop     de
        ret

;       ----

.PutWithTimeout
        push    bc
        call    ldBC_CliArgBC
        OZ      OS_Pbt                          ; write byte A to handle IX, BC=timeout
        pop     bc
        ret

;       ----

.FreeCli
        call    GetFirstCli
        scf
        ld      a, RC_Eof                       ; End Of File
        jr      z, locret_D456

        push    hl
        pop     iy
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind CLI in S1

        ld      ix,0                            ; close all streams
        ld      a, CLIS_INOPEN
        ld      bc, cli_instream
        call    RebindStream
        ld      a, CLIS_INTOPEN
        ld      bc, cli_instreamT
        call    RebindStream
        ld      a, CLIS_OUTOPEN
        ld      bc, cli_outstream
        call    RebindStream
        ld      a, CLIS_OUTTOPEN
        ld      bc, cli_outstreamT
        call    RebindStream
        ld      a, CLIS_PRTOPEN
        ld      bc, cli_prtstream
        call    RebindStream
        ld      a, CLIS_PRTTOPEN
        ld      bc, cli_prtstreamT
        call    RebindStream

        call    GetLinkCDE                      ; next CLI
        ld      iy, eIdxCliList
        push    de
        push    bc
        call    GetLinkBHL                      ; this CLI
        ld      a, b
        ld      bc, cli_SIZEOF
        ld      ix, (pIdxMemHandle)
        OZ      OS_Mfr                          ; free CLI
        pop     bc
        pop     de
        call    PutLinkCDE

        ld      a, CL_DEC
        OZ      OS_Cli                          ; decrement CLI use count

.locret_D456
        ret

;       ----

.PutLinkCDE
        ld      (iy+2), c
        ld      (iy+1), d
        ld      (iy+0), e
        ret

;       ----

; CLI . commands

.FileControl
        call    ReadCliChar
        ret     c
        OZ      GN_Cls                          ; Classify a character
        jr      nc, fc_1                        ; not alpha
        and     $df                             ; upper

.fc_1
        cp      'J'
        jr      nz, fc_2
        set     CLIF_B_IGNOREMETA, (iy+cli_Flags)
        jp      fc_15

.fc_2
        cp      '*'
        jr      nz, fc_4

        call    OpenRedirectRd                  ; open CLI file
        jp      c, fc_15
        ld      hl, 0
        ld      b, l
        OZ      DC_Icl                          ; Invoke new CLI
        jr      nc, fc_3
        push    af
        xor     a
        OZ      OS_Cl                           ; close file/stream
        pop     af
        ret
.fc_3
        call    SkipLine                        ; skip over the rest of line
        jp      GetCLI                          ; get new CLI

.fc_4
        ld      c, 0
        OZ      GN_Cls
        jr      nc, fc_5                        ; not alpha
        and     $df                             ; upper

        cp      'T'
        jr      nz, fc_5
        inc     c                               ; have T
        push    bc
        call    ReadCliChar
        pop     bc
        ret     c

.fc_5
        cp      '<'
        jr      nz, fc_7
        ld      a, c
        or      a
        jr      z, fc_6

        call    OpenRedirectWr                  ; .T< - create input file
        jp      c, fc_17
        ld      a, CLIS_INTOPEN
        ld      bc, cli_instreamT
        jr      fc_11

.fc_6
        call    OpenRedirectRd                  ; .< - open input
        jp      c, fc_17
        call    CompareIX_INP
        jp      z, fc_15
        res     CLIF_B_NOTBOL, (iy+cli_Flags)
        ld      (iy+cli_bytesleft), 0
        ld      a, CLIS_INOPEN
        ld      bc, cli_instream
        call    RebindStream
        jp      fc_16

.fc_7
        cp      '>'
        jr      nz, fc_9
        call    OpenRedirectWr
        jp      c, fc_17
        ld      a, c
        or      a
        jr      nz, fc_8

        ld      a, CLIS_OUTOPEN                 ; .>
        ld      bc, cli_outstream
        jr      fc_11

.fc_8
        ld      a, CLIS_OUTTOPEN                ; .T>
        ld      bc, cli_outstreamT
        jr      fc_11

.fc_9
        cp      '='
        jr      nz, fc_12
        call    OpenRedirectWr
        jr      c, fc_17
        ld      a, c
        or      a
        jr      nz, fc_10

        ld      a, CLIS_PRTOPEN                 ; .=
        ld      bc, cli_prtstream
        jr      fc_11

.fc_10
        ld      a, CLIS_PRTTOPEN                ; .T=
        ld      bc, cli_prtstreamT

.fc_11
        push    bc
        push    af
        call    SkipLine                        ; skip rest of line
        pop     af
        pop     bc
        call    RebindStream
        jr      fc_16

.fc_12
        cp      'S'
        jr      nz, fc_13
        ld      ix,0                            ; .S - exit CLI
        ld      bc, cli_instream
        ld      a, CLIS_INOPEN
        jr      fc_11

.fc_13
        cp      ';'
        jr      nz, fc_14
        call    SkipLine                        ; .; - comment
        jr      fc_17

.fc_14
        cp      'D'
        jr      nz, fc_16

        set     CLIF_B_FILLALL, (iy+cli_Flags)  ; delay
        call    FillCLIBuffer
        jr      c, fc_17

        call    GetLineBuffer
        xor     a
        ld      d, h
        ld      e, l
        OZ      GN_Skd                          ; Bypass delimiters in a sequence
        jr      c, fc_16
        or      a                               ; Fc=0
        push    hl
        sbc     hl, de                          ; bytes skipped
        ld      a, (iy+cli_bytesleft)
        sub     l
        pop     hl
        jr      c, fc_16
        jr      z, fc_16
        ld      b, a
        ld      de, 2                           ; return in BC
        OZ      GN_Gdn                          ; ASCII to integer conversion
        jr      c, fc_15
        OZ      OS_Dly                          ; delay a given period

.fc_15
        call    SkipLine
.fc_16
        or      a
.fc_17
        ret

;       ----

.SkipLine
        call    ReadCliChar
        ret     c
        cp      CR
        jr      nz, SkipLine
        res     CLIF_B_NOTBOL, (iy+cli_Flags)
        ret

;       ----

.OpenRedirectRd
        call    GetRedirectName
        call    nc, OpenRead
        ret

;       ----

.OpenRedirectWr
        call    GetRedirectName
        call    nc, OpenWrite
        ret

;       ----

.GetRedirectName
        set     CLIF_B_FILLALL, (iy+cli_Flags)
        call    FillCLIBuffer
        ret     c

;       ----

.GetLineBuffer
        push    de
        push    iy
        pop     hl
        ld      de, cli_LineBuffer
        add     hl, de
        pop     de
        or      a
        ret

;       ----

; Get running CLI, check for abort
;OUT:   Fc=0, IY=CLI
;       Fc=1

.GetCLI
        push    bc
        ld      d, 0
        ld      a, CL_ACK
        OZ      OS_Cli                          ; acknowledge CLI/Escape, reset shift / <>
        jr      z, gcli_1                       ; no escape

        push    de
        ld      a, CL_ACK
        OZ      OS_Cli                          ; restore flags
        pop     de
        bit     QUAL_B_CTRL, d                  ; <>
        jr      nz, gcli_3
        call    FreeCli                         ; ESC - abort

.gcli_1
        call    GetFirstCli
        scf
        ld      a, RC_Eof
        jr      z, gcli_2
        push    hl
        pop     iy
        ld      c, MS_S1
        rst     OZ_MPB                          ; bind CLI into S1
        or      a                               ; Fc = 0
.gcli_2
        pop     bc
        ret

.gcli_3
        call    FreeAllCLIs                     ; <> ESC - abort all
        jr      gcli_1

;       ----

; BC stream offset, A stream bit

.RebindStream
        push    de
        push    iy
        pop     hl
        add     hl, bc
        ld      c, a
        and     (iy+cli_StreamFlags)
        jr      z, rbds_1                       ; stream not open

        ld      e, (hl)                         ; close old stream and clear flag
        inc     hl
        ld      d, (hl)
        dec     hl
        push    de
        ex      (sp), ix
        OZ      OS_Cl                           ; close file/stream
        pop     ix
        ld      a, $FF                          ; !! 'ld a,c; cpl'
        sub     c
        and     (iy+cli_StreamFlags)
        ld      (iy+cli_StreamFlags),   a

.rbds_1
        push    ix                              ; set stream, set flag if not NULL
        pop     de
        ld      (hl), e
        inc     hl
        ld      (hl), d
        ld      a, e
        or      d
        jr      z, rbds_2
        ld      a, c
        or      (iy+cli_StreamFlags)
        ld      (iy+cli_StreamFlags),   a

.rbds_2
        pop     de
        ret

;       ----

.ReadCliChar
        push    de
        push    ix
        call    FillCLIBuffer
        jr      c, rc_2
        ld      de, cli_LineBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      c, (hl)
        push    bc
        ld      a, (iy+cli_bytesleft)
        dec     a
        ld      (iy+cli_bytesleft), a
        jr      z, rc_1
        ld      d, h                            ; move data to the beginning of buffer
        ld      e, l
        inc     hl
        ld      b, 0
        ld      c, a
        ldir

.rc_1
        pop     bc
        ld      a, c
        or      a

.rc_2
        pop     ix
        pop     de
        ret

;       ----

.FillCLIBuffer
        ld      d, (iy+cli_instream+1)
        ld      e, (iy+cli_instream)
        push    de
        pop     ix                              ; IX=instream
        ld      de, cli_LineBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      a, CLI_LINEBUFSIZE
        ld      d, 0
        ld      e, (iy+cli_bytesleft)
        sub     e
        jr      z, fcb_3
        add     hl, de
        ex      de, hl

        ld      b, 1                            ; read one byte or buffer full
        bit     CLIF_B_FILLALL, (iy+cli_Flags)
        jr      z, fcb_1
        ld      b, a
        res     CLIF_B_FILLALL, (iy+cli_Flags)

.fcb_1
        push    bc                              ; read bytes until 0D or 20-FF
        call    ldBC_CliArgBC
        OZ      OS_Gbt                          ; get byte with timeout
        pop     bc
        jr      c, fcb_3
        cp      CR
        jr      z, fcb_2
        cp      $20
        jr      c, fcb_1

.fcb_2
        ld      (de), a
        inc     de
        inc     (iy+cli_bytesleft)
        cp      CR
        jr      z, fcb_3                        ; end at CR
        djnz    fcb_1

.fcb_3
        ret     nc
        ld      c, a
        ld      a, (iy+cli_bytesleft)
        or      a
        ret     nz
        ld      a, c
        scf
        ret

;       ----

.GetFirstCli
        push    iy
        ld      iy, eIdxCliList
        call    GetLinkBHL
        ld      a, b
        or      h
        or      l
        pop     iy
        ret
