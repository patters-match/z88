; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $cb95
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNFilter

        org $cb95                               ; 939 bytes

	include "director.def"
	include "error.def"
	include "memory.def"
	include "sysvar.def"
        include "gndef.def"

;       ----

xdef    GNFlc
xdef    GNFlf
xdef    GNFlo
xdef    GNFlr
xdef    GNFlw
xdef    GNFpb

;       ----

xref    PutOsf_Err
xref    GnClsMain
xref    Upper

;       ----

;       Filters are handled with filter data in S1, table in S2

;       ----

;       open filter
;
;IN:    HL=filter table, A=flags, B=max buffer size (if A2=1)
;          A0=ignore case
;          A1=reverse mode
;          A2=force max buffer size B
; OUT: IX = filter
;
.GNFlo
        ld      a, h
        and     $C0
        rlca
        rlca
        ld      c, a                            ; slot
        OZ      OS_Mgb                          ; get table bank

        ld      a, h                            ; prepare HL for S2
        and     $3F
        or      $80
        ld      h, a
        push    hl
        ld      c, 2
        OZ      OS_Mpb                          ; bind table in S2
        push    bc                              ; remember S2 binding and table
        push    hl

        ld      c, (hl)                         ; BC=table size
        inc     hl
        ld      b, (hl)
        inc     hl

        inc     hl                              ; skip options
        inc     hl

        ex      (sp), hl                        ; entries start into stack
        add     hl, bc                          ; table end address into BC
        ld      b, h                            ; !! check bank crossing here
        ld      c, l

        pop     hl                              ; entries
        ld      e, 0                            ; max entry size
        ld      d, (iy+OSFrame_A)               ; flags
.flo_1
        ld      a, (hl)                         ; search entry size
        or      a                               ; !! should error on zero
        bit     FDF_B_REVERSE, d                ; forward mode? update max size
        call    z, flo_GetMaxBSize
        jr      c, flo_4                        ; bad table
        add     a, l                            ; go to next entry
                                                ; !! use flr_skipentry
        ld      l, a                            ; !! this hangs on zero
        jr      nc, flo_2                       ; !! fix below too
        inc     h
.flo_2
        ld      a, (hl)                         ; replace entry size
        or      a
        bit     FDF_B_REVERSE, d                ; reverse mode? upadate max size
        call    nz, flo_GetMaxBSize
        jr      c, flo_4                        ; bad table
        add     a, l                            ; go to next entry
        ld      l, a
        jr      nc, flo_3
        inc     h
.flo_3
        push    hl                              ; HL = BC, end?
        or      a
        sbc     hl, bc
        pop     hl
        jr      z, flo_4                        ; equal? Fc=0
        jr      c, flo_1                        ; lower? loop
        scf                                     ; bad table, Fc=1
.flo_4
        pop     bc                              ; restore S2
        pop     hl
        push    af
        OZ      OS_Mpb
        pop     af
        jr      nc, flo_5                       ; no error? continue

        ld      (iy+OSFrame_A), RC_Bad          ; bad table
        jr      flo_Err

.flo_5

;       !! we might want to expand max buffer size to 240 bytes to fully use
;       !! the space available

        push    bc                              ; save extended pointer to table
        push    hl

        bit     2, d                            ; force max buffer size?
        jr      z, flo_7                        ; no, use one calculated above
        ld      a, (iy+OSFrame_B)               ; get buffer size, limit to 128
        cp      129
        jr      c, flo_6
        ld      a, 128
.flo_6
        ld      e, a
.flo_7
        ld      a, MM_S1
        ld      bc, 0
        OZ      OS_Mop                          ; get mem pool for S1
        jr      c, flo_ErrA                     ; no mem

        ld      a, fd_SIZEOF                    ; allocate structure + buffer
        add     a, e
        ld      c, a
        xor     a
        ld      b, a
        OZ      OS_Mal
        jr      c, flo_8                        ; no mem

        push    ix
        ld      a, TH_FILT
        OZ      OS_Gth                          ; allocate filter handle, BHL=mem
        jr      nc, flo_11                      ; got handle? continue
        pop     ix

.flo_8
        OZ      OS_Mcl                          ; close mempool

.flo_ErrA
        ld      (iy+OSFrame_A), a               ; return error in A
        pop     hl
        pop     bc

.flo_Err
        set     Z80F_B_C, (iy+OSFrame_F)        ; set Fc
        jr      flo_x

