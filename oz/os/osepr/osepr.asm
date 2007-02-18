; **************************************************************************************************
; OS_EPR System Call (File (UV) Eprom functionality).
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
;***************************************************************************************************

        Module  EPROM

        include "blink.def"
        include "char.def"
        include "error.def"
        include "fileio.def"
        include "memory.def"
        include "misc.def"
        include "saverst.def"
        include "time.def"
        include "sysvar.def"
        include "lowram.def"

        xref PutOSFrame_BHL                     ; misc5.asm
        xref FileEprRequest                     ; osepr/eprreqst.asm
        xref FileEprFetchFile                   ; osepr/eprfetch.asm


xdef    OSEpr

;       !! completely separate module, all system calls done thru OZ calls
;       !! can be relocated if more kernel space needed
;       Eprom Interface
;       we have OSFrame so remembering S2 is unnecessary, as is remembering IY

.OSEpr
        push    hl
        ld      hl, OSEprTable
        add     a, l                            ; add reason
        ld      l, a
        jr      nc,exec_epr_reason
        inc     h                               ; adjust for page crossing.
.exec_epr_reason
        ex      (sp), hl                        ; restore hl and push address
        ret                                     ; goto reason

.OSEprTable
        jp      EprSave                         ; 00, EP_Save
        jp      EprLoad                         ; 03, EP_Load
        jp      ozFileEprRequest                ; 06, EP_Req   (OZ 4.2 and newer)
        jp      FileEprFetchFile                ; 09, EP_Fetch (OZ 4.2 and newer)
        nop                                     ; 0C
        or      a
        ret
        jp      EprDir                          ; 0f, EP_Dir
        or      a                               ; 12
        ret
        nop


;***************************************************************************************************
.ozFileEprRequest
        call    FileEprRequest
        ret     c
        ld      (iy+OSFrame_A),A                ; return "oz" File Eprom sub type (if file header found)
        call    PutOSFrame_BHL                  ; return BHL = pointer to File Header for slot C (B = absolute bank of slot)
        ld      (iy+OSFrame_C),C                ; return C = size of File Eprom Area in 16K banks
        ret     nz                              ; Fz = 0, no header found, F already 0 in (iy+OSFrame_F)
        set     Z80F_B_Z,(iy+OSFrame_F)         ; return Fz = 1 (status of "oz" file header found)
        ret



;***************************************************************************************************
;       most of this code is unnecessary - all EPROM access is done in S1

;       increment BHL and read byte
.IncPeekBHL
        inc     hl                              ; !! call IncBHL
        bit     6, h                            ; if HL=$4000 then reset it and increment bank
        jr      z, PeekBHL
        res     6, h
        inc     b

;       read byte at (BHL)
.PeekBHL
        inc     b
        dec     b
        jr      nz, peek2                       ; not local

        ld      a, (hl)                         ; read byte for easy cases
        bit     7, h                            ; if HL<$C000 then we're done
        ret     z                               ; !! shouldn't we test for S2 as well?
        bit     6, h
        ret     z

        ld      a, (BLSC_SR1)                   ; remember S1
        ex      af, af'
        ld      a, (iy+OSFrame_S3)              ; bind caller S3 in S1 and read from there
        ld      (BLSC_SR1), a
        out     (BL_SR1), a

        res     7, h                            ; fix HL into S1
        ld      a, (hl)
        set     7, h                            ; restore HL

        ex      af, af'                         ; restore S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'
        ret

.peek2
        ld      a, (BLSC_SR1)                   ; bind B in S1 and read from there
        ex      af, af'
        res     7, h                            ; fix HL into S1
        set     6, h
        ld      a, b
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ld      a, (hl)
        res     6, h                            ; normalize HL

        ex      af, af'                         ; restore S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'
        ret

;       increment BHL and write byte !! unused
.IncPokeBHL
        inc     hl                              ; !! 'call IncBHL'
        bit     6, h
        jr      z, PokeBHL_epr
        res     6, h
        inc     b

