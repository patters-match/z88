     XLIB Init_malloc

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

     LIB Alloc_new_pool

     XREF  pool_index                   ; data structures defined in application code
     XREF  allocated_mem                ; variable defined in application code


; ***********************************************************************************
;
;    Very important initial call to be performed by application
;    before using the .malloc routine.
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.Init_malloc        XOR  A
                    LD   (pool_index),A             ; initiate index to first pool
                    LD   C,A
                    LD   HL, 0
                    LD   (allocated_mem),HL
                    LD   (allocated_mem+2),A        ; reset variable
                    CALL Alloc_new_pool             ; then create a pool at index
                    RET
