     XLIB FileEprFileImage

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

     LIB FileEprRequest
     LIB FileEprFileEntryInfo
     LIB AddPointerDistance

     INCLUDE "error.def"
     INCLUDE "memory.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return pointer to start of file image of File Entry at BHL
; (B=00h-FFh embedded slot mask, HL=0000h-3FFFh bank offset)
;
; IN:
;    BHL = pointer to Eprom File Entry in card at slot
;
; OUT:
;    Fc = 0, File Eprom available, File Entry available
;         BHL = pointer to start of file image
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
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
.FileEprFileImage   PUSH DE
                    PUSH BC

                    PUSH BC
                    PUSH HL                       ; preserve pointer to File Entry
                    CALL FileEprFileEntryInfo
                    POP  HL
                    POP  BC
                    JR   C, exit_FileEprFileImage ; No files are present on File Eprom...

                    INC  A                        ; length of filename + length byte
                    ADD  A,4                      ; + 4 bytes (32bit integer containing file size)

                    LD   C,0
                    LD   D,C
                    LD   E,A
                    CALL AddPointerDistance       ; BHL = start of file image...
.exit_FileEprFileImage
                    POP  DE
                    LD   C,E                      ; original C register restored
                    POP  DE                       ; original DE restored
                    RET

