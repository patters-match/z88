     XLIB FileEprRandomID

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

     LIB SafeSegmentMask
     LIB MemReadLong
     LIB FileEprRequest

     include "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return File Eprom "oz" Header Random ID from slot x (1, 2 or 3)
;
; In:
;    C = slot number (1, 2 or 3)
;
; Out:
;    Success:
;         Fc = 0,
;              DEBC = Random ID (32bit integer)
;
;    Failure:
;         Fc = 1,
;         A = RC_ONF, File Eprom not found
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
; -----------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; -----------------------------------------------------------------------
;
.FileEprRandomID
                    LD   E,C                 ; preserve slot number
                    CALL FileEprRequest      ; check for presence of "oz" File Eprom in slot
                    JR   C, err_nofileepr
                    JR   NZ, err_nofileepr   ; File Eprom not available in slot...

                    LD   A,E
                    AND  @00000011           ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    OR   B                   ; absolute bank number of "oz" header...

                    CALL SafeSegmentMask     ; Get a safe segment address mask
                    OR   $3F
                    LD   H,A
                    LD   L,0                 ; address $3Foo in top bank of slot B

                    LD   A,$F8               ; offset $F8, position of Random ID
                    CALL MemReadLong
                    EXX                      ; return Random ID in DEBC...
                    CP   A                   ; Fc = 0...
                    RET
.err_nofileepr
                    SCF
                    LD   A,RC_ONF
                    RET
