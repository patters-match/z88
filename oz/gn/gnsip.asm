; **************************************************************************************************
; Genereric input line API, GN_Sip.
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
; (C) Thierry Peycru (pek@users.sf.net), 2007
; (C) Gunther Strube (gbs@users.sf.net), 2007
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module GNSip

        include "char.def"
        include "error.def"
        include "memory.def"
        include "stdio.def"
        include "syspar.def"

        include "sysvar.def"

;       ----

xdef    GNSip

;       ----

xref    GetOsf_DE
xref    Ld_A_HL
xref    Ld_DE_A
xref    PutOsf_ABC

;       ----

;       system input line
;
;IN:    DE=buffer, B=buffer length, A=flags
;          A0=1: buffer contains data
;          A1=1: force insert/overwrite
;          A2  : 0=insert, 1=overwrite (if A1=1)
;          A3=1: return special characters
;          A4=1: return on wrap
;          A5=1: single line lock
;          A6=1: reverse video
;          A7=1: return on insert/overwarite (if A3=1)
;       C=cursor position (if A0=1), L=line width (if A5=1)
;       A=flags
;
;OUT:   A=terminating input char, B=length of line (including null)
;       C=cursor position on exit
;
;CHG:   AFBC..../....

;       !! lots of  unnecessary rendering to set cursor etc. in sll mode

.GNSip
        ld      b, 0                            ; bind  buffer in
        ex      de, hl
        OZ      OS_Bix
        push    de                              ; remember bindings

        ex      de, hl
        ld      b, (iy+OSFrame_B)               ; minimum buffer size
        ld      a, b                            ; is two bytes
        cp      2
        jr      nc, sip_1
        ld      a, RC_Bad
        jp      sip_err

.sip_1
        dec     b                               ; reserve space for NULL
        dec     (iy+OSFrame_B)                  ; at end
        push    bc
        push    de
        ld      h, d                            ; HL=buffer
        ld      l, e
        ld      c, b                            ; BC=offset to  buffer end
        ld      b, 0
        add     hl, bc
        ld      (hl), 0                         ; zero terminate

;       set margins if single line lock

        bit     5, (iy+OSFrame_A)               ; single line lock?
        jr      z, sip_2
        ld      a, 0                            ; current window
        ld      bc, NQ_Wcur                     ; get cursor info
        OZ      OS_Nq
        ld      a, (iy+OSFrame_L)               ; line  width
        add     a, c                            ; + cursor x
        ld      b, a
        call    SetMargins                      ; margins at c,b-1
        OZ      OS_Pout
        defm    1,"W",0


;       reverse display if needed

.sip_2
        bit     6, (iy+OSFrame_A)               ; reverse?
        jr      z, sip_5
        OZ      OS_Pout
        defm    1,"2+R",0
        OZ      OS_Pout
        defm    1,"2A",0
        ld      a, (iy+OSFrame_B)               ; use buffer width
        bit     5, (iy+OSFrame_A)               ; single line lock?
        jr      z, sip_3
        ld      a, (iy+OSFrame_L)               ; use line width
.sip_3
        ld      b, a                            ; remember count
        add     a, $20                          ; and write to  ScrDriver
        OZ      OS_Out

        ld      a, BS                           ; backspace to beginning
.sip_4
        OZ      OS_Out
        djnz    sip_4

;       init insert/overwrite flag

;       !! check for forced i/o before using OZ setting

.sip_5
        ld      bc, PA_Iov                      ; get insert/overwrite  setting
        dec     sp                              ; !! 'push af; ld hl, 1' then 'pop af' below
        ld      a, 1
        ld      hl, 0
        add     hl, sp
        ld      d, h
        ld      e, l
        OZ      OS_Nq
        ld      hl, 0
        add     hl, sp
        ld      a, (hl)
        inc     sp
        cp      'O'                              ; !! 'sub "I";jr z;ld a,4'
        ld      a, 4                            ; overwrite flag
        jr      z, sip_6
        xor     a
