	XLIB ApplSegmentMask

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

	include "memory.def"


; ********************************************************************
; ApplSegmentMask
;
; This library routine returns the segment mask of this
; executing library routine.
;
; The sole purpose of this is for the application to
; determine which segment it is running in.
;
;	In:
;		None.
;	Out:
;		A = MM_Sx
;
;	Registers changed after return:
;		..BCDEHL/IXIY same
;		AF....../.... different
;
.ApplSegmentMask	EX	(SP),HL		; get return address
				LD	A,H
				AND	@11000000		; preserve only MM_Sx of PC
				EX	(SP),HL
				RET
