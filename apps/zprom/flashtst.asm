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
; $Id$  
;
;***************************************************************************************************


     MODULE FlashTest

     lib MemDefbank, MemReadByte
     lib SafeSegmentMask
     lib FlashEprBlockErase
     lib FlashEprCardId
     lib FlashEprWriteByte
     lib FlashEprVppOn, FlashEprVppOff
     lib CheckBattLow
     lib CreateWindow
     lib IntHex

     include "stdio.def"
     include "fileio.def"
     include "flashepr.def"
     include "integer.def"
     include "director.def"
     include "memory.def"


     XREF report_banner, fltst_prompt

     XREF FlashEprInfo, CheckFlashCard
     XREF ReportWindow

     XDEF FLTST_Command


; small workspace at bottom of Stack frame...
DEFVARS $1800
{
     LogFileHandle       ds.w 1              ; preserve the handle of the log file
     ErrorFlag           ds.b 1              ; Global Error Condition Flag
     ExtAddr             ds.p 1
     Buffer              ds.b 32
}


; ******************************************************************************
;
.FLTST_command
                    CALL CheckFlashCard
                    RET  C

                    CALL CreateLogFile       ; Create CLI "/eprlog"
                    CALL EprTestWindow       ; Create Window with banner

                    CALL_OZ(Gn_Nln)
                    CALL_OZ(Gn_Nln)

                    CALL FlashCardTest

                    CALL CloseLogFile        ; Terminate CLI re-direction...

                    LD   BC,$0316            ; postion of window
                    LD   DE,$052B            ; size of report window
                    LD   HL,fltst_prompt
                    LD   IX,report_banner    ; pointer to menu banner
                    CALL ReportWindow        ; display (menu) window with message

                    RET


; ******************************************************************
; Perform the test of the inserted Flash Card...
;
.FlashCardTest

; Identify, if a Flash Eprom Card is inserted in slot 3
                    CALL CheckBatteries
                    RET  C

                    CALL FlashEprInfo
                    JR   C, FlashEpr_not_found
                    CALL_OZ(Gn_sop)                    ; display chip information
                    CALL_OZ(Gn_Nln)
                    CALL_OZ(Gn_Nln)

; Flash Eprom Card available in slot 3,
; now format all 16 blocks on the card...
                    CALL FormatCard
                    JR   C, format_err

; all blocks formatted, now program all blocks with 0's
; (all bits reset)
                    CALL ProgramCard
                    LD   A,(ErrorFlag)
                    OR   A
                    JR   NZ, program_err

; Flash Eprom Card programmed successfully with 0's
; now read the complete card...
                    CALL VerifyCard
                    LD   A,(ErrorFlag)
                    OR   A
                    JR   NZ, verify_err

; finally, reset the card again...
                    CALL FormatCard
                    JR   C, format_err

; the test have been performed successfully
; Display "Completed Message" and exit.
                    LD   HL, Completedmsg
                    CALL_OZ Gn_Sop
                    RET



; ******************************************************************
; the Flash Eprom Card could not be blown correctly
;
.program_err
                    LD   HL, ProgErrmsg
                    CALL_OZ Gn_Sop
                    RET


; ******************************************************************
.verify_err
                    LD   HL, VerifyErrmsg
                    CALL_OZ Gn_Sop
                    RET


; ******************************************************************
; The block (identified in C register) couldn't be formatted
.format_err
                    LD   HL, Errormsg
                    CALL_OZ Gn_Sop
                    LD   HL, formaterrmsg
                    CALL_OZ Gn_Sop
                    CALL IntAscii
                    LD   HL, buffer
                    CALL_OZ Gn_Sop
                    CALL_OZ Gn_Nln
                    RET


; ******************************************************************
; The Flash Eprom Card was not identified in slot 3
.FlashEpr_not_found
                    ; Display error message, wait for a key press, and exit
                    LD   HL, CardNotFound
                    CALL_OZ Gn_Sop
                    RET


; ******************************************************************
.VerifyCard
                    LD   HL, Verifymsg
                    CALL_OZ Gn_Sop

                    CALL VerifyBanks
                    RET  C

