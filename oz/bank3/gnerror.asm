; -----------------------------------------------------------------------------
; Bank 3 @ S3           ROM offset $d667
;
; $Id$
; -----------------------------------------------------------------------------

        Module GNError

        org $d667                               ; 919 bytes

        include "all.def"
        include "sysvar.def"

xdef    GNErr
xdef    GNEsp

 IF 1
defc    PrintStr        =$ef57
defc    GN_ret1a        =$c0c5
defc    PutOsf_HL       =$ef83
 ELSE
xref    PrintStr
xref    GN_ret1a
xref    PutOsf_HL
 ENDIF

;       ----

;       display interactive error box
;
;IN:    A=error code
;OUT:   Fc=1, A=error:
;               RC_SUSP: error not fatal
;               RC_DRAW: error not fatal, windows corrupted
;               RC_QUIT: error fatal
;
;CHG:   AF....../....

.GNErr
        push    ix
        cp      RC_Quit                         ; we don't do anything for
        jp      z, err_x                        ; quit/draw/suspended
        cp      RC_Draw
        jp      z, err_x
        cp      RC_Susp
        jp      z, err_x

        ld      a, SR_SUS
        OZ      OS_Sr                           ; save screen
        push    af                              ; remember result

        ld      a, 2
        ld      bc, 5<<8|10
        OZ      OS_Blp

        ld      hl, ErrWd_txt
        call    PrintStr
        ld      hl, MoveTo0_3_txt               ; !! concat this to above string
        call    PrintStr

        ld      a, (iy+OSFrame_A)               ; get error string
        OZ      GN_Esp
        push    af
        call    PrintStr                        ; and print it
        pop     af
        jr      nz, err_3                       ; non-fatal? handle it

        ld      hl, Fatal_txt
        call    PrintStr
.err_1
        ld      bc, -1                          ; wait infinitely
        ld      a, CL_RIM                       ; raw input
        OZ      OS_Cli
        jr      nc, err_2

        cp      RC_Susp
        jr      z, err_1
        cp      RC_Esc
        scf                                     ; !! unnecessary
        jr      nz, err_1

        ld      a, SC_ACK                       ; !! unnecessary, SC_ACK==RC_Esc
        OZ      OS_Esc
        jr      err_1

.err_2
        ld      a, d                            ; extended key? loop
        or      a
        jr      nz, err_1
        ld      a, e                            ; not 'Q'? loop
        and     $df                             ; upper()
        cp      'Q'
        jr      nz, err_1
        jr      err_7                           ; exit

.err_3
        ld      hl, Nonfatal_txt
        call    PrintStr

;       !! re-use code - have code to accept either 'Q' or ESC

.err_4
        ld      bc, -1                          ; wait infinitely
        ld      a, CL_RIM                       ; raw input
        OZ      OS_Cli
        jr      nc, err_5

        cp      RC_Susp
        jr      z, err_4
        cp      RC_Esc
        scf                                     ; !! unnecessary
        jr      nz, err_4

        ld      a, SC_ACK                       ; !! unnecessary, SC_ACK==RC_Esc
        OZ      OS_Esc
        jr      err_6

.err_5
        ld      a, d
        or      a
        jr      nz, err_4                       ; extended key? loop
        ld      a, e
        cp      ESC                             ; not ESC? loop
        jr      nz, err_4

.err_6
        pop     af
        ld      a, RC_Draw                      ; need redraw
        jr      c, err_x                        ; couldn't save screen, exit

        ld      a, SR_RUS
        OZ      OS_Sr                           ; restore screen
        ld      a, RC_Draw
        jr      c, err_x                        ; couldn't restore screen, exit

        ld      a, RC_Susp                      ; was pre-empted
        jr      err_x

.err_7
        pop     af
        jr      c, err_8                        ; error saving screen? no restore
        ld      a, SR_RUS
        OZ      OS_Sr                           ; restore screen
.err_8
        ld      a, RC_Quit                      ; fatal error, request quit

.err_x
        scf
        pop     ix
        jp      GN_ret1a

.Nonfatal_txt
        defm    1,"3@",$20+0,$20+7
        defm    1,"2C",$FD
        defm    1,"2JC"
        defm    1,"T","PRESS ",1,"R"," ESC ",1,"R"," TO RESUME",1,"T"
        defm    1,"2JN",0

.Fatal_txt
        defm    1,"3@",$20+0,$20+7
        defm    1,"2C",$FD
        defm    1,"2JC"
        defm    1,"T","PRESS ",1,"R"," Q ",1,"R"," TO QUIT - FATAL ERROR",1,"T"
        defm    1,"2JN",0

.MoveTo0_3_txt
        defm    1,"3@",$20+0,$20+3,0

.ErrWd_txt
        defm    1,"6#8",$20+0,$20+0,$20+94,$20+8
        defm    1,"2H8"
        defm    1,"2G+"
        defm    1,"7#8",$20+20,$20+0,$20+45,$20+8,$83
        defm    1,"2C8"
        defm    1,"3@",$20+0,$20+0
        defm    1,"2C",$FD
        defm    1,"2JC"
        defm    1,"T","ERROR",1,"T"
        defm    1,"2JN"
        defm    1,"3@",$20+0,$20+0
        defm    1,"R",1,"U"
        defm    1,"2A",$20+45
        defm    1,"U",1,"R"
        defm    1,"3@",$20+0,$20+3
        defm    1,"2JC",0

