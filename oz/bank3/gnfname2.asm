; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $ded3
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNFName2

        org $ded3                               ; 1543 bytes

        include "all.def"
        include "sysvar.def"


defc	Ld_A_HL			=$C07A
defc	Ld_A_BHL		=$D43C
defc	AddPathPart		=$DAAA
defc	WriteOsfDE		=$ED8F
defc	GnClsMain		=$EEC1
defc	PutOsf_Err		=$EF60
defc	GetOsf_HL		=$EF6B
defc	GetOsf_DE		=$EF72
defc	PutOsf_DE		=$EF79
defc	PutOsf_HL		=$EF83


;       wildcard handle data

defvars 0 {
wc_eLink                ds.p    1
wc_pMemPool             ds.w    1
wc_Flags                ds.b    1
wc_NodeCount            ds.b    1
wc_MatchDepth           ds.b    1
wc_AllocSize            ds.b    1
wc_Buffer               ds.b    1
}

defc    WCF_B_BACKWARD          =0
defc    WCF_B_FULLPATH          =1
defc    WCF_B_HASFILENODE       =2
defc    WCF_B_BRANCHDONE        =3

defvars 0 {
fsn_eLink               ds.p    1
fsn_pDOR                ds.w    1
fsn_pWcStartPtr         ds.w    1
fsn_pWcEndPtr           ds.w    1
fsn_ubType              ds.b    1
fsn_ubFlags             ds.b    1
fsn_ubNewDorFlags       ds.b    1
fsn_ubNewDorType        ds.b    1
fsn_Buffer              ds.b    1
}

defc    FSNF_B_WILDDIR          =0
defc    FSNF_B_HADMATCH         =1
defc    FSNF_B_HASNAME          =2
defc    FSNF_B_HASNEWDOR        =3
	
;	----

;	parse filename
;
;IN:	BHL=filename
;OUT:	B=#segments, C=length (including terminator), A=flags
;	  A0: extension used
;	  A1: filename used
;	  A2: explicit directory used
;	  A3: current directory (".") used
;	  A4: parent directory ("..") used
;	  A5: wildcard directory ("//") used
;	  A6: device specified
;	  A7: wildcards used
;	Fc=1, A=error
;
;CHG:	AFBC..../....

.GNPrs
	OZ	OS_Bix				; bind filename	in
	push	de
	xor	a				; clear	flags, #segments and #chars
	ld	(iy+OSFrame_A),	a		; !! keep flags/#segments in DE
	ld	(iy+OSFrame_B),	a
	ld	(iy+OSFrame_C),	a
	push	hl

.prs_1
	OZ	GN_Pfs				; parse	next segment
	jr	c, prs_end			; error	or end?

	ld	c, a
	bit	1, (iy+OSFrame_A)
	jr	nz, prs_errIvf			; had filename already? error

	res	0, (iy+OSFrame_A)		; no extension yet
	and	$7A				; device, "//", "..", ".", filename
	and	(iy+OSFrame_A)
	jr	nz, prs_errIvf			; already has one? error

;	!! this logic could be done shorter
;
;	ld	a, $18				; "." or ".."
;	bit	5, (iy+OSFrame_A)
;	jr	z, prs_2
;	or	$04				; add explicit directory
;.prs_2	and	c
;	jr	z, ok
;	ld	a, $24
;	and	(iy+OSFrame_A)
;	jr	nz, prs_errIvf

	ld	a, $18				; got "." or ".."
	and	c
	jr	z, prs_2
	ld	a, $24				; had "//" or explicit directory
	and	(iy+OSFrame_A)
	jr	nz, prs_errIvf			; can't have them together
.prs_2
	ld	a, $1C				; got ".."  "." or explicit directory
	and	c
	jr	z, prs_3
	bit	5, (iy+OSFrame_A)		; had "//"
	jr	nz, prs_errIvf			; can't have them together

.prs_3
	ld	a, c				; add new flags, add #segments
	or	(iy+OSFrame_A)
	ld	(iy+OSFrame_A),	a
	inc	(iy+OSFrame_B)
	jr	prs_1

.prs_end
	cp	RC_Eof				; EOF is ok
	jr	nz, prs_err
	ld	a, (iy+OSFrame_B)		; #segments
	or	a
	jr	z, prs_errIvf			; nothing in buffer? error

	pop	de
	sbc	hl, de
	inc	l
	ld	(iy+OSFrame_C),	l		; length
	jr	prs_7

