; **************************************************************************************************
; This file is part of the Z88 FlashTest application.
;
; FlashTest is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; FlashTest is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashTest;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
;***************************************************************************************************

     MODULE FlashTest

     ORG $C000

     lib FlashEprWriteBlock
     lib FlashEprWriteByte, MemReadByte
     lib MemDefBank
     lib CreateWindow, GreyApplWindow
     lib IntHex

     lib FlashEprCardId, FlashEprCardData, FlashEprBlockErase
     xref RamTest

     xdef FlashTest_DOR

     include "stdio.def"
     include "fileio.def"
     include "flashepr.def"
     include "integer.def"
     include "director.def"
     include "dor.def"
     include "memory.def"
     include "error.def"
     include "time.def"
     include "syspar.def"


; small workspace at bottom of Stack frame...
DEFVARS $1800
{
     MenuPosition        ds.w 1
     MenuSize            ds.w 1
     MenuPrompt          ds.w 1
     MenuBanner          ds.w 1
     MenuWindow          ds.w 1
     LogFileHandle       ds.w 1                   ; preserve the handle of the log file
     ErrorFlag           ds.b 1                   ; Global Error Condition Flag
     ExtAddr             ds.p 1
     testtime            ds.b 4
     flashtype           ds.b 1
     totbanks            ds.b 1
     Buffer              ds.b 32
}

IF !DEBUG

; DOR is at bottom bank ($C000)
.FlashTest_DOR
                    DEFB 0, 0, 0                  ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                      ; DOR type - application ROM
                    DEFB DOREnd0-DORStart0        ; total length of DOR
.DORStart0          DEFB '@'                      ; Key to info section
                    DEFB InfoEnd0-InfoStart0      ; length of info section
.InfoStart0         DEFW 0                        ; reserved...
                    DEFB 'T'                      ; application key letter (T for test)
                    DEFB 0                        ;
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW 0                        ; Safe workspace
                    DEFW FlashTest_AppEntry       ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (none)
                    DEFB 0                        ; bank binding to segment 1 (none)
                    DEFB 0                        ; bank binding to segment 2 (none)
                    DEFB $3F                      ; bank binding to segment 3
                    DEFB AT_Popd                  ; Good application
                    DEFB 0                        ; no caps lock on activation
.InfoEnd0           DEFB 'H'                      ; Key to help section
                    DEFB 12                       ; total length of help
                    DEFW FlashTest_DOR
                    DEFB $3F                      ; point to topics (none)
                    DEFW FlashTest_DOR
                    DEFB $3F                      ; point to commands (none)
                    DEFW FlashTest_Help
                    DEFB $3F                      ; point to help
                    DEFW FlashTest_DOR
                    DEFB $3F                      ; point to token base
                    DEFB 'N'                      ; Key to name section
                    DEFB NameEnd0-NameStart0      ; length of name
.NameStart0         DEFM "FlashTest",0
.NameEnd0           DEFB $FF
.DOREnd0

.FlashTest_Help     DEFM $7F
                    DEFM "Flash Card Testing Tool for",$7F
                    DEFM "Intel I28F00xS5, Amd compatible 29F0xxB devices", $7F
                    DEFM $7F
endif
.progversion_msg
                    DEFM "Release V1.4.1, (C) G. Strube, Apr 2010", 0

; ******************************************************************************
;
.FlashTest_AppEntry

                    CALL CheckFlashCard
                    JP   C, exit_application ; no Eprom in slot 3...

                    CALL EprTestWindow       ; Create Window with banner

                    LD   HL, Release_msg
                    CALL_OZ(Gn_Sop)
                    LD   HL, progversion_msg
                    CALL_OZ(Gn_Sop)
                    CALL_OZ(Gn_Nln)
                    CALL_OZ(Gn_Nln)

                    LD   HL, check_msg
                    CALL_OZ(Gn_Sop)          ; user must enter 'asdf' or press ESC to abort
                    LD   HL,Buffer
                    LD   (HL),0
                    EX   DE,HL

                    LD   A,@00100011
                    LD   BC,$2000
                    LD   L,$20
                    CALL_OZ gn_sip           ; the actual keyboard input...
                    JP   C, exit_application

                    LD   HL, Buffer          ; validate the input
                    LD   DE, inputvalidate   ; with the 'asdf' sequence
