; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $1143
;
; $Id$
; -----------------------------------------------------------------------------

        Module FileSys2

        org     $d143                           ; 2785 bytes


        include "blink.def"
        include "buffer.def"
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "lowram.def"
        include "memory.def"
        include "misc.def"
        include "serintfc.def"
        include "stdio.def"
        include "syspar.def"
        include "sysvar.def"
	include	"time.def"


xdef    _MS2BankA
xdef    MS2HandleBank
xdef    OSCl
xdef    OSFrm
xdef    OSFwm
xdef    OSGb
xdef    OSGbt
xdef    OSMv
xdef    OSOp
xdef    OSPb
xdef    OSPbt
xdef    OSRen
xdef    OSDel

xdef    IsSpecialHandle
xdef    OpenMem
xdef    FileNameDate
xdef    AddAvailableFsBlock
xdef    AllocHandleBlock
xdef    AllocMemFile_SizeHL
xdef    FilePtr2MemPtr
xdef    FreeMemData
xdef    FreeMemData0
xdef    fsMS2BankB
xdef    fsRestoreS2
xdef    GetFileSize
xdef    InitFsMemHandle
xdef    InitMemHandle
xdef    MemPtr2FilePtr
xdef    MvToFile
xdef    RdFileByte
xdef    RdHeaderedData
xdef    RestoreAllAppData
xdef    RewindFile
xdef    SaveAllAppData
xdef    SetMemHandlePos
xdef    WrFileByte
xdef    WrHeaderedData

;       bank 0

xref    AllocHandle
xref    ChgHandleType
xref    Chk128KB
xref    CopyMemHL_DE
xref    DORHandleFree
xref    DORHandleFreeDirect
xref    DORHandleInUse
xref    FindHandle
xref    FPtr2MemPtrBindS2
xref    GetHandlePtr
xref    GetOSFrame_DE
xref    GetOSFrame_HL
xref    MS12BankCB
xref    MS1BankA
xref    MS2BankA
xref    MS2BankB
xref    MS2BankK1
xref    OSFramePop
xref    OSFramePush
xref    OSPrtMain
xref    OZwd__fail
xref    PeekHLinc
xref    PokeHLinc
xref    PutOSFrame_BC
xref    PutOSFrame_DE
xref    PutOSFrame_HL
xref    RdKbBuffer
xref    RestoreScreen
xref    SaveScreen
xref    VerifyHandle
xref    VerifyHandleBank



;       bank 7

xref    FreeMemHandle
xref    OSOutMain


;       ----

;       get byte from special handle

.GbtSpecial

	ld	hl, gbts_err
	add	hl, de
	ld	a, (hl)
	srl	a
	ret	c

	cp	2
	jr	z, gbts_5
	jr	nc, gbts_6

.gbts_1
        push    ix
        call    RdKbBuffer
        pop     ix
        ret
.gbts_5
        ld      l, SI_GBT
        OZ      OS_Si
        ret

.gbts_6
        OZ      OS_Tin
        ret

.gbts_err
	defb	RC_Hand*2+1,0,RC_Rp*2+1,RC_Rp*2+1,RC_Eof*2+1,2,4,RC_Rp*2+1,RC_Rp*2+1

; 0 - ??		RC_Hand
; 1 - keyboard
; 2 - screen		RC_Rp
; 3 - prt direct	Rc_Rp
; 4 - nul		Rc_Eof
; 5 - ser
; 6 - stdin
; 7 - stdout		RC_Rp
; 3 - prt filter	Rc_Rp


;       ----

;       put bute to special handle
;
;       !! this can be made a lot more efficient

.PbtSpecial
        dec     e
        ld      a, RC_Wp
        scf
        ret     z                               ; 1 - keyboard - wr protected
        dec     e
        jr      nz, pbts_1

;       2 - screen

        ld      a, (iy+OSFrame_A)
        push    bc
        call    OSOutMain
        pop     bc
        ret

.pbts_1
        dec     e
        jr      nz, pbts_2

;       3 - printer direct

        ld      a, (iy+OSFrame_A)
        OZ      OS_Prt                          ; Send character directly to printer filter
        ret

.pbts_2

        dec     e
        scf
        ccf
        ret     z                               ; 4 - NUL

        dec     e
        jr      nz, pbts_3

;       5 - serial

        ld      a, (iy+OSFrame_A)
        ld      l, SI_PBT
        OZ      OS_Si
        ret

.pbts_3
        dec     e
        ld      a, RC_Wp
        scf
        ret     z                               ; 6 - stdin - wr protected

        dec     e
        jr      nz, pbts_4

;       7 - stdout

        ld      a, (iy+OSFrame_A)
        OZ      OS_Out                          ; write a byte to std. output
        ret

.pbts_4
        dec     e
        jr      nz, pbts_5

;       8 - printer filter
        ld      a, (iy+OSFrame_A)
        jp      OSPrtMain

.pbts_5
        ld      a, RC_Hand
        scf
        ret

;       ----

;       IN: IX=handle, BC=length, DE=destination memory, HL=source memory
;
;       if DE=0 write from HL to handle, if HL=0 read from handle to DE
;       both can't be 0 or data from 0000 is written to handle

.OsMvSpecial
        ld      a, b                            ; ret if BC=0
        or      c
        ret     z                               ; Fc=0

        ld      a, d
        or      e
        push    af                              ; Fz=0 - read, Fz=1 - write

        push    bc
        push    de
        push    hl
        jr      z, rwb_1                        ; DE=0, memory -> file

;       file -> memory

        push    bc                              ; read byte from file and write it to (DE)++
        OZ      OS_Gb
        pop     bc
        jr      c, rwb_2                        ; error? exit
        push    bc
        ex      de, hl
        call    PokeHLinc
        ex      de, hl
        pop     bc
        jr      rwb_2

;       memory -> file

.rwb_1
        push    bc                              ; read byte from (HL)++ and write to file
        call    PeekHLinc
        pop     bc
        OZ      OS_Pb

.rwb_2
        pop     hl
        pop     de
        pop     bc
        jr      c, rwb_err                      ; error? exit

        pop     af
        dec     bc                              ; decrement size
        jr      z, rwb_3                        ; if read we increment DE, if write we increment DE
        inc     de
        dec     hl
.rwb_3
        inc     hl
        jr      OsMvSpecial                     ; back to size check

.rwb_err
        inc     sp                              ; purge r/w flag
        inc     sp
        ret

;       ----

.MS2HandleBank
        ld      a, (ix+hnd_Bank)
._MS2BankA
        jp      MS2BankA
; End of function MS2HandleBank

;       ----

; internal open
;
;
; IN:
;       A=OP_OUT ($02), open    (create) file for output, IX=(directory) DOR handle, HL=filename
;       A=OP_UP ($03), open for update, IX=(file) DOR handle
;       A=OP_MEM ($04), open    memory (for input), BHL=memory, C=size
;       A=OP_DIR ($05), create directory, IX=(directory) DOR    handle, HL=filename
;
.OSOp
        ld      b, a
        djnz    osop_out

;       open file for input
;IN:    IX=handle
;OUT:   IX=handle?


.OSOp_In
        call    VerifyHandleBank
        ret     c                               ; bad handle? exit

        bit     FFLG_B_SPECDEV, (ix+fhnd_flags) ; special device?
        jr      nz, opin_1

        bit     1, (iy+OSFrame_A)
        call    nz, FileNameDate                ; OS_UP? Fc=0, Fz=0 - change update time only

        ld      a, DR_RD                        ; read DOR record
        call    opout_1                         ; open file
        or      a
        jp      RewindFile                      ; reset read/write position

