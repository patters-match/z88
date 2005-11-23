; -----------------------------------------------------------------------------
; Bank 0 @ S3
;
; $Id$
; -----------------------------------------------------------------------------

        Module FileSys2

        include "buffer.def"
        include "dor.def"
        include "error.def"
        include "fileio.def"
        include "memory.def"
        include "misc.def"
        include "serintfc.def"
        include "stdio.def"
        include "syspar.def"
        include "sysvar.def"
        include "../bank7/lowram.def"

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

xref    AllocFirstBlock                         ; bank0/filesys3.asm
xref    FreeMemData0                            ; bank0/filesys3.asm
xref    GetFileEOF                              ; bank0/filesys3.asm
xref    GetFilePos                              ; bank0/filesys3.asm
xref    GetFileSize                             ; bank0/filesys3.asm
xref    MvFromFile                              ; bank0/filesys3.asm
xref    MvToFile                                ; bank0/filesys3.asm
xref    RdFileByte                              ; bank0/filesys3.asm
xref    RewindFile                              ; bank0/filesys3.asm
xref    SeekFileMayExpand                       ; bank0/filesys3.asm
xref    SetFileSize                             ; bank0/filesys3.asm
xref    WrFileByte                              ; bank0/filesys3.asm

xref    ChgHandleType                           ; bank0/handle.asm
xref    FindHandle                              ; bank0/handle.asm
xref    VerifyHandle                            ; bank0/handle.asm
xref    Chk128KB                                ; bank0/resetx.asm
xref    DORHandleFreeDirect                     ; bank0/dor.asm
xref    GetHandlePtr                            ; bank0/dor.asm
xref    VerifyHandleBank                        ; bank0/dor.asm
xref    OSPrtMain                               ; bank0/misc2.asm
xref    RdKbBuffer                              ; bank0/osin.asm
xref    OSFramePop                              ; bank0/misc4.asm
xref    OSFramePush                             ; bank0/misc4.asm

xref    CopyMemHL_DE                            ; bank0/misc5.asm
xref    GetOSFrame_DE                           ; bank0/misc5.asm
xref    GetOSFrame_HL                           ; bank0/misc5.asm
xref    MS2BankA                                ; bank0/misc5.asm
xref    MS2BankK1                               ; bank0/misc5.asm
xref    PeekHLinc                               ; bank0/misc5.asm
xref    PokeHLinc                               ; bank0/misc5.asm
xref    PutOSFrame_BC                           ; bank0/misc5.asm
xref    PutOSFrame_DE                           ; bank0/misc5.asm
xref    PutOSFrame_HL                           ; bank0/misc5.asm

xref    FileNameDate                            ; bank7/filesys1.asm
xref    IsSpecialHandle                         ; bank7/filesys1.asm
xref    OpenMem                                 ; bank7/filesys1.asm
xref    OSDel                                   ; bank7/filesys1.asm
xref    OSOutMain                               ; bank7/scrdrv1.asm


;       ----

;       get byte from special handle
;

.GbtSpecial
        dec     e
        jr      nz, gbts_1

        push    ix                              ; 1 - read keyboard
        call    RdKbBuffer
        pop     ix
        ret

.gbts_1
        dec     e
        jr      z, RcRp                         ; 2 - read screen - rd protected

        dec     e
        jr      z, RcRp                         ; 3 - read printer direct - rd protected

        dec     e
        ld      a, RC_Eof
        scf
        ret     z                               ; 4 - read NUL - EOF

        dec     e
        jr      nz, gbts_2

        ld      l, SI_GBT                       ; 5 - read serial port
        OZ      OS_Si
        ret

.gbts_2
        dec     e
        jr      nz, gbts_3

        OZ      OS_Tin                          ; 6 - read stdin
        ret                                     ; read a byte from std. input, with timeout

.gbts_3
        dec     e
        jr      z, RcRp                         ; 7 - read stdout - rd protected

        dec     e
        jr      z, RcRp                         ; 8 - read printer filter - rd protected

        ld      a, RC_Hand
        scf
        ret

.RcRp
        ld      a, Rc_Rp
        scf
        ret

;       ----

;       put bute to special handle

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
        jr      osmv_4                          ;

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
        jp      nc, PbtSpecial

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