.check_loop
                    LD   A,(DE)
                    OR   A
                    JR   Z, start_flashtest  ; found the zero byte terminator, user input OK
                    CP   (HL)
                    INC  HL
                    INC  DE
                    JR   Z, check_loop      ; match found, check next letter.
                    JP   exit_application

.start_flashtest
                    CALL CreateLogFile       ; Create CLI "/eprlog"

                    CALL_OZ(Gn_Nln)
                    CALL_OZ(Gn_Nln)

                    CALL Get_time
                    CALL FlashCardTest
                    CALL Display_testtime

                    CALL CloseLogFile        ; Terminate CLI re-direction...

                    CALL_OZ(Gn_Nln)
                    LD   HL,fltst_logmsg
                    CALL Display_string

                    LD   HL,pressQkey_msg
                    CALL Display_string      ; And the additional 'Press any key to continue' message
.wait_q_key
                    CALL_OZ os_in
                    JR   NC,check_q
                    CALL Erh
                    JR   wait_q_key
.check_q
                    CP   'q'
                    JP   Z, exit_application
                    CP   'Q'
                    JP   Z, exit_application
                    JR   wait_q_key


; *************************************************************************************

.inputvalidate      DEFM "asdf", 0
.check_msg          DEFM "This will erase your flash chip in slot 3.", 13, 10
                    DEFM "Type ESC to QUIT, or enter ", 1, "Basdf", 1, "B ", 1, SD_ENT
                    DEFM " to acknowledge the test.", 13, 10, 0


; ******************************************************************
; Perform the test of the inserted Flash Card...
;
.FlashCardTest
                    XOR  A
                    LD   (ErrorFlag),A                 ; initialize to no errors.

; Identify, if a Flash Eprom Card is inserted in slot 3
                    LD   HL, fe_found_msg
                    CALL_OZ(Gn_sop)                    ; display chip information
                    CALL FlashEprInfo
                    JP   C, FlashEpr_not_found
                    PUSH HL
                    EX   DE,HL
                    CALL_OZ(Gn_sop)                    ; display chip information
                    CALL_OZ(Gn_Nln)
                    CALL_OZ(Gn_Nln)
                    POP  HL

; Flash Eprom Card available in slot 3,
; now format all 16 blocks on the card...
.format_card
                    LD   A,(totbanks)
                    LD   B,A
                    CALL FormatCard
                    RET  C

; all blocks formatted, now program all blocks with 0's
; (all bits reset)
                    CALL TestDataBus                   ; test bit D0-D7 of databus
                    RET  C

                    CALL TestAddressLines              ; test address lines A0-A19
                    LD   A,(ErrorFlag)
                    OR   A
                    RET  NZ

                    CALL ProgramCard
                    LD   A,(ErrorFlag)
                    OR   A
                    JP   NZ, program_err

; finally, reset the card again...
                    LD   A,(totbanks)
                    LD   B,A
                    CALL FormatCard
                    RET  C

                    LD   A,(totbanks)
                    CP   32                            ; 512K chip?
                    JR   Z, PollForRam
                    OR   A                             ; No, dont check for RAM, return Fc = 0
                    RET
                    
; ***************************************************************************************************************                    
.PollForRam
                    LD   D,3
                    LD   E,0                           ; check $C0 (bottom of slot 3) and upwards for RAM bank
                    CALL PollForRam_loop
                    INC  E
                    DEC  E
                    JR   Z, test_completed             ; No RAM found - Flash Card test completed..
                    LD   B,E
                    PUSH BC                            ; B = banks of RAM to be tested...
                    
                    LD   H,0
                    LD   L,E
                    ADD  HL,HL
                    ADD  HL,HL
                    ADD  HL,HL
                    ADD  HL,HL                         ; Banks * 16 = Size of RAM in K
                    PUSH HL
                    POP  BC
                    LD   HL,2
                    LD   DE,buffer
                    PUSH DE
                    OZ   GN_Pdn
                    XOR  A
                    LD   (DE),A
                    POP  HL
                    OZ   GN_NLn
                    OZ   Gn_Sop
                    LD   A,'K'
                    OZ   OS_Out
                    LD   HL, ramcard_found_msg
                    OZ   Gn_Sop
                    
                    LD   HL, ramtest_prompt_msg
                    LD   DE, no_msg                    ; default 'No' to do RAM test
                    CALL YesNo
                    POP  BC
                    JR   NZ, test_completed

                    LD   HL, ramtesting_msg                    
                    OZ   Gn_Sop
                    CALL RamTest                       ; test B banks of RAM
