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


     MODULE Zprom_Main

     LIB ToUpper

     XREF MV_command, ME_command, EV_command, ES_command, MS_command, EPROG_command
     XREF RBW_command, BR_command, BE_command, BV_command, RBCL_command
     XREF RCLC_command, COPY_command, CLONE_command
     XREF BS_command
     XREF FPROG_command, FLBE_command, FLI_command, FLTST_command

     XREF EprType_Prompt, StartRange_prompt, EndRange_Prompt, bank_prompt, addr_prompt
     XREF flnm_prompt, Epvf_prompt, Epck_prompt, eprd_prompt, mbs_prompt, mbl_prompt, clear_prompt
     XREF EprType_banner, EprBank_banner, ProgRange_banner, StartRange_banner
     XREF startfile_banner, mrbl_banner, RamBank_banner, mbl_banner, mbs_banner, eprd_banner, report_banner
     XREF epvf_banner, epck_banner, startmbs_banner, endmbs_banner
     XREF mbsfln_banner, mbcl_banner, YesNoPrompt
     XREF Write_Err_Msg, DispErrWindow, Disp_EprAddrError
     XREF ReportWindow
     XREF File_IO_error, File_Buffer_Bndry, Out_of_Bufrange, Illegal_Range, Illegal_Bankref
     XREF Save_not_complete, Syntax_Error, Illegal_hexV
     XREF InpLine, InpSelectLine, PresetBuffer_hex16, PresetBuffer_hex8
     XREF FindItem
     XREF GetItemPtr
     XREF ClearEditBuffer, FetchCurPath
     XREF Bind_in_Bank, Get_Absrange
     XREF Search_Memory, Verify_Eprom, Check_Eprom
     XREF EpromTypes
     XREF ApplWindow, RedrawScreen
     XREF Check_file, Get_file_handle, Close_file
     XREF DisplayMenu
     XREF YesNoWindow
     XREF Get_errmsg
     XREF Error_banner

     XDEF Zprom_entry
     XDEF ClearMemBuffer
     XDEF Readkeyboard
     XDEF Display_char, Display_string, DisplMenuBar
     XDEF GetChar, SkipSpaces, Get_constant, Conv_to_nibble, ConvHexByte
     XDEF IntHexDisp, IntHexDisp_H, IntHexConv
     XDEF Zprom_ERH


     INCLUDE "defs.asm"
     INCLUDE "stdio.def"
     INCLUDE "fileio.def"
     INCLUDE "integer.def"
     INCLUDE "error.def"
     INCLUDE "director.def"



; ****************************************************************************************************
;
; Application entry point
;
.Zprom_entry        JP  Appl_Zprom                      ; run Zprom...
                    SCF                                 ; enquiry entry point for bad application
                    RET                                 ; continious RAM remains allocated...

.Appl_Zprom         LD   A,(IX+$02)                     ; IX points at information block
                    CP   $60                            ; get end page of continious RAM
                    JR   Z, continue_Zprom              ; end page OK, RAM allocated...
                    LD   A,$07                          ; No Room for Zprom, return to Index
                    CALL_OZ(Os_Bye)                     ; Zprom suicide...

.continue_Zprom     CALL InitZprom
.command_loop       CALL ApplWindow                     ; display application windows
                    LD   HL,0                           ; subroutine to redraw a menu window
                    LD   (MenuWindow),HL                ; reset to none.
                    RES  ActvCmd,(IY + 0)               ; Indicate no command is running.
                    CALL DisplMenuBar                   ; adjust menu bar to Menu call...
                    CALL Menu                           ; display menu bar and read keyboard
                    JR   command_loop                   ; for commands


; ******************************************************************************************
;
.Menu
.mainmenu_loop      CALL DisplMenuBar
                    CALL ReadKeyboard                   ; Subr. handles shortcut commands
                    CALL DisplMenuBar
                    BIT  ActvCmd,(IY + 0)               ; Indicate no command is running.
                    RET  NZ                             ; if a shortcut command  was activated...
                    CP   IN_ENT                         ; no shortcut cmd, ENTER ?
                    JR   Z, get_command
                    CP   IN_DWN                         ; Cursor Down ?
                    JR   Z, MVbar_down
                    CP   IN_UP                          ; Cursor Up ?
                    JR   Z, MVbar_up
                    JR   mainmenu_loop                  ; ignore keypress, get another...

.MVbar_down         LD   A,(MenuBarPosn)                ; get Y position of menu bar
                    CP   5                              ; has m.bar already reached bottom?
                    JR   Z,Mbar_topwrap
                    INC  A
                    LD   (MenuBarPosn),A                ; update new m.bar position
                    JR   Menu                           ; display new m.bar position
.Mbar_topwrap       LD   A,0
                    LD   (MenuBarPosn),A
                    JR   Menu

