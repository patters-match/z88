     XLIB FlashEprFileFormat

     LIB SafeSegmentMask
     LIB MemDefBank, MemReadByte, MemReadPointer, MemAbsPtr
     LIB FlashEprVppOn, FlashEprVppOff
     LIB FlashEprCardId, FlashEprWriteBlock
     LIB FlashEprBlockErase
     LIB FlashEprStdFileHeader
     LIB FlashStoreFileEpr
     LIB FlashStore_CheckPartitionID
     LIB FlashStore_NextPartitionID
     
     INCLUDE "flstore.def"
     INCLUDE "time.def"
     INCLUDE "saverst.def"
     INCLUDE "memory.def"
     INCLUDE "error.def"


; ************************************************************************
;
; 1MB Flash Eprom File Area Formatting.
; Create an "oz" File Area below application Rom Area, or
; on empty Flash Eprom to create a normal "oz" File Eprom. 
;
; Defining 8 banks in the ROM Front DOR for applications will leave 58
; banks for file storage. This scheme is however always performed with
; only formatting the Flash Eprom in free modulus 64K blocks, ie.
; having defined 5 banks for ROM would "waste" three banks for 
; applications.
;
; Hence, ROM Front DOR definitions should always define bank reserved 
; for applications in modulus 64K, eg. 4 banks, 8, 12, etc...
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Apr 1998
; ----------------------------------------------------------------------
;
; IN:
;    A = reason code:
;         FSFMT_CRPT     CReate ParTition
;         FSFMT_EXPT     EXtend ParTition with next (lower) Partition
;         FSFMT_ERPT     ERase ParTition
;         FSFMT_RMPT     ReMove ParTitions/erase whole File Area
;         FSFMT_FRPT     Get FRee void space for PaRtition
;
.FlashEprFileFormat
                    CP   FSFMT_CRPT               ; Create partition function?
                    JP   Z, FS_CreatePartition
                    CP   FSFMT_RMPT               ; Remove partitions/erase whole File Area function?
                    JP   Z, FS_RemovePartitions

                    LD   A,RC_Unk                 ; Unknown request
                    SCF
                    RET


; ************************************************************************
;
; Format existing Partition in Flash Eprom File Area.
; All 64K blocks in partition will be erased, and the Partition Identifier
; will be updated with new format time/date stamp and format counter.
; All other Identifier information will remain identical.
;
; IN:
;    BHL = pointer to Partition ID location on Flash Eprom (slot relative)
;
; OUT:
;    Success:
;         Fc = 0, erased successfully, Partion Identifier updated at (BHL)
;         A = size of partition in 64K blocks
;    Failure:
;         Fc = 1
;         A = Error code
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;    
.FS_FormatPartition
                    PUSH BC                  ; preserve original BC
                    PUSH DE                  ; preserve original DE
                    PUSH HL                  ; preserve original HL
                    PUSH IX

                    LD   A,3                 ; slot 3...
                    CALL MemAbsPtr           ; first convert BHL to abs. pointer...

                    CALL FlashStore_CheckPartitionID
                    JR   C, exit_FormatPt

                    EXX
                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-32
                    ADD  IX,SP               ; IX points at start of buffer
                    LD   SP,IX               ; 32 byte buffer created...
                    PUSH HL                  ; preserve original SP
                    EXX

                    PUSH IX
                    POP  DE                  ; point to start of buffer
                    CALL CopyPartitionId     ; copy from (BHL) to (DE)...

                    LD   C,(IX+$1C)          ; C = total of 16K banks to be erased...
                    CALL ErasePtBlocks       ; B = Top Bank of Partition
                    CALL UpdatePartitionID   ; $3FF2,F8: Update date/time of format, counter...

                    LD   A,C
                    SRL  A
                    SRL  A                   ; return A = partition size in 64K blocks

                    CALL WritePartitionID    ; Blow Partition ID at (DE) to (BHL)...
.wrerr_FormatPt
                    POP  HL
                    LD   SP,HL               ; restore old SP (buffer removed)
.exit_FormatPt
                    POP  IX                  ; original IX restored
                    POP  HL                  ; original HL restored
                    POP  DE                  ; original DE restored
                    POP  BC                  ; original BC restored
                    RET                      ; Fc = ?, A = ?


