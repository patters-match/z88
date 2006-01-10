; **************************************************************************************************
; Imp/export popdown (Bank 1, addressed for segment 3).
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
; (C) Jorma Oksanen (jorma.oksanen@aini.fi), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005
; (C) Gunther Strube (gbs@users.sf.net), 2005
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************


        Module  ImpExp

        org     $fab1

        include "director.def"
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "integer.def"
        include "memory.def"
        include "stdio.def"
        include "syspar.def"

        include "impexp.inc"

xdef    Imp_Export



; IF vars_e <> $1ffe
;       ERROR   "Error in defvars"
; ENDIF

defgroup {
ERR_System, ERR_Response, ERR_Data, MSG_Eob,
MSG_Eof, ERR_Esc, ERR_Name, MSG_AllSent
}

.Imp_Export
        ld      iy, SAFE

        ld      a, SC_ENA
        OZ      OS_Esc
        xor     a
        ld      hl, ErrHandler
        OZ      OS_Erh

.Main_redraw
        call    InitWd

.Main
        ld      a, SC_ACK
        OZ      OS_Esc

        call    KPrint
        defm    "B)atch receive, E)nd batch, R)eceive file or S)end file? ",0

        xor     a
        ld      c, a
.main_wait
        ld      de, InputBuf
        ld      b, 2
        OZ      GN_Sip
        call    c, MayQuit
        call    c, MayExit
        call    c, Backspace_C
        jr      c, main_wait

        call    PrntCRLF
        ld      a, (de)
        or      a
        jr      z, m_4

        call    ToUpper
        ld      hl, CmdChars_tbl                ; "SREB" !! do this with 4 * cp
        ld      bc, 4
        cpir
        jr      z, m_2
        ld      a, ERR_Response
        call    PrntError
        jr      m_4

.m_2
        sla     c
        ld      hl, CmdFuncs_tbl
        add     hl, bc
        ld      e, (hl)                         ; DE=func
        inc     hl
        ld      d, (hl)
        ex      de, hl
        ld      de, m_3
        push    de
        jp      (hl)
.m_3
        jp      c, Main_redraw
.m_4
        call    PrntCRLF
        jp      Main

.CmdFuncs_tbl
        defw    Cmd_BatchRcv
        defw    Cmd_EndBatch
        defw    Cmd_Receive
        defw    cmd_Send
.CmdChars_tbl
        defm    "SREB"

;       ----

.MayExit
        cp      RC_Esc
        jr      z, Exit
        scf
        ret

.MayQuit
        cp      RC_Quit
        scf
        ret     nz
.Exit
        xor     a
        OZ      OS_Bye
        jr      Exit

.ErrHandler
        ret     z
        cp      RC_Quit
        jr      z, Exit
        cp      a
        ret

;       ----

.brcv_0
        call    PrntCRLF
        jr      brcv_1

.Cmd_BatchRcv
        call    GetSerHandle
        call    c, PrntError
        ccf
        ret     nc

.brcv_1
        call    Receive
        ret     c
        cp      MSG_Eof
        jr      z, brcv_0
        or      a
        ret

;       ----

.Cmd_EndBatch
        call    GetSerHandle
        jr      c, ebat_1
        ld      a, 'Z'                          ; batch end
        call    MaySendB_EscA
.ebat_1
        call    c, PrntError
        or      a
        ret

;       ----

.snd_0
        cp      RC_Eof
        scf
        jp      nz, snd_9
        ld      a, MSG_AllSent
        jp      SndRcv_End

.cmd_Send
        ld      hl, 0
        ld      (FileHandle), hl
        ld      (WildHandle), hl
.snd_1
        call    AskFilename
        ret     c
        ret     z
        ld      a, (LocalName)
        or      a
        jr      z, snd_1

        call    GetSerHandle
        jp      c, SndRcv_End
        ld      bc, 50
        ld      hl, LocalName
        ld      e, l
        ld      d, h
        OZ      GN_Fex
        jr      c, snd_9
        rla
        jr      nc, snd_5
        xor     a
        ld      b, a
        OZ      GN_Opw                          ; open wildcard handler
        jr      c, snd_9
        ld      (WildHandle), ix
.snd_2
        ld      ix, (WildHandle)
        ld      de, LocalName
        ld      c, 50
        OZ      GN_Wfn                          ; get next filename match from wc.handler
        jr      c, snd_0                        ; no more files?
        cp      DN_FIL
        jr      nz, snd_2                       ; not file? skip
        ld      hl, LocalName