.check_ramtest
                    OR   A
                    JR   Z, RAM_test_completed         ; A=0, RAM test completed successfully..

                    LD   A, B
                    AND  @00111111
                    LD   (ExtAddr),A
                    RES  7,H
                    RES  6,H
                    LD   (ExtAddr+1),HL                ; failed RAM test ext. address...

                    LD   HL,ramtestfailed_msg
                    OZ   Gn_Sop
                    CALL DispExtAddr
                    CALL_OZ(Gn_Nln)
                    RET
.PollForRam_loop
                    LD   BC,NQ_Slt
                    OZ   OS_Nq                         ; get bank type information
                    AND  [BU_WRK | BU_FIX | BU_RES | BU_APL | BU_FRE]
                    JR   NZ, ram_bank
                    RET                                ; E = total of banks found as a RAM related types
.ram_bank
                    INC  E
                    JR   PollForRam_loop
.RAM_test_completed
                    LD   HL, RamCompletedmsg                    
                    CALL_OZ Gn_Sop
.test_completed
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
; The Flash Eprom Card was not identified in slot 3
.FlashEpr_not_found
                    ; Display error message, wait for a key press, and exit
                    LD   HL, CardNotFound
                    CALL_OZ Gn_Sop
                    RET


; ******************************************************************
; Test that databus pins work (D0-D7).
; We're using XX0000 (bottom of chip on slot) as test address.
;
.TestDataBus
                   LD   A,(totbanks)
                   LD   C,A                 ; Total of banks on card
                   LD   A,$FF               ; Get bottom bank of chip in slot 3 (0xC0 for 1Mb, 0xE0 for 512K)
                   SUB  C
                   INC  A
                   LD   B,A                 ; begin test at bottom bank of flash chip
                   LD   HL,0

; ******************************************************************
; Byte Write test at (BHL).
; Return Fc = 1 if failure.
;
.WriteByte
                    LD   C,$FF
                    LD   D,8                 ; loop count, D0-D7
                    CALL VerifyByte          ; Make sure that memory at (BHL) is $FF before we begin..
                    JR   Z, blow_datapin
.EmptyErrorMsg
                    PUSH HL
                    LD   A, B
                    AND  @00111111
                    LD   (ExtAddr),A
                    RES  7,H
                    RES  6,H
                    LD   (ExtAddr+1),HL      ; save ext. address...
                    LD   HL, ByteNotEmptyErrMsg
                    CALL_OZ(Gn_Sop)

                    CALL DispExtAddr
                    CALL_OZ(Gn_Nln)
                    POP  HL
                    SCF
                    RET
.databus_loop
                    CALL VerifyByte
                    JR   Z, blow_datapin
.VerifyErrorMsg
                    PUSH HL
                    LD   A, B
                    LD   (ExtAddr),A
                    RES  7,H
                    RES  6,H
                    LD   (ExtAddr+1),HL
                    LD   HL, VerifyErrMsg
                    CALL_OZ(Gn_Sop)

                    CALL DispExtAddr
                    LD   HL, Verify2ErrMsg
                    CALL_OZ(Gn_Sop)
                    POP  HL
                    PUSH HL
                    CALL MemReadByte
                    CALL DispHex8Number
                    LD   HL, Verify3ErrMsg
                    CALL_OZ(Gn_Sop)
                    LD   A,C
                    CALL DispHex8Number
                    CALL_OZ(Gn_Nln)
                    POP  HL
                    SCF
                    RET
.blow_datapin
                    SLA  C                   ; write bit pattern D0-D7, from bit 0 towards bit 7
                    LD   A,C
                    EX   AF,AF'
                    LD   A,(flashtype)       ; use current flash card programming algorithm...
                    EX   AF,AF'
                    CALL FlashEprWriteByte
                    JR   NC, next_datapin
                    CALL AddrProgErrorMsg    ; byte wasn't blow properly!
                    RET