.MVbar_up           LD   A,(MenuBarPosn)                ; get Y position of menu bar
                    CP   0                              ; has m.bar already reached top?
                    JR   Z,Mbar_botwrap
                    DEC  A
                    LD   (MenuBarPosn),A                ; update new m.bar position
                    JR   Menu                           ; display new m.bar position
.Mbar_botwrap       LD   A,5
                    LD   (MenuBarPosn),A
                    JR   Menu

.get_command        SET  ActvCmd,(IY + 0)               ; indicate command is running
                    LD   A,(MenuBarPosn)                ; use menu bar position as index to command
                    CALL ActivateCommand
                    RET                                 ; Return to command loop


; *************************************************************************************
;
.DisplMenuBar       PUSH AF
                    PUSH HL
                    LD   HL,SelectMenuWindow
                    CALL_OZ(Gn_Sop)
                    LD   HL, xypos                      ; (old menu bar will be overwritten)
                    CALL_OZ(Gn_Sop)
                    LD   A,32                           ; display menu bar at (0,Y)
                    CALL_OZ(Os_out)
                    LD   A,(MenuBarPosn)                ; get Y position of menu bar
                    ADD  A,32                           ; VDU...
                    CALL_OZ(Os_out)
                    LD   HL,MenuBar                     ; now display menu bar at cursor
                    CALL_OZ(Gn_Sop)
                    POP  HL
                    POP  AF
                    RET
.xypos              DEFM 1, "3@", 0
.SelectMenuWindow   DEFM 1, "2H2", 0                  ; activate menu window for menu bar control
.MenuBar            DEFM 1, "2+R"                      ; set reverse video
                    DEFM 1, "2E", 32+25               ; XOR 'display' menu bar (25 chars wide)
                    DEFM 1, "2-R", 0                  ; back to normal video



; ******************************************************************************************
.ReadKeyboard       CALL_OZ(Os_In)
                    CALL C,Zprom_ERH
                    CP   0
                    JR   Z,ReadKeyboard                 ; get menu command code
                    CP   $80                            ; key code >= $80 ?
                    RET  C                              ; Yes, not a command code...
                    CP   $9B                            ; key code <= $9A ?
                    RET  NC                             ; No, not a command code...
                    BIT  ActvCmd,(IY + 0)               ; Is a command already running?
                    JR   NZ, active_command             ; Yes, don't execute another!
                    SUB  $80                            ; convert to index value 0 - 10.
                    SET  ActvCmd,(IY + 0)               ; indicate command is running
                    JR   ActivateCommand                ; activate command from index

.active_command     LD   A,7
                    CALL_OZ (Os_Out)                    ; make a warning bleep
                    JR   ReadKeyboard                   ; then get another keypress


; ************************************************************************************************
;
; Activate command defined by index in A
;
.ActivateCommand    RLCA                               ; index word boundary...
                    LD   B,0
                    LD   C,A
                    LD   HL,Command_lookup             ; base of table
                    ADD  HL,BC                         ; point at command index
                    LD   E,(HL)                        ; get pointer to subroutine
                    INC  HL
                    LD   D,(HL)
                    EX   DE,HL                         ; HL points at command subroutine
                    JP   (HL)                          ; activate

.Command_lookup     DEFW MBL_command                   ; $80 CC_mbl    -   Memory Buffer Load
                    DEFW MV_command                    ; $81 CC_mv     -   Memory View
                    DEFW EV_command                    ; $82 CC_ev     -   Eprom View Bank
                    DEFW EB_command                    ; $83 CC_eb     -   Define Eprom Bank
                    DEFW ER_command                    ; $84 CC_er     -   Eprom Programming Range
                    DEFW ET_command                    ; $85 CC_etp    -   Define Eprom Type
                    DEFW EPVF_command                  ; $86 CC_epvf   -   Eprom Verify
                    DEFW ME_command                    ; $87 CC_me     -   Memory Edit
                    DEFW ES_command                    ; $88 CC_es     -   Eprom Search
                    DEFW EPROG_command                 ; $89 CC_eprog  -   Program Eprom
                    DEFW MBS_command                   ; $8A CC_mbs    -   Memory Buffer Save
                    DEFW EPRD_command                  ; $8B CC_eprd   -   Read Eprom
                    DEFW MS_command                    ; $8C CC_ms     -   Memory Search
                    DEFW MBCL_command                  ; $8D CC_mbcl   -   Memory Buffer Clear
                    DEFW EPCK_command                  ; $8E CC_epck   -   Check Eprom
                    DEFW RBW_command                   ; $8F CC_rbw    -   RAM Bank Write
                    DEFW BR_command                    ; $90 CC_br     -   Bank Read
                    DEFW BE_command                    ; $91 CC_be     -   Bank Edit
                    DEFW BV_command                    ; $92 CC_bv     -   Bank View
                    DEFW RBCL_command                  ; $93 CC_rbcl   -   RAM Bank Clear
                    DEFW RCLC_command                  ; $94 CC_rclc   -   RAM Clear Card (all banks in slot)
                    DEFW COPY_command                  ; $95 CC_copy   -   Copy Eprom to RAM card
                    DEFW CLONE_command                 ; $96 CC_clone  -   Clone RAM Card to Eprom
                    DEFW BS_command                    ; $97 CC_bs     -   Bank search
                    DEFW FLBE_command                  ; $98 CC_flbe   -   Flash Eprom Block Erase
                    DEFW FLI_command                   ; $99 CC_fli    -   Flash Eprom Information
                    DEFW FLTST_command                 ; $9A CC_fltst  -   Flash Eprom Testing (hidden feature)