;       ----

;       return extended pointer to system error message
;
;IN:    A=error code
;OUT:   BHL=error message, Fz=1 if error is fatal
;
;CHG:   .FB...HL/....

.GNEsp
        ld      hl, Unknown_err
        cp      RC_Quit
        jr      z, esp_1
        call    FindErrStr
        ld      (iy+OSFrame_F), a               ; set flags
.esp_1
        ld      (iy+OSFrame_B), 3               ; string in bank 3 !! 'ld b, 3: call PutOsf_BHL'
        call    PutOsf_HL
        ret

;       ----

;       find error string
;
;IN:    A=error
;OUT:   HL=string, A=flags

.FindErrStr
        ld      c, a                            ; error code to search for
        ld      hl, ErrStr_tbl

.fes_1
        ld      a, (hl)                         ;  get error code
        inc     hl
        or      a
        jr      nz, fes_2                       ; not end? compare

        ld      hl, Unknown_err                 ; else fallback to unknown
        ld      a, Z80F_Z                       ; Fz=1, error is fatal
        ret

.fes_2
        cp      c
        jr      z, fes_3                        ; match? get string
        inc     hl                              ; skip and loop
        inc     hl
        inc     hl
        jr      fes_1

.fes_3
        ld      c, (hl)                         ; flags
        inc     hl
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a                            ; HL=string
        ld      a, c                            ; A=flags
        ret


;       ----

;       !! encode Fz setting to high byte of address

.ErrStr_tbl
        defb    RC_Esc, 0
        defw    Escape_err

        defb    RC_Time,0
        defw    Timeout_err

        defb    RC_Unk,Z80F_Z
        defw    Internal_err

        defb    RC_Bad,Z80F_Z
        defw    Internal_err

        defb    RC_Ms,Z80F_Z
        defw    Internal_err

        defb    RC_Na,Z80F_Z
        defw    NotApplicable_err

        defb    RC_Room,0
        defw    NoRoom_err

        defb    RC_Hand,Z80F_Z
        defw    BadHandle_err

        defb    RC_Eof,0
        defw    EndOfFile_err

        defb    RC_Flf,0
        defw    FilterFull_err

        defb    RC_Ovf,0
        defw    Overflow_err

        defb    RC_Sntx,0
        defw    BadSyntax_err

        defb    RC_Wrap,0
        defw    Wrap_er

        defb    RC_Push,0
        defw    CannotSatReq_err

        defb    RC_Err,Z80F_Z
        defw    Internal_err

        defb    RC_Type,Z80F_Z
        defw    Unexpected_err

        defb    RC_Pre,0
        defw    NoRoom_err

        defb    RC_Onf,0
        defw    FileNF_err

        defb    RC_Rp,0
        defw    ReadProt_err

        defb    RC_Wp,0
        defw    WriteProt_err

        defb    RC_Use,0
        defw    InUse_err

        defb    RC_Dvz,0
        defw    DivByZero_err

        defb    RC_Tbg,0
        defw    NumTooBig_err

        defb    RC_Nvr,0
        defw    NegRoot_Err

        defb    RC_Lgr,0
        defw    LogRange_err

        defb    RC_Acl,0
        defw    Accuracy_Err

        defb    RC_Exr,0
        defw    RxpRange_err

        defb    RC_Bdn,0
        defw    BadNum_err

        defb    RC_Ivf,0
        defw    BadFName_err

        defb    RC_Fail,0
        defw    CannotSatReq_err

        defb    RC_Exis,0
        defw    AlreadyEx_err

        defb    RC_Ftm,0
        defw    Filetype_err

        defb    RC_Susp,0
        defw    Sunpended_err

        defb    RC_Draw,0
        defw    Redraw_Err

        defb    0

.Unknown_err
        defm    "Unknown error",0
.Escape_err
        defm    "Escape",0
.Timeout_err
        defm    "Timeout",0
.NotApplicable_err
        defm    "Not applicable",0
.NoRoom_err
        defm    "No room",0
.BadHandle_err
        defm    "Bad handle",0
.EndOfFile_err
        defm    "End of file",0
.FilterFull_err
        defm    "Filter full",0
.Overflow_err
        defm    "Overflow",0
.BadSyntax_err
        defm    "Bad syntax",0
.Wrap_er
        defm    "Wrap",0
.Internal_err
        defm    "Internal error",0
.Unexpected_err
        defm    "Unexpected type",0
.FileNF_err
        defm    "File not found",0
.ReadProt_err
        defm    "Read protected",0
.WriteProt_err
        defm    "Write protected",0
.InUse_err
        defm    "In use",0
.DivByZero_err
        defm    "Divide by 0",0
.NumTooBig_err
        defm    "Number too big",0
.NegRoot_Err
        defm    "-ve root",0
.LogRange_err
        defm    "Log range",0
.Accuracy_Err
        defm    "Accuracy lost",0
.RxpRange_err
        defm    "Exponent range",0
.BadNum_err
        defm    "Bad number",0
.BadFName_err
        defm    "Bad filename",0
.CannotSatReq_err
        defm    "Cannot satisfy request",0
.AlreadyEx_err
        defm    "Already exists",0
.Filetype_err
        defm    "File type mismatch",0
.Sunpended_err
        defm    "Suspended",0
.Redraw_Err
        defm    "Redraw",0