.snd_3
        ld      a, (hl)
        or      a
        jr      z, snd_4
        OZ      OS_Out                          ; write a byte to std. output
        inc     hl
        jr      snd_3
.snd_4
        call    PrntCRLF
.snd_5
        ld      a, 1
        ld      bc, 50
        ld      de, 3
        ld      hl, LocalName
        OZ      GN_Opf                          ; open file/stream (or device)
        jr      c, snd_9
        ld      (FileHandle), ix
        ld      de, 1
        ld      a, 'N'                          ; name start
        call    MaySendB_EscA
        jr      c, snd_10
        ld      hl, LocalName
.snd_6
        ld      a, (hl)
        or      a
        jr      z, snd_7
        call    SendChar
        jr      c, snd_10
        inc     hl
        jr      snd_6
.snd_7
        ld      a, 'F'                         ; name end, data start
        call    MaySendB_EscA
        jr      c, snd_10
.snd_8
        call    TestEsc
        ld      a, ERR_Esc
        jr      c, snd_10
        ld      ix, (FileHandle)
        OZ      OS_Gb                           ; get byte from file or device
        jr      nc, snd_11
        cp      RC_Eof
        jr      z, snd_12
        scf
.snd_9
        ld      a, ERR_System
.snd_10
        jp      SndRcv_End
.snd_11
        call    PrntLineNum
        call    SendChar
        jr      nc, snd_8
        jr      snd_10
.snd_12
        ld      a, 'E'          ; eof
        call    MaySendB_EscA
        jr      c, snd_10
        ld      hl, (WildHandle)
        ld      a, h
        or      l
        jr      z, snd_10
        call    CloseFile
        call    c, PrntError
        call    PrntCRLF
        jp      snd_2

;       ----

.SendChar
        cp      $20
        jr      c, sc_1
        cp      $7F
        jp      c, MaySendB
.sc_1
        cp      13
        jp      z, MaySendB
        cp      9
        jp      z, MaySendB
        cp      10
        jp      z, MaySendB
        push    af
        ld      a, 'B'                          ; binary
        call    MaySendB_EscA
        pop     bc
        ret     c
        ld      a, b
        push    af
        srl     a
        srl     a
        srl     a
        srl     a
        call    ItoH
        call    SendChar
        pop     bc
        ret     c
        ld      a, b
        and     $0F
        call    ItoH
        jr      SendChar

;       ----

.ItoH
        or      '0'
        cp      ':'
        ret     c
        add     a, 7
        ret

;       ----

.Cmd_Receive
        call    AskFilename
        ret     c
        ret     z
        call    GetSerHandle
        call    c, PrntError
        ccf
        ret     nc

;       ----

.Receive
        ld      de, 0
        ld      (FileHandle), de
        ld      (WildHandle), de
        ld      hl, RemoteName
        ld      (hl), d
.rcv_1
        call    TestEsc
        ld      a, ERR_Esc
        jp      c, SndRcv_End
        call    RcvB
        jp      c, SndRcv_End
        cp      27
        jr      nz, rcv_2
        call    RcvFilename
        jr      c, SndRcv_End
        jp      pe, rcv_1
.rcv_2
        ld      c, a
        ld      a, (iy+RemoteName-SAFE)
        or      (iy+LocalName-SAFE)
        jr      z, rcv_1
        ld      a, (iy+FileHandle-SAFE)
        or      (iy+FileHandle+1-SAFE)
        jr      nz, rcv_6
        call    GetName
        push    bc
        ld      a, 2
        ld      bc, 50
        ld      de, 3
        OZ      GN_Opf
        pop     bc
        jr      c, rcv_7
        ld      (FileHandle), ix
        call    GetName
        jr      z, rcv_3
        call    KPrint
        defm    "Using supplied name: ",0
        jr      rcv_4
.rcv_3
        call    KPrint
        defm    "Using remote name: ",0
.rcv_4
        ld      a, (hl)
        or      a
        jr      z, rcv_5
        OZ      OS_Out
        inc     hl
        jr      rcv_4
.rcv_5
        call    PrntCRLF
        ld      de, 1
.rcv_6
        ld      a, c
        call    PrntLineNum
        ld      ix, (FileHandle)
        OZ      OS_Pb
        jp      nc, rcv_1