.opin_1
        call    GetHandlePtr
        ld      c, (hl)                         ; enquiry code into BC  !! NQ_Khn-NQ_Rhn?
        inc     hl
        ld      b, (hl)

        ld      a, DR_FRE                       ; free DOR handle
        OZ      OS_Dor

        OZ      OS_Nq
        ret

.osop_out
        djnz    osop_up

;       open file for output
;IN:    IX=handle
;OUT:   IX=handle?

        call    VerifyHandleBank
        ret     c                               ; bad handle? exit

        ld      a, (ix+fhnd_flags)
        bit     FFLG_B_SPECDEV, a               ; special device?
        jr      nz, opin_1                      ; share code with OP_IN

        push    af                              ; remember flags
        ld      b, DN_FIL
        call    opdir_1                         ; create handle
        pop     hl
        ret     c                               ; error? exit

        ld      (ix+fhnd_attr), h
        ld      (ix+fhnd_flags), h

        call    AllocFirstBlock                        ; allocate first block?
        jr      c, opout_err                    ; error? exit

        ld      a, DR_WR                        ; write DOR record
.opout_1
        push    af
        ld      a, (ix+fhnd_flags)
        and     255-7
        or      (iy+OSFrame_A)                  ; IN=1, UP=3, OUT=2
        ld      (ix+fhnd_attr), a

        pop     af                              ; DR_RD/DR_WR
        push    ix
        pop     hl
        ld      de, fhnd_firstblk
        add     hl, de
        ex      de, hl                          ; DE=IX+fhnd_firstblk
        ld      bc, 1<<8|2                      ; read/write SON ptr from/to DE
        OZ      OS_Dor

        ld      a, HND_DEV
        ld      b, HND_FILE
        jp      ChgHandleType                   ; change dev to file

.opout_err
        push    af
        ld      a, DR_DEL
        OZ      OS_Dor                          ; delete DOR
        pop     af
        ret

.osop_up
        djnz    osop_mem

;       update handle - use op_in

        jr      OSOp_In

.osop_mem
        djnz    osop_dir

;       open memory handle
;IN:    BHL=memory, C=length
;OUT:   IX=handle

        ld      b, (iy+OSFrame_B)
        jp      OpenMem

.osop_dir
        djnz    osop_unk

;       create directory
;IN:    IX=handle, HL=name
;OUT:   IX=handle

        ld      b, DN_DIR
.opdir_1
        call    VerifyHandleBank
        ret     c                               ; bad handle? exit

        ld      a, DR_CRE
        push    ix
        OZ      OS_Dor                          ; create file/dir DOR
        pop     bc                              ; parent handle
        jr      c, opdir_3                      ; error? free parent and exit

        push    bc
        xor     a                               ; Fz=1, Fc=1
        scf
        call    FileNameDate                    ; set name+update+create date
        pop     bc                              ; parent

        ld      a, DR_INS                       ; insert IX as son of BC
        OZ      OS_Dor
        jr      c, $PC                          ; error? crash

.opdir_3
        push    af
        push    ix
        push    bc
        pop     ix
        ld      a, DR_FRE
        OZ      OS_Dor                          ; free old handle
        pop     ix
        pop     af
        ret

.osop_unk
        ld      a, RC_Unk
        scf
        ret

;       ----

; internal close

;IN:    IX=handle

.OSCl
        ld      a, HND_FILE
        ld      b, HND_DEV
        call    ChgHandleType                   ; file into dev
        jr      c, oscl_err                     ; bad handle? exit

        ld      a, (ix+fhnd_attr)
        and     FATR_READABLE|FATR_WRITABLE|FATR_MEMORY
        bit     FATR_B_MEMORY, a
        jr      nz, oscl_2                      ; memory? don't set size
        bit     FATR_B_WRITABLE, a
        jr      z, oscl_2                       ; not writable? don't set size
        cp      FATR_WRITABLE
        jr      nz, oscl_wr                     ; update handle? set size
        bit     FFLG_B_WRERROR, (ix+fhnd_flags)
        jp      nz, OSDel                       ; write error? delete

.oscl_wr
        call    GetFileSize                     ; into DEHL
        call    MS2BankK1                       ; restore S2  !! unnecessary?

        push    de
        push    hl
        ld      hl, 0                           ; DE=SP
        add     hl, sp
        ex      de, hl
        ld      a, DR_WR                        ; write record
        ld      bc, 'X'<<8|4                    ; eXtend, 4 bytes
        OZ      OS_Dor
        pop     hl
        pop     hl

.oscl_2
        bit     FATR_B_MEMORY, (ix+fhnd_attr)
        call    nz, FreeMemData0                    ; memory? free
        jp      DORHandleFreeDirect

.oscl_err
        ret     nz                              ; bad handle type
        or      a                               ; special handle, no error
        ret

;       ----

; move bytes between stream and memory
;IN:    IX,BC,DE,HL
;OUT:   BC,DE,HL

.OSMv
        call    OSFramePush
        call    OSMvMain
        jp      OSFramePop

.OSMvMain
        call    IsSpecialHandle
        jr      c, osmv_1

;       do special handle


        call    GetOSFrame_DE
        call    GetOSFrame_HL
        call    OsMvSpecial
        call    PutOSFrame_HL
        jr      osmv_3                          ; update BC and DE too

;       normal handle

.osmv_1

        call    GetOSFrame_DE
        call    GetOSFrame_HL
        ld      a, HND_FILE
        call    VerifyHandle
        ret     c                               ; bad handle? exit

        ld      a, b
        or      c
        ret     z                               ; BC=0, done

        ld      a, h
        or      l
        jr      z, osmv_rdf                     ; HL=0? read from file

        ld      a, d
        or      e
        ld      a, RC_Bad
        scf
        ret     nz                              ; HL<>0 and DE<>0? bad args

        bit     FATR_B_WRITABLE, (ix+fhnd_attr)
        ld      a, RC_Wp
        scf
        ret     z                               ; not writable? wr protected

        ld      d, 0                            ; local pointer
        call    MvToFile                        ; write data from HL
        call    PutOSFrame_HL                   ; update mem position
        call    c, SetFileWriteErrF             ; set error flag
        jr      osmv_4                          ; !! jp PutOSFrame_BC

.osmv_rdf
        ld      a, d
        or      e
        ld      a, RC_Bad
        scf
        ret     z                               ; HL=0 and DE=0? bad args

        bit     FATR_B_READABLE, (ix+fhnd_attr)
        ld      a, RC_Rp
        scf
        ret     z                               ; not readable? rd protected

        ex      de, hl                          ; HL=DE
        ld      d, 0                            ; local pointer
        call    MvFromFile                      ; read data to HL
        ex      de, hl                          ; DE=HL
.osmv_3
        call    PutOSFrame_DE
.osmv_4
        jp      PutOSFrame_BC

;       ----

;       get byte from file (or device)
;IN:    IX=handle
;OUT:   Fc=0, A=byte
;       Fc=1, A=error

.OSGb
        call    OSFramePush
        ld      bc, -1                          ; no timeout
        call    OSGbtMain
        jr      OSGbt_x

;       get byte from file (or device) with timeout

