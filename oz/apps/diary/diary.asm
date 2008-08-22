; **************************************************************************************************
; Diary application (addressed for segment 3).
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
; (C) Gunther Strube (gbs@users.sf.net), 2005-2008
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module Diary

        include "blink.def"
        include "char.def"
        include "director.def"
        include "error.def"
        include "fileio.def"
        include "integer.def"
        include "memory.def"
        include "saverst.def"
        include "stdio.def"
        include "syspar.def"
        include "time.def"
        include "printer.def"
        include "sysvar.def"
        include "sysapps.def"

        org ORG_DIARY

defc    dix_eCurrentDatePrev    =$00
defc    dix_eCurrentDate        =$03
defc    dix_eSrchDatePrev       =$06
defc    dix_eSrchDate           =$09
defc    dix_eCurrentLnPrev      =$0C
defc    dix_eCurrentLine        =$0F
defc    dix_eSrchLnPrev         =$12
defc    dix_eSrchLn             =$15
defc    dix_18                  =$18
defc    dix_eTopLnPrev          =$1B
defc    dix_eTopLine            =$1E
defc    dix_CurrentDate         =$21
defc    dix_e24                 =$24
defc    dix_ubCrsrXPos          =$27
defc    dix_ubCrsrYPos          =$28
defc    dix_BlkStartLn          =$29
defc    dix_BlkStartDate        =$2C
defc    dix_BlkStartFlags2F     =$2F
defc    dix_BlkEndLn            =$30
defc    dix_BlkEndDate          =$33
defc    dix_BlkEndFlags36       =$36
defc    dix_SavedStates         =$37            ; 5*7 bytes
defc    dix_SavedStates_23      =$59            ; dix_SavedStates+5*7-1
defc    dix_ubNumSavedPositions =$5A
defc    dix_ubFlags5B           =$5B            ; 0=overwrite
defc    dix_ubFlags5C           =$5C            ; local flag
defc    dix_ubFlags5D           =$5D
defc    dix_ubFlags5E           =$5E
defc    dix_Date2               =$5F
defc    dix_Date3               =$62
defc    dix_ubCommand           =$65
defc    dix_ubTmp               =$66
defc    dix_Tmp2                =$67
defc    dix_68                  =$68
defc    dix_6A                  =$6A
defc    dix_6C                  =$6C
defc    dix_uwFoundCount        =$6E
defc    dix_eTmp                =$70
defc    dix_e73                 =$73
defc    dix_76                  =$76
defc    dix_77                  =$77
defc    dix_78                  =$78
defc    dix_FreeMem             =$79
defc    dix_DateBuf             =$CC

; enum _Diary_
defc    DF2F_B_ACTIVE           =0

defc    DF36_B_ACTIVE           =0

defc    DF5B_B_OVERWRITE        =0
defc    DF5B_B_ALLOCNEW         =1              ; local flag
defc    DF5B_B_FREEOLD          =2              ; local flag
defc    DF5B_B_ALLOC83ERR       =3
defc    DF5B_B_NEEDREDRAW       =4
defc    DF5B_B_ONEDAY           =5              ; local flag
defc    DF5B_B_BLOCKDONE        =6
defc    DF5B_B_REVERSELINE      =7

defc    DF5C_B_MATCHBACKW       =0
defc    DF5C_B_ERRORSHOWN       =1
defc    DF5C_B_2                =2
defc    DF5C_B_SRCHRPLC         =3
defc    DF5C_B_APPND_NEWLINE    =4
defc    DF5C_B_5                =5
defc    DF5C_B_6                =6
defc    DF5C_B_7                =7              ; local flag

defc    DF5D_B_0                =0              ; local flag
defc    DF5D_B_CPY6UP           =1              ; local flag
defc    DF5D_B_ALLOCATEDNEW     =2
defc    DF5D_B_ALLOCATED83_1    =3
defc    DF5D_B_ALLOCATED83_2    =4
defc    DF5D_B_WRMAILDATE       =5              ; local flag
defc    DF5D_B_DATE2_EQ_BLKDATE =6
defc    DF5D_B_DATE2_EQ_BLKEND  =7

defc    DF5E_B_IGNORECASE       =0
defc    DF5E_B_SEARCHBLOCK      =1
defc    DF5E_B_LST_SV_BLOCK     =3
defc    DF5E_B_MAKESEARCHLIST   =4
defc    DF5E_B_PRINTSEARCHLIST  =5
defc    DF5E_B_CONFIRMRPLC      =6
defc    DF5E_B_LOADATDATE       =7

defc    DF67_B_0                =0
defc    DF67_B_1                =1
defc    DF67_B_2                =2


defc    iob_Filename            =0              ; !! should avoid using this
defc    iob_IOBuffer            =$53            ; !! should have pIObuffer in safe area

defc    lbuf_InputBuffer        =0              ; !! should avoid using this
defc    lbuf_Buffer2            =$4F            ; !! should have pBuffer2 in safe area
defc    lbuf_Buffer3            =$9E            ; !! should have pBuffer3 in safe area

defvars $1fde
        eMem_LineBuffers        ds.p    1
        eMem_dix_254            ds.p    1
        eIOBuf_242              ds.p    1
        pMemHandle1             ds.w    1
        pMemHandleMulti         ds.w    1
        DiaryFileHandle         ds.w    1
        S1Binding               ds.b    1
enddef


.loc_C000
        ld      hl, eMem_LineBuffers
        ld      b, $10
        call    ClearMem

        ld      a, $80                          ; S2
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool, A=mask
        jp      c, loc_C0D9

        ld      (pMemHandle1), ix
        xor     a
        ld      bc, 237                         ; 3*79
        OZ      OS_Mal                          ; Allocate memory
        jp      c, loc_C0D9

        ld      (eMem_LineBuffers), hl
        ld      a, b
        ld      (eMem_LineBuffers+2), a

        ld      bc, 254
        xor     a
        OZ      OS_Mal                          ; Allocate memory
        jp      c, loc_C0D9

        ld      (eMem_dix_254), hl
        ld      a, b
        ld      (eMem_dix_254+2), a

        ld      bc, 242
        xor     a
        OZ      OS_Mal                          ; Allocate memory
        jp      c, loc_C0D9

        ld      (eIOBuf_242), hl
        ld      a, b
        ld      (eIOBuf_242+2), a

        ld      c, MS_S2
        rst     OZ_MPB                          ; bind  it in S2

        ld      a, $60                          ; S1, multiple  banks
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool, A=mask
        jp      c, loc_C0D9

        ld      (pMemHandleMulti), ix

        xor     a
        ld      (S1Binding), a

        ld      b, a                            ; b00 into S1
        ld      c, MS_S1
        rst     OZ_MPB                          ; Bind  bank B in slot C

        ld      hl, (eMem_LineBuffers)
        ld      b, 237
        call    ClearMem

        ld      hl, (eMem_dix_254)
        ld      b, 254
        call    ClearMem

        ld      hl, (eIOBuf_242)
        ld      b, 242
        call    ClearMem

        ld      ix, (eMem_dix_254)
        xor     a
        ld      hl, ErrHandler
        OZ      OS_Erh                          ; Set (install) Error Handler
        call    GetCurrentDate

        call    RdMailDate

        call    CpyDate_Current_3

        ld      bc, (eMem_dix_254)
        ld      hl, dix_18
        add     hl, bc
        ld      a, (eMem_dix_254+2)
        ld      (ix+dix_eCurrentDatePrev), l
        ld      (ix+dix_eCurrentDatePrev+1), h
        ld      (ix+dix_eCurrentDatePrev+2), a
        ld      (ix+dix_e24), l
        ld      (ix+dix_e24+1), h
        ld      (ix+dix_e24+2), a
        ld      bc, (eMem_dix_254)
        ld      hl, dix_ubTmp
        add     hl, bc
        ex      de, hl
        ld      bc, PA_Iov                      ; insert/overwrite
        ld      a, 1
        OZ      OS_Nq                           ; enquire (fetch) parameter
        ld      a, 'O'
        cp      (ix+dix_ubTmp)
        jr      nz, loc_C0CA

        set     DF5B_B_OVERWRITE, (ix+dix_ubFlags5B)

.loc_C0CA
        call    InitWd

        call    ShowInsertMode

        ld      (ix+dix_ubCommand), $25
        call    CheckMemory

        jr      nc, loc_C0E4


.loc_C0D9
        ld      a, RC_Room                      ; No room
        jp      loc_C186


.ClearMem
        xor     a

.zm_1
        ld      (hl), a
        inc     hl
        djnz    zm_1

        ret

;       ----

.loc_C0E4
        call    Cpy6_CrntDate_SrchDate

        call    CpyDate_Current_3

        call    sub_D700

        call    Cpy6_SrchDate_CrntDate

        jr      nc, loc_C107


.loc_C0F2
        call    Cpy6_SrchLn_CrntLn

        call    Cpy6_CrntDate_SrchDate

        call    CpyDate_Current_2

        call    sub_D681

        call    CpyDate_2_Current

        call    Cpy6_SrchDate_CrntDate

        call    Cpy6_SrchLn_CrntLn


.loc_C107
        call    PrintDate

        ld      (ix+dix_ubCrsrXPos), 0
        ld      (ix+dix_ubCrsrYPos), 0
        call    sub_D969

        call    RedrawDiaryWd


.loc_C118
        call    GetCurrentLnPtrs


.loc_C11B
        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE


.NextOption
        ld      a, 5                            ; SC_ENA
        OZ      OS_Esc                          ; Examine special condition
        call    ShowEndOfText

        ld      hl, (eMem_LineBuffers)
        ld      bc, lbuf_InputBuffer
        add     hl, bc
        ex      de, hl
        ld      a, $9B                          ; return wrap,  special, insert/overwrite, forcei/o, has data
        bit     DF5B_B_OVERWRITE, (ix+dix_ubFlags5B)
        jr      z, loc_C13A

        set     2, a                            ; overwrite

.loc_C13A
        call    CursorInBlock

        jr      nc, loc_C141

        set     6, a                            ; reverse

.loc_C141
        ld      b, 79                           ; buffer length
        ld      c, (ix+dix_ubCrsrXPos)
        call    ToggleCursor

        OZ      GN_Sip                          ; system input  line routine
        call    ToggleCursor

        ld      (ix+dix_ubCrsrXPos), c
        push    af
        OZ      OS_Pout
        defm    1,"4-RBT",0
        call    RemoveError
        pop     af
        jp      nc, loc_C29F

        res     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      z, sub_C1AB

        cp      RC_Susp                         ; Suspicion of  pre-emption
        jr      z, loc_C1BE

        cp      RC_Wrap                         ; Wrap  condition met
        jp      z, DoWrap

        cp      RC_Esc                          ; Escape condition (e.g. ESC pressed)
        jr      nz, loc_C17B

        ld      a, 1                            ; SC_ACK !! already 1
        OZ      OS_Esc                          ; Examine special condition
        jr      NextOption


.loc_C17B
        cp      RC_Quit                         ; Request application to quit *
        jr      nz, NextOption

        jr      Quit


.ErrQuit
        xor     a
        OZ      GN_Err                          ; Display an interactive error  box

.Quit
        xor     a

.loc_C186
        push    af
        OZ      OS_Pout
        defm    1,"6#2",$21,$20,$7D,$28
        defm    1,"2C2",0

        ld      ix, (pMemHandleMulti)
        call    MayCloseMem

        ld      ix, (pMemHandle1)
        call    MayCloseMem

        pop     af
        OZ      OS_Bye                          ; Application exit
        jp      loc_C000


.MayCloseMem
        push    ix
        pop     hl
        ld      a, l
        or      h
        jr      z, locret_C1AA

        OZ      OS_Mcl                          ; Close memory  (free memory pool)

.locret_C1AA
        ret

;       ----

.sub_C1AB
        ld      (ix+dix_ubCommand), $26
        call    CheckMemory

        call    nc, StoreCurrentLine

        call    sub_E14A

        set     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        jr      loc_C1C8


.loc_C1BE
        ld      (ix+dix_ubCommand), $26
        call    CheckMemory

        call    nc, StoreCurrentLine


.loc_C1C8
        call    CheckMemory

        jr      c, loc_C1EB

        call    CpyDate_Current_3

        call    RdMailDate

        ld      bc, (eMem_dix_254)
        ld      hl, dix_CurrentDate
        add     hl, bc
        ex      de, hl
        ld      hl, dix_Date3
        add     hl, bc
        call    Cmp3_HL_DE

        jr      z, loc_C1EB

        call    sub_D76E

        jp      loc_C0E4


.loc_C1EB
        call    GetCurrentLnPtrs

        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE

        bit     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        jr      z, loc_C1FD

        call    RedrawDiaryWd


.loc_C1FD
        jp      NextOption

;       ----

.DoWrap
        ld      (ix+dix_ubCommand), $22
        call    CheckMemory

        jr      nc, loc_C216

        ld      hl, 77                          ; lbuf_InputBuffer+77
        ld      de, (eMem_LineBuffers)
        add     hl, de
        ld      (hl), 0
        jp      NextOption


.loc_C216
        ld      bc, 78
        ld      de, (eMem_LineBuffers)
        ld      hl, 77                          ; lbuf_InputBuffer+77
        add     hl, de
        ld      a, ' '
        cpdr
        jr      nz, loc_C241                    ; no spaces, cut at 77

        inc     hl                              ; change space  into NULL
        ld      (hl), 0
        inc     hl                              ; and move HL to next char
        inc     bc
        ld      a, 78
        sub     c
        ld      c, a                            ; #chars to move to next line
        push    hl
        ld      de, lbuf_Buffer2
        ld      hl, (eMem_LineBuffers)
        add     hl, de
        ex      de, hl
        pop     hl
        or      a
        jr      z, loc_C25D                     ; no chars to move? done

        ldir                                    ; copy  chars
        jr      loc_C25D


.loc_C241
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer2
        add     hl, bc
        ex      de, hl                          ; DE=buf2
        ld      hl, 77                          ; lbuf_InputBuffer+77
        add     hl, bc
        ldi                                     ; copy  one char
        dec     hl                              ; and NULL it
        ld      (hl), 0
        ld      a, 77                           ; xpos<77? xpos++
        cp      (ix+dix_ubCrsrXPos)
        jr      nc, loc_C25D

        inc     (ix+dix_ubCrsrXPos)

.loc_C25D
        ex      de, hl                          ; NULL-terminate buf2
        ld      (hl), 0
        call    ReallocCurrent

        call    InsertEmptyLine

        call    Cpy_Buf2_InBuf

        call    ReallocCurrent

        call    RetreatCurrentPtrs

        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE

        call    PrintCurrentLn

        ld      hl, lbuf_InputBuffer
        ld      de, (eMem_LineBuffers)
        add     hl, de
        ld      bc, 78
        xor     a
        cpir
        ld      a, 77
        sub     c                               ; strlen()
        cp      (ix+dix_ubCrsrXPos)
        jr      c, loc_C291

        jp      nz, NextOption


.loc_C291
        ld      c, a
        ld      a, (ix+dix_ubCrsrXPos)
        sub     c
        jr      z, loc_C299

        dec     a

.loc_C299
        ld      (ix+dix_ubCrsrXPos), a
        jp      cdn_1

;       ----

.loc_C29F
        cp      $16                             ; <>V,  insert/overwrite
        jr      nz, loc_C2B0

        ld      (ix+dix_ubCommand), $24
        call    CheckMemory

        jp      c, NextOption

        jp      ToggleInsert


.loc_C2B0
        cp      13
        jr      nz, loc_C2C1

        ld      (ix+dix_ubCommand), $23
        call    CheckMemory

        jp      c, NextOption

        jp      loc_C372                        ; move  to next line


.loc_C2C1
        sub     $20
        jp      c, NextOption

        cp      $22
        jp      nc, NextOption

        ld      (ix+dix_ubCommand), a
        call    CheckMemory

        jp      c, NextOption

        sla     a
        ld      hl, Commands_tbl
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl
        jp      (hl)

.Commands_tbl
        defw    MarkBlock
        defw    ClearMark
        defw    Copy
        defw    Move
        defw    Delete                          ; 24
        defw    List
        defw    Search
        defw    NextMatch
        defw    PrevMatch                       ; 28
        defw    Replace
        defw    Tab
        defw    SavePosition
        defw    RestorePosition                 ; 2C
        defw    CursorDown
        defw    CursorUp
        defw    LastLine
        defw    FirstLine                       ; 30
        defw    ScreenDown
        defw    ScreenUp
        defw    Today
        defw    NextDay                         ; 34
        defw    PreviousDay
        defw    NextActiveDay
        defw    PreviousActiveDay
        defw    LastActiveDay                   ; 38
        defw    FirstActiveDay
        defw    DeleteLine
        defw    JoinLines
        defw    InsertLine                      ; 3C
        defw    SplitLine
        defw    MemoryFree
        defw    NextOption
        defw    Load                            ; 40
        defw    Save
.CmdFlags_tbl
        defb    1,1,7,7,1,1,3,3
        defb    3,7,6,3,1,1,1,1
        defb    1,1,1,3,3,3,3,3
        defb    3,3,1,3,3,3,0,0
        defb    7,1,6,3,0,6,1


.CursorUp
        call    CurrentHasPrevLine

        jp      z, NextOption

        call    ReallocCurrent

        call    RetreatCurrentPtrs

        xor     a
        cp      (ix+dix_ubCrsrYPos)
        jr      z, cup_1                        ; ypos=0? need  scrolling

        dec     (ix+dix_ubCrsrYPos)
        jr      cup_2

.cup_1
        OZ      OS_Pout
        defm    1,$FE,0
        call    Cpy2e_CurrentLn_TopLn

.cup_2
        jp      loc_C11B

;       ----

.loc_C372
        ld      (ix+dix_ubCrsrXPos), 0          ; !! move this  to caller (enter handling)
        jr      cdn_1


.CursorDown
        call    CurrentHasNextLine

        jp      z, NextOption


