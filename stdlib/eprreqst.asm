     XLIB FileEprRequest

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     LIB ApplEprType
     LIB SafeSegmentMask
     LIB MemReadByte
     LIB FlashEprCardId

     include "error.def"
     include "memory.def"


; ************************************************************************
;
; Check for "oz" File Eprom (on a conventional Eprom or on a 1mb Flash Eprom)
;
;    1) Check for a standard "oz" File Eprom, if that fails -
;    2) Check that slot contains an Application ROM, then check for the 
;       Header Identifier in the first top block below reserved 
;       application banks on the card.
;    3) If a Rom Front Dor is located in a RAM Card, then this slot
;       is regarded as a non-valid card as a File Eprom, ie. not present.
;
;    On partial success, if a Header is not found, the returned pointer 
;    indicates that the card might hold a file area, beginning at this location.
;
;    If the routine returns HL = @3FC0, it's an "oz" File Eprom Header 
;    (64 byte header)
;
; In:
;         C = slot number (1, 2 or 3)
;
; Out:
;    Success, File Area (or potential) available:
;         Fc = 0,
;
;              BHL = pointer to File Header for slot C (B = slot relative).
;                    (or pointer to free space in File Area).
;              Fz = 1, File Header found
;                   A = "oz" File Eprom sub type
;                   C = size of card in 16K banks (0 - 64)
;                   D = size of partition in 16K banks
;              Fz = 0, File Header not found
;                   A undefined
;                   C undefined
;                   D undefined
;    Failure:
;         Fc = 1,
;              RC_ONF:
;                   FlashStore File Area not available (possibly no ROM card)
;                   nor any std. File Eprom "oz" header.
;              RC_ROOM, No room for File Area (all banks used for applications)
;
; Registers changed after return:
;    .....E../IXIY same
;    AFBCD.HL/.... different
;
; ---------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, 
; Dec 1997 - Aug 1998, July-Aug 2004
;----------------------------------------------------------------
; 
.FileEprRequest
                    PUSH DE

                    LD   B,$3F
                    CALL CheckFileEprHeader  ; check for standard "oz" File Eprom in top bank of slot C...
                    JR   C, eval_applrom
                         POP  DE
                         LD   C,B            ; return C = number of 16K banks of card
                         LD   D,B            ; return D = size of partition (= size of card)
                         LD   B,$3F
                         LD   HL, $3FC0      ; pointer to "oz" header at top of card...
                         CP   A              ; indicate "Header found" (Fz = 1)
                         RET
.eval_applrom
                    LD   D,C                 ; copy of slot number
                    CALL ApplEprType
                    JR   C,no_appldor        ; Application ROM Header not present...
                    CP   $82                 ; Front Dor located in RAM Card?
                    JR   Z,no_fstepr         ; Yes - indicate Card Not Available...
                    
                    LD   E,C                 ; preserve size of card            
                    CALL DefHeaderPosition   ; locate and validate File Eprom Header
                    JR   C, no_filespace     ; whole card used for Applications...
                    LD   H,D                 
                    LD   C,E                 ; C = size of card in 16K banks
                    POP  DE
                    LD   D,H                 ; D = size of Partition in 16K banks
                    RES  7,B
                    RES  6,B
                    LD   H,$3F               ; BHL = ptr. to File Header, B $3Fxx
                    RET                      ; Fc = 0, Fz = ?
.no_filespace
                    POP  DE
                    SCF
                    LD   A,RC_ROOM
                    RET
.no_fstepr                                   ; the slot cannot hold a File Area.
                    POP  DE
                    SCF
                    LD   A,RC_ONF
                    RET
.no_appldor                                  ; the slot is empty, but might
                    POP  DE
                    LD   B,$3F
                    LD   HL,$3FC0
                    OR   B                   ; Fc = 0, Fz = 0, indicate no header found
                    RET                      ; but potential "oz" File Eprom header.
                                        