.next_datapin
                    DEC  D                   ; all 8 bits written?
                    JR   NZ,databus_loop
                    RET


; ******************************************************************
; Verify that BHL address contains empty byte
;
; IN:
;    BHL = address of Flash Card
;    C = verify bit pattern
; OUT:
;    Fz = 1, byte at (BHL) is equal to C
;    Fz = 0, byte contains data.
;
.VerifyByte
                    XOR  A                   ; read byte at (BHL) (no offset)
                    CALL MemReadByte
                    CP   C
                    RET


; ******************************************************************
; Test that that all address lines may be selected by blowing
; a byte (all bits) to each boundary (A0-A19) address line.
;
; Write Error message when failure...
;
.TestAddressLines
                    LD   C,3
                    CALL FlashEprCardId
                    RET  C                   ; no Flash Card in slot 3...

                    LD   B,$FF               ; B = top of slot 3
.test_nextbank_loop
                    LD   HL, testaddrline_msg
                    CALL_OZ(Gn_Sop)

                    LD   A,B
                    AND  @00111111           ; display relative bank number
                    CALL DispHex8Number
                    CALL_OZ(GN_nln)
                    LD   HL,1                ; begin with address pin 0 for each bank
.test_nextoffset_loop
                    LD   C,$FF
                    CALL VerifyByte          ; Make sure that memory at (BHL) is $FF before we begin..
                    CALL C,EmptyErrorMsg

                    LD   C,@10101010
                    LD   A,C
                    EX   AF,AF'
                    LD   A,(flashtype)       ; use the correct flash card programming
                    EX   AF,AF'
                    CALL FlashEprWriteByte
                    CALL C,SetErrorFlag      ; indicate global error condition
                    CALL VerifyByte
                    CALL C,SetErrorFlag      ; indicate global error condition
                    CALL C,VerifyErrorMsg
                    ADD  HL,HL               ; next address pin
                    BIT  6,H                 ; A0-A14 tested?
                    JR   Z, test_nextoffset_loop

                    DEC  B                   ; A15-A19 tested?

                    LD   A,(totbanks)
                    LD   C,A                 ; Total of banks on card
                    LD   A,$FF               ; Get bottom bank-1 of chip in slot 3 (ie. 0xBF for 1Mb, 0xDF for 512K)
                    SUB  C

                    CP   B                   ; tested bottom bank of slot 3?
                    JR   NZ,test_nextbank_loop
                    RET                      ; return Fc = 0...
.testaddrline_msg   DEFM "Test address lines in Bank ",0


; ******************************************************************
;
.ProgramCard
                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-512
                    ADD  IX,SP               ; IX points at start of buffer
                    LD   SP,IX               ; 512 byte buffer created...
                    PUSH HL                  ; preserve original SP

                    LD   BC,512
                    PUSH IX
                    POP  HL
.null_buffer
                    LD   (HL),0
                    INC  HL
                    DEC  BC
                    LD   A,B
                    OR   C
                    JR   NZ, null_buffer     ; (buffer) = 0

                    LD   A,(totbanks)
                    LD   C,A                 ; C = Total of banks on card
                    LD   A,$FF
                    SUB  C
                    INC  A
                    LD   B,A                 ; start programming bottom bank of flash chip

                    XOR  A
                    LD   (ErrorFlag),A       ; reset error flag
.prog_card_loop
                    PUSH BC
                    PUSH HL
                    LD   HL, ProgramBankMsg
                    CALL_OZ Gn_Sop
                    LD   A,B
                    AND  @00111111           ; display relative bank numbers...
                    CALL DispHex8Number
                    LD   HL, Dotsmsg
                    CALL_OZ Gn_Sop
                    POP  HL
                    POP  BC

                    LD   E, 32               ; blow 32 * 512 = 16K...
                    LD   HL, $8000           ; start of bank (of B) in segment 2
