     XLIB FileEprCntFiles

     LIB FileEprFileEntryInfo
     LIB FileEprRequest


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; area in application cards (below application banks in first free 64K boundary)
;
; Count total of active and deleted files on File Eprom in slot C
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
;         HL = total of active (visible) files
;         DE = total of (marked as) deleted files
;         (HL + DE would total files on the card)
;
;    Fc = 1, File Eprom was not found at slot C
;
; Registers changed after return:
;    ..BC..../IXIY same
;    AF..DEHL/.... different
;
.FileEprCntFiles    PUSH BC

                    LD   E,C                      ; preserve slot number
                    CALL FileEprRequest           ; check for presence of "oz" File Eprom in slot C
                    JR   C, err_count_files       
                    JR   NZ, err_count_files      ; File Eprom not available in slot...

                    LD   A,E
                    AND  @00000011                ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                          ; converted to Slot mask $40, $80 or $C0
                    OR   B
                    SUB  D                        ; D = total banks of File Eprom Area
                    INC  A
                    LD   B,A                      ; B is now bottom bank of File Eprom
                    LD   HL,$4000                 ; BHL points at first File Entry...

                    EXX
                    LD   DE,0                     ; reset "deleted" files counter
                    LD   H,D
                    LD   L,E                      ; reset active files counter
                    EXX

                    ; scan all file entries, and count
.scan_eprom         CALL FileEprFileEntryInfo
                    JR   C, finished              ; No File Entry was available in File Eprom
                    EXX
                    CALL Z,DeletedFile
                    CALL NZ, ActiveFile
                    EXX
                    JR   scan_eprom
.err_count_files    
                    SCF
                    JR   exit_count_files
.finished           
                    CP   A                        ; Fc = 0, File Eprom parsed.
.exit_count_files   
                    EXX
                    POP  BC
                    RET

.DeletedFile        INC  DE
                    RET
.ActiveFile         INC  HL
                    RET
