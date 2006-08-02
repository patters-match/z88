; **************************************************************************************************
; Calculator popdown (Bank 3, addressed for segment 3).
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

        module  Calculator

        include "blink.def"
        include "director.def"
        include "error.def"
        include "fpp.def"
        include "stdio.def"

        org     $f300

defvars 0
{
        calc_ActiveCol          ds.b    1
        calc_ActiveRow          ds.b    1
        calc_PrevActCol         ds.b    1
        calc_PrecActRow         ds.b    1
        calc_NumBuffer          ds.b    18
        calc_BufferPos          ds.b    1
        calc_BufferPosH         ds.b    1
        calc_StatusLineLen      ds.b    1
        calc_CmdBuffer          ds.b    3
        calc_Operation          ds.b    1
        calc_Flags              ds.b    1
        calc_CvtActiveCol       ds.b    1
        calc_CvtActiveRow       ds.b    1
        calc_PrevCvtActCol      ds.b    1
        calc_PrevCvtActRow      ds.b    1
        calc_StrBuffer          ds.b    1
}

defvars $0fbf                                   ; !! should use named mem later
{
        Float1                  ds.b    5
        Float2                  ds.b    5
        Memories                ds.b    10*5
        varFix                  ds.b    1
}

;       Flags
defc    CF_B_Convert            = 1
defc    CF_B_Constant           = 2
defc    CF_B_3                  = 3
defc    CF_B_Error              = 4
defc    CF_B_Symbol             = 5
defc    CF_B_Command            = 6
defc    CF_B_HasNumBuf          = 7

defc    CF_Convert              = 2
defc    CF_Constant             = 4
defc    CF_3                    = 8
defc    CF_Error                = 16
defc    CF_Symbol               = 32
defc    CF_Command              = 64
defc    CF_HasNumBuf            = 128


;       CalcOp
defc    OP_ADD                  = 0
defc    OP_SUB                  = 1
defc    OP_MUL                  = 2
defc    OP_DIV                  = 3

;       CalcCmd
defc    CC_NONE                 = 0
defc    CC_STOM                 = 1
defc    CC_RCLM                 = 2
defc    CC_FIX                  = 3



.Calculator
        ld      iy, $1FAC
        ld      a, 5
        OZ      OS_Esc                          ; Examine special condition

        xor     a
        ld      hl, ErrorHandler
        OZ      OS_Erh                          ; install error handler

        ld      b, calc_StrBuffer
        push    iy
        pop     hl
        call    ZeroMem

        call    KPrint                          ; init calculator window
        defm    1,"7#5",$20+10,$20+0,$20+33,$20+8,$83
        defm    1,"2I5",0

        call    PrntChar_0C
        call    InitCalcWd

        ld      bc, 0                           ; !! do two loads to re-use ld c,0
.calc_1
        call    PrintCalcButton
        inc     c                               ; column
        ld      a, c
        cp      5
        jr      nz, calc_1
        ld      c, 0
        inc     b                               ; row
        ld      a, b
        cp      5
        jr      nz, calc_1

        call    KPrint                          ; init convert window
        defm    1,"7#4",$20+46,$20+0,$20+22,$20+8,$83
        defm    1,"2I4",0

        call    PrntChar_0C

        ld      a, 1
        ld      b, 0
        call    MoveXY_AB

        call    KPrint
        defm    1,"2JC"
        defm    1,"T"
        defm    "CONVERT"
        defm    1,"T"
        defm    1,"2JN"
        defm    1,$32,$58,$20
        defm    1,"R"
        defm    1,"U"
        defm    1,$32,$41,$36
        defm    1,"R"
        defm    1,"U",0

        ld      c, (iy+calc_CvtActiveCol)
        ld      b, (iy+calc_CvtActiveRow)
        ld      (iy+calc_PrevCvtActCol), c
        ld      (iy+calc_PrevCvtActRow), b

        ld      bc, 0                           ; !! do two loads to re-use ld c,0
.calc_2
        call    PrintConvButton
        inc     c                               ; column
        ld      a, c
        cp      2
        jr      nz, calc_2
        ld      c, 0
        inc     b                               ; row
        ld      a, b
        cp      7
        jr      nz, calc_2

        call    KPrint
        defm    1,"2I5",0

.Main
        call    PrintStatusRow

.main_1
        call    ReadKey
        jr      main_5

.main_2
        pop     de
        ld      c, 5
        ld      b, (iy+calc_ActiveRow)
        xor     a
        inc     b

.main_3
        dec     b
        jr      z, main_4
        add     a, c
        jr      main_3

.main_4
        add     a, (iy+calc_ActiveCol)
        ld      hl, Key2Button_tbl
        ld      e, a
        ld      d, 0
        add     hl, de
        ld      a, (hl)

.main_5
        call    ToUpper
        ld      hl, Key2Button_tbl
        ld      c, -1                           ; key #

.main_6
        ld      b, (hl)
        inc     b
        dec     b
        jr      z, main_1                       ; no more keys
        inc     c
        cp      (hl)
        inc     hl
        jr      nz, main_6

        push    bc
        push    af

        ld      a, c                            ; key #
        ld      b, -1
.main_7
        inc     b
        sub     5
        jr      nc, main_7
        add     a, 5
        ld      c, a                            ; button column
        ld      a, b                            ; button row

        cp      5
        jr      nc, loc_F3F6

        ld      (iy+calc_ActiveRow), b
        ld      (iy+calc_ActiveCol), c
.loc_F3F6
        pop     af
        exx
        pop     bc
        ld      ix, KeyTable
        call    IndirectJump
        call    UpdButton
        call    sub_FBA0
        jr      Main

.Key2Button_tbl
        defm    "C",$7f,"SR+","789U*","456Y-","123I/","0.%F="
        defm    "PTXMD\E"
        defm    $FF,$FE,$FC,$FD,$0D,$1B,$12,0

