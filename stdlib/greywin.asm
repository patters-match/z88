     XLIB GreyApplWindow

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

     INCLUDE "stdio.def"


; ****************************************************************************************
;
; Grey Application window (using base window "1")
;
; Registers changed after return:
;    AFBCDEHL/IXIY same
;    ......../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Copyright (C) InterLogic 1995
; ----------------------------------------------------------------------
;
.GreyApplWindow     PUSH AF
                    PUSH HL
                    LD   HL,greywindow                  ; use base window
                    CALL_OZ(Gn_Sop)                     ; then grey window...
                    POP  HL
                    POP  AF
                    RET
.greywindow         DEFM 1,"7#1",$20,$20,32+$5E,$28,128,1,"2H1" ; window VDU definitions
                    DEFM 1,"2H1",1,"2G+",0