.cdn_1
        call    ReallocCurrent

        call    AdvanceCurrentPtrs

        ld      a, 7
        cp      (ix+dix_ubCrsrYPos)
        jr      z, cdn_2                        ; ypos=7? need  scrolling

        inc     (ix+dix_ubCrsrYPos)
        call    TstBHL

        jr      nz, cdn_3

        call    MoveTo_0_ypos
        call    PrntClearEOL
        jr      cdn_3


.cdn_2
        push    hl
        push    de
        push    bc

        OZ      OS_Pout
        defm    1,$FF,0

        call    GetTopLnPtrs

        OZ      GN_Xnx
        call    PutTopLnPtrs

        pop     bc
        pop     de
        pop     hl

.cdn_3
        jp      loc_C11B

;       ----

.ToggleInsert
        bit     DF5B_B_OVERWRITE, (ix+dix_ubFlags5B)
        jr      z, tgi_1

        res     DF5B_B_OVERWRITE, (ix+dix_ubFlags5B)
        jr      tgi_2


.tgi_1
        set     DF5B_B_OVERWRITE, (ix+dix_ubFlags5B)

.tgi_2
        call    ShowInsertMode

        jp      NextOption

;       ----

.DeleteLine
        call    ReallocCurrent

        call    Cpy_CurrentLine_eTmp

        call    TstCurrentLine

        jr      z, dln_1

        call    GetCurrentLnPtrs

        call    FreeCurrentLine

        jp      c, ErrQuit

        call    MayInactivateBlkSaved

        ld      hl, dix_eTopLine
        call    MayReplaceWithCurrent

        call    TstCurrentLine

        jr      nz, dln_3


.dln_1
        call    CurrentHasPrevLine

        jr      z, dln_2

        call    RetreatCurrentPtrs

        xor     a
        cp      (ix+dix_ubCrsrYPos)
        jr      z, dln_2

        dec     (ix+dix_ubCrsrYPos)
        jr      dln_3


.dln_2
        ld      (ix+dix_ubCrsrYPos), 0
        call    Cpy2e_CurrentLn_TopLn


.dln_3
        jp      loc_D45C

;       ----

.JoinLines
        call    ReallocCurrent

        call    CurrentHasNextLine

        jp      z, jln_err                      ; no next line? exit

        call    GetCurrentLnPtrs

        OZ      GN_Xnx
        call    TstBHL

        jp      z, jln_err                      ; no next line? exit

        push    bc
        push    de
        push    hl
        ld      de, lbuf_Buffer2
        call    Cpy_BHL_BufDE                   ; copy  next to Buf2

        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer2
        add     hl, bc
        ld      a, (hl)
        cp      0
        pop     hl
        pop     de
        pop     bc
        jr      nz, jln_1                       ; next  not empty?

        call    PutCurrentLnPtrs

        jr      jln_del2


.jln_1
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_InputBuffer
        add     hl, bc
        ld      bc, 78
        xor     a
        cpir
        inc     c                               ; #bytes left in buffer
        ld      a, c
        or      a
        jr      z, jln_err

        dec     hl                              ; ptr to end(this)
        push    hl
        ld      hl, (eMem_LineBuffers)
        ld      de, lbuf_Buffer2
        add     hl, de
        push    hl
        ld      e, l                            ; DE=split position
        ld      d, h

.jln_2
        ld      a, (hl)
        cp      0
        jr      z, jln_4

        cp      $20
        jr      nz, jln_3

        ld      e, l                            ; remember breaking point
        ld      d, h

.jln_3
        dec     c
        jr      z, jln_5

        inc     hl
        jr      jln_2


.jln_4
        ld      e, l
        ld      d, h

.jln_5
        pop     hl
        push    hl
        ex      de, hl
        or      a
        sbc     hl, de                          ; bytes to append
        ld      c, l
        ld      b, h
        pop     hl
        pop     de
        xor     a
        cp      c
        jr      z, jln_err

        ldir
        push    hl
        ex      de, hl
        ld      (hl), 0
        call    ReallocCurrent

        call    AdvanceCurrentPtrs

        pop     hl
        xor     a
        cp      (hl)
        jr      z, jln_del2                     ; joined full line?

        inc     hl
        cp      (hl)
        jr      z, jln_del2                     ; joined full line?

        ex      de, hl
        ld      hl, (eMem_LineBuffers)
        ld      bc, lbuf_InputBuffer
        add     hl, bc
        ex      de, hl

.jln_6
        ldi
        cp      (hl)
        jr      nz, jln_6

        ldi
        call    ReallocCurrent

        jr      jln_x


.jln_err
        jp      NextOption


.jln_del2
        call    Cpy_CurrentLine_eTmp

        call    FreeCurrentLine

        call    MayInactivateBlkSaved


.jln_x
        call    RetreatCurrentPtrs

        jp      loc_D46B

;       ----

.InsertLine
        call    ReallocCurrent

        call    GetCurrentLnPtrs

        call    Cpy_CurrentLine_eTmp

        ld      c, 4
        call    AllocBindMulti

        jp      c, NextOption

        call    InsertCurrentLine

        push    hl
        pop     iy
        ld      (iy+3), 0                       ; length=0
        ld      hl, $1E
        call    MayReplaceWithCurrent

        jp      loc_D46B

;       ----

.SplitLine
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer2
        add     hl, bc
        ex      de, hl                          ; DE=buf2
        ld      hl, lbuf_InputBuffer
        add     hl, bc                          ; HL=buf1
        ld      c, (ix+dix_ubCrsrXPos)
        ld      b, 0
        add     hl, bc
        push    hl
        xor     a                               ; copy  rest of line from buf1 to buf2

.split_1
        cp      (hl)
        jr      z, split_2

        ldi
        jr      split_1


.split_2
        ldi
        pop     hl                              ; terminate buf1
        ld      (hl), 0
        call    ReallocCurrent

        call    InsertEmptyLine

        call    Cpy_Buf2_InBuf

        call    ReallocCurrent

        call    RetreatCurrentPtrs

        jp      loc_D46B

;       ----

.MemoryFree
        push    ix
        ld      ix, (pMemHandleMulti)
        ld      bc, NQ_Mfs                      ; free  memory
        OZ      OS_Nq                           ; enquire (fetch) parameter
        pop     ix
        ld      (ix+dix_FreeMem), c
        ld      (ix+dix_FreeMem+1), b
        ld      (ix+dix_FreeMem+2), a
        ld      (ix+dix_FreeMem+3), 0
        call    PrntErrorPre
        ld      bc, (eMem_dix_254)
        ld      hl, dix_FreeMem
        add     hl, bc
        ld      de, 0
        ld      a, 4
        push    ix
        call    GetOutHandle

        OZ      GN_Pdn                          ; Integer to ASCII conversion
        pop     ix
        ld      hl, Free_txt
        OZ      GN_Sop                          ; write string  to std. output
        call    loc_E23A

        jp      NextOption

;       ----

.Tab
        call    ReallocCurrent

        call    Cpy_InBuf_Buf2

        ld      c, (ix+dix_ubCrsrXPos)
        ld      b, 0
        ld      hl, (eMem_LineBuffers)
        add     hl, bc
        push    hl
        pop     bc
        ld      hl, lbuf_Buffer2
        add     hl, bc
        ex      de, hl
        ld      hl, lbuf_InputBuffer
        add     hl, bc
        ld      a, (ix+dix_ubCrsrXPos)
        and     $0F8
        add     a, 8
        cp      78
        jp      nc, NextOption

        ld      b, (ix+dix_ubCrsrXPos)
        ld      (ix+dix_ubCrsrXPos), a
        sub     b
        ld      b, a

.tab_1
        ld      (hl), ' '
        inc     hl
        djnz    tab_1

        ld      (hl), 0
        ex      de, hl
        res     DF5C_B_APPND_NEWLINE, (ix+dix_ubFlags5C)
        call    AppendToCurrent

        ex      de, hl
        ld      (hl), 0
        call    ReallocCurrent

        call    GetCurrentLnPtrs

        bit     DF5C_B_APPND_NEWLINE, (ix+dix_ubFlags5C)
        call    nz, GetPrev

        call    PutCurrentLnPtrs

        jp      loc_D46B

;       ----

.SavePosition
        call    ReallocCurrent

        ld      a, (ix+dix_ubNumSavedPositions)
        cp      5
        jr      z, svp_3

        ld      hl, dix_SavedStates
        inc     (ix+dix_ubNumSavedPositions)
        ld      de, 7
        or      a
        jr      z, svp_2

        ld      b, a

.svp_1
        add     hl, de
        djnz    svp_1


.svp_2
        call    SaveState

        jr      svp_4


.svp_3
        push    hl
        ld      hl, NoRoom_txt
        call    ShowError

        pop     hl

.svp_4
        jp      NextOption

;       ----

.RestorePosition
        call    StoreCurrentLine

        ld      a, (ix+dix_ubNumSavedPositions)
        or      a
        jr      z, rsp_3

        dec     (ix+dix_ubNumSavedPositions)
        ld      de, dix_SavedStates
        ld      hl, (eMem_dix_254)
        add     hl, de
        ld      de, 7

.rsp_1
        dec     a
        jr      z, rsp_2

        add     hl, de
        jr      rsp_1


.rsp_2
        push    hl
        pop     iy
        bit     0, (iy+6)
        jr      nz, rsp_4


.rsp_3
        push    hl
        ld      hl, NoMarker_txt
        call    ShowError

        pop     hl
        jp      NextOption


.rsp_4
        ld      (ix+dix_ubCrsrXPos), 0
        res     0, (iy+6)
        push    iy
        pop     hl
        ld      de, (eMem_dix_254)
        or      a
        sbc     hl, de
        push    hl
        ld      de, 3
        add     hl, de
        ld      de, dix_Date3
        call    Cpy3_HL_DE

        pop     hl
        ld      de, 0
        add     hl, de
        ld      de, dix_eTmp
        call    Cpy3_HL_DE

        call    Cpy6_CrntDate_SrchDate

        call    sub_D72D

        jr      c, rsp_5

        jr      nz, rsp_5

        call    FindLineOnScreen

        jr      c, rsp_6

        call    PutCurrentLnPtrs

        ld      (ix+dix_ubCrsrYPos), a
        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE

        jp      NextOption


.rsp_5
        call    sub_D76E

        ld      hl, dix_Date3
        ld      de, dix_CurrentDate
        call    Cpy3_HL_DE

        call    sub_D700

        call    Cpy6_SrchDate_CrntDate

        jp      c, loc_C0F2


.rsp_6
        call    sub_DAEE

        call    PrintDate

        jp      loc_D45C

;       ----

.LastLine
        call    ReallocCurrent

        ld      (ix+dix_eTmp), 0
        ld      (ix+dix_eTmp+1), 0
        ld      (ix+dix_eTmp+2), 0
        res     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)

.lln_1
        call    FindLineOnScreen

        jr      nc, lln_2                       ; on screen

        call    PutCurrentLnPtrs

        call    CurrentHasNextLine

        jr      z, lln_3

        OZ      GN_Xnx
        call    PutTopLnPtrs

        set     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        jr      lln_1


.lln_2
        dec     a
        ld      (ix+dix_ubCrsrYPos), a
        call    GetPrev

        call    PutCurrentLnPtrs

        jr      lln_4


.lln_3
        ld      (ix+dix_ubCrsrYPos), 7

.lln_4
        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE

        bit     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        jr      z, lln_5

        call    RedrawDiaryWd


.lln_5
        jp      NextOption

;       ----

.FirstLine
        call    ReallocCurrent

        ld      hl, (eMem_dix_254)
        ld      bc, dix_eTopLine
        add     hl, bc
        ex      de, hl
        ld      l, (ix+dix_eCurrentDate)
        ld      h, (ix+dix_eCurrentDate+1)
        ld      b, (ix+dix_eCurrentDate+2)
        call    MayBindS1

        ld      bc, 6
        add     hl, bc
        call    Cmp3_HL_DE

        push    af
        call    sub_D969

        pop     af
        jr      z, fln_1

        call    RedrawDiaryWd


.fln_1
        jp      NextOption

;       ----

.ScreenDown
        call    ReallocCurrent

        call    CurrentHasNextLine

        jp      z, NextOption

        ld      (ix+dix_ubTmp), 0
        call    GetCurrentLnPtrs


.sdn_1
        OZ      GN_Xnx
        inc     (ix+dix_ubTmp)
        inc     (ix+dix_ubCrsrYPos)
        call    PutCurrentLnPtrs

        call    CurrentHasNextLine

        jr      z, sdn_2

        ld      a, 7
        cp      (ix+dix_ubTmp)
        jr      nz, sdn_1


.sdn_2
        call    GetTopLnPtrs


.sdn_3
        xor     a
        cp      (ix+dix_ubTmp)
        jr      z, sdn_4

        OZ      GN_Xnx
        dec     (ix+dix_ubTmp)
        dec     (ix+dix_ubCrsrYPos)
        jr      sdn_3


.sdn_4
        call    PutTopLnPtrs

        jp      loc_D45C

;       ----

.ScreenUp
        call    ReallocCurrent

        call    CurrentHasPrevLine

        jp      z, NextOption

        ld      (ix+dix_ubTmp), 0
        call    GetCurrentLnPtrs


.sup_1
        call    GetPrev

        inc     (ix+dix_ubTmp)
        dec     (ix+dix_ubCrsrYPos)
        call    PutCurrentLnPtrs

        call    CurrentHasPrevLine

        jr      z, sup_2

        ld      a, 7
        cp      (ix+dix_ubTmp)
        jr      nz, sup_1


.sup_2
        call    GetTopLnPtrs


.sup_3
        xor     a
        cp      (ix+dix_ubTmp)
        jr      z, sup_4

        call    TstPrevNode

        jr      z, sup_4

        call    GetPrev

        dec     (ix+dix_ubTmp)
        inc     (ix+dix_ubCrsrYPos)
        jr      sup_3


.sup_4
        call    PutTopLnPtrs

        jp      loc_D45C

;       ----

.NextDay
        call    StoreCurrentLine

        call    sub_D76E

        call    CpyDate_Current_2

        inc     (ix+dix_CurrentDate)
        jr      nz, nxd_1

        inc     (ix+dix_CurrentDate+1)
        jr      nz, nxd_1

        inc     (ix+dix_CurrentDate+2)

.nxd_1
        jr      loc_C79E


.PreviousDay
        call    StoreCurrentLine

        call    sub_D76E

        call    CpyDate_Current_2

        ld      a, (ix+dix_CurrentDate)
        or      a
        jr      nz, prevday_2

        or      (ix+dix_CurrentDate+1)
        jr      nz, prevday_1

        dec     (ix+dix_CurrentDate+2)

.prevday_1
        dec     (ix+dix_CurrentDate+1)

.prevday_2
        dec     (ix+dix_CurrentDate)

.loc_C79E
        call    VerifyCurrentDate

        jr      nc, loc_C7AC

        ld      hl, DateRange_TXT
        call    ShowError

        call    CpyDate_2_Current


.loc_C7AC
        jp      loc_C0E4

;       ----

.NextActiveDay
        call    StoreCurrentLine

        call    GetCurrentDatePtrs

        call    TstNextNode

        jp      z, NextOption

        OZ      GN_Xnx
        jr      loc_C7CF


.PreviousActiveDay
        call    StoreCurrentLine

        call    GetCurrentDatePtrs

        call    TstPrevNode

        jp      z, NextOption

        call    GetPrev


.loc_C7CF
        call    Cpy6_CrntDate_SrchDate

        call    PutCurrentDatePtrs

        call    MayRemoveDate

        call    Cpy6_CrntDate_SrchDate

        call    InitSearchDate

        call    Cpy6_SrchLn_CrntLn

        call    CpyDate_2_Current

        jp      loc_C107

;       ----

.Today
        call    StoreCurrentLine

        call    sub_D76E

        call    GetCurrentDate

        jp      loc_C0E4

;       ----

.LastActiveDay
        res     DF5D_B_0, (ix+dix_ubFlags5D)    ; local flag
        jr      actd_1


.FirstActiveDay
        set     DF5D_B_0, (ix+dix_ubFlags5D)

.actd_1
        call    StoreCurrentLine

        call    sub_D76E

        call    sub_DC8D

        call    GetSrchDatePtrs

        call    TstBHL

        jp      z, loc_C0F2

        bit     DF5D_B_0, (ix+dix_ubFlags5D)
        jr      nz, actd_4


.actd_2
        OZ      GN_Xnx
        jr      c, actd_3

        call    TstBHL

        jr      nz, actd_2                      ; loop  until last found


.actd_3
        call    GetPrev

        call    PutSearchDatePtrs


.actd_4
        call    InitSearchDate

        call    Cpy6_SrchDate_CrntDate

        call    Cpy6_SrchLn_CrntLn

        call    CpyDate_2_Current

        jp      loc_C107

;       ----

.MarkBlock
        call    ReallocCurrent

        bit     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jr      z, loc_C846

        bit     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        jr      z, loc_C84B

        call    InactivateBlk


.loc_C846
        ld      hl, dix_BlkStartLn
        jr      loc_C891


.loc_C84B
        ld      bc, (eMem_dix_254)
        ld      hl, dix_BlkStartDate
        add     hl, bc
        ex      de, hl
        ld      hl, dix_CurrentDate
        add     hl, bc
        call    Cmp3_HL_DE

        jr      c, loc_C876                     ; current < blkstart

        jr      nz, loc_C88E                    ; current > blkstart

        call    GetCurrentLnPtrs


.loc_C862
        push    de
        ld      de, dix_BlkStartLn
        call    Cmp3_ePtr

        pop     de
        jr      z, loc_C876

        call    TstBHL

        jr      z, loc_C88E

        OZ      GN_Xnx
        jr      loc_C862


.loc_C876
        ld      bc, (eMem_dix_254)              ; start -> end
        ld      hl, dix_BlkEndLn
        add     hl, bc
        ex      de, hl
        ld      hl, dix_BlkStartLn
        add     hl, bc
        ld      bc, 7
        ldir
        res     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jr      loc_C846                        ; make  new start


.loc_C88E
        ld      hl, dix_BlkEndLn

.loc_C891
        call    SaveState

        jp      loc_D465

;       ----

.ClearMark
        call    StoreCurrentLine

        call    InactivateBlk

        jp      loc_D465

;       ----

.InactivateBlk
        res     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        res     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        ret

