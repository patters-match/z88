
	XLIB ApplSegmentMask

	include "memory.def"


; ********************************************************************
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