.flo_11
        ld      c, 1
        OZ      OS_Mpb                          ; bind mem in S1
        push    bc
        exx
        pop     bc                              ; bc' = old S1 binding
        pop     de                              ; de' = mempool
        pop     hl                              ; hl' = table
        exx

        ld      a, fd_SIZEOF                    ; clear structure and buffer
        add     a, e
        ld      b, a
        xor     a
        push    hl
.flo_12
        ld      (hl), a
        inc     hl
        djnz    flo_12

        pop     hl                              ; data
        pop     af                              ; bank
        push    hl
        ex      (sp), ix                        ; put memhandle, get data
        exx

        ld      (ix+fd_wMemPool), e             ; init structure
        ld      (ix+fd_wMemPool+1), d
        ld      (ix+fd_eTable+2), a
        ld      (ix+fd_eTable+1), h
        ld      (ix+fd_eTable), l
        ld      a, (iy+OSFrame_A)               ; copy open flags
        and     FDF_IGNORECASE|FDF_REVERSE
        ld      (ix+fd_ubFlags), a

        push    bc                              ; put old S1 binding back
        exx
        ld      (ix+fd_ubBufSize), e
        pop     bc                              ;
        pop     ix                              ; filter handle
        OZ      OS_Mpb                          ; restore S1
.flo_x
        ret

.flo_GetMaxBSize

        cp      1                               ; length 1 is invalid
        jr      z, flo_gmbs2
        cp      e                               ; E = max(E,A)
        jr      c, flo_gmbs2
        ld      e, a
        scf
.flo_gmbs2
        ccf
        ret

;       ----

;       close filter
;
;IN:    IX=filter handle
;OUT:   BC=#char written into filter, DE=#chars read from filter
;
;CHG:   AFBCDE../IX..

.GNFlc
        ld      a, TH_FILT
        OZ      OS_Vth                          ; BHL=handle data
        jr      c, flc_err                      ; bad handle

        push    ix
        ld      c, 1                            ; bind data in S1
        OZ      OS_Mpb
        push    bc                              ; remember binding

        push    hl                              ; IX=data
        pop     ix

        ld      a, (ix+fd_uwWritten+1)          ; BC(out)=written
        ld      (iy+OSFrame_B), a
        ld      a, (ix+fd_uwWritten)
        ld      (iy+OSFrame_C), a
        ld      a, (ix+fd_uwRead+1)             ; DE(out)=read
        ld      (iy+OSFrame_D), a
        ld      a, (ix+fd_uwRead)
        ld      (iy+OSFrame_E), a

        ld      b, (ix+fd_wMemPool+1)           ; close and free memory
        ld      c, (ix+fd_wMemPool)
        push    bc
        pop     ix
        OZ      OS_Mcl

        pop     bc                              ; restore S1 binding
        OZ      OS_Mpb
        pop     ix

        ld      a, TH_FILT
        OZ      OS_Fth                          ; free filter handle
        jr      nc, flc_x
.flc_err
        call    PutOsf_Err
.flc_x
        ret

;       ----

;       write character to filter
;
;IN:    A=char, IX=filter
;OUT:   -
;       Fc=1, A=error
;
;CHG:   AF....../....

.GNFlw
        ld      a, TH_FILT
        OZ      OS_Vth
        jr      c, flw_4                        ; bad handle

        push    ix
        ld      c, 1                            ; bind data in
        OZ      OS_Mpb
        push    bc                              ; remember binding

        push    hl                              ; IX=data
        pop     ix

        ld      a, (ix+fd_ubBufLeft)
        cp      (ix+fd_ubBufSize)
        jr      c, flw_1                        ; space in buffer? ok
        ccf
        ld      a, RC_Flf
        jr      flw_3

.flw_1
        ld      a, (ix+fd_ubBufLeft)            ; !! unnecessary
        add     a, fd_SIZEOF                    ; skip structure
        inc     (ix+fd_ubBufLeft)
        add     a, l                            ; point HL to write position
        ld      l, a
        jr      nc, flw_2
        inc     h
.flw_2
        ld      a, (iy+OSFrame_A)               ; write byte into buffer
        ld      (hl), a
        or      a                               ; Fc=0, return A(in)
.flw_3
        pop     bc                              ; binding
        pop     ix                              ; filter
.flw_4
        push    af                              ; remember return code, set error
        jr      nc, flw_5
        set     Z80F_B_C, (iy+OSFrame_F)
        cp      RC_Hand
        jr      z, flw_6                        ; bad handle, didn't change S1