;       write byte at (BHL)
.PokeBHL_epr
        inc     b
        dec     b
        jr      nz, poke_2                      ; not local

        bit     7, h                            ; if not S3 then just poke it
        jr      z, poke_1                       ; !! shouldn't we test for S2 as well?
        bit     6, h
        jr      z, poke_1

        ex      af, af'
        ld      a, (BLSC_SR1)                   ; remember S1
        push    af

        ld      a, (iy+OSFrame_S3)              ; bind caller S3 in S1 and write there
        ld      (BLSC_SR1), a
        out     (BL_SR1), a

        res     7, h                            ; fix HL into S1
        ex      af, af'
        ld      (hl), a
        ex      af, af'
        set     7, h                            ; restore HL

        pop     af                              ; restore S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'
        ret

.poke_1
        ld      (hl), a                         ; easy...
        ret

.poke_2
        ex      af, af'
        ld      a, (BLSC_SR1)                   ; remember S1
        push    af
        res     7, h                            ; fix HL into S1
        set     6, h

        ld      a, b                            ; bind B into S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a
        ex      af, af'
        ld      (hl), a
        ex      af, af'
        res     6, h                            ; restore HL

        pop     af                              ; restore S1
        ld      (BLSC_SR1), a
        out     (BL_SR1), a

        ex      af, af'
        ret

;       ----

; read file from Eprom
;
;IN:    BHL = source filename
;       IX = output handle
;OUT:   Fc=0, file read successfully
;       Fc=1, A=error if fail
;chg:   AFBCDEHL/....

.EprLoad
        ld      b, 0                            ; bind source in
        OZ      OS_Bix
        push    de                              ; remember S1/S2

        call    IsEPROM
        jr      c, ld_4                         ; not EPROM? exit

        OZ      GN_Pfs                          ; parse filename segment

        call    FindFile
        jr      c, ld_4                         ; not found? exit
        call    FileEprFetchFile
.ld_4
        pop     de                              ; restore S1/S2
        push    af
        OZ      OS_Box
        pop     af
        ret

;       ----

; write file to EPROM
;
;IN:    HL=filename
;OUT:   Fc=0, success
;       Fc=1, A=error if fail
;chg:   AFBCDEHL/....

.EprSave
        ld      b, 0
        push    ix
        OZ      OS_Bix                          ; bind in HL
        push    de                              ; remember S1/S2

        call    OZ_DI
        push    af
        ei

        ld      bc, 250
        OZ      OS_Ust                          ; timer underflow in 2.5 secs
.check_fepr
        call    IsEPROM
        jr      nc, found_fepr                  ; File EPROM identified

        call    FormatCard                      ; no File header found, try to create file header in slot 3
        jp      c, sv_11                        ; error? exit
        jr      check_fepr
.found_fepr
        ld      a, (ubEpr_Fstype)               ; check it's filing EPROM
        cp      1
        jr      z, sv_1
        ld      a, RC_Ftm                       ; file type mismatch
        scf
        jp      sv_11

.sv_1
        push    iy
        push    hl
        ld      iy, (pEpr_PrgTable)

        ld      b, $FF                          ; check for unformatted ID
        ld      hl, $3FFC
        ld      c, 4
.sv_2
        dec     hl
        call    PeekBHL
        cp      b
        scf                                     ; Fc=0 for later check
        ccf                                     ; !! use 'cpl; or a; jr nz,...'
        jr      nz, sv_3                        ; not FF? skip ID writing
        dec     c
        jr      nz, sv_2                        ; loop for 4 bytes

        ld      a, SR_RND                       ; write random ID
        OZ      OS_Sr
        push    de
        push    bc
        ex      de, hl
        ld      hl, 0
        add     hl, sp
        ex      de, hl
        ld      bc, $FF04                       ; last bank, 4 bytes
        call    BlowMem
        pop     hl                              ; purge stack
        pop     hl