; ************************************************************************
;
; Erase Blocks in Flash Eprom Partition
;
; IN:
;    B = Top bank of Partition
;    C = Number of 16K banks in partitition
;
; OUT:
;    Fc = 0, Partition on Flash Eprom erased successfully.
;    (contains $FF bytes)
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;    
.ErasePtBlocks
                    PUSH AF
                    PUSH BC

                    LD   A,B
                    SRL  A
                    SRL  A
                    AND  @00001111           
                    LD   B,A                 ; B = Top Block Number of Partition
                    
                    SRL  C
                    SRL  C                   ; C = total of 64K blocks to be erased...
.erase_PT_loop
                    LD   A,B
                    CALL FlashEprBlockErase  ; format block B of partition
                    JR   C, erase_PT_loop    ; erase block until completed successfully
                    DEC  B                   ; next (lower) block to erase
                    DEC  C
                    JR   NZ, erase_PT_loop   ; erase all blocks of partition...
          
                    POP  BC
                    POP  AF
                    CP   A                   ; Fc = 0 always...
                    RET


; ************************************************************************
;
; Remove Partitions in Flash Eprom File Area.
; All 64K blocks in the File Area will be erased. All Partitions with 
; file contents will be lost.
;
; IN:
;    -
;
; OUT:
;    Success:
;         Fc = 0, File Area on Flash Eprom erased successfully.
;         (Complete File Area contains $FF bytes)
;
;    Failure:
;         Fc = 1
;         (Blocks could not be formatted or Flash Eprom not available)
;         A = Error code
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;    
.FS_RemovePartitions
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   C,3                      ; check for FE in slot 3...
                    CALL FlashEprCardID
                    JR   C, exit_format           ; Flash Eprom not available.

                    LD   C,3                      ; slot 3...
                    LD   A,FSFLE_SCPT
                    CALL FlashStoreFileEpr        ; get pointer to first partition
                    JR   C, exit_FreePtSp         ; No FlashStore File System (Space) available
                    
                    LD   C,B                      ; B = Top Bank of File Area (or potential)
                    INC  C                        ; C = total of 16K banks to be erased...
                    CALL ErasePtBlocks       
.exit_format
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; ************************************************************************
;
; Get Free Partition Space in File Area, returned in modulus 64K blocks,
; of slot specified in C register.
;
; IN:
;    C = slot number (1, 2 or 3)
;
; OUT:
;    Success:
;         Fc = 0, Free Partition Space in File Area
;         A = Total of Free 64K blocks
;         BHL = (slot relative) pointer to potential Partition Identifier
;
;    Failure:
;         Fc = 1
;         A = Error code
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;    
.FS_FreePartitionSpace
                    PUSH DE
                    PUSH BC

                    LD   E,C                      ; preserve slot number
                    LD   A,FSFLE_SCPT
                    CALL FlashStoreFileEpr
                    JR   C, exit_FreePtSp         ; No FlashStore File System available
                    CALL Z,find_PtFrSp            ; BHL = top partition, scan until bottom...
                    JR   C, exit_FreePtSp         ; all File Space used by partitions...
.calc_free_blocks
                    LD   A,B                      ; B = top bank of free partition file area
                    INC  A                        ; A = free banks of partition file area
                    SRL  A
                    SRL  A                        ; return A/4 = total of free 64K blocks
                    CP   A                        ; Fc = 0
.exit_FreePtSp
                    POP  DE
                    LD   C,E                      ; original C restored
                    POP  DE                       ; original DE restored
                    RET                           ; BHL = pointer ...


; ************************************************************************
;
; Scan all partitions downwards to find free File Space for a new
; partition Identifier.
;
; IN:
;    BHL = (relative) pointer to first Partition ID
;    D = size of current Partition in 16K banks
;    E = Slot number to scan
;
; OUT:
;    A = undefined
;    C = size of card in 16K banks
;    D = undefined
;    H = changed to address available segment in address space
;
;    Success:
;         Fc = 0
;         B = relative bank number of free bank
;
;    Failure:
;         Fc = 1
;         A = RC_ROOM, No Free File Space available
;
; Registers changed after return:
;    .....E.L/IXIY same
;    AFBCD.H./.... different
;
.find_PtFrSp        
                    LD   A,E                      ; BHL = relative pointer to top partition id of slot C
                    CALL MemAbsPtr                ; Convert BHL to absolute pointer for slot C