.sip_6
        pop     de
        pop     bc
        bit     1, (iy+OSFrame_A)               ; force insert/overwrite?
        jr      z, sip_7
        ld      a, (iy+OSFrame_A)               ; use caller setting
.sip_7
        and     4
        ld      h, a                            ; store flag

;       buffer init

        bit     0, (iy+OSFrame_A)               ; buffer has data?
        jr      nz, sip_8
        xor     a                               ; zero the first byte in buffer
        ld      b, a                            ; !! unnecessary
        call    Ld_DE_A

;       print buffer

.sip_8
        call    StrLen                          ; B=#chars
        ld      c, 0
        call    PrintBuf
        jr      c, sip_err                      ; error? exit
        bit     0, (iy+OSFrame_A)
        jr      z, sip_main                     ; no data in buffer? skip

        ld      a, (iy+OSFrame_C)               ; cursor position
        ld      c, a                            ; C=MIN(A,B)
        cp      b
        jr      c, sip_9
        jr      z, sip_9                        ; !! unnecessary
        ld      c, b
.sip_9
        ld      a, c                            ; cursor at beginning? skip
        or      a
        jr      z, sip_main                     ; cursor at pos zer0?   skip

;       print chars until cursor position

        ld      l, a
        ld      c, 0
.sip_10
        call    PrCharBumpC_DE
        dec     l
        jr      nz, sip_10

;       init done, here's the main loop
;
;       B=#chars in buffer, C=cursor position, H=flags
;       DE=buffer pointer to current position

.sip_main
        res     7, h                            ; not extended
        OZ      OS_In
        jr      c, sip_err                      ; exit on error
        or      a
        jr      nz, sip_normalc                 ; normal? go do it
        set     7, h                            ; extended
        OZ      OS_In
        jr      nc, sip_extendedc
.sip_err
        set     Z80F_B_C, (iy+OSFrame_F)
        jr      sip_x

;       print char, exit on error

.sip_PrChar
        OZ      OS_Out
        ret     nc
        inc     sp                              ; discard one call level
        inc     sp                              ; !! does this work if we come from
        jr      sip_err                         ; !! PrintBuf() -> PrintBackChar()?

;       !! 'ld hl, table-2' and move 'inc hl;inc hl' to start of loop

.sip_normalc
        push    hl
        ld      hl, SipNormal_tbl
        jr      sip_16

.sip_extendedc
        push    hl
        ld      hl, SipExtended_tbl

.sip_16
        push    bc
        ld      c, a                            ; C=input char
.sip_17
        ld      a, (hl)                         ; command char
        inc     hl
        or      a
        jr      z, sip_19                       ; end of list?
        cp      c
        jr      z, sip_18                       ; match? execute
        inc     hl                              ; next  command and loop
        inc     hl
        jr      sip_17

;       get function address an jump there

;       !! could push sp_main to allow looping with 'ret'
;       !! (needs changes in sip_PrChar)

.sip_18
        push    af                              ; !! don't push/pop, 'ld a, c' below
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        pop     af
        pop     bc
        ex      (sp), hl                        ; restore hl, push function
        ret                                     ; call  it

;       not command, handle control chars or put into buffer

.sip_19
        ld      a, c
        pop     bc
        pop     hl
        bit     7, h                            ; was extended?
        scf
        jr      nz, sip_20
        cp      $20
.sip_20
        jp      c, sip_special                  ; control chars
        jp      sip_InputChar


.sip_x
        inc     b                               ; include null to length
        bit     5, (iy+OSFrame_A)               ; single line lock?
        call    PutOsf_ABC

        jr      z, sip_22
        ld      a, 0                            ; set margins at very edges of  window
        ld      bc, NQ_Wbox
        OZ      OS_Nq                           ; enquire (fetch) parameter
        ld      b, c
        ld      c, 0
        call    SetMargins
        OZ      OS_Pout
        defm    1,"W",0

.sip_22
        pop     de
        OZ      OS_Box                          ; Restore bindings after OS_Bix
        ret

.sip_Del
        ld      a, c
        or      a
        jr      z, sip_26                       ; cursor at 0? exit

        call    PrintBackChar                   ; move left
        bit     2, h
        jr      nz, sip_delo                    ; overwrite mode?