.OSGbt
        call    OSFramePush
        call    OSGbtMain
        call    PutOSFrame_BC
.OSGbt_x
        ld      (iy+OSFrame_A), a               ; return byte
        jp      OSFramePop

.OSGbtMain
        call    IsSpecialHandle
        jp      nc, GbtSpecial

.osbgt_1
        ld      a, HND_FILE
        call    VerifyHandle
        ret     c                               ; bad handle? exit

        bit     FATR_B_READABLE, (ix+fhnd_attr)
        ld      a, RC_Rp
        scf
        ret     z                               ; not readable? rd protected
        jp      RdFileByte

;       ----

;       write byte to file/device
;IN:    IX=handle, A=byte
;OUT:   Fc=0 if ok
;       Fc=1, A=error

.OSPb
        call    OSFramePush
        ld      bc, -1                          ; no timeout
        call    OSPbtMain
        jr      ospbt_x

;       write byte with timeout

.OSPbt
        call    OSFramePush
        call    OSPbtMain
        call    PutOSFrame_BC
.ospbt_x
        jp      OSFramePop

.OSPbtMain
        call    IsSpecialHandle
        jr      c, pbt_1                        ; jp nc,PbtSpecial
        jp      PbtSpecial

.pbt_1
        ld      a, HND_FILE
        call    VerifyHandle
        ret     c                               ; bad handle? exit

        bit     FATR_B_WRITABLE, (ix+fhnd_attr)
        ld      a, RC_Wp
        scf
        ret     z                               ; not writable? wr protected

        ld      a, (iy+OSFrame_A)
        call    WrFileByte
        jp      SetFileWriteErrF                ; may set error flag

;       ----

;       file read miscellaneous
;IN:    IX=handle, A=reason code, DE=destination buffer (0=return in DEBC)
;       if IX=-1 system values are returned

.OSFrm
        call    OSFramePush
        ld      b, a
        push    ix
        call    frm_ptr
        pop     ix
        jp      OSFramePop
.frm_ptr
        ld      de, $00FF                       ; !! VerifyFileHandle here, djnz preserves flags
        djnz    frm_ext

;       FA_PTR, return sequential pointer (32bit integer) or free handles (DE) and OZ version (BC)

        call    VerifyFileHandle
        ret     c                               ; bad handle? exit
        jr      z, frmptr_1                     ; 0 or -1

        call    GetFilePos
        jr      osfrm_x

.frmptr_1
        ld      e, d
        push    de
        pop     ix
        ld      bc, -1                          ; don't match anything
        call    FindHandle                      ; count free handles
        ld      hl, OZVERSION
        jr      osfrm_x

.frm_ext
        djnz    frm_eof

;       FA_EXT, return file size or free RAM

        call    VerifyFileHandle
        ret     c                               ; bad handle? exit

        ld      hl, (uwFreeRAMPages)            ; prepare for free RAM
        ld      e, h
        ld      h, l
        ld      l, d                            ; d=0 ?
        call    nz, GetFileSize
        jr      osfrm_x

.frm_eof
        djnz    frm_bst

;        FA_EOF, end of file status of expanded status

        call    VerifyFileHandle
        ret     c                               ; bad handle? exit
        jr      z, frmeof_2                     ; return expanded status

        call    GetFileEOF
        ret     nc
.frmeof_1
        set    Z80F_B_Z, (iy+OSFrame_F)          ; Fz=1, EOF
        or      a
        ret
.frmeof_2
        call    Chk128KB
        jr      nc, frmeof_1                    ; set Fz
        or      a
        ret

.frm_bst
        djnz    osfrm_err

;       FA_BST, buffer status (only for handle 5, serial)

        call    IsSpecialHandle
        ld      a, RC_Hand
        ret     c                               ; not special handle? exit

        ld      a, e
        cp      5
        ld      a, RC_Na
        scf
        ret     nz                              ; not serial? exit

        ld      ix, SerTXHandle
        ld      l, BF_STA                       ; get buffer status
        call    OZ_BUF
        ex      de, hl
        call    PutOSFrame_DE                   ; TX status in DE
        ld      ix, SerRXHandle
        ld      l, BF_STA                       ; get buffer status
        call    OZ_BUF
        or      a
        jp      PutOSFrame_HL                   ; RX status in HL

.osfrm_err
        ld      a, RC_Unk
        scf
        ret

.osfrm_x
        push    de
        push    hl
        ld      hl, 0
        add     hl, sp                          ; HL points to DEHL
        call    GetOSFrame_DE                   ; destination
        ld      a, d
        or      e
        jr      nz, osfrm_x2                    ; store result in memory
        push    iy
        ex      de, hl
        pop     hl
        ld      bc, OSFrame_C
        add     hl, bc
        ex      de, hl                          ; copy to BCDE
.osfrm_x2
        ld      c, 4
        call    CopyMemHL_DE
        pop     hl
        pop     de
        or      a
        ret

;       ----

;       Fc=0 if file handle IX ok
;       Fc=1 if error - Fz=1 if IX -1

.VerifyFileHandle
        push    hl
        push    ix
        pop     hl
        inc     h
        dec     h
        pop     hl
        ret     z                               ; IXH=0 - Fc=? Fz=1
        push    hl
        push    ix
        pop     hl
        ld      a, h
        and     l
        pop     hl
        inc     a
        ret     z                               ; IX=-1 - Fc=0 Fz=1
        ld      a, HND_FILE
        call    VerifyHandle
        ret     c
        or      a                               ; Fc=0, Fz=0
        ret

;       ----

; file write miscellaneous

.OSFwm
        call    OSFramePush
        ld      b, a
        call    OSFwmMain
        jp      OSFramePop

.OSFwmMain
        call    VerifyFileHandle
        ret     c                               ; bad handle? exit
        ret     z                               ; handle=0 or 1? return

.fwm_ptr
        djnz    fw_ext

; write sequential pointer

        ex      de, hl
        push    hl                              ; copy position to stack buffer
        push    hl
        ld      hl, 0
        add     hl, sp
        ld      c, 4
        ex      de, hl
        call    CopyMemHL_DE
        pop     hl                              ; get position into DEHL
        pop     de
        call    SeekFileMayExpand               ; seek there, expand file if necessary
        jr      SetFileWriteErrF                ; may set error flag

.fw_ext
        djnz    fw_unk

; write extent (size) of file

        ex      de, hl
        push    hl                              ; copy size to stack buffer
        push    hl
        ld      hl, 0
        add     hl, sp
        ld      c, 4
        ex      de, hl
        call    CopyMemHL_DE
        pop     hl                              ; get size into DEHL
        pop     de
        call    SetFileSize                     ; set file size, keep r/w position
        jr      SetFileWriteErrF                ; may set error flag

.fw_unk
        ld      a, RC_Unk
        scf
        ret

;       set write error flag if Fc=1

.SetFileWriteErrF

        ret     nc
        set     FFLG_B_WRERROR, (ix+fhnd_flags)
        ret

; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3222
;
; $Id$
; -----------------------------------------------------------------------------

.SetMemHandlePos
        ld      ix, pFsMemPool
        jr      SetFhnFirstBlock

;       ----

.InitFsMemHandle
        ld      ix, pFsMemPool

.InitMemHandle
        ld      a, (ix+fhnd_attr)               ; keep only rd/wr/mem flags
        and     FATR_READABLE|FATR_WRITABLE|FATR_MEMORY
        ld      (ix+fhnd_attr), a