.prs_errIvf
	ld	a, RC_Ivf			; invalid filename
.prs_err
	call	PutOsf_Err
	pop	de

.prs_7
	pop	de
	OZ	OS_Box
	ret

;	----

;	parse filename segment
;
;IN:	BHL=filename segment
;OUT:	BHL=terminating character, A=flags
;	  A0: extension used
;	  A1: filename used
;	  A2: explicit directory used
;	  A3: current directory (".") used
;	  A4: parent directory ("..") used
;	  A5: wildcard directory ("//") used
;	  A6: device specified
;	  A7: wildcards used
;	Fc=1, A=error
;
;CHG:	AF....HL/....

.GNPfs
	xor	a				; clear	flags
	ld	(iy+OSFrame_A),	a		; !! keep this in a'

	OZ	OS_Bix				; bind filename	in
	push	de

	ld	d, h
	ld	e, l

;	check for device

	ld	a, (hl)
	cp	':'
	jr	nz, pfs_slash
	inc	hl
	set	6, (iy+OSFrame_A)		; device specified
	jr	pfs_segment			; check device name

;	check for '/' or '//'

.pfs_slash
	set	2, (iy+OSFrame_A)		; assume explicit directory

	cp	'/'
	jr	z, pfs_2
	cp	'\'
	jr	nz, pfs_dot			; not slash, test dot
.pfs_2
	inc	hl				; if we	have another slash it's wildcard
	ld	a, (hl)
	cp	'/'
	jr	z, pfs_3
	cp	'\'
	jr	nz, pfs_segment			; no, normal segment separator

.pfs_3
	ld	a, (iy+OSFrame_A)
	and	~4				; clear	explicit directory
	or	$a0				; wildcards, "//"
	ld	(iy+OSFrame_A),	a
	jp	pfs_x

;	check for '.' or '..'

.pfs_dot
	cp	'.'                     	; check for current/parent dir
	jr	nz, pfs_segment
	ld	c, 8				; '.'
	inc	hl
	ld	a, (hl)				; !! 'cp (hl)'
	cp	'.'
	jr	nz, pfs_5
	ld	c, $10				; '..'
	inc	hl
.pfs_5
	ld	a, (hl)
	cp	$21
	jr	c, pfs_6			; end or slash?	ok
	cp	'/'
	jr	z, pfs_6
	cp	'\'
	jr	nz, pfs_erIvf			; else invalid name
.pfs_6
	ld	a, (iy+OSFrame_A)
	and	~4				; clear	explicit directory
	or	c				; either '.' or '..'
	ld	(iy+OSFrame_A),	a
	jr	pfs_x

;	parse segment

.pfs_segment
	call	HandleFilename
	jr	c, pfs_err

	ld	a, (hl)				; get terminating char
	cp	'.'
	jr	nz, pfs_9

	ld	a, (iy+OSFrame_A)
	and	$40				; device specified?
	jr	z, pfs_extension		; not device? get extension
	inc	hl
	ld	a, (hl)				; get char after '.'
	dec	hl
	cp	'.'                     	; exit if ':dev..', ':dev./'
	jr	z, pfs_x
	cp	'/'
	jr	z, pfs_x
	cp	'\'
	jr	z, pfs_x

.pfs_extension
	inc	hl				; skip '.'
	call	HandleExtension
	jr	c, pfs_erIvf
	set	0, (iy+OSFrame_A)		; extension

;	finish test by checking for file/dir status

.pfs_9
	bit	6, (iy+OSFrame_A)		; device
	jr	nz, pfs_x
	ld	a, (hl)				; if it	doesn't end with '.' or '/' it's file
	cp	'.'
	jr	z, pfs_x
	cp	'/'
	jr	z, pfs_x
	cp	'\'
	jr	z, pfs_x
	res	2, (iy+OSFrame_A)		; explicit directory
	set	1, (iy+OSFrame_A)		; filename
	jr	pfs_x

.pfs_erIvf
	ld	a, RC_Ivf			; Invalid filename
.pfs_err
	call	PutOsf_Err
.pfs_x
	or	a				; return end ptr
	sbc	hl, de
	ld	d, (iy+OSFrame_H)
	ld	e, (iy+OSFrame_L)
	add	hl, de
	call	PutOsf_HL

	pop	de
	OZ	OS_Box
	ret

;	----