.rcv_7
        ld      a, 0

;       ----

.SndRcv_End
        push    af
        call    CloseFile
        jr      nc, sre_2
        pop     de
        bit     0, e
        jr      nz, sre_1
        set     0, e
        ld      d, a
.sre_1
        push    de
.sre_2
        pop     af
        push    af
        call    c, PrntError
        ld      hl, (WildHandle)
        ld      a, h
        or      l
        jr      z, sre_3
        push    hl
        pop     ix
        OZ      GN_Wcl
.sre_3
        pop     af
        or      a
        ret

;       ----

.GetName
        ld      hl, LocalName
        ld      a, (hl)
        or      a
        ret     nz
        ld      hl, RemoteName                  ; !! ld l,<RemoteName
        ret

;       ----

.RcvFilename
        call    RcvB
        ret     c
        call    ToUpper
        cp      'F'
        jr      z, rfn_3                        ; name end? return
        cp      'E'
        jr      z, SetEofErr                    ; file end?
        cp      'Z'
        jr      z, SetEobErr                    ; batch end?
        cp      'B'
        jr      z, GetHexB
        cp      'N'
        jr      nz, SetDataErr

        ld      hl, RemoteName
        ld      b, 50
.rfn_1
        call    RcvB
        ret     c
        cp      27
        jr      z, rfn_2
        ld      (hl), a
        inc     hl
        djnz    rfn_1
        jr      SetDataErr                      ; name too long

.rfn_2
        ld      (hl), 0
        call    RcvB
        ret     c
        call    ToUpper
        cp      'F'                             ; name end
        jr      nz, SetDataErr

.rfn_3
        push    af
        pop     hl
        ld      l, 4                            ; V flag?
        push    hl
        pop     af
        ret

.SetDataErr
        ld      a, ERR_Data
        scf
        ret

.SetEofErr
        ld      a, MSG_Eof
        scf
        ret

.SetEobErr
        ld      a, MSG_Eob
        scf
        ret

.GetHexB
        call    RcvB
        ret     c
        call    AtoI
        jr      c, SetDataErr
        add     a, a                            ; C=A<<4
        add     a, a
        add     a, a
        add     a, a
        ld      c, a
        call    RcvB
        ret     c
        call    AtoI
        jr      c, SetDataErr
        add     a, c
        push    af
        pop     hl
        ld      l, 0                            ; clear flags
        push    hl
        pop     af
        ret

;       ----

;       Fc=0, A=hex digit
;       Fc=1 if bad char

.AtoI
        call    ToUpper
        sub     '0'
        ret     c
        cp      10
        ccf
        ret     nc
        sub     7
        cp      $10
        ccf
        ret

;       ----

.CloseFile
        ld      a, (iy+FileHandle-SAFE)
        or      (iy+FileHandle+1-SAFE)
        ret     z
        ld      ix, (FileHandle)
        OZ      GN_Cl                           ; close file/stream
        ld      hl, 0
        ld      (FileHandle), hl
        ld      a, l
        ret

;       ----

.GetSerHandle
        ld      bc, NQ_Chn
        OZ      OS_Nq                           ; enquire (fetch) parameter
        ld      (SerHandle), ix
        or      a
        ret

;       ----

.PrntLineNum
        cp      10
        jr      z, pln_1
        cp      13
        ret     nz
.pln_1
        push    af
        ld      a, 13
        OZ      OS_Out                          ; write a byte to std. output
        push    de
        ld      bc, NQ_Out
        OZ      OS_Nq                           ; IX=outhandle
        ld      c, e                            ; BC=DE
        ld      b, d
        ld      hl, 2                           ; convert BC
        xor     a                               ; no formatting
        ld      e, a                            ; DE=0, write to IX
        ld      d, a
        OZ      GN_Pdn
        pop     de
        inc     de
        pop     af
        ret

;       ----

.RcvB
        ld      ix, (SerHandle)
        OZ      OS_Gb
        jr      nc, gb_1
        ld      a, ERR_System
        ret
.gb_1
        and     $7F
        ret

;       ----

.MaySendB_EscA
        push    af
        ld      a, 27
        call    MaySendB
        pop     bc
        ret     c
        ld      a, b

;       ----