.KeyTable
        defw    key_Clr, key_Del, key_StoM, key_RclM, key_Add
        defw    key_Num, key_Num, key_Num, key_Unit, key_Mul
        defw    key_Num, key_Num, key_Num, key_Y, key_Sub
        defw    key_Num, key_Num, key_Num, key_Sign, key_Div
        defw    key_Num, key_DotE, key_Perc, key_Fix, key_Equ

        defw    key_P, key_TX, key_TX, key_M, key_D, key_D, key_DotE
        defw    key_Up, key_Down, key_Left, key_Right, main_2, key_Esc, key_DiamR

.key_Num
        call    ClrError
        bit     CF_B_Command, (iy+calc_Flags)
        jp      z, PutNum

        sub     '0'
        ld      de, calc_CmdBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      c, (hl)
        dec     c
        push    bc
        ex      de, hl
        inc     de
        exx
        pop     bc
        ld      ix, CmdTable
        jp      IndirectJump

.DoStoM
        push    af
        push    de
        call    ldFH_F1NumBuf
        call    stFReg1_Float1
        pop     de
        pop     af
        ld      b, a
        ld      a, (de)
        or      a
        jr      z, stom_1
        sub     4

.stom_1
        push    af
        ld      a, b
        call    GetMemPtrA
        pop     af
        push    ix
        push    ix
        pop     de
        exx
        ld      c, a
        ld      ix, StoM_tbl
        jp      IndirectJump

.StoM_tbl
        defw    StoM_plain
        defw    StoM_add
        defw    StoM_sub
        defw    StoM_mul
        defw    StoM_div

.StoM_add
        call    RclM_FReg2
        call    FpAdd
        jr      StoM_plain
.StoM_sub
        call    RclM_FReg2
        call    FpSub
        jr      StoM_plain
.StoM_mul
        call    RclM_FReg2
        call    FpMul
        jr      StoM_plain
.StoM_div
        call    RclM_FReg2
        call    FpDiv
.StoM_plain
        pop     ix
        call    StoM_FReg1

;       ----

.ClearCommand
        res     CF_B_Command, (iy+calc_Flags)
        ld      de, calc_CmdBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      (hl), 0
        ret

.RclM
        res     CF_B_HasNumBuf, (iy+calc_Flags)
        call    GetMemPtrA
        call    RclM_FReg1
        call    stFReg1_Float1
        jr      ClearCommand

.Fix
        scf
        rla
        ld      (varFix), a
        jr      ClearCommand

;       ----

.key_DotE
        bit     CF_B_HasNumBuf, (iy+calc_Flags)
        jr      z, PutNum

        ld      de, calc_PrecActRow
        push    iy
        pop     hl
        add     hl, de
.dote_1
        inc     hl
        ld      b, (hl)
        cp      b
        ret     z                               ; '.' or 'E' already entered
        inc     b
        dec     b
        jr      nz, dote_1

;       ----

.PutNum
        bit     CF_B_Command, (iy+calc_Flags)
        ret     nz
        ld      de, calc_NumBuffer
        push    iy
        pop     hl
        add     hl, de
        bit     CF_B_HasNumBuf, (iy+calc_Flags)
        jr      nz, putn_1
        set     CF_B_HasNumBuf, (iy+calc_Flags)
        ld      (iy+calc_BufferPos), l
        ld      (iy+calc_BufferPosH), h
        ld      (hl), 0
.putn_1
        ld      e, a
        cp      '.'
        jr      z, loc_F564
        ld      a, (hl)
        cp      '0'
        jr      nz, loc_F564
        inc     hl
        ld      a, (hl)
        cp      '.'
        jr      z, loc_F564
        ld      a, (iy+calc_BufferPos)
        or      a
        jr      nz, loc_F561
        dec     (iy+calc_BufferPosH)

.loc_F561
        dec     (iy+calc_BufferPos)

.loc_F564
        ld      a, e
        call    NumBufferFull
        ret     nc
        inc     (iy+calc_BufferPos)
        jr      nz, loc_F571
        inc     (iy+calc_BufferPosH)

.loc_F571
        ld      (hl), a
        inc     hl
        ld      (hl), 0
        ret

;       ----

.key_Clr
        call    ClearCommand
        res     CF_B_HasNumBuf, (iy+calc_Flags) ; !! and these away
        res     CF_B_Symbol, (iy+calc_Flags)
        res     CF_B_Error, (iy+calc_Flags)
        res     CF_B_3, (iy+calc_Flags)
        res     CF_B_Constant, (iy+calc_Flags)

;       ----

;       clear X & Y

.ZeroNums
        ld      b, 10                           ; 2*fp
        ld      hl, Float1
        jr      ZeroMem

;       <>R - clear all memories

.key_DiamR
        call    PrntChar_07
        call    ZeroNums
        ld      b, 51                           ; 10*fp+fix
        ld      hl, Memories

.ZeroMem
        xor     a
.zm_1
        ld      (hl), a
        inc     hl
        djnz    zm_1
        ret

;       ----

.ClrError
        bit     CF_B_Error, (iy+calc_Flags)     ; !! use and
        ret     z
        res     CF_B_Error, (iy+calc_Flags)
        res     CF_B_HasNumBuf, (iy+calc_Flags)
        res     CF_B_Symbol, (iy+calc_Flags)
        ret

.key_RclM
        ld      a, CC_RCLM
        jr      PutCmd

.key_Fix
        ld      a, CC_FIX
        jr      PutCmd

.key_StoM
        ld      a, CC_STOM

.PutCmd
        bit     CF_B_Error, (iy+calc_Flags)
        ret     nz
        bit     CF_B_Command, (iy+calc_Flags)
        ret     nz
        set     CF_B_Command, (iy+calc_Flags)

;       ----