;       ----

.Copy
        set     DF5B_B_ALLOCNEW, (ix+dix_ubFlags5B)     ; local flag
        res     DF5B_B_FREEOLD, (ix+dix_ubFlags5B)      ; local flag
        jr      blk_1


.Move
        set     DF5B_B_ALLOCNEW, (ix+dix_ubFlags5B)     ; allocate more
        set     DF5B_B_FREEOLD, (ix+dix_ubFlags5B)      ; free old
        jr      blk_1


.Delete
        res     DF5B_B_ALLOCNEW, (ix+dix_ubFlags5B)
        set     DF5B_B_FREEOLD, (ix+dix_ubFlags5B)

.blk_1
        call    ReallocCurrent

        ld      a, 5                            ; SC_ENA
        OZ      OS_Esc                          ; Examine special condition
        bit     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jp      z, blk_err1

        call    CursorInBlock                   ; !! should be  able to delete block with cursor in it

        jp      c, blk_err2

        set     DF5B_B_ONEDAY, (ix+dix_ubFlags5B)       ; local flag
        res     DF5B_B_BLOCKDONE, (ix+dix_ubFlags5B)
        call    Cpy6_CrntDate_SrchDate

        ld      hl, dix_BlkStartDate
        ld      de, dix_Date3
        call    Cpy3_HL_DE

        call    sub_D700

        jr      blk_3


.blk_2
        res     DF5B_B_ONEDAY, (ix+dix_ubFlags5B)
        call    MayRemoveDate

        jr      nc, blk_3

        call    GetSrchDatePtrs

        OZ      GN_Xnx
        jp      c, blk_4

        call    PutSearchDatePtrs


.blk_3
        call    GetSrchDatePtrs

        call    TstBHL

        jp      z, blk_4

        ld      (ix+dix_eSrchLnPrev), 0
        ld      (ix+dix_eSrchLnPrev+1), 0
        ld      (ix+dix_eSrchLnPrev+2), 0
        ld      de, 6
        add     hl, de
        ld      (ix+dix_eSrchLn), l
        ld      (ix+dix_eSrchLn+1), h
        ld      (ix+dix_eSrchLn+2), b
        call    MayBindS1

        ld      iy, -3
        ex      de, hl
        add     iy, de
        ex      de, hl
        ld      a, (iy+0)
        ld      (ix+dix_Date2), a
        ld      a, (iy+1)
        ld      (ix+dix_Date2+1), a
        ld      a, (iy+2)
        ld      (ix+dix_Date2+2), a
        bit     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        jr      z, blk_ln1

        ld      bc, (eMem_dix_254)
        ld      hl, dix_Date2
        add     hl, bc
        ex      de, hl
        ld      hl, dix_BlkEndDate
        add     hl, bc
        call    Cmp3_HL_DE

        jp      c, blk_4                        ; blkend<date2


.blk_ln1
        call    GetSrchLnPtrs


.blk_ln2
        OZ      GN_Xnx
        jr      c, blk_2


.blk_ln3
        call    TstBHL

        jr      z, blk_2

        bit     DF5B_B_ONEDAY, (ix+dix_ubFlags5B)
        jr      z, blk_ln4

        push    de
        ld      de, dix_BlkStartLn
        call    Cmp3_ePtr

        pop     de
        jr      nz, blk_ln2

        res     DF5B_B_ONEDAY, (ix+dix_ubFlags5B)

.blk_ln4
        call    PutSearchLnPtrs

        ld      a, 1
        OZ      OS_Esc                          ; Examine special condition
        jp      nz, blk_4

        bit     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        jr      z, blk_ln5

        push    de
        ld      de, dix_BlkEndLn
        call    Cmp3_ePtr

        pop     de
        jr      nz, blk_ln6


.blk_ln5
        set     DF5B_B_BLOCKDONE, (ix+dix_ubFlags5B)

.blk_ln6
        bit     DF5B_B_ALLOCNEW, (ix+dix_ubFlags5B)
        jr      z, blk_ln8

        call    CheckMemory

        jp      c, blk_4

        call    MayBindS1

        push    hl
        pop     iy
        ld      bc, 4
        add     hl, bc
        ex      de, hl
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer2
        add     hl, bc
        ex      de, hl
        push    de
        ld      c, (iy+3)
        xor     a
        ld      b, a
        push    bc
        cp      c
        jr      z, blk_ln7

        ldir

.blk_ln7
        pop     bc
        push    bc
        ld      a, 4
        add     a, c
        ld      c, a
        call    AllocBindMulti

        jp      c, ErrQuit

        call    InsertCurrentLine

        push    bc
        push    de
        push    hl
        call    AdvanceCurrentPtrs

        pop     hl
        pop     de
        pop     bc
        push    hl
        pop     iy
        pop     bc
        ld      (iy+3), c
        ld      de, 4
        add     hl, de
        ex      de, hl
        pop     hl
        ld      a, c
        or      a
        jr      z, blk_ln8

        ldir

.blk_ln8
        bit     DF5B_B_FREEOLD, (ix+dix_ubFlags5B)
        jr      z, blk_ln11

        call    GetSrchLnPtrs

        ld      (ix+dix_eTmp), l
        ld      (ix+dix_eTmp+1), h
        ld      (ix+dix_eTmp+2), b
        push    hl
        push    bc
        push    ix
        OZ      GN_Xdl
        pop     ix
        call    PutSearchLnPtrs

        call    MayInactivateSaved

        pop     bc
        pop     hl
        ld      de, dix_eCurrentLine
        call    Cmp3_ePtr

        jr      nz, blk_ln9

        push    hl
        ld      hl, dix_eSrchLn
        ld      de, dix_eCurrentLine
        call    Cpy3_HL_DE

        pop     hl

.blk_ln9
        ld      de, dix_eCurrentLnPrev
        call    Cmp3_ePtr

        jr      nz, blk_ln10

        push    hl
        ld      hl, dix_eSrchLnPrev
        ld      de, dix_eCurrentLnPrev
        call    Cpy3_HL_DE

        pop     hl

.blk_ln10
        push    hl
        pop     iy
        call    MayBindS1

        ld      a, (iy+3)
        add     a, 4
        ld      c, a
        call    FreeMultiMem

        jp      c, ErrQuit


.blk_ln11
        bit     DF5B_B_BLOCKDONE, (ix+dix_ubFlags5B)
        jr      nz, blk_4

        bit     DF5B_B_FREEOLD, (ix+dix_ubFlags5B)
        jp      z, blk_ln1

        call    GetSrchLnPtrs

        jp      blk_ln3


.blk_4
        bit     DF5B_B_FREEOLD, (ix+dix_ubFlags5B)      ; copy doesn't deselect block
        jr      z, blk_5

        call    InactivateBlk


.blk_5
        ld      hl, dix_eCurrentLine
        ld      de, dix_eTmp
        call    Cpy3_HL_DE

        call    sub_DAEE

        call    RedrawDiaryWd

        jr      blk_x


.blk_err1
        push    hl
        ld      hl, NoMarker_txt
        jr      blk_err


.blk_err2
        push    hl
        ld      hl, Overlaps_TXT

.blk_err
        call    ShowError

        pop     hl

.blk_x
        jp      NextOption

;       ----

.Search
        call    ReallocCurrent

        ld      a, 6
        OZ      OS_Esc                          ; Examine special condition
        ld      (ix+dix_ubFlags5E), 1           ; ignore case
        res     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        call    Search2


.loc_CAA0
        ld      c, 77

.loc_CAA2
        ld      a, 3
        call    MoveTo_0Ya

        ld      a, 9
        ld      b, 78
        ld      hl, lbuf_Buffer3
        ld      de, (eMem_LineBuffers)
        add     hl, de
        ex      de, hl
        OZ      GN_Sip                          ; system input  line routine
        jr      nc, loc_CACA

        cp      RC_Quit                         ; Request application to quit *
        jp      z, Quit

        call    WrMailDate

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      nz, loc_CAA2

        call    Search3

        jr      loc_CAA2


.loc_CACA
        cp      IN_ESC
        jp      z, sub_CD00

        cp      IN_ENT
        jr      z, loc_CAE9

        cp      '-'
        jr      nz, loc_CAA2

        ld      de, SearchUI_tbl
        call    DoUI

        jp      c, Quit

        cp      IN_ESC
        jp      z, sub_CD00

        cp      '.'
        jr      z, loc_CAA0


.loc_CAE9
        set     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        call    sub_D581

        jp      c, sub_CD00

        jp      sub_CBF1

;       ----

.NextMatch
        res     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        jr      loc_CB00


.PrevMatch
        set     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)

.loc_CB00
        call    ReallocCurrent

        set     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        res     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        call    sub_D581

        jp      c, loc_CBC6

        bit     DF5E_B_SEARCHBLOCK, (ix+dix_ubFlags5E)
        jr      z, loc_CB34

        bit     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jr      nz, loc_CB26

        ld      hl, NoMarker_txt
        call    ShowError

        jp      loc_CBB6


.loc_CB26
        call    CursorInBlock

        jr      c, loc_CB34

        ld      hl, NotMarked_TXT
        call    ShowError

        jp      loc_CBB6


.loc_CB34
        call    GetCurrentLnPtrs

        ld      de, lbuf_Buffer2
        call    Cpy_BHL_BufDE

        call    Cpy6_CrntDate_SrchDate

        call    CpyDate_Current_2

        call    Cpy6_CrntLn_SrchLn

        ld      c, (ix+dix_ubCrsrXPos)
        bit     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        jr      nz, loc_CB5E

        inc     c

.loc_CB50
        call    SearchForw

        jr      nc, loc_CB85

        call    AdvanceSearchPos

        ld      c, 0
        jr      nc, loc_CB50

        jr      loc_CB6F


.loc_CB5E
        ld      a, c
        or      a
        jr      z, loc_CB68

        dec     c
        call    SearchBack

        jr      nc, loc_CB85


.loc_CB68
        call    AdvanceSearchPos

        ld      c, 78
        jr      nc, loc_CB5E


.loc_CB6F
        bit     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        call    nz, Redraw

        res     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        ld      hl, NoMatch_txt
        call    ShowError

        call    GetCurrentLnPtrs

        jr      loc_CBB6


.loc_CB85
        ld      (ix+dix_ubCrsrXPos), c
        ld      hl, dix_eSrchLn
        ld      de, dix_eTmp
        call    Cpy3_HL_DE

        call    GetSrchDatePtrs

        ld      de, dix_eCurrentDate
        call    Cmp3_ePtr

        jr      nz, loc_CBA9

        call    FindLineOnScreen

        jr      c, loc_CBAF

        call    PutCurrentLnPtrs

        ld      (ix+dix_ubCrsrYPos), a
        jr      loc_CBB6


.loc_CBA9
        call    Cpy6_SrchDate_CrntDate

        call    CpyDate_2_Current


.loc_CBAF
        call    sub_DAEE

        set     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)

.loc_CBB6
        call    GetCurrentLnPtrs

        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE

        bit     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        call    nz, Redraw


.loc_CBC6
        jp      NextOption

;       ----

.List
        call    ReallocCurrent

        ld      a, 6                            ; SC_DIS
        OZ      OS_Esc                          ; Examine special condition
        ld      (ix+dix_ubFlags5E), $10         ; DF5E_MAKESEARCHLIST
        res     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        res     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        call    List2


.loc_CBDF
        ld      de, ListUI_tbl
        call    DoUI

        jp      c, Quit

        cp      IN_ESC
        jp      z, sub_CD00

        cp      '.'
        jr      z, loc_CBDF

;       ----

.sub_CBF1
        call    ToggleCursor

        call    CheckMemory

        jp      c, sub_CD00

        ld      a, 5
        OZ      OS_Esc                          ; Examine special condition
        res     DF5C_B_2, (ix+dix_ubFlags5C)
        ld      (ix+dix_ubTmp), 7
        bit     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        jr      nz, loc_CC12

        bit     DF5E_B_LST_SV_BLOCK, (ix+dix_ubFlags5E)
        jr      loc_CC16


.loc_CC12
        bit     DF5E_B_SEARCHBLOCK, (ix+dix_ubFlags5E)

.loc_CC16
        jr      nz, loc_CC20

        call    sub_DC8D

        call    InitSearchDate

        jr      loc_CC34


.loc_CC20
        call    sub_DCEC

        jr      c, loc_CC2D

        call    InitSearchDate

        call    sub_DD06

        jr      nc, loc_CC34


.loc_CC2D
        set     DF5C_B_2, (ix+dix_ubFlags5C)
        jp      sub_CD00


.loc_CC34
        call    GetSrchLnPtrs

        ld      de, lbuf_Buffer2
        call    Cpy_BHL_BufDE

        ld      a, (ix+dix_ubFlags5E)
        and     $30                             ; bits  4 & 5, make or print search list
        jr      nz, loc_CC5A

        bit     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        jp      z, sub_CD00

        call    InitWd

        call    ShowInsertMode

        ld      c, 0
        set     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        jp      loc_CB50


.loc_CC5A
        bit     DF5E_B_MAKESEARCHLIST, (ix+dix_ubFlags5E)
        jr      z, loc_CC66

        ld      hl, SearchListWd_txt
        OZ      GN_Sop                          ; write string  to std. output

.loc_CC66
        bit     DF5E_B_PRINTSEARCHLIST, (ix+dix_ubFlags5E)
        jr      z, loc_CC74

        ld      a, 5
        OZ      OS_Prt                          ; Send  character directly to printer filter
        ld      a, '['
        OZ      OS_Prt                          ; Send  character directly to printer filter

.loc_CC74
        ld      (ix+dix_Date3), -1
        ld      (ix+dix_Date3+1), -1
        ld      (ix+dix_Date3+2), -1

.srch_loop
        ld      c, 0
        or      a                               ; Fc=0
        bit     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        call    nz, SearchForw

        jr      c, loc_CCE7

        ld      l, (ix+dix_Date2)
        ld      h, (ix+dix_Date2+1)
        ld      b, (ix+dix_Date2+2)
        ld      de, dix_Date3
        call    Cmp3_ePtr

        jr      z, loc_CCD6                     ; still same date, just print

        ld      hl, dix_Date2
        ld      de, dix_Date3
        call    Cpy3_HL_DE

        ld      bc, (eMem_dix_254)
        ld      hl, dix_DateBuf
        add     hl, bc
        push    hl
        ex      de, hl
        ld      hl, dix_Date3
        add     hl, bc
        ld      a, $0C0                         ; century, date suffix
        ld      b, $0F                          ; everything in expanded form
        OZ      GN_Pdt                          ; convert internal date to ASCII string
        jr      nc, loc_CCC3

        pop     hl
        ld      hl, NoMem_txt
        jr      loc_CCCD


.loc_CCC3
        ex      de, hl                          ; null-terminate
        ld      (hl), 0
        ld      hl, CRLF_txt
        call    PrintList

        pop     hl

.loc_CCCD
        call    PrintList                       ; print date

        ld      hl, CRLF_txt
        call    PrintList


.loc_CCD6
        ld      hl, lbuf_Buffer2
        ld      de, (eMem_LineBuffers)
        add     hl, de
        call    PrintList

        ld      hl, CRLF_txt
        call    PrintList


.loc_CCE7
        ld      a, 1
        OZ      OS_Esc                          ; Examine special condition
        jr      nz, loc_CCF9

        call    AdvanceSearchPos

        jr      nc, srch_loop

        bit     DF5E_B_MAKESEARCHLIST, (ix+dix_ubFlags5E)
        call    nz, MayPageWait


.loc_CCF9
        bit     DF5E_B_PRINTSEARCHLIST, (ix+dix_ubFlags5E)
        call    nz, PrtFormFeed

;       ----

.sub_CD00
        call    sub_E14A

        bit     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        call    nz, sub_D581

        bit     DF5C_B_2, (ix+dix_ubFlags5C)
        jr      z, loc_CD16

        ld      hl, NoMarker_txt
        call    ShowError


.loc_CD16
        call    GetCurrentLnPtrs

        jp      loc_D45C

;       ----

.Replace
        call    ReallocCurrent

        ld      a, 6
        OZ      OS_Esc                          ; Examine special condition
        ld      (ix+dix_ubFlags5E), $41
        res     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        set     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        res     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        xor     a
        ld      (ix+dix_uwFoundCount), a
        ld      (ix+dix_uwFoundCount+1), a
        call    Replace2


.loc_CD3D
        ld      c, 77

.loc_CD3F
        ld      a, 2
        call    MoveTo_0Ya

        ld      a, 9
        ld      b, 78
        ld      hl, lbuf_Buffer3
        ld      de, (eMem_LineBuffers)
        add     hl, de
        ex      de, hl
        OZ      GN_Sip                          ; system input  line routine
        jr      nc, loc_CD67

        cp      RC_Quit                         ; Request application to quit *
        jp      z, Quit

        call    WrMailDate

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      nz, loc_CD3F

        call    Replace3

        jr      loc_CD3F


.loc_CD67
        cp      $1B
        jp      z, loc_CF4F

        cp      $0D
        jr      z, loc_CDC1

        cp      $2D
        jr      nz, loc_CD3F

        ld      c, 77

.loc_CD76
        ld      a, 4
        call    MoveTo_0Ya

        ld      a, 9
        ld      b, 78
        ld      hl, $7D
        ld      de, (eMem_dix_254)
        add     hl, de
        ex      de, hl
        OZ      GN_Sip                          ; system input  line routine
        jr      nc, loc_CD9E

        cp      RC_Quit                         ; Request application to quit *
        jp      z, Quit

        call    WrMailDate

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      nz, loc_CD76

        call    Replace3

        jr      loc_CD76


.loc_CD9E
        cp      $1B
        jp      z, loc_CF4F

        cp      $0D
        jr      z, loc_CDC1

        cp      $2E                             ; '.'
        jr      z, loc_CD3D

        cp      $2D
        jr      nz, loc_CD76

        ld      de, RplcUI_tbl
        call    DoUI

        jp      c, Quit

        cp      $1B
        jp      z, loc_CF4F

        cp      $2E
        jr      z, loc_CD76


