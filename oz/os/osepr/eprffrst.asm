        module FileEprFirstFile

; **************************************************************************************************
; File Area functionality.
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
;
; ***************************************************************************************************

        xdef FileEprFirstFile
        xref FileEprRequest, FileEprNextFile, FileEprFileEntryInfo

        include "error.def"


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return first file entry pointer on Standard File Eprom, inserted in slot C.
;
; If the NULL file is identified as the first file, it is skipped and the next
; file entry pointer is automatically returned.
;
; IN:
;    C = slot number containing File Eprom
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry is active.
;         BHL = pointer to first file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
;         (NULL file skipped if found on Intel Flash Card)
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004, July 2005
; ------------------------------------------------------------------------
;
.FileEprFirstFile
        push    de
        push    af
        push    bc                              ; preserve CDE

        ld      e,c                             ; preserve slot number
        call    FileEprRequest                  ; check for presence of "oz" File Eprom in slot C
        jr      c,no_entry
        jr      nz,no_entry                     ; File Eprom not available in slot...

        ld      a,b
        sub     c                               ; C = total banks of File Eprom Area
        inc     a
        ld      b,a                             ; B is now bottom bank of File Eprom in slot C
        ld      hl,$0000                        ; BHL points at first File Entry...
        push    bc
        push    hl
        call    FileEprFileEntryInfo
        ld      a,c                             ; CDE = length of file entry
        pop     hl
        pop     bc
        jr      c, no_entry                     ; Ups - no File Entry found...
        jr      nz, end_FeFirstFile             ; first file is an active file...
        or      d
        or      e                               ; CDE = 0 means that NULL file is present.
        jr      nz, no_null_file
        call    FileEprNextFile                 ; ignore NULL file, get pointer to next file (entry)
        jr      end_FeFirstFile                 ; get pointer to next file entry and return Fz status
.no_null_file
        cp      a                               ; return Fz = 1, deleted file was not a Null file...
.end_FeFirstFile
        pop     de                              ; BHL = pointer to first File Entry
        ld      c,e                             ; original C restored
        pop     de
        ld      a,d                             ; original A restored
        pop     de
        ret
.no_entry
        scf
        ld      a, RC_Onf                       ; "Object not found"
        pop     de
        ld      c,e                             ; original C register restored
        pop     de                              ; ignore original AF...
        pop     de
        ret