.StoreCmdChar
        ld      de, calc_CmdBuffer
        push    iy
        pop     hl
        add     hl, de
        dec     hl
.stc_1
        inc     hl
        ld      c, (hl)
        inc     c
        dec     c
        jr      nz, stc_1
        ld      (hl), a
        inc     hl
        ld      (hl), 0
        ret

.key_Unit
        bit     CF_B_Error, (iy+calc_Flags)
        ret     nz
        bit     CF_B_Command, (iy+calc_Flags)
        ret     nz
        ld      a, 4
        call    StoreCmdChar
        call    sub_FBA0
        set     CF_B_Convert, (iy+calc_Flags)
        call    UpdButton
        call    KPrint
        defm    1,"2I4",0

.UnitLoop
        call    UpdConvButton
        call    ReadKey
        call    ToUpper
        ld      hl, UnitKey_tbl
        ld      c, 0

.ul_1
        cp      (hl)
        jr      z, ul_2
        ld      b, (hl)
        inc     b
        dec     b
        jr      z, UnitLoop                     ; no more keys
        inc     c
        inc     hl
        jr      ul_1

.ul_2
        push    af
        ld      a, c
        exx
        ld      c, a
        pop     af
        ld      ix, UnitCmd_tbl
        call    IndirectJump
        jr      nc, UnitLoop
        res     CF_B_Convert, (iy+calc_Flags)
        call    UpdConvButton

        call    KPrint
        defm    1,"2I5",0

        call    UpdButton
        jp      ClearCommand

.UnitKey_tbl
        defm    $43,$7F,$FC,$FD,$FF,$FE,$3D,$0D,$1B
        defm    "0123456789.",0

.UnitCmd_tbl
        defw    ckey_Clr, ckey_Del
        defw    ckey_Left, ckey_Right, ckey_Up, ckey_Down
        defw    ckey_EquEnter, ckey_EquEnter, ckey_Esc
        defw    ckey_Num, ckey_Num, ckey_Num, ckey_Num, ckey_Num
        defw    ckey_Num, ckey_Num, ckey_Num, ckey_Num, ckey_Num
        defw    ckey_Dot

.ckey_Num
        call    PutNum
        jr      ckey_numdot

.ckey_Dot
        call    key_DotE

.ckey_numdot
        call    KPrint
        defm    1,"2I5",0
        call    PrintStatusRow
        call    KPrint
        defm    1,"2I4",0
        ret

.ckey_Clr
        call    key_Clr
.ckey_Del
        scf
        ret

;       ----

.ckey_Up
        call    cDecRow
        ret     nz

.cDecCol
        ld      a, (iy+calc_CvtActiveCol)
        or      a
        jr      z, cdc_1
        dec     (iy+calc_CvtActiveCol)
        or      a
        ret
.cdc_1
        ld      (iy+calc_CvtActiveCol), 1
        ret

.ckey_Left
        call    cDecCol
        ret     nz

.cDecRow
        ld      a, (iy+calc_CvtActiveRow)
        or      a
        jr      z, cdr_1
        dec     (iy+calc_CvtActiveRow)
        or      a
        ret
.cdr_1
        ld      (iy+calc_CvtActiveRow), 6
        ret

.ckey_Right
        call    cIncCol
        ret     nz

.cIncRow
        ld      a, (iy+calc_CvtActiveRow)
        cp      6
        jr      nc, cir_1
        inc     (iy+calc_CvtActiveRow)
        inc     a
        or      a
        ret
.cir_1
        xor     a
        ld      (iy+calc_CvtActiveRow), a
        ret

.ckey_Down
        call    cIncRow
        ret     nz

.cIncCol
        ld      a, (iy+calc_CvtActiveCol)
        cp      1
        jr      nc, cic_1
        inc     (iy+calc_CvtActiveCol)
        inc     a
        or      a
        ret
.cic_1
        xor     a
        ld      (iy+calc_CvtActiveCol), a
        ret

;       ----

.ckey_EquEnter
        call    ldFH_F1NumBuf
        call    stFReg1_Float1
        ld      c, (iy+calc_CvtActiveRow)
        call    GetNumC
        call    FpVal
        ld      a, (iy+calc_CvtActiveCol)
        exx
        ld      c, (iy+calc_CvtActiveRow)
        ld      ix, ConvertCmd_tbl
        jp      IndirectJump

.ConvertCmd_tbl
        defw    loc_F71D, loc_F71D, loc_F72C, loc_F71D
        defw    loc_F71D, loc_F71D, loc_F73A

.loc_F71D
        or      a
        call    nz, sub_F76F
        call    ldFReg2_Float1
        call    FpMul

.loc_F727
        call    stFReg1_Float1
        scf
        ret

.loc_F72C
        call    OnePerFloat
        call    ldFReg2_Float1
        call    FpMul
        call    OnePerFloat
        jr      loc_F727

.loc_F73A
        or      a
        push    af
        call    nz, sub_F76F
        pop     af
        call    ldFReg2_Float1
        push    af
        jr      z, loc_F761
        exx
        push    hl
        exx
        push    hl
        ld      a, c
        push    af
        call    ExFReg1_FReg2
        call    ldFReg2_32
        call    ExFReg1_FReg2
        call    FpSub
        call    ExFReg1_FReg2
        pop     af
        ld      c, a
        pop     hl
        exx
        pop     hl
        exx

.loc_F761
        call    FpMul
        call    ldFReg2_32
        pop     af
        call    z, FpAdd
        jr      loc_F727
.ckey_Esc
        scf
        ret
;       ----
.sub_F76F
        call    FpTst
        ret     z
        jp      OnePerFloat
; End of function sub_F76F
;       ----
.GetNumC
        ld      hl, ConvNumTable                ; ".219978442"
        inc     c
.gnc_1
        dec     c
        ret     z                               ; return string in (HL)
