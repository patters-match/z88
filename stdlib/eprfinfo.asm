     XLIB FileEprFileEntryInfo

     LIB MemReadByte
     LIB FileEprReadByte
     LIB PointerNextByte
     LIB AddPointerDistance


; ****************************************************************************
;
; Standard Z88 File Eprom Format.
;
; Read File Entry information, if available.
;
; NB:     This routine might be used by applications, but is primarily called by
;         <FileEprCntFiles>, <FileEprFreeSpace>, <FileEprFirstFile>.
;
; --------------------------------------------------------------------------
;
; $Header$
;
; $History: EprFinfo.asm $
; 
; *****************  Version 3  *****************
; User: Gbs          Date: 28-02-99   Time: 12:22
; Updated in $/Z88/StdLib/FileEprom
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
; --------------------------------------------------------------------------
;
; Design & programming by Gunther Strube, InterLogic, Dec 1997
;
; --------------------------------------------------------------------------
;
; IN:
;    BHL = pointer to start of file entry
;         The Bank specifier contains the slot mask, ie. defines which slot
;         is being read.
;         The offset must be used with a segment specifier MM_Sx in H register
;         (which segment will be used for bank implicit bank binding).
;
;
; OUT:
;    Fc = 0, File Entry available
;         Fz = 1, deleted file
;         Fz = 0, active file
;         A = length of filename
;         BHL = pointer to next File Entry (or free space)
;         CDE = length of file
;
;    Fc = 1, File Entry not available ($FF was first byte of entry)
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FileEprFileEntryInfo
                    XOR  A
                    CALL MemReadByte              ; Read first byte of File Entry
                    CP   $FF
                    JR   Z, exit_eprfile          ; previous File Entry was last in File Eprom
                    CP   $00
                    JR   Z, exit_eprfile          ; pointing at start of ROM header!
                    CALL PointerNextByte
                    LD   C,A                      ; preserve length of string
                    XOR  A
                    CALL MemReadByte              ; get first char of filename
                    OR   A                        ; Fc = 0, Fz = 1, if file marked as "deleted" (0)
                    LD   A,C                      ; Fz = 0, if '/' character...
                    PUSH AF                       ; preserve length of filename, status

                    LD   C,0
                    LD   D,C
                    LD   E,A
                    CALL AddPointerDistance       ; skip filename, point at length of file...

                    CALL FileEprReadByte
                    LD   E,A
                    CALL FileEprReadByte
                    LD   D,A
                    call FileEprReadByte
                    LD   C,A                      ; CDE is length of file
                    CALL PointerNextByte          ; point at beginning of file image
                    CALL AddPointerDistance       ; BHL points at next File Entry (or none)

                    POP  AF
                    RET                           ; return length of filename, deleted status

.exit_eprfile       SCF
                    RET