.flw_5
        OZ      OS_Mpb                          ; Bind bank B in slot C
.flw_6
        pop     af                              ; !! why not set osf_A above?
        ld      (iy+OSFrame_A), a               ; return error code or char written
        ret

;       ----

;       read character from filter
;
;IN:    IX=filter
;OUT:   A=char, Fz=1 if character is converted
;       Fc=1, A=error
;
;CHG:   AF....../....

.GNFlr
        ld      a, TH_FILT
        OZ      OS_Vth
        jp      c, flr_err                      ; bad handle

        push    ix                              ; remember handle
        ld      c, 1                            ; bind data in S1
        OZ      OS_Mpb
        push    bc                              ; remember S1 binding

        push    hl                              ; IX=data
        pop     ix

        ld      l, (ix+fd_eTable)               ; bind table in S2
        ld      h, (ix+fd_eTable+1)
        ld      b, (ix+fd_eTable+2)
        ld      c, 2
        OZ      OS_Mpb
        push    bc                              ; remember S2 binding

        bit     FDF_B_PUSHBACK, (ix+fd_ubFlags) ; get pushback char if there's one
        jr      z, flr_2
        res     FDF_B_PUSHBACK, (ix+fd_ubFlags)
        ld      a, (ix+fd_ubLastChar)
        bit     FDF_B_CONVERTED, (ix+fd_ubFlags)
        jr      z, flr_1
        set     Z80F_B_Z, (iy+OSFrame_F)
.flr_1
        jp      flr_19

.flr_2
        ld      h, (ix+fd_eTable+1)             ; HL=table
        ld      l, (ix+fd_eTable)
        exx
        push    ix                              ; de'=data buffer
        pop     hl
        ld      de, fd_SIZEOF
        add     hl, de
        ex      de, hl
        ld      c, (ix+fd_ubBufSize)            ; c'=#bytes in buffer
        exx

        bit     FDF_B_REPLACING, (ix+fd_ubFlags); continue replacing?
        jr      z, flr_3
        ld      h, (ix+fd_pReplaceStr+1)        ; HL=replace ptr
        ld      l, (ix+fd_pReplaceStr)
        ld      a, (ix+fd_ubReplaceLeft)        ; A=#bytes left
        jp      flr_16

.flr_3
        ld      a, (ix+fd_ubBufLeft)
        or      a
        jp      z, flr_eof                      ; no data

        push    hl                              ; get options
        inc     hl
        inc     hl
        ld      d, (hl)                         ; forward options
        inc     hl
        bit     FDF_B_REVERSE, (ix+fd_ubFlags)
        jr      z, flr_4
        ld      d, (hl)                         ; reverse options
.flr_4
        pop     hl

        exx
        push    ix                              ; de'=data buffer
        pop     hl                              ; !! we did this already
        ld      de, fd_SIZEOF
        add     hl, de
        ex      de, hl
        ld      a, (de)                         ; get data byte
        inc     de
        exx
        or      a
        jp      p, flr_5                        ; <128 is ok
        bit     7, d                            ; has top bit set characters?
        jr      nz, flr_srch                    ; yes, search !! unnecessary
        jr      flr_8                           ; else return A

.flr_5
        call    GnClsMain
        jr      c, flr_6                        ; is alpha
        jr      z, flr_7                        ; is numeric
        bit     4, d                            ; has puncuation characters?
        jr      nz, flr_srch                    ; yes, search !! unnecessary
        jr      flr_8                           ; else return A

.flr_6
        bit     5, d                            ; has alphabetic data
        jr      nz, flr_srch                    ; yes, search !! unnecessary
        jr      flr_8                           ; else return A

.flr_7
        bit     6, d                            ; has numeric data?
.flr_8
        jp      z, flr_18                       ; no, return A

;       search table for match

.flr_srch
        ld      d, h                            ; DE=table
        ld      e, l
        ld      a, (hl)                         ; HL=table length
        inc     hl
        ld      h, (hl)
        ld      l, a
        add     hl, de                          ; HL=table end
        push    hl                              ; remember
        ex      de, hl
        ld      de, 4
        add     hl, de                          ; HL=first entry

