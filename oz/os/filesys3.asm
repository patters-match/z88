; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $3222
;
; $Id$
; -----------------------------------------------------------------------------

        Module FileSys3

        include "blink.def"
        include "error.def"
        include "fileio.def"
        include "handle.def"
        include "memory.def"
        include "syspar.def"
        include "sysvar.def"


xdef    AddAvailableFsBlock
xdef    AllocFirstBlock
xdef    AllocHandleBlock
xdef    AllocMemFile_SizeHL
xdef    FilePtr2MemPtr
xdef    FreeMemData
xdef    FreeMemData0
xdef    fsMS2BankB
xdef    fsRestoreS2
xdef    GetFileEOF
xdef    GetFilePos
xdef    GetFileSize
xdef    InitFsMemHandle
xdef    InitMemHandle
xdef    MemPtr2FilePtr
xdef    MvFromFile
xdef    MvToFile
xdef    RdFileByte
xdef    RdHeaderedData
xdef    RestoreAllAppData
xdef    RewindFile
xdef    SaveAllAppData
xdef    SeekFileMayExpand
xdef    SetFhnFirstBlock
xdef    SetFileSize
xdef    SetMemHandlePos
xdef    WrFileByte
xdef    WrHeaderedData

xref    AllocHandle                             ; bank0/handle.asm
xref    FPtr2MemPtrBindS2                       ; bank0/misc5.asm
xref    MS12BankCB                              ; bank0/misc5.asm
xref    MS1BankA                                ; bank0/misc5.asm
xref    MS2BankA                                ; bank0/misc5.asm
xref    MS2BankB                                ; bank0/misc5.asm
xref    OZwd__fail                              ; bank0/ozwindow.asm
xref    RestoreScreen                           ; bank0/scrdrv4.asm
xref    SaveScreen                              ; bank0/scrdrv4.asm

xref    FreeMemHandle                           ; bank7/ossr.asm


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
        ld      a, d                            ; !! unnecessary check
        or      e
        ret     z
        jr      FreeMemData

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
        ld      c, 2                            ; segment  !! do this first to avoid duplicate code
        ret
.fp2mp_1
        ld      hl, uwFsAvailBlock
        ld      c, 2                            ; segment
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
        dec     e                               ; previous block
        ld      a, e
        and     3                               ; block_of_page
        cp      3                               ; !! 'lda a,e' before 'dec e', avoids cp
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
        dec     l                               ; !! remove this, add a, $3f
        ld      a, l
        add     a, $40                          ; next block
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
._MoveToFromFile
        call    MoveToFromFile                  ; !! just drop thru
        ret

;       ----

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
        jp      _MoveToFromFile                 ; !! jp directly to MoveToFromFile

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
        ld      hl, (pAppStackPtr)              ; !! ex de,hl
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

; save data from $78d8-78ff to 7dd8-7dff  !! unused

.Save78d8_data
        ld      h, $78
        ld      b, 6
        ld      e, $E0
.loc_F72B
        push    bc
        push    hl
        ld      l, $D8                          ; from 7xd8-7xff
        ld      bc, $28
        ld      d, 0                            ; !! unnecessary
        ld      a, e
        call    WrHeaderedData
        pop     hl
        pop     bc
        ret     c
        inc     h
        inc     e
        djnz    loc_F72B
        ret

; read data from $78d8-78ff to 7dd8-7dff  !! unused

.Load78d8_data
        ld      h, $78
        ld      b, 6
        ld      e, $E0
.loc_F746
        push    bc
        push    hl
        ld      a, e                            ; E0-E6 - SBF extra
        ld      bc, $28
        ld      l, $D8
        call    RdHeaderedData
        pop     hl
        pop     bc
        ret     c
        inc     h
        inc     e
        djnz    loc_F746
        ret

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
        ld      a, RC_Eof                       ; !! just jr nz,EOFcode below
        scf                                     ; !! unnecessary
        ret     nz                              ; pos>num? EOF
        inc     d
        dec     d
        ret     z                               ; last block, pos=num? EOF
        call    FPtr2MemPtrBindS2
        ld      a, (hl)
        inc     hl
        or      (hl)
        ret     nz                              ; next has bytes? not EOF
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
        ld      (ubFsTemp), a                   ; remember char  !! do this write thru HL
        ex      af, af'                         ; r/w flag into f'
        ld      bc, 1                           ; read/write one byte
        ld      d, 0                            ; from DHL
        ld      hl, ubFsTemp
        call    fsmv_4
        jr      c, rdwr_x
        ld      a, (ubFsTemp)                   ; restore char
        jr      rdwr_x

