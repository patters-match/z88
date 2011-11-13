     XLIB FileEprUsedSpace

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
;***************************************************************************************************

     LIB FileEprTotalSpace

     include "error.def"

; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return used space in Standard File Eprom Area, inserted in slot C
; (API wrapper of FileEprTotalSpace)
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         DEBC = Used space (amount of deleted & active files) in bytes
;                (DE = high 16bit, BC = low 16bit)
;
;    Fc = 1, File Eprom was not found in slot C
;         A = RC_ONF
;
; Registers changed after (succesful) return:
;    A.....HL/IXIY same
;    .FBCDE../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, July 2005
; -----------------------------------------------------------------------
;
.FileEprUsedSpace   PUSH HL
                    PUSH AF

                    CALL FileEprTotalSpace
                    JR   C, err_FileEprUsedSpace
                    ADD  HL,DE
                    LD   A,B
                    ADC  A,C
                    LD   D,0
                    LD   E,A
                    PUSH HL
                    POP  BC                       ; BHL + CDE -> DEBC
.exit_usedspace
                    POP  HL
                    LD   A,H                      ; restored original A, Fc = 0..
                    POP  HL                       ; restored original HL
                    RET
.err_FileEprUsedSpace
                    POP  HL                       ; discard old AF
                    POP  HL                       ; original HL restored
                    RET
