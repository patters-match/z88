     XLIB FileEprFreeSpace

     LIB FileEprRequest
     LIB FileEprFileEntryInfo
     LIB ConvPtrToAddr, ConvAddrToPtr

     include "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return free space in Standard File Eprom Area, inserted in slot C
;
; ------------------------------------------------------------------------
;
; $Header$
;
; $History: EprFreSp.asm $
; 
; *****************  Version 3  *****************
; User: Gbs          Date: 16-08-98   Time: 16:03
; Updated in $/Z88/StdLib/FileEprom
; Extended for Sub File Eprom handling.
; 
; *****************  Version 2  *****************
; User: Gbs          Date: 24-01-98   Time: 20:41
; Updated in $/Z88/StdLib/FileEprom
; INCLUDE directives optimized (if any)
; 
; *****************  Version 1  *****************
; User: Gbs          Date: 20-01-98   Time: 8:55
; Created in $/Z88/StdLib/FileEprom
; Added to SourceSafe
;
; ------------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
;
; -----------------------------------------------------------------------
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         DEBC = Free space available
;
;    Fc = 1, File Eprom was not found in slot C
;
; Registers changed after return:
;    ......HL/IXIY same
;    AFBCDE../.... different
;
.FileEprFreeSpace   PUSH HL

                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot
                    JR   C, err_FileEprFreeSpace
                    JR   NZ, err_FileEprFreeSpace ; File Eprom not available in slot...

                    LD   A,B
                    EXX
                    LD   B,A                      ; preserve bank number of header
                    EXX
                    
                    LD   A,E
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    SUB  D                        ; D = total banks of File Eprom Area
                    INC  A
                    LD   B,A                      ; B is now bottom bank of File Eprom
                    LD   HL,$4000                 ; BHL points at first address of File Eprom
                                                  ; (using segment 1 specifier
                    ; scan all file entries, to point at first free byte
.scan_eprom         CALL FileEprFileEntryInfo
                    JR   NC, scan_eprom

                    RES  7,B
                    RES  6,B
                    RES  7,H
                    RES  6,H                      ; strip physical attributes of pointer...

                    EXX
                    LD   HL,$3FC0
                    CALL ConvPtrToAddr            ; get absolute address of ROM header in BHL
                    PUSH DE
                    PUSH BC
                    EXX

                    CALL ConvPtrToAddr            ; BHL (ptr to free space) => DEBC absolute address
                    CP   A
                    POP  HL
                    SBC  HL,BC                    ; <Addr. of ROM Header> - <BHL> = free space
                    LD   B,H
                    LD   C,L
                    POP  HL
                    SBC  HL,DE
                    EX   DE,HL                    ; free space of File Eprom in DEBC
.exit_freespace
                    POP  HL
                    RET
.err_FileEprFreeSpace
                    SCF
                    LD   A, RC_ONF
                    POP  HL
                    RET                 