;	check filename/extension

.HandleFilename
	ld	b, 12				; max 12 chars
	jr	HandlePart

.HandleExtension
	ld	b, 3				; max 3 chars

.HandlePart
	ld	c, -1
.hp_1
	call	HandleWild			; skip '*'
	call	FilenameCls
	jr	c, hp_2				; alpha
	jr	z, hp_2				; number, '-'
	cp	'?'
	jr	nz, hp_3
	set	7, (iy+OSFrame_A)		; wildcards
.hp_2
	djnz	hp_1
	call	HandleWild			; skip '*'
.hp_3
	dec	hl				; decrement pointer
	call	FilenameCls			; recheck last char
	jr	c, hp_errIvf			; alpha	- too long
	jr	z, hp_errIvf			; numeric or '-' - too long
	cp	'?'
	jr	z, hp_errIvf			; '?' - too long

	ld	a, c				; did we get anything?
	or	a
	jr	nz, hp_6
	bit	6, (iy+OSFrame_A)		; device
	jr	nz, hp_errIvf			; ':' only? error

	ld	a, RC_Eof			; End Of File
	jr	hp_err
.hp_errIvf
	ld	a, RC_Ivf			; Invalid filename
.hp_err
	scf
.hp_6
	ret

;	----

;	skip chars until not '*', return last char

.HandleWild
	ld	a, (hl)
	inc	hl
	inc	c
	cp	'*'
	ret	nz
	set	7, (iy+OSFrame_A)		; wildcards
	jr	HandleWild
	ret					; !! unnecessary

;	----

;	match filename segment to wildcard string
;
;IN:	DE=segment, HL=wildcard
;OUT:	Fz=1 if match, DE=segment end, HL=wildcard end
;	Fz=0 if miss, DE/HL unchanged
;
;CHG:	.F..DEHL/....

.GNWsm
	ld	hl, -17				; temp space for filename
	add	hl, sp
	ld	sp, hl
	ex	de, hl
	push	de
	push	de

	ld	b, 0				; bind in segment
	OZ	OS_Bix
	ex	(sp), hl			; ex(sp), de
	ex	de, hl
	ex	(sp), hl

;	copy segment to stack
;	!! no overflow check

.wsm_1
	ld	a, (hl)
	ld	(de), a
	cp	$21
	jr	c, wsm_2
	inc	hl
	inc	de
	jr	wsm_1
.wsm_2
	pop	de				; restore bindings
	OZ	OS_Box

	call	GetOsf_HL			; bind in wildcard
	ld	b, 0
	OZ	OS_Bix
	ex	(sp), hl			; ex (sp), de
	ex	de, hl
	ex	(sp), hl

	ex	de, hl				; HL=stack buffer, DE=wildcard
	OZ	GN_Prs				; parse	segment
	ex	de, hl				; !! do	this after 'jp c' for logic
	jp	c, wsm_retMiss			; bad name

	ld	b, 0
	OZ	GN_Prs				; parse	wildcard
	jp	c, wsm_retMiss			; bad wildcard

	push	hl				; bc'=wildcard start
	exx
	pop	bc
	exx

	ld	c, 0				; '*' flag
.wsm_loop
	ld	a, (de)				; segment char
	call	FilenameCls
	jr	nc, wsm_4			; not alpha
	and	$df				; upper()
	jr	wsm_5
.wsm_4
	jr	z, wsm_5			; numeric
	cp	'.'
	jr	nz, wsm_12

;	segment char: A-Z 0-9 - .

.wsm_5
	ld	b, a

.wsm_6
	ld	a, (hl)				; wildcard char
	call	FilenameCls
	jr	nc, wsm_7			; not alpha
	and	$df				; upper()
	jr	wsm_cp
.wsm_7
	jr	z, wsm_cp			; numeric
	cp	'.'
	jr	z, wsm_cp
	cp	'?'
	jr	z, wsm_cp
	cp	'*'
	jr	nz, wsm_13
	ld	c, 1				; has '*'
	inc	hl				; skip it
	push	hl				; remember pointers in hl' and de'
	push	de
	exx
	pop	de
	pop	hl
	exx
	jr	wsm_6				; get new wildcard char

;	wildcard char: A-Z 0-9 - . ?

.wsm_cp
	cp	b
	jr	z, wsm_match
	cp	'?'				; '?' matches anything but '.'
	jr	nz, wsm_miss
	ld	a, (de)
	cp	'.'                     	; !! 'cp b'
	jr	z, wsm_retMiss			; wild '?', name '.' - return miss

