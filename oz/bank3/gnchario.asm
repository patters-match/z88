; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $cf40
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNCharIO

        org $cf40                               ; 115 bytes

	include "stdio.def"
        include "sysvar.def"

;       ----

xdef	GNCls
xdef	GNNln
xdef	GNSkc
xdef	GNSkd
xdef	GNSkt

;       ----

xref	GN_ret0
xref	GnClsMain
xref	PutOsf_BC
xref	PutOsf_Err
xref	ReadOsfHL
xref	UngetOsfHL

;	----

;	send newline to stdout
;
;IN:	-
;OUT:	Fc=1, A=error
;
;CHG:	AF....../....

.GNNln
	ld	a, CR
	OZ	OS_Out
	ld	a, LF
	OZ	OS_Out
	ret

;	----

;	classify character
;
;IN:	A=char
;OUT:	Fc=1, Fz=1: lower case alpha
;	Fc=1, Fz=0: upper case alpha
;	Fc=0, Fz=1: numeric
;	Fc=0, Fz=0: not alphanum
;
;CHG:	.F....../....

.GNCls
	call	GnClsMain
	jp	GN_ret0

;	----

;	skip character
;
;IN:	A=char to bypass, HL=source, IX=source handle (if HL<2)
;OUT:	HL=end ptr (if HL>255)
;
;CHG:	.F....HL/....

.GNSkc
.skc_1
	call	ReadOsfHL			; get char, exit on error
	jr	c, skc_err
	cp	(iy+OSFrame_A)			; loop back if it matches A(in)
	jr	z, skc_1
	call	UngetOsfHL			; put char back
	jr	nc, skc_x			; !! we can drop thru, if
.skc_err
	call	PutOsf_Err			 ; !! we do here 'call c,'
.skc_x
	ret

;	----

;	skip delimiters in byte sequence
;
;IN:	A=terminator, HL=source, IX=source handle (if HL<2)
;OUT:	HL=terminator ptr (if HL>255), Fz=1 if terminator seen
;	Fc=1, A=error
;CHG:	AF....HL/....

.GNSkd
.skd_1
	call	ReadOsfHL			; get char, exit on error
	jr	c, skd_err

	cp	(iy+OSFrame_A)			; match? end
	jr	z, skd_2
	cp	HT				; loop on tab, space and ','
	jr	z, skd_1
	cp	' '
	jr	z, skd_1
	cp	','
	jr	z, skd_1
	jr	skd_3

.skd_err
	call	PutOsf_Err
	jr	skd_x
.skd_2
	set	Z80F_B_Z, (iy+OSFrame_F)	; flag terminator
.skd_3
	call	UngetOsfHL			; put byte back
.skd_x
	ret

;	----

;	skip to value
;
;IN:	A=char, BC=max search length (0=unlimited)
;	HL=source, IX=source handle (if HL<2)
;OUT:	BC=remaining length
;	HL=search char ptr (if HL>255)
;	Fc=1, A=error
;
;CHG:	AFBC..HL/....

.GNSkt

	ld	(iy+OSFrame_F),	Z80F_Z		; assume success
	ld	a, b				; E=decrement flag
	or	c
	ld	e, a
.skt_1
	call	ReadOsfHL			; get char, exit on error
	jr	c, skt_err

	cp	(iy+OSFrame_A)			; match search char?
	jr	z, skt_3			; end
	ld	a, e
	or	a
	jr	z, skt_1			; loop without decrement

	dec	bc
	ld	a, b
	or	c
	jr	nz, skt_1			; loop more

	res	Z80F_B_Z, (iy+OSFrame_F)	; Fz=0, char not found
	jr	skt_3

.skt_err
	call	PutOsf_Err
	jr	skt_x

.skt_3
	call	PutOsf_BC			; return remaining length
	call	UngetOsfHL			; put char back
.skt_x
	ret