.VerifyCompleted
                    LD   HL, DoneMsg
                    CALL_OZ Gn_Sop
                    CP   A
                    RET


; ******************************************************************
.VerifyBanks
                    CALL FlashEprInfo
                    SLA  B
                    SLA  B
                    LD   C,B                 ; Total of banks = Block * 4
                    LD   B,$C0               ; start verifying of bank $C0
.verif_card_loop

                    PUSH BC
                    LD   C, MS_S2
                    CALL MemDefBank          ; bind bank into segment 2
                    POP  BC

                    PUSH BC
                    PUSH HL
                    LD   HL, VerifyBankMsg
                    CALL_OZ Gn_Sop
                    LD   A,B
                    AND  @00111111           ; display relative bank numbers...
                    LD   (ExtAddr),A
                    LD   C,1                 ; 8bit integer...
                    LD   B,0                 ; (local ptr)
                    LD   HL, ExtAddr
                    LD   DE, Buffer          ; ptr to Ascii result...
                    CALL IntHex
                    LD   HL, Buffer
                    CALL_OZ Gn_Sop
                    LD   HL, Dotsmsg
                    CALL_OZ Gn_Sop
                    POP  HL
                    POP  BC

                    LD   DE, $4000           ; verify 16K...
                    LD   HL, $8000           ; point at beginning of segment

.verif_bank_loop
                    LD   A,(HL)
                    OR   A
                    CALL NZ, SetErrorFlag
                    CALL NZ, AddrProgError   ; display address of programming error
                    INC  HL

                    DEC  DE
                    LD   A,D
                    OR   E
                    JR   NZ, verif_bank_loop

                    PUSH HL
                    LD   HL, Donemsg
                    CALL_OZ Gn_Sop
                    POP  HL

                    INC  B                   ; ready for next bank
                    DEC  C
                    JR   NZ, verif_card_loop

                    CP   A                   ; signal success (Fc = 0)
.exit_verify
                    RET


; ******************************************************************
;
.ProgramCard        XOR  A
                    LD   (ErrorFlag),A

                    CALL CheckBatteries
                    RET  C                   ; batteries are low - abort...

                    LD   HL, ProgramMsg
                    CALL_OZ Gn_Sop

                    CALL FlashEprVppOn

                    CALL FlashEprInfo
                    SLA  B
                    SLA  B
                    LD   C,B                 ; Total of banks = Block * 4
                    LD   B,$C0               ; start programming of bank $C0
                    LD   C,64                ; total of 64 banks...

                    XOR  A
                    LD   (ErrorFlag),A       ; reset error flag

.prog_card_loop
                    PUSH BC
                    LD   C, MS_S2
                    CALL MemDefBank          ; bind bank into segment MS_S2
                    POP  BC

                    PUSH BC
                    PUSH HL
                    LD   HL, ProgramBankMsg
                    CALL_OZ Gn_Sop
                    LD   A,B
                    AND  @00111111           ; display relative bank numbers...
                    LD   (ExtAddr),A
                    LD   C,1                 ; 8bit integer...
                    LD   B,0                 ; (local ptr)
                    LD   HL, ExtAddr
                    LD   DE, Buffer          ; ptr to Ascii result...
                    CALL IntHex
                    LD   HL, Buffer
                    CALL_OZ Gn_Sop

                    LD   HL, Dotsmsg
                    CALL_OZ Gn_Sop
                    POP  HL
                    POP  BC

                    LD   DE, $4000           ; blow 16K...
                    LD   HL, $8000           ; beginning of segment
.prog_bank_loop
                    CALL CheckBatteries
                    JR   C, exit_programming ; batteries low - abort...

                    PUSH BC
                    LD   C,0
                    CALL BlowByte
                    POP  BC
                    CALL C, SetErrorFlag
                    CALL C, AddrProgError    ; display address of programming error
                    INC  HL                  ; ready for next address on bank

                    DEC  DE
                    LD   A,D
                    OR   E
                    JR   NZ, prog_bank_loop

                    PUSH HL
                    LD   HL, Donemsg
                    CALL_OZ Gn_Sop
                    POP  HL

                    INC  B                   ; ready for next bank
                    DEC  C
                    JR   NZ, prog_card_loop