; ************************************************************************************************
; CC_mbl    -   Memory Buffer Load
;
.MBL_command        LD   DE,EditBuffer                  ; set DE to point at edit buffer
                    CALL FetchCurPath                   ; store current directory path into edit buffer
                    LD   A,C                            ; set cursor at end of directory path
                    LD   BC,$0110                       ; display menu at (16,1)
                    LD   DE,flnm_prompt                 ; prompt 'Filename:'
                    LD   HL,mbl_banner                  ; 'Load file into buffer'
                    SET  GetMail,(IY + 0)               ; mail from Filer is allowed...
                    CALL InpLine                        ; enter a filename
                    RES  GetMail,(IY + 0)
                    CP   IN_ESC                         ; <ESC> pressed during input?
                    RET  Z                              ; Yes, abort command.

                    EX   DE,HL                          ; HL points at filename
                    CALL Check_file                     ; check name syntax & add extension...
                    RET  C
                    LD   A, OP_IN
                    CALL Get_file_handle                ; now open...
                    JP   C, File_IO_error

                    ; file opened, IX contains file handle...
                    LD   A,0                            ; set cursor at start position
                    LD   BC,$0212                       ; display menu at (18,2)
                    LD   DE,addr_prompt                 ; prompt 'Enter address:'
                    LD   HL,startfile_banner            ; 'Load file at address:'
                    CALL ClearEditBuffer                ; empty before new input...
                    CALL InpLine                        ; enter an address
                    CP   IN_ESC
                    CALL Z, Close_file                  ; ESC pressed, close file and return to main menu
                    RET  Z
                    EX   DE,HL                          ; HL points at start of buffer
                    LD   C,16
                    CALL Get_constant                   ; convert ASCII to 16 bit integer
                    JP   C, Close_file                  ; close file and return
                    LD   A,D                            ; get high byte of start address
                    AND  @11000000                      ; bank range 0000h - 3FFFh
                    JR   NZ, Bufrange                   ; 'out of buffer/bank range'

                    PUSH DE                             ; remember start address of file load...
                    LD   A, FA_EXT
                    LD   DE,0
                    CALL_OZ(Os_Frm)                     ; get size of file in DEBC
                    POP  DE
                    LD   H,D
                    LD   L,E
                    ADD  HL,BC                          ; check file is with buffer boundary (0000h-3FFFh)
                    DEC  HL                             ; (start address + BC-1)
                    LD   A,H
                    AND  @11000000
                    JR   NZ, buffer_boundary            ; ups - file exceeds buffer boundary...

                    ; Update Start & End Range, and load file into memory buffer
                    LD   (RangeStart),DE                ; Update Start Range variable
                    LD   (RangeEnd),HL                  ; Update End Range variable
                    EX   DE,HL                          ; start range in HL
                    LD   A,H
                    ADD  A,$20                          ; add base of memory buffer to start buffer offset
                    LD   H,A                            ;
                    EX   DE,HL                          ; DE points at absolute start address in buffer
                    LD   HL,0                           ; move file into memory, starting at (DE),
                    CALL_OZ(Os_Mv)                      ; total of BC bytes
                    CALL Close_file

                    LD   BC,$0314                       ; postion of window
                    LD   DE,$0528                       ; size of error window
                    LD   HL,mbl_prompt
                    LD   IX,report_banner               ; pointer to menu banner
                    CALL ReportWindow                   ; display (menu) window with message
                    RET

.buffer_boundary    CALL_OZ(Gn_Cl)                      ; close file
                    JP   File_Buffer_Bndry              ; and report 'file exceeds buffer boundary'
.bufrange           CALL_OZ(Gn_Cl)
                    JP   Out_of_Bufrange                ; 'out of buffer/bank range'