.AllocFirstBlock
        xor     a
        ld      (ix+fhnd_firstblk_h), a         ; reset first block
        ld      (ix+fhnd_firstblk), a
        call    AllocHandleBlock
        ret     c

.SetFhnFirstBlock
        ld      (ix+fhnd_firstblk_h), d         ; set first block
        ld      (ix+fhnd_firstblk), e

.RewindFile
        ld      d, (ix+fhnd_firstblk_h)         ; read first block
        ld      e, (ix+fhnd_firstblk)

.fsAdvanceBlock
        push    af
        call    FilePtr2MemPtr                  ; DE->BHL
        ld      (ix+fhnd_filepos_h), d          ; set position
        ld      (ix+fhnd_filepos), e
        ld      a, l
        add     a, 2                            ; point pos_lo to start of data area
        ld      (ix+fhnd_filepos_lo), a
        pop     af
        ret

;       ----

.FreeMemData0
        ld      d, (ix+fhnd_firstblk_h)
        ld      e, (ix+fhnd_firstblk)
        xor     a
        ld      (ix+fhnd_firstblk_h), a
        ld      (ix+fhnd_firstblk), a
						; drop thru
;       ----


.FreeMemData
        ld      a, e
        or      d
        ret     z
.fmd_1
        call    MS2FilePtr                      ; bind in DE
        push    de
        ld      e, (hl)                         ; DE=fsPtr to next
        inc     hl
        ld      d, (hl)
        pop     hl                              ; HL=fsPtr to this
        ex      de, hl                          ; DE=this, HL=next
        call    AddAvailableFsBlock
        call    fsRestoreS2
        ret     c
        ex      de, hl                          ; DE=next
        ld      a, d
        or      a
        jr      nz, fmd_1                       ; has next? free it
        or      a
        ret

;       ----

.GetFilePosMemPtr
        push    de
        ld      d, (ix+fhnd_filepos_h)
        ld      e, (ix+fhnd_filepos)
        call    FilePtr2MemPtr
        pop     de
        ret

;       ----

.fsMarkBlockDead
        ld      (hl), e
        inc     l
        ld      (hl), d
        inc     l
        ld      (hl), $de
        inc     l
        ld      (hl), $ad
        ret

;       ----

.GetSlotBlocks
        ld      a, b                            ; slot
        exx
        rlca
        add     a, <uwSlotAvailFsBlocks         ; !! ld hl,uwSlotAvailFsBlocks; add a,l; ld l,a
        ld      l, a
        ld      h, >uwSlotAvailFsBlocks
        ld      a, (hl)                         ; first block available in slot
        ld      (uwFsAvailBlock), a
        inc     l
        ld      a, (hl)
        ld      (uwFsAvailBlock+1), a
        dec     l
        ex      (sp), hl                        ; push hl for caller
        push    hl
        exx
        ret

;       ----

.SetSlotBlocks
        ex      af, af'
        exx
        pop     de                              ; return address
        pop     hl                              ; pushed in fsSetAvailableBlock
        ld      a, (uwFsAvailBlock)             ; put fsPtr back to slot chain
        ld      (hl), a
        ld      a, (uwFsAvailBlock+1)
        inc     l
        ld      (hl), a
        push    de                              ; return address
        exx
        ex      af, af'
        ret

;       ----

.AllocHandleBlock
        ld      a, (ix+fhnd_attr)
        and     ~(FATR_READABLE|FATR_WRITABLE|FATR_MEMORY)
        jr      z, ahb_2                        ; no flags? any slot
        rlca                                    ; bits 3&4 to top - slot
        rlca
        rlca
.ahb_1
        rlca
        rlca
        and     3
        ld      b, a                            ; save slot
        add     a, <ubSlotRamSize               ; !! ld hl,ubSlotRamSize; add a,l; ld l,a
        ld      l, a
        ld      h, >ubSlotRamSize
        ld      a, (hl)
        or      a
        ld      a, RC_Room                      ; No room
        scf
        ret     z                               ; no RAM in slot
        call    GetSlotBlocks
        ld      a, b
        or      $10                             ; for OS_Mal
        call    fsGetBlock
        call    SetSlotBlocks
        ret
.ahb_2
        add     a, $40                          ; 40-80-C0-00, slot 1-2-3-0
        push    af
        call    ahb_1
        jr      nc, ahb_3
        ex      af, af'
        pop     af
        jr      nz, ahb_2
        ex      af, af'
        ret
.ahb_3
        inc     sp
        inc     sp
        ret

;       ----

.fsGetBlock
        push    af
        call    fsGetAvailableBlock
        jr      nc, gb_1                        ; got block, return
        pop     af
        call    fsAllocBlock
        ret     c
        jr      fsGetBlock
.gb_1
        inc     sp
        inc     sp
        ret

;       ----

.fsAllocBlock
        push    ix
        ld      ix, (pFsMemPool)
        ld      bc, $100
        OZ      OS_Mal                          ; allocate full page
        pop     ix
        ret     c
        call    fsMS2BankB                      ; bind it in
        call    MemPtr2FilePtr

;       link blocks 00/40/80 to one above itself, last to uwFsAvailBlock,
;       then make this head of uwFsAvailBlock chain

        push    de
.fsab_1
        inc     e
        call    fsMarkBlockDead
        ld      a, l
        and     $c0
        add     a, $40
        ld      l, a
        cp      $c0
        jr      c, fsab_1
        ld      de, (uwFsAvailBlock)
        ld      (hl), e
        inc     l
        ld      (hl), d
        pop     de
        ld      (uwFsAvailBlock), de
        call    fsRestoreS2
        or      a
        ret

;       ----

;OUT:   Fc=0, BHL=fsBlock

.fsGetAvailableBlock
        ld      de, (uwFsAvailBlock)
        ld      a, d
        or      e
        ccf                                     ; scf
        ret     z                               ; no available, allocate more
        push    de
        call    MS2FilePtr                      ; bind it in, BHL=memptr
        ld      e, (hl)                         ; DE=next available block
        inc     hl
        ld      d, (hl)
        ld      (hl), 0                         ; clear next pointer
        dec     hl
        ld      (hl), 0
        ld      (uwFsAvailBlock), de            ; make this.Next new head of chain
        call    fsRestoreS2
        pop     de                              ; pop block and return it as MemPtr too
                                                ; !! wouldn't it be enough to 'ld b,d; ret'?
;       ----

;IN:    DE=fsPTR
;OUT:   BHL=memPtr

.FilePtr2MemPtr
	ld	c, 2				; segment
        ld      b, d                            ; bank
        inc     d
        dec     d
        jr      z, fp2mp_1                      ; zero, start from beginning
        ld      h, e
        ld      l, 1
        srl     h
        rr      l
        rr      h                               ; 10eeeeee
        rr      l                               ; ee000000
        ret
.fp2mp_1
        ld      hl, uwFsAvailBlock
        or      a
        ret

;       ----

;       D=B
;       E=(HL>>6) & $00ff

.MemPtr2FilePtr
        push    hl
        ld      d, b
        add     hl, hl
        add     hl, hl
        ld      e, h
        pop     hl
        ret

;       ----

;IN:    DE=fsPtr

.AddAvailableFsBlock
        ld      a, d                            ; FsPtr
        rlca
        rlca
        and     3
        ld      b, a                            ; slot
        call    GetSlotBlocks
        call    AddAvailableFsBlock2
        call    SetSlotBlocks
        ret

