; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $09d6
;
; $Id$
; -----------------------------------------------------------------------------

        Module CardMgr

        org     $c9d6                           ; 79 bytes

        include "blink.def"
        include "sysvar.def"

xdef    AddRAMCard
xdef    IntFlap

;       bank 0

xref    Delay300Kclocks
xref    ExpandMachine
xref    InitSlotRAM
xref    MountAllRAM
xref    MS12BankCB
xref    MS2BankK1
xref    NMIMain

;       bank 7

xref    ChkCardChange
xref    StoreCardIDs

;       ----

.IntFlap                                        
        ld      bc, (BLSC_SR1)                  ; remember S1/S2
        push    bc
        exx
        push    bc
        push    de
        push    hl
        call    MS2BankK1
        call    StoreCardIDs

        ld      a, (BLSC_COM)                   ; beep
        or      BM_COMSRUN
        out     (BL_COM), a

.intf_1                                         
        push    af
        call    Delay300Kclocks
        ld      a, BM_INTFLAP                   ; ack flap
        out     (BL_ACK), a
        in      a, (BL_STA)
        bit     BB_STAFLAPOPEN, a               ; !! add a; call c,...
        call    nz, NMIMain                     ; halt until flap closed?

        pop     af
        jr      nc, intf_2

        ld      a, (BLSC_COM)                   ; beep
        or      BM_COMSRUN
        out     (BL_COM), a
.intf_2                                         
        call    ChkCardChange
        jr      c, intf_1                       ; go back

        ld      a, (BLSC_COM)                   ; restore BL_COM
        out     (BL_COM), a
        pop     hl
        pop     de
        pop     bc
        exx
        pop     bc                              ; restore S1/S2
        jp      MS12BankCB

;       ----

.AddRAMCard                                     
        call    InitSlotRAM
        cp      $40
        call    z, ExpandMachine                ; slot1? expand if 128KB or more
        call    MountAllRAM
        jp      MS2BankK1                       ; restore S2 before returning there
