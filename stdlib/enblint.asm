     XLIB EnableInt

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     INCLUDE "interrpt.def"


; ***************************************************************************
;
; Enable (previous) Interrupt Status (performed by <DisableInt>).
;
; IN:
;    IX = old interrupt status
;
; OUT:
;    -
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
.EnableInt          PUSH AF
                    PUSH IX
                    POP  AF
                    CALL OZ_EI               ; restore old Int. status
                    POP  AF
                    RET