.gnc_2
        ld      a, (hl)                         ; skip string
        inc     hl
        or      a
        jr      z, gnc_1
        jr      gnc_2

;       ----

.UpdConvButton
        ld      c, (iy+calc_PrevCvtActCol)
        ld      b, (iy+calc_PrevCvtActRow)
        call    PrintConvButton
        ld      c, (iy+calc_CvtActiveCol)
        ld      b, (iy+calc_CvtActiveRow)
        call    PrintConvButton
        ld      (iy+calc_PrevCvtActCol), c
        ld      (iy+calc_PrevCvtActRow), b
        ret

;       ----

.PrintConvButton
        push    bc
        inc     b
        ld      a, c
        add     a, a
        add     a, a
        ld      e, a
        add     a, a
        add     a, e
        inc     a
        call    MoveXY_AB
        pop     bc
        push    bc

        call    KPrint
        defm    1,"T",0

        ld      a, (iy+calc_Flags)
        xor     CF_CONVERT
        bit     CF_B_Convert, a
        jr      nz, pcb_1
        ld      a, b
        cp      (iy+calc_CvtActiveRow)
        jr      nz, pcb_1
        ld      a, c
        cp      (iy+calc_CvtActiveCol)
        call    z, PrntReverse
.pcb_1
        pop     bc
        push    bc
        push    af
        ld      a, b
        add     a, a
        add     a, c
        add     a, a
        add     a, a
        add     a, a
        ld      c, a                            ; 16*B+8*C
        ld      b, 0
        ld      hl, CvtStrings_tbl
        add     hl, bc
        ld      b, 8
.pcb_2
        ld      a, (hl)
        inc     hl
        OZ      OS_Out                          ; write a byte to std. output
        djnz    pcb_2
        pop     af
        call    z, PrntReverse                  ; active
        pop     bc

        call    KPrint
        defm    1,"T",0

        inc     b
        ld      a, 10
        call    MoveXY_AB
        dec     b
        ld      a, b
        cp      (iy+calc_CvtActiveRow)
        ld      a, 2
        jp      nz, PrntASpaces
        ld      a, (iy+calc_CvtActiveCol)
        or      a
        jr      z, loc_F806

        call    KPrint
        defm    "->",0

        ret
.loc_F806
        call    KPrint
        defm    "<-",0

        ret
; End of function PrintConvButton
.CvtStrings_tbl
        defm    "Gallons "                      ; !! shorten these
        defm    "Litres  "                      ; !! 54 bytes to gain
        defm    "Miles   "
        defm    "km      "
        defm    "MPG     "
        defm    "l/100km "
        defm    "Acres   "
        defm    "Hectares"
        defm    "lb      "
        defm    "kg      "
        defm    "oz      "
        defm    "g       "
        defm    "DegF    "
        defm    "DegC    "

.ConvNumTable
        defm ".219978442",0                     ; !! change these to fp values
.a_621371192
        defm ".621371192",0                     ; !! 36 bytes to gain
.a282_4691303
        defm "282.4691303",0
.a2_47104395
        defm "2.47104395",0
.a2_204622345
        defm "2.204622345",0
.a_03527399
        defm ".03527399",0
.a1_8
        defm "1.8",0

.key_Del
        call    ClrError
        bit     CF_B_Command, (iy+calc_Flags)
        jp      nz, ClearCommand ; cancel command
        bit     CF_B_HasNumBuf, (iy+calc_Flags)
        jr      z, loc_F8F5                     ; no number, display zero
        ld      l, (iy+calc_BufferPos)
        ld      h, (iy+calc_BufferPosH)
        dec     hl
        ld      (hl), 0
        ld      (iy+calc_BufferPos), l
        ld      (iy+calc_BufferPosH), h
        push    hl
        ld      de, calc_NumBuffer
        push    iy
        pop     hl
        add     hl, de
        pop     de
        or      a
        sbc     hl, de
        ret     nz                              ; buffer not empty
        res     CF_B_HasNumBuf, (iy+calc_Flags)
        ret
.loc_F8F5
        call    FpZero
        jp      stFReg1_Float1
.key_Perc
        bit     CF_B_Command, (iy+calc_Flags)
        ret     nz
        bit     CF_B_Symbol, (iy+calc_Flags)
        ret     z
        call    ldFH_F1NumBuf
        call    stFReg1_Float1
        call    ldFReg2_Float2
        exx
        ld      c, (iy+calc_Operation)
        ld      ix, PercCmd_tbl
        jp      IndirectJump

.PercCmd_tbl
        defw    PercAdd
        defw    PercSub
        defw    PercMul
        defw    PercDiv

.PercAdd
        call    ldFReg2_100
        FPP     FP_DIV
        call    ExFReg1_FReg2
        call    FpOne
        FPP     FP_SUB
        call    ldFReg2_Float2
        jr      loc_F942

.PercSub
        call    FpSub
        call    ldFReg2_100
        call    FpMul
        call    ldFReg2_Float1
        call    ExFReg1_FReg2
.loc_F942
        call    FpDiv
        jr      loc_F963
.PercMul
        set     CF_B_3, (iy+calc_Flags)
        call    FpMul
        call    ldFReg2_100
        call    ExFReg1_FReg2
        call    FpDiv
        jp      stFReg1_Float1
.PercDiv
        call    FpDiv
        call    ldFReg2_100
        call    FpMul
.loc_F963
        call    stFReg1_Float1
        res     CF_B_Symbol, (iy+calc_Flags)
        res     CF_B_Constant, (iy+calc_Flags)
        call    FpZero
        call    stFReg1_Float2
        ret
.key_P
        ld      (iy+calc_ActiveRow), 0
        ld      (iy+calc_ActiveCol), 4
.key_Add
        ld      c, OP_ADD
        jr      loc_F9AB
.key_M
        ld      (iy+calc_ActiveRow), 2
        ld      (iy+calc_ActiveCol), 4