;       ----

.AddAvailableFsBlock2

        push    hl
        call    MS2FilePtr                      ; bind in DE -> BHL
        push    de
        push    hl

;       try to add block after lower free block in same page

.aab_1
	ld	a, e
        dec     e                               ; previous block
        and     3                               ; block_of_page
        jr      z, aab_2                        ; page change? skip

        call    FilePtr2MemPtr
        inc     l                               ; check $DEAD signature
        inc     l                               ; this is to avoid expensive FindPrevBlock
        ld      a, (hl)
        cp      $de
        jr      nz, aab_1                       ; no DEAD? in use
        inc     l
        ld      a, (hl)
        cp      $ad
        jr      nz, aab_1                       ; no DEAD? in use
        call    FindPrevBlock                   ; BC=fsPtr of block pointing to first block on same page as DE
        jr      c, aab_1                        ; this block not in chain? in use

;       link fsPtr in after fsPtr this

        push    de
        ex      af, af'
        exx
        pop     de                              ; DE=fsPtr this
        call    FilePtr2MemPtr                  ; HL=memPtr this
        ld      e, (hl)                         ; DE=fsPtr next
        inc     l
        ld      d, (hl)
        dec     l
        ex      (sp), hl                        ; HL=memPtr in
        call    fsMarkBlockDead                 ; in.next=this.next
        pop     hl                              ; memPtr this
        pop     de                              ; fsPtr in
        ld      (hl), e                         ; this.next=in
        inc     l
        ld      (hl), d
        push    de
        exx
        ex      af, af'                         ; Fz=1 from FindPrevBlock
        pop     de                              ; DE=fsPtr in, BC=fsPtr prev
        jr      aab_6                           ; !! why branch into jr nz? branch after it
.aab_2
        pop     hl                              ; swap stack vars
        pop     de
        push    de
        push    hl

;       try to add block before higher free block in same page

.aab_3
        inc     e
        ld      a, e
        and     3
        jr      z, aab_4                        ; page change? exit

        call    FilePtr2MemPtr
        inc     l                               ; check $DEAD signature
        inc     l
        ld      a, (hl)
        cp      $de
        jr      nz, aab_3                       ; in use? check next
        inc     l
        ld      a, (hl)
        cp      $ad
        jr      nz, aab_3                       ; in use? check next
        call    FindPrevBlock
        jr      c, aab_3                        ; not found? in use

        push    de
        exx
        pop     de                              ; fsPtr this
        pop     hl                              ; memPtr in
        call    fsMarkBlockDead                 ; in.next=this
        exx
        ex      de, hl                          ; de=prev
        call    FilePtr2MemPtr                  ; HL=memPtr prev
        ex      de, hl                          ; de=memPtr, HL=fsPtr
        ex      (sp), hl                        ; hl=fsPtr in
        ex      de, hl                          ; DE=fsPtr in, HL=memPtr prev
        call    fsMS2BankB
        call    fsLinkHL_DE_RestoreS2           ; prev.next=in
        pop     bc                              ; BC=fsPtr prev, DE=fsPtr in
        jr      aab_5

;       no other block from this page, insert ahead of list

.aab_4
        pop     hl                              ; memPtr in
        ld      de, (uwFsAvailBlock)
        call    fsMarkBlockDead
        pop     de                              ; fsPtr in
        ld      (uwFsAvailBlock), de
        jr      aab_x
.aab_5
        ld      a, e
        and     3
.aab_6
        jr      nz, aab_x                       ; not first block in page? exit
        ld      a, e                            ; point filePtr (in) to  first block in page
        and     $FC
        ld      e, a
        push    bc                              ; prev
        call    FilePtr2MemPtr
.aab_7
        inc     e                               ; next fsBlock
        ld      a, (hl)
        cp      e
        jr      nz, aab_9                       ; doesn't point to next? exit
        inc     l
        ld      a, (hl)
        cp      d
        jr      nz, aab_9                       ; doesn't point to next? exit
        ld      a, l
        add     a, $40-1                        ; next block
        ld      l, a
        cp      $c0
        jr      c, aab_7                        ; not at last block in page? loop

;       remove from chain

        ld      c, (hl)                         ; BC=fsPtr to next
        inc     l
        ld      b, (hl)
        dec     e                               ; DE back to first block in page
        dec     e
        dec     e
        ex      de, hl                          ; HL=fsPtr last
        ex      (sp), hl                        ; HL=fsPtr prev
        ex      de, hl                          ; DE=fsPtr prev
        push    bc
        call    FilePtr2MemPtr                  ; HL=memPtr prev
        pop     de                              ; DE=fsPtr next
        call    fsMS2BankB                      ; bind prev in
        call    fsLinkHL_DE_RestoreS2           ; prev.next=next

;       free page

        pop     de                              ; DE=fsPtr last
        call    FilePtr2MemPtr                  ; HL=memPtr last
        push    ix
        ld      a, b
        ld      bc, $100
        ld      ix, (pFsMemPool)
        OZ      OS_Mfr                          ; Free memory
        pop     ix
        jr      c, $PC                          ; error? crash
        jr      aab_x
.aab_9
        pop     hl
.aab_x
        call    fsRestoreS2
        pop     hl
        or      a
        ret

;       ----

;IN:    DE=fsPtr
;OUT:   BC=fsPtr of block pointing to first block on same page as DE

.FindPrevBlock
        ld      b, d                            ; BC=in
        ld      c, e
        ld      de, 0
        inc     e                               ; DE=1, Fz=0
        push    de
        push    af
.fpb_1
        ld      a, e
        or      d
        jr      z, fpb_err                      ; end? error
        ld      a, b
        cp      d
        jr      nz, fpb_3                       ; different bank

        pop     af
        jr      z, fpb_2                        ; have changed stack? skip

        ld      a, c                            ; fsPtr in
        and     ~3                              ; mask out non-page part
        cp      e
        jr      nz, fpb_2                       ; different page
        inc     sp                              ; replace original DE with HL - prev
        inc     sp
        push    hl                              ; pointer to first block on same page as BC

.fpb_2
        push    af
        ld      a, c
        cp      e
        jr      z, fpb_x                        ; same block? exit
.fpb_3
        push    bc                              ; HL=fsPtr this, DE=fsPtr next
        push    de
        call    MS2FilePtr
        ld      e, (hl)
        inc     l
        ld      d, (hl)
        call    fsRestoreS2
        pop     hl
        pop     bc
        jr      fpb_1

.fpb_x
        pop     af
        pop     bc                              ; BC=prevblock
        scf                                     ; Fc=0, keep Fz=1
        ccf
        ret

.fpb_err
        ld      d, b                            ; DE=fsPtr in
        ld      e, c
        pop     af
        pop     af
        scf
        ret

;       ----

.AllocMemFile_SizeHL

        ld      ix, 0
        ld      a, h
        or      l
        ret     z                               ; Fc=0
        ex      de, hl
        ld      a, OP_MEM
        ld      b, 0                            ; BC=0, HL=0
        ld      h, b
        ld      l, b
        ld      c, b
        OZ      OS_Op                           ; internal open
        ret     c
        ex      de, hl
        call    SeekFileMayExpand
        ret     nc
        push    af
        OZ      OS_Cl                           ; close file/stream
        pop     af
        ret

;       ----