.loc_CDC1
        ld      a, 5
        OZ      OS_Esc                          ; Examine special condition
        call    InitWd

        call    ShowInsertMode

        call    sub_D581

        jp      c, loc_CF54

        call    CheckMemory

        jp      c, loc_CF4F

        bit     DF5E_B_SEARCHBLOCK, (ix+dix_ubFlags5E)
        jr      nz, loc_CDE5

        call    sub_DC8D

        call    InitSearchDate

        jr      loc_CDF4


.loc_CDE5
        call    sub_DCEC

        jp      c, loc_CF54

        call    InitSearchDate

        call    sub_DD06

        jp      c, loc_CF54


.loc_CDF4
        call    GetSrchLnPtrs

        ld      de, lbuf_Buffer2
        call    Cpy_BHL_BufDE


.loc_CDFD
        ld      c, 0

.loc_CDFF
        call    SearchForw

        jr      nc, loc_CE13

        ld      a, 1
        OZ      OS_Esc                          ; Examine special condition
        jp      nz, loc_CF54

        call    AdvanceSearchPos

        jp      c, loc_CF54

        jr      loc_CDFD


.loc_CE13
        ld      (ix+dix_ubCrsrXPos), c
        res     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        inc     (ix+dix_uwFoundCount)
        jr      nz, loc_CE22

        inc     (ix+dix_uwFoundCount+1)

.loc_CE22
        ld      hl, dix_eSrchLn
        ld      de, dix_eTmp
        call    Cpy3_HL_DE

        call    GetSrchDatePtrs

        ld      de, dix_eCurrentDate
        call    Cmp3_ePtr

        jr      nz, loc_CE43

        call    FindLineOnScreen

        jr      c, loc_CE49

        call    PutCurrentLnPtrs

        ld      (ix+dix_ubCrsrYPos), a
        jr      loc_CE4C


.loc_CE43
        call    Cpy6_SrchDate_CrntDate

        call    CpyDate_2_Current


.loc_CE49
        call    sub_DAEE


.loc_CE4C
        call    GetCurrentLnPtrs

        ld      de, 0
        call    Cpy_BHL_BufDE

        bit     DF5E_B_CONFIRMRPLC, (ix+dix_ubFlags5E)
        call    z, ShowFoundCount

        jr      z, loc_CEC9

        call    Redraw

        ld      hl, ReplaceYN_txt
        call    ShowError

        OZ      OS_Pout
        defm    1,"3@",0

        ld      a, (ix+dix_ubCrsrXPos)
        add     a, $20
        OZ      OS_Out                          ; write a byte  to std. output
        ld      a, (ix+dix_ubCrsrYPos)
        add     a, $20
        OZ      OS_Out                          ; write a byte  to std. output

.loc_CE7B
        call    ToggleCursor

        OZ      OS_In                           ; read  a byte from std. input
        call    ToggleCursor

        jr      c, loc_CE92

        cp      0
        jr      z, loc_CE7B

        OZ      GN_Cls                          ; Classify a character
        jr      nc, loc_CEB1

        and     $0DF                            ; upper()
        jr      loc_CEB1


.loc_CE92
        cp      RC_Quit                         ; Request application to quit *
        jp      z, Quit

        cp      RC_Esc                          ; Escape condition (e.g. ESC pressed)
        jr      nz, loc_CEA2

        ld      a, 1                            ; !! already 1
        OZ      OS_Esc                          ; Examine special condition
        jp      loc_CF54


.loc_CEA2
        call    WrMailDate

        cp      $66
        jr      nz, loc_CE7B

        call    InitWd

        call    ShowInsertMode

        jr      loc_CE4C


.loc_CEB1
        cp      'Y'
        jr      z, loc_CEC6

        cp      'N'
        jr      nz, loc_CE7B

        ld      c, (ix+dix_ubCrsrXPos)
        inc     c
        call    Cpy_InBuf_Buf2

        call    Cpy6_CrntLn_SrchLn

        jp      loc_CDFF


.loc_CEC6
        call    RemoveError


.loc_CEC9
        call    CheckMemory

        jp      c, loc_CF54

        call    Cpy_InBuf_Buf2

        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_InputBuffer
        add     hl, bc
        ld      b, 0
        ld      c, (ix+dix_ubCrsrXPos)
        add     hl, bc
        ld      (hl), 0
        push    hl
        ld      de, (eMem_dix_254)
        ld      hl, $7D
        add     hl, de
        pop     de
        call    AppendToCurrent

        xor     a
        ld      (de), a
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer3
        add     hl, bc
        ld      bc, 79
        xor     a
        cpir
        ld      a, 78
        sub     c
        ld      c, (ix+dix_ubCrsrXPos)
        add     a, c
        ld      c, a
        ld      hl, lbuf_Buffer2
        add     hl, bc
        ld      bc, (eMem_LineBuffers)
        add     hl, bc
        push    hl
        push    de
        ld      hl, 0
        add     hl, bc
        ex      de, hl
        or      a
        sbc     hl, de
        ld      (ix+dix_ubCrsrXPos), l
        pop     de
        pop     hl
        res     DF5C_B_APPND_NEWLINE, (ix+dix_ubFlags5C)
        xor     a
        cp      (hl)
        jr      z, loc_CF2D

        call    AppendToCurrent

        ex      de, hl
        ld      (hl), 0

.loc_CF2D
        call    ReallocCurrent

        call    GetCurrentLnPtrs

        bit     DF5C_B_APPND_NEWLINE, (ix+dix_ubFlags5C)
        call    nz, GetPrev

        call    PutCurrentLnPtrs

        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE

        ld      c, (ix+dix_ubCrsrXPos)
        call    Cpy_InBuf_Buf2

        call    Cpy6_CrntLn_SrchLn

        jp      loc_CDFF


.loc_CF4F
        call    InitWd

        jr      loc_CF5A


.loc_CF54
        call    sub_D581

        call    nc, ShowFoundCount


.loc_CF5A
        call    PrintDate

        call    ShowInsertMode

        bit     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)
        jr      z, loc_CF79

        call    Cpy_CurrentLine_eTmp

        call    FindLineOnScreen

        jr      c, loc_CF76

        call    PutCurrentLnPtrs

        ld      (ix+dix_ubCrsrYPos), a
        jr      loc_CF79


.loc_CF76
        call    sub_DAEE


.loc_CF79
        call    GetCurrentLnPtrs

        jp      loc_D45C

;       ----

.ShowFoundCount
        push    hl
        push    de
        push    bc
        push    af
        call    PrntErrorPre
        ld      hl, 2
        ld      d, h
        ld      e, h
        ld      a, 4
        ld      c, (ix+dix_uwFoundCount)
        ld      b, (ix+dix_uwFoundCount+1)
        push    ix
        call    GetOutHandle

        OZ      GN_Pdn                          ; Integer to ASCII conversion
        pop     ix
        ld      hl, Found_txt
        OZ      GN_Sop                          ; write string  to std. output
        call    loc_E23A

        pop     af
        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.AppendToCurrent
        push    de
        push    hl
        ld      a, (ix+dix_ubCrsrXPos)
        cp      77
        jr      c, loc_CFBB

        pop     de
        pop     hl
        jr      loc_D002


.loc_CFBB
        ld      a, 77
        sub     (ix+dix_ubCrsrXPos)             ; #bytes_after_cursor
        ld      c, a
        inc     c
        ld      b, 0
        pop     hl
        push    hl
        push    bc
        xor     a
        cpir
        pop     bc
        jr      z, loc_D01A                     ; found NULL? can append

        pop     hl
        push    hl
        ld      a, ' '
        cpir
        jr      z, loc_CFD9                     ; found ' '? can append

        pop     de
        pop     hl
        jr      loc_D002


.loc_CFD9
        jp      pe, loc_CFDF

        ex      de, hl
        jr      loc_CFE8


.loc_CFDF
        jp      po, loc_CFE8

        push    hl
        pop     de
        cpir
        jr      z, loc_CFDF


.loc_CFE8
        pop     hl
        push    hl
        or      a
        ex      de, hl
        sbc     hl, de
        push    hl
        pop     bc
        pop     hl
        pop     de
        ld      b, 0
        ld      a, c
        cp      77
        jr      nc, loc_CFFF

        or      b
        jr      z, loc_CFFF

        ldir
        dec     de

.loc_CFFF
        ex      de, hl
        ld      (hl), 0

.loc_D002
        ld      hl, lbuf_InputBuffer
        ld      bc, (eMem_LineBuffers)
        add     hl, bc
        push    hl
        push    de
        call    ReallocCurrent

        call    InsertEmptyLine

        set     DF5C_B_APPND_NEWLINE, (ix+dix_ubFlags5C)
        set     DF5B_B_NEEDREDRAW, (ix+dix_ubFlags5B)

.loc_D01A
        pop     hl
        pop     de
        xor     a

.loc_D01D
        cp      (hl)
        jr      z, locret_D024

        ldi
        jr      loc_D01D


.locret_D024
        ret

;       ----

.Load
        call    ReallocCurrent

        ld      a, 6                            ; SC_DIS
        OZ      OS_Esc                          ; Examine special condition
        res     DF5C_B_2, (ix+dix_ubFlags5C)
        res     DF5E_B_LOADATDATE, (ix+dix_ubFlags5E)
        res     DF5E_B_LST_SV_BLOCK, (ix+dix_ubFlags5E)
        call    Load2


.loc_D03B
        ld      c, 77

.loc_D03D
        ld      a, 3
        call    MoveTo_0Ya

        ld      a, 9
        ld      b, 78
        ld      hl, iob_Filename
        ld      de, (eIOBuf_242)
        add     hl, de
        ex      de, hl
        OZ      GN_Sip                          ; system input  line routine
        jr      nc, loc_D082

        cp      RC_Quit                         ; Request application to quit *
        jp      z, Quit

        push    af
        push    bc
        ld      hl, iob_Filename
        ld      bc, (eIOBuf_242)
        add     hl, bc
        ld      a, (eIOBuf_242+2)
        ld      b, a
        ld      de, Name_txt
        ld      c, 77
        ld      a, 4                            ; SR_RPD
        OZ      OS_Sr                           ; Save  & Restore
        pop     bc
        jr      c, loc_D075

        ld      c, 77

.loc_D075
        pop     af
        call    WrMailDate

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      nz, loc_D03D

        call    LoadDiary

        jr      loc_D03D


.loc_D082
        cp      IN_ESC
        jp      z, loc_D3F5

        cp      IN_ENT
        jr      z, loc_D0A1

        cp      '-'
        jr      nz, loc_D03D

        ld      de, LoadUI_tbl
        call    DoUI

        jp      c, Quit

        cp      IN_ESC
        jp      z, loc_D3F5

        cp      '.'
        jr      z, loc_D03B


.loc_D0A1
        call    ToggleCursor

        push    ix
        ld      bc, (eIOBuf_242)
        ld      hl, iob_Filename
        add     hl, bc
        ld      b, 0
        OZ      GN_Prs                          ; parse filename
        jr      c, load_err

        ld      a, 1                            ; OP_IN
        push    de
        ld      bc, $11
        ld      de, 3
        OZ      GN_Opf                          ; open  file/stream (or device)
        pop     de
        jr      nc, loc_D0D9


.load_err
        pop     ix
        OZ      GN_Err                          ; Display an interactive error  box
        cp      RC_Quit                         ; Request application to quit *
        jp      z, loc_D3F5

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        call    z, LoadDiary

        call    ToggleCursor

        jp      loc_D03B


.loc_D0D9
        ld      (DiaryFileHandle), ix
        pop     ix
        call    CheckMemory

        jp      c, loc_D3CC

        ld      hl, dix_eCurrentLine
        ld      de, dix_e73
        call    Cpy3_HL_DE

        call    Cpy6_CrntDate_SrchDate

        call    CpyDate_Current_2

        call    sub_DCD3

        xor     a
        ld      (ix+dix_76), a
        ld      (ix+dix_77), a
        ld      (ix+dix_78), a
        res     DF5C_B_6, (ix+dix_ubFlags5C)
        ld      hl, iob_IOBuffer
        ld      bc, (eIOBuf_242)
        add     hl, bc
        push    hl
        pop     de
        ld      bc, 158
        add     hl, bc
        ld      (hl), $0D
        ld      hl, 0
        push    ix
        ld      ix, (DiaryFileHandle)
        OZ      OS_Mv                           ; move  bytes between stream and memory
        pop     ix

.loc_D122
        jr      nc, loc_D12B

        ex      de, hl
        ld      (hl), 0
        set     DF5C_B_6, (ix+dix_ubFlags5C)

.loc_D12B
        res     DF5C_B_5, (ix+dix_ubFlags5C)
        ld      hl, lbuf_Buffer2
        ld      bc, (eMem_LineBuffers)
        add     hl, bc
        ex      de, hl
        ld      (ix+dix_ubTmp), 0
        ld      bc, (eIOBuf_242)
        ld      hl, iob_IOBuffer
        add     hl, bc
        ld      a, (hl)
        cp      '%'
        jr      nz, loc_D158

        inc     hl
        cp      (hl)
        jr      z, loc_D158

        set     DF5C_B_5, (ix+dix_ubFlags5C)

.loc_D151
        ld      a, (hl)
        cp      '%'
        jr      nz, loc_D158


.loc_D156
        inc     hl
        ld      a, (hl)

.loc_D158
        bit     DF5C_B_6, (ix+dix_ubFlags5C)
        jr      z, loc_D163

        cp      0
        jp      z, loc_D276


.loc_D163
        cp      $0D
        jr      z, loc_D179

        cp      $20
        jr      c, loc_D156

        ld      a, (ix+dix_ubTmp)
        cp      77
        jr      nc, loc_D17A

        ldi
        inc     (ix+dix_ubTmp)
        jr      loc_D151


.loc_D179
        inc     hl

.loc_D17A
        push    hl
        ex      de, hl
        ld      (hl), 0
        bit     DF5C_B_5, (ix+dix_ubFlags5C)
        jr      z, loc_D1F8

        ld      hl, lbuf_Buffer2
        ld      bc, (eMem_LineBuffers)
        add     hl, bc
        ld      de, 2
        ld      a, $10
        ld      b, $1E
        OZ      GN_Gdt                          ; convert ASCII string  to internal date
        jr      c, loc_D1F8

        bit     DF5E_B_LOADATDATE, (ix+dix_ubFlags5E)
        jr      z, loc_D1D5

        push    af
        ld      a, (ix+dix_76)
        or      (ix+dix_77)
        or      (ix+dix_78)
        jr      nz, loc_D1B6

        pop     af
        ld      (ix+dix_76), c
        ld      (ix+dix_77), b
        ld      (ix+dix_78), a
        jr      loc_D1B7


.loc_D1B6
        pop     af

.loc_D1B7
        push    bc
        pop     hl
        ld      e, (ix+dix_76)
        ld      d, (ix+dix_77)

.loc_D1BF
        ld      c, (ix+dix_78)
        or      a
        sbc     hl, de
        sbc     a, c
        ld      e, (ix+dix_CurrentDate)
        ld      d, (ix+dix_CurrentDate+1)
        ld      c, (ix+dix_CurrentDate+2)
        or      a
        adc     hl, de
        adc     a, c
        push    hl
        pop     bc

.loc_D1D5
        call    CheckMemory

        jp      c, loc_D276

        ld      (ix+dix_Date3), c
        ld      (ix+dix_Date3+1), b
        ld      (ix+dix_Date3+2), a
        ld      hl, dix_Date3
        ld      de, dix_Date2
        call    Cpy3_HL_DE

        call    sub_D700

        call    c, sub_D681

        call    sub_DCD3

        jr      loc_D239


.loc_D1F8
        call    CheckMemory

        jr      c, loc_D276

        call    GetSrchLnPtrs

        OZ      GN_Xnx
        call    PutCurrentLnPtrs

        ld      a, (ix+dix_ubTmp)
        add     a, 4
        ld      c, a
        call    AllocBindMulti

        jp      c, ErrQuit

        call    InsertCurrentLine

        call    Cpy6_CrntLn_SrchLn

        call    GetSrchLnPtrs

        push    hl
        pop     iy
        ld      de, 4
        add     hl, de
        ex      de, hl
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer2
        add     hl, bc
        ld      c, (ix+dix_ubTmp)
        ld      (iy+3), c
        ld      b, 0
        ld      a, c
        or      a
        jr      z, loc_D239

        ldir

.loc_D239
        ld      bc, (eIOBuf_242)
        ld      hl, iob_IOBuffer
        add     hl, bc
        ex      de, hl
        pop     hl
        push    hl
        sbc     hl, de
        push    hl
        pop     bc
        pop     hl
        ld      a, b
        or      c
        jr      z, loc_D276

        push    bc
        push    hl
        ld      hl, $9E
        or      a
        sbc     hl, bc
        push    hl
        pop     bc
        pop     hl
        ld      a, b
        or      c
        jr      z, loc_D25E

        ldir

.loc_D25E
        pop     bc
        bit     DF5C_B_6, (ix+dix_ubFlags5C)
        jp      nz, loc_D12B

        push    ix
        ld      ix, (DiaryFileHandle)
        ld      hl, 0
        OZ      OS_Mv                           ; move  bytes between stream and memory
        pop     ix
        jp      loc_D122


.loc_D276
        call    CpyDate_Current_3

        call    sub_D700

        call    Cpy6_SrchDate_CrntDate

        ld      hl, dix_e73
        ld      de, dix_eTmp
        call    Cpy3_HL_DE

        call    sub_DAEE

        jp      loc_D3CC

;       ----

.Save
        call    ReallocCurrent

        ld      a, 6
        OZ      OS_Esc                          ; Examine special condition
        res     DF5C_B_2, (ix+dix_ubFlags5C)
        res     DF5E_B_LST_SV_BLOCK, (ix+dix_ubFlags5E)
        res     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        res     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        call    Save2


.loc_D2A8
        ld      c, 77

.loc_D2AA
        ld      a, 3
        call    MoveTo_0Ya

        ld      a, 9
        ld      b, 78
        ld      hl, iob_Filename
        ld      de, (eIOBuf_242)
        add     hl, de
        ex      de, hl
        OZ      GN_Sip                          ; system input  line routine
        jr      nc, loc_D2D2

        cp      RC_Quit                         ; Request application to quit *
        jp      z, Quit

        call    WrMailDate

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      nz, loc_D2AA

        call    SaveDiary

        jr      loc_D2AA