.key_Sub
        ld      c, OP_SUB
        jr      loc_F9AB
.key_TX
        ld      (iy+calc_ActiveRow), 1
        ld      (iy+calc_ActiveCol), 4
.key_Mul
        res     CF_B_3, (iy+calc_Flags)
        ld      c, OP_MUL
        jr      loc_F9AB
.key_D
        ld      (iy+calc_ActiveRow), 3
        ld      (iy+calc_ActiveCol), 4
.key_Div
        res     CF_B_3, (iy+calc_Flags)
        ld      c, OP_DIV
.loc_F9AB
        bit     CF_B_Command, (iy+calc_Flags)
        jr      nz, loc_F9F6
        bit     CF_B_3, (iy+calc_Flags)
        jr      nz, loc_FA07
        bit     CF_B_HasNumBuf, (iy+calc_Flags)
        jr      z, loc_F9C6
        bit     CF_B_Symbol, (iy+calc_Flags)
        push    bc
        call    nz, sub_FA1A
        pop     bc
.loc_F9C6
        ld      b, (iy+calc_Operation)
        push    bc
        ld      (iy+calc_Operation), c
        call    ldFH_F1NumBuf
        call    stFReg1_Float1
        call    stFReg1_Float2
        pop     bc
        bit     CF_B_Symbol, (iy+calc_Flags)
        set     CF_B_Symbol, (iy+calc_Flags)
        res     CF_B_3, (iy+calc_Flags)
        ret     z
        ld      a, b
        cp      c
        jr      nz, locret_F9F5
        bit     CF_B_Constant, (iy+calc_Flags)
        set     CF_B_Constant, (iy+calc_Flags)
        ret     z
        res     CF_B_Constant, (iy+calc_Flags)
.locret_F9F5
        ret
.loc_F9F6
        ld      de, calc_CmdBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      a, (hl)
        cp      1
        ret     nz
        ld      a, c
        add     a, 5
        jp      StoreCmdChar
.loc_FA07
        ld      (iy+calc_Operation), c
        jr      sub_FA1A
.key_Equ
        res     CF_B_3, (iy+calc_Flags)
        bit     CF_B_Command, (iy+calc_Flags)
        ret     nz
        bit     CF_B_Symbol, (iy+calc_Flags)
        ret     z
;       ----
.sub_FA1A
        call    ldFH_F1NumBuf
        call    ldFReg2_Float2
        exx
        ld      c, (iy+calc_Operation)
        ld      ix, OpCmd_tbl
        call    IndirectJump
        call    stFReg1_Float1
        res     CF_B_3, (iy+calc_Flags)
        bit     CF_B_Constant, (iy+calc_Flags)
        ret     nz
        res     CF_B_Symbol, (iy+calc_Flags)
        call    FpZero
        jp      stFReg1_Float2
; End of function sub_FA1A

.OpCmd_tbl
        defw FpAdd
        defw FpSub
        defw FpMul
        defw FpDiv
.key_Y
        bit     CF_B_Command, (iy+calc_Flags)
        ret     nz
        call    ldFH_F1NumBuf
        call    stFReg1_Float1
        call    ldFReg1_Float2
        call    ldFReg2_Float1
        call    stFReg1_Float1
        jp      stFReg2_Float2
;       ----
.ldFH_F1NumBuf
        call    ldFReg1_Float1
        bit     CF_B_HasNumBuf, (iy+calc_Flags)
        ret     z
        ld      de, calc_NumBuffer
        push    iy
        pop     hl
        add     hl, de
        call    FpVal
        res     CF_B_HasNumBuf, (iy+calc_Flags)
        ret
; End of function ldFH_F1NumBuf
.key_Sign
        bit     CF_B_Command, (iy+calc_Flags)
        ret     nz
        bit     CF_B_HasNumBuf, (iy+calc_Flags)
        jr      z, sgn_8
        ld      de, calc_NumBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      e, l
        ld      d, h
        dec     de
.sgn_1
        inc     de
        ld      a, (de)
        cp      'E'
        jr      z, sgn_3
        or      a
        jr      nz, sgn_1
        ld      a, (hl)
        cp      '-'
        jr      z, sgn_6
        call    NumBufferFull
        ret     nc
        push    hl
        ld      de, calc_NumBuffer
        push    iy
        pop     hl
        add     hl, de
        ex      de, hl
        pop     hl
        inc     hl
.sgn_2
        dec     hl
        ld      a, (hl)
        inc     hl
        ld      (hl), a
        dec     hl
        push    hl
        or      a
        sbc     hl, de
        pop     hl
        jr      nz, sgn_2
        ld      (hl), '-'
        inc     (iy+calc_BufferPos)
        ret     nz
        inc     (iy+calc_BufferPosH)
        ret
.sgn_3
        inc     de
        ld      l, e
        ld      h, d
        ld      a, (hl)
        cp      $2D
        jr      z, sgn_6
        dec     hl
        push    hl
        push    de
        call    NumBufferFull
        pop     de
        pop     hl
        ret     nc
.sgn_4
        ld      a, (hl)
        inc     hl
        or      a
        jr      nz, sgn_4
        jr      sgn_2
.sgn_5
        inc     hl
.sgn_6
        inc     hl
        ld      a, (hl)
        dec     hl
        ld      (hl), a
        or      a
        jr      nz, sgn_5
        ld      a, (iy+calc_BufferPos)
        or      a
        jr      nz, sgn_7
        dec     (iy+calc_BufferPosH)
.sgn_7
        dec     (iy+calc_BufferPos)
        push    hl
        ld      de, calc_NumBuffer
        push    iy
        pop     hl
        add     hl, de
        ex      de, hl
        pop     hl
        or      a
        sbc     hl, de
        ret     nz
        res     CF_B_HasNumBuf, (iy+calc_Flags)
        ret