.MS2FilePtr
        call    FilePtr2MemPtr

.fsMS2BankB
        ex      af, af'
        ld      a, b
        exx
        ld      hl, (BLSC_SR1)                  ; S1S2
        ex      (sp), hl                        ; push it, pop return address
.fsMS2sub
        call    MS2BankA
        push    hl                              ; return address
        exx
        ld      b, a                            ; old bank
        ex      af, af'
        ret

.fsLinkHL_DE_RestoreS2
        ld      (hl), e
        inc     l
        ld      (hl), d

.fsRestoreS2
        ex      af, af'
        exx
        pop     hl
        pop     af
        jr      fsMS2sub

;       ----

;       write identifier A, length BC, and BC bytes of data from (HL)

.WrHeaderedData
        ld      d, 0                            ; HL=local
        call    WrFileByte
        ret     c
        ld      a, c
        call    WrFileByte
        ret     c
        ld      a, b
        call    WrFileByte
        ret     c

;       ----

; write BC bytes from (DHL)

.MvToFile
        scf

.MoveToFromFile
        ex      af, af'
.fsmv_1
        push    de
        push    hl
        push    bc
        ld      de, 0
        ld      a, h
        or      $C0
        ld      h, a
        ex      de, hl
        sbc     hl, de
        or      a
        push    hl
        sbc     hl, bc
        pop     bc
        jr      nc, fsmv_3
        pop     hl
        or      a
        sbc     hl, bc
        ex      de, hl
        pop     hl
        add     hl, bc
        pop     af
        push    hl
        push    de
        ld      d, a
        or      a
        sbc     hl, bc
        call    fsmv_4
        jr      c, fsmv_2
        pop     bc
        pop     hl
        inc     d
        dec     d
        jr      z, fsmv_1
        inc     d
        jr      fsmv_1
.fsmv_2
        ex      de, hl
        ex      (sp), hl
        ex      af, af'
        add     hl, bc
        ld      b, h
        ld      c, l
        ex      af, af'
        ex      de, hl
        pop     de
        inc     sp
        inc     sp
        ret
.fsmv_3
        pop     bc
        pop     hl
        pop     de
.fsmv_4
        push    de
        push    hl
        push    bc
        inc     d
        dec     d
        jr      nz, fsmv_7                      ; far ptr
        bit     7, h
        jr      nz, fsmv_5                      ; kernel space, bind in S1
        bit     6, h
        jr      z, fsmv_8                       ; S0, no binding
        ld      a, (BLSC_SR1)                   ; S1 bank into S2
        jr      fsmv_6
.fsmv_5
        bit     6, h                            ; A14 selects S2/S3 bank
        ld      a, (iy+OSFrame_S2)
        jr      z, fsmv_6
        ld      a, (iy+OSFrame_S3)
.fsmv_6
        ld      d, a                            ; store bank
.fsmv_7
        res     7, h                            ; S2 fix
        set     6, h
.fsmv_8
        push    iy
        ld      iy, (BLSC_SR1)                  ; remember S1/S2
        push    iy
        push    bc                              ; IY=BC
        pop     iy
        ld      a, d                            ; buffer in S1
        call    MS1BankA
        ex      de, hl                          ; DE=HL
        call    GetFilePosMemPtr
.fsmv_9
        call    MS2BankB                        ; file in S2
        push    iy                              ; BC=IY
        pop     bc
        ld      a, b
        or      c
        jp      z, fsmv_24                      ; no more bytes? done
        ld      a, (ix+fhnd_filepos_lo)
        and     $3F
        jr      nz, fsmv_13                     ; block not fully used? skip
.fsmv_10
        ex      af, af'
        push    af
        push    de
        jr      c, fsmv_11                      ; write? do it
        call    GetFilePosMemPtr
        ld      e, (hl)                         ; DE=next block
        inc     hl
        ld      d, (hl)
        ld      a, d
        or      a
        scf
        ex      de, hl                          ; HL=next
        pop     de                              ; un-stack for branch
        pop     bc                              ; ditto
        ld      a, RC_Eof
        jp      z, fsmv_25                      ; no next block? EOF

        push    bc                              ; re-stack AF
        push    de                              ; re-stack DE
        ex      de, hl                          ; DE=next
        jr      fsmv_12
.fsmv_11
        call    GetFilePosMemPtr
        ld      e, (hl)                         ; DE=next block
        inc     hl
        ld      d, (hl)
        ld      a, d
        or      a
        jr      nz, fsmv_12                     ; has next? write into it
        call    AllocHandleBlock
        ex      de, hl                          ; HL=de
        pop     de                              ; un-stack for branch
        pop     bc
        jp      c, fsmv_25                      ; no block? exit
        push    bc                              ; re-stack
        push    de
        ex      de, hl                          ; DE=next
        call    GetFilePosMemPtr                ; point this block to next
        ld      (hl), e
        inc     hl
        ld      (hl), d
.fsmv_12
        call    fsAdvanceBlock
        pop     de
        pop     af
        ex      af, af'
        jr      fsmv_9                          ; retry read/write
.fsmv_13
        or      $C0
        neg                                     ; bytes left in block
        ex      af, af'
        inc     l
        ld      a, (hl)                         ; next block
        dec     l
        inc     a
        dec     a
        jr      c, fsmv_16                      ; write? ok
        jr      nz, fsmv_16                     ; has next block? ok
        ex      af, af'
        ld      a, (hl)                         ; #bytes in block
        add     a, l                            ; + block start
        add     a, 2                            ; + header bytes
        jr      nz, fsmv_14
        sub     (ix+fhnd_filepos_lo)            ; -pos = bytes left
        jr      fsmv_15                         ; always ok for full last block_in_page  !! jr +2 bytes
.fsmv_14
        sub     (ix+fhnd_filepos_lo)
        jr      z, fsmv_20                      ; no more bytes? EOF
        jr      c, fsmv_20                      ; already past end? EOF
.fsmv_15
        ex      af, af'
.fsmv_16
        ex      af, af'
        push    hl                              ; IY=HL, block start
        pop     iy
        ld      l, (ix+fhnd_filepos_lo)
        inc     b
        dec     b
        jr      nz, fsmv_17
        cp      c
        jr      nc, fsmv_21
.fsmv_17
        push    bc
        ld      b, 0
        ld      c, a
        ex      af, af'
        jr      nc, fsmv_18                     ; read? HL->DE
        ex      de, hl                          ; write? DE-HL
.fsmv_18
        ldir
        jr      nc, fsmv_19                     ; read? skip
        ex      de, hl                          ; restore HL/DE
        jr      nz, fsmv_19                     ; has next block? skip
        ld      (iy+0), FSBLOCK_SIZE
.fsmv_19
        ex      af, af'                         ; store r/w flag
        ld      (ix+fhnd_filepos_lo), l         ; store new position
        pop     hl                              ; bytes left to read/write
        ld      b, 0
        ld      c, a
        or      a
        sbc     hl, bc
        push    hl
        pop     iy                              ; into IY
        jr      z, fsmv_24                      ; done? exit
        jp      fsmv_10                         ; handle next block
.fsmv_20
        push    bc
        pop     iy
        ld      a, RC_Eof
        scf
        jr      fsmv_25

.fsmv_21
        ex      af, af'
        jr      nc, fsmv_22
        ex      de, hl
