; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $105d
;
; $Id$
; -----------------------------------------------------------------------------

        Module Error

        org     $d05d                           ; 111 bytes

        include "all.def"
        include "sysvar.def"

xdef	OSErh	
xdef	CallErrorHandler

defc	DefErrHandler		=$00e0
defc	JumpToAHL		=$00d4
defc	OZCallReturn2		=$00ac


;	set error handler

.OSErh
	ld	hl, (pAppErrorHandler)		; remember old handler
	push	hl
	exx
	ld	a, h				; if HL=0 use default handler
	or	l				; !! note that if you had AT2_IE set
	jr	nz, oserh_1			; !! in	DOR this enables error return
	ld	hl, DefErrHandler		; !! ld l,<DefErrHandler
.oserh_1
	ld	(pAppErrorHandler), hl
	pop	hl				; get old handler
	exx
	ld	a, (ubAppCallLevel)		; remember old call level
	dec	a				; -1 for Os_Erh
	push	af				; !! just ex af,af' after setting new value
	ex	af, af'
	inc	a				; +1 for OS_Erh
	ld	(ubAppCallLevel), a		; set new call level
	pop	af
	or	a
	jp	OZCallReturn2

;	----

;	get error context

.OSErc
	ld	ix, 0
	exx
	ld	bc, (ubAppDynID)		; resumption cycle, dynamic id
	exx
	ld	a, (ubAppLastError)		; last error code
	or	a
	jp	OZCallReturn2

;	----

.CallErrorHandler
	push	bc
	push	de
	push	hl
	exx
	push	bc
	push	de
	push	hl
	push	af

.cerh_1
	push	af				; push bank
	ex	af, af'
	ld	(ubAppLastError), a
	OZ	GN_Esp				; only for Fz
	scf					; for AppErrorHandler
	ex	af, af'	

	ld	hl, (pAppErrorHandler)
	pop	af				; bank
	push	af
	call	JumpToAHL
	pop	af
	ex	af, af'				; error/flags from AppErrorHandler
	jr	c, cerh_4
	jr	z, cerh_3			; not fatal? exit
	ex	af, af'
	call	JumpToAHL
	jr	$PC				; crash

.cerh_3
	scf
	ex	af, af'
	pop	af
	pop	hl
	pop	de
	pop	bc
	exx
	pop	hl
	pop	de
	pop	bc
	ret

.cerh_4
	ld	hl, ubAppCallLevel
	inc	(hl)
	OZ	GN_Err				; display an interactive error box
	dec	(hl)
	ex	af, af'
	pop	af
	push	af
	jr	cerh_1
