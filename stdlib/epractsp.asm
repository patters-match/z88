     XLIB FileEprActiveSpace

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

     LIB FileEprUsedSpace, FileEprDeletedSpace

     include "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return amount of active (visible) file space in File Eprom Area, inserted in slot C.
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         DEBC = Active space (amount of visible files) in bytes
;                (DE = high 16bit, BC = low 16bit)
;
;    Fc = 1, 
;         A = RC_ONF
;         File Eprom was not found in slot C.
;
; Registers changed after (succesful) return:
;    A.....HL/IXIY same
;    .FBCDE../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, July 2005
; ------------------------------------------------------------------------
;
.FileEprActiveSpace
                    PUSH HL
                    
                    LD   L,C                      ; preserve slot number
                    CALL FileEprUsedSpace
                    JR   C,err_FileEprActiveSpace ; File Area not available
                    PUSH DE
                    PUSH BC                       ; preserve amount of used space
                    
                    LD   C,L
                    CALL FileEprDeletedSpace      ; returns deleted space in DEBC, Fc = 0
                    POP  HL
                    SBC  HL,BC                    ; Used Space - Deleted Space = Active Space
                    LD   B,H
                    LD   C,L                      ; result, BC = low 16bits
                    POP  HL
                    SBC  HL,DE
                    EX   DE,HL                    ; result, DE = high 16bits  
                                                  ; (Fc = 0)
.err_FileEprActiveSpace
                    POP  HL
                    RET