.fsmv_22
        ldir
        jr      nc, fsmv_23
        ex      de, hl
        jr      nz, fsmv_23
        ex      af, af'
        ld      a, l
        dec     a
        dec     a
        and     $3F
        ld      (iy+0), a
        ex      af, af'
.fsmv_23
        ex      af, af'
        ld      (ix+fhnd_filepos_lo), l
        ld      iy, 0
.fsmv_24
        or      a
.fsmv_25
        ex      de, hl
        push    af
        pop     de
        pop     bc
        call    MS12BankCB
        push    iy
        pop     bc
        pop     iy
        pop     hl
        or      a
        sbc     hl, bc
        ex      de, hl
        ex      (sp), hl
        add     hl, de
        pop     af
        pop     de
        ret

;       ----

;       compare next byte of stream with A
;       if match, read length into BC and read that many bytes to (HL)

.RdHeaderedData
        ld      d, 0                            ; HL=local
        ld      c, a
        call    RdFileByte
        ret     c
        cp      c
        scf
        ld      a, RC_Type                      ; Unexpected type *
        ret     nz
        call    RdFileByte
        ld      c, a
        ret     c
        call    RdFileByte
        ld      b, a
        ret     c

;       ----

; move BC bytes to (HL)

.MvFromFile
        or      a
        jp      MoveToFromFile

;       ----

.SaveAllAppData
        ld      a, HND_PROC
        call    AllocHandle
        ret     c
        call    InitMemHandle
        ret     c
        call    SaveAppVars                     ; save app variables
        jr      c, saad_err

;       save stack contents and safe area

        ld      hl, (pAppUnSafeArea)
        ld      de, (pAppStackPtr)
        sbc     hl, de
        ld      b, h
        ld      c, l
        ld      a, $A1                          ; A1 - stack
	ex	de, hl
        call    WrHeaderedData
        jr      c, saad_err
        push    ix                              ; save screen if needed
        ld      ix, (uwAppStaticHnd)
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; get application data
        pop     ix
        bit     AT_B_Draw, a
        jr      z, saad_1
        call    SaveScreen
        jr      c, saad_err
.saad_1
        ld      a, $00                          ; write end mark - 00 0E 0F
        call    WrFileByte
        jr      c, saad_err
        ld      a, $0E
        call    WrFileByte
        jr      c, saad_err
        ld      a, $0F
        call    WrFileByte
        jr      c, saad_err
        or      a
        ret
.saad_err
        jp      FreeMemHandle

;       ----

.RestoreAllAppData
        xor     a
        push    af
        call    RewindFile
        call    LoadAppVars
        jr      c, raad_2                       ; error? fail
        ld      hl, (pAppUnSafeArea)            ; BC=size of saved stack
        ld      de, (pAppStackPtr)
        sbc     hl, de
        ld      b, h
        ld      c, l
        ld      a, $A1                          ; A1 - stack
        ld      hl, (pAppStackPtr)
        call    RdHeaderedData
        jr      c, raad_2
        push    ix
        ld      ix, (uwAppStaticHnd)
        ld      bc, NQ_Ain
        OZ      OS_Nq                           ; enquire (fetch) parameter
        pop     ix
        bit     AT_B_Draw, a
        jr      z, raad_1
        call    RestoreScreen
        jr      c, raad_2
        pop     af
        inc     a
        push    af
.raad_1
        call    RdFileByte                      ; check tail bytes - 00 0E 0F
        or      a
        jr      c, raad_2                       ; !! bug? jr nz?
        call    RdFileByte
        cp      $0E
        jr      c, raad_2
        call    RdFileByte
        xor     $0F
        cp      1
        ccf
.raad_2
        jp      c, OZwd__fail
        pop     af
        ret

;       ----

.SaveAppVars
        ld      a, $A0                          ; A0 - app vars
        ld      bc, $40
        ld      hl, uwAppStaticHnd
        jp      WrHeaderedData
.LoadAppVars
        ld      a, $A0                          ; A0 - app vars
        ld      bc, $40
        ld      hl, uwAppStaticHnd
        jp      RdHeaderedData

;       ----

.GetFileEOF
        call    GetFilePosMemPtr
        call    MS2BankB
        ld      e, (hl)                         ; DE=next
        inc     hl
        ld      d, (hl)
        ld      c, e
        inc     d
        dec     d
        jr      z, geof_1                       ; last block? use size from block
        ld      c, FSBLOCK_SIZE
.geof_1
        ld      a, (ix+fhnd_filepos_lo)
        sub     2
        and     $3F
        cp      c
        ccf
        ret     nc                              ; pos<num, no EOF
	jr	nz, geof_eof
        inc     d
        dec     d
        ret     z                               ; last block, pos=num? EOF
        call    FPtr2MemPtrBindS2
        ld      a, (hl)
        inc     hl
        or      (hl)
        ret     nz                              ; next has bytes? not EOF
.geof_eof
        ld      a, RC_Eof
        scf
        ret

;       ----

;OUT:   DEHL=size

.GetFileSize
        call    InitFile_dehl
.fsize_1
        call    FPtr2MemPtrBindS2
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ld      a, d
        or      a
        jr      z, fsize_2
        call    Add_dehl_block
        jr      fsize_1
.fsize_2
        ld      a, e
        jr      gsp_5

;       ----

;OUT:   DEHL

.GetFilePos
        call    InitFile_dehl
.gsp_1
        call    FPtr2MemPtrBindS2
        ld      a, (ix+fhnd_filepos)            ; are we in current block yet?
        cp      e
        jr      nz, gsp_2                       ; no, bump size and go to next
        ld      a, (ix+fhnd_filepos_h)
        cp      d
        jr      z, gsp_4                        ; current block
.gsp_2
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ld      a, d
        or      a
        jr      z, gsp_3                        ; last block,  still not current  !! jp z,OZwd__fail
        call    Add_dehl_block
        jr      gsp_1
.gsp_3
        jp      OZwd__fail
.gsp_4
        ld      a, (ix+fhnd_filepos_lo)
        sub     2
        and     $3F
.gsp_5
        call    Add_dehl_A
        exx
        or      a
        ret

;       ----

.Add_dehl_block
        ld      a, FSBLOCK_SIZE

.Add_dehl_A
        exx
        ld      b, 0
        ld      c, a
        add     hl, bc
        ld      c, b
        ex      de, hl
        adc     hl, bc
        ex      de, hl
        exx
        ret

;       ----

.Sub_dehl_block
        ld      a, FSBLOCK_SIZE

.Sub_dehl_A
        exx
        or      a
        ld      b, 0
        ld      c, a
        sbc     hl, bc
        ld      c, b
        ex      de, hl
        sbc     hl, bc
        ex      de, hl
        ld      a, l
        exx
        ret

.InitFile_dehl
        ld      d, (ix+fhnd_firstblk_h)         ; !! reorder instructions so SeekFile() can use them
        ld      e, (ix+fhnd_firstblk)
        exx                                     ; dehl'=0
        ld      hl, 0
        ld      d, h
        ld      e, l
        exx
        ret
;       ----

.SeekFileMayExpand
        call    SeekFile
        jr      c, ExpandFile
        ret

;       ----

;IN:    DEHL=new size

.SetFileSize
        ld      b, (ix+fhnd_filepos_h)
        ld      c, (ix+fhnd_filepos)
        push    bc
        ld      b, (ix+fhnd_filepos_lo)
        push    bc
        call    SeekFile
        call    c, ExpandFile
        pop     bc
        ld      (ix+fhnd_filepos_lo), b
        pop     bc
        ld      (ix+fhnd_filepos_h), b
        ld      (ix+fhnd_filepos), c
        ret

