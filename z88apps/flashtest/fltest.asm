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

     lib FlashEprBlockErase, FlashEprWriteBlock
     lib FlashEprCardId, FlashEprWriteByte
     lib CheckBattLow
     lib CreateWindow, GreyApplWindow
     lib IntHex

     xdef FlashTest_DOR
     
     include "stdio.def"
     include "fileio.def"
     include "flashepr.def"
     include "integer.def"
     include "director.def"
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
     LogFileHandle       ds.w 1              ; preserve the handle of the log file
     ErrorFlag           ds.b 1              ; Global Error Condition Flag
     ExtAddr             ds.p 1
     testtime            ds.b 4
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
                    DEFB @00000001                ; Good application
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
                    DEFM "Intel I28F00xS5 and Amd AM29F0x0B devices", $7F
                    DEFM $7F
                    DEFM "Release V1.1, (C) G. Strube, November 2004", 0
endif

; ******************************************************************************
;
.FlashTest_AppEntry
                    
                    CALL CheckFlashCard
                    JP   C, exit_application ; no Eprom in slot 3...

                    CALL EprTestWindow       ; Create Window with banner

                    LD   HL, Release_msg                    
                    CALL_OZ(Gn_Sop)

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

                    LD   HL,presskey_msg
                    CALL Display_string      ; And the additional 'Press any key to continue' message

                    CALL_OZ(OS_In)
                    JP   exit_application

.inputvalidate      DEFM "asdf", 0
.check_msg          DEFM "This will erase your flash chip in slot 3.", 13, 10
                    DEFM "Type ESC to QUIT, or enter ", 1, "Basdf", 1, "B ", 1, SD_ENT
                    DEFM " to acknowledge the test.", 13, 10, 0


; ******************************************************************
; Perform the test of the inserted Flash Card...
;
.FlashCardTest

; Identify, if a Flash Eprom Card is inserted in slot 3
                    CALL CheckBatteries
                    RET  C

                    LD   HL, fe_found_msg
                    CALL_OZ(Gn_sop)                    ; display chip information
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
; The sector (identified in B register) couldn't be formatted
.format_err
                    LD   HL, Errormsg
                    CALL_OZ Gn_Sop
                    LD   HL, formaterrmsg
                    CALL_OZ Gn_Sop
                    LD   C,B
                    LD   B,0
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
;
.ProgramCard        XOR  A
                    LD   (ErrorFlag),A

                    CALL CheckBatteries
                    RET  C                   ; batteries are low - abort...

                    LD   C,3
                    CALL FlashEprCardId
                    LD   C,B                 ; Total of banks on card
                    LD   B,$C0               ; start programming of bank $C0

                    XOR  A
                    LD   (ErrorFlag),A       ; reset error flag
.prog_card_loop
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

                    LD   E, 16               ; blow 10 * 1024 = 16K...
                    LD   HL, 0               ; start of bank (of B)
.prog_bank_loop
                    PUSH DE
                    CALL CheckBatteries
                    JR   C, exit_programming ; batteries low - abort...

                    PUSH BC
                    LD   C, MS_S2            ; blow the 1024 bytes block in segment 2
                    LD   DE, testblock       ; blow source block to Flash Card Bank
                    LD   IY, 1024
                    CALL FlashEprWriteBlock
                    POP  BC
                    CALL C, SetErrorFlag
                    CALL C, AddrProgError    ; display address of programming error
                    LD   DE, 1024
                    ADD  HL,DE               ; ready for next block address on bank

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
; Format the Flash Eprom Card
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

                    CALL FlashEprInfo        ; B = returned number of sectors on card
.format_loop
                    CALL CheckBatteries      ; before a format, check battery status
                    JR   C, exit_format

                    PUSH BC
                    PUSH HL
                    LD   HL, formatmsg
                    CALL_OZ Gn_Sop           ; "Formatting sector "
                    LD   C,B
                    LD   B,0
                    DEC  C                   ; actual sector...
                    CALL IntAscii
                    LD   HL, buffer
                    CALL_OZ Gn_Sop           ; Display block number...
                    LD   HL, Dotsmsg
                    CALL_OZ Gn_sop
                    POP  HL
                    POP  BC

                    LD   C,3                 ; slot 3
                    DEC  B                   ; actual block to erase
                    CALL FlashEprBlockErase  ; slot 3...
                    JR   C, exit_format
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


; ******************************************************************
; Check Battery Status
;
.CheckBatteries
                    CALL CheckBattLow
                    RET  NC
                    PUSH AF
                    PUSH HL
                    LD   A,1                      ; Battery Low.
                    CALL Write_Err_msg
                    POP  HL
                    LD   A,$FF
                    LD   (ErrorFlag),A
                    POP  AF
                    SCF
                    RET