.sv_3
        pop     hl
        pop     iy
        jp      c, sv_11                        ; error? exit

        ld      a, OP_IN
        ld      bc, 255                         ; bufsize=255
        ld      de, 3                           ; ignore filename
        OZ      GN_Opf                          ; open file
        ld      (pEpr_FileHandle), ix
        jp      c, sv_11                        ; error? exit

        ld      b, 0
        OZ      GN_Pfs                          ; skip path
        ld      (pEpr_Parsedname), hl

        exx                                     ; reserve 256 bytes from stack
        ld      hl, -256                        ; !! should get 5 bytes more
        add     hl, sp
        ld      sp, hl
        exx

        call    FindFile                        ; find earlier version to delete
        push    af                              ; and remember it
        push    bc
        push    hl

        ld      a, FA_EXT                       ; get file size into DEBC
        ld      de, 0
        OZ      OS_Frm
        jp      c, sv_9                         ; error? exit

        ld      a, d
        or      a
        jr      z, sv_4                         ; smaller than 16MB? continue

        ld      a, RC_Room
        scf
        jp      sv_9

.sv_4
        push    bc
        push    de
        call    GotoEnd                         ; skip all files

        pop     de
        ld      a, e
        pop     de
        ld      c, a                            ; CDE=size

        jr      c, sv_9                         ; error? exit

        push    hl                              ; check if there's room for file
        push    de
        push    bc
        inc     d                               ; CDE+=256
        jr      nz, sv_5
        inc     c
.sv_5
        call    AddBHL_CDE
        pop     bc
        pop     de
        pop     hl
        jr      c, sv_9                         ; too big for remaining space? error

        exx                                     ; point HL to stack buffer
        ld      hl, 6
        add     hl, sp
        push    hl
        exx
        ex      (sp), hl

        ld      a, (ubEpr_NameLen)              ; name length to buffer
        ld      (hl), a
        inc     hl
        push    de
        push    bc
        ld      c, a                            ; copy filename to stack buffer (starts with '/')
        ld      b, 0                            ; !! if filename is longer than 251 bytes then
        ex      de, hl                          ; !! this corrupts stack!
        ld      hl, (pEpr_Parsedname)
        ldir
        pop     bc
        pop     hl
        ex      de, hl
        ld      (hl), e                         ; put 32-bit size into buffer
        inc     hl
        ld      (hl), d
        inc     hl
        ld      (hl), c
        inc     hl
        ld      (hl), 0

        ld      hl, 8                           ; point DE to stack buffer
        add     hl, sp
        ex      de, hl

        pop     hl
        add     a, 5                            ; write namelen+5 bytes
        jr      sv_8                            ; followed by data from file

.sv_6
        push    de
        push    hl                              ; remember BHL
        ld      a, b                            ; !! push bc
        push    af
        ld      bc, 64                          ; read 64 bytes into stack buffer
        ld      hl, 0
        OZ      OS_Mv
        pop     hl                              ; restore BL
        ld      b, h
        pop     hl
        pop     de

        jr      nc, sv_7                        ; any other error than EOF? exit
        cp      RC_Eof
        scf
        jr      nz, sv_9

.sv_7
        ld      a, 64
        sub     c
        jr      z, sv_9                         ; got zero bytes? exit

.sv_8
        ld      c, a
        call    BlowMem                         ; write c bytes from BHL
        jr      c, sv_9                         ; error? exit

        push    bc
        OZ      OS_Ust                          ; get timer value
        push    af
        OZ      OS_Ust                          ; and write it back
        pop     af
        pop     bc
        jr      nz, sv_6                        ; no timer  underflow? write more

        push    bc
        ld      a, SC_ACK
        OZ      OS_Esc                          ; reset timeout
        ld      bc, 50
        OZ      OS_Dly                          ; delay half a second
        ld      bc, 250
        OZ      OS_Ust                          ; next underflow in 2.5 seconds
        pop     bc
        jr      sv_6

.sv_9
        pop     hl                              ; pop earlier version info
        pop     bc
        pop     de
        jr      c, sv_10                        ; error? exit

        push    de
        pop     af
        ccf
        jr      nc, sv_10                       ; no earlier version? exit

        call    IncBHL                          ; delete old file
        push    iy
        ld      iy, (pEpr_PrgTable)
        xor     a
        call    BlowByte
        pop     iy

.sv_10
        ex      af, af'
        ld      hl, 256                         ; restore stack
        add     hl, sp
        ld      sp, hl
        ex      af, af'
        push    af
        ld      ix, (pEpr_FileHandle)           ; close infile
        OZ      OS_Cl
        pop     af