.sgn_8
        call    ldFReg1_Float1
        call    NegateFReg1
        jp      stFReg1_Float1
;       ----
.NumBufferFull
        ld      de, calc_NumBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      e, (iy+calc_BufferPos)
        ld      d, (iy+calc_BufferPosH)
        ex      de, hl
        push    hl
        or      a
        sbc     hl, de
        ld      c, a
        ld      a, l
        cp      17
        ld      a, c
        pop     hl
        ret
; End of function NumBufferFull
.key_Left
        call    DecCol
        ret     nz
;       ----
.DecRow
        ld      a, (iy+calc_ActiveRow)
        or      a
        jr      z, dr_1
        dec     (iy+calc_ActiveRow)
        or      a
        ret
.dr_1
        ld      (iy+calc_ActiveRow), 4
        ret
; End of function DecRow
.key_Up
        call    DecRow
        ret     nz
;       ----
.DecCol
        ld      a, (iy+calc_ActiveCol)
        or      a
        jr      z, dc_1
        dec     (iy+calc_ActiveCol)
        or      a
        ret
.dc_1
        ld      (iy+0), 4
        ret
; End of function DecCol
.key_Right
        call    IncCol
        ret     c
;       ----
.IncRow
        ld      a, (iy+calc_ActiveRow)
        cp      4
        jr      nc, ir_1
        inc     (iy+calc_ActiveRow)
        ret
.ir_1
        ld      (iy+calc_ActiveRow), 0
        ret
; End of function IncRow
.key_Down
        call    IncRow
        ret     c
;       ----
.IncCol
        ld      a, (iy+calc_ActiveCol)
        cp      4
        jr      nc, ic_1
        inc     (iy+calc_ActiveCol)
        ret
.ic_1
        ld      (iy+calc_ActiveCol), 0
        ret
; End of function IncCol
.key_Esc
        bit     CF_B_Command, (iy+calc_Flags)
        jp      nz, ClearCommand
.Exit
        xor     a
        OZ      OS_Bye
.loc_FB7A
        jr      loc_FB7A

;       ----

.GetMemPtrA
        push    de
        ld      ix, Memories
        ld      e, a
        add     a, a
        add     a, a
        add     a, e
        ld      e, a                            ; 5*E
        ld      d, 0
        add     ix, de
        pop     de
        ret

;       ----
.IndirectJump
        sla     c
        ld      b, 0
        add     ix, bc
        ld      c, (ix+0)
        ld      b, (ix+1)
        push    bc
        pop     ix
        exx
        push    de
        ex      (sp), ix
        ret

;       ----
.sub_FBA0
        ld      a, 2
        ld      b, 2
        call    MoveXY_AB
        ld      c, 0
        bit     CF_B_Command, (iy+calc_Flags)
        jr      z, loc_FBE0
        call    KPrint
        defm    1,"T",0
        ld      de, calc_CmdBuffer
        push    iy
        pop     hl
        add     hl, de
.loc_FBBC
        ld      a, (hl)
        or      a
        jr      z, loc_FBD5
        dec     a
        inc     hl
        call    GetCmdNameA
.loc_FBC5
        ld      a, (de)
        or      a
        jr      z, loc_FBCF
        OZ      OS_Out                          ; write a byte to std. output
        inc     de
        inc     c
        jr      loc_FBC5
.loc_FBCF
        call    PrntSpace
        inc     c
        jr      loc_FBBC
.loc_FBD5
        ld      a, '?'
        OZ      OS_Out                          ; write a byte to std. output
        inc     c
        call    KPrint
        defm    1,"T",0
.loc_FBE0
        ld      a, (iy+calc_StatusLineLen)
        sub     c
        call    nc, PrntASpaces
        ld      (iy+calc_StatusLineLen), c
        ret

;       ----

.GetCmdNameA
        push    bc
        ld      c, a
        ld      de, aStom                       ; "StoM"
        inc     c
.gcn_1
        dec     c
        jr      z, gcn_3
.gcn_2
        ld      a, (de)                         ; skip string
        inc     de
        or      a
        jr      nz, gcn_2
        jr      gcn_1
.gcn_3
        pop     bc
        ret

.CmdTable
        defw DoStoM, RclM, Fix

.aStom
        defm "StoM",0
        defm "RclM",0
        defm "Fix",0
        defm "Unit",0
        defm "+",0
        defm "-",0
        defm "*",0
        defm "/",0
;       ----
.PrintStatusRow
        ld      a, 8
        ld      b, 1
        call    MoveXY_AB
        bit     CF_B_Error, (iy+calc_Flags)
        jr      nz, loc_FC3C
        ld      de, 4
        bit     CF_B_HasNumBuf, (iy+calc_Flags)
        jr      nz, loc_FC4F
        call    ldFReg1_Float1
        call    sub_FEBC
        jr      loc_FC4C
.loc_FC3C
        ld      de, calc_StrBuffer
        push    iy
        pop     hl
        add     hl, de
        ld      de, aError
        ex      de, hl
        ld      bc, 6
        ldir
.loc_FC4C
        ld      de, calc_StrBuffer
.loc_FC4F
        push    iy
        pop     hl
        add     hl, de
        push    hl
        ld      b, -1                           ; strlen
.loc_FC56
        inc     b
        ld      a, (hl)
        inc     hl
        or      a
        jr      nz, loc_FC56
        pop     hl
        ld      a, 17
        sub     b
        call    PrntASpaces                     ; pad left
.loc_FC63
        ld      a, (hl)
        or      a
        jr      z, loc_FC6C
        OZ      OS_Out
        inc     hl
        jr      loc_FC63
.loc_FC6C
        ld      a, 28
        ld      b, 1
        call    MoveXY_AB
        ld      a, ' '
        bit     CF_B_Symbol, (iy+calc_Flags)
        jr      z, loc_FC85
        ld      hl, Symbol_tbl                  ; "+-x/"
        ld      c, (iy+calc_Operation)
        ld      b, 0
        add     hl, bc
        ld      a, (hl)
