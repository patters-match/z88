; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2009
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     module ApplDorScanning

     include "memory.def"
     include "dor.def"
     include "error.def"

     lib ApplEprType          ; Evaluate Standard Z88 Application ROM Format (Front Dor/ROM Header)
     lib MemReadByte          ; Read byte at pointer in BHL, offset A, returned in A
     lib MemWritePointer      ; Set pointer in CDE, at record base pointer BHL, offset A.
     lib MemReadPointer       ; Read pointer at record defined as extended (base) address in BHL, offset A.
     lib MemWriteByte         ; Set byte in C, at base record pointer in BHL, offset A.
     lib SafeBHLSegment       ; Prepare BHL pointer to be bound into a safe segment specfier returned in C


     xdef ApplRomFindDor, ApplRomFrontDor, ApplRomReadDorPtr
     xdef ApplRomFirstDor, ApplRomNextDor, ApplRomLastDor, ApplRomSetNextDor
     xdef ApplRomGetDorSize, ApplRomCopyDor, ApplRomDorName
     xdef ApplSegmentBinding, ApplSetSegmentBinding
     xdef ApplTopicsPtr, ApplCommandsPtr, ApplHelpPtr, ApplTokenbasePtr
     xdef ApplSetTopicsPtr, ApplSetCommandsPtr, ApplSetHelpPtr, ApplSetTokenbasePtr
     xdef ApplRomCopyCardHdr

     xref CopyMemory


; *************************************************************************************
;
; Return pointer to Application DOR in BHL
;
; In:
;    C = slot number (0, 1, 2 or 3)
;    DE = local pointer to application DOR name, null-terminated (must match name in DOR exactly)
;
; Out:
;    Success:
;         Fc = 0,
;              BHL = pointer to start of DOR
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, Application DOR not found in slot C
;              BHL = 0
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.ApplRomFindDor
                    push de
                    push bc

                    call ApplRomFirstDor     ; get pointer to first app DOR of slot C in BHL
                    jr   c, exit_ApplRomFindDor
.scan_slot
                    call ApplRomValidateDor  ; is it a valid DOR?
                    jr   c, exit_ApplRomFindDor

                    call ApplRomDorName      ; get offset to DOR name in C (length of name in A)
                    push de                  ; preserve pointer to start of search key
.compare_name       ld   a,c
                    call MemReadByte
                    inc  c
                    ex   de,hl
                    cp   (hl)
                    inc  hl
                    ex   de,hl
                    jr   nz, check_nextDor
                    or   a                   ; reached null-terminator?
                    jr   nz,compare_name     ; match found, but not yet reached null-byte of DOR name...
.found_dor
                    pop  de                  ; last byte compared was null-terminator - match found!
                    jr   exit_ApplRomFindDor
.check_nextDor
                    pop  de                  ; no name match at current DOR,
                    call ApplRomNextDor      ; jump to next application DOR and check it's name...
                    xor  a
                    or   b
                    or   h
                    or   l
                    jr   nz, scan_slot       ; another application DOR found, check DOR name
                    scf
                    ld   a,RC_ONF            ; end of list reached, DOR not found in slot...
.exit_ApplRomFindDor
                    pop  de
                    ld   c,e                 ; restore original C
                    pop  de
                    ret
; *************************************************************************************



; *************************************************************************************
;
; Copy Application DOR at BHL to local RAM at DE.
;
; In:
;    BHL = pointer to base of DOR (if B=0 then HL is also a local pointer)
;    DE = local pointer to RAM buffer
;
; Out:
;    Success:
;         Fc = 0,
;              Valid DOR copied to RAM buffer at DE
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, Invalid Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY    same
;    AF....../.... bc different
;
.ApplRomCopyDor
                    push hl
                    push de
                    push bc

                    call ApplRomValidateDor  ; is it a valid DOR?
                    jr   c, exit_ApplRomFindDor

                    call ApplRomGetDorSize
                    exx
                    ld   b,0
                    ld   c,a
                    exx
                    call CopyMemory          ; copy DOR at (BHL) to (DE)
