; **************************************************************************************************
; OS_EPR System Call (File Area functionality on UV Eprom or Flash).
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
; (C) Gunther Strube (gbs@users.sf.net), 2005-2007
;
; Copyright of original (binary) implementation, V4.0:
; (C) 1987,88 by Trinity Concepts Limited, Protechnic Computers Limited & Operating Systems Limited.
;
; $Id$
; ***************************************************************************************************

        Module  OS_EPR

        include "blink.def"
        include "error.def"
        include "fileio.def"
        include "memory.def"
        include "handle.def"
        include "saverst.def"
        include "time.def"
        include "sysvar.def"
        include "interrpt.def"
        include "card.def"

        xref PutOSFrame_BHL                     ; misc5.asm
        xref PutOSFrame_CDE                     ; misc5.asm
        xref PutOSFrame_DE, PutOSFrame_HL       ; misc5.asm
        xref PeekBHL, PokeBHL, IncBHL           ; misc5.asm
        xref FileEprRequest                     ; osepr/eprreqst.asm
        xref FileEprFetchFile                   ; osepr/eprfetch.asm
        xref FileEprFindFile                    ; osepr/eprfndfl.asm
        xref FileEprFirstFile                   ; osepr/eprffrst.asm
        xref FileEprPrevFile                    ; osepr/eprfprev.asm
        xref FileEprNextFile                    ; osepr/eprfnext.asm
        xref FileEprLastFile                    ; osepr/eprflast.asm
        xref FileEprTotalSpace                  ; osepr/eprtotsp.asm
        xref FileEprActiveSpace                 ; osepr/epractsp.asm
        xref FileEprFreeSpace                   ; osepr/eprfresp.asm
        xref FileEprCntFiles                    ; osepr/eprcntfl.asm
        xref FileEprFileStatus                  ; osepr/eprfstat.asm
        xref FileEprNewFileEntry                ; osepr/eprfnew.asm
        xref FileEprFileSize                    ; osepr/eprfsize.asm
        xref FileEprFilename                    ; osepr/eprfname.asm
        xref FileEprFileImage                   ; osepr/eprfimage.asm
        xref FileEprSaveRamFile                 ; osepr/eprfsave.asm
        xref FileEprDeleteFile                  ; osepr/eprfdel.asm
        xref FlashEprFileFormat                 ; osfep/fepflfmt.asm

        xdef OSEpr
        xdef GetSlotNo
        xdef GetUvProgMode
        xdef BlowByte, BlowMem


;       On entry: we have OSFrame so remembering S2 is unnecessary, as is remembering IY
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
        jp      ozFileEprRequest                ; 06, EP_Req    (OZ 4.2 and newer)
        jp      FileEprFetchFile                ; 09, EP_Fetch  (OZ 4.2 and newer)
        jp      ozFileEprFindFile               ; 0c, EP_Find   (OZ 4.2 and newer)
        jp      EprDir                          ; 0f, EP_Dir
        jp      ozFileEprFirstFile              ; 12, EP_First  (OZ 4.2 and newer)
        jp      ozFileEprPrevFile               ; 15, EP_Prev   (OZ 4.2 and newer)
        jp      ozFileEprNextFile               ; 18, EP_Next   (OZ 4.2 and newer)
        jp      ozFileEprLastFile               ; 1b, EP_Last   (OZ 4.2 and newer)
        jp      ozFileEprTotalSpace             ; 1e, EP_TotSp  (OZ 4.2 and newer)
        jp      ozFileEprActiveSpace            ; 21, EP_ActSp  (OZ 4.2 and newer)
        jp      ozFileEprFreeSpace              ; 24, EP_FreSp  (OZ 4.2 and newer)
        jp      ozFileEprCntFiles               ; 27, EP_Count  (OZ 4.2 and newer)
        jp      ozFileEprFileStatus             ; 2a, EP_Stat   (OZ 4.2 and newer)
        jp      ozFileEprFileSize               ; 2d, EP_Size   (OZ 4.2 and newer)
        jp      ozFileEprFilename               ; 30, EP_Name   (OZ 4.2 and newer)
        jp      ozFileEprFileImage              ; 33, EP_Image  (OZ 4.2 and newer)
        jp      ozFileEprNewFileEntry           ; 36, EP_New    (OZ 4.2 and newer)
        jp      ozFileEprSaveRamFile            ; 39, EP_SvFl   (OZ 4.2 and newer)
        jp      FileEprDeleteFile               ; 3c, EP_Delete (OZ 4.2 and newer)
        jp      FormatCard                      ; 3f, EP_Format (OZ 4.2 and newer)
        jp      ozBlowMem                       ; 42, EP_WrBlk  (OZ 4.2 and newer)