; ************************************************************************************************
; CC_mbs    -   Memory Buffer Save
;
.MBS_command        LD   HL,(RangeStart)                ; get cur. Start Prog. Range
                    CALL PresetBuffer_Hex16             ; preset buffer with ...
                    LD   A,4                            ; set cursor at end of hex address
                    LD   BC,$0010                       ; display menu at (16,1)
                    LD   DE,addr_prompt                 ; prompt 'Enter Address:'
                    LD   HL,startmbs_banner             ;
                    CALL InpLine                        ; enter an address
                    CP   IN_ESC
                    RET  Z                              ; ESC pressed, return to main menu
                    EX   DE,HL                          ; HL points at start of buffer
                    LD   C,16
                    CALL Get_constant                   ; convert ASCII to 16 bit integer
                    RET  C                              ; close file and return if an error occurred
                    LD   A,D                            ; get high byte of start address
                    AND  @11000000                      ; bank range 0000h - 3FFFh
                    JP   NZ, Out_of_Bufrange            ; 'out of buffer/bank range'
                    PUSH DE
                    POP  IX                             ; save start range temporarily
                    LD   HL,(RangeEnd)                  ; get cur. End Prog. Range
                    CALL PresetBuffer_Hex16             ; preset buffer with ...
                    LD   A,4                            ; set cursor at end of hex address
                    LD   BC,$0112                       ; display menu at (18,2)
                    LD   DE,addr_prompt                 ; prompt 'Enter Address:'
                    LD   HL,endmbs_banner
                    CALL InpLine                        ; enter an address
                    CP   IN_ESC
                    RET  Z                              ; ESC pressed, return to main menu
                    EX   DE,HL                          ; HL points at start of buffer
                    LD   C,16
                    CALL Get_constant                   ; convert ASCII to 16 bit integer
                    RET  C                              ; close file and return if an error occurred
                    LD   A,D                            ; get high byte of start address
                    AND  @11000000                      ; bank range 0000h - 3FFFh
                    JP   NZ, Out_of_Bufrange            ; 'out of buffer/bank range'
                    EX   DE,HL                          ; End Range in HL
                    PUSH IX
                    POP  DE                             ; Start Range in DE
                    CP   A
                    SBC  HL,DE                          ; test that Start is lower than End
                    JP   C,Illegal_Range                ; End lower than Start!
                    LD   B,H
                    LD   C,L
                    INC  BC                             ; length of range (incl. start)
                    PUSH BC
                    PUSH DE                             ; remember start & length of range to save
                    LD   DE,EditBuffer                  ; set DE to point at edit buffer
                    CALL FetchCurPath                   ; store current directory path into edit buffer
                    LD   A,C                            ; set cursor at end of directory path
                    LD   BC,$0214                       ; display menu at (20,3)
                    LD   DE,flnm_prompt                 ; prompt 'Filename:'
                    LD   HL,mbsfln_banner
                    SET  GetMail,(IY + 0)               ; mail from Filer is allowed...
                    CALL InpLine                        ; enter a filename
                    RES  GetMail,(IY + 0)
                    POP  HL                             ; start of buffer to save
                    POP  BC
                    CP   IN_ESC                         ; <ESC> pressed during input?
                    RET  Z                              ; Yes, abort command.

                    EX   DE,HL                          ; HL points at filename, DE = start of code
                    LD   A, OP_IN
                    CALL Get_file_handle
                    CALL NC, Close_file
                    JR   C, create_file                 ; file doesn't exist, create it...
                    CALL NC,OverWrite_YesNo             ; file exists, overwrite?
                    RET  C                              ; ESC pressed
                    RET  NZ                             ; don't overwrite file, return...

.create_file        LD   A, OP_OUT
                    CALL Get_file_handle                ; Yes - overwrite
                    JP   C, File_IO_error               ; Ups creation error
                    EX   DE,HL                          ; HL = start of code
                    LD   A,H
                    ADD  A,$20
                    LD   H,A                            ; pointer converted to absolute address in buffer
                    LD   DE,0
                    CALL_OZ(Os_Mv)                      ; save buffer range to file
                    CALL_OZ(Gn_Cl)                      ; close file
                    LD   A,B
                    OR   C
                    JP   NZ, Save_not_complete          ; Ups - bytes remain to be saved...
                    LD   BC,$0316                       ; postion of window
                    LD   DE,$0528                       ; size of error window
                    LD   HL,mbs_prompt
                    LD   IX,report_banner               ; pointer to menu banner
                    CALL ReportWindow                   ; display (menu) window with message
                    RET

.Overwrite_YesNo    PUSH BC                             ; preserve length of code to save
                    PUSH DE
                    PUSH HL                             ; preserve pointer to filename

                    LD   BC,$0128                       ; postion of error window
                    LD   DE,$0428                       ; size of error window
                    LD   A,15                           ; 'File exists'
                    CALL Get_errmsg                     ; HL = return pointer to err. msg from opcode in A
                    LD   IX,error_banner                ; pointer to menu banner
                    CALL YesNoWindow

                    POP  HL
                    POP  DE
                    POP  BC
                    RET