.loc_D2D2
        cp      $1B
        jp      z, loc_D3F5

        cp      $0D
        jr      z, loc_D2F1

        cp      $2D
        jr      nz, loc_D2AA

        ld      de, SaveUI_tbl
        call    DoUI

        jp      c, Quit

        cp      $1B
        jp      z, loc_D3F5

        cp      $2E
        jr      z, loc_D2A8


.loc_D2F1
        call    ToggleCursor

        push    ix
        ld      bc, (eIOBuf_242)
        ld      hl, iob_Filename
        add     hl, bc
        ld      b, 0
        OZ      GN_Prs                          ; parse filename
        jr      c, loc_D314

        ld      a, 2
        push    de
        ld      bc, $11
        ld      de, 3
        OZ      GN_Opf                          ; open  file/stream (or device)
        pop     de
        jr      nc, loc_D328


.loc_D314
        pop     ix
        OZ      GN_Err                          ; Display an interactive error  box
        cp      RC_Quit                         ; Request application to quit *
        jp      z, loc_D3F5

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        call    z, SaveDiary

        call    ToggleCursor

        jr      loc_D2A8


.loc_D328
        ld      (DiaryFileHandle), ix
        pop     ix
        call    CheckMemory

        jp      c, loc_D3CC

        bit     DF5E_B_LST_SV_BLOCK, (ix+dix_ubFlags5E)
        jr      nz, loc_D342

        call    sub_DC8D

        call    InitSearchDate

        jr      loc_D355


.loc_D342
        call    sub_DCEC

        jr      nc, loc_D34D

        set     DF5C_B_2, (ix+dix_ubFlags5C)
        jr      loc_D3CC


.loc_D34D
        call    InitSearchDate

        call    sub_DD06

        jr      c, loc_D3CC


.loc_D355
        call    GetSrchLnPtrs

        ld      de, lbuf_Buffer2
        call    Cpy_BHL_BufDE


.loc_D35E
        ld      hl, dix_Date2
        ld      de, dix_Date3
        call    Cpy3_HL_DE

        ld      bc, (eMem_dix_254)
        ld      hl, dix_DateBuf
        add     hl, bc
        push    hl
        ld      (hl), $0A5
        inc     hl
        ex      de, hl
        ld      hl, dix_Date3
        add     hl, bc
        ld      a, $0B0
        ld      b, 0
        ld      c, $2F
        OZ      GN_Pdt                          ; convert internal date to ASCII string
        jr      nc, loc_D389

        pop     hl
        ld      hl, NoMem_txt
        jr      loc_D38D


.loc_D389
        ex      de, hl
        ld      (hl), 0
        pop     hl

.loc_D38D
        call    SaveLn

        jr      c, loc_D39F


.loc_D392
        ld      hl, lbuf_Buffer2
        ld      de, (eMem_LineBuffers)
        add     hl, de
        call    SaveLn

        jr      nc, loc_D3B4


.loc_D39F
        OZ      GN_Err                          ; Display an interactive error  box
        call    sub_D40C

        ld      hl, iob_Filename
        ld      de, (eIOBuf_242)
        add     hl, de
        ld      b, 0
        OZ      GN_Del                          ; delete file
        jr      loc_D3F5


.loc_D3B4
        call    AdvanceSearchPos

        jr      c, loc_D3CC

        ld      l, (ix+dix_Date2)
        ld      h, (ix+dix_Date2+1)
        ld      b, (ix+dix_Date2+2)
        ld      de, dix_Date3
        call    Cmp3_ePtr

        jr      z, loc_D392

        jr      loc_D35E

;       ----

.loc_D3CC
        bit     DF5E_B_LST_SV_BLOCK, (ix+dix_ubFlags5E)
        jr      nz, loc_D3ED

        xor     a
        ld      hl, (eMem_dix_254)
        ld      de, $0CC
        add     hl, de
        ex      de, hl
        push    de
        ld      hl, (eIOBuf_242)
        ld      bc, iob_Filename
        add     hl, bc
        ld      bc, $0FF31
        OZ      GN_Esa                          ; read/write filename segments
        pop     hl
        OZ      DC_Nam                          ; Name  current application

.loc_D3ED
        call    sub_D40C

        jr      nc, loc_D3F5

        OZ      GN_Err                          ; Display an interactive error  box

.loc_D3F5
        call    sub_E14A

        call    CheckMemory

        bit     DF5C_B_2, (ix+dix_ubFlags5C)
        jr      z, loc_D407

        ld      hl, NoMarker_txt
        call    ShowError


.loc_D407
        call    GetCurrentLnPtrs

        jr      loc_D45C


.sub_D40C
        push    ix
        ld      ix, (DiaryFileHandle)
        OZ      GN_Cl                           ; close file/stream
        pop     ix
        ret

;       ----

; IN:  DE=line

.SaveLn
        push    ix
        push    de
        push    bc
        ld      ix, (DiaryFileHandle)
        ex      de, hl
        ld      bc, (eIOBuf_242)
        ld      hl, iob_IOBuffer
        add     hl, bc                          ; dest  buffer
        push    hl
        ex      de, hl
        ld      bc, 158

.loc_D42E
        ld      a, (hl)
        cp      0
        jr      z, loc_D445

        cp      '%'                                     ; % -> %%
        jr      nz, loc_D43A

        ldi
        dec     hl

.loc_D43A
        ld      a, $0A5                         ; '%'|$80 -> '%'
        cp      (hl)
        jr      nz, loc_D441

        res     7, (hl)

.loc_D441
        ldi
        jr      loc_D42E


.loc_D445
        ld      a, 13
        ld      (de), a
        dec     bc
        or      a
        ld      hl, 158
        sbc     hl, bc
        push    hl
        pop     bc
        pop     hl
        ld      de, 0
        OZ      OS_Mv                           ; move  bytes between stream and memory
        pop     bc
        pop     de
        pop     ix
        ret

;       ----

.loc_D45C
        call    GetCurrentLnPtrs

        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE


.loc_D465
        call    RedrawDiaryWd

        jp      NextOption


.loc_D46B
        call    GetCurrentLnPtrs

        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE

        call    PrintCurrentLn

        jp      NextOption


; OUT: Fc=0, C=match offset

.SearchForw
        push    hl
        push    de
        push    bc
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer3
        add     hl, bc
        ex      de, hl
        ld      hl, lbuf_Buffer2
        add     hl, bc
        pop     bc
        xor     a
        ld      b, a
        or      c                               ; max length
        jr      z, loc_D496

        xor     a
        cpir
        jp      z, loc_D534                     ; no NULL found? Fc=1


.loc_D496
        ld      (ix+dix_6A), e
        ld      (ix+dix_6A+1), d

.loc_D49C
        ld      (ix+dix_68), l
        ld      (ix+dix_68+1), h
        ld      e, (ix+dix_6A)
        ld      d, (ix+dix_6A+1)

.loc_D4A8
        ld      a, (de)
        cp      0
        jr      z, loc_D4C0

        call    CmpChar

        jr      nz, loc_D4B6

        inc     hl
        inc     de
        jr      loc_D4A8


.loc_D4B6
        xor     a
        cp      (hl)
        jr      z, loc_D534

        call    GetMatchPos

        inc     hl
        jr      loc_D49C


.loc_D4C0
        call    GetMatchPos

        jr      loc_D538

;       ----

.GetMatchPos
        ld      l, (ix+dix_68)
        ld      h, (ix+dix_68+1)
        ret

;       ----

.SearchBack
        push    hl
        push    de
        push    bc
        ld      bc, (eMem_LineBuffers)
        ld      hl, 78                          ; lbuf_InputBuffer+78
        add     hl, bc
        ld      (ix+dix_6A), l
        ld      (ix+dix_6A+1), h
        ld      hl, 157                         ; lbuf_Buffer2+77
        add     hl, bc
        ld      (ix+dix_6C), l
        ld      (ix+dix_6C+1), h
        pop     bc
        ld      b, 0
        ld      hl, lbuf_Buffer2
        call    sub_D548

        ex      de, hl
        ld      hl, lbuf_Buffer3
        ld      bc, 78                          ; lbuf_InputBuffer+78
        call    sub_D548

        ex      de, hl
        ld      (ix+dix_uwFoundCount), e
        ld      (ix+dix_uwFoundCount+1), d

.loc_D501
        ld      (ix+dix_68), l
        ld      (ix+dix_68+1), h
        ld      e, (ix+dix_uwFoundCount)
        ld      d, (ix+dix_uwFoundCount+1)

.loc_D50D
        ld      a, e
        cp      (ix+dix_6C)
        jr      nz, loc_D517

        ld      a, d
        cp      (ix+dix_6C+1)

.loc_D517
        jr      z, loc_D537

        ld      a, l
        cp      (ix+dix_6A)
        jr      nz, loc_D523

        ld      a, h
        cp      (ix+dix_6A+1)

.loc_D523
        jr      z, loc_D534

        call    CmpChar

        jr      nz, loc_D52E

        dec     hl
        dec     de
        jr      loc_D50D


.loc_D52E
        call    GetMatchPos

        dec     hl
        jr      loc_D501


.loc_D534
        scf
        jr      loc_D545


.loc_D537
        inc     hl

.loc_D538
        ld      de, (eMem_LineBuffers)
        or      a
        sbc     hl, de
        ld      de, lbuf_Buffer2
        sbc     hl, de
        ld      c, l

.loc_D545
        pop     de
        pop     hl
        ret

;       ----

.sub_D548
        push    bc
        ld      bc, (eMem_LineBuffers)
        add     hl, bc
        pop     bc
        xor     a
        ld      b, a
        or      c
        ld      a, 0                            ; !! ld a,b
        jr      z, loc_D55D

        cpir
        dec     hl
        cp      (hl)
        jr      z, loc_D560                     ; found NULL

        inc     hl

.loc_D55D
        cp      (hl)
        jr      nz, locret_D561


.loc_D560
        dec     hl

.locret_D561
        ret

;       ----

.CmpChar
        ld      a, (de)
        bit     DF5E_B_IGNORECASE, (ix+dix_ubFlags5E)
        jr      z, loc_D570

        OZ      GN_Cls                          ; Classify a character
        jr      nc, loc_D570

        and     $0DF                            ; upper()

.loc_D570
        ld      b, a
        ld      a, (hl)
        bit     DF5E_B_IGNORECASE, (ix+dix_ubFlags5E)
        jr      z, loc_D57F

        OZ      GN_Cls                          ; Classify a character
        jr      nc, loc_D57F

        and     $0DF                            ; upper()

.loc_D57F
        cp      b
        ret

;       ----

.sub_D581
        push    hl
        push    de
        ld      hl, lbuf_Buffer3
        ld      de, (eMem_LineBuffers)
        add     hl, de
        ld      a, (hl)
        cp      0
        jr      nz, loc_D597

        ld      hl, NoString_txt
        call    ShowError

        scf

.loc_D597
        pop     de
        pop     hl
        ret

;       ----

.AdvanceSearchPos
        call    GetSrchLnPtrs

        bit     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        jr      nz, asp_1

        bit     DF5E_B_LST_SV_BLOCK, (ix+dix_ubFlags5E)
        jr      asp_2


.asp_1
        bit     DF5E_B_SEARCHBLOCK, (ix+dix_ubFlags5E)

.asp_2
        jr      z, asp_ln1                      ; not block limited? skip test

        bit     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        jp      z, asp_errx                     ; no end? Fc=1

        push    de                              ; compare to end/start  line
        bit     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        jr      z, asp_blk1

        ld      de, dix_BlkStartLn
        jr      asp_blk2


.asp_blk1
        ld      de, dix_BlkEndLn

.asp_blk2
        call    Cmp3_ePtr

        pop     de
        jp      z, asp_errx                     ; match? Fc=1


.asp_ln1
        bit     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        jr      z, asp_ln2

        call    GetPrev

        jr      c, asp_date1

        call    TstCDE

        jr      z, asp_date1

        jr      asp_ln3


.asp_ln2
        OZ      GN_Xnx
        jr      c, asp_date1

        call    TstBHL

        jr      z, asp_date1


.asp_ln3
        call    PutSearchLnPtrs

        jr      asp_okx


.asp_date1
        bit     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        jr      nz, asp_date2

        bit     DF5E_B_LST_SV_BLOCK, (ix+dix_ubFlags5E)
        jr      asp_date3


.asp_date2
        bit     DF5E_B_SEARCHBLOCK, (ix+dix_ubFlags5E)

.asp_date3
        jr      z, asp_advd1

        bit     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)   ;       compare to end/start date
        jr      z, asp_date4

        ld      hl, dix_BlkStartDate
        jr      asp_date5


.asp_date4
        ld      hl, dix_BlkEndDate

.asp_date5
        ld      de, dix_Date2
        ld      bc, (eMem_dix_254)
        add     hl, bc
        ex      de, hl
        add     hl, bc
        call    Cmp3_HL_DE

        jr      z, asp_errx                     ; match? Fc=1


.asp_advd1
        call    GetSrchDatePtrs

        bit     DF5C_B_MATCHBACKW, (ix+dix_ubFlags5C)
        jr      z, asp_advd2

        call    GetPrev

        jr      c, asp_errx

        call    TstCDE

        jr      z, asp_errx

        call    PutSearchDatePtrs

        call    sub_DCD3

        jr      asp_advd3


.asp_advd2
        OZ      GN_Xnx
        jr      c, asp_errx

        call    TstBHL

        jr      z, asp_errx

        call    PutSearchDatePtrs

        call    InitSearchDate


.asp_advd3
        call    TstBHL

        jr      z, asp_advd1


.asp_okx
        ld      de, lbuf_Buffer2
        call    Cpy_BHL_BufDE

        or      a
        jr      asp_x


.asp_errx
        scf

.asp_x
        ret

;       ----

.Cpy_InBuf_Buf2
        set     DF5C_B_7, (ix+dix_ubFlags5C)    ; local flag !! remove, use Fc
        jr      loc_D661


.Cpy_Buf2_InBuf
        res     DF5C_B_7, (ix+dix_ubFlags5C)

.loc_D661
        push    hl
        push    de
        push    bc
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer2
        add     hl, bc
        ex      de, hl
        ld      hl, lbuf_InputBuffer
        add     hl, bc
        bit     DF5C_B_7, (ix+dix_ubFlags5C)
        jr      nz, loc_D678

        ex      de, hl

.loc_D678
        ld      bc, 78
        ldir
        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.sub_D681
        push    hl
        push    de
        push    bc
        ld      c, 9
        call    AllocBindMulti

        jp      c, ErrQuit

        push    hl
        ld      e, (ix+dix_eSrchDate)
        ld      d, (ix+dix_eSrchDate+1)
        ld      a, (ix+dix_eSrchDate+2)
        push    af
        inc     sp
        push    de
        ld      e, (ix+dix_eSrchDatePrev)
        ld      d, (ix+DF5E_B_LOADATDATE)
        ld      a, (ix+dix_eSrchDatePrev+2)
        push    af
        inc     sp
        push    de
        ld      (ix+dix_eSrchDate), l
        ld      (ix+dix_eSrchDate+1), h
        ld      (ix+dix_eSrchDate+2), b
        push    bc
        inc     sp
        push    hl
        ld      hl, 0
        add     hl, sp
        push    ix
        OZ      GN_Xin
        pop     ix
        ld      hl, 9
        add     hl, sp
        ld      sp, hl
        pop     iy
        ld      (iy+6), 0
        ld      (iy+7), 0
        ld      (iy+8), 0
        ld      bc, 3
        add     iy, bc
        push    iy
        pop     de
        ld      hl, (eMem_dix_254)
        ld      bc, dix_Date2
        add     hl, bc
        ld      bc, 3
        ldir
        call    InitSearchDate

        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.InsertEmptyLine
        call    AdvanceCurrentPtrs

        ld      c, 4
        call    AllocBindMulti

        jp      c, ErrQuit

        call    InsertCurrentLine

        push    hl
        pop     iy
        ld      (iy+3), 0
        ret

;       ----

.sub_D700
        call    sub_D72D

        jr      c, loc_D715

        jr      z, loc_D72B


.loc_D707
        call    sub_D75F

        call    sub_D72D

        jr      c, loc_D713

        jr      z, loc_D72B

        jr      loc_D707


.loc_D713
        jr      loc_D728


.loc_D715
        call    sub_D750

        call    sub_D72D

        jr      c, loc_D724

        jr      z, loc_D72B

        call    sub_D75F

        jr      loc_D728


.loc_D724
        jr      nz, loc_D715

        jr      loc_D707


.loc_D728
        scf
        jr      locret_D72C


.loc_D72B
        or      a

.locret_D72C
        ret

;       ----

.sub_D72D
        call    GetSrchDatePtrs

        call    TstBHL

        jr      z, loc_D73A

        call    TstCDE

        jr      nz, loc_D73D


.loc_D73A
        scf
        jr      locret_D74F


.loc_D73D
        call    MayBindS1

        ld      bc, 3
        add     hl, bc
        ex      de, hl
        ld      hl, (eMem_dix_254)
        ld      bc, dix_Date3
        add     hl, bc
        call    Cmp3_HL_DE


.locret_D74F
        ret

;       ----

.sub_D750
        call    GetSrchDatePtrs

        call    TstCDE

        jr      z, locret_D75E

        call    GetPrev

        call    PutSearchDatePtrs


.locret_D75E
        ret

;       ----

.sub_D75F
        call    GetSrchDatePtrs

        call    TstBHL

        jr      z, locret_D76D

        OZ      GN_Xnx
        call    PutSearchDatePtrs


.locret_D76D
        ret

;       ----

.sub_D76E
        call    Cpy6_CrntDate_SrchDate

        call    MayRemoveDate

        jp      Cpy6_SrchDate_CrntDate

;       ----