.sv_11
        ex      af, af'

        pop     af
        call    OZ_EI
        ex      af, af'
        pop     de                              ; restore S1/S2
        push    af
        OZ      OS_Box
        pop     af
        pop     ix
        ret

;       ----

; get next filename from EPROM
;
;IN:    BHL=buffer
;       IX=temp handle, if 0 then start at beginning
;OUT:   Fc=0, success
;       Fc=1, fail
;chg:   AFBCDEHL/....

.EprDir
        call    IsEPROM
        jr      c, dir_7                        ; not EPROM? exit

        push    bc
        push    hl

        push    ix
        pop     de
        ld      a, d
        or      e
        jr      nz, dir_1                       ; IX not 0? continue

        ld      a, FN_AH                        ; allocate temp handle
        ld      b, HND_TEMP
        OZ      OS_Fn
        jr      c, dir_6                        ; error? exit

        ld      a, (ubEpr_FirstBank)
        ld      b, a                            ; rewind to start
        ld      hl, 0
        jr      dir_3

.dir_1
        ld      a, FN_VH                        ; verify handle
        ld      b, HND_TEMP
        OZ      OS_Fn
        jr      c, dir_6                        ; error? exit

        ld      b, (ix+8)                       ; get EPROM pointer
        ld      h, (ix+9)
        ld      l, (ix+10)

.dir_2
        call    SkipFile                        ; skip  current file
        jr      c, dir_5                        ; error? EOF

.dir_3
        call    ChkFormattedByte
        jr      z, dir_5                        ; unformatted? EOF

        push    bc
        push    hl
        call    GetHeaderByte
        call    PeekBHL                         ; first byte of filename
        pop     hl                              ; rewind position
        pop     bc
        or      a
        jr      z, dir_2                        ; deleted? get next

        ld      (ix+8), b                       ; store EPROM pointer
        ld      (ix+9), h
        ld      (ix+10), l

        call    GetHeaderByte                   ; filename length in C
        pop     de                              ; original BHL in ADE
        pop     af

.dir_4
        push    bc
        push    af
        ld      c, a
        call    PeekBHL
        ld      b, c
        OZ      GN_Wbe                          ; write A to BDE
        inc     de                              ; bump buffer position, no bank bump!
        pop     af
        pop     bc

        call    IncBHL                          ; bump EPROM pointer
        dec     c
        jr      nz, dir_4                       ; loop until filename done

        ld      b, a                            ; write trailing NULL
        xor     a
        OZ      GN_Wbe
        jr      dir_7                           ; exit

.dir_5
        ld      a, FN_FH                        ; free handle
        ld      b, HND_TEMP
        OZ      OS_Fn
        scf
        ld      a, RC_Eof

.dir_6
        pop     de                              ; fix stack
        pop     de

.dir_7
        ret

;       ----

;       check if card in slot 3 is EPROM
;
;OUT:   Fc=0 if success
;       Fc=1, A=error if fail
;chg:   AF....../....

.IsEPROM
        push    hl
        push    de
        push    bc
        ld      hl, $3FFD                       ; try poking subtype to see if it's RAM
        ld      b, $FF
        call    PeekBHL
        ld      e, a                            ; store old value
        cpl
        ld      d, a
        call    PokeBHL_epr
        call    PeekBHL
        cp      d
        ld      a, e
        jr      nz, ise_1                       ; not changed, ROM or EPROM

        call    PokeBHL_epr                     ; put original value back and exit
        jr      ise_5

.ise_1
        cp      b
        jr      z, ise_5                        ; unformatted?

        ld      d, a                            ; store subtype
        dec     hl
        call    PeekBHL
        ld      c, a                            ; store size
        xor     a
        sub     c
        ld      b, a                            ; -size, first bank
        jp      p, ise_5                        ; 2MB card?  not likely...

        ld      a, d                            ; find subtype in programming table
        ld      hl, EpromTypes