.MaySendB
        call    TestEsc
        jr      c, mpb_1
        ld      ix, (SerHandle)
        OZ      OS_Pb                           ; write byte A to handle IX
        ret     nc
        ld      a, ERR_System
        ret

.mpb_1
        ld      a, ERR_Esc
        ret

;       ----

.TestEsc
        push    af
        ld      a, SC_BIT
        OZ      OS_Esc                          ; Examine special condition
        jr      c, tesc_1                       ; !! ex (sp),hl; ld a,h; pop hl; ret
        pop     af
        or      a
        ret
.tesc_1
        pop     af
        scf
        ret

;       ----

;       Fc=1 if error, FZ=1 if ESC (ESC never returned, so checking it is unnecessary)

.AskFilename
        call    KPrint
        defm    "Filename? ",0
        xor     a
        ld      c, a
.afn_1
        ld      b, 51
        ld      de, LocalName
        OZ      GN_Sip
        call    c, MayQuit
        jr      nc, afn_2
        cp      RC_Esc
        ret     z
        cp      RC_Susp                         ; suspended? clear line and re-read filename
        call    z, Backspace_C
        jr      z, afn_1
        scf
        ret

.afn_2
        call    PrntCRLF
        ld      a, (de)
        or      a
        jr      z, afn_3                        ; empty name? return
        ex      de, hl
        ld      b, 0
        OZ      GN_Prs
        jr      nc, afn_3                       ; no error? return

        ld      a, ERR_Name
        call    PrntError
        call    PrntCRLF
        jr      AskFilename

.afn_3
        ld      a, 1                            ; Fc=0, Fz=0
        or      a
        ret

;       ----

.InitWd
        call    KPrint
        defb    1, $37, $23,    $31, $21, $20, $7C, $28, $81
        defb    1, $32, $43,    $31
        defb    1, $32, $2B,    $43
        defb    1, $53
        defb    0
        ret

;       ----

.PrntError
        push    af

        xor     a
        ld      bc, NQ_WCUR
        OZ      OS_Nq
        inc     c
        dec     c
        call    nz, PrntCRLF                    ; x<>0? crlf

        call    PrntBell
        pop     af
        or      a
        jr      z, pre_3                        ; A=0? print system error
        dec     a
        add     a, a
        ld      e, a
        ld      d, 0
        ld      hl, ErrorTable
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl
.pre_1
        ld      a, (hl)
        push    af                              ; !! add a,a; push af; rra a
        and     $7F
        OZ      OS_Out
        inc     hl
        pop     af                              ; !! pop af; jr nc
        bit     7, a
        jr      z, pre_1
.pre_x
        scf
        ret

.pre_3
        OZ      OS_Erc
        OZ      GN_Esp
.pre_5
        OZ      GN_Rbe
        or      a
        jr      z, pre_x
        OZ      OS_Out
        inc     hl
        jr      pre_5

.ErrorTable
        defw    Error_1
        defw    Error_2
        defw    Error_3
        defw    Error_4
        defw    Error_5
        defw    Error_6
        defw    Error_7

.Error_1
        defm    "Bad respons",'e'|$80
.Error_2
        defm    "Poor data receive",'d'|$80
.Error_3
        defm    "End of batc",'h'|$80
.Error_4
        defm    "End of fil",'e'|$80
.Error_5
        defm    "Escap",'e'|$80
.Error_6
        defm    "Bad nam",'e'|$80
.Error_7
        defm    "All sen",'t'|$80

;       ----

.PrntCRLF
        call    KPrint
        defm    13,10,0
        ret

;       ----

.PrntBell
        ld      a, 7
        OZ      OS_Out
        ret

;       ----
.KPrint
        ex      (sp), hl
.kpr_1
        ld      a, (hl)
        inc     hl
        or      a
        jr      z, kpr_2
        OZ      OS_Out
        jr      kpr_1
.kpr_2
        ex      (sp), hl
        ret

;       ----

.Backspace_C
        push    af
        ex      (sp), hl
        ld      h, 1
        ex      (sp), hl
        ld      b, c
        inc     b
        dec     b
        jr      z, bsc_2
        ld      a, 8
.bsc_1
        OZ      OS_Out
        djnz    bsc_1
.bsc_2
        pop     af
        ret

;       ----

.ToUpper
        call    IsAlpha
        ret     nc
        and     $df
        ret

;       ----

;       Fc=1 if alpha

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
