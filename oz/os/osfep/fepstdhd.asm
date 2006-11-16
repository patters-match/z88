        module FlashEprStdFileHeader

; **************************************************************************************************
; OZ Flash Memory Management.
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
; $Id$
; ***************************************************************************************************

        xdef FlashEprStdFileHeader

        lib SafeBHLSegment, Divu8
        xref FlashEprWriteBlock

        include "saverst.def"
        include "memory.def"


;***************************************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Blow File Eprom "oz" header on Flash Eprom, in specified bank (which is part of the slot that
; the Flash Memory Card have been inserted into).
;
; Traditional File Eprom's use the whole card with file area header in top bank $3F.
;
; Pseudo File Cards might be part of Application cards below the reserved application area (as
; specified by the ROM Front DOR), or above the reserved application area.
;
; This routine might be supplied with a pre-fabricated 64-byte header, or be instructed to
; auto-generate and blow it to the specified bank. If a pre-fabricated header is supplied, then
; it will be temporarily copied to the system stack (somewhere in lower 8K RAM) and blown from
; there. Applications need not to worry about 16K segmentation issues.
;
; The format of a standard 'oz' file header is as follows:
; ------------------------------------------------------------------------------
; $3FC0       $00's until
; $3FF7       $01
; $3FF8       4 byte random id
; $3FFC       size of card in banks (2=32K, 8=128K, 16=256K, 64=1Mb)
; $3FFD       sub-type, $7E for 32K cards, and $7C for 128K (or larger) cards
; $3FFE       'o'
; $3FFF       'z' (file eprom identifier, lower case 'oz')
; ------------------------------------------------------------------------------
; in hex dump (example):
; 00003fc0h: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ; ................
; 00003fd0h: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ; ................
; 00003fe0h: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 ; ................
; 00003ff0h: 00 00 00 00 00 00 00 01 73 D1 4B 3C 02 7E 6F 7A ; ........s?<.~oz
; ------------------------------------------------------------------------------
;
; Important:
; Third generation AMD Flash Memory chips may be programmed in all available slots (1-3).
; Only INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3 to successfully blow
; the File Eprom header on the memory chip. If the Flash Eprom card is inserted in slot 1 or 2,
; this routine will report a programming failure.
;
; It is the responsibility of the application (before using this call) to evaluate the Flash
; Memory (using the FlashEprCardId routine) and warn the user that an INTEL Flash Memory Card
; requires the Z88 slot 3 hardware, so this type of unnecessary error can be avoided.
;
; This is an internal, shared routine used by FlashEprFileFormat and FlashEprReduceFileArea;
; End-user applications might use this routine, but must then consider the semantics used by
; FlashEprFileFormat and FlashEprReduceFileArea.
;
; In:
;    A = FE_28F, FE_29F programming algorithm (or 0 to poll for programming)
;    B = Absolute Bank (00h - FFh) where to blow header (at offset $3FC0)
;        (bits 7,6 is the slot mask)
;    HL <> 0, use 64 byte header, located current address space at (HL)
;
;    HL = 0, create a new 'oz' header (auto-generated random no, etc)
;    C = total 16K banks on card
;
; Out:
;    Success:
;         Fc = 0, File Eprom Header successfully blown to Flash Eprom
;         C = size of File Eprom Area in 16K banks
;
;    Failure:
;         Fc = 1
;         A = RC_BWR (couldn't write header to Flash Memory)
;         A = RC_NFE (not a recognized Flash Memory Chip)
;
; Registers changed after return:
;    A.B.DEHL/IXIY ........ same
;    .F.C..../.... afbcdehl different
;
; ------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, Dec 1997 - Aug 1998, July 2006, Aug-Oct 2006
;    Thierry Peycru, Zlab, Dec 1997
; ------------------------------------------------------------------------
;
.FlashEprStdFileHeader
        push    de
        push    bc
        push    af
        push    hl
        push    ix

        push    hl                              ; preserve local pointer to file area header
        exx
        pop     hl
        exx

        ld      hl,0
        add     hl,sp
        ld      ix,-66
        add     ix,sp                           ; IX points at start of buffer
        ld      sp,ix                           ; 64 byte buffer created...
        push    hl                              ; preserve original SP
        push    af                              ; preserve FE_xx flash chip programming algorithm

        exx
        ld      a,h
        or      l
        exx
        jr      z,create_new_header             ; HL function argument = 0, create a new File Area Header...
        exx
        ld      bc,64
        push    ix
        pop     de
        ldir                                    ; copy prepared 64 byte file area header into stack buffer
        exx
        jr      blow_header
.create_new_header
        push    bc                              ; preserve B = bank to blow header, C = total banks on card

        push    ix
        pop     hl
        ld      b,$37                           ; 55 bytes of $00 from $3FC0
        xor     a
.wri0_loop
        ld      (hl),a
        inc     hl
        djnz    wri0_loop

        ld      (hl),1
        inc     hl

        push    hl
        ld      a,sr_rnd
        oz      OS_SR
        pop     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d                          ; low word random ID...
        inc     hl

        ld      bc,6
        ex      de,hl
        ld      hl, stdromhdr
        ldir
        pop     hl                              ; H = blow header at bank, L = total of banks on Flash Memory Card
        ld      b,h                             ; B = blow header at bank
        ld      c,l
        res     7,h
        res     6,h
        inc     h
        call    Divu8                           ; get true file eprom size, no matter where bank header is blown
        inc     l
        dec     l
        jr      z, whole_card
        ld      (ix + $3C),l                    ; File Eprom area smaller than card size
        jr      blow_header
.whole_card
        ld      (ix + $3c),c                    ; File Eprom area uses whole card
.blow_header
        pop     af                              ; use FE_xx chip type to program File Card header
        push    ix
        pop     de                              ; start of File Eprom Header
        ld      hl, $3fc0                       ; blow at address B,$3FC0
        call    SafeBHLSegment                  ; get a safe segment in C (not this executing segment!) to blow bytes
        push    iy                              ; (preserve IY)
        ld      iy, 64                          ; of size
        call    FlashEprWriteBlock              ; blow header...
        pop     iy

        ld      c,(ix + $3c)                    ; return size of File Eprom Area
        pop     hl
        ld      sp,hl                           ; restore original Stack Pointer
        jr      c, err_FlashEprStdFileHeader

        pop     ix                              ; restore registers...
        pop     hl
        pop     de                              ; original AF..
        ld      a,d                             ; A restored
        pop     de
        ld      b,d                             ; original B restored (return C)
        pop     de                              ; original DE restored
        ret
.err_FlashEprStdFileHeader
        pop     ix                              ; restore registers...
        pop     hl
        pop     bc                              ; return error code in AF...
        pop     bc
        pop     de
        ret
.stdromhdr
        defb $01, $80, $40, $7c, $6f, $7a