;       insert mode: move left, delete char

        call    DelChar
        call    PrintBuf
        jp      c, sip_err
        jr      sip_26

;       overwrite mode: move left, replace char with space

.sip_delo
        ld      a, c                            ; if we were at the end
        inc     a                               ; we decrement length
        cp      b
        jr      nz, sip_25
        dec     b
.sip_25
        ld      a, ' '
        call    Ld_DE_A
        call    sip_PrChar
        ld      a, 8
        call    sip_PrChar
.sip_26
        jp      sip_main

;       swap case

.sip_CtrlS
        ld      a, c
        cp      b
        ld      a, $13                          ; ^S
        jp      z, sip_special                  ; cursor at end? may exit

        call    ClsBufChar                      ; get char and classify it
        jr      nc, skip_char                   ; non-alpha, skip it..
        call    InvCase                         ; inverse alpha (both ASCII and ISO)
.sip_28
        call    Ld_DE_A                         ; put char back
.skip_char
        inc     de                              ; advance cursor
        inc     c
        call    sip_PrChar
        jp      sip_main

;       delete word

.sip_CtrlT
        ld      a, c                            ; delete right until space
        cp      b
        jp      z, sip_main                     ; cursor at end? main !! why not sip_special
        push    hl                              ; get buffer char
        ld      h, d
        ld      l, e
        call    Ld_A_HL
        pop     hl
        cp      ' '
        jr      z, sip_30                       ; space? start deleting spaces
        call    DelChar
        call    PrintBuf
        jr      sip_CtrlT
.sip_30
        call    DelChar                         ; delete right until nonspace
        call    PrintBuf
        ld      a, c
        cp      b
        jp      z, sip_main                     ; cursor at end? main
        push    hl                              ; get buffer char
        ld      h, d
        ld      l, e
        call    Ld_A_HL
        pop     hl
        cp      ' '
        jr      z, sip_30                       ; space? continue delete
        jp      sip_main

;       normal char, put into buffer

.sip_InputChar
        ld      l, a
        ld      a, c
        cp      b
        ld      a, l
        jr      z, sip_inpins                   ; end of string? skip
        bit     2, h
        jr      z, sip_inpins                   ; insert mode? skip

;       overwrite not at end? just put char into buffer

        call    Ld_DE_A
        jr      sip_33

.sip_inpins
        call    InsChar                         ; insert into buffer
        call    PrintBuf                        ; update display
        jp      c, sip_err
        ld      a, c                            ; don't advance if at
        cp      (iy+OSFrame_B)                  ; max length already
        jr      z, sip_34

        ld      a, HT                           ; move right
.sip_33
        inc     c                               ; advance cursor
        inc     de
        call    sip_PrChar                      ; update display
.sip_34
        jp      sip_maywrap                     ; check for wrap

;       delete line - first move to start, then drop thru to <>DEL

.sip_CtrlDel
        ld      a, c
        or      a
        jr      z, sip_CtrlD                    ; cursor at 0? go delete
        call    PrintBackChar                   ; else move left and loop
        jr      sip_CtrlDel

;       delete to EOL

.sip_CtrlD
        ld      a, c                            ; cursor at end? main
        cp      b
        jr      z, sip_39
        xor     a                               ; terminate buffer
        call    Ld_DE_A
        ld      a, b
        sub     c
        ld      b, a                            ; # chars deleted
        ld      l, a

        ld      a, ' '                           ; print spaces until end
.sip_37
        call    sip_PrChar
        djnz    sip_37

        ld      b, l                            ; then  move back
        ld      a, BS
.sip_38
        call    sip_PrChar
        djnz    sip_38
        ld      b, c                            ; set string length
.sip_39
        jp      sip_main

;       move to EOL

.sip_CtrlRight
        ld      a, c                            ; cursor at end? exit
        cp      b
        jp      z, sip_maywrap
        call    PrCharBumpC_DE                  ; else move right and loop
        jr      sip_CtrlRight

;       move to SOL