; ***************************************************************************************************
; EP_Req interface:
;
; In:
;       C = poll for file header in slot number 0, 1, 2 or 3
; Out:
;       BHL = pointer to File Header for slot C (B = absolute bank of slot).
;             (or pointer to free space in potential new File Area).
;         C = size of File Eprom Area in 16K banks
;       Fz = 1, File Header found
;            A = "oz" File Eprom sub type
;
.ozFileEprRequest
        call    FileEprRequest
        ret     c
        ld      (iy+OSFrame_A),A                ; return "oz" File Area sub type (if file header found)
        ld      (iy+OSFrame_C),C                ; return C = size of File Eprom Area in 16K banks
        ld      (iy+OSFrame_D),D                ; return D = size of physical card in 16K banks
        jr      ret_bhl_fz                      ; return BHL = pointer to File Header for slot C (B = absolute bank of slot)
                                                ; Fz = 0, no header found, F already 0 in (iy+OSFrame_F), otherwise header found.

; ***************************************************************************************************
.ozFileEprFindFile
        call    FileEprFindFile
        ret     c
.ret_bhl_fz
        call    PutOSFrame_BHL                  ; return BHL = pointer to found File entry or pointer to free byte in File area
.ret_fz
        ret     nz                              ; Fz = 0 is returned by default in OS_Epr interface...
        set     Z80F_B_Z,(iy+OSFrame_F)         ; return Fz = 1
        ret


; ***************************************************************************************************
.ozFileEprFirstFile
        call    FileEprFirstFile
        ret     c                               ; return BHL = pointer to first file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
        jr      ret_bhl_fz                      ; return Fz = 1, File Entry marked as deleted, otherwise active.


; ***************************************************************************************************
.ozFileEprPrevFile
        call    FileEprPrevFile
        ret     c                               ; return BHL = pointer to previous file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
        jr      ret_bhl_fz                      ; return Fz = 1, File Entry marked as deleted, otherwise active.


; ***************************************************************************************************
.ozFileEprNextFile
        call    FileEprNextFile                 ; return BHL = pointer to next file entry or first byte of empty space
        jr      ret_bhl_fz                      ; return Fz = 1, File Entry marked as deleted, otherwise active.


; ***************************************************************************************************
.ozFileEprLastFile
        call    FileEprLastFile
        ret     c                               ; return BHL = pointer to last file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
        jr      ret_bhl_fz                      ; return Fz = 1, File Entry marked as deleted, otherwise active.


; ***************************************************************************************************
.ozFileEprTotalSpace
        call    FileEprTotalSpace
        ret     c
        call    PutOSFrame_BHL                  ; return BHL = Amount of active file space in bytes (24bit integer, B = MSB)
.ret_cde
        jp      PutOSFrame_CDE                  ; return CDE = Amount of deleted file space in bytes (24bit integer, C = MSB)


; ***************************************************************************************************
.ozFileEprActiveSpace
        call    FileEprActiveSpace
        ret     c
.ret_bcde
        ld      (iy+OSFrame_B),b
        jr      ret_cde                         ; return DEBC = Active space (visible files) (DE=high, BC=low)


; ***************************************************************************************************
.ozFileEprFreeSpace
        call    FileEprFreeSpace
        ret     c
        jr      ret_bcde                        ; return DEBC = Free space (DE=high, BC=low)


; ***************************************************************************************************
.ozFileEprCntFiles
        call    FileEprCntFiles
        ret     c
        call    PutOSFrame_DE
        jp      PutOSFrame_HL                   ; return HL = total of active files, DE = total of deleted files


; ***************************************************************************************************
.ozFileEprFileStatus
        call    FileEprFileStatus
        ret     c
        jr      ret_fz                          ; return Fz status (if file entry is marked as deleted or not)


; ***************************************************************************************************
.ozFileEprNewFileEntry
        call    FileEprNewFileEntry
        ret     c
        jr      ret_bhl_fz                      ; return BHL that is pointer to potential new file entry


