     XLIB FileEprRandomID

     LIB SafeSegmentMask
     LIB MemReadLong
     LIB FileEprRequest

     include "error.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format, including support for sub File Eprom
; Area in application cards (below application banks in first free 64K boundary)
;
; Return File Eprom "oz" Header Random ID from slot x (1, 2 or 3)
;
; -----------------------------------------------------------------------
; Design & programming by Gunther Strube, InterLogic, Dec 1997 - Aug 1998
; -----------------------------------------------------------------------
;
; In:
;    C = slot number (1, 2 or 3)
;
; Out:
;    Success:
;         Fc = 0,
;              DEBC = Random ID (32bit integer)
;
;    Failure:
;         Fc = 1,
;         A = RC_ONF, File Eprom not found
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FileEprRandomID
                    LD   E,C                 ; preserve slot number
                    CALL FileEprRequest      ; check for presence of "oz" File Eprom in slot
                    JR   C, err_nofileepr
                    JR   NZ, err_nofileepr   ; File Eprom not available in slot...

                    LD   A,E
                    AND  @00000011           ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    OR   B                   ; absolute bank number of "oz" header...

                    CALL SafeSegmentMask     ; Get a safe segment address mask
                    OR   $3F
                    LD   H,A
                    LD   L,0                 ; address $3Foo in top bank of slot B

                    LD   A,$F8               ; offset $F8, position of Random ID
                    CALL MemReadLong
                    EXX                      ; return Random ID in DEBC...
                    CP   A                   ; Fc = 0...
                    RET
.err_nofileepr
                    SCF
                    LD   A,RC_ONF
                    RET