.wsm_match
	ld	a, b				; extension separator?
	cp	'.'
	jr	nz, wsm_10
	ld	c, 0				; discard '*' pointers
.wsm_10
	inc	de
	inc	hl
	jr	wsm_loop

.wsm_miss
	ld	a, c				; if we	don't have '*' we return miss
	or	a
	jr	z, wsm_retMiss
	exx					; restore pointers from	de' hl',
	inc	de				; bump segment
	push	de
	push	hl
	exx
	pop	hl
	pop	de
	jr	wsm_loop			; retry from next segment char

;	segment exhausted

.wsm_12
	ld	a, (hl)				; check if wildcard over too
	call	FilenameCls
	jr	c, wsm_retMiss			; fail if A-Z 0-9 - . ?
	jr	z, wsm_retMiss
	cp	'.'
	jr	z, wsm_retMiss
	cp	'?'
	jr	z, wsm_retMiss
	cp	'*'				; skip trailing '*'
	jr	nz, wsm_retMatch		; else match
	inc	hl
	jr	wsm_12

;	wildcard exhausted
;
;	!! is this ever reached?

.wsm_13
	ld	a, (de)				; check if segment over too
	call	FilenameCls
	jr	c, wsm_miss			; fail if A-Z 0-9 - .
	jr	z, wsm_miss
	cp	'.'
	jr	z, wsm_miss

.wsm_retMatch
	set	Z80F_B_Z, (iy+OSFrame_F)
	exx					; calculate wildcard end address
	push	bc
	exx
	pop	bc
	or	a
	sbc	hl, bc
	ld	b, (iy+OSFrame_H)
	ld	c, (iy+OSFrame_L)
	add	hl, bc
	call	PutOsf_HL

	ex	de, hl				; calculate segment end address
	ld	bc, 2
	or	a
	sbc	hl, bc				; !! 'dec hl; dec hl'
	sbc	hl, sp
	ld	b, (iy+OSFrame_D)
	ld	c, (iy+OSFrame_E)
	add	hl, bc
	ld	(iy+OSFrame_D),	h
	ld	(iy+OSFrame_E),	l

.wsm_retMiss
	pop	de
	OZ	OS_Box

	ld	hl, 17				; fix stack
	add	hl, sp
	ld	sp, hl
	ret

;	----

; !! unused
.sub_E129
	call	IsSegSeparator
	ret	nz
	inc	hl
	dec	b
	ret

;	----

; !! unused
.sub_E130
	ld	a, (de)
	call	FilenameCls
	jr	c, loc_E137
	ret	nz
.loc_E137
	inc	de
	jr	sub_E130

;	----

;	read & write filename segments
;
;IN:	A=command (A7=0: read, A7=1: write, A0=0: name, A1=1: extension)
;	B=segment number (+/-64)
;	read:  HL=filename, DE=buffer
;	write: HL=segment, DE=buffer, C=buffer size
;OUT:	read:  C=#chars, DE=buffer end (if DE>255)
;	write: B=#segments, C=#chars, DE=buffer end (if DE>255) or DE(in)-1 (DE<256)
;	Fc=1, A=error
;
;CHG:	read:  AF.CDE../....
;	write: AFBCDE../....

.GNEsa
	bit	7, (iy+OSFrame_A)
	jr	z, esa_1			; !! 'jr z' to 'ld hl, ...'
	ex	de, hl				; HL=DE
.esa_1
	ex	de, hl				; DE=HL
	ld	hl, -205			; reserve temp space
	add	hl, sp
	ld	sp, hl
	ex	de, hl				; bind filename(r) or buffer (w) in
	ld	b, 0
	push	de
	OZ	OS_Bix
	ex	(sp), hl			; ex (sp), de
	ex	de, hl
	ex	(sp), hl

	ld	c, 205
	OZ	GN_Fex				; expand name/buffer into stack
	pop	de
	push	af
	OZ	OS_Box				; restore binding
	pop	af
	jp	c, esa_err

	ld	a, (iy+OSFrame_B)		; segment number
	or	a				; if negative check for validity
	jp	p, esa_2
	add	a, b				; + #segments
	jr	c, esa_2
	ccf					; !! scf
	ld	a, RC_Bad
	jp	esa_err

