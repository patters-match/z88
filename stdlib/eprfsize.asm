     XLIB FileEprFileSize

     LIB FileEprFileEntryInfo

     INCLUDE "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return file size of File Entry at pointer BHL, slot C
; (B=00h-3Fh, HL=0000h-3FFFh)
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
; IN:
;    C = slot number containing File Eprom
;    BHL = Pointer to File Entry (slot relative)
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry active
;              CDE = size of file (24bit integer, C = high byte)
;
;    Fc = 1, 
;         A = RC_ONF
;         File Eprom was not found in slot C, or File Entry not available
;
; Registers changed after return:
;    A.B...HL/IXIY same
;    .F.CDE../.... different
;
.FileEprFileSize    PUSH HL
                    PUSH AF
                    PUSH BC                       ; preserve pointer

                    LD   A,C
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    LD   B,A                      ; absolute bank of File Entry in slot C...
                    RES  7,H
                    SET  6,H                      ; (offset set to segment 1 temporarily)

                    CALL FileEprFileEntryInfo     ; filename size in A, file status (Fz)

                    POP  HL                       ; length of file in CDE
                    LD   B,H
                    POP  HL
                    LD   A,H                      ; original A restored
                    POP  HL                       ; original pointer restored
                    RET                           ; filestatus (Fz) and error status (Fc)
.err_fileepr
                    SCF
                    LD   A, RC_ONF
                    POP  BC                       ; original BC restored
                    POP  HL                       ; ignore old AF
                    POP  HL                       ; original HL restored
                    RET
