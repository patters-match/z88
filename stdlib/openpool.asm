    XLIB Open_pool

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

    INCLUDE "memory.def"


; ******************************************************************************
;
; INTERNAL MALLOC ROUTINE
;
; Open a memory pool for segment 1. Memory handle returned in IX if Fc = 0.
; If no memory is available, Fc = 1 is returned (IX unchanged).
;
; Register status on return:
; A.BCDEHL/..IY  same
; .F....../IX..  different
;
; -----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; -----------------------------------------------------------------------
;
.Open_pool          PUSH BC
                    PUSH AF                         ; preserve A
                    LD   A,MM_S1                    ; memory mask for segment 1 (&40)
                    LD   BC,0
                    CALL_OZ(OS_MOP)                 ; open pool (initial 256 byte size)
                    POP  BC
                    LD   A,B                        ; A restored
                    POP  BC                         ; BC restored
                    RET
