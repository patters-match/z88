;          ZZZZZZZZZZZZZZZZZZZZ
;        ZZZZZZZZZZZZZZZZZZZZ
;                     ZZZZZ
;                   ZZZZZ
;                 ZZZZZ           PPPPPPPPPPPPPP     RRRRRRRRRRRRRR       OOOOOOOOOOO     MMMM       MMMM
;               ZZZZZ             PPPPPPPPPPPPPPPP   RRRRRRRRRRRRRRRR   OOOOOOOOOOOOOOO   MMMMMM   MMMMMM
;             ZZZZZ               PPPP        PPPP   RRRR        RRRR   OOOO       OOOO   MMMMMMMMMMMMMMM
;           ZZZZZ                 PPPPPPPPPPPPPP     RRRRRRRRRRRRRR     OOOO       OOOO   MMMM MMMMM MMMM
;         ZZZZZZZZZZZZZZZZZZZZZ   PPPP               RRRR      RRRR     OOOOOOOOOOOOOOO   MMMM       MMMM
;       ZZZZZZZZZZZZZZZZZZZZZ     PPPP               RRRR        RRRR     OOOOOOOOOOO     MMMM       MMMM


; **************************************************************************************************
; This file is part of Zprom.
;
; Zprom is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Zprom is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the Zprom;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
;***************************************************************************************************


     MODULE Eprom_Programming

     LIB MemDefBank

     XREF eprg_prompt, eprg_banner
     XREF DispErrWindow, ReportWindow, Disp_EprAddrError
     XREF ProgramFlashEprom

     XDEF EPROG_command, Check_Eprom, Verify_Eprom, Bind_in_Bank
     XDEF BlowEprom
     XDEF Get_AbsRange

     INCLUDE "defs.asm"
     INCLUDE "stdio.def"
     INCLUDE "memory.def"
     INCLUDE "interrpt.def"


; ************************************************************************************************
; CC_eprog  -   Program Eprom
;
.EPROG_command      LD   A,(EpromType)
                    CP   FlashEprom
                    JP   Z, ProgramFlashEprom          ; Eprom Type is Flash Card...

                    CALL BlowEprom                     ; Blow 32, 128 or 256K conventional Eproms...
                    RET  C
                    LD   BC,$0210                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,eprg_prompt
                    LD   IX,eprg_banner                ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET



; ************************************************************************************************
;
.BlowEprom          CALL Check_Eprom                    ; eprom already used at range?
                    RET  C
                    LD   A,(EprBank)                    ; get current EPROM bank to be blown...
                    BIT  7,A
                    JR   Z, err_BlowEprom               ; UV Eproms require slot 3 hardware...
                    BIT  6,A
                    JR   Z, err_BlowEprom
                    LD   B,A                            ; bank to be bound into
                    CALL Bind_in_Bank                   ; segment 2
                    CALL OZ_DI                          ; Disable interrupts
                    PUSH AF                             ; preserve interrupt status
                    CALL ProgramEprom
                    EX   AF,AF'                         ; preserve Eprom programming status
                    POP  AF                             ; restore previous interrupt status
                    CALL OZ_EI
                    EX   AF,AF'                         ; restore status from eprom programing
                    RET  NC

.Epr_prog_err       LD   (ReProgram),HL                 ; save address (in HL) of used byte in EPROM
                    LD   A,7
                    CALL_OZ(Os_out)                     ; warning bleep
                    LD   A,13                           ; "Byte incorrectly blown in Eprom at "
                    CALL Disp_EprAddrError
.err_BlowEprom
                    SCF
                    RET


; *********************************************************************************************************************
;
; Program current Eprom Bank at current range with the contents of the identical range in memory buffer
;
; Returns Fc = 1, if an Eprom Address couldn't be programmed. The address is in HL.
;         Fc = 0, if programming were successful.
;
; All registers except IY are changed.
;
.ProgramEprom                                           ; blow all bytes the first time...
                    CALL Get_AbsRange                   ; get start ranges in HL, DE, length in BC
                    LD   A,$0E                          ; VPP on, PROGRAM on, screen OFF...
                    OUT  ($B0),A                        ; set COM register...
                    CALL BlowBytes                      ;
                    LD   A,$04                          ; PROGRAM off, VPP off (screen still off)
                    OUT  ($B0),A                        ;

.vfy_main_loop      CALL Verify_Eprom                   ; BC returned = remaining bytes to verify
                    CALL NC,OverProgram                 ; overprogram successfully blown bytes
                    JR   NC,progr_finished              ; then turn screen back on - and back to main menu

                    CALL Check_Startbyte                ; Verification failed - is first byte badly blown?
                    CALL Z,ReProgram_Byte               ; Yes - try to re-program byte and
                    JR   Z, new_vfy_range               ; then continue to verify after re-blown byte

                    CALL OverProgram                    ; First overprogram subrange before incorrect byte
                    CALL ReProgram_Byte                 ; then re-program byte after subrange.