.flr_10
        push    hl                              ; remember current entry
        exx
        push    ix                              ; de'=data buffer
        pop     hl
        ld      de, fd_SIZEOF
        add     hl, de
        ex      de, hl
        pop     hl                              ; hl'=entry
        exx
        ld      b, (ix+fd_ubBufLeft)
        ld      d, (ix+fd_ubFlags)
        ld      a, (hl)                         ; entry length
        bit     FDF_B_REVERSE, d
        call    nz, flr_skipentry
        inc     hl
        dec     a
        ld      c, a                            ; c=e=length
        ld      e, c

.flr_11
        ld      a, (hl)                         ; entry char
        inc     hl
        bit     FDF_B_IGNORECASE, d
        call    nz, Upper
        push    de
        ld      e, a                            ; remember it
        exx
        ld      a, (de)                         ; buffer char
        inc     de
        exx
        bit     FDF_B_IGNORECASE, d
        call    nz, Upper
        cp      e                               ; match?
        pop     de
        jr      nz, flr_12                      ; not same, skip rest
        dec     c                               ; entry length
        jr      z, flr_match                    ; end? match
        djnz    flr_11                          ; more in buffer? loop

        set     FDF_B_EOF, d                    ; partial match

.flr_12
        exx                                     ; reset HL to entry start
        push    hl
        exx
        pop     hl

        ld      a, (hl)                         ; skip two entries
        call    flr_skipentry
        call    flr_skipentry

;       !! 'ld c, d; ld d, h; ld e, l; pop hl; push hl'

        ex      (sp), hl                        ; get table end
        ld      c, d                            ; remember d
        pop     de                              ; next entry
        push    hl                              ; push table end

        or      a                               ; hl=next entry, Fz=end flag
        sbc     hl, de
        ex      de, hl
        ld      d, c                            ; restore d
        jr      nz, flr_10                      ; not end, loop

        inc     sp                              ; fix stack
        inc     sp

        bit     FDF_B_EOF, d
        jr      z, flr_18                       ; no EOF, return A

.flr_eof
        ld      a, RC_Eof
.flr_err
        call    PutOsf_Err
        cp      RC_Hand
        jr      z, flr_x                        ; bad handle, just exit
        jr      flr_20                          ; otherwise restore S1 and S2

.flr_match
        inc     sp                              ; fix stack
        inc     sp
        ld      a, e                            ; dicard matching incgars
        call    flr_PurgeAchars

        exx                                     ; HL=entry
        push    hl
        exx
        pop     hl

        ld      a, (hl)
        bit     FDF_B_REVERSE, d
        call    z, flr_skipentry                ; not reverse, get next
        inc     hl
        dec     a
        jp      z, flr_2                        ; zero chars out, start again

.flr_16
        res     FDF_B_REPLACING, (ix+fd_ubFlags); clear replace flag,
        dec     a                               ; set it if we have more chars
        ld      (ix+fd_ubReplaceLeft), a
        jr      z, flr_17
        set     FDF_B_REPLACING, (ix+fd_ubFlags)

.flr_17
        ld      a, (hl)                         ; get output char and bump pointer
        inc     hl
        ld      (ix+fd_pReplaceStr+1), h
        ld      (ix+fd_pReplaceStr), l

        set     Z80F_B_Z, (iy+OSFrame_F)        ; mark as converted
        set     FDF_B_CONVERTED, (ix+fd_ubFlags)
        jr      flr_19

.flr_18
        ld      a, 1                            ; output one char
        call    flr_PurgeAchars

.flr_19
        ld      (iy+OSFrame_A), a               ; return a
        ld      (ix+fd_ubLastChar), a
        set     FDF_B_HASBEENREAD, (ix+fd_ubFlags)

        inc     (ix+fd_uwRead)                  ; bump read count
        jr      nz, flr_20
        inc     (ix+fd_uwRead+1)

.flr_20
        pop     bc                              ; restore S2 & s1
        OZ      OS_Mpb
        pop     bc
        OZ      OS_Mpb
        pop     ix
.flr_x
        ret

.flr_PurgeAchars
        push    de
        push    hl
        push    bc
        push    ix
        pop     hl
        ld      bc, fd_SIZEOF
        add     hl, bc                          ; buffer start

        ld      e, a                            ; bump write count
        add     a, (ix+fd_uwWritten)
        ld      (ix+fd_uwWritten), a
        jr      nc, flr_s1
        inc     (ix+fd_uwWritten+1)