; ************************************************************************************************
; CC_er     -   Eprom Programming Range
;
.ER_command         LD   HL,(RangeStart)                ; get cur. Start Prog. Range
                    CALL PresetBuffer_Hex16             ; preset buffer with ...
                    LD   A,4                            ; set cursor at end of hex address
                    LD   BC,$0210                       ; display menu at (16,2)
                    LD   DE,startrange_prompt           ; prompt 'Enter Start Range:'
                    LD   HL,ProgRange_banner            ; 'Input Eprom Range (0000h-3FFFh) :'
                    CALL InpLine                        ; enter an address
                    CP   IN_ESC
                    RET  Z                              ; ESC pressed, return to main menu
                    EX   DE,HL                          ; HL points at start of buffer
                    LD   C,16
                    CALL Get_constant                   ; convert ASCII to 16 bit integer
                    RET  C                              ; close file and return if an error occurred
                    LD   A,D                            ; get high byte of start address
                    AND  @11000000                      ; bank range 0000h - 3FFFh
                    JP   NZ, Out_of_Bufrange            ; 'out of buffer/bank range'
                    PUSH DE
                    POP  IX                             ; save start range temporarily
                    LD   HL,(RangeEnd)                  ; get cur. End Prog. Range
                    CALL PresetBuffer_Hex16             ; preset buffer with ...
                    LD   A,4                            ; set cursor at end of hex address
                    LD   BC,$0312                       ; display menu at (18,3)
                    LD   DE,endrange_prompt             ; prompt 'Enter End Range:'
                    LD   HL,ProgRange_banner            ; 'Input Eprom Range (0000h-3FFFh) :'
                    CALL InpLine                        ; enter an address
                    CP   IN_ESC
                    RET  Z                              ; ESC pressed, return to main menu
                    EX   DE,HL                          ; HL points at start of buffer
                    LD   C,16
                    CALL Get_constant                   ; convert ASCII to 16 bit integer
                    RET  C                              ; close file and return if an error occurred
                    LD   A,D                            ; get high byte of start address
                    AND  @11000000                      ; bank range 0000h - 3FFFh
                    JP   NZ, Out_of_Bufrange            ; 'out of buffer/bank range'
                    EX   DE,HL                          ; End Range in HL
                    PUSH IX
                    POP  DE                             ; Start Range in DE
                    CP   A
                    PUSH HL
                    SBC  HL,DE                          ; test that Start is lower than End
                    POP  HL
                    JP   C,Illegal_Range                ; End lower than start!
                    LD   (RangeStart),DE                ; store new Start Range
                    LD   (RangeEnd),HL                  ; store new End Range
                    RET


; ************************************************************************************************
; CC_etp    -   Define Eprom Type
;
.ET_command         LD   A,(EprSelection)               ; get current Item Index
                    LD   IX,EpromTypes
                    LD   BC,$0310                       ; display menu at (16,3)
                    LD   DE,EprType_prompt              ; prompt 'Enter Eprom Size or press @J"
                    LD   HL,EprType_banner              ; 'Define Eprom Type'
                    CALL InpSelectLine                  ; enter a filename
                    CP   IN_ESC                         ; <ESC> pressed during input?
                    RET  Z                              ; Yes, abort command.
                    CALL FindItem                       ; is input a legal Eprom type?
                    JR   C,unknown_eprtype
                    LD   (EprSelection),A               ; new Eprom Type selected
                    CALL GetItemPtr                     ; get pointer to select Eprom Type
                    LD   A,(HL)                         ; get Programming signals
                    LD   (EpromType),A                  ; for selected Eprom.
                    RET
.unknown_eprtype    LD   A,14
                    CALL Write_Err_Msg
                    RET


; ************************************************************************************************
; CC_eb     -   Define Eprom Bank
;
.EB_command         LD   A,(EprBank)                    ; get current bank number
                    LD   L,A
                    CALL PresetBuffer_Hex8              ; preset buffer with current bank
                    LD   A,3                            ; set cursor at end of bank number
                    LD   BC,$0310                       ; display menu at (16,3)
                    LD   DE,bank_prompt                 ; prompt 'Enter bank number:'
                    LD   HL,EprBank_banner              ; 'Define Eprom Bank:'
                    CALL InpLine                        ; enter address
                    CP   IN_ESC                         ; <ESC> pressed during input?
                    RET  Z                              ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                          ; get bank number
                    CALL Get_Constant
                    RET  C                              ; Ups - syntax error or illegal value
                    LD   A,E
                    AND  @11000000                      ; bank number in range 00h - 3Fh ?
                    JP   NZ, Illegal_Bankref            ; ...
                    LD   A,E
                    LD   (EprBank),A                    ; New Eprom bank number defined.
                    RET



; ************************************************************************************************
; CC_eprd   -   Read Eprom
;
.EPRD_command       LD   A,(EprBank)                    ; get current EPROM bank
                    OR   $C0                            ; bank in slot 3...
                    LD   B,A
                    CALL Bind_in_bank
                    CALL Get_Absrange
                    EX   DE,HL                          ; (HL) points at EPROM, (DE) at buffer
                    LDIR                                ; read range from Eprom to Memory

                    LD   BC,$0210                       ; postion of window
                    LD   DE,$0528                       ; size of message window
                    LD   HL,eprd_prompt                 ; pointer to prompt (error message)
                    LD   IX,eprd_banner                 ; pointer to menu banner
                    CALL ReportWindow                   ; display (menu) window with message
                    RET



