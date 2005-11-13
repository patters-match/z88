module ResetX

include "sysvar.def"

xdef    Chk128KB
xdef    Chk128KBslot0
xdef    FirstFreeRAM
xdef    MountAllRAM

xref    MS1BankA                                ; bank0/misc5.asm
xref    MS2BankK1                               ; bank0/misc5.asm

xref    RAMDORtable                             ; bank7/misc1.asm
xref    RAMxDOR                                 ; bank7/misc1.asm


.MountAllRAM
        call    MS2BankK1
        ld      hl, RAMDORtable
.maram_1
        ld      a, (hl)                         ; 21 21 40 80 c0  bank
        inc     hl
        or      a
        jr      z, maram_5
        call    MS1BankA
        ld      d, $40                          ; address high byte
        ld      e, (hl)                         ; 80 40 40 40 40  address low byte
        inc     hl
        ld      c, (hl)                         ;  -  0  1  2  3  RAM number
        inc     hl
        ld      a, c
        cp      '-'
        jr      z, maram_2
        ld      a, (de)                         ; skip if no RAM
        or      a
        jr      nz, maram_1
.maram_2
        push    hl
        ld      a, c
        cp      '-'                             ; !! combine with above check
        jr      z, maram_3
        ex      af, af'
        ld      hl, $4000
        ld      a, (ubResetType)                ; 0 = hard reset
        and     (hl)
        jr      nz, maram_4                     ; soft reset & already tagged, skip
        ex      af, af'
.maram_3
        ld      hl, RAMxDOR                     ; !! could be smaller without table
        ld      bc, 17
        ldir
        ld      (de), a
        inc     de
        ld      bc, 2                           ; just copy 00 FF
        ldir
        cp      '-'                             ; tag RAM if not RAM.-
        jr      z, maram_4
        ld      bc, $a55a
        ld      ($4000), bc
.maram_4
        pop     hl
        jr      maram_1
.maram_5
        ret

.Chk128KB
        ld      a, (ubSlotRamSize+1)            ; RAM in slot1
        cp      128/16
        ret     nc

.Chk128KBslot0
        ld      a, (ubSlotRamSize)              ; RAM in slot0
        cp      128/16                          ; Fc=1 if less than 128KB
        ret

.FirstFreeRAM
        call    Chk128KBslot0
        ld      a, $21
        ret     nc
        ld      a, $40
.ffr_1
        ret