.get_bottom_pt
                    CALL FlashStore_NextPartitionID
                    JR   Z, get_bottom_pt         ; another partition found, find next (lower)...
                    
                    RES  7,B
                    RES  6,B                      ; B = relative bank of free space (0 - 64)
                    LD   H,$3F                    ; H = standard offset in bank
                    RET                           ; C = size of card in 16K banks
.all_used
                    LD   A, RC_ROOM
                    SCF
                    RET


; ************************************************************************
;
; Create "oz" File Area in Flash Eprom (in slot 3).
;
; When creating an "oz" File Eprom, ALL remaining space is ALWAYS used 
; in File Area (B parameter is ignored).
;
; IN:
;    B = Total of 64K Blocks for FS II partition, or 0 (use remaining void space).
;    DE = ptr. to label, null-terminated string, for partition
;
;    DE = 0, create "oz" File Eprom (use remaining free space of Eprom)
;
; OUT:
;    Success:
;         Fc = 0
;         A = number of allocated blocks for partition/"oz" area
;         BHL = pointer to Partition Identifier/"oz" header (slot relative)
;
;    Failure:
;         Fc = 1
;         A = Error code
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;    
.FS_CreatePartition
                    PUSH DE
                    PUSH BC
                    PUSH IX

                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-33
                    ADD  IX,SP                    ; IX points at start of buffer
                    LD   SP,IX                    ; 32 byte buffer created...
                    PUSH HL                       ; preserve original SP

                    LD   (IX + $20),B             ; size of partition

                    LD   A,D
                    OR   E
                    JR   NZ, cr_fspt              ; create a FS II partition
                         LD   C,3                      ; check for FE in slot 3...
                         CALL FlashEprCardId
                         JR   C, exit_fsthdr           ; Ups - Flash Eprom not available
                         LD   C,3                      ; slot 3...
                         CALL FS_FreePartitionSpace    ; A = returned amount of free 64K blocks
                         JR   C, exit_fsthdr           ; B = bank of "oz" header
                         CALL FlashEprStdFileHeader    ; Create "oz" File Eprom Header
                         JR   C,exit_fsthdr
                         LD   HL,$3FC0                 ; return pointer to "oz" header
                         LD   A,B
                         INC  A                        ; 
                         SRL  A
                         SRL  A                        ; return A = partition size in blocks
                         CP   A
                         JR   exit_fsthdr
.cr_fspt                 
                    PUSH IX
                    POP  HL

                    PUSH HL
                    XOR  A
                    LD   B,32
.reset_loop         LD   (HL),A
                    INC  HL
                    DJNZ reset_loop
                    POP  HL                       ; point at start of buffer
                                        
                    CALL StoreLabel               ; $3FE3: Label (15 characters, 0 padded)
                    EX   DE,HL
                    CALL UpdatePartitionID        ; $3FF2,F8: Date/time of format, counter = 1

                    LD   (IX + $1B),'1'           ; $3FFB: Version of FlashStore Filing System
                    LD   C,3                      ; check for FE in slot 3...
                    CALL FlashEprCardId
                    JR   C, exit_fsthdr           ; Ups - Flash Eprom not available
                    LD   (IX + $1D), A            ; $3FFC: Device Code of Flash Eprom

                    LD   C,3                      ; slot 3...
                    CALL FS_FreePartitionSpace    ; A = returned amount of free 64K blocks
                    JR   C, exit_fsthdr           ; BHL = pointer to new Partition Identifier

                    LD   E,(IX + $20)             ; specified size for new partition
                    CALL DefinePartitionSize
                    JR   C, exit_fsthdr           ; no room for new partion in slot 3
                    LD   (IX + $1C),A             ; size of new partition in 16K banks
                    LD   (IX + $1E),'F'           ; $3FFE: 'FS' (FlashStore)
                    LD   (IX + $1F),'S'

                    SRL  A
                    SRL  A                        ; return A = partition size in blocks

                    PUSH IX                       
                    POP  DE                       ; Blow FlashStore Partition ID
                    CALL WritePartitionID         ; at (DE) to (BHL)...

