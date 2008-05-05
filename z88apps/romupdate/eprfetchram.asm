; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2007
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     Module EprFetchToRAM

     LIB FileEprFileImage
     LIB FileEprFileEntryInfo
     LIB FileEprTransferBlockSize
     LIB MemDefBank             ; Bind bank, defined in B, into segment C. Return old bank binding in B
     LIB ApplSegmentMask        ; Get segment mask (MM_Sx) of this executing code)
     LIB SafeSegmentMask        ; Get a 'safe' segment mask outside the current executing code

     XDEF EprFetchToRAM

     include "error.def"
     include "memory.def"


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format.
;
; Copy file (image) from file area to memory (RAM) buffer. This routine runs no boundary checking;
; the application is responsible for copying files into the RAM buffer at CDE without crossing
; the bank boundary of CDE, ie. the file must be able to be copied as one unit within the boundaries
; of bank C, offset DE.
;
; IN:
;         BHL = pointer to file entry to be copied
;         CDE = pointer to RAM buffer (max. 16K)
; OUT:
;         Fc = 0,
;              File successfully copied to RAM buffer in CDE.
;         Fc = 1,
;              File Entry at BHL was not found.
;                   A = RC_Onf
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
; -------------------------------------------------------------------------
; Design & Programming by Gunther Strube, Apr 2008
; -------------------------------------------------------------------------
;
.EprFetchToRAM
                    push iy                       ; preserve original IY

                    push bc
                    push de
                    push hl

                    call FileEprFileEntryInfo     ; return CDE = file image size, A = length of entry filename
                    jr   c, exit_EprFetchToRAM    ; File entry not recognised, exit with error...
                    push bc
                    push de
                    exx
                    pop  de
                    pop  bc                       ; File Entry File Image size in 'CDE
                    exx

                    pop  hl
                    pop  de
                    pop  bc
                    res  7,h
                    res  6,h                      ; discard segment mask, if any...
                    res  7,d
                    res  6,d
                    push bc
                    push de
                    push hl
                    call FileEprFileImage         ; BHL now points at first byte of file image (not file entry)
                    call CopyFileEntry            ; Now, copy source file entry to RAM buffer in CDE
.exit_EprFetchToRAM
                    pop  hl
                    pop  de
                    pop  bc
                    pop  iy
                    ret


; **************************************************************************
.CopyFileEntry
.copy_file_loop
                    exx                           ; file size = 0?
                    ld   a,d
                    or   e
                    exx
                    jr   nz, copy_file_block      ; No, bytes still left to copy...
                    exx
                    xor  a
                    or   c
                    exx
                    ret  z                        ; File entry was successfully copied to RAM buffer!
.copy_file_block
                    call FileEprTransferBlockSize ; get block size in hl' based on current BHL pointer
                    exx                           ; and remaining file size in cde'
                    push bc
                    push de                       ; preserve remaining file size
                    push hl
                    pop  iy                       ; size of block to copy
                    exx

                    call EprCopyFileImage         ; copy file entry from BHL to CDE, block size IY

                    exx
                    pop  de
                    pop  bc                       ; restore remaining file size = CDE
                    exx
                    jr   copy_file_loop           ; then get next block from source file

.EprCopyFileImage
                    push iy
                    push bc

                    call SafeSegmentMask               ; get safe segments for BHL & CDE pointers (outside executing PC segment)
                    push af
                    res  7,h
                    res  6,h
                    or   h
                    ld   h,a                           ; HL[sgmask]
                    call ApplSegmentMask               ; PC[sgmask]
                    ex   (sp),hl
                    xor  h
                    res  7,d
                    res  6,d
                    or   d
                    ld   d,a                           ; DE[sgmask] = PC[sgmask] XOR HL[sgmask]
                    pop  hl

                    push bc
                    ld   a,h
                    exx
                    pop  bc
                    rlca
                    rlca
                    ld   c,a                           ; C = MS_Sx of BHL source data block
                    call MemDefBank                    ; Bind bank of source data into segment C
                    push bc                            ; preserve old bank binding of segment C
                    exx

                    ex   de,hl
                    ld   b,c                           ; BHL <- CDE
                    call CopyFileBlockToBuffer         ; DE now source block in current address space, BHL destination pointer
                    exx
                    pop  bc
                    call MemDefBank                    ; restore old segment C bank binding of BHL source data block
                    exx

                    res  7,d
                    res  6,d
                    add  iy,de                         ; block size + offset = updated block pointer (installed in HL below)
                    push iy

                    ex   de,hl
                    ld   c,b
                    res  7,d
                    res  6,d                           ; return updated CDE destination pointer to caller

                    pop  hl                            ; HL = updated byte beyond source block offset
                    pop  af
                    ld   b,a                           ; original B restored
                    bit  6,h                           ; source pointer crossed bank boundary?
                    jr   z,exit_EprCopyFileImage           ; nope (withing 16k offset)
                    inc  b
                    res  6,h                           ; source block copy reached boundary of bank...
.exit_EprCopyFileImage
                    pop  iy                            ; restored original IY
                    ret


; In :
;         DE = local pointer to start of block (located in current address space)
;         BHL = extended address to start of destination
;              (bits 7,6 of B is the slot mask)
;              (bits 7,6 of H = MM_Sx segment mask for BHL)
;         IY = size of block (at DE) to copy
; Out:
;         Success:
;              Fc = 0
;              BHL updated
;
; Registers changed on return:
;    ...CDE../IXIY ........ same
;    AFB...HL/.... afbcdehl different
;
.CopyFileBlockToBuffer
                    push de                            ; preserve DE
                    push bc                            ; preserve C

                    ld   a,h
                    rlca
                    rlca
                    and  @00000011
                    ld   c,a                           ; C = MS_Sx
                    ld   a,b
                    call MemDefBank                    ; Bind slot x bank into segment C
                    push bc                            ; preserve old bank binding of segment C

                    push iy
                    pop  bc
                    ex   de,hl                         ; copy from one segment in (HL) to other segment at (DE) of size BC
                    ldir

                    pop  bc
                    call MemDefBank                    ; restore old segment C bank binding

                    pop  de
                    ld   c,e                           ; original C register restored...
                    pop  de
                    ret
