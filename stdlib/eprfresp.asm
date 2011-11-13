     XLIB FileEprFreeSpace

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

     LIB FileEprRequest, FileEprUsedSpace
     LIB ConvPtrToAddr

     include "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return free space in Standard File Eprom Area, inserted in slot C
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Area available
;         DEBC = Free space available
;
;    Fc = 1, File Area was not found in slot C
;         A = RC_ONF
;
; Registers changed after (successful) return:
;    A.....HL/IXIY same
;    .FBCDE../.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997-Aug 1998, July 2005
; -----------------------------------------------------------------------
;
.FileEprFreeSpace   PUSH HL
                    PUSH AF

                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot
                    JR   C, err_FileEprFreeSpace
                    JR   NZ, err_FileEprFreeSpace ; File Eprom not available in slot...

                    LD   A,E                      ; preserve slot number in A
                    LD   B,C
                    DEC  B
                    LD   HL,$3FC0                 ; File Header at relative BHL (seen from bottom of bank)
                    CALL ConvPtrToAddr            ; File header -> DEBC (total bytes in file area)
                    PUSH DE
                    PUSH BC

                    LD   C,A                      ; slot number.
                    CALL FileEprUsedSpace         ; get used file space in file area in DEBC

                    POP  HL
                    SBC  HL,BC                    ; <Capacity> - <UsedSpace> = Free Space
                    LD   B,H
                    LD   C,L
                    POP  HL
                    SBC  HL,DE
                    EX   DE,HL                    ; return free space of File Eprom in DEBC
.exit_freespace
                    POP  HL
                    LD   A,H                      ; restored original A
                    POP  HL                       ; restored original HL
                    RET
.err_FileEprFreeSpace
                    POP  HL                       ; ignore old AF
                    SCF
                    LD   A, RC_ONF
                    POP  HL                       ; restored original HL
                    RET