.prog_bank_loop
                    PUSH DE
                    PUSH BC

                    PUSH IX
                    POP  DE                  ; blow source block to Flash Card Bank
                    LD   IY, 512
                    LD   A,(flashtype)       ; use the correct Flash Card type...
                    CALL FlashEprWriteBlock
                    POP  BC                  ; HL updated to point at next block...
                    CALL C, SetErrorFlag
                    CALL C, AddrProgErrorMsg ; display address of programming error

                    POP  DE
                    DEC  E
                    JR   NZ, prog_bank_loop

                    PUSH HL
                    LD   HL, Donemsg
                    CALL_OZ Gn_Sop
                    POP  HL

                    INC  B                   ; ready for next bank
                    DEC  C                   ; one bank less to program...
                    JR   NZ, prog_card_loop
.exit_programming                            ; all banks manipulated
                    POP  HL
                    LD   SP,HL               ; restore original Stack Pointer
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
; Display error message and ext. address (in BHL) of programming error
;
.AddrProgErrorMsg
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

                    CALL DispExtAddr
                    CALL_OZ(Gn_Nln)

                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET


; ******************************************************************
;
.DispHex8Number
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    LD   (ExtAddr),A
                    LD   BC,1                ; 8bit integer...
                    LD   HL, ExtAddr
                    LD   DE, Buffer          ; ptr to Ascii result...
                    CALL IntHex
                    EX   DE,HL
                    CALL_OZ Gn_Sop
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; ******************************************************************
;
.DispExtAddr
                    PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   A,(ExtAddr)
                    AND  @00111111
                    CALL DispHex8Number

                    LD   BC,2
                    LD   HL,ExtAddr+1
                    LD   DE, Buffer
                    CALL IntHex

                    EX   DE,HL
                    CALL_OZ(Gn_Sop)          ; Display offset address in hex

                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
                    RET


; ******************************************************************
;
; Format the Flash Eprom Card
;
; In:
;     B = total bank on card.
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

                    SRL  B
                    SRL  B                   ; B = returned number of sectors on card
.format_loop

                    PUSH BC
                    PUSH HL
                    LD   HL, formatmsg
                    CALL_OZ Gn_Sop           ; "Formatting sector "
                    LD   C,B
                    LD   B,0
                    DEC  C                   ; actual sector...
                    CALL IntAscii
                    LD   HL, buffer
                    CALL_OZ Gn_Sop           ; Display sector number...
                    LD   HL, Dotsmsg
                    CALL_OZ Gn_sop
                    POP  HL
                    POP  BC

                    LD   C,3                 ; slot 3
                    DEC  B                   ; actual block to erase
                    CALL FlashEprBlockErase  ; slot 3...
                    JR   NC, format_ok
.format_err
                    PUSH AF
                    LD   HL, Errormsg        ; The sector (identified in B register) couldn't be formatted
                    CALL_OZ Gn_Sop
                    LD   HL, formaterrmsg
                    CALL_OZ Gn_Sop
                    LD   C,B
                    LD   B,0
                    CALL IntAscii
                    LD   HL, buffer
                    CALL_OZ Gn_Sop
                    CALL_OZ Gn_Nln
                    POP  AF
                    JR   exit_format
.format_ok
                    INC  B                   ; number of blocks left to erase...

                    PUSH HL
                    LD   HL, donemsg
                    CALL_OZ Gn_Sop
                    POP  HL

                    DEC  B                   ; next block...
                    JR   NZ, format_loop     ; format next block
.exit_format
                    POP  HL
                    POP  DE
                    RET


; ***************************************************************
;
.EprTestWindow
                    LD   A, 64 | '2'
                    LD   BC, $0015
                    LD   DE, $0845
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


; ************************************************************************************************
; Fetch Intel Flash Eprom Device Code and return information of chip.
;
; IN:
;    None.
;
; OUT:
;    Fc = 0, Flash Eprom Recognized in slot 3
;         B = total of banks on Flash Eprom
;         (totbanks) = total of banks on Flash Eprom
;         DE = pointer to Mnemonic description of Flash Eprom
;         HL = Flash Memory ID
;              H = Manufacturer Code (FE_INTEL_MFCD, FE_AMD_MFCD)
;              L = Device Code
;    Fc = 1, Flash Eprom not found in slot 3, or Device code not found
;
.FlashEprInfo       LD   C,3
                    CALL FlashEprCardId
                    RET  C
                    PUSH BC
                    LD   (flashtype),A            ; remember Flash Card type...
                    LD   A,B
                    LD   (totbanks),A

                    CALL FlashEprCardData
                    POP  BC
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