.sip_CtrlLeft
        ld      a, c                            ; cursor at start? exit
        or      a
        jp      z, sip_maywrap
        call    PrintBackChar                   ; else move left and loop
        jr      sip_CtrlLeft

;       next word

.sip_ShftRight
        ld      a, c                            ; cursor at end?
        cp      b
.sip_43
        ld      a, IN_SRGT                      ; go handle special key
        jp      z, sip_special                  ; if at end

.sip_44
        ld      a, c
        cp      b
        jr      z, sip_46
        call    ClsNextBufChar                  ; move right, classify char
        jr      c, sip_44                       ; alpha? loop
        jr      z, sip_44                       ; number? loop

.sip_45
        ld      a, c                            ; move right until alphanum
        cp      b
        jr      nz, sip_47                      ; not at end? skip

.sip_46
        bit     3, (iy+OSFrame_A)               ; return on special?
        jr      z, sip_maywrap                  ; no? may wrap
        sub     a
        jr      sip_43                          ; else handle shift-right

.sip_47
        call    ClsNextBufChar                  ; move right, classify char
        jr      c, sip_48
        jr      nz, sip_45                      ; loop back if not alphanum

.sip_48
        jp      sip_maywrap

;       prev word

.sip_ShftLeft
        ld      a, c                            ; cursor at 0?
        or      a
.sip_50
        ld      a, IN_SLFT                      ; go handle special key
        jr      z, sip_special                  ; if at end

.sip_51
        ld      a, c                            ; move left until alphanum
        or      a
        jr      nz, sip_52                      ; not at start? skip

        bit     3, (iy+OSFrame_A)               ; return on special?
        jr      z, sip_maywrap                  ; no? may wrap
        sub     a
        jr      sip_50                          ; else handle shift-left

.sip_52
        call    ClsPrevBufChar                  ; move left, classify char
        jr      c, sip_53
        jr      nz, sip_51                      ; loop back if not alphanum

.sip_53
        ld      a, c
        or      a
        jr      z, sip_maywrap                  ; cursor at start? end

        call    ClsPrevBufChar                  ; move left, classify char
        jr      c, sip_53
        jr      z, sip_53                       ; loop back if alphanum
                                                ; then drop thru

;       move right

.sip_Right
        ld      a, c
        cp      b
        ld      a, IN_RGT
        jr      z, sip_special                  ; may exit if at end

        call    PrCharBumpC_DE                  ; move right and exit
        jr      sip_maywrap

;       move left

.sip_Left
        ld      a, c
        or      a
        ld      a, IN_LFT
        jr      z, sip_special                  ; may exit if at start

        call    PrintBackChar                   ; mover left and exit
        jr      sip_maywrap

;       insert character

.sip_CtrlU
        ld      a, ' '                          ; insert space into buffer
        call    InsChar
        call    PrintBuf                        ; and update
        jp      c, sip_err
        jr      sip_maywrap

;       delete char under cursor

.sip_CtrlG
        call    DelChar                         ; delete from buffer
        call    PrintBuf                        ; and update
        jp      c, sip_err
        jr      sip_maywrap

;       toggle insert/overwrite

.sip_CtrlV
        ld      a, 4                            ; toggle flag
        xor     h
        ld      h, a

        bit     3, (iy+OSFrame_A)               ; return special?
        jr      z, sip_maywrap                  ; no? main
        bit     7, (iy+OSFrame_A)               ; i/o return?
        jr      z, sip_maywrap                  ; no? main
        ld      a, $16                          ; ^V
        jp      sip_x                           ; exit

.sip_maywrap
        bit     4, (iy+OSFrame_A)               ; return on wrap?
        jp      z, sip_main                     ; no? loop

        ld      a, b                            ; loop if not at end
        cp      (iy+OSFrame_B)
        jp      nz, sip_main
        ld      a, RC_Wrap
        jp      sip_err

.sip_special
        bit     3, (iy+OSFrame_A)               ; return special?
        jp      z, sip_main                     ; no? loop
        jp      sip_x

;       ----

