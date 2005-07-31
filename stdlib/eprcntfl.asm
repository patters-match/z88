     XLIB FileEprCntFiles

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
     LIB FileEprRequest


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Count total of active and deleted files on File Eprom in slot C
; (excl. NULL file on Intel Flash card)
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         HL = total of active (visible) files
;         DE = total of (marked as) deleted files
;         (HL + DE are total files in the file area)
;
;    Fc = 1, File Eprom was not found at slot C
;
; Registers changed after return:
;    ..BC..../IXIY same
;    AF..DEHL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997-Aug 1998, July 2005
; ------------------------------------------------------------------------
;
.FileEprCntFiles    PUSH BC

                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot C
                    JR   C, err_count_files
                    JR   NZ, err_count_files      ; File Eprom not available in slot...

                    LD   A,E
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    SUB  C                        ; C = total banks of File Eprom Area
                    INC  A
                    LD   B,A                      ; B is now bottom bank of File Eprom
                    LD   HL,$0000                 ; BHL points at first File Entry...
                    PUSH HL
                    PUSH HL
                    EXX
                    POP  HL                       ; reset "deleted" files counter
                    POP  DE                       ; reset active files counter
                    EXX

                    ; scan all file entries, and count
.scan_eprom         CALL FileEprFileEntryInfo
                    JR   C, finished              ; No File Entry was available in File Eprom
                    EXX
                    CALL Z,DeletedFile
                    CALL NZ, ActiveFile
                    EXX
                    JR   scan_eprom
.err_count_files
                    SCF
                    JR   exit_count_files
.finished
                    CP   A                        ; Fc = 0, File Eprom parsed.
.exit_count_files
                    EXX
                    POP  BC
                    RET

.DeletedFile        EXX
                    EX   AF,AF'                   ; preserve file status of entry
                    LD   A,C
                    OR   D
                    OR   E
                    EXX
                    JR   Z, ignore_nullfile       ; ignore NULL file
                    INC  DE
.ignore_nullfile    EX   AF,AF'
                    RET
.ActiveFile         INC  HL
                    RET