.exit_programming                            ; all banks manipulated
                    CALL FlashEprVppOff      ; disable vpp pin on Flash Card
                    RET


; ***********************************************************
;
.SetErrorFlag
                    PUSH AF
                    LD   A,$FF
                    LD   (ErrorFlag),A
                    POP  AF
                    RET


; ******************************************************************
;
; Display error message and ext. address of programming error
;
.AddrProgError
                    PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   A, B
                    LD   (ExtAddr),A
                    RES  7,H
                    RES  6,H
                    LD   (ExtAddr+1),HL      ; save ext. address...

                    LD   HL, Progaddrerrmsg
                    CALL_OZ(Gn_Sop)

                    LD   BC,1
                    LD   HL,ExtAddr
                    LD   DE, Buffer
                    CALL IntHex

                    EX   DE,HL
                    CALL_OZ(Gn_Sop)          ; Display Bank no in hex

                    LD   BC,2
                    LD   HL,ExtAddr+1
                    LD   DE, Buffer
                    CALL IntHex

                    EX   DE,HL
                    CALL_OZ(Gn_Sop)          ; Display offset address in hex
                    CALL_OZ(Gn_Nln)

                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET



; ******************************************************************
;
; Write a 0 byte to the Flash Eprom Card, at address (HL), in the
; default bank identified by Register B
;
; In:
;         C = Byte to blow at (HL)
;
; Out:
;         Fc = 0, Byte blown successfully
;         Fc = 1, Byte failed to be blown at address
;
; ==========================================================================================
; Flash Eprom Commands for 28Fxxxx series (equal to all chips, regardless of manufacturer)

DEFC FE_RST = $FF           ; reset chip in read array mode
DEFC FE_RSR = $70           ; read status register
DEFC FE_CSR = $50           ; clear status register
DEFC FE_WRI = $40           ; byte write command
; ==========================================================================================
.BlowByte
                    PUSH BC

                    LD   A, FE_WRI
                    LD   (HL), A             ; Flash Eprom (WRI)te Byte command
                    LD   (HL), C             ; blow the byte...

.write_busy_loop
                    LD   (HL), FE_RSR        ; Flash Eprom (R)equest for (S)tatus (R)egister
                    LD   A,(HL)              ; - returned in A
                    BIT  7,A
                    JR   Z,write_busy_loop

                    CP   A                   ; Flash Eprom Command executed
                    LD   B,0                 ; Default is success...
                    BIT  4,A
                    CALL NZ,write_error      ; Error: Byte couldn't be blown
                    BIT  3,A
                    CALL NZ,vpp_error        ; Error: Vpp was not enabled...
                    LD   A,B

                    POP  BC
                    RET

.write_error
                    LD   B, RC_BWR
                    SCF
                    RET
.vpp_error
                    LD   B, RC_VPL
                    SCF
                    RET



; ******************************************************************
;
; Format the Flash Eprom Card, beginning at block 15 (top), downwards.
;
; In:
;     None.
; Out:
;     Success:
;        Fc = 0, Card formatted
;     Failure:
;        Fc = 1
;        A = RC_VPL, RC_BER
;        C = Block that couldn't be formatted
;
; Registers changed after return:
;   ....DEHL/IXIY same
;   AFBC..../.... different
;
.FormatCard
                    PUSH DE
                    PUSH HL

                    CALL FlashEprInfo
                    LD   H,B                 ; H = returned number of blocks on card

                    LD   BC,0