.exit_ApplRomCopyDor
                    pop  bc
                    pop  de
                    pop  hl
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Get size of Application DOR at BHL
;
; In:
;    BHL = pointer to base of DOR (if B=0 then HL is also a local pointer)
;
; Out:
;    Success:
;         Fc = 0,
;              A = total size of DOR, from base pointer to end marker (inclusive).
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, Invalid Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplRomGetDorSize
                    call ApplRomValidateDor  ; DOR really there?
                    ret  c
                    push bc
                    ld   c,3+3+3+1
                    ld   a,c
                    call MemReadByte         ; total DOR length (excl. pointer section)
                    add  a,c                 ; add pointer section + type
                    inc  a                   ; + length byte
                    pop  bc
                    ret
; *************************************************************************************



; *************************************************************************************
;
; Get DOR start offset to application name section.
;
; In:
;    BHL = pointer to base of DOR (if B=0 then HL is local pointer)
;
; Out:
;    Success:
;         Fc = 0,
;         C = offset from base DOR pointer to first char of application name
;         A = length of name incl. null-terminator
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, Application DOR not recognized
;
; Registers changed after return:
;    ..B.DEHL/IXIY same
;    AF.C..../.... different
;
.ApplRomDorName
                    ld   c,$2d               ; point at 'N' name section
                    ld   a,c

                    call GetRecId
                    cp   'N'                 ; reached DOR Name section?
                    jr   z, found_dorname
                    scf
                    ld   a,RC_ONF
                    ret
.found_dorname
                    jr   GetRecId            ; get length of name incl null in A
                                             ; C = offset to first char of application name
; *************************************************************************************



; *************************************************************************************
; Validate Application DOR
; - make sure that Info, Help, Name section and End Marker is recognized.
;
; In:
;    BHL = pointer to base of DOR (if B=0 then HL is local pointer)
;
; Out:
;    Success:
;         Fc = 0, a valid Application DOR is recognized at BHL base pointer
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, Application DOR not recognized
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplRomValidateDor
                    push bc

                    ld   c,3+3+3             ; point at type byte
                    ld   a,c
                    call MemReadByte         ; validate that we get a DOR Type
                    cp   Dm_Rom
                    jr   nz, err_ValidateDor
                    inc  c
                    inc  c                   ; offset to '@' info record identifier
                    call GetRecId
                    cp   '@'
                    jr   nz, err_ValidateDor ; no Info section!
                    ld   a,c
                    add  a,18+1
                    ld   c,a                 ; info section contains length byte + 18 bytes
                    call GetRecId
                    cp   'H'
                    jr   nz, err_ValidateDor ; no Help section!
                    ld   a,c
                    add  a,12+1              ; help section contains
                    ld   c,a                 ; length byte + 4 x (3 byte) pointers
                    call GetRecId
                    cp   'N'
                    jr   nz, err_ValidateDor ; no Name section!
                    call MoveToNextRec
                    call GetRecId
                    cp   $ff
                    jr   z, exit_ValidateDor ; end marker was found, DOR valicated...
.err_ValidateDor
                    scf
                    ld   a, RC_ONF
.exit_ValidateDor
                    pop  bc
                    ret
.GetRecId
                    ld   a,c
                    call MemReadByte
                    inc  c
                    ret
.MoveToNextRec
                    ld   a,c
                    call MemReadByte         ; get length of current record
                    add  a,c
                    inc  a
                    ld   c,a                 ; and point at next record Id
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Return default bank binding of specified segment in application DOR
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;      C = segment binding specifier (0-3)
;
; Out:
;    Success:
;         Fc = 0,
;              A = default bank binding for segment C in DOR
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplSegmentBinding
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,c
                    and  @00000011           ; only 0-3 allowed
                    add  a,25                ; the first segment binding specifier is at 25th byte in DOR
                    jp   MemReadByte         ; return bank segment binding in A
; *************************************************************************************


; *************************************************************************************
;
; Set default bank binding of specified segment in application DOR
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;      C = segment binding specifier (0-3)
;      A = bank number
;
; Out:
;    Success:
;         Fc = 0,
;              A = new default bank binding for segment C in DOR
;                  (A is automatcically masked slot relative)
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplSetSegmentBinding
                    push af
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    jr   nc, setsegmb
                    inc  sp
                    inc  sp
                    ret                      ; pop bank number and return error code