.ise_2
        bit     0, (hl)
        jr      nz, ise_5                       ; end? unknown type
        cp      (hl)
        jr      z, ise_4                        ; match? go on
        ld      de, 7                           ; otherwise try next
        add     hl, de
        jr      ise_2

.ise_4
        or      a                               ; !! unnecessary
        ld      (ubEpr_SubType), a              ; store EPROM variables
        ld      (pEpr_PrgTable), hl
        ld      a, b
        ld      (ubEpr_FirstBank), a
        ld      hl, $3FF7                       ; filing EPROM/application ROM
        ld      b, $FF
        call    PeekBHL
        ld      (ubEpr_Fstype), a
        or      a                               ; Fc=0
        jr      ise_6
.ise_5
        ld      a, RC_Fail
        scf
.ise_6
        pop     bc
        pop     de
        pop     hl
        ret

;       ----

;       find out programming model for this card
;
;OUT:   Fc=0, A=subtype, HL=programming model if ok
;       Fc=1, A=error if fail
;chg:   AFBCDEHL/....

.FormatCard
        push    iy
        ld      b, $FF                          ; subtype
        ld      hl, $3FFD
        ld      iy, EpromTypes
        call    IdentifyCardType                ; !! doesn't return B
        jp      c, fmt_8
        ld      e, a                            ; remember type

        ld      a, b                            ; find out card size
        sub     $C0                             ; !! as B is still $FF much of this is unnecessary
        inc     a                               ; !! A=$40, Fc=0
        ld      c, $80                          ; !! ends up $40
.fmt_1
        rl      a                               ; !! $80-$ff - exit
        jr      c, fmt_2
        rrc     c                               ; !! $40
        jr      fmt_1
.fmt_2
        ld      a, b                            ; !! A=$FF-$40=$3F
        sub     c

.fmt_3
        rrc     c                               ; try mirroring at 512/256/128/64/32 KB
        jr      c, fmt_5
        add     a, c                            ; check bank for mirroring
        ld      b, a                            ; remember new first bank
        call    PeekBHL
        cp      e
        jr      nz, fmt_4
        ld      a, b                            ; mirrored, loop
        jr      fmt_3

.fmt_4
        ld      a, b                            ; get last mirrored bank
        sub     c

.fmt_5
        rlc     c                               ; size in banks
        inc     a                               ; first bank
        ld      b, a
        push    bc

        ld      a, b                            ; !! unnecessary
        add     a, c
        dec     a                               ; last bank !! always $FF
        ld      b, a                            ; bank
        ld      a, c                            ; card size
        dec     hl
        call    BlowByte
        jr      c, fmt_7                        ; error? exit

        ld      hl, $3FFE                       ; "oz" identifier
        ld      a, 'o'
        call    BlowByte
        jr      c, fmt_7
        inc     hl
        ld      a, 'z'
        call    BlowByte
        jr      c, fmt_7
        ld      hl, $3FF7                       ; file system identifier !! just 'ld l,$f7'
        ld      a, 1
        call    BlowByte
        jr      c, fmt_7

        ld      hl, $3FF7                       ; fill 3fc0-3ff6 with zero
        ld      c, $37
.fmt_6
        push    bc
        dec     hl
        xor     a
        call    BlowByte
        pop     bc
        jr      c, fmt_7
        dec     c
        jr      nz, fmt_6
        dec     hl                              ; !! unnecessary

.fmt_7
        pop     bc
        jr      c, fmt_8                        ; error? exit

        ld      a, e                            ; subtype
        push    iy
        pop     hl                              ; programming model
        jr      fmt_9

.fmt_8
        push    af                              ; in case of error clear subtype
        xor     a
        ld      (ubEpr_SubType), a
        pop     af

.fmt_9
        pop     iy
        ret

;       ----

;       identify empty EPROM
;
;IN:    BHL=test address ($FF:3FFD, subtype)
;       IY=programming model table
;OUT:   Fc=0, A=type, IY=programmin model if success
;       Fc=1, A=error if fail
;chg:   AF....../..IY

.IdentifyCardType
        push    bc
        push    de

