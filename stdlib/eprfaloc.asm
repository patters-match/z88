     XLIB FileEprAllocFilePtr

     LIB FileEprRequest
     LIB FileEprFileEntryInfo
     LIB ConvPtrToAddr, ConvAddrToPtr



; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return pointer to free space in File Eprom Area, inserted in slot C.
; (B=00h-3Fh, HL=0000h-3FFFh)
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
; IN:
;    C = slot number containing File Eprom Area
;
; OUT:
;    Fc = 0, File Eprom available
;         BHL = pointer to first byte of free space
;
;    Fc = 1, File Eprom was not found in slot C
;
; Registers changed after return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
.FileEprAllocFilePtr
                    PUSH BC
                    PUSH DE
                    
                    LD   E,C                           ; preserve slot number
                    CALL FileEprRequest                ; check for presence of "oz" File Eprom in slot
                    JR   C,err_FileEprAllocFilePtr
                    JR   NZ,err_FileEprAllocFilePtr    ; File Eprom not available in slot...
                    
                    LD   A,E
                    AND  @00000011                     ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                               ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    SUB  D                             ; D = total banks of File Eprom Area
                    INC  A
                    LD   B,A                           ; B is now bottom bank of File Eprom
                    LD   HL,$4000                      ; BHL points at first File Entry...
.scan_eprom
                    CALL FileEprFileEntryInfo          ; scan all file entries, to point at first free byte
                    JR   NC, scan_eprom
                    JR   exit_FileEprAllocFilePtr
.err_FileEprAllocFilePtr
                    SCF
.exit_FileEprAllocFilePtr
                    POP  DE
                    LD   A,B
                    POP  BC
                    LD   B,A                           ; BHL points at first free byte...

                    RES  7,B
                    RES  6,B
                    RES  7,H
                    RES  6,H                           ; strip physical attributes of pointer...
                    RET
