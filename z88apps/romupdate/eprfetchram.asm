     Module EprFetchToRAM

     LIB FileEprFileImage
     LIB FileEprFileEntryInfo
     LIB FileEprTransferBlockSize
     LIB MemDefBank             ; Bind bank, defined in B, into segment C. Return old bank binding in B
     LIB ApplSegmentMask        ; Get segment mask (MM_Sx) of this executing code)
     LIB SafeSegmentMask        ; Get a 'safe' segment mask outside the current executing code

     include "error.def"
     include "memory.def"


; ***************************************************************************************************
;
; Standard Z88 File Eprom Format.
;
; Copy file (image) from file area to memory (RAM) buffer. This routine runs no boundary checking;
; the application is responsible for copying files into the RAM buffer at CDE without crossing
; the bank boundary of CDE, ie. the file must be able to be copied as one unit within the boundaries
; of bank C, offset DE.
;
; IN:
;         BHL = pointer to file entry to be copied
;         CDE = pointer to RAM buffer (max. 16K)
; OUT:
;         Fc = 0,
;              File successfully copied to RAM buffer in CDE.
;         Fc = 1,
;              File Entry at BHL was not found.
;                   A = RC_Onf
;
; Registers changed on return:
;    ..BCDEHL/IXIY ........ same
;    AF....../.... afbcdehl different
;
; -------------------------------------------------------------------------
; Design & Programming by Gunther Strube, Apr 2008
; -------------------------------------------------------------------------
;
.EprFetchToRAM
                    push ix                       ; preserve IX
                    push iy                       ; preserve original IY

                    push bc 
                    push de
                    push hl

                    call FileEprFileEntryInfo     ; return CDE = file image size, A = length of entry filename
                    jr   c, exit_EprFetchToRAM    ; File entry not recognised, exit with error...
                    push bc
                    push de
                    exx
                    pop  de
                    pop  bc                       ; File Entry File Image size in 'CDE
                    exx

                    pop  hl
                    pop  de
                    pop  bc
                    res  7,h
                    res  6,h                      ; discard segment mask, if any...
                    res  7,d
                    res  6,d
                    push bc 
                    push de
                    push hl
                    call FileEprFileImage         ; BHL now points at first byte of file image (not file entry)
                    call CopyFileEntry            ; Now, copy source file entry to RAM buffer in CDE
.exit_EprFetchToRAM
                    pop  hl
                    pop  de
                    pop  bc
                    pop  iy
                    pop  ix
                    ret


; **************************************************************************
.CopyFileEntry
.copy_file_loop
                    exx                           ; file size = 0?
                    ld   a,d
                    or   e
                    exx
                    jr   nz, copy_file_block      ; No, bytes still left to copy...
                    exx
                    xor  a
                    or   c
                    exx
                    ret  z                        ; File entry was successfully copied to RAM buffer!
.copy_file_block
                    call FileEprTransferBlockSize ; get block size in hl' based on current BHL pointer & file size in cde'
                    push iy                       ; preserve base pointer to local stack variables
                    exx
                    push bc
                    push de                       ; preserve remaining file size
                    push hl
                    pop  iy                       ; size of block to copy
                    exx

                    call EprCopyFileImage         ; copy file entry from BHL to CDE, block size IY

                    exx
                    pop  de
                    pop  bc                       ; restore remaining file size = CDE
                    exx
                    pop  iy                       ; restore base pointer to local stack variables...
                    jr   copy_file_loop           ; then get next block from source file