; ***************************************************************************************************
.ozFileEprFileSize
        call    FileEprFileSize
        ret     c
        call    PutOSFrame_CDE                  ; return file entry size in CDE
        jr      ret_fz                          ; return File status (active/deleted) in Fz


; ***************************************************************************************************
.ozFileEprFilename
        call    FileEprFilename
        ret     c
        ld      (iy+OSFrame_A),a                ; return length of copied filename
        jr      ret_fz                          ; return File status (active/deleted) in Fz


; ***************************************************************************************************
.ozFileEprFileImage
        call    FileEprFileImage
        ret     c
        jr      ret_bhl_fz                      ; return BHL that is pointer to file entry image (contents)


; ***************************************************************************************************
.ozFileEprSaveRamFile
        call    FileEprSaveRamFile
        ret     c
        jr      ret_bhl_fz                      ; return BHL pointer to file entry


; ***************************************************************************************************
; Blow block of data to UV Eprom in slot 3.
; Screen will be switched off during operation.
;
; IN:
;       C = Blowing algorithm context (also known as File Area sub type)
;       DE = source address (local address space pointer)
;       IX = length of block
;       BHL = destination address in slot 3
; OUT:
;       Fc = 0 (block blown successfully to UV Eprom)
;               BHL updated
;       Fc = 1,
;               A = RC_BWR (write error)
;               A = RC_Onf (unknown blowing algorithm context)
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.ozBlowMem
        push    ix                              ; preserve IX
        push    ix
        exx
        pop     bc
        exx
        ld      a,c
        call    GetUvProgHandle
        pop     ix
        ret     c                               ; unknown blowing algorithm context
        call    BlowMem
        jr      ret_bhl_fz                      ; return updated BHL pointer (end of block +1) or error status


; ***************************************************************************************************
; Get slot number C (embedded in Bank number B).
;
; In:
;       B = absolute bank number
; Out:
;       C = slot number which bank B is part of
;
; Registers changed after return:
;    AFB.DEHL/IXIY same
;    ...C..../.... different
;
.GetSlotNo
        push    af
        ld      a,b
        and     @11000000
        rlca
        rlca
        ld      c,a                             ; slot C (of bank B)
        pop     af
        ret


; ***************************************************************************************************
; Read file from File Area in slot 3
;
;IN:    BHL = source filename
;       IX = output file handle
;OUT:   Fc=0, file fetched successfully to RAM file
;       Fc=1, A=error if fail
;chg:   AFBCDEHL/....

.EprLoad
        call    IsEPROM
        ret     c                               ; not EPROM? exit

        ld      b, 0                            ; bind source in
        OZ      OS_Bix
        push    de                              ; remember S1/S2

        OZ      GN_Pfs                          ; parse filename segment

        ex      de,hl
        ld      c,3                             ; EP_LOAD always in slot 3
        call    FileEprFindFile
        jr      c, ld_4                         ; no file area? exit
        jr      z, ld_5
        ld      a,RC_Onf                        ; "file not found"
        scf
        jr      ld_4
.ld_5
        call    FileEprFetchFile
.ld_4
        pop     de                              ; restore S1/S2
        push    af
        OZ      OS_Box
        pop     af
        ret


; ***************************************************************************************************
; Write file to File Area in slot 3
;
;IN:    HL=filename
;OUT:   Fc=0, success
;       Fc=1, A=error if fail
;chg:   AFBCDEHL/....
;
defc    IObuffer = 256
.EprSave
        ld      b, 0
        push    ix

        OZ      OS_Bix                          ; bind in HL
        push    de                              ; remember S1/S2

.check_fepr
        call    IsEPROM
        jr      nc, found_fepr                  ; File EPROM identified

        push    hl                              ; (preserve filename pointer while formatting header)
        ld      c,3
        call    FormatCard                      ; no File header found, try to create file header in slot 3
        pop     hl
        jp      c, sv_11                        ; error? exit
        jr      check_fepr