; ************************************************************************************************
; CC_epvf   -   Eprom Verify
;
.EPVF_command       LD   A,(EprBank)                    ; get current EPROM bank
                    OR   $C0                            ; bank in slot 3...
                    LD   B,A
                    CALL Bind_in_Bank
                    CALL Get_Absrange
                    CALL Verify_Eprom
                    JR   C, Epr_no_match

                    LD   BC,$0210                       ; position of window
                    LD   DE,$0528                       ; size of message window
                    LD   HL,epvf_prompt
                    LD   IX,epvf_banner                 ; pointer to menu banner
                    CALL ReportWindow                   ; display (menu) window with message
                    RET

.Epr_no_match       LD   A,12
                    CALL Disp_EprAddrError
                    RET



; ************************************************************************************************
; CC_epck   -   Check Eprom
;
.EPCK_command       CALL Check_Eprom
                    RET  C                              ; Ups - Eprom already used...

                    LD   BC,$0210                       ; position of window
                    LD   DE,$0528                       ; size of message window
                    LD   HL,epck_prompt
                    LD   IX,epck_banner                 ; pointer to menu banner
                    CALL ReportWindow                   ; display (menu) window with message
                    RET


; ************************************************************************************************
; CC_mbcl   -   Memory Buffer Clear
;
.MBCL_command       CALL ClearMemBuffer
                    LD   HL,0
                    LD   (RangeStart),HL                ; Eprom Programming Range Start to 0000h
                    LD   HL, $3FFF
                    LD   (RangeEnd),HL                  ; Eprom Programming Range End to 3FFFh

                    LD   BC,$0210                       ; postion of window
                    LD   DE,$0528                       ; size of error window
                    LD   HL,clear_prompt
                    LD   IX,mbcl_banner                 ; pointer to menu banner
                    CALL ReportWindow                   ; display (menu) window with message
                    RET


; ************************************************************************************************
;
.ClearMemBuffer     PUSH HL
                    PUSH BC
                    PUSH AF
                    LD   HL, $2000                      ; base address of memory buffer
                    LD   BC, $4000                      ; 16K
.clearmembuf_loop   LD   (HL),$FF
                    INC  HL
                    DEC  BC
                    LD   A,B
                    OR   C
                    JR   NZ,clearmembuf_loop            ; reset 16K memory buffer with $FF's
                    POP  AF
                    POP  BC
                    POP  HL
                    RET


; **********************************************************************************
;
; Skip spaces in input buffer, and point at first non-space character
; Entry; HL points at position to start skipping spaces...
; On return HL will point at first non-space character.
; If EOL occurs, Fc = 1, otherwise Fc = 0.
;
; Register status after return:
;
;       A.BCDE../IXIY  same
;       .F....HL/....  different
;
.SkipSpaces         PUSH BC
                    LD   B,A
.SpacesLoop         LD   A,(HL)
                    CP   0                                ; EOL ?
                    JR   Z, EOL_reached
                    CP   32
                    JR   NZ, Exit_SkipSpaces              ; x <> spaces!
                    INC  HL
                    JR   SpacesLoop
.EOL_reached        SCF                                   ; Ups, EOL!
                    JR   Restore_A
.Exit_SkipSpaces    XOR  A                                ; Fc = 0
.Restore_A          LD   A,B
                    POP  BC
                    RET


; **********************************************************************************
;
; GetChar routine
; - Return a char, in A, from input buffer by the current pointer, HL
;   If EOL reached, return Fc = 1, otherwise Fc = 0
;
; Status of registers on return:
;
;       ..BCDE../IXIY  same
;       AF....HL/....  different
;
.GetChar            LD   A,(HL)                           ; get char at current buffer pointer
                    INC  HL                               ; get ready for next char
                    CP   0                                ; EOL ?
                    JR   Z, no_char_read                  ; Yes, no char read...
                    CP   A                                ; Fc = 0
                    RET
.no_char_read       SCF
                    RET



; **********************************************************************************
;
; Get constant value defined as ASCII bytes in input buffer, pointed out
; by HL. The subroutine fetches the appropriate integer size as defined in C (8 or 16bit).
;
; Integer result returned in DE if 16 bit value, or E if 8 bit value.
;
; Status of registers on return:
;
;       A..C..../..IY  same
;       .FB.DEHL/IX..  different             (IX only different if register reference used)
;
;
; If parameter is successfully fetched Fc = 0; HL ptr to next char in input buffer,
; otherwise Fc = 1.
;
; To obtain an integer constant it is necessary to specify a ~ in front of the decimal
; constant, or a @ to obtain an 8bit binary integer. Hexadecimal notation is default.
;
.Get_Constant       CALL SkipSpaces                     ; ignore spaces...
                    JP   C, Syntax_error                ; ups...
                    LD   A,C
                    CP   8                              ; fetch an 8 bit value...
                    JR   Z, get_8bitvalue
                    CALL GetChar
                    CP   '~'
                    JR   Z, get_decvalue