; ************************************************************************************************
; Fetch Intel Flash Eprom Device Code and return information of chip.
;
; IN:
;    None.
;
; OUT:
;    Fc = 0, Flash Eprom Recognized in slot 3
;         B = total of Blocks on Flash Eprom
;         HL = pointer to Mnemonic description of Flash Eprom
;    Fc = 1, Flash Eprom not found in slot 3, or Device code not found
;
.FlashEprInfo       LD   C,3
                    CALL FlashEprCardId
                    RET  C

                    LD   A,L                      ; get Device Code in A.
                    PUSH DE
                    LD   HL, FlashEprTypes
                    LD   DE, 6                    ; each table entry is 6 bytes (3 x 2 16bit words)
                    LD   B,(HL)                   ; no. of Flash Eprom Types in table
                    INC  HL
.find_loop          CP   (HL)                     ; device code found?
                    JR   NZ, get_next
                         INC  HL                  ; points at manufacturer code
                         INC  HL
                         LD   B,(HL)              ; B = total of block on Flash Eprom
                         INC  HL
                         INC  HL                  ; points at mnemonic string description.
                         LD   E,(HL)
                         INC  HL
                         LD   D,(HL)
                         EX   DE,HL               ; HL = pointer to mnemonic string
                         POP  DE
                         RET                      ; Fc = 0, Flash Eprom data returned...
.get_next           ADD  HL,DE
                    DJNZ find_loop                ; point at next entry...
                    SCF
                    POP  DE                       ; Flash Eprom Device Code not recognised
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


; ***********************************************************************************************
; Text constants
; ***********************************************************************************************
.time1_msg          DEFM "Flash Card tested in", 0
.time2_msg          DEFM "minutes", 0

.CLI_file           DEFM "/eprlog", 0            ; standard CLI logfile 1, 5 bytes long
.CLI_command        DEFM ".S", 0

.Progaddrerrmsg     defm "Programming error at ", 0
.Progerrmsg         defm "Programming of card failed.", 13, 10, 0
.Battlowmsg         defm "Batteries are low. ", 13, 10, 0
.Completedmsg       defm 1, "BTest of Flash Card completed successfully with no errors.", 1, "B", 13, 10, 0
.CardNotFound       defm 1, "BFlash Card was not found in slot 3.", 1, "B", 13, 10, 0
.formatmsg          defm "Formatting sector ", 0
.formaterrmsg       defm "Could not format sector ", 0
.ProgramBankMsg     defm "Programming Bank ", 0
.report_banner      DEFM "Report:", 0
.fltst_logmsg       DEFM "A copy of the messages are available in ", '"', "/eprlog", '"', " file.", 13, 10, 0
.Error_banner       DEFM "Error:", 0
.fe_found_msg       DEFM "The following Flash chip was found in slot 3:", 13, 10, 0
.presskey_msg       DEFM 1, "F", "Press any key to continue", 1, "F", 13, 10, 0

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

.FlashEprTypes
                    DEFB 6
                    DEFW FE_I28F004S5, 8, mnem_i004
                    DEFW FE_I28F008SA, 16, mnem_i008
                    DEFW FE_I28F008S5, 16, mnem_i8s5
                    DEFW FE_AM29F010B, 8, mnem_am010b
                    DEFW FE_AM29F040B, 8, mnem_am040b
                    DEFW FE_AM29F080B, 16, mnem_am080b

.mnem_i004          DEFM "INTEL 28F004S5 (512Kb, 8 x 64Kb sectors)", 0
.mnem_i008          DEFM "INTEL 28F008SA (1024Kb, 16 x 64Kb sectors)", 0
.mnem_i8S5          DEFM "INTEL 28F008S5 (1024Kb, 16 x 64Kb sectors)", 0
.mnem_am010b        DEFM "AMD AM29F010B (128Kb, 8 x 16K sectors)", 0
.mnem_am040b        DEFM "AMD AM29F040B (512Kb, 8 x 64K sectors)", 0
.mnem_am080b        DEFM "AMD AM29F080B (1024Kb, 16 x 64K sectors)", 0

.Errmsg_lookup      DEFW Error_msg_00
                    DEFW Error_msg_01
                    DEFW Error_msg_02
                    DEFW Error_msg_03

.Error_msg_00       DEFM "Byte incorrectly blown in Flash Card at ", 0
.Error_msg_01       DEFM "Battery Low - operation aborted", 0
.Error_msg_02       DEFM "Flash Card Sector couldn't be formatted.", 0
.Error_msg_03       DEFM "Flash Card was not found in slot 3.", 0

.Release_msg      
                    DEFM "Flash Card Testing Tool for Intel I28F00xS5 & Amd AM29F0x0B devices", 13, 10
                    DEFM "Release V1.1, (C) G. Strube, November 2004", 13, 10, 13, 10, 0

.testblock          DS 1024