.setsegmb
                    pop  af                  ; restore bank number
                    and  @00111111           ; make sure that bank is slot relative
                    push bc
                    ex   af,af'
                    push af                  ; preserve original alternate AF
                    ld   a,c
                    and  @00000011           ; only 0-3 allowed
                    add  a,25                ; point at segment binding specifier for bank
                    ex   af,af'
                    ld   c,a                 ; C = bank
                    ex   af,af'
                    call MemWriteByte        ; return bank segment binding in A
                    pop  af                  ; original alternate AF restored
                    ex   af,af'
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Return pointer to Last Application DOR of slot C in BHL (second pointer from start
; of DOR), scanning the brother link of each DOR.
;
; -------------------------------------------------------------------------------
; Start of DOR:
; 3 bytes     0 0 0         Link to parent
; 3 bytes     x x x         Link to brother (0 0 0 if only application or last app in chain)
; 3 bytes     0 0 0         Link to son
; ...
; -------------------------------------------------------------------------------
;
; In:
;    C = slot number (0, 1, 2 or 3)
;
; Out:
;    Success:
;         Fc = 0,
;              BHL = pointer to last application DOR in list of slot C
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DORs found in slot C
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.ApplRomLastDor
                    call ApplRomFirstDor     ; get the first (top) DOR of slot
                    ret  c
                    push de
.next_dor_loop
                    push bc
                    push hl
                    call ApplRomNextDor      ; get Next DOR in application list
                    xor  a
                    or   b
                    or   h
                    or   l
                    jr   z, last_dor_reached ; if BHL = 0 then we've reached beyond end of list...
                    pop  de
                    pop  de                  ; forget old DOR pointer...
                    jr   next_dor_loop       ; and use this DOR pointer to get the next
.last_dor_reached
                    pop  hl
                    pop  bc                  ; return BHL = last DOR in slot
                    pop  de
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Return MTH Application Topics pointer in DOR
;
; -------------------------------------------------------------------------------
; 'H'                       Key to help section
; 1 byte      n             Length of help section
; 3 bytes     x x x         Extended pointer to topics
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;
; Out:
;    Success:
;         Fc = 0,
;              CDE = pointer to MTH Topics for application DOR
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    AFB...HL/IXIY same
;    ...CDE../.... different
;
.ApplTopicsPtr
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,33                ; (point at first byte of Topics pointer)
.GetMthPointer                               ; return MTH pointer in CDE
                    push bc
                    push hl
                    call ApplRomReadDorPtr   ; return link to Topics section
                    ex   de,hl
                    pop  hl
                    ld   a,b
                    pop  bc
                    ld   c,a
                    ret
; *************************************************************************************



; *************************************************************************************
;
; Return MTH Application Commands pointer in DOR
;
; -------------------------------------------------------------------------------
; 'H'                       Key to help section
; 1 byte      n             Length of help section
; 3 bytes     0 0 0         Extended pointer to topics
; 3 bytes     x x x         Extended pointer to commands
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;
; Out:
;    Success:
;         Fc = 0,
;              CDE = pointer to MTH Commands for application DOR
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..B...HL/IXIY same
;    AF.CDE../.... different
;
.ApplCommandsPtr
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,36                ; (point at first byte of Commands pointer)
                    jr   GetMthPointer       ; return MTH pointer in CDE
; *************************************************************************************



; *************************************************************************************
;
; Return MTH Application Help pointer in DOR
;
; -------------------------------------------------------------------------------
; 'H'                       Key to help section
; 1 byte      n             Length of help section
; 3 bytes     0 0 0         Extended pointer to topics
; 3 bytes     0 0 0         Extended pointer to commands
; 3 bytes     x x x         Extended pointer to application help
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;
; Out:
;    Success:
;         Fc = 0,
;              CDE = pointer to MTH Help for application DOR
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..B...HL/IXIY same
;    AF.CDE../.... different
;
.ApplHelpPtr
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,39                ; (point at first byte of Help pointer)
                    jr   GetMthPointer       ; return MTH pointer in CDE
; *************************************************************************************



; *************************************************************************************
;
; Return MTH Token base pointer in DOR
;
; -------------------------------------------------------------------------------
; 'H'                       Key to help section
; 1 byte      n             Length of help section
; 3 bytes     0 0 0         Extended pointer to topics
; 3 bytes     0 0 0         Extended pointer to commands
; 3 bytes     0 0 0         Extended pointer to application help
; 3 bytes     x x x         Extended pointer to token base
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;
; Out:
;    Success:
;         Fc = 0,
;              CDE = pointer to MTH Token base for application DOR
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..B...HL/IXIY same
;    AF.CDE../.... different
;
.ApplTokenbasePtr
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,42                ; (point at first byte of Token base pointer)
                    jr   GetMthPointer       ; return MTH pointer in CDE