.ict_1
        bit     0, (iy+0)
        ld      a, RC_Fail
        scf
        jr      nz, ict_3                       ; end of table? exit

        ld      a, $fe                          ; try to clear low bit
        call    BlowByte
        jr      nc, ict_2                       ; success, write type
        ld      de, 7                           ; try next type
        add     iy, de
        jr      ict_1

.ict_2
        ld      a, (iy+0)                       ; subtype
        ld      e, a
        call    BlowByte
        jr      c, ict_3                        ; error, exit
        ld      a, e                            ; return subtype

.ict_3
        pop     de
        pop     bc
        ret

;       ----

;       find file in card
;IN:    HL=name
;OUT:   Fc=0, BHL=pointer to file
;       Fc=1, A=error if not found
;chg:   AFBCDEHL/....

.FindFile
        ld      d, h                            ; remember name
        ld      e, l

        ld      c, 0                            ; get filename length
.ff_1
        ld      a, (hl)
        cp      $21
        jr      c, ff_2                         ; space/ctrl char? end of name
        inc     c
        inc     hl
        jr      ff_1

.ff_2
        ld      a, c
        ld      (ubEpr_NameLen), a

        ld      a, (ubEpr_FirstBank)            ; start scanning at card start
        ld      b, a
        ld      hl, 0

.ff_3
        call    ChkFormattedByte
        jr      z, ff_10                        ; unformatted? end of files

        push    bc                              ; remember EPROM pointer
        push    hl

        call    GetHeaderByte                   ; name length into C
        ld      a, (ubEpr_NameLen)
        cp      c
        jr      z, ff_4                         ; length matches? compare names
        scf
        jr      ff_9                            ; skip this file


.ff_4
        push    de                              ; remember name

.ff_5
        ld      a, (de)                         ; uppercase searched name char
        inc     de
        cp      $21                             ; !! use 'ccf; jr nc,...' for clarity
        jr      c, ff_8                         ; name end? found file
        OZ      GN_Cls
        jr      nc, ff_6                        ; not alpha
        and     $df                             ; upper()
.ff_6
        ld      c, a

        call    PeekBHL                         ; uppercase EPROM name char
        call    IncBHL
        OZ      GN_Cls
        jr      nc, ff_7                        ; not alpha
        and     $df                             ; upper()

.ff_7
        cp      c
        jr      z, ff_5                         ; match, continue compare

        or      a                               ; Fc=1 after ccf !! scf for clarity

.ff_8
        ccf
        pop     de                              ; restore name

.ff_9
        pop     hl                              ; restore EPROM pointer
        pop     bc
        jr      nc, ff_11                       ; no error? exit

        push    de                              ; else skip file and check next
        call    SkipFile
        pop     de
        jr      nc, ff_3

.ff_10
        ld      a, RC_Onf                       ; object not found
        scf

.ff_11
        ret

;       ----

;       check EPROM position for $FF
;
;IN:    BHL=EPROM pointer
;OUT:   Fz=0 if byte not $FF
;       Fz=1 if it is $FF, unformatted
;chg:   AF....../....

.ChkFormattedByte
        call    PeekBHL
        inc     a
        ret     nz                              ; not FF? exit with Fz=0

        ld      a, (ubEpr_Fstype)
        bit     0, a
        jr      z, cfb_1                        ; use 3-byte header format
        xor     a                               ; Fz=1
        ret

.cfb_1
        push    bc
        push    hl
        call    IncBHL                          ; skip two bytes and try again
        call    IncPeekBHL
        pop     hl
        pop     bc
        ret     z                               ; !! bug: Peek doesn't return meaningful flags
        inc     a                               ; Fz=1 if $FF
        ret

;       ----

;       gets header byte, handles 3-byte header format
;
;IN:    BHL=EPROM pointer
;OUT:   A=C=byte
;chg:   AF.C..../....

.GetHeaderByte
        ld      a, (ubEpr_Fstype)
        bit     0, a
        jr      z, ghb_1                        ; not filing EPROM? use 3-byte header
        call    PeekBHL
        jr      ghb_2

.ghb_1
        call    IncBHL                          ; skip 2 bytes before reading byte
        call    IncPeekBHL

.ghb_2
        call    IncBHL                          ; bump pointer
        ld      c, a
        ret

