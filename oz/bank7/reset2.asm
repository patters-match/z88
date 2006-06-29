; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1d5a5
;
; $Id$
; -----------------------------------------------------------------------------

        Module Reset2

        include "blink.def"
        include "memory.def"
        include "screen.def"
        include "sysvar.def"

xdef    Reset2

xref    InitBufKBD_RX_TX                        ; bank0/buffer.asm
xref    KPrint                                  ; bank0/misc5.asm
xref    Reset3                                  ; bank0/reset13.asm
xref    ResetHandles                            ; bank0/handle.asm
xref    ResetTimeout                            ; bank0/nmi.asm

xref    InitData                                ; bank7/initdata.asm
xref    LowRAMcode                              ; bank7/lowram0.asm
xref    LowRAMcode_e                            ; bank7/lowram0.asm

;       ----

.Reset2
	xor     a
        ex      af, af'                         ; interrupt status
        bit     BB_STAFLAPOPEN, a
        ld      a, $21
        jr      nz, b20_hard_reset              ; flap? hard reset

        out     (BL_SR1), a                     ; b21 into S1
        ld      hl, ($4000)
        ld      bc, $A55A        	            ; RAM tag
        or      a
        sbc     hl, bc
        jr      nz, b20_hard_reset              ; not tagged? hard reset

        ex      af, af'                         ; soft reset - a' = $FF, fc'=1
        cpl
        scf
        ex      af, af'

        dec     a                               ; only clear b20
        ld      bc, $3DFF			            ; from 0200-3FFF
        ld      de, $4201			            ; 0000-01DF is overwritten by lowram.bin
        ld      hl, $4200			            ; 01E0-01FF is preserved area
        jr      b20_reset
.b20_hard_reset
        ld      bc, $3FFF                       ; fill bank with 00
        ld      de, $4001
        ld      hl, $4000
.b20_reset
        out     (BL_SR1), a                     ; bind A into S1
        ld      (hl), 0
        ldir
        dec     a
        cp      $20
        jr      z, b20_hard_reset               ; loop if hard reset

        ex      af, af'
        ld      ($4000+ubResetType), a
        
;       init BLINK

        ld      hl, InitData
.rst2_2
        ld      c, (hl)                         ; port
        inc     hl
        inc     c
        dec     c
        jr      z, rst2_3                       ; end of init data
        ld      a, (hl)                         ; data byte
        inc     hl
        ld      b, 0
        out     (c), a                          ; write blink
        ld      b, $40+BLSC_PAGE                ; softcopy in S1
        ld      (bc), a
        jr      rst2_2

;       copy low RAM code

.rst2_3
        ld      bc, #LowRAMcode_e-LowRAMcode
        ld      de, $4000                       ; destination b20 in S1
        ldir
        ld      a, 1
        ld      ($4000+ubAppCallLevel), a
        ld      a, BM_COMRAMS|BM_COMLCDON
        ld      ($4000+BLSC_COM), a
        out     (BL_COM), a
        ld      sp, $2000                       ; init stack
        ld      b, NUMHANDLES                   ; !! move this ld into ResetHandles
        call    ResetHandles

;       init screen file for unexpanded machine

        ld      b, $21
        ld      h, $22
        ld      a, 1
        OZ      OS_Sci                          ; LORES0 at 21:2200-22FF
        ld      b, 7
        ld      h, 0
        inc     a
        OZ      OS_Sci                          ; LORES1 at 07:0000-07FF
        ld      b, $21
        ld      h, $20
        inc     a
        OZ      OS_Sci                          ; HIRES0 at 21:2200-23FF
        ld      b, 7
        ld      h, 8
        inc     a
        OZ      OS_Sci                          ; HIRES1 at 07:0800-0FFF
        ld      b, $20
        ld      h, SBF_PAGE
        inc     a
        OZ      OS_Sci                          ; SBF at 20:7800-7FFF - this inits memory

        call    ResetTimeout
        call    InitBufKBD_RX_TX

        ld      a, (ubResetType)                ; print reset string
        or      a
        jr      nz, rst2_4

        call    KPrint
        defm    1,"B"
        defm    "HARD",0
        jr      rst2_5

.rst2_4
        call    KPrint
        defm    1,"T"
        defm    "SOFT",0

.rst2_5
        call    KPrint
        defm    " RESET ...",0

        ld      a, MM_S2|MM_MUL|MM_FIX
        ld      bc, 0
        OZ      OS_Mop                          ; allocate memory pool, A=mask
.rst2_6
        jr      c, rst2_6                       ; crash if no memory

        ld      (pFsMemPool), ix                ; filesystem pool
        jp      Reset3