.found_fepr
        exx
        ld      hl, 0                           ; reserve 256 bytes from stack for I/O buffer
        add     hl, sp
        ex      de, hl                          ; current SP in DE...
        ld      hl, -IObuffer
        add     hl, sp
        ld      sp, hl
        push    de                              ; preserve old SP
        push    hl
        exx
        pop     iy                              ; IY points at base of buffer

        push    hl
        pop     ix                              ; pointer to original filename

        ld      b, 0
        OZ      GN_Pfs                          ; skip path

        ex      de,hl
        ld      c,3                             ; EP_SAVE always in slot 3
        call    FileEprFindFile                 ; find earlier version (to be marked as deleted later)
        push    af                              ; and remember found status
        push    bc
        push    hl

        ld      c,3                             ; blow file to slot 3
        push    ix
        pop     hl                              ; pointer to RAM filename (to blow to file area)
        push    iy
        pop     de                              ; pointer to base of I/O buffer
        ld      ix,IObuffer                     ; size of I/O buffer
        call    FileEprSaveRamFile

        pop     hl                              ; get old file entry (if previously found)
        pop     bc
        pop     de
        jr      c, sv_10                        ; error writing new file?

        bit     Z80F_B_Z,E
        jr      z, sv_10                        ; no earlier version (Fz = 0)?

        call    FileEprDeleteFile               ; new version saved, mark old file entry as deleted (in BHL)
        or      a
.sv_10
        pop     hl
        ld      sp, hl                          ; restore stack
.sv_11
        pop     de                              ; restore S1/S2
        push    af
        OZ      OS_Box
        pop     af
        pop     ix
        ret


; ***************************************************************************************************
; Get next filename from File Area
;
;IN:    BHL=buffer
;       IX=temp handle, if 0 then start at beginning
;OUT:   Fc=0, success
;       Fc=1, fail
;chg:   AFBCDEHL/....

.EprDir
        call    IsEPROM
        ret     c                               ; not EPROM? exit

        push    bc
        push    hl                              ; preserve BHL buffer pointer

        push    ix
        pop     de
        ld      a, d
        or      e
        jr      nz, check_handle                ; IX not 0? continue

        ld      a, FN_AH                        ; allocate temp handle
        ld      b, HND_TEMP
        OZ      OS_Fn
        jr      c, exit_EprDir                  ; error? exit

        ld      c,3                             ; EP_Dir always reads from slot 3
        call    FileEprFirstFile                ; return BHL to first file entry in slot
        jr      z, get_next_fe                  ; deleted file entry? then get next entry
        jr      update_handle_ptr
.check_handle
        ld      a, FN_VH                        ; verify handle
        ld      b, HND_TEMP
        OZ      OS_Fn
        jr      c, exit_EprDir                  ; error? exit

        ld      b, (ix+8)                       ; get current File Entry pointer through handle
        ld      h, (ix+9)
        ld      l, (ix+10)
.get_next_fe
        call    FileEprNextFile                 ; get pointer to next file entry in BHL
        jr      c, free_temp_handle             ; error? EOF
        jr      z, get_next_fe                  ; deleted file entry? skip this one and get next entry
.update_handle_ptr
        ld      (ix+8), b                       ; store File Entry pointer for next EP_Dir
        ld      (ix+9), h                       ; in allocated handle memory
        ld      (ix+10), l

        pop     de
        pop     af
        ld      c,a                             ; CDE is pointer to buffer
        jp      FileEprFileName                 ; get filename from file entry into buffer and exit EP_Dir
.free_temp_handle
        ld      a, FN_FH                        ; free handle
        ld      b, HND_TEMP
        OZ      OS_Fn
        scf
        ld      a, RC_Eof
.exit_EprDir
        pop     de                              ; fix stack
        pop     de
        ret


; ***************************************************************************************************
; Check if card in slot 3 contains a File Area
;
;OUT:   Fc=0 if success
;       Fc=1, A=error if fail
;chg:   AF....../....

.IsEPROM
        push    hl
        push    de
        push    bc

        ld      c,3
        call    FileEprRequest                  ; poll for file area in slot 3

        pop     bc
        pop     de
        pop     hl
        ret


; ***************************************************************************************************
; Get "handle" to UV Eprom programming mode settings for current UV Eprom, fetching
; sub type from File Area in slot 3.
;
; In:
;         None
; Out:
;         Fc = 0,
;               Success, return IX as "handle" (to point at UV programming) settings of sub type:
;         Fc = 1,
;               A = RC_Onf. Sub type not recognized for UV Eprom
;
; Registers changed after return:
;    ..BCDEHL/..IY same
;    AF....../IX.. different
;
.GetUvProgMode
        call    IsEPROM                         ; poll for file area in slot 3
        ret     c                               ; no "oz" header found
        jr      z, GetUvProgHandle              ; header found, A = sub type...
        ld      a, RC_Onf
        scf
        ret