.exit_fsthdr        EXX
                    POP  HL
                    LD   SP,HL                    ; restore original Stack Pointer
                    EXX

                    POP  IX                       ; original IX restored
                    LD   D,B
                    POP  BC                       ; original C restored
                    LD   B,D                      ; BHL = return parameter
                    POP  DE                       ; original DE restored
                    RET                           ; AF = return parameter




; ************************************************************************
;
; IN:
;    A = Free 64K blocks in File Area (of slot 3)
;    E = specified size in 64K blocks of new Partition (entry argument)
;
; OUT:
;    Success:
;         Fc = 0
;         A = number of banks for new partition
;
;    Failure:
;         Fc = 1
;         Specified partition size (in E) was larger than free space
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
.DefinePartitionSize
                    INC  E
                    DEC  E
                    JR   Z, use_freespace    ; SpecifiedSize = 0, use free space

                         SUB  E              ; FreeSpace - SpecifiedSize
                         JR   C, pt_too_large; specified size too large, exit
                         LD   A,E            ; use specified E * 64K partition size...

.use_freespace      ADD  A,A
                    ADD  A,A                 ; return free space in 16K banks...
                    RET                      ; Fc = 0...
.pt_too_large       LD   A, RC_ROOM
                    RET                      ; return Fc = 1, A = RC_ROOM






; ************************************************************************
;
; Copy Partition ID at (BHL) to local buffer at (DE).
; BHL has been prepared with absolute bank and a safe segment mask.
; The buffer must be available in local address space.
;
; IN:
;    BHL = physical, absolute pointer to Partition ID
;
; OUT:
;    -
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;    
.CopyPartitionId    
                    PUSH BC
                    PUSH DE

                    LD   C,32                ; copy 32 byte Identifier to buffer
                    XOR  A
.copy_ID_loop       PUSH AF
                    CALL MemReadByte
                    LD   (DE),A
                    INC  DE
                    POP  AF
                    INC  A                   ; next byte at Identifier BHL+A
                    DEC  C
                    JR   NZ, copy_ID_loop

                    POP  DE
                    POP  BC
                    RET


; ************************************************************************
;
; Update local copy of Partition ID with new date/time (of format),
; and increment the format counter.
;
; IN:
;    DE = pointer to Partition ID copy in local address space
;
; OUT:
;    -
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;    
.UpdatePartitionID
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   BC,$12
                    EX   DE,HL
                    ADD  HL,BC               ; HL points at date of format
                    
                    EX   DE,HL               ; update date/time stamp of format at (DE)
                    CALL_OZ(Gn_Gmd)          ; $3FF2: current Machine Date
                    CALL_OZ(Gn_Gmt)          ; $3FF5: current Machine Time
                    EX   DE,HL

                    INC  (HL)                ; $3FF8: format counter += 1
                    JR   NC, exit_UpdatePtID
                    INC  HL
                    INC  (HL)
                    JR   NC, exit_UpdatePtID
                    INC  HL
                    INC  (HL)
.exit_UpdatePtID
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; ************************************************************************
;
; Write local copy of Partition ID back to Flash Eprom at (BHL).
;
; IN:
;    DE = pointer to Partition ID copy in local address space
;    BHL = pointer to memory to blow Partition ID on Flash Eprom.
;
; OUT:
;    Fc = ?
;    A = ?
;    (return parameters from FlashEprWriteBlock library routine)
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;    
.WritePartitionID   PUSH BC
                    PUSH HL
                    PUSH IX

                    LD   C, MS_S1            ; use segment 1 to blow bytes
                    LD   IX, 32              ; of size 32 bytes...

                    CALL FlashEprVppOn
                    CALL FlashEprWriteBlock  ; blow header...
                    CALL FlashEprVppOff      ; Fc = ? (returned and checked by caller)

                    POP  IX
                    POP  HL
                    POP  BC
                    RET
