     XLIB FileEprFileName

     LIB FileEprRequest
     LIB FileEprFileEntryInfo
     LIB PointerNextByte
     LIB MemReadByte
     LIB FileEprReadByte

     INCLUDE "error.def"
     INCLUDE "memory.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Return file name of File Entry at BHL, slot C
; (B=00h-3Fh, HL=0000h-3FFFh)
;
; ------------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; ------------------------------------------------------------------------
;
; IN:
;    C = slot number containing File Eprom
;    DE = buffer to hold returned filename
;    BHL = pointer to Eprom File Entry
;
; OUT:
;    Fc = 0, File Eprom available
;         Fz = 1, File Entry marked as deleted
;         Fz = 0, File Entry marked as active
;         A = length of filename
;         (DE) contains a copy of filename, null-terminated.
;
;    Fc = 1,
;         A = RC_Onf
;         File Eprom was not found in slot C, or File Entry not available
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF...../.... different
;
.FileEprFileName    PUSH DE
                    PUSH HL
                    PUSH BC                       ; preserve pointer

                    LD   A,C
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    LD   B,A                      ; bank in slot C...
                    RES  7,H
                    SET  6,H                      ; (offset bound into segment 1 temporarily)

                    PUSH BC
                    PUSH DE                       ; preserve "to" pointer
                    PUSH HL                       ; preserve pointer to File Entry
                    CALL FileEprFileEntryInfo
                    POP  HL
                    POP  DE
                    POP  BC
                    JR   C, no_entry              ; No files are present on File Eprom...

                    CALL FetchFilename            ; copy filename into local buffer, null-terminated

                    POP  BC
                    POP  HL                       ; original pointer restored
                    POP  DE                       ; original buffer pointer restored
                    RET

.no_entry           LD   A, RC_Onf
                    POP  BC
                    POP  HL                       ; original pointer restored
                    POP  DE                       ; original buffer pointer restored
                    RET


; ************************************************************************
;
; Fetch filename at BHL, length C characters.
;
; IN:
;    A = length of filename
;    DE = buffer to hold returned filename
;    BHL = pointer to length byte of filename (start of File Entry)
;
; OUT:
;    Fc = 0, always.
;    (DE) contains a copy of filename, null-terminated, DE points at null.
;    BHL points at byte beyond filename (start of file length 32bit integer)
;    First char of filename always set to "/" (due to deleted filenames)
;
; Registers changed after return:
;    AF....../IXIY same
;    ..BCDEHL/.... different
;
.FetchFilename      PUSH AF

                    LD   C,A
                    LD   A,'/'
                    LD   (DE),A                   ; first character always "/"
                    INC  DE
                    DEC  C
                    CALL PointerNextByte          ; point at start of filename (of C length)
                    CALL PointerNextByte          ; point at first real character of filename

.flnm_loop          CALL FileEprReadByte          ; BHL++
                    LD   (DE),A
                    INC  DE                       ; bufptr++
                    DEC  C                        ; flnmlength--
                    JR   NZ,flnm_loop
                    XOR  A
                    LD   (DE),A                   ; null-terminate filename

                    POP  AF
                    RET

; ************************************************************************
;
.CheckFileEprom
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot C
                    JR   Z,exit_fileepr           ; found...
                    SCF                           ; not found
.exit_fileepr
                    POP  HL
                    POP  DE
                    POP  BC
                    RET
