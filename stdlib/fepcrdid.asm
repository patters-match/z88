     XLIB FlashEprCardId

     INCLUDE "flashepr.def"
     INCLUDE "memory.def"


; ***************************************************************
;
; Identify Intel Flash Eprom Chip in slot C.
;
; ---------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997 - Apr 1998
;    Thierry Peycru, Zlab, Dec 1997
; ---------------------------------------------------------------
;
; In:
;         C = slot number (1, 2 or 3)
;
; Out:
;         Success:
;              Fc = 0
;              Fz = 1
;              A = Intel Device Code
;                   fe_i016 ($AA), an INTEL 28F016S5 (2048K)
;                   fe_i008 ($A2), an INTEL 28F008SA (1024K)
;                   fe_i8s5 ($A6), an INTEL 28F008S5 (1024K)
;                   fe_i004 ($A7), an INTEL 28F004S5 (512K)
;                   fe_i020 ($BD), an INTEL 28F020 (256K)
;              B = total of 64K blocks on Flash Eprom.
;
;         Failure:
;              Fc = 1
;              Fz = 0
;              A = RC_NFE (not a recognised Intel Flash Eprom)
;
; Registers changed on return:
;    ...CDEHL/IXIY ........ same
;    AFB...../.... afbcdehl different
;
.FlashEprCardId
                    PUSH HL
                    PUSH BC

                    CALL FetchCardID         ; get info of Intel chip in HL...
                    LD   A, FE_INT           ; Intel Flash Eprom?
                    CP   H
                    JR   NZ, unknown_device  ; not an Intel Chip...

                    LD   A,L                 ; Fc = 0, Fz = 1, A = device code
                    CALL GetTotalBlocks      ; return no. of blocks in B
                    POP  HL
                    LD   C,L                 ; original C restored
                    POP  HL                  ; original HL restored
                    RET
.unknown_device     
                    LD   A, RC_NFE
                    SCF
                    POP  BC
                    POP  HL
                    RET


; ***************************************************************
;
; Get the Manufactor and device code from the Intel chip.
; This routine will clone itself on the stack and execute there.
;
; In:
;    C = slot number (1, 2 or 3)
; 
; Out:
;    H = manufacturer code (at $00 0000 on chip)
;    L = device code (at $00 0001 on chip)
;
; Registers changed on return:
;    ....DE../IXIY same
;    AFBC..HL/.... different
;
.FetchCardID        EXX
                    LD   HL,0
                    ADD  HL,SP
                    EX   DE,HL
                    LD   HL, -(RAM_code_end - RAM_code_start)
                    ADD  HL,SP
                    LD   SP,HL               ; buffer for routine ready...
                    PUSH DE                  ; preserve original SP
                    
                    PUSH HL
                    EX   DE,HL               ; DE points at <RAM_code_start>
                    LD   HL, RAM_code_start
                    LD   BC, RAM_code_end - RAM_code_start
                    LDIR                     ; copy RAM routine...
                    LD   HL,exit_fetchid
                    EX   (SP),HL
                    PUSH HL
                    EXX
                    RET                      ; CALL RAM_code_start
.exit_fetchid                 
                    EXX
                    POP  HL                  ; original SP
                    LD   SP,HL
                    EXX
                    RET                      ; return HL = Intel info...

; 40 bytes of code to be executed on stack...
.RAM_code_start
                    LD   A,C
                    AND  @00000011           ; slots (0), 1, 2 or 3 possible
                    RRCA
                    RRCA                     ; Converted to Slot mask $40, $80 or $C0
                    LD   B,A
                    LD   C, $01           
                    CALL_OZ(OS_MPB)          ; Get bottom Bank of slot 3 into segment 1
                    PUSH BC                  ; preserve old bank binding

                    LD   HL, $4000           ; Pointer at beginning of segment 1 ($0000)
                    LD   (HL), FE_IID        ; Flash Eprom Card ID command
                    LD   B,(HL)              ; B = manufacturer code (at $00 0000)
                    INC  HL
                    LD   C,(HL)              ; C = device code (at $00 0001)
                    LD   (HL), FE_RST        ; Reset Flash Eprom Chip to read array mode
                    PUSH BC
                    POP  HL
                    POP  BC
                    CALL_OZ(OS_MPB)          ; restore original bank in segment 1
                    RET
.RAM_code_end


; ***************************************************************
;
; IN:
;    A = Device code
;
; OUT:
;    B = total of 64K blocks on Flash Eprom
;
; Registers changed on return:
;   AF.CDE../IXIY same
;    .B...HL/.... different
;
.GetTotalBlocks     PUSH AF

                    LD   HL, FlashEprTypes
                    LD   B,(HL)                   ; no. of Flash Eprom Types in table
                    INC  HL
.find_loop          CP   (HL)                     ; device code found?
                    INC  HL
                    JR   NZ, get_next
                         LD   B,(HL)              ; B = total of block on Flash Eprom
                         JR   exit_getblocks      ; Fc = 0, Flash Eprom data returned...
.get_next           INC  HL
                    DJNZ find_loop                ; point at next entry...
.exit_getblocks
                    POP  AF
                    RET
.FlashEprTypes
                    DEFB 5
                    DEFB fe_i020, 4
                    DEFB fe_i004, 8
                    DEFB fe_i008, 16
                    DEFB fe_i8s5, 16
                    DEFB fe_i016, 32
                    DEFB fe_i8s5, 16