;       ----

;       skip file name and return file size
;
;IN:    BHL=EPROM pointer
;OUT:
;chg

.GetFileSize
        ld      a, (ubEpr_Fstype)
        bit     0, a
        jr      z, gfs_1                        ; use 3-byte header format

        call    PeekBHL                         ; name length
        inc     a                               ; + delete byte
        ld      e, a
        ld      d, 0                            ; !! should zero C too
        call    AddBHL_CDE                      ; skip name

        call    PeekBHL                         ; get file size into CDE
        ld      e, a
        call    IncPeekBHL
        ld      d, a
        call    IncPeekBHL
        ld      c, a
        call    IncBHL
        jr      IncBHL                          ; skip one byte and exit

.gfs_1
        call    PeekBHL                         ; get file size into DE
        ld      e, a
        call    IncPeekBHL
        ld      d, a

        call    IncPeekBHL                      ; get name length
        call    IncBHL                          ; skip delete byte !! why not 'inc a'
        push    de                              ; remember size
        ld      e, a
        ld      d, 0
        ld      c, d
        call    AddBHL_CDE                      ; skip file name

        pop     de                              ; restore length !! ld c,d before pop
        ld      c, 0
        ret

;       ----

;       increment BHL, handle bank change

.IncBHL
        inc     hl
        bit     6, h
        ret     z
        res     6, h
        inc     b
        ret
;       ----

;       skip file data

.SkipFile
        call    GetFileSize

;       ----

;       BHL+=CDE, handle bank crossing

.AddBHL_CDE
        ld      a, h
        and     $3F
        ld      h, a
        xor     a
        add     hl, de
        adc     a, c
        jr      c, add_4                        ; overflow? error

        rlca                                    ; A*4 for bank
        jr      c, add_4
        rlca
        jr      c, add_4

        bit     7, h                            ; add HL high bits to A
        jr      z, add_1
        res     7, h
        add     a, 2
        jr      c, add_4
.add_1
        bit     6, h
        jr      z, add_2
        res     6, h
        add     a, 1
        jr      c, add_4

.add_2
        add     a, b
        jr      c, add_4
        ld      b, a
        inc     a
        jr      nz, add_3                       ; not last bank? exit

        ld      a, h                            ; error if last page
        cp      $3F
        ccf

.add_3
        ret     nc

.add_4
        ld      a, RC_Room
        ret

;       ----

;       go to   end of used area
;
;chg:   AFB...HL/....

.GotoEnd
        ld      a, (ubEpr_FirstBank)            ; start from beginning
        ld      b, a
        ld      hl, 0
.ge_1
        call    ChkFormattedByte
        jr      z, ge_2                         ; unformatted? exit
        call    SkipFile
        jr      nc, ge_1                        ; skip next !! should this report error instead of Fc=0
.ge_2
        or      a                               ; Fc=0
        ret

;       ----

.EpromTypes
        defb $7E                                ; subtype
        defb PD_312us|BM_EPRSE3D                ; BL_EPR before data byte, prefixed by following
        defb BM_COMOVERP|BM_COMPROGRAM          ; ORed into BL_COM
        defb 0                                  ; BL_EPR after data byte, prefixed by following
        defb 0                                  ; ORed into BL_COM
        defb PD_312us|BM_EPRSE3D                ; BL_EPR before overwrite, prefixed by following
        defb BM_COMOVERP|BM_COMPROGRAM          ; ORed into BL_COM

        defb $7C
        defb PD_312us|BM_EPRPGMD|BM_EPRSE3D|BM_EPRSE3P
        defb BM_COMPROGRAM
        defb 0
        defb 0
        defb PD_312us|BM_EPRPGMD|BM_EPRSE3D|BM_EPRSE3P
        defb BM_COMPROGRAM

        defb $7A
        defb PD_312us|BM_EPRPGMD|BM_EPRSE3D|BM_EPRSE3P
        defb BM_COMOVERP|BM_COMPROGRAM
        defb 0
        defb 0
        defb PD_312us|BM_EPRPGMD|BM_EPRSE3D|BM_EPRSE3P
        defb BM_COMOVERP|BM_COMPROGRAM

        defb 1