;       ----

.ExpandFile
        bit     FATR_B_WRITABLE, (ix+fhnd_attr)
        ld      a, RC_Wp                        ; Write protected
        scf
        ret     z
.expf_1
        ld      a, 32
        call    Sub_dehl_A
        jr      c, expf_2                       ; less than 32 bytes to expand
        exx                                     ; write 32 bytes
        push    de
        push    hl
        ld      bc, 32
        call    expf_3
        pop     hl
        pop     de
        exx
        jr      nc, expf_1                      ; no error? loop
        ret
.expf_2
        add     a, 32                           ; number of bytes remaining
        ld      b, 0
        ld      c, a
.expf_3
        ld      d, $10
        ld      hl, byte_F843
        jp      MvToFile

.byte_F843
        defs    32 ($3f)

;       ----

;IN:    DEHL=position

.SeekFile
        exx
        ld      d, (ix+fhnd_firstblk_h)
        ld      e, (ix+fhnd_firstblk)
        jr      seek_2
.seek_1
        call    Sub_dehl_block
        jr      c, seek_5
.seek_2
        ld      (ix+fhnd_filepos_h), d          ; update position block
        ld      (ix+fhnd_filepos), e
        call    FPtr2MemPtrBindS2
        ld      e, (hl)                         ; DE=next
        inc     hl
        ld      d, (hl)
        dec     hl
        ld      a, d
        or      a
        jr      nz, seek_1                      ; not end, advance one block
        ld      a, e                            ; substract last bytes
        call    Sub_dehl_A
        jr      nc, seek_6                      ; still not wanted position? EOF
.seek_3
        add     a, e                            ; +last bytes
        add     a, 2                            ; +2 to skip header
.seek_4
        add     a, l
        ld      (ix+fhnd_filepos_lo), a         ; put position low byte
        or      a
        ret
.seek_5
        add     a, FSBLOCK_SIZE+2
        jr      seek_4
.seek_6
        xor     a
        call    seek_3                          ; set position to the last byte
        ld      a, RC_Eof
        scf
        ret

;       ----

.WrFileByte
        scf                                     ; Fc=1, write into file
        jr      RdWRFile
.RdFileByte
        or      a                               ; Fc=0, read from file
.RdWRFile
        push    bc
        push    de
        push    hl
        push    af
        call    GetFilePosMemPtr                ; BHL=mem ptr
        pop     af                              ; !! pop this after binding, looks better :)
        call    fsMS2BankB                      ; bind mem in
        ex      af, af'
        ld      a, (ix+fhnd_filepos_lo)
        and     $3F
        jr      z, rdwr_eob                     ; end of block? handle
        inc     l
        ld      a, (hl)
        dec     l
        or      a
        jr      nz, rdwr_1                      ; not last block? skip
        ld      a, (ix+fhnd_filepos_lo)
        and     $3F
        sub     2                               ; A=#databytes
        cp      (hl)
        jr      c, rdwr_1                       ; not past end? skip
        ex      af, af'
        jr      nc, rdwr_eof                    ; read request? EOF
        inc     (hl)                            ; increment size of last block
        ex      af, af'
.rdwr_1
        ld      l, (ix+fhnd_filepos_lo)         ; get block pointer
        inc     (ix+fhnd_filepos_lo)            ; and increment it
        ld      a, (hl)                         ; read byte from file
        ex      af, af'
        jr      nc, rdwr_2                      ; read request? skip write
        ld      (hl), a
        ex      af, af'                         ; return written byte
.rdwr_2
        ex      af, af'
        or      a
.rdwr_x
        call    fsRestoreS2
        pop     hl
        pop     de
        pop     bc
        ret
.rdwr_eof
        ld      a, RC_Eof
        scf
        jr      rdwr_x
.rdwr_eob
        ex      af, af'
        ld      hl, ubFsTemp
        ld      (hl), a                         ; remember char
        ex      af, af'                         ; r/w flag into f'
        ld      bc, 1                           ; read/write one byte
        ld      d, 0                            ; from DHL
        call    fsmv_4
        jr      c, rdwr_x
        ld      a, (ubFsTemp)                   ; restore char
        jr      rdwr_x


; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1dcdd
;
; $Id$
; -----------------------------------------------------------------------------


;       ----

;       check that IX is in range 0-8

.IsSpecialHandle
        push    ix
        pop     hl
        ld      de, -9
        add     hl, de
        ret     c                               ; Fc=1 if IX>8
        push    ix
        pop     de
        ret


;       ----
.OpenMem
        push    bc
        push    hl
        ld      a, HND_FILE
        call    AllocHandle
        jr      c, omem_2
        call    InitMemHandle
        pop     hl
        pop     bc
        jr      c, omem_1
        ld      d, b
        ld      b, 0
        call    MvToFile
        ld      (ix+fhnd_attr), FATR_READABLE|FATR_WRITABLE|FATR_MEMORY
        jp      nc, RewindFile
.omem_1
        jp      FreeMemHandle
.omem_2
        pop     hl
        pop     bc
        ret


; file rename
;       ----
.OSRen
        ld      a, HND_DEV
        call    VerifyHandle
        ret     c
        call    DORHandleInUse
        jp      c, DORHandleFree
        cp      a                               ; Fz=1
        call    FileNameDate
        jp      DORHandleFreeDirect


; file delete
;       ----
.OSDel
        ld      a, DR_DEL                       ; delete DOR
        OZ      OS_Dor                          ; DOR interface
        ret


;       ----
.FileNameDate
        ex      af, af'                         ; preserve Fz and Fc
        ld      hl, -17                         ; reserve stack buffer
        add     hl, sp
        ld      sp, hl
        ex      de, hl
        ex      af, af'
        jr      nz, flnd_2                      ; Fz=0? don't rename
        push    af
        call    GetOSFrame_HL                   ; copy HL to stack buffer
        push    de
        ld      c, 17
        call    CopyMemHL_DE
        pop     de
        ld      a, DR_WR                        ; write DOR record
        ld      bc, 'N'<<8|17                   ; Name, 17 chars
        OZ      OS_Dor
.flnd_1
        jr      c, flnd_1                       ; crash if fail
        pop     af
.flnd_2
        push    af
        ld      h, d                            ; HL=stack buffer
        ld      l, e
.flnd_3
        ld      d, h                            ; DE=stack buffer
        ld      e, l
        OZ      GN_Gmd                          ; get current machine date in internal format
        ld      c, (hl)
        OZ      GN_Gmt                          ; get (read) machine time in internal format
        jr      nz, flnd_3                      ; inconsistent, read again
        ld      bc, 3                           ; copy time after date
        ldir
        ex      de, hl                          ; DE=datetime
        ld      a, DR_WR                        ; write DOR record
        ld      bc, 'U'<<8|6                    ; Update, 6 bytes
        OZ      OS_Dor
        pop     af
        jr      nc, flnd_4                      ; Fc=0? don't set creation date
        ld      a, DR_WR                        ; write DOR record
        ld      bc, 'C'<<8|6                    ; Create, 6 bytes
        OZ      OS_Dor
.flnd_4
        ld      hl, 17                          ; restore stack
        add     hl, sp
        ld      sp, hl
        ret
