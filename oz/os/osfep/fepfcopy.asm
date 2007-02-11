        module FlashEprCopyFileEntry

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

        xdef FlashEprCopyFileEntry

        lib FileEprAllocFilePtr
        lib FileEprFreeSpace
        lib FileEprFileEntryInfo
        lib FileEprTransferBlockSize
        lib OZSlotPoll, SetBlinkScreen

        xref FlashEprCardId
        xref FlashEprFileDelete
        xref FlashEprCopyBlock
        xref SetBlinkScreenOn

        include "error.def"
        include "memory.def"


        ; IY points at base of stack workspace
        defvars 0
             SrcFileEntry ds.p 1           ; pointer to source File Entry (to be copied)
             DstFileEntry ds.p 1           ; pointer to destination File Entry
             SrcFileSize  ds.b 3           ; 24bit total file size of entry (header + image)
             CardSlot     ds.b 1           ; slot number of destination Flash Card
             FepType      ds.b 1           ; Flash Eprom type in Slot C
             SizeOfWorkSpace               ; size of Workspace on stack
        enddef


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Copy file entry from one file area to another file area in slot C (or to file area in same slot).
;
; The routine does NOT handle automatical "deletion" of existing files that matches the filename
; (excl. device). This must be used by a call to <FlashEprFileDelete>.
;
; Should the actual process of blowing the file image fail, the new File Entry will be marked as
; deleted, if possible.
;
; ---------------------------------------------------------------------------------------------------
; The screen is turned off while copying a file to flash file area that is in the same slot as the
; OZ ROM. During copying, no interference should happen from Blink, because the Blink reads the font
; bitmaps each 1/100 second:
;    When copying to a file area which is part of the OZ ROM chip, the font bitmaps are suddenly
;    unavailable which creates violent screen flickering during chip command mode. Further, and most
;    importantly, the Blink must be prohibited doing read-cycles while chip is in command mode.
; By switching off the screen, the Blink doesn't read the font bit maps in OZ ROM, and the Flash chip
; can be in command mode without being disturbed by the Blink.
; ---------------------------------------------------------------------------------------------------
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3 to successfully blow data to
; the memory chip. If the Flash Eprom card is inserted in slot 1 or 2, this routine will report a
; programming failure.
;
; It is the responsibility of the application (before using this call) to evaluate the Flash Memory
; (using the FlashEprCardId routine) and warn the user that an INTEL Flash Memory Card requires the
; Z88 slot 3 hardware, so this type of unnecessary error can be avoided.
;
; IN:
;           C = slot number (0, 1, 2 or 3)
;         BHL = pointer to file entry to be copied
; OUT:
;         Fc = 0,
;              File successfully copied to File Area in slot C.
;         Fc = 1,
;              File (Flash) Eprom not available in slot C:
;                   A = RC_Nfe (not a recognized Flash Memory Chip)
;              File Entry at BHL was not found, or no file area in slot C:
;                   A = RC_Onf
;              No sufficient space to store file (and File Entry Header) in slot C:
;                   A = RC_Room
;              Flash Write Errors:
;                   If possible, the new File Entry is marked as deleted.
;                   A = RC_Vpl, RC_Bwr (see "flashepr.def" for details)
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
; -------------------------------------------------------------------------
; Design & Programming by Gunther Strube, Oct 2006
; -------------------------------------------------------------------------
;
.FlashEprCopyFileEntry
        push    ix                              ; preserve IX
        push    hl
        push    de
        push    bc                              ; preserve CDE
        push    iy                              ; preserve original IY

        exx                                     ; use alternate registers temporarily
        ld      hl,0
        add     hl,sp
        ld      iy, -SizeOfWorkSpace            ; create temporary work buffer on stack
        add     iy,sp
        ld      sp,iy
        push    hl                              ; preserve a copy of original SP on return
        exx

        ld      (iy + CardSlot),c               ; preserve slot number of File Eprom Card
        res     7,h
        res     6,h                             ; discard segment mask, if any...
        ld      (iy + SrcFileEntry),l
        ld      (iy + SrcFileEntry+1),h
        ld      (iy + SrcFileEntry+2),b         ; preserve pointer to source File Entry...

        call    FileEprFileEntryInfo            ; return CDE = file image size, A = length of entry filename
        jr      c, exit_FlashEprCopyFileEntry   ; File entry not recognised, exit with error...

        ex      de,hl
        add     a,4+1                           ; file entry header size = length of filename + 1 + file length (4 bytes)
        ld      d,0
        ld      e,a
        add     hl,de                           ; total size of file entry = header + image
        jr      nc,preserve_entrysize
        inc     c                               ; total file size > 64K, adjust 24bit high byte