; *************************************************************************************



; *************************************************************************************
;
; Set MTH Application Topics pointer in DOR
;
; -------------------------------------------------------------------------------
; 'H'                       Key to help section
; 1 byte      n             Length of help section
; 3 bytes     x x x         Extended pointer to topics
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;    CDE = MTH Topics pointer
;
; Out:
;    Success:
;         Fc = 0,
;              MTH Topics pointer in DOR updated with CDE
;              (C is masked as slot-relative bank number)
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplSetTopicsPtr
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,33                ; (point at first byte of Topics pointer)
                    jr   WriteSlotRelPtr     ; set MTH pointer in CDE at (BHL)
; *************************************************************************************



; *************************************************************************************
;
; Set MTH Application Commands pointer in DOR
;
; -------------------------------------------------------------------------------
; 'H'                       Key to help section
; 1 byte      n             Length of help section
; 3 bytes     0 0 0         Extended pointer to topics
; 3 bytes     x x x         Extended pointer to commands
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;    CDE = MTH Commands pointer
;
; Out:
;    Success:
;         Fc = 0,
;              MTH Commands pointer in DOR updated with CDE
;              (C is masked as slot-relative bank number)
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplSetCommandsPtr
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,36                ; (point at first byte of Commands pointer)
                    jr   WriteSlotRelPtr     ; set MTH pointer in CDE at (BHL)
; *************************************************************************************



; *************************************************************************************
;
; Set MTH Application Help pointer in DOR
;
; -------------------------------------------------------------------------------
; 'H'                       Key to help section
; 1 byte      n             Length of help section
; 3 bytes     0 0 0         Extended pointer to topics
; 3 bytes     0 0 0         Extended pointer to commands
; 3 bytes     x x x         Extended pointer to application help
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;    CDE = MTH Help pointer
;
; Out:
;    Success:
;         Fc = 0,
;              MTH Help pointer in DOR updated with CDE
;              (C is masked as slot-relative bank number)
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplSetHelpPtr
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,39                ; (point at first byte of Help pointer)
                    jr   WriteSlotRelPtr     ; set MTH pointer in CDE at (BHL)
; *************************************************************************************



; *************************************************************************************
;
; Set MTH Application Token base pointer in DOR
;
; -------------------------------------------------------------------------------
; 'H'                       Key to help section
; 1 byte      n             Length of help section
; 3 bytes     0 0 0         Extended pointer to topics
; 3 bytes     0 0 0         Extended pointer to commands
; 3 bytes     0 0 0         Extended pointer to application help
; 3 bytes     x x x         Extended pointer to token base
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;    CDE = MTH Token base pointer
;
; Out:
;    Success:
;         Fc = 0,
;              MTH Token base pointer in DOR updated with CDE
;              (C is masked as slot-relative bank number)
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplSetTokenbasePtr
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,42                ; (point at first byte of Token base pointer)
                    jr   WriteSlotRelPtr     ; set MTH pointer in CDE at (BHL)
; *************************************************************************************



; *************************************************************************************
;
; Set pointer (in CDE) to Next Application in DOR at BHL (second pointer from start of DOR).
;
; -------------------------------------------------------------------------------
; Start of DOR:
; 3 bytes     0 0 0         Link to parent
; 3 bytes     x x x         Link to brother (0 0 0 if only application or last app in chain)
; 3 bytes     0 0 0         Link to son
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;    CDE = pointer to next DOR (brother)
;
; Out:
;    Success:
;         Fc = 0,
;              brother link in DOR updated with CDE
;              (C is masked as slot-relative bank number)
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.ApplRomSetNextDor
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a,3
.WriteSlotRelPtr
                    push bc
                    res  7,c
                    res  6,c                 ; use only slot-relative bank numbers in DOR pointers...
                    res  7,d
                    res  6,d                 ; bank offset is always 16K range
                    call MemWritePointer     ; (BHL,A) = CDE
                    pop  bc                  ; restore C
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Return pointer to Application Front DOR in BHL
;
; In:
;    C = slot number (0, 1, 2 or 3)
;
; Out:
;    Success:
;         Fc = 0,
;              BHL = pointer to Front DOR of slot C
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, Application Card Front DOR not found in slot C
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.ApplRomFrontDor    push bc
                    call ApplEprType
                    pop  bc
                    ret  c                   ; no application "OZ" card found in slot C
                    ld   a,c
                    rrca
                    rrca
                    or   $3F
                    ld   b,a
                    ld   hl, $3fc0           ; point to start of Application Card Front DOR

                    push bc                  ; validate that a Front DOR is present at location
                    push hl
                    xor  a
                    call MemReadPointer      ; Link to parent should be 0
                    or   b
                    or   h
                    or   l
                    pop  hl
                    pop  bc
                    jr   nz, err_applfrontdor
                    ld   a,3+3+3
                    call MemReadByte         ; check if Rom Front DOR Type = $13
                    cp   Dn_Apl
                    jr   nz, err_applfrontdor
                    ret                      ; return Fc = 0, BHL = Rom Front DOR
