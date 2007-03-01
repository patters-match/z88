     XLIB FileEprLastFile

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
; ***************************************************************************************************

     LIB FileEprFirstFile, FileEprNextFile
     LIB FileEprFileStatus


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return pointer to last file entry on Standard File Eprom, inserted in slot C
;
; IN:
;    C = slot number containing File Eprom
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry is active.
;         BHL = pointer to last file entry in slot (B=00h-FFh, HL=0000h-3FFFh).
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 2004, Mar 2007
; ------------------------------------------------------------------------
;
.FileEprLastFile    PUSH DE
                    PUSH BC                       ; preserve CDE

                    CALL FileEprFirstFile         ; Get first file entry in File Area
                    JR   C,exit_FileEprLastFile
.scan_filearea                                    ; scan the File Area until last File Entry found...
                    LD   C,B
                    LD   D,H
                    LD   E,L
                    PUSH AF                       ; preserve current File Entry in CDE,F
                    CALL FileEprNextFile          ; get next file entry in BHL
                    CALL FileEprFileStatus        ; validate status of next file entry.
                    EX   AF,AF'
                    POP  AF
                    EX   AF,AF'
                    JR   NC, scan_filearea
                                                  ; next file entry was pointing to empty space
                    EX   AF,AF'                   ; file status of last file entry restored.
                    LD   B,C
                    EX   DE,HL                    ; BHL = pointer to last File Entry
.exit_FileEprLastFile
                    POP  DE
                    LD   C,E                      ; original C restored
                    POP  DE                       ; original DE restored
                    RET