; ************************************************************************
;
; Define the position of the Header, starting from top bank 
; of free card space area, calculated by number of reserved banks for 
; application usage, then using the top bank of the first free 64K block
; below the last used 64K block containg application code.
;
; If no space is left for a file area (all banks used for applications),
; then Fc = 1 is returned.
;
; IN:
;         B = number of banks reserved (used) for ROM applications
;         D = slot number
; OUT:
;         Fc = 0 (success),
;              Fz = 1, Header found
;                   A = sub type of File Eprom
;                   C = size of Card in 16K banks (defined by Device Code)
;                   D = size of File Eprom Area in 16K banks
;              Fz = 0, Header not found
;                   A undefined
;                   C undefined
;                   D undefined
;              BHL = pointer to "oz" header (or potential)
;         Fc = 1 (failure),
;              No room for File Eprom Area.
;
; Registers changed after return:
;    .....E../IXIY same
;    AFBCD.HL/.... different
;
.DefHeaderPosition
                    LD   A,$3F
                    SUB  B                   ; $3F - <ROM banks>
                    INC  A                   ; A = lowest bank of ROM area

                    CP   3                   ;
                    JR   Z, hdr_not_found    ; Application card uses banks 
                    RET  C                   ; in lowest 64K block of card...

                    AND  @11111100
                    DEC  A                   ; A = Top Bank of File Area (in isolated 64K block)

                    LD   B,A
                    LD   C,D
                    LD   D,B                 ; preserve bank number of pointer
                    CALL CheckFileEprHeader
                    RET  C                   ; "oz" File Eprom Header not found
                    LD   C,B
                    LD   B,D
                    LD   D,C                 ; D = The size of banks in "oz" File Eprom Area
                    LD   HL,$3FC0            ; BHL = pointer to "oz" File Eprom Header
                    CP   A                   ; return flag status = found!
                    RET
.hdr_not_found
                    SCF
                    RET
                    

; ************************************************************************
;
; Return File Eprom Area status in slot x (1, 2 or 3), 
; with top of area at bank B (00h - 3Fh).
;
; In:
;         C = slot number (1, 2 or 3)
;         B = bank of "oz" header (slot relative, 00 - $3F)
;
; Out:
;    Success:
;         Fc = 0,
;              File Eprom found
;              A = Sub type of Eprom
;         B = size of File Eprom Area in 16K banks
;
;    Failure:
;         Fc = 1, RC_ONF, "oz" File Eprom not found
;
; Registers changed after return:
;    ...CDEHL/IXIY same
;    AFB...../.... different
;
.CheckFileEprHeader
                    PUSH DE
                    PUSH HL
                    PUSH BC

                    LD   A,C
                    AND  @00000011           ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    OR   B                   
                    LD   B,A                 ; bank B of slot C...

                    CALL SafeSegmentMask     ; Get a safe segment address mask
                    OR   $3F                 ; address $3Fxx in bank B
                    LD   H,A
                    LD   L,0                 ; address $3F00 in bank B of slot C

                    LD   A,$FC
                    CALL MemReadByte
                    PUSH AF                  ; get size of File Eprom in Banks, $3FFC
                    LD   A,$FD
                    CALL MemReadByte
                    LD   C,A                 ; get sub type of File Eprom
                    LD   A,$FE
                    CALL MemReadByte
                    LD   D,A                 ; 'o'
                    LD   A,$FF
                    CALL MemReadByte
                    LD   E,A                 ; 'z'

                    CP   A
                    LD   HL,$6F7A
                    SBC  HL,DE               ; 'oz' ?
                    JR   NZ,no_fileeprom

                    LD   E,B
                    LD   A,C                 ; File Eprom found, sub type in A...
                    POP  BC                  ; B = size of Eprom Card in banks
                    CP   A                    
.exit_FlashEprType
                    POP  HL                  ; B = size of Card in banks
                    LD   C,L                 ; original C restored
                    POP  HL                  ; original HL restored
                    POP  DE                  ; original DE restored
                    RET

.no_fileeprom       POP  AF
                    LD   A,RC_ONF
                    SCF
                    POP BC
                    POP HL
                    POP DE
                    RET