.esa_2
	ld	c, a				; segment number (now >= 0)
	ld	b, 0				; BHL=source=sp
	ld	h, b
	ld	l, b
	add	hl, sp
	ld	de, GnFnameBuf			; DE=dest
	jr	z, esa_4			; segment=0? don't skip any

;	copy C parts from BHL to DE
;	!! none of the code below handles buffer overflow

.esa_3
	call	AddPathPart
	dec	c
	jr	nz, esa_3

.esa_4
	bit	7, (iy+OSFrame_A)
	jr	z, esa_read

;	replace filename segment/extension with new one

	ld	a, (hl)				; copy separating char
	ld	(de), a
	inc	hl
	inc	de

	bit	0, (iy+OSFrame_A)
	jr	z, esa_wrname

;	copy from BHL to DE until not A-Z 0-9 - ? *

.esa_extension
	ld	a, (hl)
	call	WildCls
	jr	c, esa_6			; alpha
	jr	nz, esa_7			; not number
.esa_6
	ld	(de), a
	inc	de
	inc	hl
	jr	esa_extension

.esa_7
	ld	a, '.'                  	; add extension separator
	ld	(de), a
	inc	de
	ld	a, (hl)				; !! cp	(hl)
	cp	'.'
	jr	nz, esa_8
	inc	hl				; skip extension
	call	EsaSkipSeg
.esa_8
	ld	b, 3				; copy max 3 chars
	jr	esa_10

.esa_wrname
	call	EsaSkipSeg			; skip name
	ld	b, 12				; copy max 12 chars

.esa_10
	push	hl
	call	GetOsf_HL			; new segment/extension
.esa_11
	call	Ld_A_HL				; read char
	cp	$21
	jr	c, esa_12			; end
	ld	(de), a				; write	to buffer, loop
	inc	de				; until B chars done
	inc	hl
	djnz	esa_11
.esa_12
	pop	hl
.esa_13
	ld	a, (hl)				; copy rest of original	name
	ld	(de), a
	cp	$21
	jr	c, esa_14
	inc	hl
	inc	de
	jr	esa_13
.esa_14
	ld	hl, GnFnameBuf			; compress to destination buffer
	ld	b, 0
	call	CompressFN
	jr	esa_err

;	copy filename part into buffer

.esa_read
	inc	hl				; skip separator
	bit	0, (iy+OSFrame_A)
	jr	z, esa_rdname
	call	EsaSkipSeg			; skip name part
	cp	'.'                     	; skip separator if '.'
	jr	nz, esa_rdname
	inc	hl
.esa_rdname
	ld	(iy+OSFrame_C),	0
.esa_17
	ld	a, (hl)
	call	WildCls
	jr	c, esa_18			; alpha
	jr	z, esa_18			; number
	xor	a
.esa_18
	call	WriteOsfDE
	inc	hl
	inc	(iy+OSFrame_C)
	or	a
	jr	nz, esa_17
.esa_err
	ex	af, af'
	ld	hl, 205
	add	hl, sp
	ld	sp, hl
	ex	af, af'
	call	c, PutOsf_Err
	ret

;	----

; skip a-z A-Z 0-9 * - ?

.EsaSkipSeg
	ld	a, (hl)
	call	WildCls
	jr	c, ess_1			; alpha
	ret	nz				; non-numeric
.ess_1
	inc	hl
	jr	EsaSkipSeg

;	----

;IN:	IY=FsNode
;OUT:	Fc=0 if found

.FindMatchingFsNode
	push	ix
	call	LdIX_FsnDOR
	bit	FSNF_B_HASNEWDOR, (iy+fsn_ubFlags) ; already got new DOR?
	jr	z, fmn_1
	res	FSNF_B_HASNEWDOR, (iy+fsn_ubFlags) ; use it, update type/flags
	ld	h, (iy+fsn_ubNewDorType)
	ld	l, (iy+fsn_ubNewDorFlags)
	push	hl
	pop	af
	jr	fmn_5

.fmn_1
	bit	FSNF_B_HASNAME,	(iy+fsn_ubFlags) ; already has name? skip
	jr	nz, fmn_4
