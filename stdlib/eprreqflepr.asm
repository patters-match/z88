     XLIB FileEprRequest

     LIB ApplEprType
     LIB FlashEprType

     include "flashepr.def"
     include "error.def"
     include "memory.def"


; ************************************************************************
;
; Check for "oz" File Eprom (on a conventional Eprom or on a 1mb Flash Eprom)
;
; ---------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, 
; Dec 1997 - Aug 1998, July 2004
;----------------------------------------------------------------
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
;    Success, first (top) partition (or potential) available:
;         Fc = 0,
;
;              BHL = pointer to top Partition ID for slot C (B = slot relative).
;                    (or pointer to free space in File Area).
;              Fz = 1, File Header found
;                   A = Device Code of Flash Eprom (or "oz" File Eprom sub type)
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
.FileEprRequest
                    PUSH DE

                    LD   B,$3F
                    CALL FlashEprType        ; check for standard "oz" File Eprom in slot C...
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
;              Fz = 1, Top Header found
;                   A = Intel Chip Device Code
;                   C = size of Card in 16K banks (defined by Device Code)
;                   D = size of Partition in 16K banks
;              Fz = 0, Header not found
;                   A undefined
;                   C undefined
;                   D undefined
;              BHL = pointer to "oz" header (or potential)
;         Fc = 1 (failure),
;              No room for File Area.
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
                    CALL FlashEprType
                    RET  C                   ; "oz" File Eprom Header not found
                    LD   C,B
                    LD   B,D
                    LD   D,C                 ; D = The size of banks in "oz" File Eprom Area
                    LD   HL,$3FC0            ; BHL = pointer to "oz" File Eprom Header
                    CP   A                   ; return flag status = found!
                    RET