.MayRemoveDate
        call    InitSearchDate

        call    TstBHL

        jr      z, loc_D7D8                     ; no line?

        call    TstNextNode

        jp      nz, mrd_err                     ; no next? Fc=1

        call    MayBindS1

        push    hl
        pop     iy
        ld      a, (iy+3)
        or      a
        jp      nz, mrd_err                     ; length<>0? Fc=1

        ld      hl, dix_eSrchLn
        ld      de, dix_eTmp
        call    Cpy3_HL_DE

        bit     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jr      z, loc_D7A9

        ld      hl, dix_BlkStartLn
        call    Cmp3_HL_eTmp

        jr      z, mrd_err                      ; BlkStart=SrchLn? Fc=1


.loc_D7A9
        bit     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        jr      z, loc_D7B7

        ld      hl, dix_BlkEndLn
        call    Cmp3_HL_eTmp

        jr      z, mrd_err                      ; match? Fc=1


.loc_D7B7
        ld      hl, dix_SavedStates
        ld      iy, (eMem_dix_254)
        ld      bc, $3D                         ; dix_SavedStates+6
        add     iy, bc
        ld      b, 5
        ld      de, 7

.loc_D7C8
        bit     0, (iy+0)
        jr      z, loc_D7D3

        call    Cmp3_HL_eTmp

        jr      z, mrd_err                      ; match? Fc=1


.loc_D7D3
        add     iy, de
        add     hl, de
        djnz    loc_D7C8


.loc_D7D8
        call    GetSrchDatePtrs                 ; remove date

        push    hl
        push    bc
        push    ix                              ; !! push/pop unnecessary
        OZ      GN_Xdl
        pop     ix
        call    PutSearchDatePtrs

        pop     bc
        pop     hl
        ld      de, dix_eCurrentDate            ; removed current? change it
        call    Cmp3_ePtr

        jr      nz, loc_D7FC

        push    hl
        ld      hl, dix_eSrchDate
        ld      de, dix_eCurrentDate
        call    Cpy3_HL_DE

        pop     hl

.loc_D7FC
        ld      de, dix_eCurrentDatePrev        ; removed CurrentPrev?  change it
        call    Cmp3_ePtr

        jr      nz, loc_D80F

        push    hl
        ld      hl, dix_eSrchDatePrev
        ld      de, dix_eCurrentDatePrev
        call    Cpy3_HL_DE

        pop     hl

.loc_D80F
        ld      c, 9                            ; free  date
        call    FreeMultiMem

        jr      nc, mrd_x

        jp      ErrQuit


.mrd_err
        scf

.mrd_x
        ret

;       ----

.CursorInBlock
        call    Cpy6_CrntLn_SrchLn

        call    CpyDate_Current_2

;       ----

.Day2e15InsideBlock
        push    bc
        push    de
        push    hl
        push    af
        bit     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jp      z, loc_D8B7                     ; Fc=0

        res     DF5D_B_DATE2_EQ_BLKDATE, (ix+dix_ubFlags5D)
        ld      bc, (eMem_dix_254)
        ld      hl, dix_BlkStartDate
        add     hl, bc
        ex      de, hl
        ld      hl, dix_Date2
        add     hl, bc
        call    Cmp3_HL_DE

        jr      c, loc_D8B7                     ; Date2<BlkStart? Fc=0

        jr      nz, loc_D856

        set     DF5D_B_DATE2_EQ_BLKDATE, (ix+dix_ubFlags5D)
        ld      hl, dix_eSrchLn
        add     hl, bc
        ex      de, hl
        ld      hl, dix_BlkStartLn
        add     hl, bc
        call    Cmp3_HL_DE

        jr      z, loc_D8B3                     ; ln matches? Fc=1


.loc_D856
        bit     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        jr      z, loc_D8B7                     ; Fc=0

        res     DF5D_B_DATE2_EQ_BLKEND, (ix+dix_ubFlags5D)
        ld      hl, dix_Date2
        add     hl, bc
        ex      de, hl
        ld      hl, dix_BlkEndDate
        add     hl, bc
        call    Cmp3_HL_DE

        jr      c, loc_D8B7                     ; BlkEnd<Date2? Fc=0

        jr      nz, loc_D886

        set     DF5D_B_DATE2_EQ_BLKDATE, (ix+dix_ubFlags5D)
        set     DF5D_B_DATE2_EQ_BLKEND, (ix+dix_ubFlags5D)
        ld      hl, dix_eSrchLn
        add     hl, bc
        ex      de, hl
        ld      hl, dix_BlkEndLn
        add     hl, bc
        call    Cmp3_HL_DE

        jr      z, loc_D8B3                     ; ln matches? Fc=1


.loc_D886
        bit     DF5D_B_DATE2_EQ_BLKDATE, (ix+dix_ubFlags5D)
        jr      z, loc_D8B3                     ; surely in block? Fc=1

        call    GetSrchLnPtrs


.loc_D88F
        call    TstBHL

        jr      z, loc_D8AD                     ; end of list

        OZ      GN_Xnx
        push    de
        ld      de, dix_BlkStartLn
        call    Cmp3_ePtr

        pop     de
        jr      z, loc_D8B7                     ; found BlkStart? Fc=0

        push    de
        ld      de, dix_BlkEndLn
        call    Cmp3_ePtr

        pop     de
        jr      z, loc_D8B3                     ; found BlkEnd? Fc=1

        jr      loc_D88F


.loc_D8AD
        bit     DF5D_B_DATE2_EQ_BLKEND, (ix+dix_ubFlags5D)
        jr      nz, loc_D8B7


.loc_D8B3
        pop     af
        scf
        jr      loc_D8B9


.loc_D8B7
        pop     af
        or      a

.loc_D8B9
        pop     hl
        pop     de
        pop     bc
        ret

;       ----

.StoreCurrentLine
        call    Cpy_CurrentLine_eTmp

        call    TstCurrentLine

        jr      nz, loc_D8DB

        call    CurrentHasPrevLine

        jr      nz, loc_D8DB

        ld      iy, (eMem_LineBuffers)
        ld      a, (iy+0)
        cp      0
        jp      z, locret_D957

        jr      loc_D8DB

;       ----

.ReallocCurrent
        call    Cpy_CurrentLine_eTmp


.loc_D8DB
        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_InputBuffer
        add     hl, bc
        push    hl
        ld      bc, 78
        xor     a
        cpir
        ld      a, 77
        sub     c
        ld      c, a                            ; strlen()
        ld      b, 0
        push    bc
        call    TstCurrentLine

        jr      z, loc_D90C                     ; no line? allocate new one

        call    GetCurrentLnPtrs                ; bhl=e0F

        call    MayBindS1

        ld      bc, 3
        add     hl, bc
        ld      a, (hl)
        pop     bc
        push    bc
        cp      c
        jr      z, loc_D91B

        call    FreeCurrentLine

        jp      c, ErrQuit


.loc_D90C
        pop     bc
        push    bc
        ld      a, 4
        add     a, c
        ld      c, a
        call    AllocBindMulti

        jp      c, ErrQuit

        call    InsertCurrentLine


.loc_D91B
        call    GetCurrentLnPtrs

        push    hl
        pop     iy
        ld      bc, 4
        add     hl, bc
        ex      de, hl                          ; DE=node data
        pop     bc
        pop     hl
        ld      (iy+3), c                       ; store length
        xor     a
        or      c
        jr      z, loc_D931                     ; no data? skip copy

        ldir

.loc_D931
        ld      hl, dix_BlkStartLn
        call    MayReplaceWithCurrent

        ld      hl, dix_BlkEndLn
        call    MayReplaceWithCurrent

        ld      hl, dix_SavedStates
        ld      b, 5
        ld      de, 7

.loc_D945
        call    MayReplaceWithCurrent

        add     hl, de
        djnz    loc_D945

        ld      hl, dix_eTopLnPrev
        call    MayReplaceWithCurrent

        ld      hl, dix_eTopLine
        call    MayReplaceWithCurrent


.locret_D957
        ret

;       ----

; compare ePtr at HL with eTmp, if it matches replace it with eCurrent

.MayReplaceWithCurrent
        push    hl
        push    de
        ld      de, dix_eCurrentLine            ; !! move this  below jr nz
        call    Cmp3_HL_eTmp

        jr      nz, loc_D966

        ex      de, hl
        call    Cpy3_HL_DE


.loc_D966
        pop     de
        pop     hl
        ret

;       ----

.sub_D969
        ld      l, (ix+dix_eCurrentDate)
        ld      h, (ix+dix_eCurrentDate+1)
        ld      b, (ix+dix_eCurrentDate+2)
        call    MayBindS1

        push    hl
        ld      de, 6
        add     hl, de
        ld      (ix+dix_eCurrentLnPrev), l
        ld      (ix+dix_eCurrentLnPrev+1), h
        ld      (ix+dix_eCurrentLnPrev+2), b
        pop     iy
        ld      l, (iy+6)
        ld      h, (iy+7)
        ld      b, (iy+8)
        ld      (ix+dix_eCurrentLine), l
        ld      (ix+dix_eCurrentLine+1), h
        ld      (ix+dix_eCurrentLine+2), b
        call    Cpy2e_CurrentLn_TopLn

        ld      (ix+dix_ubCrsrYPos), 0
        ld      de, 0
;       ----

.Cpy_BHL_BufDE
        push    hl
        push    bc
        call    TstBHL

        jr      z, loc_D9C7                     ; no source? NULL destination

        call    MayBindS1

        push    hl
        pop     iy
        ld      a, (iy+3)
        ld      hl, (eMem_LineBuffers)
        add     hl, de
        ex      de, hl
        ld      bc, 4
        push    iy
        pop     hl
        add     hl, bc
        ld      b, 0                            ; BC=length
        ld      c, a
        or      a
        jr      z, loc_D9CC                     ; 0? skip copy   !! do this test right after ld a

        ldir
        jr      loc_D9CC


.loc_D9C7
        ld      hl, (eMem_LineBuffers)
        add     hl, de
        ex      de, hl

.loc_D9CC
        ex      de, hl                          ; NULL-terminate dest
        ld      (hl), 0
        pop     bc
        pop     hl
        ret

;       ----

.FreeCurrentLine
        call    TstCurrentLine

        jr      z, locret_D9F8

        call    GetCurrentLnPtrs

        push    hl
        push    bc
        push    ix
        OZ      GN_Xdl                          ; remove BHL from list
        pop     ix
        call    PutCurrentLnPtrs

        pop     bc
        pop     iy
        call    MayBindS1

        ld      a, (iy+3)
        add     a, 4
        ld      c, a
        push    iy
        pop     hl
        call    FreeMultiMem


.locret_D9F8
        ret

;       ----

.MayInactivateBlkSaved
        push    hl
        push    de
        push    bc
        jr      loc_DA03

;       ----

.MayInactivateSaved
        push    hl
        push    de
        push    bc
        jr      loc_DA31


.loc_DA03
        ld      hl, dix_BlkStartLn
        call    MayInactivateState

        ld      hl, dix_BlkEndLn
        call    MayInactivateState

; if end is active but start not, we make current end new start
        bit     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        jr      z, loc_DA31

        bit     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jr      nz, loc_DA31

        ld      bc, (eMem_dix_254)
        ld      hl, dix_BlkStartLn
        add     hl, bc
        ex      de, hl
        ld      hl, dix_BlkEndLn
        add     hl, bc
        ld      bc, 7
        ldir
        res     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)

.loc_DA31
        ld      hl, dix_SavedStates
        ld      b, 5
        ld      de, 7

.loc_DA39
        call    MayInactivateState

        add     hl, de
        djnz    loc_DA39

        ld      de, dix_SavedStates_23          ; dix_SavedStates+5*7-1
        ld      hl, (eMem_dix_254)
        add     hl, de
        ld      b, 5
        ld      de, 7

.loc_DA4B
        ld      a, (ix+dix_ubNumSavedPositions)
        cp      b
        jr      c, loc_DA58

        bit     0, (hl)
        jr      nz, loc_DA5E

        dec     (ix+dix_ubNumSavedPositions)

.loc_DA58
        or      a
        sbc     hl, de
        dec     b
        jr      nz, loc_DA4B


.loc_DA5E
        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.MayInactivateState
        push    hl
        push    de
        call    Cmp3_HL_eTmp

        jr      nz, mis_1

        ld      de, (eMem_dix_254)
        add     hl, de
        ld      de, 6
        add     hl, de
        res     0, (hl)

.mis_1
        pop     de
        pop     hl
        ret

;       ----

.Cmp3_HL_eTmp
        push    hl
        push    de
        push    bc
        ld      bc, (eMem_dix_254)
        add     hl, bc
        ex      de, hl
        ld      hl, dix_eTmp
        add     hl, bc
        call    Cmp3_HL_DE

        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.InsertCurrentLine
        push    bc
        push    de
        push    hl
        push    ix
        ld      e, (ix+dix_eCurrentLine)
        ld      d, (ix+dix_eCurrentLine+1)
        ld      a, (ix+dix_eCurrentLine+2)
        push    af                              ; push  ADE (next node)
        inc     sp
        push    de
        ld      e, (ix+dix_eCurrentLnPrev)
        ld      d, (ix+dix_eCurrentLnPrev+1)
        ld      a, (ix+dix_eCurrentLnPrev+2)
        push    af                              ; push  ADE (prev node)
        inc     sp
        push    de
        ld      (ix+dix_eCurrentLine), l        ; put new ptr
        ld      (ix+dix_eCurrentLine+1), h
        ld      (ix+dix_eCurrentLine+2), b
        push    bc                              ; push  BHL (insert node)
        inc     sp
        push    hl
        ld      hl, 0
        add     hl, sp
        OZ      GN_Xin                          ; insert entry
        ld      hl, 9                           ; fix stack
        add     hl, sp
        ld      sp, hl
        pop     ix
        pop     hl
        pop     de
        pop     bc
        ret


.SaveState
        push    de
        push    hl
        push    hl
        ld      de, 0
        add     hl, de
        ex      de, hl
        ld      hl, dix_eCurrentLine
        call    Cpy3_HL_DE

        pop     hl
        ld      de, 3
        add     hl, de
        ex      de, hl
        ld      hl, dix_CurrentDate
        call    Cpy3_HL_DE

        pop     hl
        ld      de, (eMem_dix_254)
        add     hl, de
        ld      de, 6
        add     hl, de
        set     0, (hl)                         ; mark  as active
        pop     de
        ret

;       ----

.sub_DAEE
        call    sub_D969


.loc_DAF1
        call    FindLineOnScreen

        jr      nc, loc_DB00

        jr      z, loc_DB0E

        OZ      GN_Xnx
        call    PutTopLnPtrs

        jr      loc_DAF1


.loc_DB00
        call    PutCurrentLnPtrs

        ld      (ix+dix_ubCrsrYPos), a
        ld      de, lbuf_InputBuffer
        call    Cpy_BHL_BufDE

        jr      locret_DB11


.loc_DB0E
        call    sub_D969


.locret_DB11
        ret

;       ----

.FindLineOnScreen
        call    GetTopLnPtrs

        ld      (ix+dix_Tmp2), 8
        jr      loc_DB28


.loc_DB1B
        dec     (ix+dix_Tmp2)
        jr      z, loc_DB3A

        call    TstBHL

        jr      z, loc_DB3A                     ; !! jr to scf

        OZ      GN_Xnx

.loc_DB28
        push    de
        ld      de, dix_eTmp
        call    Cmp3_ePtr

        pop     de
        jr      nz, loc_DB1B

        ld      a, 8
        sub     (ix+dix_Tmp2)
        or      a                               ; A=line, Fc=0
        jr      locret_DB3E


.loc_DB3A
        call    TstBHL                          ; Fz= BHL status

        scf

.locret_DB3E
        ret

;       ----

.GetCurrentDatePtrs
        ld      bc, dix_eCurrentDatePrev
        jr      GetDIXptrs


.GetSrchDatePtrs
        ld      bc, dix_eSrchDatePrev
        jr      GetDIXptrs


.GetCurrentLnPtrs
        ld      bc, dix_eCurrentLnPrev
        jr      GetDIXptrs


.GetSrchLnPtrs
        ld      bc, dix_eSrchLnPrev
        jr      GetDIXptrs


.GetTopLnPtrs
        ld      bc, dix_eTopLnPrev

.GetDIXptrs
        push    ix
        add     ix, bc
        ld      e, (ix+0)
        ld      d, (ix+1)
        ld      c, (ix+2)
        ld      l, (ix+3)
        ld      h, (ix+4)
        ld      b, (ix+5)
        pop     ix
        ret

;       ----

.PutCurrentDatePtrs
        push    af
        ld      a, dix_eCurrentDatePrev
        jr      PutDIXptrs


.PutSearchDatePtrs
        push    af
        ld      a, dix_eSrchDatePrev
        jr      PutDIXptrs


.PutCurrentLnPtrs
        push    af
        ld      a, dix_eCurrentLnPrev
        jr      PutDIXptrs


.PutSearchLnPtrs
        push    af
        ld      a, dix_eSrchLnPrev
        jr      PutDIXptrs


.PutTopLnPtrs
        push    af
        ld      a, dix_eTopLnPrev

.PutDIXptrs
        push    ix
        push    bc
        ld      c, a
        ld      b, 0
        add     ix, bc
        pop     bc
        ld      (ix+0), e
        ld      (ix+1), d
        ld      (ix+2), c
        ld      (ix+3), l
        ld      (ix+4), h
        ld      (ix+5), b
        pop     ix
        pop     af
        ret

;       ----

.Cpy6_CrntDate_SrchDate
        push    af
        ld      a, dix_eCurrentDatePrev
        jr      cpy6_u


.Cpy6_CrntLn_SrchLn
        push    af
        ld      a, dix_eCurrentLnPrev
        jr      cpy6_u


.Cpy6_SrchDate_CrntDate
        push    af
        ld      a, dix_eCurrentDatePrev
        jr      cpy6_d


.Cpy6_SrchLn_CrntLn
        push    af
        ld      a, dix_eCurrentLnPrev

.cpy6_d
        res     DF5D_B_CPY6UP, (ix+dix_ubFlags5D)       ; local flag
        jr      cpy6_1


.cpy6_u
        set     DF5D_B_CPY6UP, (ix+dix_ubFlags5D)