; ***************************************************************************************************
; Get "handle" to UV Eprom programming mode settings for current UV Eprom, by specifying
; sub type ($7E, $7C or $7A).
;
; In:
;         A = sub type
; Out:
;         Fc = 0,
;               Success, return IX as "handle" (to point at UV programming) settings of sub type:
;         Fc = 1,
;               A = RC_Onf. Sub type not recognized for UV Eprom
;
; Registers changed after return:
;    ..BCDEHL/..IY same
;    AF....../IX.. different
;
.GetUvProgHandle
        push    hl
        push    de
        push    bc

        ld      de, 7                           ; each entry is 7 bytes...
        ld      ix, UvEpromTypes                ; find subtype in programming table
.ise_2
        bit     0, (ix+0)
        jr      nz, ise_5                       ; end? unknown type
        cp      (ix+0)
        jr      z, exit_GetUvProgMode           ; match?
        add     ix, de
        jr      ise_2
.ise_5
        ld      a, RC_Onf
        scf
.exit_GetUvProgMode
        pop     bc
        pop     de
        pop     hl
        ret


; ***************************************************************************************************
; Create file area header in UV Eprom card (or Flash card, if available) in slot C.
; On UV Eprom, on the header is created - on Flash, the complete file area is formatted.
;
; IN:
;       C = slot
;OUT:   Fc=0, File Area formatted (either Flash or UV Eprom) in slot 3.
;       Fc=1, A=error if fail
;chg:   AFBCDEHL/IX..
;
.FormatCard
        push    bc
        call    FileEprRequest                  ; poll for potential file area in slot C
        pop     bc
        ret     z                               ; "oz" file header was found, no need to format anything...

        push    bc
        call    FlashEprFileFormat              ; first try to format a file area, assuming a flash card is inserted in slot X
        pop     bc
        ret     nc                              ; flash card formatted with an "oz" file header!

        ld      a,3
        cp      c                               ; using slot 3 for UV EPROM?
        jr      z, blow_uvhdr
        ld      a,RC_BWR                        ; a header cannot be blown on UV EPROM in slots 0-2
        scf
        ret
.blow_uvhdr
        call    FileEprRequest                  ; poll for potential file area in slot C
        jr      nc, create_uv_hdr               ; create a sub file area (below application area)
        ld      b,$ff                           ; card is empty, create file header at top of card
.create_uv_hdr
        ld      hl, $3FFD                       ; point at sub type byte in potential header (B points at bank)
        ld      ix, UvEpromTypes
        call    IdentifyCardType                ; try to blow bytes to UV Eprom to identify type
        ret     c
        ld      e, a                            ; a byte was blown successfully to UV Eprom, remember returned type

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

        ld      hl, CH_TAG                      ; "oz" identifier
        ld      a, 'o'
        call    BlowByte
        jr      c, fmt_7
        inc     hl
        ld      a, 'z'
        call    BlowByte
        jr      c, fmt_7

        ld      l, $F7                          ; file system identifier at $3ff7
        ld      a, 1
        call    BlowByte
        jr      c, fmt_7

        ld      a, SR_RND
        OZ      OS_Sr
        push    de
        push    bc
        ld      hl, 0
        add     hl, sp
        ex      de, hl
        ld      bc, $FF04                       ; blow 4 byte random ID
        ld      hl, $3ff8                       ; at FF 3FF8
.blow_randomid
        ld      a,(de)
        call    BlowByte
        jr      c, rid_err
        inc     de
        inc     hl
        dec     c
        jr      nz,blow_randomid
        cp      a                               ; Fc = 0
.rid_err
        pop     hl                              ; purge stack
        pop     hl
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
.fmt_7
        pop     bc
        ret     c                               ; error? exit

        ld      a, e                            ; return A = subtype, IX = UV programming handle
        ret


; ***************************************************************************************************
; Identify empty UV EPROM by trying to blow the sub type of the File Area header.
;
;IN:    BHL=test address ($FF:3FFD, subtype)
;       IX = handle to UV Eprom programming settings
;OUT:   Fc=0, A=type, IX = handle to UV EProm programming settings
;       Fc=1, A=error if fail
;chg:   AF....../IX..

