     XLIB FileEprDelSpace

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

     include "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return amount of deleted file space in File Eprom Area, inserted in slot C.
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         DEBC = Amount of deleted file space used on File Eprom
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
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
.FileEprDelSpace
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

                    EXX
                    LD   BC,0
                    LD   D,B
                    LD   E,C
                    EXX
.scan_eprom
                    CALL FileEprFileEntryInfo     ; scan all file entries...
                    CALL CalcDelFileSpace         ; add file space (for deleted file entry)
                    JR   NC, scan_eprom           ; look in next File Entry...

                    EXX                           ; return DEBC (amount of deleted file space)
                    CP   A                        ; Fc = 0, File Eprom parsed...
                    RET
.no_fileepr
                    SCF
                    LD   A,RC_ONF
                    RET


; ************************************************************************
;
; Add file space to current sum, if file is marked as deleted.
;
; IN:
;    Fz = File status (active or deleted)
;    CDE = length of file
;
; OUT:
;    (Amount of deleted file space updated)
;
.CalcDelFileSpace   RET  C                        ; not a valid File Entry
                    RET  NZ                       ; file is active, ignore
                    PUSH AF                       ; preserve Z80 status flags

                    PUSH BC
                    PUSH DE
                    EXX
                    POP  HL
                    ADD  HL,BC
                    LD   B,H
                    LD   C,L
                    POP  HL
                    LD   A,E
                    ADC  A,L
                    LD   E,A                      ; delspace (DEBC) += <file length>
                    EXX

                    POP  AF
                    RET