.format_loop
                    PUSH BC
                    PUSH HL
                    LD   HL, formatmsg
                    CALL_OZ Gn_Sop           ; "Formatting block "
                    CALL IntAscii
                    LD   HL, buffer
                    CALL_OZ Gn_Sop           ; Display block number...
                    LD   HL, Dotsmsg
                    CALL_OZ Gn_sop
                    POP  HL
                    POP  BC

                    CALL CheckBatteries      ; before a format, check battery status
                    JR   C, exit_format

                    LD   A,C
                    CALL FlashEprBlockErase
                    JR   C, exit_format

                    PUSH HL
                    LD   HL, donemsg
                    CALL_OZ Gn_Sop
                    POP  HL

                    INC  C                   ; next block
                    DEC  H
                    JR   NZ, format_loop     ; format next block
.exit_format
                    POP  HL
                    POP  DE
                    RET


; ***************************************************************
;
.EprTestWindow
                    LD   A, 64 | '2'
                    LD   BC, $0011
                    LD   DE, $0834
                    CALL CreateWindow
                    LD   HL, vdu
                    CALL_OZ(Gn_Sop)
                    RET


; ******************************************************************
; Convert integer in BC too Ascii at (Buffer), null-terminated
.IntAscii
                    PUSH AF
                    PUSH DE
                    PUSH HL

                    LD   HL, 2
                    LD   DE, buffer
                    LD   A,1                 ; free format
                    CALL_OZ Gn_Pdn
                    XOR  A
                    LD   (DE),A              ; Null-terminate

                    POP  HL
                    POP  DE
                    POP  AF
                    RET


; ******************************************************************
; Check Battery Status
;
.CheckBatteries
                    CALL CheckBattLow
                    RET  NC
                    PUSH AF
                    PUSH HL
                    LD   HL, battlowmsg
                    CALL_OZ(Gn_sop)
                    POP  HL
                    LD   A,$FF
                    LD   (ErrorFlag),A
                    POP  AF
                    SCF
                    RET



; ******************************************************************
;
.CreateLogFile      LD   HL, CLI_file
                    LD   DE, Buffer
                    LD   A,OP_OUT
                    LD   BC,8
                    CALL_OZ(Gn_Opf)               ; log file '/eprlog' & 0
                    RET  C                        ; Ups - open error, return immediately

                    PUSH DE
                    LD   HL, CLI_command          ; 2. command to the CLI file
                    LD   BC,2                     ;
                    LDIR                          ; copy CLI command to buffer
                    POP  HL                       ; point at CLI command
                    LD   C,2
                    CALL_OZ(Dc_Icl)               ; activate '.S' CLI redirection
                    RET  C

                    LD   BC,1                     ; dummy key read to allow execute CLI
                    CALL_OZ(Os_Tin)
                    LD   A,4
                    CALL_OZ(DC_Rbd)               ; rebind stream to T-output screen, file
                    CP   A
                    RET


; ******************************************************************
;
.CloseLogFile       LD   IX,0                     ; close file and quit CLI.
                    LD   A,4                      ; T-output code
                    CALL_OZ(Dc_Rbd)
                    RET


.CLI_file           DEFM "/eprlog", 0            ; standard CLI logfile 1, 5 bytes long
.CLI_command        DEFM ".S", 0

.Progaddrerrmsg     defm "Programming error at ", 0
.Progerrmsg         defm "Programming of card failed.", 13, 10, 0
.Battlowmsg         defm "Batteries are low. ", 13, 10, 0
.Completedmsg       defm "Test completed successfully.", 13, 10, 0
.CardNotFound       defm "Flash Card not found in slot 3.", 13, 10, 0
.formatmsg          defm "Formatting block ", 0
.formaterrmsg       defm "Could not format blok ", 0
.ProgramMsg         defm "Programming Card...", 13, 10, 0
.ProgramBankMsg     defm "Programming Bank ", 13, 10, 0
.Verifymsg          defm "Verifying Card contents... ", 13, 10, 0
.VerifyBankMsg      defm "Verifying Bank ", 0
.VerifyErrmsg       defm "Card was not blown properly, or slot connection is bad.", 13, 10, 0

.Donemsg            defm "OK", 13, 10, 0
.Dotsmsg            defm "... ", 0

.Errormsg           defm "ERROR", 13, 10, 0
.vdu                defm 1, "3+CS", 0