;       ----

;       write memory to EPROM
;
;IN:    C=number of bytes to write
;       DE=source address
;       BHL=EPROM pointer
;OUT:   Fc=0 if success
;       Fc=1, A=error if fail
;chg:   AFBC..HL/....

.BlowMem
        push    iy
        push    de

        ld      iy, (pEpr_PrgTable)
        ld      a, BM_COMLCDON                  ; turn LCD off
        call    AndCom

.blowm_1
        ld      a, (de)                         ; write byte to EPROM
        inc     de
        call    BlowByte
        jr      c, blowm_2                      ; error? exit
        call    IncBHL
        dec     c
        jr      nz, blowm_1                     ; bytes left? loop
        or      a                               ; Fc=0

.blowm_2
        push    af
        ld      a, BM_COMLCDON                  ; turn LCD on
        call    OrCom
        pop     af
        pop     de
        pop     iy
        ret

;       ----

;       write byte to EPROM
;
;IN:    A=byte
;       BHL=EPROM pointer
;OUT:   Fc=0 if write succesfull
;       Fc=1, A=error if fail
;chg:   AF....../....

.BlowByte
        push    bc
        push    de
        ld      d, a                            ; store data

        call    PeekBHL
        cp      d
        jr      z, blow_6                       ; already there? exit

        ld      c, 24                           ; 24 attempts

.blow_1
        ld      a, BM_COMOVERP|BM_COMPROGRAM
        call    AndCom
        ld      a, (iy+2)                       ; pre-data parameters
        or      BM_COMVPPON
        call    OrCom
        ld      a, (iy+1)
        out     (BL_EPR), a

        ld      a, d                            ; write data
        call    PokeBHL_epr

        ld      a, BM_COMOVERP|BM_COMPROGRAM|BM_COMVPPON
        call    AndCom
        ld      a, (iy+4)                       ; post-data parameters
        call    OrCom
        ld      a, (iy+3)
        out     (BL_EPR), a

        call    PeekBHL                         ; verify data
        cp      d
        jr      z, blow_2                       ; write succesfull

        dec     c
        jr      nz, blow_1                      ; retry

        ld      a, BM_COMOVERP|BM_COMPROGRAM|BM_COMVPPON
        call    AndCom
        scf
        ld      a, RC_Fail
        jr      blow_7

.blow_2
        ld      a, BM_COMOVERP|BM_COMPROGRAM|BM_COMVPPON
        call    AndCom
        ld      a, (iy+6)                       ; overwrite parameters
        or      BM_COMVPPON
        call    OrCom
        ld      a, (iy+5)
        out     (BL_EPR), a

        ld      a, 25
        sub     c
        ld      c, a                            ; used this many tries
        bit     BB_COMOVERP, (iy+2)
        jr      z, blow_3                       ; overprogramming? use three times that many
        sla     a
        add     a, c
        ld      c, a
        jr      blow_4

.blow_3
        ld      a, BM_COMOVERP                  ; force overprogramming
        call    OrCom

.blow_4
        ld      a, d                            ; write data C times
.blow_5
        call    PokeBHL_epr
        dec     c
        jr      nz, blow_5

        ld      a, BM_COMOVERP|BM_COMPROGRAM|BM_COMVPPON
        call    AndCom
.blow_6
        or      a                               ; Fc=0
.blow_7
        pop     de
        pop     bc
        ret

;       ----

;       set/reset bits in BL_COM

.OrCom
        push    bc
        call    chgcom_1                        ; get old bits
        or      b                               ; or in new ones
        jr      chgcom_x                        ; write

.AndCom
        cpl                                     ; reverse bit mask
        push    bc
        call    chgcom_1                        ; get old bits
        and     b                               ; and out new ones

.chgcom_x
        ld      (BLSC_COM), a
        out     (BL_COM), a
        ex      af, af'
        call    OZ_EI
        pop     bc
        ret

.chgcom_1
        ld      b, a                            ; new bits into B
        call    OZ_DI
        ex      af, af'
        ld      a, (BLSC_COM)                   ; old bits into A
        ret
