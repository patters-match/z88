     XLIB FlashEprCopyFileEntry

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

     LIB FlashEprFileDelete
     LIB FlashEprCopyBlock
     LIB FileEprAllocFilePtr
     LIB FileEprFreeSpace
     LIB FileEprFileEntryInfo
     LIB SafeBHLSegment
     LIB FlashEprCardId
     LIB FileEprTransferBlockSize
     LIB OZSlotPoll, SetBlinkScreen

     XREF SetBlinkScreenOn

     include "error.def"
     include "memory.def"


     ; IY points at base of stack workspace
     DEFVARS 0
          SrcFileEntry ds.p 1           ; pointer to source File Entry (to be copied)
          DstFileEntry ds.p 1           ; pointer to destination File Entry
          SrcFileSize  ds.b 3           ; 24bit total file size of entry (header + image)
          CardSlot     ds.b 1           ; slot number of destination Flash Card
          FepType      ds.b 1           ; Flash Eprom type in Slot C
          SizeOfWorkSpace               ; size of Workspace on stack
     ENDDEF


; **************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Copy file entry from one file area to another file area in slot C (or to file
; area in same slot).
;
; The routine does NOT handle automatical "deletion" of existing files
; that matches the filename (excl. device). This must be used by a call
; to <FlashEprFileDelete>.
;
; Should the actual process of blowing the file image fail, the new
; File Entry will be marked as deleted, if possible.
;
; -------------------------------------------------------------------------
; The screen is turned off while copying a file to flash file area that is in
; the same slot as the OZ ROM. During copying, no interference should happen
; from Blink, because the Blink reads the font bitmaps each 1/100 second:
;    When copying to a file area which is part of the OZ ROM chip, the font
;    bitmaps are suddenly unavailable which creates violent screen flickering
;    during chip command mode. Further, and most importantly, the Blink
;    must be prohibited doing read-cycles while chip is in command mode.
; By switching off the screen, the Blink doesn't read the font bit maps in
; OZ ROM, and the Flash chip can be in command mode without being disturbed
; by the Blink.
; -------------------------------------------------------------------------
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3
; to successfully blow data to the memory chip. If the Flash Eprom card
; is inserted in slot 1 or 2, this routine will report a programming failure.
;
; It is the responsibility of the application (before using this call) to
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
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
                    PUSH IX                       ; preserve IX
                    PUSH HL
                    PUSH DE
                    PUSH BC                       ; preserve CDE
                    PUSH IY                       ; preserve original IY

                    EXX                           ; use alternate registers temporarily
                    LD   HL,0
                    ADD  HL,SP
                    LD   IY, -SizeOfWorkSpace     ; create temporary work buffer on stack
                    ADD  IY,SP
                    LD   SP,IY
                    PUSH HL                       ; preserve a copy of original SP on return
                    EXX

                    LD   (IY + CardSlot),C        ; preserve slot number of File Eprom Card
                    RES  7,H
                    RES  6,H                      ; discard segment mask, if any...
                    LD   (IY + SrcFileEntry),L
                    LD   (IY + SrcFileEntry+1),H
                    LD   (IY + SrcFileEntry+2),B  ; preserve pointer to source File Entry...

                    CALL FileEprFileEntryInfo     ; return CDE = file image size, A = length of entry filename
                    JR   C, exit_FlashEprCopyFileEntry ; File entry not recognised, exit with error...

                    EX   DE,HL
                    ADD  A,4+1                    ; file entry header size = length of filename + 1 + file length (4 bytes)
                    LD   D,0
                    LD   E,A
                    ADD  HL,DE                    ; total size of file entry = header + image
                    JR   NC,preserve_entrysize
                    INC  C                        ; total file size > 64K, adjust 24bit high byte
.preserve_entrysize
                    LD   (IY + SrcFileSize),L
                    LD   (IY + SrcFileSize+1),H
                    LD   (IY + SrcFileSize+2),C
                    LD   B,0
                    PUSH BC                       ; high word of file entry size
                    PUSH HL                       ; low word of file entry size

                    LD   C,(IY + CardSlot)        ; scan File Eprom in slot X for free space
                    CALL FileEprFreeSpace         ; returned in DEBC (Fc = 0, File area is available from FileEprFileEntryInfo...)

                    LD   H,B
                    LD   L,C                      ; HL = low word of 32bit free space...
                    POP  BC
                    SBC  HL,BC
                    EX   DE,HL                    ; HL = high word of 32bit free space...
                    POP  DE                       ; DE = high word of file size
                    SBC  HL,DE
                    JR   NC, copy_fileentry       ; there's room for file in slot C, start to copy...
                    LD   A, RC_Room
                    SCF                           ; file size (incl. File Entry Header) > free space, don't copy...
                    JR   exit_FlashEprCopyFileEntry