.fmn_2
	call	LeaHL_FsnBuffer
	push	hl
	ld	d, h
	ld	e, l
	ld	bc, 'N'<<8|17
	ld	a, DR_RD
	OZ	OS_Dor				; read name
	pop	de				; !! no push above, 'ld d,h; ld e,l'
	set	FSNF_B_HASNAME,	(iy+fsn_ubFlags)
	ld	a, (iy+fsn_ubType)
	cp	DN_DIR
	jr	nz, fmn_3
	bit	FSNF_B_WILDDIR,	(iy+fsn_ubFlags) ; '//'? always match dir
	jr	nz, fmn_7
.fmn_3
	call	MatchFsNode			; match	this name
	jr	z, fmn_6			; match? end
.fmn_4
	ld	a, DR_SIB
	OZ	OS_Dor				; get brother
	call	LdFsnDOR_IX
.fmn_5
	jr	c, fmn_6			; !! jr	directly to 'pop ix'
	ld	(iy+fsn_ubType), a
	jr	fmn_2				; test brother

.fmn_6
	jr	c, fmn_8
	ld	(iy+fsn_pWcEndPtr+1), h
	ld	(iy+fsn_pWcEndPtr), l
.fmn_7
	res	FSNF_B_HADMATCH, (iy+fsn_ubFlags)
.fmn_8
	pop	ix
	ret

;	----

.MatchFsNode
	call	LeaHL_FsnBuffer
	ex	de, hl
	ld	h, (iy+fsn_pWcStartPtr+1)
	ld	l, (iy+fsn_pWcStartPtr)
	inc	hl				; skip separator
	OZ	GN_Wsm				; match	filename segment to wildcard string
	ret

;	----

.LdIX_FsnDOR
	push	de
	ld	d, (iy+fsn_pDOR+1)
	ld	e, (iy+fsn_pDOR)
	push	de
	pop	ix
	pop	de
	ret

;	----

.LdFsnDOR_IX
	push	de
	push	ix
	pop	de
	ld	(iy+fsn_pDOR+1), d
	ld	(iy+fsn_pDOR), e
	pop	de
	ret

;	----

.FreeDOR
	push	de
	push	ix				; free DOR handle in IX	if non-zero
	pop	de
	ld	a, d
	or	e
	jr	z, fdor_1			; !! 'pop de;ret z'
	ld	a, DR_FRE
	OZ	OS_Dor
.fdor_1
	pop	de
	ret

;	----

.LeaHL_FsnBuffer
	push	iy
	pop	hl
	push	de
	ld	de, fsn_Buffer
	add	hl, de
	pop	de
	ret

;	----

;IN	IY=FsNode
;OUT:	IX=DOR
;	Fc=1, A=error

.GetFsNodeDOR
	push	iy
	ld	iy, -30				; temp FsNode
	add	iy, sp
	ld	sp, iy

	push	iy				; clear	it
	pop	hl
	ld	c, 30
.gfsnd_1
	ld	(hl), 0				; !! 'xor a' and clear with it
	inc	hl
	dec	c
	jr	nz, gfsnd_1

	ld	hl, GnFnameBuf			; holds	file name
	jr	gfsnd_3
.gfsnd_2
	ld	h, (iy+fsn_pWcEndPtr+1)
	ld	l, (iy+fsn_pWcEndPtr)
.gfsnd_3
	ld	(iy+fsn_pWcStartPtr+1), h
	ld	(iy+fsn_pWcStartPtr), l
	push	bc
	ld	b, 0
	OZ	GN_Pfs				; parse	filename segment
	ld	(iy+fsn_pWcEndPtr+1), h
	ld	(iy+fsn_pWcEndPtr), l

	and	$40				; device specified?
	ld	a, DR_SON			; son of IX from below
	jr	z, gfsnd_4			; not device? get son
	ld	hl, RootName_txt		; get device node
	ld	a, DR_GET
.gfsnd_4
	OZ	OS_Dor
	call	LdFsnDOR_IX
	jr	c, gfsnd_err			; !! do this before storing IX
	ld	(iy+fsn_ubType), a
	res	FSNF_B_HASNAME,	(iy+fsn_ubFlags)
	call	FindMatchingFsNode
	jr	nc, gfsnd_6

.gfsnd_err
	pop	bc
	cp	RC_Eof				; EOF -> object	not found
	scf
	jr	nz, gfsnd_x
	ld	a, RC_Onf
	jr	gfsnd_x

.gfsnd_6
	call	LdIX_FsnDOR
	pop	bc
	djnz	gfsnd_2				; loop back while segments left
	ld	a, (iy+fsn_ubType)