.preserve_entrysize
        ld      (iy + SrcFileSize),l
        ld      (iy + SrcFileSize+1),h
        ld      (iy + SrcFileSize+2),c
        ld      b,0
        push    bc                              ; high word of file entry size
        push    hl                              ; low word of file entry size

        ld      c,(iy + CardSlot)               ; scan File Eprom in slot X for free space
        call    FileEprFreeSpace                ; returned in DEBC (Fc = 0, File area is available from FileEprFileEntryInfo...)

        ld      h,b
        ld      l,c                             ; HL = low word of 32bit free space...
        pop     bc
        sbc     hl,bc
        ex      de,hl                           ; HL = high word of 32bit free space...
        pop     de                              ; DE = high word of file size
        sbc     hl,de
        jr      nc, copy_fileentry              ; there's room for file in slot C, start to copy...
        ld      a, RC_Room
        scf                                     ; file size (incl. File Entry Header) > free space, don't copy...
        jr      exit_FlashEprCopyFileEntry
.copy_fileentry
        ld      c,(iy + CardSlot)
        call    FlashEprCardId                  ; make sure that a flash card is available in slot C..
        ld      (iy + FepType),a                ; yes, remember flash type for later
        jr      c, exit_FlashEprCopyFileEntry   ; no flash card - no copying...

        call    OZSlotPoll                      ; is OZ running in slot C?
        call    nz,SetBlinkScreen               ; yes, copying file to file area in OZ ROM (slot 0 or 1) requires LCD turned off
        call    CopyFileEntry                   ; Now, copy source file entry to file area in slot C...
        call    SetBlinkScreenOn                ; always turn on screen after copy file operation

.exit_FlashEprCopyFileEntry
        pop     hl
        ld      sp,hl                           ; restore original SP
        pop     iy                              ;                  IY

        pop     bc                              ; and the usual gang...
        pop     de
        pop     hl
        pop     ix
        ret


; **************************************************************************
.CopyFileEntry
        call    FileEprAllocFilePtr             ; BHL = pointer to free file space on File Eprom Card
        ret     c                               ; no file area recognized in slot C!
        ex      de,hl
        ld      c,b
        ld      (iy + DstFileEntry),e
        ld      (iy + DstFileEntry+1),d         ; preserve destination File Entry pointer if copy fails..
        ld      (iy + DstFileEntry+2),c         ; (and needs to marked as deleted)
        ld      l,(iy + SrcFileEntry)
        ld      h,(iy + SrcFileEntry+1)
        ld      b,(iy + SrcFileEntry+2)         ; BHL = pointer to source File Entry...
        exx
        ld      e,(iy + SrcFileSize)
        ld      d,(iy + SrcFileSize+1)
        ld      c,(iy + SrcFileSize+2)          ; total file size to copy to slot C...
        exx
.copy_file_loop
        exx                                     ; file size = 0?
        ld      a,d
        or      e
        exx
        jr      nz, copy_file_block             ; No, bytes still left to copy...
        exx
        xor     a
        or      c
        exx
        ret     z                               ; File entry was successfully copied to file area!
.copy_file_block
        call    FileEprTransferBlockSize        ; get block size in hl' based on current BHL pointer & file size in cde'
        ld      a,(iy + FepType)                ; get chip programming type FE_xxx
        exx
        push    bc
        push    de                              ; preserve remaining file size
        push    hl
        pop     ix                              ; size of block to copy
        exx
        call    FlashEprCopyBlock               ; copy file entry from BHL to Flash Card at CDE, block size IY
        exx
        pop     de
        pop     bc                              ; restore remaining file size = CDE
        exx
        jr      nc,copy_file_loop               ; if block successfully blown (Fc = 0), then get next block from source file

        push    af                              ; write block failure!
        ld      l,(iy + DstFileEntry)
        ld      h,(iy + DstFileEntry+1)
        ld      b,(iy + DstFileEntry+2)
        call    FlashEprFileDelete              ; mark Destination File Entry as deleted, if possible.
        pop     af                              ; and exit with error code from FlashEprCopyBlock
        ret