.cpy6_1
        push    bc
        push    de
        push    hl
        ld      bc, (eMem_dix_254)
        ld      l, a
        ld      h, 0
        add     hl, bc
        ex      de, hl
        add     a, 6
        ld      l, a
        ld      h, 0
        add     hl, bc
        ld      bc, 6
        bit     DF5D_B_CPY6UP, (ix+dix_ubFlags5D)
        jr      z, cpy6_2

        ex      de, hl

.cpy6_2
        ldir
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret

;       ----

.CpyDate_Current_2
        push    af
        push    de
        push    hl
        ld      hl, dix_CurrentDate
        ld      de, dix_Date2
        call    Cpy3_HL_DE

        pop     hl
        pop     de
        pop     af
        ret

;       ----

.CpyDate_2_Current
        push    af
        push    de
        push    hl
        ld      hl, dix_Date2
        ld      de, dix_CurrentDate
        call    Cpy3_HL_DE

        pop     hl
        pop     de
        pop     af
        ret

;       ----

.Cpy2e_CurrentLn_TopLn
        push    hl
        push    de
        push    bc
        call    GetCurrentLnPtrs

        call    PutTopLnPtrs

        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.CpyDate_Current_3
        ld      hl, dix_CurrentDate
        ld      de, dix_Date3
        call    Cpy3_HL_DE

        ret

;       ----

.Cpy_CurrentLine_eTmp
        push    hl
        push    de
        ld      hl, dix_eCurrentLine
        ld      de, dix_eTmp
        call    Cpy3_HL_DE

        pop     de
        pop     hl
        ret

;       ----

; IN: HL=src offset, DE=dst offset

.Cpy3_HL_DE
        push    bc
        push    hl
        push    de
        ld      bc, (eMem_dix_254)
        add     hl, bc
        ex      de, hl
        add     hl, bc
        ex      de, hl
        ld      bc, 3
        ldir
        pop     de
        pop     hl
        pop     bc
        ret

;       ----

.TstBHL
        ld      a, b
        or      h
        or      l
        ret

;       ----

.TstCDE
        ld      a, c
        or      d
        or      e
        ret


.TstNextNode
        call    TstBHL

        jr      z, tstx_1                       ; !! ret z

        push    hl
        push    de
        push    bc
        OZ      GN_Xnx
        call    TstBHL

        pop     bc
        pop     de
        pop     hl

.tstx_1
        ret

;       ----

.TstPrevNode
        call    TstCDE

        jr      z, tstx2_1                      ; !! ret z

        push    hl
        push    de
        push    bc
        call    GetPrev

        call    TstCDE

        pop     bc
        pop     de
        pop     hl

.tstx2_1
        ret

;       ----

.TstCurrentLine
        ld      a, (ix+dix_eCurrentLine)
        or      (ix+dix_eCurrentLine+1)
        or      (ix+dix_eCurrentLine+2)
        ret

;       ----

.CurrentHasNextLine
        push    hl
        push    de
        push    bc
        call    GetCurrentLnPtrs

        call    TstNextNode

        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.CurrentHasPrevLine
        push    hl
        push    bc
        push    de
        call    GetCurrentLnPtrs

        call    TstPrevNode

        pop     de
        pop     bc
        pop     hl
        ret

;       ----

.sub_DC8D
        ld      de, dix_18
        ld      hl, (eMem_dix_254)
        add     hl, de
        ex      de, hl
        ld      a, (eMem_dix_254+2)
        ld      c, a
        ld      l, (ix+dix_18)
        ld      h, (ix+dix_18+1)
        ld      b, (ix+dix_18+2)
        jp      PutSearchDatePtrs

;       ----

; OUT:BHL,CDE=LnPtrs

.InitSearchDate
        call    GetSrchDatePtrs

        push    hl
        pop     iy
        ld      de, 6                           ; DE=HL+6
        add     hl, de
        ex      de, hl
        ld      c, b
        call    MayBindS1

        ld      l, (iy+6)                       ; set LnPtrs
        ld      h, (iy+7)
        ld      b, (iy+8)
        call    PutSearchLnPtrs

        ld      a, (iy+3)                       ; Set Date2
        ld      (ix+dix_Date2), a
        ld      a, (iy+4)
        ld      (ix+dix_Date2+1), a
        ld      a, (iy+5)
        ld      (ix+dix_Date2+2), a
        ret

;       ----

.sub_DCD3
        call    InitSearchDate

        call    TstBHL

        jr      z, locret_DCEB


.loc_DCDB
        OZ      GN_Xnx
        jr      c, loc_DCE5

        call    TstBHL

        jr      nz, loc_DCDB


.loc_DCE5
        call    GetPrev

        call    PutSearchLnPtrs


.locret_DCEB
        ret

;       ----

.sub_DCEC
        bit     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jr      z, loc_DD04

        call    Cpy6_CrntDate_SrchDate

        ld      hl, dix_BlkStartDate
        ld      de, dix_Date3
        call    Cpy3_HL_DE

        call    sub_D700

        or      a
        jr      locret_DD05


.loc_DD04
        scf

.locret_DD05
        ret

;       ----

.sub_DD06
        ld      hl, dix_BlkStartLn
        ld      de, dix_eTmp
        call    Cpy3_HL_DE


.loc_DD0F
        ld      hl, $15
        call    Cmp3_HL_eTmp

        jr      z, locret_DD24

        call    GetSrchLnPtrs

        OZ      GN_Xnx
        jr      c, locret_DD24

        call    PutSearchLnPtrs

        jr      loc_DD0F


.locret_DD24
        ret

;       ----

.GetPrev
        call    xnx2_1

        OZ      GN_Xnx

.xnx2_1
        ex      de, hl
        ld      a, b
        ld      b, c
        ld      c, a
        ret


.AdvanceCurrentPtrs
        call    GetCurrentLnPtrs

        OZ      GN_Xnx
        jp      PutCurrentLnPtrs

;       ----

.RetreatCurrentPtrs
        call    GetCurrentLnPtrs

        call    GetPrev

        jp      PutCurrentLnPtrs

;       ----

.Cmp3_HL_DE
        push    hl
        push    de
        push    bc
        ld      bc, 2                           ; !! inc hl; inc hl; in de; inc de
        add     hl, bc
        ex      de, hl
        add     hl, bc
        ld      b, 3

.loc_DD4D
        ld      a, (de)                         ; !! drop 'ex de,hl' and 'ld a,(hl); cp (de)'
        cp      (hl)
        jr      nz, loc_DD55

        dec     de
        dec     hl
        djnz    loc_DD4D


.loc_DD55
        pop     bc
        pop     de
        pop     hl
        ret

;       ----

; OUT: Fz

.Cmp3_ePtr
        push    hl
        push    de
        push    bc
        ex      de, hl
        ld      bc, (eMem_dix_254)
        add     hl, bc
        pop     bc
        ld      a, e
        cp      (hl)
        jr      nz, cmp3_x

        inc     hl
        ld      a, d
        cp      (hl)
        jr      nz, cmp3_x

        inc     hl
        ld      a, b
        cp      (hl)

.cmp3_x
        pop     de
        pop     hl
        ret

;       ----

.RdMailDate
        res     DF5D_B_WRMAILDATE, (ix+dix_ubFlags5D)   ;       local flag
        call    RdWrDate


.WrMailDate
        set     DF5D_B_WRMAILDATE, (ix+dix_ubFlags5D)

.RdWrDate
        push    hl
        push    de
        push    bc
        push    af
        ld      hl, dix_CurrentDate
        ld      bc, (eMem_dix_254)
        add     hl, bc
        ld      a, (eMem_dix_254+2)
        ld      b, a
        ld      de, Date_txt
        bit     DF5D_B_WRMAILDATE, (ix+dix_ubFlags5D)
        jr      z, rwm_1

        ld      c, 6                            ; write 6 bytes
        ld      a, 3                            ; SR_WPD
        jr      rwm_2


.rwm_1
        ld      c, 3                            ; read  3 bytes
        ld      a, 4                            ; SR_RPD

.rwm_2
        OZ      OS_Sr                           ; Save  & Restore
        pop     af
        pop     bc
        pop     de
        pop     hl
        ret

.Date_txt
        defm    "DATE",0

.VerifyCurrentDate
        push    de
        push    bc
        ld      c, (ix+dix_CurrentDate)
        ld      b, (ix+dix_CurrentDate+1)
        ld      a, (ix+dix_CurrentDate+2)
        OZ      GN_Die                          ; convert from  internal to zoned format
        pop     bc
        pop     de
        ret

;       ----

.GetCurrentDate
        push    hl
        push    de
        ld      hl, (eMem_dix_254)
        ld      de, dix_CurrentDate
        add     hl, de
        ex      de, hl
        OZ      GN_Gmd                          ; get current machine date in internal  format
        pop     de
        pop     hl
        ret


.GetOutHandle
        push    bc
        ld      bc, NQ_Out
        OZ      OS_Nq                           ; enquire (fetch) parameter
        pop     bc
        ret


.AllocBindMulti
        call    AllocMultiMem

        jr      c, abm_1

        call    MayBindS1


.abm_1
        ret

;       ----

.AllocMultiMem
        push    ix
        ld      ix, (pMemHandleMulti)
        xor     a
        ld      b, a
        OZ      OS_Mal                          ; Allocate memory
        pop     ix
        ret

;       ----

.MayBindS1
        push    bc
        push    hl
        ld      a, (S1Binding)                  ; !! cp/ret before push
        cp      b
        jr      z, mbs1_1

        ld      a, b
        ld      (S1Binding), a
        ld      c, MS_S1
        rst     OZ_MPB                          ; Bind bank B in segment C
        or      a                               ; Fc = 0
.mbs1_1
        pop     hl
        pop     bc
        ret

;       ----

.FreeMultiMem
        push    ix
        push    hl
        push    bc
        ld      a, b
        ld      b, 0
        ld      ix, (pMemHandleMulti)
        OZ      OS_Mfr                          ; Free  memory
        pop     bc
        pop     hl
        pop     ix
        ret

;       ----

.CheckMemory
        push    af
        push    bc
        push    de
        push    hl
        ld      a, (S1Binding)
        push    af
        ld      c, (ix+dix_ubCommand)
        ld      b, 0
        ld      hl, CmdFlags_tbl
        add     hl, bc
        ld      a, (hl)
        ld      (ix+dix_Tmp2), a
        res     DF5D_B_ALLOCATEDNEW, (ix+dix_ubFlags5D) ; !! all these are local flags
        res     DF5D_B_ALLOCATED83_1, (ix+dix_ubFlags5D)
        res     DF5D_B_ALLOCATED83_2, (ix+dix_ubFlags5D)
        res     DF5B_B_ALLOC83ERR, (ix+dix_ubFlags5B)
        bit     DF67_B_0, (ix+dix_Tmp2)         ; DF67  local as well
        jr      z, chkm_3

        ld      bc, (eMem_LineBuffers)
        ld      hl, lbuf_InputBuffer
        add     hl, bc
        ld      bc, 78
        xor     a
        cpir
        ld      a, 77
        sub     c                               ; strlen()
        push    af
        call    TstCurrentLine

        jr      nz, chkm_1

        pop     bc
        jr      chkm_2


.chkm_1
        call    GetCurrentLnPtrs

        call    MayBindS1

        ld      bc, 3
        add     hl, bc
        pop     bc
        ld      a, (hl)
        cp      b
        jr      nc, chkm_3                      ; InputBuffer fits? skip


.chkm_2
        ld      a, 4
        add     a, b
        ld      c, a
        ld      e, a
        call    AllocMultiMem

        jr      c, chkm_5

        set     DF5D_B_ALLOCATEDNEW, (ix+dix_ubFlags5D)
        ld      c, e
        push    bc
        push    hl

.chkm_3
        bit     DF67_B_1, (ix+dix_Tmp2)
        jr      z, chkm_4

        ld      c, 83
        call    AllocMultiMem

        jr      c, chkm_5

        set     DF5D_B_ALLOCATED83_1, (ix+dix_ubFlags5D)
        ld      c, 83
        push    bc
        push    hl

.chkm_4
        bit     DF67_B_2, (ix+dix_Tmp2)
        jr      z, chkm_6

        ld      c, 83
        call    AllocMultiMem

        jr      c, chkm_5

        set     DF5D_B_ALLOCATED83_2, (ix+dix_ubFlags5D)
        ld      c, 83
        push    bc
        push    hl
        jr      chkm_6


.chkm_5
        set     DF5B_B_ALLOC83ERR, (ix+dix_ubFlags5B)

.chkm_6
        bit     DF5D_B_ALLOCATED83_2, (ix+dix_ubFlags5D)
        jr      z, chkm_7

        pop     hl
        pop     bc
        call    FreeMultiMem

        jr      nc, chkm_7

        set     DF5B_B_ALLOC83ERR, (ix+dix_ubFlags5B)

.chkm_7
        bit     DF5D_B_ALLOCATED83_1, (ix+dix_ubFlags5D)
        jr      z, chkm_8

        pop     hl
        pop     bc
        call    FreeMultiMem

        jr      nc, chkm_8

        set     DF5B_B_ALLOC83ERR, (ix+dix_ubFlags5B)

.chkm_8
        bit     DF5D_B_ALLOCATEDNEW, (ix+dix_ubFlags5D)
        jr      z, chkm_9

        pop     hl
        pop     bc
        call    FreeMultiMem

        jr      nc, chkm_9

        set     DF5B_B_ALLOC83ERR, (ix+dix_ubFlags5B)

.chkm_9
        bit     DF5B_B_ALLOC83ERR, (ix+dix_ubFlags5B)
        jr      z, chkm_10

        ld      hl, MemoryLow_txt
        call    ShowError

.chkm_10
        pop     bc
        call    MayBindS1

        pop     hl
        pop     de
        pop     bc
        pop     af
        or      a
        bit     DF5B_B_ALLOC83ERR, (ix+dix_ubFlags5B)
        jr      z, chkm_11

        scf

.chkm_11
        ret

;       ----

.PrintCurrentLn
        call    GetCurrentLnPtrs

        ld      a, 8
        sub     (ix+dix_ubCrsrYPos)
        ld      (ix+dix_Tmp2), a
        jr      loc_DF09


.RedrawDiaryWd
        call    GetTopLnPtrs

        ld      (ix+dix_Tmp2), 8

.loc_DF09
        res     DF5B_B_REVERSELINE, (ix+dix_ubFlags5B)
        call    PutSearchLnPtrs

        call    CpyDate_Current_2

        call    Day2e15InsideBlock

        jr      nc, loc_DF1C

        set     DF5B_B_REVERSELINE, (ix+dix_ubFlags5B)

.loc_DF1C
        or      a                               ; Fc=0

.loc_DF1D
        push    af
        push    hl
        ld      a, 8
        sub     (ix+dix_Tmp2)
        call    MoveTo_0Ya

        pop     hl
        pop     af
        jp      c, PrntEndOfText                ; no more to print? "end of text"

        call    TstBHL

        jr      nz, loc_DF3F

        call    TstCurrentLine

        jp      nz, PrntEndOfText

        call    PrntClearEOL
        jr      loc_DF42

.loc_DF3F
        call    PrintOneLine

.loc_DF42
        dec     (ix+dix_Tmp2)
        ret     z

        OZ      GN_Xnx
        jr      loc_DF1D

;       ----

.ShowEndOfText
        push    hl
        push    de
        push    bc
        call    GetCurrentLnPtrs

        OZ      GN_Xnx
        jr      c, loc_DF63
        call    TstBHL
        jr      nz, loc_DF74

.loc_DF63
        ld      a, (ix+dix_ubCrsrYPos)
        inc     a
        cp      8
        jr      nc, loc_DF74

        call    MoveTo_0Ya
        call    PrntEndOfText

.loc_DF74
        call    MoveTo_0_ypos

        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.PrintOneLine
        push    hl
        push    de
        push    bc
        bit     DF2F_B_ACTIVE, (ix+dix_BlkStartFlags2F)
        jr      z, loc_DFA0

        bit     DF5B_B_REVERSELINE, (ix+dix_ubFlags5B)
        jr      nz, loc_DF98

        push    de                              ; check if we need to turn reverse on
        ld      de, dix_BlkStartLn
        call    Cmp3_ePtr

        pop     de
        jr      nz, loc_DFA0

        set     DF5B_B_REVERSELINE, (ix+dix_ubFlags5B)

.loc_DF98
        OZ      OS_Pout
        defm    1,"2+R",0

.loc_DFA0
        push    de
        ld      de, dix_eCurrentLine
        call    Cmp3_ePtr

        pop     de
        jr      nz, loc_DFB3                    ; not current?  use Buf2

        ld      hl, (eMem_LineBuffers)          ; else  print InputBuf
        ld      bc, lbuf_InputBuffer
        add     hl, bc
        jr      loc_DFC0


.loc_DFB3
        ld      de, lbuf_Buffer2
        call    Cpy_BHL_BufDE

        ld      hl, (eMem_LineBuffers)
        ld      bc, lbuf_Buffer2
        add     hl, bc

.loc_DFC0
        OZ      GN_Sop                          ; write string  to std. output
        call    PrntClearEOL

        OZ      OS_Pout
        defm    1,"2-R"
        defm    1,"2X",$6E
        defm    " ",0

        pop     bc
        pop     de
        pop     hl
        bit     DF36_B_ACTIVE, (ix+dix_BlkEndFlags36)
        jr      z, loc_DFE8

        bit     DF5B_B_REVERSELINE, (ix+dix_ubFlags5B)
        jr      z, locret_DFEC

        push    de                              ; check if we need to turn reverse off
        ld      de, dix_BlkEndLn
        call    Cmp3_ePtr

        pop     de
        jr      nz, locret_DFEC


.loc_DFE8
        res     DF5B_B_REVERSELINE, (ix+dix_ubFlags5B)

.locret_DFEC
        ret

;       ----

.ShowInsertMode
        oz      OS_Pout
        defm    1,"2I3"
        defm    1,"3@",$20+0,$20+6
        defm    1,"2C",$FD
        defm    1,"2+T"
        defm    1,"2JC",0

        bit     DF5B_B_OVERWRITE, (ix+dix_ubFlags5B)
        jr      z, sim_1

        oz      OS_Pout
        defm    "OVERTYPE",0
        jp      PrntErrorPost
