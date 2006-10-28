     MODULE FlashEprCopyBlock

; **************************************************************************************************
; OZ Flash Memory Management.
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; $Id$
; ***************************************************************************************************

     XDEF FlashEprCopyBlock

     LIB MemDefBank             ; Bind bank, defined in B, into segment C. Return old bank binding in B
     LIB ApplSegmentMask        ; Get segment mask (MM_Sx) of this executing code)
     LIB SafeSegmentMask        ; Get a 'safe' segment mask outside the current executing code

     XREF FlashEprWriteBlock    ; Write a block of bytes to Flash memory, from DE to BHL of block size IY.

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"
     INCLUDE "error.def"


;***************************************************************************************************
;
; Copy a block of bytes to the Flash Card, from address BHL to CDE of block size IY. If a block
; on the destination will cross a bank boundary, it is automatically continued on the next adjacent
; bank of the card. Block at BHL+IY must be within the bank boundary because source and destination
; pointers are bound into unique segments in the address space temporarily.
;
; BHL points to an absolute bank of the source block.
; CDE points equally to an absolute bank of the destination block (to be written) on the flash memory.
;
; On return, CDE points at the byte after the end of the block, without segment mask.
;
; ---------------------------------------------------------------------------------------------
; The routine is used by the File Area Management libraries, but is well suited for other
; application purposes.
; ---------------------------------------------------------------------------------------------
;
; The routine can be told which programming algorithm to use (by specifying the FE_28F or FE_29F
; mnemonic in A); these parameters can be fetched when investigating which Flash Memory chip is
; available in the slot, using the FlashEprCardId routine that reports these constants.
;
; However, if neither of the constants are provided in A, the routine can be specified with A = 0
; which internally polls the Flash Memory for identification and intelligently use the correct
; programming algorithm. The identified FE_28F or FE_29F constant is returned to the caller in A
; for future reference (when the block was successfully programmed to the card).
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3 to successfully blow data to
; the memory chip. If the Flash Eprom card is inserted in slot 1 or 2, this routine will report a
; programming failure.
;
; It is the responsibility of the application (before using this call) to evaluate the Flash Memory
; (using the FlashEprCardId routine) and warn the user that an INTEL Flash Memory Card requires the
; Z88 slot 3 hardware, so this type of unnecessary error can be avoided.
;
; In :
;         A = FE_28F, FE_29F or 0 (poll card for blowing algorithm)
;         BHL = extended address to start of source (any memory)
;              (bits 7,6 of B is the slot mask)
;         CDE = extended address to start of destination (pointer into flash card)
;              (bits 7,6 of C is the slot mask)
;         IY = size of block (at BHL) to copy (blow) to CDE (must be within bank boundary)
; Out:
;         Success:
;              Fc = 0
;              A = FE_28F or FE_29F (if A(in)=0, depending on found card)
;              BHL, CDE updated to reflect block copy (segment masks stripped from HL, DE offset)
;         Failure:
;              Fc = 1
;              A = RC_BWR (block not blown properly)
;              A = RC_NFE (not a recognized Flash Memory Chip)
;              A = RC_UNK (chip type is unknown: use only FE_28F, FE_29F or 0)
;
; Registers changed on return:
;    ......../IXIY ........ same
;    AFBCDEHL/.... afbcdehl different
;
; ---------------------------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, October 2006
; ---------------------------------------------------------------------------------------------
;
.FlashEprCopyBlock
                    push iy
                    push bc

                    ex   af,af'                        ; preserve FE Programming type in A'
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
                    ex   af,af'                        ; FE Programming type
                    call FlashEprWriteBlock            ; DE now source block in current address space, BHL destination pointer
                    ex   af,af'                        ; preserve error status ...

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
                    jr   z,exit_FlashEprCopyBlock      ; nope (withing 16k offset)
                    inc  b
                    res  6,h                           ; source block copy reached boundary of bank...
.exit_FlashEprCopyBlock                    
                    pop  iy                            ; restored original IY
                    ex   af,af'
                    ret                                ; return A = FE Programming type, or error condition in AF