.gfsnd_x
	ex	af, af'				; remember Fc
	ld	iy, 30				; restore stack
	add	iy, sp
	ld	sp, iy
	ex	af, af'

	pop	iy
	ret

.RootName_txt
	defm	":",0

;	----

.AllocFsNode
	push	de
	push	bc
	push	hl
	ld	d, (ix+wc_pMemPool+1)
	ld	e, (ix+wc_pMemPool)
	push	de
	ex	(sp), ix
	xor	a
	ld	bc, 30
	OZ	OS_Mal
	pop	ix
	jp	c, afn_8
	inc	(ix+wc_NodeCount)
	push	hl
	ld	de, wc_Buffer
	push	ix
	pop	hl
	add	hl, de
	ex	(sp), hl			; hl=allocated,	stack=wc.buffer
	xor	a
	ld	d, a				; push NULL ptr
	ld	e, a
	push	de
	push	af
	ld	c, (ix+wc_eLink+2)
	ld	d, (ix+wc_eLink+1)
	ld	e, (ix+wc_eLink)
	ld	a, c
	or	d
	or	e
	jr	z, afn_2			; old ptr=NULL?	skip

	pop	af				; discard null DOR, flags and IX buffer
	pop	af
	pop	af
	push	hl				; remember HL, BC
	push	bc

	push	de				; IY=de
	pop	iy
	ld	b, c				; bind old node	in S1
	ld	c, 1
	OZ	OS_Mpb
	exx
	ld	d, (iy+fsn_pDOR+1)
	ld	e, (iy+fsn_pDOR)
	exx
	ld	h, (iy+fsn_pWcEndPtr+1)
	ld	l, (iy+fsn_pWcEndPtr)
	ld	a, (iy+fsn_ubFlags)
	and	1				; WILDDIR
	jr	z, afn_1
	ld	h, (iy+fsn_pWcStartPtr+1)	; yes, redo parent dir
	ld	l, (iy+fsn_pWcStartPtr)
.afn_1
	pop	bc
	ex	(sp), hl
	exx
	push	de
	exx
	push	af

.afn_2
	push	bc				; put new node on the top of list
	ld	c, 1				; bind new mem in S1
	OZ	OS_Mpb
	push	hl				; into IY
	pop	iy
	pop	bc
	ld	(iy+fsn_eLink+2), c		; new.link=old
	ld	(iy+fsn_eLink+1), d
	ld	(iy+fsn_eLink),	e
	ld	(ix+wc_eLink+2), b		; IX.link=new
	ld	(ix+wc_eLink+1), h
	ld	(ix+wc_eLink), l

	pop	af				; old node data (or NULL)
	pop	de				; old DOR
	pop	hl				; IX buffer
	ld	(iy+fsn_ubFlags), a
	ld	(iy+fsn_pWcStartPtr+1), h
	ld	(iy+fsn_pWcStartPtr), l
	push	hl
	push	ix
	ld	a, d
	or	e
	jr	z, afn_3			; DOR=0? start from top

	push	de				; IX=DOR
	pop	ix
	ld	a, DR_DUP
	OZ	OS_Dor
	pop	ix
	push	bc				; new DOR
	jr	c, afn_4
	ex	(sp), ix
	ld	a, DR_SON
	OZ	OS_Dor
	ex	(sp), ix
	jr	afn_4

.afn_3
	ld	hl, RootName_txt
	ld	a, DR_GET
	OZ	OS_Dor
	ex	(sp), ix

.afn_4
	pop	de
	ld	(iy+fsn_pDOR+1), d
	ld	(iy+fsn_pDOR), e
	pop	hl
	jr	c, afn_7

	ld	(iy+fsn_ubType), a
.afn_5
	ld	b, 0
	OZ	GN_Pfs				; parse	filename segment
	jr	c, afn_7
	bit	5, a				; wildcard directory ("//") used?
	jr	z, afn_6
	set	FSNF_B_WILDDIR,	(iy+fsn_ubFlags)
	ld	(iy+fsn_pWcStartPtr+1), h
	ld	(iy+fsn_pWcStartPtr), l
	jr	afn_5
.afn_6
	ld	(iy+fsn_pWcEndPtr+1), h
	ld	(iy+fsn_pWcEndPtr), l
	or	a
.afn_7
	jr	nc, afn_8
	push	af				; in case of error
	call	FreeTopFsNode			; free new node
	push	ix
	pop	iy
	call	NextFsNode			; and return top of list
	pop	af

