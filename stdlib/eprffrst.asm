     XLIB FileEprFirstFile

     LIB FileEprRequest
     LIB FileEprFileEntryInfo

     INCLUDE "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return first file entry pointer on Standard File Eprom, inserted in slot C
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
; IN:
;    C = slot number containing File Eprom
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry is active.
;         BHL = pointer to first file entry (B=00h-3Fh, HL=0000h-3FFFh).
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot C, or File Entry not available
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
.FileEprFirstFile   PUSH DE
                    PUSH AF
                    PUSH BC                       ; preserve CDE

                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot C
                    JR   C,no_entry
                    JR   NZ,no_entry              ; File Eprom not available in slot...

                    LD   A,E
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    SUB  D                        ; D = total banks of File Eprom Area
                    INC  A
                    LD   B,A                      ; B is now bottom bank of File Eprom
                    LD   HL,$4000                 ; BHL points at first File Entry...
                    PUSH BC                       ; (using segment 1 specifier)
                    CALL FileEprFileEntryInfo
                    POP  BC
                    JR   C, no_entry              ; Ups - no File Entry found...
                    PUSH AF
                    RES  7,B
                    RES  6,B
                    LD   HL,0
                    POP  AF

                    POP  DE                       ; BHL = pointer to first File Entry
                    LD   C,E                      ; original C restored
                    POP  DE
                    LD   A,D                      ; original A restored
                    POP  DE
                    RET                           ; Fz = 1, File Entry marked as deleted...

.no_entry           SCF
                    LD   A, RC_Onf                ; "Object not found"
                    POP  DE
                    LD   C,E                      ; original C register restored
                    POP  DE                       ; ignore original AF...
                    POP  DE
                    RET