;       put character into buffer, move rest to right
;
;IN:    A=char to insert, B=string length, C=cursor pos, DE=buffer

.InsChar
        push    af
        ld      a, c                            ; cursor at end of buffer?
        cp      (iy+OSFrame_B)
        jr      z, insc_5                       ; yes? no more room, skip

        ld      a, b
        sub     c
        ld      l, a                            ; #bytes to move
        ld      a, b                            ; -1 if buffer full
        cp      (iy+OSFrame_B)
        jr      nz, insc_1
        dec     l
.insc_1
        push    bc
        push    hl
        ld      a, l                            ; !! do this check before push
        or      a
        jr      z, insc_4                       ; no data to move

;       !! could move one more char to avoid ZeroTerm()

        ld      b, a                            ; count
        add     a, e                            ; DE += A, end of data to move
        ld      e, a
        jr      nc, insc_2
        inc     d
.insc_2
        ld      h, d                            ; HL=DE-1
        ld      l, e
        dec     hl
.insc_3
        call    Ld_A_HL                         ; move  data forward one byte
        call    Ld_DE_A
        dec     hl
        dec     de
        djnz    insc_3                          ; until all done

.insc_4
        pop     hl
        pop     bc
        pop     af
        push    af
        call    Ld_DE_A                         ; put new char  into buffer

        ld      a, b                            ; increment string length
        cp      (iy+OSFrame_B)                  ; if not max already
        jr      z, insc_5
        inc     b
        call    ZeroTerm
.insc_5
        pop     af
        ret

;       ----

;       delete char from buffer, move rest to left
;
;IN:    B=string length, C=cursor pos, DE=buffer

.DelChar
        ld      a, b                            ; cursor at end of string?
        sub     c
        jr      z, ZeroTerm                     ; yes, just terminate

        push    de
        dec     a                               ; no data to move? skip
        jr      z, delc_2

        push    bc
        push    hl
        ld      b, a
        ld      h, d                            ; HL=DE+1
        ld      l, e
        inc     hl
.delc_1
        call    Ld_A_HL                         ; move  buffer data one byte left
        call    Ld_DE_A
        inc     hl
        inc     de
        djnz    delc_1                          ; until all done
        pop     hl
        pop     bc

.delc_2
        pop     de                              ; restore buffer pos
        dec     b                               ; shrink string
                                                ; and drop thru
;       ----

.ZeroTerm
        ld      a, b
        cp      (iy+OSFrame_B)
        jr      z, zt_2                         ; max length? end !! 'ret z'

        push    de
        call    GetOsf_DE                       ; DE=DE(in) + string_len
        add     a, e
        ld      e, a
        jr      nc, zt_1
        inc     d
.zt_1
        xor     a                               ; terminate buffer
        call    Ld_DE_A
        pop     de
.zt_2
        ret

;       ----

; OUT: B=#chars in buffer DE

.StrLen
        ld      b, 0
        ld      c, (iy+OSFrame_B)               ; buffer length
        push    hl
        ld      h, d
        ld      l, e
.strl_1
        call    Ld_A_HL
        inc     hl
        or      a
        jr      z, strl_2                       ; zero? end
        inc     b
        dec     c
        jr      nz, strl_1                      ; more  chars? loop
.strl_2
        pop     hl
        ret

;       ----

;       print chars from C to B

.PrintBuf
        ld      a, (iy+OSFrame_B)               ; buffer length
        cp      c
        ret     z                               ; C at  EOB? exit Fc=0
        push    bc
        push    hl
        ld      a, b                            ; string length
        cp      (iy+OSFrame_B)                  ; +1 if not max length
        jr      z, pb_1
        inc     a
.pb_1
        sub     c                               ; current pos
        ld      b, a                            ; save count
        ld      c, a
        ld      h, d                            ; HL=buffer
        ld      l, e
.pb_2
        call    Ld_A_HL                         ; get buffer char
        inc     hl
        or      a                               ; replace NULL with space
        jr      nz, pb_3
        ld      a, ' '
.pb_3
        OZ      OS_Out                          ; print
        djnz    pb_2                            ; loop  until B chars done

        ld      b, c                            ; restore count
        ex      de, hl                          ; DE=buffer end
