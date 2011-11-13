     XLIB FileEprTotalSpace

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

     LIB FileEprRequest
     LIB FileEprFileEntryInfo

     include "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return amount of active and deleted file space (in bytes) in File Eprom Area,
; inserted in slot C.
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         BHL = Amount of active file space in bytes (24bit integer, B = MSB)
;         CDE = Amount of deleted file space in bytes (24bit integer, C = MSB)
;
;    Fc = 1,
;         A = RC_ONF
;         File Eprom was not found in slot C.
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, July 2005
; ------------------------------------------------------------------------
;
.FileEprTotalSpace
                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot
                    JR   C, no_fileepr
                    JR   NZ, no_fileepr           ; File Eprom not available in slot...

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
                    PUSH HL
                    EXX
                    POP  HL
                    POP  DE
                    POP  BC                       ; BC', DE' & HL' = 0
                    EXX
.scan_eprom
                    CALL FileEprFileEntryInfo     ; scan all file entries...
                    CALL CalcFileSpace            ; summarize file space (active/deleted file entry)
                    JR   NC, scan_eprom           ; look in next File Entry...

                    EXX                           ; return BHL, CDE (amount of active/deleted file space)
                    CP   A                        ; Fc = 0, File Eprom parsed...
                    RET
.no_fileepr
                    SCF
                    LD   A,RC_ONF
                    RET


; ************************************************************************
;
; Add file space to current sum of active or deleted file space.
;
; IN:
;    Fz = File status (active or deleted)
;      A = length of filename
;    CDE = length of file
;
; OUT:
;    (Amount of active/deleted file space updated)
;
.CalcFileSpace      RET  C                        ; not a valid File Entry
                    PUSH AF                       ; preserve Z80 status flags
                    ADD  A,4+1                    ; header size = length of filename + 1 + 4
                    PUSH HL
                    LD   H,0
                    LD   L,A
                    ADD  HL,DE
                    LD   A,0
                    ADC  A,C
                    LD   C,A
                    EX   DE,HL                    ; CDE = total size of file (hdr + file image)
                    POP  HL
                    POP  AF
                    PUSH IX                       ; use IX temporarily as 16bit accumulator...
                    CALL NZ, sum_actfile
                    CALL Z, sum_delfile
                    POP  IX
                    RET
.sum_actfile                                      ; add current file size to sum of active files
                    PUSH AF                       ; preserve Z80 status flags
                    LD   A,C
                    PUSH DE                       ; add file size (in CDE) to BHL'...
                    EXX
                    PUSH HL
                    POP  IX
                    EX   DE,HL
                    POP  DE
                    ADD  IX,DE
                    EX   DE,HL                    ; original DE restored (of deleted file space)
                    PUSH IX
                    POP  HL                       ; HL += active file size (low 16bit of 24bit)
                    ADC  A,B
                    LD   B,A                      ; B += active files size (high 8 bit of 24bit)
                    EXX
                    POP  AF
                    RET
.sum_delfile
                    PUSH AF                       ; preserve Z80 status flags
                    LD   A,C
                    PUSH DE                       ; add file size (in CDE) to CDE'...
                    EXX
                    PUSH DE
                    POP  IX
                    POP  DE
                    ADD  IX,DE
                    PUSH IX
                    POP  DE                       ; DE += deleted file size (low 16bit of 24bit)
                    ADC  A,C
                    LD   C,A                      ; C += deleted files size (high 8 bit of 24bit)
                    EXX
                    POP  AF
                    RET