.loc_FC85
        OZ      OS_Out                          ; write a byte to std. output
        call    PrntSpace
        bit     CF_B_Constant, (iy+calc_Flags)
        jp      z, PrntSpace

        call    KPrint
        defm    1,"T","K",1,"T",0

        ret

;       ----

.Symbol_tbl
        defm "+-x/"
.aError
        defm "Error",0

;       ----

.InitCalcWd
        call    KPrint
        defm    1,"2JC"
        defm    1,"T"
        defm    "CALCULATOR"
        defm    1,"T"
        defm    1,"2JN"
        defm    1,"2X",$20+0
        defm    1,"R"
        defm    1,"U"
        defm    1,"2A",$20+33
        defm    1,"R"
        defm    1,"U"
        defb 0

        ld      b, 1
        ld      a, 6
        call    MoveXY_AB
        call    KPrint
        defb    0
        call    PrntVBar
        ld      a, 26
        call    MoveXY_AB
        call    PrntVBar
        call    KPrint
        defb    0
        ret

;       ----

.PrntVBar
        call    KPrint
        defm    1,$7C,0
        ret

;       ----

.UpdButton
        ld      c, (iy+calc_PrevActCol)
        ld      b, (iy+calc_PrecActRow)
        call    PrintCalcButton
        ld      c, (iy+calc_ActiveCol)
        ld      b, (iy+calc_ActiveRow)
        call    PrintCalcButton
        ld      (iy+calc_PrevActCol), c
        ld      (iy+calc_PrecActRow), b
        ret

;       ----

.PrintCalcButton
        push    bc
        inc     b
        inc     b
        inc     b                               ; B+3
        ld      a, c
        add     a, a
        ld      c, a
        add     a, a
        add     a, c
        add     a, 2                            ; 6*C+2
        call    MoveXY_AB
        pop     bc
        push    bc
        ld      a, c
        cp      4                               ; last column
        call    nz, PrntTiny
        bit     CF_B_Convert, (iy+calc_Flags)
        jr      nz, loc_FD33
        ld      a, b
        cp      (iy+calc_ActiveRow)
        jr      nz, loc_FD33
        ld      a, c
        cp      (iy+calc_ActiveCol)
        call    z, PrntReverse
.loc_FD33
        pop     bc
        push    bc
        push    af
        jr      z, loc_FD3E                     ; active?
        ld      a, b
        cp      4                               ; last row?
        call    nz, PrntUnderline
.loc_FD3E
        ld      a, b
        add     a, a
        add     a, a
        add     a, b                            ; 5*B
        add     a, c
        ld      c, a                            ; 5*B+C
        add     a, a
        add     a, a
        add     a, c
        ld      c, a                            ; 25*B+5*C
        ld      b, 0
        ld      hl, ButtonTxt_tbl
        add     hl, bc
        ld      b, 5
.loc_FD50
        ld      a, (hl)
        inc     hl
        OZ      OS_Out                          ; write a byte to std. output
        djnz    loc_FD50
        pop     af
        pop     bc
        call    z, PrntReverse                  ; active
        ld      a, b
        cp      4
        call    nz, PrntUnderlineOn             ; not last row
        ld      a, c
        cp      4
        push    af
        call    nz, PrntVBar                    ; not last col
        pop     af
        call    nz, PrntTiny                    ; not last col
        call    KPrint
        defm    1,"2-U",0
        ret

;       ----

.PrntUnderlineOn
        call    KPrint
        defm    1,"2+U",0
        ret

;       ----

.PrntUnderline
        call    KPrint
        defm    1,"U",0
        ret

;       ----

.PrntTiny
        call    KPrint
        defm    1,"T",0
        ret

;       ----

.ButtonTxt_tbl
        defm    "Clear"," DEL ","StoM ","RclM ","  +  " ; !! shorten
        defm    "  7  ","  8  ","  9  ","Unit ","  x  " ; !! 41 bytes from trailing spaces
        defm    "  4  ","  5  ","  6  ","Y<>x ","  -  "
        defm    "  1  ","  2  ","  3  ","sIgn ","  /  "
        defm    "  0  ","  .  ","  %  "," Fix ","  =  "
;       ----

.ldFReg1_Float1
        exx
        ld      hl, (Float1)
        exx
        ld      hl, (Float1+2)
        ld      a, (Float1+4)
        ld      c, a
        ret

;       ----

.ldFReg2_Float1
        exx
        ld      de, (Float1)
        exx
        ld      de, (Float1+2)
        ld      a, (Float1+4)
        ld      b, a
        ret

;       ----
.ldFReg1_Float2
        exx
        ld      hl, (Float2)
        exx
        ld      hl, (Float2+2)
        ld      a, (Float2+4)
        ld      c, a
        ret

;       ----

.ldFReg2_Float2
        exx
        ld      de, (Float2)
        exx
        ld      de, (Float2+2)
        ld      a, (Float2+4)
        ld      b, a
        ret

;       ----

.stFReg1_Float1
        exx
        ld      (Float1), hl
        exx
        ld      (Float1+2), hl
        ld      a, c
        ld      (Float1+4), a
        ret

;       ----

.stFReg1_Float2
        exx
        ld      (Float2), hl
        exx
        ld      (Float2+2), hl
        ld      a, c
        ld      (Float2+4), a
        ret

;       ----

.stFReg2_Float2
        exx
        ld      (Float2), de
        exx
        ld      (Float2+2), de
        ld      a, b
        ld      (Float2+4), a
        ret

;       ----

.RclM_FReg1
        exx
        ld      l, (ix+0)
        ld      h, (ix+1)
        exx
        ld      l, (ix+2)
        ld      h, (ix+3)
        ld      c, (ix+4)
        ret