.err_applfrontdor
                    ld   a,RC_ONF
                    scf
                    ret
; *************************************************************************************


; *************************************************************************************
; Get a copy of the application card header (64 bytes) in slot C to buffer in local
; address space memory, using DE register as pointer.
;
; In:
;    C = slot number (0, 1, 2 or 3)
;    DE = local pointer in address space to copy Card header
;
; Out:
;    Fc = 0,
;         (DE) contains card header
;
; Registers changed after return:
;    ..BCDEHL/IXIY    same
;    AF....../.... bc different
;
.ApplRomCopyCardHdr
                    push bc
                    push de
                    push hl

                    ld   a,c
                    and  @00000011                      ; only slots 0, 1, 2 or 3 possible
                    rrca
                    rrca                                ; converted to slot mask $40, $80 or $c0
                    or   $3f                            ; top bank in slot...
                    ld   b,a
                    ld   hl,$3fc0
                    exx
                    ld   bc,64
                    exx
                    call CopyMemory                     ; copy 64 bytes from BHL to DE...
.exit_ApplRomCopyCardHdr
                    pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Return pointer to First (Top) Application DOR of slot C in BHL
;
; In:
;    C = slot number (0, 1, 2 or 3)
;
; Out:
;    Success:
;         Fc = 0,
;              BHL = pointer to first (top) application DOR in slot C
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found in slot C
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.ApplRomFirstDor
                    call ApplRomFrontDor
                    ret  c                   ; no application card...
                    ld   a, 3+3
                    jr   ApplRomReadDorPtr   ; return Link to son (3. pointer of Front DOR) in slot C
; *************************************************************************************


; *************************************************************************************
;
; Return pointer to Next Application DOR in BHL (second pointer from start of DOR).
;
; -------------------------------------------------------------------------------
; Start of DOR:
; 3 bytes     0 0 0         Link to parent
; 3 bytes     x x x         Link to brother (0 0 0 if only application or last app in chain)
; 3 bytes     0 0 0         Link to son
; ...
; -------------------------------------------------------------------------------
;
; In:
;    BHL = base pointer to current DOR (if B=0 then HL is local pointer)
;
; Out:
;    Success:
;         Fc = 0,
;              BHL = pointer to next (brother) application DOR
;              if B(in) = 0, then next App DOR ptr is slot relative.
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, no Application DOR found at BHL
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.ApplRomNextDor
                    call ApplRomValidateDor  ; make sure that a DOR is available at BHL pointer...
                    ret  c
                    ld   a, 3                ; return Link to brother (2. pointer of Front DOR) in slot C
; *************************************************************************************


; *************************************************************************************
; Get DOR pointer in BHL, masked to use the slot of the BHL input pointer.
; (All pointers in DOR's are slot relative)
;
; In:
;    BHL,A = pointer to DOR pointer (if B=0 then HL = local pointer)
;
; Out:
;    Fc = 0,
;    BHL = pointer to DOR - masked for B(in) slot, or BHL = 0 if null pointer
;    if B(in) = 0 (no embedded slot mask): BHL returned = slot relative
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.ApplRomReadDorPtr
                    ex   af,af'
                    ld   a,b
                    and  @11000000           ; preserve slot mask of this pointer
                    ex   af,af'
                    call MemReadPointer
                    inc  b
                    dec  b
                    ret  z                   ; don't restore slot mask when it's a null pointer
                    ex   af,af'
                    or   b
                    ld   b,a                 ; return pointer as part of current slot
                    ret
; *************************************************************************************