; ************************************************************************************************
; Check presence of Flash Eprom in slot 3
;
.CheckFlashCard     LD   C,3
                    CALL FlashEprCardId
                    RET  NC

                    LD   A,3                      ; FE not available
                    CALL Write_Err_msg
                    SCF
                    RET




; **********************************************************************************************************
;
.DisplayMenu        PUSH HL
                    PUSH DE
                    PUSH BC
                    PUSH AF
                    EXX
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    EXX
                    EX   AF,AF'
                    PUSH AF
                    EX   AF,AF'
                    CALL GreyApplWindow                 ; tone application area to grey before displaying the menu
                    LD   A, 192 | '4'                   ; use window ID '4'
                    LD   BC,(MenuPosition)              ; position of menu
                    LD   DE,(MenuSize)                  ; get menu window size
                    LD   HL,(MenuBanner)                ; pointer to menu banner
                    CALL CreateWindow                   ; display the menu window
                    LD   HL,CentreJustify               ; centre justify the window
                    CALL Display_string
                    LD   HL,(MenuPrompt)                ; get the menu prompt and
                    CALL_OZ(Gn_Sop)                     ; display in menu window
                    EX   AF,AF'
                    POP  AF
                    EX   AF,AF'
                    EXX
                    POP  HL
                    POP  DE
                    POP  BC
                    EXX
                    POP  AF
                    POP  BC
                    POP  DE
                    POP  HL
                    RET
.CentreJustify      DEFM 1, "2-C", 1, "2JC", 1, "3@", 32, 32, 0     ; centre justify and put cursor at top line


; ******************************************************************************
;
; Display a string in current window at cursor position
;
; IN: HL points at string.
;
;
.Display_String     PUSH HL
                    CALL_OZ(Gn_Sop)                      ; write string
                    POP  HL
                    RET

; *****************************************************************************************************
; Standard error message window routine
;
.Write_err_msg      PUSH BC
                    PUSH DE
                    PUSH HL
                    CALL SetupErrWindow
                    CALL DispErrWindow                  ; display error (menu) window with error message
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


.DispErrWindow      LD   HL, ErrWindow                  ; Zprom Wman. is now aware of this menu...
                    LD   (MenuWindow),HL
                    CALL ErrWindow
                    CALL Get_ESC_key
                    RET

.ErrWindow          CALL DisplayMenu
                    LD   HL,ESCPrompt
                    CALL Display_string                 ; And the additional 'Press ESC to resume' message
                    RET


; ***********************************************************************************************************
; Error opcode in A
;
.SetupErrWindow     LD   HL,$0120                       ; postion of error window
                    LD   (MenuPosition),HL
                    LD   HL,$0530                       ; size of error window
                    LD   (MenuSize),HL
                    CALL Get_errmsg                     ; return pointer to err. msg from opcode in A
                    LD   (MenuPrompt),HL                ; pointer to prompt (error message)
                    LD   HL,Error_banner                ; pointer to menu banner
                    LD   (MenuBanner),HL
                    RET

; **********************************************************************************************************
;
;    Display report and wait for a key press
;
;    IN:  BC = window position
;         DE = size of window
;         HL = pointer to null-terminated prompt, message
;         IX = window banner
;
.ReportWindow       LD   (MenuPrompt),HL               ; prompt parameter saved
                    LD   (MenuSize),DE                 ; size of window parameter stored
                    LD   (MenuPosition),BC             ; window position parameter saved
                    LD   (MenuBanner),IX               ; window banner parameter stored
                    CALL DispKeyWindow                 ; display window with message and
                    RET                                ; wait for a key to pressed


; **********************************************************************************************************
;
.DispKeyWindow      LD   HL,KeyWindow
                    LD   (MenuWindow),HL                ; Zprom Wman. is now aware of this menu...
                    CALL KeyWindow
                    CALL ReadKeyboard
                    RET
.KeyWindow          CALL DisplayMenu
                    LD   HL,KeyPrompt
                    CALL Display_string                 ; And the additional 'Press any key to continue' message
                    RET


; ******************************************************************************************
.ReadKeyboard       CALL_OZ(Os_In)
                    CALL C,ERH
                    RET