.sim_1
        oz      OS_Pout
        defm    "INSERT",0
        jp      PrntErrorPost

;       ----

.PrintDate
        ld      bc, (eMem_dix_254)
        ld      hl, dix_DateBuf
        add     hl, bc
        push    hl
        ex      de, hl
        ld      hl, dix_CurrentDate
        add     hl, bc
        ld      a, $0E0
        ld      b, $0F
        ld      c, $20
        OZ      GN_Pdt                          ; convert internal date to ASCII string
        ex      de, hl
        ld      (hl), 0
        pop     de

        push    af
        oz      OS_Pout
        defm    1,"2I3"
        defm    1,"3@",$20+0,$20+1              ; clear lines 1-4
        defm    1,"2C",$FD
        defm    1,"3@",$20+0,$20+2
        defm    1,"2C",$FD
        defm    1,"3@",$20+0,$20+3
        defm    1,"2C",$FD
        defm    1,"3@",$20+0,$20+4
        defm    1,"2C",$FD
        defm    1,"3+TL"
        defm    1,"2JC",0
        pop     af
        jr      nc, loc_E038

        ld      hl, MemoryLow_txt
        OZ      GN_Sop                          ; write string  to std. output
        jr      loc_E041


.loc_E038
        xor     a

.loc_E039
        inc     a
        call    PrntLn

        cp      4
        jr      nz, loc_E039
.loc_E041
        jp      PrntErrorPost


.PrntLn
        push    af
        call    MoveTo_0Ya

        ex      de, hl

.loc_E04D
        ld      a, (hl)
        inc     hl
        cp      ' '
        jr      z, loc_E05B

        cp      0
        jr      z, loc_E05B

        OZ      OS_Out                          ; write a byte  to std. output
        jr      loc_E04D


.loc_E05B
        ex      de, hl
        pop     af
        ret

;       ----

.Redraw
        call    RedrawDiaryWd

        call    PrintDate

        ret

;       ----

.Search3
        push    hl
        push    de
        push    bc
        call    sub_E14A

        jr      search_1


.Search2
        push    hl
        push    de
        push    bc

.search_1
        call    InitWin4

        OZ      OS_Pout
        defm    "SEARCH DIARY"
        defm    1,"2JN"
        defm    1,"2-R"
        defm    1,"3@",$20+0,$20+2
        defm    1,"3N",$20+28,"-"
        defm    " STRING TO SEARCH FOR "
        defm    1,"3N",$20+28,"-"
        defm    1,"3@",$20+17,$20+4
        defm    "EQUATE UPPER AND LOWER CASE "
        defm    1,"3N",$20+11,"."
        defm    1,"3@",$20+17,$20+5
        defm    "SEARCH ONLY MARKED BLOCK "
        defm    1,"3N",$20+14,"."
        defm    1,"3@",$20+17,$20+6
        defm    "PRODUCE LIST "
        defm    1,"3N",$20+26,"."
        defm    1,"3@",$20+17,$20+7
        defm    "PRINT LIST "
        defm    1,"3N",$20+28,"."
        defm    1,"2-T",0

        ld      a, 3
        call    MoveTo_0Ya

        ld      de, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer3
        add     hl, de
        OZ      GN_Sop                          ; write string  to std. output
        ld      de, SearchUI_tbl
        jp      ExitList

;       ----

.Replace3
        push    hl
        push    de
        push    bc
        call    sub_E14A

        jr      replace_1


.Replace2
        push    hl
        push    de
        push    bc

.replace_1
        call    InitWin4

        OZ      OS_Pout
        defm    "DIARY REPLACE"
        defm    1,"2JN"
        defm    1,"2-R"
        defm    1,"3@",$20+0,$20+1
        defm    1,"3N",$20+28,"-"
        defm    " STRING TO SEARCH FOR "
        defm    1,"3N",$20+28,"-"
        defm    1,"3@",$20+0,$20+3
        defm    1,"3N",$20+27,"-"
        defm    " STRING TO REPLACE WITH "
        defm    1,"3N",$20+27,"-"
        defm    1,"3@",$20+17,$20+5
        defm    "EQUATE UPPER AND LOWER CASE "
        defm    1,"3N",$20+11,"."
        defm    1,"3@",$20+17,$20+6
        defm    "ASK FOR CONFIRMATION "
        defm    1,"3N",$20+18,"."
        defm    1,"3@",$20+17,$20+7
        defm    "SEARCH ONLY MARKED BLOCK "
        defm    1,"3N",$20+14,"."
        defm    1,"2-T",0

        ld      a, 2
        call    MoveTo_0Ya

        ld      de, (eMem_LineBuffers)
        ld      hl, lbuf_Buffer3
        add     hl, de
        OZ      GN_Sop                          ; write string  to std. output
        ld      a, 4
        call    MoveTo_0Ya

        ld      de, (eMem_dix_254)
        ld      hl, $7D
        add     hl, de
        OZ      GN_Sop                          ; write string  to std. output
        ld      de, RplcUI_tbl
        jp      ExitList

;       ----

.ListDiary
        push    hl
        push    de
        push    bc
        call    sub_E14A

        jr      list_1


.List2
        push    hl
        push    de
        push    bc

.list_1
        call    InitWin4

        oz      OS_Pout
        defm    "LIST DIARY"
        defm    1,"2JN"
        defm    1,"2-R"
        defm    1,"3@",$20+17,$20+3
        defm    "LIST ON SCREEN "
        defm    1,"3N",$20+24,"."
        defm    1,"3@",$20+17,$20+4
        defm    "LIST ON PRINTER "
        defm    1,"3N",$20+23,"."
        defm    1,"3@",$20+17,$20+5
        defm    "LIST ONLY MARKED BLOCK "
        defm    1,"3N",$20+16,"."
        defm    1,"2-T",0

        ld      de, ListUI_tbl
        jp      ExitList

;       ----

.LoadDiary
        push    hl
        push    de
        push    bc
        call    sub_E14A

        jr      load_1


.Load2
        push    hl
        push    de
        push    bc

.load_1
        call    InitWin4

        oz      OS_Pout
        defm    "LOAD (APPEND) FILE INTO DIARY"
        defm    1,"2JN"
        defm    1,"2-R"
        defm    1,"3@",$20+0,$20+2
        defm    1,"3N",$20+28,"-"
        defm    " NAME OF FILE TO LOAD "
        defm    1,"3N",$20+28,"-"
        defm    1,"3@",$20+17,$20+5
        defm    "START LOADING DATA AT DIARY DATE "
        defm    1,"3N",$20+6,"."
        defm    1,"2-T",0

        ld      a, 3
        call    MoveTo_0Ya

        ld      de, (eIOBuf_242)
        ld      hl, iob_Filename
        add     hl, de
        OZ      GN_Sop                          ; write string  to std. output
        ld      de, LoadUI_tbl
        jp      ExitList

;       ----

.SaveDiary
        push    hl
        push    de
        push    bc
        call    sub_E14A

        jr      save_2


.Save2
        push    hl
        push    de
        push    bc

.save_2
        call    InitWin4

        oz      OS_Pout
        defm    "SAVE FILE FROM DIARY"
        defm    1,"2JN"
        defm    1,"2-R"
        defm    1,"3@",$20+0,$20+2
        defm    1,"3N",$20+28,"-"
        defm    " NAME OF FILE TO SAVE "
        defm    1,"3N",$20+28,"-"
        defm    1,"3@",$20+17,$20+5
        defm    "SAVE ONLY MARKED BLOCK "
        defm    1,"3N",$20+16,"."
        defm    1,"2-T",0

        ld      a, 3
        call    MoveTo_0Ya

        ld      de, (eIOBuf_242)
        ld      hl, iob_Filename
        add     hl, de
        OZ      GN_Sop                          ; write string  to std. output
        ld      de, SaveUI_tbl

.ExitList
        call    Show5EFlags

        call    ToggleCursor

        pop     bc
        pop     de
        pop     hl
        ret

;       ----

.sub_E14A
        call    InitWd

        call    ShowInsertMode

        jp      PrintDate

;       ----

.Show5EFlags
        push    hl
        push    bc
        ld      a, (de)
        ld      b, a
        inc     de
        inc     de
        inc     de

.loc_E15A
        ld      a, (de)
        call    sub_E269

        inc     de
        ld      a, (de)
        and     (ix+dix_ubFlags5E)
        call    PntYesNo

        inc     de
        djnz    loc_E15A

        pop     bc
        pop     hl
        ret

;       ----

.PntYesNo
        jr      z, pyn_1
        OZ      OS_Pout
        defm    "Yes",0
        ret
.pyn_1
        OZ      OS_Pout
        defm    "No ",0
        ret

;       ----

.DoUI
        push    hl
        push    bc
        ld      (ix+dix_ubTmp), 1

.ui_draw
        ld      a, (ix+dix_ubTmp)
        dec     a
        sla     a
        add     a, 3                            ; skip  N and Func
        ld      l, a
        ld      h, 0
        add     hl, de
        ld      a, (hl)
        ld      b, a                            ; ypos
        inc     hl
        ld      a, (hl)
        ld      c, a                            ; bit mask
        ld      a, b
        call    sub_E269

        ld      a, (ix+dix_ubFlags5E)
        and     c
        call    PntYesNo

        ld      a, b
        call    sub_E269


.ui_get
        OZ      OS_In                           ; read  a byte from std. input
        jr      c, ui_err

        cp      0
        jr      z, ui_get

        cp      $1B
        jr      z, ui_okx

        cp      $0D
        jr      z, ui_okx

        OZ      GN_Cls                          ; Classify a character
        jr      nc, ui_act

        and     $0DF                            ; upper
        jr      ui_act


.ui_err
        cp      RC_Quit                         ; Request application to quit *
        jr      z, ui_errx

        call    WrMailDate

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      nz, ui_draw

        push    de
        ld      hl, ui_back
        push    hl
        inc     de
        ld      a, (de)
        ld      l, a
        inc     de
        ld      a, (de)
        ld      h, a
        jp      (hl)


.ui_back
        pop     de
        jr      ui_draw


.ui_act
        cp      'Y'
        jr      z, ui_set

        cp      'N'
        jr      z, ui_clr

        cp      '-'
        jr      z, ui_down

        cp      '.'
        jr      z, ui_up

        cp      '?'
        jr      nz, ui_draw

        ld      a, (ix+dix_ubFlags5E)           ; toggle
        and     c
        jr      nz, ui_clr


.ui_set
        ld      a, (ix+dix_ubFlags5E)
        or      c
        jr      ui_1


.ui_clr
        ld      a, (ix+dix_ubFlags5E)
        cpl
        or      c
        cpl

.ui_1
        ld      (ix+dix_ubFlags5E), a
        jp      ui_draw


.ui_down
        ld      a, (de)
        cp      (ix+dix_ubTmp)
        jp      z, ui_draw

        inc     (ix+dix_ubTmp)
        jp      ui_draw


.ui_up
        ld      a, (ix+dix_ubTmp)
        cp      1
        jr      nz, ui_2

        ld      a, '.'
        jr      ui_okx                          ; exit  with A='.'


.ui_2
        dec     (ix+dix_ubTmp)
        jp      ui_draw


.ui_okx
        or      a
        jr      ui_x


.ui_errx
        scf

.ui_x
        pop     bc
        pop     hl
        ret

; IN: HL = ptr to error message
.ShowError
        call    PrntErrorPre
        OZ      GN_Sop                          ; write string to std. output

.loc_E23A
        call    PrntErrorPost
        set     DF5C_B_ERRORSHOWN, (ix+dix_ubFlags5C)   ;       local flag
        ret

.RemoveError
        bit     DF5C_B_ERRORSHOWN, (ix+dix_ubFlags5C)
        jr      z, locret_E257

        OZ      OS_Pout
        defm    1,"2I3"
        defm    1,"3@",$20+0,$20+5
        defm    1,"2C",$FD
        defm    1,"2I2",0

        res     DF5C_B_ERRORSHOWN, (ix+dix_ubFlags5C)
.locret_E257
        ret

;       ----

.InitWd
        OZ      OS_Pout
        defm    1,"7#2",$21,$20,$6F,$28,$81
        defm    1,"2C2"
        defm    1,"2-C"
        defm    1,"7#3",$71,$20,$2C,$28,$83
        defm    1,"2C3"
        defm    1,"2-C"
        defm    1,"3+RT"
        defm    1,"2JC"
        defm    " DIARY DATE "
        defm    1,"2-R"
        defm    1,"3@",$20+0,$20+7
        defm    "MODE"
        defm    1,"2-T"
        defm    1,"2JN"
        defm    1,"2I2",0

        res     DF5C_B_ERRORSHOWN, (ix+dix_ubFlags5C)
        ret

;       ----

.MoveTo_0_ypos
        ld      a, (ix+dix_ubCrsrYPos)

.MoveTo_0Ya
        OZ      OS_Pout
        defm    1,"3@",$20+0,0
        jr      disp_byte
.sub_E269
        OZ      OS_Pout
        defm    1,"3@",$20+57, 0
.disp_byte
        add     a, $20
        OZ      OS_Out                          ; write a byte  to std. output
        ret

;       ----

.ToggleCursor
        push    af
        OZ      OS_Pout
        defm    1,"C",0
        pop     af
        ret

;       ----

.MayPageWait
        push    af
        push    hl
        ld      a, 7
        cp      (ix+dix_ubTmp)
        jr      z, mpw_4

        ld      a, 8                            ; SR_PWT
        OZ      OS_Sr                           ; Save  & Restore
        jr      nc, mpw_3

        cp      RC_Draw                         ; Application pre-empted and screen corrupted
        jr      nz, mpw_3

        bit     DF5C_B_SRCHRPLC, (ix+dix_ubFlags5C)
        jr      z, mpw_1

        call    Search3

        jr      mpw_2


.mpw_1
        call    ListDiary

.mpw_2
        ld      hl, SearchListWd_txt
        OZ      GN_Sop                          ; write string  to std. output

.mpw_3
        ld      (ix+dix_ubTmp), 7

.mpw_4
        pop     hl
        pop     af
        ret

;       ----

.PrintList
        push    hl

.loc_E2AB
        ld      a, 0
        OZ      OS_Esc                          ; Examine special condition
        jr      c, loc_E2D5

        ld      a, (hl)
        cp      0
        jr      z, loc_E2D5

        bit     DF5E_B_MAKESEARCHLIST, (ix+dix_ubFlags5E)
        jr      z, loc_E2CA

        cp      10
        jr      nz, loc_E2C6

        dec     (ix+dix_ubTmp)
        call    z, MayPageWait
.loc_E2C6
        push    af
        OZ      OS_Out                          ; write a byte  to std. output
        pop     af

.loc_E2CA
        bit     DF5E_B_PRINTSEARCHLIST, (ix+dix_ubFlags5E)
        jr      z, loc_E2D2

        OZ      OS_Prt                          ; Send  character directly to printer filter
.loc_E2D2
        inc     hl
        jr      loc_E2AB

.loc_E2D5
        pop     hl
        ret

;       ----

.PrtFormFeed
        ld      a, 12
        OZ      OS_Prt                          ; Send  character directly to printer filter
        ret

;       ----

.PrntClearEOL
        oz      OS_Pout
        defm    1,"2C",$FD,0
        ret

;       ----

.PrntErrorPre
        oz      OS_Pout
        defm    1,"2I3"
        defm    1,"3@",$20+0,$20+5
        defm    1,"3+TR"
        defm    1,"2C",$FD
        defm    1,"2JC",0
        ret

;       ----

.PrntErrorPost
        oz      OS_Pout
        defm    1,"5-TRLB"
        defm    1,"2JN"
        defm    1,"2I2",0
        ret

;       ----

.PrntEndOfText
        OZ      OS_Pout
        defm    1,"3+RT"
        defm    " END OF TEXT "
        defm    1,"3-RT"
        defm    1,"2C",$FE,0
        ret

;       ----

.InitWin4
        OZ      OS_Pout
        defm    1,"7#4",$20+1,$20+0,$20+78,$20+8,$83
        defm    1,"2C4"
        defm    1,"2-C"
        defm    1,"3@",$20+0,$20+0
        defm    1,"3+TR"
        defm    1,"2C",$FD
        defm    1,"2JC",0
        ret

;       ----

.ErrHandler
        ret     z
        cp      RC_Quit
        jp      z, Quit
        cp      a
        ret

.CRLF_txt
        defm    $0D,$0A,0

.SearchListWd_txt
        defm    1,"7#5",$20+1,$20+1,$20+78,$20+7,$81
        defm    1,"2C5"
        defm    1,"2+S",0

.Name_txt
        defm    "NAME",0

.SearchUI_tbl
        defb    4
        defw    Search3
        defb    4,1                             ; ignore case,  search block, list, print list
        defb    5,2
        defb    6,$10
        defb    7,$20

.ListUI_tbl
        defb    3
        defw    ListDiary
        defb    3,$10                           ; screen, printer, block
        defb    4,$20
        defb    5,8

.RplcUI_tbl
        defb    3
        defw    Replace3
        defb    5,1                             ; ignore case,  confirm, block
        defb    6,$40
        defb    7,2

.LoadUI_tbl
        defb    1
        defw    LoadDiary
        defb    5,$80                           ; start at date

.SaveUI_tbl
        defb    1
        defw    SaveDiary
        defb    5,8                             ; block


.NoMem_txt
        defm    "No memory for date conversion",0

.MemoryLow_txt
        defm    "MEMORY LOW",7,0
.NoMatch_txt
        defm    "NO MATCH",7,0
.NoString_txt
        defm    "NO STRING",7,0
.NoRoom_txt
        defm    "NO ROOM",$7f,0
.NoMarker_txt
        defm    "NO MARKER",7,0
.NotMarked_TXT
        defm    "NOT MARKED",7,0
.DateRange_TXT
        defm    "DATE RANGE",7,0
.Overlaps_TXT
        defm    "OVERLAPS",7,0
.ReplaceYN_txt
        defm    "REPLACE Y/N",0
.Found_txt
        defm    "FOUND",0
.Free_txt
        ascii   "FREE",0