.get_16hexvalue     DEC  HL                             ; unget char (first part of hex byte)
                    CALL ConvHexByte
                    RET  C
                    LD   D,A                            ; high byte of integer word in D
                    CALL ConvHexByte
                    RET  C
                    LD   E,A
                    RET

.get_decvalue       CALL Check_decvalue
                    JP   C, Syntax_error
                    PUSH BC                   ; preserve size identifier in C
                    LD   DE,2                 ; conversion result in BC
                    CALL_OZ(Gn_Gdn)           ; HL ptr. top decimals - convert...
                    POP  DE
                    JP   C, Syntax_error
                    LD   A,E
                    LD   D,B
                    LD   E,C                  ; ASCII decimal converted to integer
                    LD   C,A                  ; size identifier in C
                    RET


.get_8bitvalue      CALL GetChar
                    CP   '~'
                    JR   Z, get_decvalue
                    CP   '@'                            ; binary constant?
                    JR   Z, binary_constant             ;
                    JR   hex_constant

.binary_constant    CALL ConvBinByte                    ;
                    LD   E,A                            ;
                    RET                                 ;
.hex_constant       DEC  HL                             ; unget char just read...
                    CALL ConvHexByte
                    LD   E,A                            ; return 8bit constant in E
                    RET



; *****************************************************************************************
;
; Check decimal value                       V0.33
;
.Check_decvalue   PUSH HL                   ; preserve pointer to inp. buffer
                  LD   B,0                  ;
.check_decloop    LD   A,(HL)               ;
                  INC  B                    ;
                  INC  HL                   ;
                  CP   0                    ; ASCII value finished?
                  JR   Z, exit_decvalue
                  CP   '0'                  ;
                  JR   C, err_dechex        ; char < '0'
                  CP   ':'
                  JR   NC, err_dechex       ; char > '9'
                  JR   check_decloop
.exit_decvalue    POP  HL                   ;
                  CP   A                    ; Fc = 0, legal decimal values...
                  RET
.err_dechex       POP  HL                   ;
                  SCF                       ; Fc = 1, syntax error
                  RET




; *********************************************************************************
;
; Convert Hex byte (e.g. 'FF') to integer byte. Both chars are read from input buffer.
; Result returned in A
;
; Register status after return:
;
;       ...CDE../IXIY same
;       AFB...HL/....  different
;
.ConvHexByte        CALL GetChar
                    JP   C, Syntax_Error                   ; EOL reached...
                    CALL ToUpper
                    CALL Conv_to_nibble                    ; ASCII to value 0 - 15.
                    CP   16                                ; legal range 0 - 15
                    JP   NC, Illegal_hexV
                    SLA  A
                    SLA  A
                    SLA  A
                    SLA  A                                 ; into bit 7 - 4.
                    LD   B,A
                    CALL GetChar
                    JP   C, syntax_error                   ; EOL reached...
                    CALL ToUpper
                    CALL Conv_to_nibble                    ; ASCII to value 0 - 15.
                    CP   16                                ; legal range 0 - 15
                    JP   NC, Illegal_hexV
                    OR   B                                 ; merge the two nibbles
                    RET

; **********************************************************************************
.Conv_to_nibble     CP   '@'                              ; digit >= "A"?
                    JR   NC,hex_alpha                     ; digit is in interval "A" - "F"
                    SUB  48                               ; digit is in interval "0" - "9"
                    RET
                    .hex_alpha
                    SUB  55
                    RET


; **********************************************************************************
;
; V0.17:
; Convert a ASCII binary string to integer.
; Result returned in A
;
; If binary ASCII string is fetched successfully from input buffer, Fc = 0
;
; Register status after return:
;
;       ...C..../IXIY same
;       AFB.DEHL/....  different                        B = 0 on return
;
;
.ConvBinByte        LD   B,8                              ; byte integer to fetch...
                    LD   D,0
                    LD   E,@10000000                      ; bit mask - starting with Bit 7...
.conv_bin_loop      CALL GetChar
                    CP   '0'
                    JR   Z, get_next_binval
                    CP   '1'
                    JP   NZ, syntax_error                 ; only '0' and '1' allowed...
                    LD   A,D
                    OR   E                                ; mask bit into A
                    LD   D,A
.get_next_binval    RRC  E                                ; bit mask rotate right...
                    DJNZ,conv_bin_loop
                    LD   A,D
                    CP   A                                ; Fc = 0, Success!
                    RET


; ******************************************************************************
.Display_Char       PUSH AF
                    CALL_OZ(Os_Out)
                    POP  AF
                    RET


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