.IdentifyCardType
        push    bc
        push    de
.ict_1
        bit     0, (ix+0)
        ld      a, RC_Fail
        scf
        jr      nz, ict_3                       ; end of table? exit

        ld      a, $fe                          ; try to clear low bit
        call    BlowByte
        jr      nc, ict_2                       ; success, write type
        ld      de, 7                           ; try next type
        add     ix, de
        jr      ict_1
.ict_2
        ld      a, (ix+0)                       ; subtype
        ld      e, a
        call    BlowByte
        jr      c, ict_3                        ; error, exit
        ld      a, e                            ; return subtype
.ict_3
        pop     de
        pop     bc
        ret


; ***************************************************************************************************
; Write memory block to UV EPROM
;
;IN:    BC'=number of bytes to write
;       DE=source address
;       IX = handle to UV Eprom programming settings
;       BHL=EPROM pointer
;OUT:   Fc=0 if success
;       Fc=1, A=error if fail
;chg:   AFBC..HL/....

.BlowMem
        push    de

        ld      a, BM_COMLCDON                  ; turn LCD off
        call    AndCom
.blowm_1
        push    bc
        ld      b,0                             ; (local source pointer)
        ex      de,hl
        call    PeekBHL                         ; get byte from (DE)
        inc     hl
        ex      de,hl
        pop     bc
        call    BlowByte                        ; to be written to EPROM at (BHL)
        jr      c, blowm_2                      ; error? exit
        call    IncBHL
        exx
        dec     bc
        ld      a,b
        or      c
        exx
        jr      nz, blowm_1                     ; bytes left? loop
.blowm_2
        push    af
        ld      a, BM_COMLCDON                  ; turn LCD on
        call    OrCom
        pop     af
        pop     de
        ret


; ***************************************************************************************************
; Write byte to UV EPROM
;
;IN:    A=byte
;       BHL=EPROM pointer
;       IX = handle to UV Eprom programming settings
;OUT:   Fc=0 if write succesfull
;       Fc=1, A=RC_BWR
;chg:   AF....../....
;
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
        ld      a, (ix+2)                       ; pre-data parameters
        or      BM_COMVPPON
        call    OrCom
        ld      a, (ix+1)
        out     (BL_EPR), a

        ld      a, d                            ; write data
        call    PokeBHL

        ld      a, BM_COMOVERP|BM_COMPROGRAM|BM_COMVPPON
        call    AndCom
        ld      a, (ix+4)                       ; post-data parameters
        call    OrCom
        ld      a, (ix+3)
        out     (BL_EPR), a

        call    PeekBHL                         ; verify data
        cp      d
        jr      z, blow_2                       ; write succesfull

        dec     c
        jr      nz, blow_1                      ; retry

        ld      a, BM_COMOVERP|BM_COMPROGRAM|BM_COMVPPON
        call    AndCom
        scf
        ld      a, RC_BWR
        jr      blow_7
.blow_2
        ld      a, BM_COMOVERP|BM_COMPROGRAM|BM_COMVPPON
        call    AndCom
        ld      a, (ix+6)                       ; overwrite parameters
        or      BM_COMVPPON
        call    OrCom
        ld      a, (ix+5)
        out     (BL_EPR), a

        ld      a, 25
        sub     c
        ld      c, a                            ; used this many tries
        bit     BB_COMOVERP, (ix+2)
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
        call    PokeBHL
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


; ***************************************************************************************************
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
        ei
        pop     bc
        ret

.chgcom_1
        ld      b, a                            ; new bits into B
        di                                      ; avoid slot polling during blowing of byte
        ld      a, (BLSC_COM)                   ; old bits into A
        ret


; ***************************************************************************************************
; Sub types, used to define UV programming method in slot 3:
;        7E: 32K               01111110
;        7C: 128K, 256K        01111100
;        7A: Unknown           01111010
; Flash sub types (returned as abstractions in OS_Epr, EP_Req), only used to differentiate that it
; is not an UV Eprom (not in this table for UV Eprom only):
;        77: Intel Flash       01110111
;        6F: AMD Flash         01101111
;
.UvEpromTypes
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