; ******************************************************************************************
;
; Error handler
;
.ERH
                    CP   RC_QUIT
                    JR   Z,exit_application
                    CP   RC_ESC
                    JR   Z, ackn_esc
                    XOR  A                              ; ignore rest of errors
                    RET
.exit_application   XOR  A
                    CALL_OZ(Os_Bye)                     ; kill Zprom and return to Index
                    JR   exit_application
.ackn_esc           EXX
                    PUSH HL
                    PUSH DE
                    PUSH BC
                    EXX
                    EX   AF,AF'
                    PUSH AF
                    EX   AF,AF'                         ; A = RC_ESC...
                    CALL_OZ(Os_Esc)                     ; acknowledge ESC key
                    EX   AF,AF'
                    POP  AF
                    EX   AF,AF'
                    EXX
                    POP  BC
                    POP  DE
                    POP  HL
                    EXX
                    LD   A,IN_ESC                       ; ESC were pressed
                    CP   A                              ; Fc = 0 ...
                    RET

.Get_ESC_key        CALL ReadKeyboard
                    CP   27
                    JR   NZ, Get_esc_key
                    RET


; ******************************************************************************
;
; Return pointer to error message from code in A
;
.Get_errmsg         PUSH AF
                    PUSH DE
                    LD   HL, Errmsg_lookup
                    LD   D,0
                    LD   E,A
                    SLA  E                                ; word boundary
                    ADD  HL,DE                            ; HL points at index containing pointer
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)                           ; pointer fetched in
                    EX   DE,HL                            ; HL
                    POP  DE
                    POP  AF
                    RET

; ******************************************************************
;
.CloseLogFile       LD   IX,0                     ; close file and quit CLI.
                    LD   A,4                      ; T-output code
                    CALL_OZ(Dc_Rbd)
                    RET

; ***********************************************************************
;
.Get_time           LD   C,0
                    LD   DE,0
                    CALL_OZ(GN_Gmt)                    ; current internal machine time
                    LD   (testtime),BC
                    LD   (testtime+2),A                ; current machine time
                    RET                                ; in ABC


; ***********************************************************************
;
.Display_testtime   PUSH AF
                    LD   C,0
                    LD   DE,0
                    CALL_OZ(GN_Gmt)                    ; current internal machine time
                    LD   H,B
                    LD   L,C
                    LD   BC,(testtime)
                    SBC  HL,BC
                    LD   D,A
                    LD   A,(testtime+2)                ; elapsed time = current - previous
                    LD   E,A
                    LD   A,D
                    SBC  A,E
                    LD   (testtime),HL
                    LD   (testtime+2),A                ; AHL = elapsed time in centiseconds

                    LD   BC, NQ_OHN
                    CALL_OZ(Os_Nq)                     ; get handle in IX for standard output

                    LD   HL, time1_msg
                    CALL_OZ(Gn_Sop)                    ; "Tested in '
                    LD   DE,0                          ; write time to window...
                    LD   HL, testtime                  ; pointer to internal time
                    LD   A, @00110111                  ; time display format
                    CALL_OZ(Gn_Ptm)                    ; display elapsed time...
                    LD   HL, time2_msg
                    CALL_OZ(Gn_Sop)
                    CALL_OZ(Gn_Nln)
                    POP  AF
                    RET

; *************************************************************************************
;
.yesno
                    LD   BC, yesno_loop
                    PUSH BC
                    JP   (HL)                ; call display message
.yesno_loop         LD   H,D
                    LD   L,E
                    OZ   gn_sop
                    OZ   OS_Pur              ; make sure no keys in sys. inp. buffer...
                    CALL rdch
                    JR   C,yesno_loop        ; ignore pre-emption...
                    CP   IN_ESC
                    JR   Z, abort_yesno
                    CP   13
                    JR   NZ,yn1
                    LD   HL,yes_msg
                    SBC  HL,DE               ; Yes, Fc = 0, Fz = 1
                    RET  Z
                    OR   A                   ; No, Fc = 0, Fz = 0
                    RET
.abort_yesno
                    OR   A                   ; ESC pressed
                    RET                      ; return Fc = 0, Fz = 0
