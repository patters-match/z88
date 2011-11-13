; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2009
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
;
; *************************************************************************************

     Module EprFetchToRAM

     LIB FileEprFileImage
     LIB FileEprFileEntryInfo
     LIB FileEprTransferBlockSize
     LIB MemDefBank             ; Bind bank, defined in B, into segment C. Return old bank binding in B

     XDEF EprFetchToRAM

     include "error.def"
     include "memory.def"


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format.
;
; Copy file (image) from file area to memory (RAM) buffer. This routine runs no boundary checking;
; the application is responsible for copying files into the RAM buffer at DE without crossing
; the bank boundary of DE (Z80 address space), ie. the file must be able to be copied as one unit
; within the boundaries of the segment memory in Z80 address space that DE points to.
;
; IN:
;         BHL = pointer to file entry to be copied
;         DE = pointer to RAM buffer (max. 16K), available in current Z80 address space
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
                    push ix                       ; preserve original IX

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
                    pop  de                       ; DE = destination block pointer (start of RAM buffer)
                    pop  bc                       ; BHL = pointer to entry in File Area
                    res  7,h
                    res  6,h                      ; discard segment mask, if any...
                    push bc
                    push de
                    push hl
                    call FileEprFileImage         ; adjust BHL pointer to first byte of file image (beyond file entry header)
                    call CopyFileEntry            ; Now, copy source file entry to RAM buffer at (DE)
.exit_EprFetchToRAM
                    pop  hl
                    pop  de
                    pop  bc
                    pop  ix
                    ret


; **************************************************************************
.CopyFileEntry
.copy_file_loop
                    exx                           ; file size = 0?
                    ld   a,d
                    or   e                        ; bank file sizes always 16bit...
                    exx
                    ret  z                        ; File entry was successfully copied to RAM buffer!
.copy_file_block
                    call FileEprTransferBlockSize ; get block size in hl' based on current BHL pointer
                    exx                           ; and remaining file size in cde'
                    push bc
                    push de                       ; preserve remaining file size
                    push hl
                    pop  ix                       ; size of block to copy
                    exx

                    call EprCopyFileImage         ; copy file entry from BHL to DE, block size IX

                    exx
                    pop  de
                    pop  bc                       ; restore remaining file size = CDE
                    exx
                    jr   copy_file_loop           ; then get next block from source file

.EprCopyFileImage
                    push bc
if BBCBASIC
                    set  7,h                      ; for BBC BASIC:
                    set  6,h                      ; use segment 3 to bind data block of file entry into address space
else
                    set  7,h                      ; for POPDOWN:
                    res  6,h                      ; use segment 2 to bind data block of file entry into address space
endif
                    ld   a,b
                    exx
                    ld   b,a
if BBCBASIC
                    ld   c, MS_S3                 ; BBCBASIC: Use C = MS_S3 for BHL source data block
else
                    ld   c, MS_S2                 ; POPDOWN: Use C = MS_S2 of BHL source data block
endif
                    call MemDefBank               ; Bind bank of source data into segment C
                    push bc                       ; preserve old bank binding of segment C
                    exx

                    push ix                       ; now BHL source block in current address space
                    pop  bc
                    ldir                          ; copy from one segment in (HL) to other segment at (DE) of size BC

                    exx
                    pop  bc
                    call MemDefBank               ; restore old segment C bank binding of BHL source data block
                    exx

                    res  7,h
                    res  6,h
                    pop  bc                       ; original B restored

                    inc  h                        ; source pointer crossed bank boundary?
                    dec  h                        ; (HL = 0, because segment specifier went into next segment)
                    ret  nz                       ; nope (within 16k offset)
                    inc  b                        ; remaining block of file is in next bank of file area
                    ret