.afn_8
	pop	hl
	pop	bc
	pop	de
	ret

;	----

.FreeTopFsNode
	ld	b, (ix+wc_eLink+2)
	ld	h, (ix+wc_eLink+1)
	ld	l, (ix+wc_eLink)
	ld	a, b
	or	h
	or	l
	jr	z, ftfsn_x			; !! ret z

	ld	e, b				; bind node in S1
	ld	c, 1
	OZ	OS_Mpb

	ld	b, e
	push	hl
	pop	iy
	ld	c, (iy+fsn_eLink+2)		; unlink IY
	ld	d, (iy+fsn_eLink+1)
	ld	e, (iy+fsn_eLink)
	ld	(ix+wc_eLink+2), c
	ld	(ix+wc_eLink+1), d
	ld	(ix+wc_eLink), e
	ld	a, b				; free node
	ld	bc, 30
	ld	d, (ix+wc_pMemPool+1)
	ld	e, (ix+wc_pMemPool)
	push	de
	ex	(sp), ix
	OZ	OS_Mfr
	pop	ix
	dec	(ix+wc_NodeCount)
.ftfsn_x
	ret

;	----

.NextFsNode
	push	de				; !! unnecessary push/pop
	ld	b, (iy+fsn_eLink+2)
	ld	h, (iy+fsn_eLink+1)
	ld	l, (iy+fsn_eLink)
	ld	a, l
	or	h
	or	b
	scf
	ld	a, RC_Eof			; End Of File
	jr	z, nxfn_1			; BHL=0? EOF !!	ret z

	push	bc
	ld	c, 1				; bind memory into S1
	OZ	OS_Mpb				; Bind bank B in slot C
	pop	bc
	push	hl				; and return it	in IY
	pop	iy
	or	a				; Fc=0
.nxfn_1
	pop	de
	ret

;	----

;	BHL=source (bound in)

.CompressFN
	ld	d, h				; DE=source
	ld	e, l
	xor	a
	ld	c, a
	ld	(iy+OSFrame_B),	a		; # of segments

;	count chars until ctrl char

.cfn_1
	call	Ld_A_BHL
	cp	$21
	jr	c, cfn_2
	inc	c
	inc	hl
	jr	cfn_1

.cfn_2
	ld	a, c
	ld	c, (iy+OSFrame_C)		; max dest size
	cp	c
	ld	(iy+OSFrame_C),	0
	jr	c, cfn_5			; string fits as-is
	jr	z, cfn_5
	ld	d, h				; DE=source end
	ld	e, l
	dec	hl

;	go back max buffer size, find segment separator

.cfn_3
	call	Ld_A_BHL
	call	IsSegSeparator
	jr	nz, cfn_4
	ld	d, h				; remember pos of '/\:'
	ld	e, l
.cfn_4
	dec	hl
	dec	c
	jr	nz, cfn_3

;	copy from BHL to OsfDE

.cfn_5
	ex	de, hl				; HL=source
	xor	a				; !! unnecessary
.cfn_6
	call	Ld_A_BHL			; read char
	inc	hl
	call	WriteOsfDE			; write	to output
	inc	(iy+OSFrame_C)			; increment output size
	cp	$21
	jr	c, cfn_7			; ctrl char? end
	call	IsSegSeparator
	jr	nz, cfn_6
	inc	(iy+OSFrame_B)			; increment segment count
	jr	cfn_6

.cfn_7
	call	GetOsf_DE			; decrement output ptr by one
	dec	de				; !! bug if DE<256
	call	PutOsf_DE
	xor	a				; Fc=0
	ret

;	----

.WildCls
	cp	'*'
	ret	z				; Fc=0,	Fz=1 - numeric
	cp	'?'
	ret	z				; Fc=0,	Fz=1 - numeric

;	drop thru

.FilenameCls
	cp	'-'
	ret	z				; Fc=0,	Fz=1 - numeric
	cp	$c0				; !! used by filter?
	jr	c, fncls_1			; !! 'jp c, GnClsMain'
	cp	a				; Fc=0,	Fz=1 - numeric
	ret
.fncls_1
	jp	GnClsMain

;	----

.IsSegSeparator
	cp	'/'                     	; !! compare in 5c-3a-2f order, 'ret nc'
	ret	z
	cp	'\'
	ret	z
	cp	':'
	ret

