     XLIB FileEprNextFile

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

     LIB FileEprFileEntryInfo

     INCLUDE "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return next file entry pointer on Standard File Eprom, inserted in slot
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset) 
;
; IN:
;    BHL = pointer to File Entry
;
; OUT:
;    Fc = 0, File Eprom available
;         BHL = pointer to next file entry on File Eprom in slot
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
; -----------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004
; -----------------------------------------------------------------------
;
.FileEprNextFile    PUSH DE
                    PUSH AF

                    PUSH BC
                    CALL FileEprFileEntryInfo
                    LD   A,B                      ; returned BHL is next file entry...
                    POP  BC                       ; original C register restored
                    LD   B,A
                    JR   C, no_entry              ; No files are present on File Eprom...

                    POP  DE
                    LD   A,D                      ; original A restored...
                    POP  DE                       ; original DE register restored
                    RET
.no_entry           
                    SCF
                    LD   A, RC_Onf
                    POP  DE                       ; ignore old AF
                    POP  DE                       ; original DE register restored
                    RET
