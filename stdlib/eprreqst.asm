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
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     LIB ApplEprType, MemReadByte

     include "error.def"
     include "memory.def"


; ************************************************************************
;
; Check for "oz" File Eprom (on a conventional Eprom or on a Flash Memory)
;
;    1) Check for a standard "oz" File Eprom, if that fails -
;    2) Check if that slot contains an Application ROM, then check for the 
;       Header Identifier in the first top block below reserved 
;       application banks on the card.
;    3) If a Rom Front Dor is located in a RAM Card, then this slot
;       is regarded as a non-valid card as a File Eprom, ie. not present.
;
;    On partial success, if a Header is not found, the returned pointer 
;    indicates that the card might hold a file area, beginning at this location.
;
;    If the routine returns HL = $3FC0, it's an "oz" File Eprom Header 
;    (pointing to 64 byte header)
;
; In:
;         C = slot number (1, 2 or 3)
;
; Out:
;    Success, File Area (or potential) available:
;         Fc = 0,
;              BHL = pointer to File Header for slot C (B = absolute bank of slot).
;                    (or pointer to free space in File Area).
;              Fz = 1, File Header found
;                   A = "oz" File Eprom sub type
;                   C = size of File Eprom Area in 16K banks
;                   D = size of card in 16K banks (0 - 64)
;              Fz = 0, File Header not found
;                   A undefined
;                   C undefined
;                   D undefined
;    Failure:
;         Fc = 1,
;              A = RC_ONF (File Eprom Card/Area not available; possibly no card in slot)
;              A = RC_ROOM (No room for File Area; all banks used for applications)
;
; Registers changed after return:
;    .....E../IXIY same
;    AFBCD.HL/.... different
;
; ---------------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Aug 1998, July-Sept 2004
;----------------------------------------------------------------------------
; 
.FileEprRequest
                    PUSH DE

                    LD   B,$3F
                    CALL CheckFileEprHeader  ; check for standard "oz" File Eprom in top bank of slot C...
                    JR   C, eval_applrom
                         POP  DE             ; found "oz" header at top of card...
                         LD   D,C            ; return C = D = number of 16K banks of card
                         LD   HL, $3FC0      ; offset pointer to "oz" header at top of card...
                         CP   A              ; indicate "Header found" (Fz = 1)
                         RET
.eval_applrom
                    LD   D,C                 ; copy of slot number
                    CALL ApplEprType
                    JR   C,no_appldor        ; Application ROM Header not present...
                    CP   $82                 ; Front Dor located in RAM Card?
                    JR   Z,no_fstepr         ; Yes - indicate Card Not Available...
                                             ; B = app card banks, C = total size of card in banks
                    LD   E,C                 ; preserve card size in E
                    LD   C,D                 ; C = slot number
                    CALL DefHeaderPosition   ; locate and validate File Eprom Header
                    JR   C, no_filespace     ; whole card used for Applications...
                    POP  HL                  ; old DE
                    LD   D,E                 ; C = size of file area in 16K banks, D = size of card in 16K banks
                    LD   E,L                 ; restore original E
                    LD   HL,$3FC0            ; BHL = absolute pointer to "oz" File Header below applications in slot
                    RET                      ; A = File Eprom sub type, Fc = 0, Fz = indicated by DefHeaderPosition
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
.no_appldor                                  ; the slot is empty, but might be used for File Eprom
                    LD   A,D
                    AND  @00000011           ; only slots 0, 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    OR   $3F                 ; Fc = 0, Fz = 0, indicate no header found
                    LD   B,A
                    LD   C,$FF               ; size of card unknown
                    LD   HL,$3FC0            ; absolute pointer to potential File Eprom Card
                    POP  DE
                    RET
                                        


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
;         C = slot number
; OUT:
;         Fc = 0 (success),
;              Fz = 1, Header found
;                   A = sub type of File Eprom
;                   C = size of File Eprom Area in 16K banks
;              Fz = 0, Header not found
;                   A undefined
;                   C undefined
;                   D undefined
;              BHL = pointer to "oz" header (or potential)
;         Fc = 1 (failure),
;              A = RC_ROOM (No room for File Eprom Area)
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
                    JR   Z, appcard_no_room  ; Application card uses banks 
                    RET  C                   ; in lowest 64K block of card...

                    AND  @11111100
                    DEC  A                   ; A = Top Bank of File Area (in isolated 64K block)
                    LD   B,A                 ; B = bank number of "oz" header (or potential), C = slot number                                             
                    CALL CheckFileEprHeader
                    JR   C, new_filearea     ; "oz" File Eprom Header not found, but potential area...                                             
                    CP   A                   ; B = bank of "oz" Header, C = banks in "oz" File Eprom Area
                    RET                      ; return flag status = found!
.new_filearea       
                    OR   B                   ; Fc = 0, Fz = 0, indicate potential file area
                    RET
.appcard_no_room
                    LD   A,RC_ROOM
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
;         B = absolute bank (embedded slot mask) of File Eprom Header
;         C = size of File Eprom Area in 16K banks
;
;    Failure:
;         Fc = 1, 
;         A = RC_ONF ("oz" File Eprom not found)
;         C = slot number (1, 2 or 3)
;         B = bank of "oz" header (slot relative, 00 - $3F)
;
; Registers changed after return:
;    ....DEHL/IXIY same
;    AFBC..../.... different
;
.CheckFileEprHeader
                    PUSH DE
                    PUSH BC
                    PUSH HL

                    LD   A,C
                    AND  @00000011           ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    OR   B                   
                    LD   B,A                 ; bank B of slot C...
                    LD   HL, $3F00

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
                    LD   A,C                 ; A = sub type of File Eprom
                    CP   A                   ; return Fc = 0
                    POP  DE                  ; B = absolute bank no of hdr, 
                    LD   C,D                 ; C = size of Eprom Card in banks

                    POP  HL                  ; original HL restored
                    POP  DE                  ; ignore old BC -> new values are returned...
                    POP  DE                  ; original DE restored
                    RET

.no_fileeprom       POP  AF                  ; ignore "size" (just random junk)
                    LD   A,RC_ONF
                    SCF
                    POP HL
                    POP BC            
                    POP DE                   ; original BC, DE & HL restored
                    RET