.flr_s1
        ld      a, (ix+fd_ubBufLeft)            ; discard E chars
        sub     e
        ld      (ix+fd_ubBufLeft), a

        ld      a, (hl)                         ; return first char
        push    af
        jr      z, flr_s2                       ; no chars to purge?

        xor     a
        ld      d, a
        ld      b, a                            ; bc=#bytes still in buffer
        ld      c, (ix+fd_ubBufLeft)
        ex      de, hl
        add     hl, de                          ; hl=bufstart+E, de=bufstart
        ldir                                    ; move them

.flr_s2
        pop     af
        pop     bc
        pop     hl
        pop     de
        ret

.flr_skipentry
        add     a, l
        ld      l, a
        jr      nc, flr_s3
        inc     h
.flr_s3
        ld      a, (hl)
        ret

;       ----

;       flush filter
;
;IN:    IX=filter
;OUT:   A=char, Fz=1 if converted
;       Fc=1, A=error
;
;CHG:   AF....../....

.GNFlf
        ld      a, TH_FILT
        OZ      OS_Vth
        jr      c, flf_err                      ; bad handle

        push    ix
        ld      c, 1                            ; bind data in S1
        OZ      OS_Mpb
        push    bc

        ld      a, (ix+2)
        and     ~$18
        ld      (ix+2), a

        push    hl                              ; IX=data
        pop     ix

;       !! should make sub of these, used in Flr as well

        bit     FDF_B_PUSHBACK, (ix+fd_ubFlags) ; get pushback char if there's one
        jr      z, flf_1
        res     FDF_B_PUSHBACK, (ix+fd_ubFlags)
        ld      a, (ix+fd_ubLastChar)
        bit     FDF_B_CONVERTED, (ix+fd_ubFlags)
        jr      z, flf_2
        set     Z80F_B_Z, (iy+OSFrame_F)
        jr      flf_2

.flf_1
        ld      a, (ix+fd_ubBufLeft)            ; else read from buffer
        or      a
        scf
        ld      a, RC_Eof
        jr      z, flf_4                        ; EOF if no data

        ld      de, fd_SIZEOF                   ; DE=buffer, HL=buffer+1
        add     hl, de
        ld      d, h
        ld      e, l
        inc     hl

        ld      a, (de)                         ; get char (no conversion)

        dec     (ix+fd_ubBufLeft)               ; decrement #bytes in buffer
        jr      z, flf_2
        ld      c, (ix+fd_ubBufLeft)            ; move buffer data
        ld      b, 0
        ldir
.flf_2
        inc     (ix+fd_uwRead)                  ; bump read count
        jr      nz, flf_3
        inc     (ix+fd_uwRead+1)
.flf_3
        or      a                               ; clean exit
        set     FDF_B_HASBEENREAD, (ix+fd_ubFlags)
.flf_4
        pop     bc
        pop     ix
        push    af
        OZ      OS_Mpb                          ; restore S1
        pop     af
        jr      nc, flf_6
.flf_err
        set     Z80F_B_C, (iy+OSFrame_F)
.flf_6
        ld      (iy+OSFrame_A), a
        ret

;       ----

;       push back a character into filter
;
;IN:    IX=filter
;OUT:   -
;       Fc=1, A=error
;
;CHG:   AF....../....

.GNFpb
        ld      a, TH_FILT
        OZ      OS_Vth
        jr      c, fpb_4                        ; bad handle

        push    ix
        ld      c, 1                            ; data into S1
        OZ      OS_Mpb
        push    bc

        push    hl
        pop     ix
        ld      a, (ix+fd_ubFlags)              ; !! 'and FDF_HASBEENREAD|FDF_PUSHBACK; cp FDF_HASBEENREAD'
        bit     FDF_B_HASBEENREAD, a
        jr      z, fpb_1                        ; never read
        bit     FDF_B_PUSHBACK, a
        jr      z, fpb_2                        ; no pushback present

.fpb_1
        ld      a, RC_Push                      ; pushback error
        scf
        jr      fpb_3

.fpb_2
        set     FDF_B_PUSHBACK, (ix+fd_ubFlags)
        ld      b, (ix+fd_uwRead+1)             ; decrement read count
        ld      c, (ix+fd_uwRead)
        dec     bc
        ld      (ix+fd_uwRead+1), b
        ld      (ix+fd_uwRead), c
        or      a
.fpb_3
        pop     bc
        pop     ix
        push    af
        OZ      OS_Mpb                          ; restore S1
        pop     af
        jr      nc, fpb_x
.fpb_4
        call    PutOsf_Err
.fpb_x
        ret