;       ----

.StoM_FReg1
        exx
        ld      (ix+0), l
        ld      (ix+1), h
        exx
        ld      (ix+2), l
        ld      (ix+3), h
        ld      (ix+4), c
        ret

;       ----

.RclM_FReg2
        exx
        ld      e, (ix+0)
        ld      d, (ix+1)
        exx
        ld      e, (ix+2)
        ld      d, (ix+3)
        ld      b, (ix+4)
        ret

;       ----

.FpZero
        FPP     FP_ZER
        ret

;       ----

.ldFReg2_32
        exx
        ld      de, 32                          ; !! jr below
        exx
        ld      de, 0
        ld      b, 0
        ret

;       ----

.ldFReg2_100
        exx
        ld      de, 100
        exx
        ld      de, 0
        ld      b, 0
        ret

;       ----

.FpVal
        FPP     FP_VAL
        ret

;       ----

.sub_FEBC
        push    hl
        ld      de, calc_StrBuffer
        push    iy
        pop     hl
        add     hl, de
        ex      de, hl
        pop     hl
        exx
        ld      d, 2
        ld      e, d
        ld      a, (varFix)
        or      a
        jr      z, FpStr
        rra
        ld      e, a
        cp      9
        jr      nz, FpStr
        ld      d, 0

.FpStr
        exx
        FPP     FP_STR
        ret

;       ----

.ExFReg1_FReg2
        ex      de, hl
        exx
        ex      de, hl
        exx
        ld      a, b
        ld      b, c
        ld      c, a
        ret

;       ----

.FpTst
        FPP     FP_TST
        add     a, a
        ret

;       ----

.FpOne
        FPP     FP_ONE
        ret

;       ----

.FpAdd
        FPP     FP_ADD
        ret

;       ----

.NegateFReg1
        call    ExFReg1_FReg2
        call    FpZero
        call    ExFReg1_FReg2                   ; !! jr would be smaller

;       ----

.FpSub
        call    ExFReg1_FReg2
        FPP     FP_SUB
        ret

;       ----

.FpMul
        FPP     FP_MUL
        ret

;       ----

.OnePerFloat
        call    ExFReg1_FReg2
        call    FpOne
        call    ExFReg1_FReg2

;       ----

.FpDiv
        call    ExFReg1_FReg2
        FPP     FP_DIV
        ret

;       ----

.MoveXY_AB
        push    af
        ld      a, 1
        OZ      OS_Out
        ld      a, '3'
        OZ      OS_Out
        ld      a, '@'
        OZ      OS_Out
        pop     af
        add     a, $20
        OZ      OS_Out
        push    af
        ld      a, b
        add     a, $20
        OZ      OS_Out
        pop     af
        ret

;       ----

.ReadKey
        call    PurgeKbdBuf

.rdk_1
        OZ      OS_In
        jr      c, rdk_2
        or      a
        ret     nz                              ; return normal char
        OZ      OS_In
        ret     nc                              ; return expanded char

.rdk_2
        cp      RC_Quit
        jp      z, Exit
        cp      RC_Esc
        jr      nz, rdk_1

        ld      a, $1B                          ; !! move this after OS_Esc

        push    af
        ld      a, 1                            ; !! this can be removed if above is done
        OZ      OS_Esc                          ; Examine special condition
        pop     af

        scf
        ret

;       ----

.ErrorHandler
        ret     z
        cp      RC_Quit
        jp      z, Exit
        cp      RC_Dvz
        jr      c, erh_1
        cp      $4D
        jr      nc, erh_1
        set     CF_B_Error, (iy+calc_Flags)
.erh_1
        cp      a
        ret
;       ----

.PurgeKbdBuf
        ld      ix, 1
        OZ      OS_Pur
        scf
        ret

;       ----

.ToUpper
        call    IsAlpha
        ret     nc
        and     $DF
        ret

;       ----

.IsNum
        cp      '0'
        ccf
        ret     nc
        cp      '9'+1
        ret

;       !! unused

.IsAlphaNum
        call    IsNum
        ret     c

.IsAlpha
        cp      'A'
        ccf
        ret     nc
        cp      'Z'+1
        ret     c
        cp      'a'
        ccf
        ret     nc
        cp      'z'+1
        ret

;       !! unused

        call    KPrint
        defm    1,"2C",$FD,0
        ret

;       ----

.PrntChar_0C
        ld      a, 12
        jr      PrntChar

;       ----

.PrntChar_07
        ld      a, 7
        OZ      OS_Out
        scf
        ret

;       ----

.PrntReverse
        push    af
        ld      a, 1
        OZ      OS_Out
        ld      a, 'R'
        OZ      OS_Out
        pop     af
        ret


;       !! unused!

        push    bc
        ld      c, '-'
        jr      loc_FFAA
        push    bc
        ld      c, '+'

.loc_FFAA
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

.sub_FFBD
        cp      13                              ; expand CR to LF+CL
        jr      nz, PrntChar
        ld      a, 10
        call    PrntChar
        ld      a, 13

;       ----

.PrntChar
        OZ      OS_Out                          ; write a byte to std. output
        ret

;       ----

.KPrint
        ex      (sp), hl

.kpr_1
        ld      a, (hl)
        inc     hl
        or      a
        jr      z, kpr_2
        call    sub_FFBD                        ;expand CR into CD+LF
        jr      kpr_1

.kpr_2
        ex      (sp), hl
        ret

;       ----

.PrntASpaces
        or      a
        ret     z
        push    af
        ld      a, 1
        OZ      OS_Out
        ld      a, '3'
        OZ      OS_Out
        ld      a, 'N'
        OZ      OS_Out
        pop     af
        add     a, $20
        OZ      OS_Out

.PrntSpace
        ld      a, ' '
        OZ      OS_Out
        ret
