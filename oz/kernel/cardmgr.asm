; -----------------------------------------------------------------------------
; Bank 0 @ S3           ROM offset $09d6
;
; $Id$
; -----------------------------------------------------------------------------

        Module CardMgr

        org     $c9d6                           ; 361 bytes

;       bank 0

        include "director.def"
        include "blink.def"
        include "sysvar.def"

xdef    IntFlap

;       bank 0

xref    Delay300Kclocks
xref    DrawOZwd
xref    ExpandMachine
xref    InitSlotRAM
xref    MountAllRAM
xref    MS12BankCB
xref    MS1BankA
xref    MS2BankK1
xref    NMIMain
xref    OZwd__fail
xref    OZwd_card
xref    OZwd_index
xref    VerifySlotType

;       ----

.IntFlap                                        
        ld      bc, (BLSC_SR1)                  ; remember S1/S2
        push    bc
        exx
        push    bc
        push    de
        push    hl

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


; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1dbbe
;
; $Id$
; -----------------------------------------------------------------------------


;       read application card IDs into RAM

.StoreCardIDs
        call    CardSub

.scid_1
        push    de
        ld      a, d                            ; map in last bank in slot D
        rrca
        rrca
        or      $3F
        call    MS1BankA
        exx                                     ; clear ID
        xor     a
        ld      b, a
        ld      c, a
        ld      d, a
        ld      e, a
        exx
        call    VerifySlotType
        bit     1, d
        exx
        jr      z, scid_2                       ; not application rom? skip

        ld      bc, ($7FF8)                     ; read card ID into debc'
        ld      de, ($7FFA)

.scid_2
        dec     hl                              ; store ID
        ld      (hl), d
        dec     hl
        ld      (hl), e
        dec     hl
        ld      (hl), b
        dec     hl
        ld      (hl), c
        exx

        pop     de
        dec     d
        jr      nz, scid_1
        ret

;       ----

;       check if cards were changed, act accordingly

.ChkCardChange
        call    CardSub

.ccc_1
        push    de
        ld      a, d                            ; bind in last bank in slot D
        rrca
        rrca
        or      $3F
        call    MS1BankA
        exx                                     ; read previous slotID into debc'
        dec     hl
        ld      d, (hl)
        dec     hl
        ld      e, (hl)
        dec     hl
        ld      b, (hl)
        dec     hl
        ld      c, (hl)
        push    hl
        exx
        call    VerifySlotType
        bit     ST_B_APPLROM, d
        jr      z, ccc_8                        ; not appl card? skip

        exx                                     ; compare IDs
        ld      hl, ($7FF8)
        or      a
        sbc     hl, bc
        exx
        jr      nz, ccc_diff                    ; not same card
        exx
        ld      hl, ($7FFA)
        sbc     hl, de
        exx
        jr      z, ccc_same                     ; same card

.ccc_diff
        exx
        ld      a, d
        or      e
        or      b
        or      c
        exx
        jr      z, ccc_insert                   ; previously empty, just signal Index

.ccc_3
        ld      hl, ubIdxPubFlags
        bit     IDXF1_B_INSIDEOZ, (hl)
        jr      nz, ccc_4                       ; we can handle it now
        call    OZwd_index                      ; otherwise show "index" in OZ window
        jr      ccc_6

.ccc_4
        pop     hl
        pop     de
        push    de
        push    hl
        ld      a, d                            ; slot
        rrca
        rrca
        and     $C0
        ld      c, a                            ; slot base
        ld      a, d
        exx
        push    bc                              ; remember ID
        push    de
        push    hl                              ; !! is this necessary?
        exx
        OZ      DC_Pol                          ; Poll for card usage
        exx
        pop     hl
        pop     de
        pop     bc
        exx
        jr      nz, ccc_5                       ; card was active? show "card"

        ld      a, (pMTHHelpHandle+1)
        or      a
        jr      z, ccc_insert
        ld      ix, (pMTHHelpHandle)
        ld      a, (ix+$0D)                     ; check if slot matches
        and     $C0
        cp      c
        jr      nz, ccc_insert

.ccc_5
        call    OZwd_card                       ; show "card" in OZ window

.ccc_6
        pop     hl
        pop     hl
        scf
        ret

.ccc_insert
        ld      hl, ubIdxPubFlags               ; tell Index to re-read application letters
        set     IDXF1_B_INIT, (hl)
        jr      ccc_same

.ccc_8
        exx                                     ; if we had card earlier see if it was in use
        ld      a, d
        or      e
        or      b
        or      c
        exx
        jr      nz, ccc_3

.ccc_same
        pop     hl
        pop     de
        push    de
        push    hl
        ld      a, d                            ; bind first bank in S1
        rrca
        rrca
        and     $C0
        call    MS1BankA
        ld      hl, $4000                       ; test for RAM
        ld      c, (hl)
        ld      a, c
        xor     $FF				; !! cpl
        ld      (hl), a
        xor     (hl)                            ; Fz=1 if RAM
        ld      (hl), c
        inc     hl
        ld      b, (hl)
        jr      z, ccc_ram                      ; RAM? verify it's tagged
        pop     hl
        pop     de
        push    de
        push    hl
        ld      c, d                            ; check there was no RAM earlier
        ld      b, 0
        ld      hl, ubSlotRamSize
        add     hl, bc
        ld      a, (hl)
        or      a
        jr      nz, ccc_fail                    ; RAM card removed? fail
        jr      ccc_next

.ccc_ram
        ld      hl, $A55A
        sbc     hl, bc
        jr      z, ccc_next                     ; tagged? skip

        pop     hl
        pop     de
        push    de
        push    hl
        ld      c, d
        ld      b, 0
        ld      hl, ubSlotRamSize
        add     hl, bc
        ld      a, (hl)
        or      a
        jr      nz, ccc_fail                    ; RAM card replaced? fail
        pop     hl
        pop     de
        push    de
        push    hl
        ld      a, d                            ; go add RAM in slot D
        rrca
        rrca
        and     $C0
        call    AddRAMCard

.ccc_next
        exx
        pop     hl
        exx
        pop     de
        dec     d
        jp      nz, ccc_1
        call    DrawOZwd
        or      a
        ret

.ccc_fail
        ei
        jp      OZwd__fail

;       ----

.CardSub
        ld      de, 3<<8|$3F                    ; 3 loops, max card size
        exx
        ld      hl, ulSlot3ID+4
        exx
        ret

.AddRAMCard                                     
        call    InitSlotRAM
        cp      $40
        call    z, ExpandMachine                ; slot1? expand if 128KB or more
        call    MountAllRAM
	ret