.pb_4
        call    PrintBackChar                   ; print chars backward
        djnz    pb_4                            ; until we are where we started

        or      a                               ; Fc=0
        pop     hl
        pop     bc
        ret

;       ----

.ClsPrevBufChar
        call    PrintBackChar                   ; move left
        jr      ClsBufChar
.ClsNextBufChar
        call    PrCharBumpC_DE                  ; move right
.ClsBufChar
        push    hl                              ; get buffer char and classify it
        ld      h, d
        ld      l, e
        call    Ld_A_HL
        pop     hl
        OZ      GN_Cls
        ret

;       ----

; IN: B=right margin+1, C=left margin

.SetMargins
        push    bc
        OZ      OS_Pout
        defm    1,"2L",0                        ; Set left margin
        pop     bc
        push    bc
        ld      a, $20
        add     a, c
        OZ      OS_Out
        OZ      OS_Pout
        defm    1,"2R",0                        ; Set right margin
        pop     bc
        ld      a, $20-1
        add     a, b
        OZ      OS_Out
        ret

;       ----

.PrintBackChar
        dec     c                               ; decrement pos
        dec     de
        ld      a, BS                           ; move left
        call    sip_PrChar
        ld      a, (de)                         ; get char, replace NULL with space
        or      a
        jr      nz, bpc_1
        ld      a, ' '
.bpc_1
        call    sip_PrChar                      ; print it
        ld      a, BS                           ; and move back
        jp      sip_PrChar

;       ----

.PrCharBumpC_DE
        ld      a, (de)                         ; get char in buffer
        call    sip_PrChar                      ; print it
        inc     c                               ; increment pos
        inc     de
        ret

;       ----
.InvCase
        cp      191
        jr      nc,InvCaseISO
        xor     $20                             ; normal ASCII alpha's can always be case inversed...
        ret
.InvCaseISO
        push    bc
        push    hl
        ld      hl,InvCaseTable
        ld      b, InvCaseTable_end-InvCaseTable
.lookup
        ld      c,(hl)
        cp      c                               ; check for upper case -> lower case
        jr      z, found_invcase
        set     5,c                             ; check for lower case -> upper case
        cp      c
        inc     hl
        jr      z, found_invcase
        djnz    lookup
        jr      exit_invcase
.found_invcase
        xor     $20                             ; case inverse the allowed ISO character
.exit_invcase
        pop     hl
        pop     bc
        ret
.InvCaseTable
        defb    196, 197, 198, 199, 203, 209, 214, 216, 220
.InvCaseTable_end


.SipExtended_tbl
        defb    IN_LFT
        defw    sip_Left
        defb    IN_RGT
        defw    sip_Right
        defb    IN_DRGT
        defw    sip_CtrlRight
        defb    IN_DLFT
        defw    sip_CtrlLeft
        defb    IN_SRGT
        defw    sip_ShftRight
        defb    IN_SLFT
        defw    sip_ShftLeft
        defb    IN_UP
        defw    sip_special
        defb    IN_DWN
        defw    sip_special
        defb    IN_SUP
        defw    sip_special
        defb    IN_SDWN
        defw    sip_special
        defb    IN_DUP
        defw    sip_special
        defb    IN_DDWN
        defw    sip_special
        defb    IN_DRGT
        defw    sip_special
        defb    IN_DLFT
        defw    sip_special
        defb    IN_SDEL
        defw    sip_CtrlG
        defb    IN_DDEL
        defw    sip_CtrlDel

;       !! drops thru - is this intentional?

.SipNormal_tbl
        defb    $1B
        defw    sip_x
        defb    7
        defw    sip_CtrlG
        defb    $15
        defw    sip_CtrlU
        defb    4
        defw    sip_CtrlD
        defb    $16
        defw    sip_CtrlV
        defb    $7F
        defw    sip_Del
        defb    $0D
        defw    sip_x
        defb    $13
        defw    sip_CtrlS
        defb    $14
        defw    sip_CtrlT
        defb    0