.yn1
                    OR   32
                    CP   'y'
                    JR   NZ,yn2
                    LD   DE,yes_msg
                    JR   yesno_loop
.yn2                                          ; all other keypressed means 'No'...
                    LD   DE,no_msg
                    JR   yesno_loop
; *************************************************************************************

; *************************************************************************************
;
.rdch
                    CALL_OZ os_in
                    JR   NC,rd2
                    CP   RC_ESC
                    JR   Z, ret_esc
                    SCF
                    RET
.ret_esc
                    LD   A, IN_ESC
                    RET
.rd2
                    CP   0
                    RET  NZ
                    CALL_OZ os_in
                    RET
; *************************************************************************************

.ramtest_prompt_msg
                    LD   HL, ramtest_msg
                    CALL_OZ gn_sop
                    RET


; ***********************************************************************************************
; Text constants
; ***********************************************************************************************
.time1_msg          DEFM "Flash Card tested in", 0
.time2_msg          DEFM "minutes", 0

.CLI_file           DEFM "/eprlog", 0            ; standard CLI logfile 1, 5 bytes long
.CLI_command        DEFM ".S", 0

.yes_msg            DEFM 13,1,"2+C Yes",8,8,8,0
.no_msg             DEFM 13,1,"2+C No ",8,8,8,0

.ramcard_found_msg  DEFM " RAM found.", 13, 10, 0
.ramtest_msg        DEFM "Execute RAM test? ", 13, 10, 0
.ramtesting_msg     DEFM "Testing RAM...", 13, 10, 0
.ramtestfailed_msg  DEFM "RAM test failed at address ",0

.ByteNotEmptyErrMsg defm "Byte not empty at address ",0
.VerifyErrMsg       defm "Byte program verify error: (", 0
.Verify2ErrMsg      defm ")=", 0
.Verify3ErrMsg      defm ", but should have been ", 0
.Progaddrerrmsg     defm "Programming of byte failed at ", 0
.Progerrmsg         defm "Programming of card failed.", 13, 10, 0
.RamCompletedmsg    defm 1, "BSuccessfully tested RAM memory with no errors.", 1, "B", 13, 10, 0
.Completedmsg       defm 1, "BTest of Flash Card completed successfully with no errors.", 1, "B", 13, 10, 0
.CardNotFound       defm 1, "BFlash Card was not found in slot 3.", 1, "B", 13, 10, 0
.formatmsg          defm "Formatting sector ", 0
.formaterrmsg       defm "Could not format sector ", 0
.ProgramBankMsg     defm "Programming Bank ", 0
.report_banner      DEFM "Report:", 0
.fltst_logmsg       DEFM "A copy of the messages are available in ", '"', "/eprlog", '"', " file.", 13, 10, 0
.Error_banner       DEFM "Error:", 0
.fe_found_msg       DEFM "The following Flash chip was found in slot 3:", 13, 10, 0
.pressQkey_msg      DEFM 1, "F", "Press Q to quit FlashTest", 1, "F", 13, 10, 0

.Donemsg            defm "OK", 13, 10, 0
.Dotsmsg            defm "... ", 0

.Errormsg           defm "ERROR", 13, 10, 0
.vdu                defm 1, "3+CS", 0

.ESCPrompt          DEFM 1, "2JC", 1, "3@", 32, 34
                    DEFM 1, "F", "Press ", 1, $E4, " to resume", 1, "F"
                    DEFM 1, "2JN", 0

.KeyPrompt          DEFM 1, "2JC", 1, "3@", 32, 34
                    DEFM 1, "F", "Press any key to continue", 1, "F"
                    DEFM 1, "2JN", 0


.Errmsg_lookup      DEFW Error_msg_00
                    DEFW Error_msg_01
                    DEFW Error_msg_02
                    DEFW Error_msg_03

.Error_msg_00       DEFM "Byte incorrectly blown in Flash Card at ", 0
.Error_msg_01       DEFM 0
.Error_msg_02       DEFM "Flash Card Sector couldn't be formatted.", 0
.Error_msg_03       DEFM "Flash Card was not found in slot 3.", 0

.Release_msg
                    DEFM "Flash Card Testing Tool for", 13, 10
                    DEFM "Intel I28F00xS5 and Amd compatible 29F0xxB devices", 13, 10, 0
