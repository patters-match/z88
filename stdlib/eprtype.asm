     XLIB FileEprType

     LIB FileEprRequest
     
     include "error.def"
     include "memory.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return pointer to Standard File Eprom "oz" header in slot x (1, 2 or 3).
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
; In:
;    C = slot number (1, 2 or 3)
;
; Out:
;    Success:
;         Fc = 0,
;              A = Sub type of Eprom.
;                   Standard 32K, 128K, 256K Eprom (or 1MB Flash Eprom)
;              BHL = Pointer to "oz" header in slot.
;              C = size of File Eprom in total of banks.
;
;    Failure:
;         Fc = 1,
;              A = RC_ONF, File Eprom not found
;
; Registers changed after return:
;    ....DE../IXIY same
;    AFBC..HL/.... different
;
.FileEprType
                    PUSH DE

                    CALL FileEprRequest      ; check for presence of "oz" File Eprom in slot C
                    LD   E,A                 ; preserve sub-type for a moment...
                    JR   C,err_fileepr
                    JR   NZ,err_fileepr      ; File Eprom not available in slot...

                    LD   C,D                 ; return size of File Eprom Area in 16K banks
                    LD   A,E
                    CP   A                   ; A = sub type of File Eprom, Fc = 0

                    POP  DE                  ; original DE restored
                    RET

.err_fileepr        POP  DE
                    LD   A,RC_ONF
                    SCF
                    RET