.copy_fileentry
                    LD   C,(IY + CardSlot)
                    CALL FlashEprCardId           ; make sure that a flash card is available in slot C..
                    LD   (IY + FepType),A         ; yes, remember flash type for later
                    JR   C, exit_FlashEprCopyFileEntry ; no flash card - no copying...

                    CALL OZSlotPoll               ; is OZ running in slot C?
                    CALL NZ,SetBlinkScreen        ; yes, copying file to file area in OZ ROM (slot 0 or 1) requires LCD turned off
                    CALL CopyFileEntry            ; Now, copy source file entry to file area in slot C...
                    CALL SetBlinkScreenOn         ; always turn on screen after copy file operation

.exit_FlashEprCopyFileEntry
                    POP  HL
                    LD   SP,HL                    ; restore original SP
                    POP  IY                       ;                  IY

                    POP  BC                       ; and the usual gang...
                    POP  DE
                    POP  HL
                    POP  IX
                    RET


; **************************************************************************
.CopyFileEntry
                    LD   C,(IY + CardSlot)
                    CALL FileEprAllocFilePtr      ; BHL = pointer to free file space on File Eprom Card
                    RET  C                        ; no file area recognized in slot C!
                    EX   DE,HL
                    LD   C,B
                    LD   (IY + DstFileEntry),E
                    LD   (IY + DstFileEntry+1),D  ; preserve destination File Entry pointer if copy fails..
                    LD   (IY + DstFileEntry+2),C  ; (and needs to marked as deleted)
                    LD   L,(IY + SrcFileEntry)
                    LD   H,(IY + SrcFileEntry+1)
                    LD   B,(IY + SrcFileEntry+2)  ; BHL = pointer to source File Entry...
                    EXX
                    LD   E,(IY + SrcFileSize)
                    LD   D,(IY + SrcFileSize+1)
                    LD   C,(IY + SrcFileSize+2)   ; total file size to copy to slot C...
                    EXX
.copy_file_loop
                    EXX                           ; file size = 0?
                    LD   A,D
                    OR   E
                    EXX
                    JR   NZ, copy_file_block      ; No, bytes still left to copy...
                    EXX
                    XOR  A
                    OR   C
                    EXX
                    RET  Z                        ; File entry was successfully copied to file area!
.copy_file_block
                    CALL FileEprTransferBlockSize ; get block size in hl' based on current BHL pointer & file size.
                    LD   A,(IY + FepType)
                    PUSH IY
                    EXX
                    PUSH BC
                    PUSH DE                       ; preserve remaining file size
                    PUSH HL
                    PUSH HL
                    POP  IY                       ; size of block to copy
                    EXX
                    CALL FlashEprCopyBlock        ; copy file entry to Flash Card at CDE
                    EX   AF,AF'                   ; preserve error status of block write while updating BHL source ptr...
                    PUSH HL
                    EXX
                    POP  HL
                    POP  BC
                    ADD  HL,BC                    ; update BHL pointer with block written..
                    POP  DE
                    POP  BC                       ; restore remaining file size = CDE
                    PUSH HL
                    EXX
                    POP  HL                       ; BHL pointer updated
                    BIT  6,H                      ; source pointer crossed bank boundary?
                    JR   Z,check_write_status     ; nope (withing 16K offset)
                    INC  B
                    RES  6,H                      ; source block copy reached boundary of bank...

                    POP  IY                       ; restore base pointer to local stack variables...
.check_write_status
                    EX   AF,AF'
                    JR   NC,copy_file_loop        ; if block successfully blown (Fc = 0), then get next block from source file

                    PUSH AF                       ; write block failure!
                    LD   L,(IY + DstFileEntry)
                    LD   H,(IY + DstFileEntry+1)
                    LD   B,(IY + DstFileEntry+2)
                    CALL FlashEprFileDelete       ; mark Destination File Entry as deleted, if possible.
                    POP  AF                       ; and exit with error code from FlashEprCopyBlock
                    RET