.EprCopyFileImage
                    push iy
                    push bc

                    call SafeSegmentMask               ; get safe segments for BHL & CDE pointers (outside executing PC segment)
                    push af
                    res  7,h
                    res  6,h
                    or   h
                    ld   h,a                           ; HL[sgmask]
                    call ApplSegmentMask               ; PC[sgmask]
                    ex   (sp),hl
                    xor  h
                    res  7,d
                    res  6,d
                    or   d
                    ld   d,a                           ; DE[sgmask] = PC[sgmask] XOR HL[sgmask]
                    pop  hl

                    push bc
                    ld   a,h
                    exx
                    pop  bc
                    rlca
                    rlca
                    ld   c,a                           ; C = MS_Sx of BHL source data block
                    call MemDefBank                    ; Bind bank of source data into segment C
                    push bc                            ; preserve old bank binding of segment C
                    exx

                    ex   de,hl
                    ld   b,c                           ; BHL <- CDE
                    call EprCopyToBuffer               ; DE now source block in current address space, BHL destination pointer
                    exx
                    pop  bc
                    call MemDefBank                    ; restore old segment C bank binding of BHL source data block
                    exx

                    res  7,d
                    res  6,d
                    add  iy,de                         ; block size + offset = updated block pointer (installed in HL below)
                    push iy

                    ex   de,hl
                    ld   c,b
                    res  7,d
                    res  6,d                           ; return updated CDE destination pointer to caller

                    pop  hl                            ; HL = updated byte beyond source block offset
                    pop  af
                    ld   b,a                           ; original B restored
                    bit  6,h                           ; source pointer crossed bank boundary?
                    jr   z,exit_EprCopyFileImage           ; nope (withing 16k offset)
                    inc  b
                    res  6,h                           ; source block copy reached boundary of bank...
.exit_EprCopyFileImage
                    pop  iy                            ; restored original IY
                    ret


; In :
;         DE = local pointer to start of block (located in current address space)
;         BHL = extended address to start of destination 
;              (bits 7,6 of B is the slot mask)
;              (bits 7,6 of H = MM_Sx segment mask for BHL)
;         IY = size of block (at DE) to copy
; Out:
;         Success:
;              Fc = 0
;              BHL updated
;
; Registers changed on return:
;    ...CDE../IXIY ........ same
;    AFB...HL/.... afbcdehl different
;
.EprCopyToBuffer
                    push ix
                    push de                            ; preserve DE
                    push bc                            ; preserve C

                    ld   a,h
                    rlca
                    rlca
                    and  @00000011
                    ld   c,a                           ; C = MS_Sx
                    ld   a,b
                    call MemDefBank                    ; Bind slot x bank into segment C
                    push bc                            ; preserve old bank binding of segment C
                    ld   b,a                           ; but use current bank as reference...

                    call CopyBlock

                    ld   d,b                           ; preserve current Bank number of pointer...
                    pop  bc
                    call MemDefBank                    ; restore old segment C bank binding
                    ld   b,d

                    pop  de
                    ld   c,e                           ; original C register restored...
                    pop  de
                    pop  ix
                    ret


; ***************************************************************
;
; Copy Block to BHL already bound of IY length.
;
; In:
;         C  = MS_Sx segment specifier
;         DE = local pointer to start of block (available in current address space)
;         BHL = extended address to start of destination (pointer into RAM buffer)
;         IY = size of block to copy
; Out:
;    Fc = 0
;         BHL = points at next free byte in RAM buffer
;         DE = points beyond last byte of source 
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.CopyBlock 
                    exx
                    push iy
                    pop  hl                  ; use hl as 16bit decrement counter
                    exx

.CopyBlockLoop      exx
                    ld   a,h
                    or   l
                    dec  hl
                    exx
                    ret  z                   ; block copied successfully
                    push bc

                    ld   a,(de)
                    ld   (hl),a              ; copy the byte...

                    inc  de                  ; buffer++
                    ld   a,b
                    push af

                    ld   a,h                 ; BHL++
                    and  @11000000           ; preserve segment mask

                    res  7,h
                    res  6,h                 ; strip segment mask to determine bank boundary crossing
                    inc  hl                  ; ptr++
                    bit  6,h                 ; crossed bank boundary?
                    jr   z, not_crossed      ; no, offset still in current bank
                    inc  b
                    res  6,h                 ; yes, HL = 0, B++
.not_crossed
                    or   h                   ; re-establish original segment mask for bank offset
                    ld   h,a

                    pop  af
                    cp   b                   ; was a new bank crossed?
                    jr   z,CopyBlockLoop     ; no...

                    push bc                  ; pointer crossed a new bank
                    call MemDefBank          ; bind new bank into segment C...
                    pop  bc
                    jr   CopyBlockLoop