; ********************************************************************************
;
; Write message to window
; HL points to Null-terminated string
;
.Write_Msg          PUSH AF
                    PUSH HL
                    CALL_OZ(Gn_Sop)
                    CALL_OZ(Gn_Nln)
                    POP  HL
                    POP  AF
                    RET



; ****************************************************************************
; INTEGER to HEX conversion
; HL (in) = integer to be converted to an ASCII HEX string
; Fc = 1 convert 16 bit integer, otherwise byte integer
;
; Returns ASCII representation in DEBC, e.g. '3FFF' -> D='3', E='F', B='F', C='F'
; (8 bit ASCII only in BC)
;
; Register status after return:
;
;       AF....HL/IXIY  same
;       ..BCDE../....  different
;
.IntHexConv         PUSH AF
                    JR   NC, calc_low_byte                ; convert only byte
                    LD   A,H
                    CALL CalcHexByte
.calc_low_byte      PUSH DE
                    LD   A,L
                    CALL CalcHexByte                      ; DE = low byte ASCII
                    LD   B,D
                    LD   C,E
                    POP  DE
                    POP  AF
                    RET


; ****************************************************************************
; INTEGER to HEX conversion
; HL (in) = integer to be converted to an ASCII HEX string
; Fc = 1 convert 16 bit integer, otherwise byte integer
;
; Prints the string to the current window
;
; Register status after return:
;
;       AFBCDEHL/IXIY  same
;       ......../....  different
;
.IntHexDisp         PUSH DE
                    PUSH BC
                    PUSH AF
                    CALL IntHexConv
                    JR   NC, only_byte_int                ; NC = display only a byte
                    LD   A,D
                    CALL Display_Char
                    LD   A,E
                    CALL Display_Char
.only_byte_int      LD   A,B
                    CALL Display_Char
                    LD   A,C
                    CALL Display_Char                     ; string printed...
                    POP  AF
                    POP  BC
                    POP  DE
                    RET

.IntHexDisp_H       CALL IntHexDisp
                    PUSH AF
                    LD   A, 'h'                           ; same as 'IntHexDisp_H', but with a
                    CALL Display_Char                     ; trailing 'H' hex identifier...
                    POP  AF
                    RET


; ****************************************************************************
; byte in A, will be returned in ASCII form in DE
.CalcHexByte        PUSH HL
                    LD   H,A                              ; copy of A
                    SRL  A
                    SRL  A
                    SRL  A
                    SRL  A                                ; high nibble of H
                    CALL CalcHexNibble
                    LD   D,A
                    LD   A,H
                    AND  @00001111                        ; low nibble of A
                    CALL CalcHexNibble
                    LD   E,A
                    POP  HL
                    RET


; ******************************************************************
; A(in) = 4 bit integer value, A(out) = ASCII HEX byte
.CalcHexNibble      PUSH HL
                    LD   HL, HexSymbols
                    LD   B,0
                    LD   C,A
                    ADD  HL,BC
                    LD   A,(HL)
                    POP  HL
                    RET
.HexSymbols         DEFM "0123456789ABCDEF"



; ******************************************************************************************
;
; Zprom error handler
;
.Zprom_ERH          CP   RC_DRAW                        ; application screen corrupted
                    JR   Z,corrupt_scr
                    CP   RC_QUIT
                    JR   Z,Zprom_suicide
                    CP   RC_ESC
                    JR   Z, ackn_esc
                    XOR  A                              ; ignore rest of errors
                    RET

.Zprom_suicide
.exec_suicide       XOR  A
                    CALL_OZ(Os_Bye)                     ; kill Zprom and return to Index

.corrupt_scr        CALL RedrawScreen                   ; redraw screen before suspension
                    XOR  A
                    RET

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


; ******************************************************************************************
;
.InitZprom          LD   HL, logo
                    CALL_OZ(Dc_Nam)                     ; Name Zprom with 'InterLogic'
                    LD   IY,$1FFD - Zprom_workspace + 1 ; define base of workspace
                    LD   A,128                          ; 128 bytes of buffer editing area
                    LD   (BufSize),A
                    LD   A,0
                    LD   (MenuBarPosn),A                ; initialise main menu bar at top line
                    LD   HL,0
                    LD   (RangeStart),HL
                    LD   HL, $3FFF
                    LD   (RangeEnd),HL                  ; Eprom Programming Range End to 3FFFh
                    LD   A, Eprsignal128                ; Programming Signals for 128K Eprom.
                    LD   (EpromType),A
                    LD   A,1
                    LD   (EprSelection),A               ; pre-select EPROM type 0 (128K).
                    LD   HL, EprBank
                    LD   (HL),$3F                       ; Pre-select bank $3F
                    LD   HL, RamBank
                    LD   (HL),$BF                       ; Pre-select top bank in slot 2
                    CALL ClearMemBuffer                 ; reset memory buffer with $FF's
                    RET
.logo               DEFM "InterLogic", 0