.new_vfy_range      EXX
                    PUSH HL
                    PUSH DE
                    PUSH BC
                    EXX
                    POP  BC                             ; get new sub-range to verify
                    POP  DE
                    POP  HL

                    LD   A,B
                    OR   C                              ; all bytes programmed successfully on Eprom?
                    JR   NZ, vfy_main_loop              ; no - continue to verify the sub-range

.progr_finished     LD   A,$05                          ;
                    OUT  ($B0),A                        ; turn screen back on
                    RET                                 ; and report state of Eprom at caller


; **************************************************************************************************************
;
; a byte wasn't correctly blown on eprom, check if the address is the same as the first
; address where blowing began.
; - if not, then execute first overprogramming, then re-program the incorrectly blown byte
;
; Returns:
;           Fz = 1, first byte in range not programmed correctly
;           Fz = 0, byte to be reprogrammed at end+1 of subrange
;
; Registers changed on return:
;   ..BCDEHL/IXIY   same
;   AF....../....   different
;
.Check_Startbyte    PUSH HL                             ;
                    PUSH DE                             ;
                    EX   DE,HL                          ; HL = overprogram address
                    LD   DE,(ReProgram)                 ; DE = reprogram address
                    LD   A,D                            ; are they the same?
                    CP   H                              ;
                    JR   NZ,do_overprog                 ; no - first overprogram blown bytes
                    LD   A,E                            ;
                    CP   L                              ;
                    JR   NZ,do_overprog                 ;
.do_overprog        POP  DE                             ; Fz = 1 , first byte not programmed correctly
                    POP  HL                             ;
                    RET


; **************************************************************************************************************
;
; HL = start of Memory range
; DE = start of Eprom Bank range (in segment 2)
; BC = bytes left in subrange (0 if subrange were verified completely)
; IX = total no. of bytes in subrange
;
; OUT: BC = number of bytes overprogrammed at subrange
;
; Registers changed on return:
;   AF..DEHL/IXIY   same
;   ..BC..../....   different
;
.OverProgram        PUSH AF
                    PUSH HL
                    PUSH IX
                    POP  HL                             ; length of subrange in HL
                    CP   A
                    SBC  HL,BC                          ; get no. of bytes that were programmed correctly
                    LD   B,H
                    LD   C,L                            ; number of bytes to overprogram...
                    DEC  BC                             ; don't overprogram incorrectly blown byte...
                    LD   A,$2E                          ; VPP on, OverPROGRAM on, screen OFF...
                    OUT  ($B0),A                        ; set COM register
                    POP  HL                             ; restore pointer to start of memory subrange
                    CALL BlowBytes                      ; overprogram correctly blown bytes...
                    LD   A,$04                          ; overprogramming off
                    OUT  ($B0),A                        ;
                    POP  AF
                    RET


; **************************************************************************************************************
;
; No registers changed on return.
;
; If byte cannot be reprogrammed at Eprom address, an immediate return is executed to '.EPROG_command' ,
; which displays an error box.
;
.ReProgram_Byte     PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   B,74                           ; max. attempts to reprogram (already blown once)
                    LD   HL,(ReProgram)                 ; get address to reprogram in HL
                    LD   DE,(ReProgByte)
                    LD   A,(DE)                         ; get byte to be re-programmed in A
.reprog_loop        PUSH AF
                    LD   A,$0E                          ; VPP on, PROGRAM on, screen OFF...
                    OUT  ($B0),A                        ; set COM register...
                    POP  AF
                    LD   (HL),A                         ; re-program byte...
                    PUSH AF
                    LD   A,$04                          ; PROGRAM off, VPP off (screen still off)
                    OUT  ($B0),A                        ;
                    POP  AF
                    CP   (HL)                           ; byte blown correctly on EPROM?
                    JR   Z,byte_blown                   ;
                    DJNZ reprog_loop                    ;

                    POP  DE                             ; POP HL from stack
                    POP  DE
                    POP  BC
                    POP  AF                             ; eprom programming finished, byte not blown...
                    POP  IX                             ; remove subroutine return address
                    SCF                                 ; Signal error, HL = Eprom address
                    JP   progr_finished                 ; re-bind prev. bank in segment 2 and return.

; byte has finally been blown correctly                 ;
.byte_blown         PUSH AF
                    LD   A,$2E                          ; VPP on, OverPROGRAM on, screen OFF...
                    OUT  ($B0),A                        ; set COM register...
                    LD   A,75                           ; now overprogram same no of times
                    SUB  B                              ; it took to re-program + 1 (the first blow)
                    LD   B,A                            ;
                    POP  AF
.ovp_byte_loop      LD   (HL),A                         ;
                    DJNZ,ovp_byte_loop                  ;
                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET


; **************************************************************************************************************
;
; IN:
; HL points at start of memory buffer range to verify with
; DE points at start of eprom range (bound in segment 2)
; BC number of bytes to verify
;
; Returns:
;           Always:     DE  = start of verified Eprom range
;                       HL  = start of verified Memory range
;                       IX  = total no. of bytes in subrange
;                       BC  = number of bytes left to verify (or 0 if all verified)
;                       BC' = BC
;
;           Fc = 1      a byte wasn't programmed successfully
;                       (ReProgram) = Eprom Address of
;                       (ReProgByte) = byte not programmed correctly after first blow.
;                       DE' = next start subrange address in Eprom to verify
;                       HL' = next start subrange address in Memory to verify
;
;           Fc = 0      range/subrange programmed correctly - verification successful.
;
; Registers changed on return:
;   ....DEHL/..IY   same
;   AFBC..../IX..   different
;
.Verify_Eprom       PUSH HL
                    PUSH DE
                    PUSH BC
                    POP  IX
