     XLIB FileEprFileSize

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
;
; ***************************************************************************************************

     LIB FileEprFileEntryInfo


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return file size of File Entry at pointer BHL
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset) 
;
; IN:
;    BHL = Pointer to File Entry in card at slot 
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry active
;              CDE = size of file (24bit integer, C = high byte)
;
;    Fc = 1, 
;         A = RC_ONF
;         File Eprom was not found in slot, or File Entry not available
;
; Registers changed after return:
;    ..B...HL/IXIY same
;    AF.CDE../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, Sep 2004, Feb 2007
; ------------------------------------------------------------------------
;
.FileEprFileSize    PUSH HL
                    PUSH BC                       ; preserve pointer

                    CALL FileEprFileEntryInfo     ; get size in CDE, file status (Fz)

                    POP  HL                       ; if Fc = 1, then A = RC_Onf, CDE is random 
                    LD   B,H                      ; if Fc = 0, then CDE contains file entry image size.
                    POP  HL                       ; BHL restored
                    RET                           ; return filestatus (Fz) (or possibly error status, Fc)