.verify_loop        LD   A,B                            ;
                    OR   C                              ;
                    JR   Z,all_verified                 ;
                    LD   A,(DE)                         ;
                    CP   (HL)                           ;
                    INC  HL                             ;
                    INC  DE                             ;
                    DEC  BC                             ;
                    JR   Z,verify_loop                  ; byte successfully blown - check next byte
                    PUSH HL                             ;
                    PUSH DE                             ;
                    PUSH BC                             ;
                    EXX                                 ;
                    POP  BC                             ; number of bytes left to be verified
                    POP  DE                             ; pointer to next byte in memory
                    POP  HL                             ; pointer to next byte to be verified in EPROM
                    EXX                                 ;
                    INC  BC                             ; adjust to byte not correctly blown
                    DEC  HL                             ;
                    LD   A,(HL)                         ; get byte to be re-programmed
                    LD   (ReProgByte),A                 ; store it in variable 'ReProgByte'
                    DEC  DE                             ; point at byte not correctly blown
                    LD   (ReProgram),DE                 ; remember address to reprogram
                    SCF                                 ; signal byte not correctly blown...
                    POP  DE                             ;
                    POP  HL                             ; remember addresses to overprogram...
                    RET                                 ;
.all_verified       PUSH BC
                    EXX
                    POP  BC
                    EXX
                    POP  DE
                    POP  HL
                    RET


; ************************************************************************************
;
; Check current Eprom Bank at current range for bytes already blown.
; Returns Fc = 1 if byte already blown in address range,
;                and HL points at address already used
;
; All registers except IY are changed on return
;
.Check_Eprom        LD   A,(EprBank)
                    LD   B,A
                    CALL Bind_in_bank

                    CALL Get_AbsRange                   ; get Range in absolute addresses (for segment 2)
                    EX   DE,HL                          ; HL points at start range of Eprom...
                    LD   A,$FF                          ; $FF = byte not blown on eprom
.check_loop         CPI                                 ; byte used?
                    JP   PO,all_checked                 ; address range is free to be blown
                    JR   Z,check_loop                   ; no - check next byte
                    DEC  HL                             ;

                    LD   (ReProgram),HL                 ; save address (in HL) of used byte in EPROM
                    LD   A,7
                    CALL_OZ(Os_Out)                     ; Warning bleep
                    LD   A,11                           ; 'Eprom already used at ' ...
                    CALL Disp_EprAddrError
                    SCF                                 ; signal address range already used...
                    RET
.all_checked        CP   A                              ; Fc = 0, signal address range free to be used..
                    RET



; *************************************************************************************************************
;
; Get Current range in absolute addresses.
;
; Returns:
;   HL = start range in memory
;   DE = start range in Eprom (addressed for segment 2)
;   BC = length of range
;
; All registers except IX,IY are changed on return
;
.Get_AbsRange       LD   DE,(RangeStart)
                    PUSH DE
                    PUSH DE
                    PUSH DE                             ; range start on stack in 3 copies
                    LD   HL,(RangeEnd)
                    POP  DE                             ; get first copy of start range
                    CP   A
                    SBC  HL,DE
                    INC  HL
                    LD   B,H
                    LD   C,L                            ; length of range in BC
                    POP  DE                             ; get second copy of start range
                    LD   A,D                            ;
                    ADD  A,$80                          ; start range in Eprom bank (addressed for segment 2)
                    LD   D,A
                    POP  HL
                    LD   A,H
                    ADD  A,$20                          ; start range in memory buffer
                    LD   H,A
                    RET


; ***************************************************************************************
;
; Main Eprom blow routine.
; Entry ,
;       HL = start address of information (source address)...
;       DE = offset in bank to begin blow information in.
;       BC = length of information to blow.
;
; Registers changed on return:
;   .FBCDEHL/IXIY   same
;   A......./....   different
;
.BlowBytes          PUSH BC                             ;
                    PUSH DE                             ;
                    PUSH HL                             ;
                    LD   A,(EpromType)
                    OUT  ($B3),A                        ; set EPROM programming signals...
                    LDIR                                ; move bytes, BC, from memory (HL)
                    POP  HL                             ; to EPROM (DE)
                    POP  DE                             ;
                    POP  BC                             ;
                    RET                                 ;


; ************************************************************************************************
; Bank number in B
;
; Registers changed on return:
;   AF.CDEHL/IXIY   same
;   ..B...../....   different
;
.Bind_in_bank       PUSH AF
                    LD   C,$02                          ; segment 2, address range $8000 - $BFFF
                    CALL MemDefBank                     ; execute new binding...
                    POP  AF
                    RET                                 ; return old binding in B
