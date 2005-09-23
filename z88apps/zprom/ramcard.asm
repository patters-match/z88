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


     MODULE RamCard_commands

     LIB ApplEprType

     XDEF RBW_command, BR_command, BE_command, BV_command, RBCL_command
     XDEF RCLC_command, COPY_command, CLONE_command

     XREF ClearEditBuffer, ClearMemBuffer, Presetbuffer_hex8
     XREF ramwrt_banner, membank_prompt, memrd_banner, rbw_prompt, rbr_prompt
     XREF rbclwarn_prompt, rbcl_prompt
     XREF Editram_banner, Editmem_banner, Viewram_Banner, RamCl_banner
     XREF ramcrd_banner, rclc_prompt, rclc2_prompt
     XREF copy_banner, copy_prompt, copy2_prompt
     XREF clone_banner,clone_prompt
     XREF Memory_edit, Memory_view, ViewEditDump
     XREF InpLine
     XREF Get_Constant
     XREF ReportWindow, Write_err_msg
     XREF Get_AbsRange
     XREF Bind_in_bank
     XREF BlowEprom, BlowFlashEprom, CheckBatteries


     INCLUDE "defs.asm"
     INCLUDE "stdio.def"
     INCLUDE "fileio.def"


; *****************************************************************************
;
;    Write the contents of the buffer range into a specified memory bank.
;    The slot number of the bank's Ram Card will be examined if it contains
;    a RAM filing device :RAM.x. It will not be allowed to clear a bank of a
;    pseudo RAM card if it is a RAM filing device.
;
.RBW_command        LD   A,(RamBank)                   ; get current RAM bank
                    LD   L,A
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0110                      ; display menu at (16,3)
                    LD   DE,Membank_prompt             ; prompt 'Define Memory Bank (00h-FFh):'
                    LD   HL,RamWrt_banner              ; 'Write RAM Bank at Range'
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value
                    LD   A,E
                    AND  @11000000                     ; get slot number (top two bits)
                    RLCA                               ; rotate slot number into bit 1,0
                    RLCA                               ; (which is a value between 0-3)
                    LD   D,A

                    PUSH BC                            ; This is for Garry's Installer utility!
                    LD   C,D
                    CALL ApplEprType                   ; does slot contain Rom Front Dor?
                    POP  BC
                    JR   NC, upload_code               ; Yes, try to upload code to RAM...

                    LD   A,D                           ; check slot again...
                    LD   HL, RAM_wildcard              ; No Rom Front Dor found, make sure it's
                    CALL CheckDevice                   ; not a RAM filing device!
                    JP   C, ramcard_used
.upload_code
                         LD   A,E
                         LD   (Rambank),A              ; update current Ram Bank variable
                         LD   B,E
                         CALL Bind_in_bank             ; bind pseudo RAM bank into segment 2
                         CALL Get_AbsRange             ; get range size in BC, start in HL,
                         LDIR                          ; destination in DE (to segment 2)
                         CALL VerifyRamBank            ; Verify bytes written to Ram Bank
                         JP   NZ, write_protected      ; RAM Card was write-protected

                         LD   BC,$0211                 ; position of window
                         LD   DE,$0530                 ; size of message window
                         LD   HL,rbw_prompt
                         LD   IX,ramwrt_banner         ; pointer to menu banner
                         CALL ReportWindow             ; display (menu) window with message
                         RET



; *****************************************************************************
;
;    Read the contents of a specified memory bank (0 - 255) into the buffer.
;
.BR_command         LD   A,(RamBank)                   ; get current RAM bank
                    LD   L,A
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0310                      ; display menu at (16,3)
                    LD   DE,membank_prompt             ;
                    LD   HL,Memrd_banner               ; 'Read Memory bank Range into buffer'
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value
                    LD   A,E
                    LD   (RamBank), A                  ; Update current RAM bank variable
                    LD   B,E
                    CALL Bind_in_bank                  ; bind pseudo RAM bank into segment 2
                    CALL Get_AbsRange                  ; get range size in BC,
                    EX   DE,HL                         ; start in HL (segment 2),
                    LDIR                               ; destination in DE (buffer)

                    LD   BC,$0210                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,rbr_prompt
                    LD   IX,Memrd_banner               ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET



; *****************************************************************************
;
;    Edit the contents of a specified memory bank (0 - 255).
;
.BE_command         LD   A,(RamBank)                   ; get current RAM bank
                    LD   L,A
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0211                      ; display menu at (16,2)
                    LD   DE,membank_prompt             ;
                    LD   HL,editram_banner             ; 'Edit Mem. Bank'
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value
                    LD   A,E
                    LD   (RamBank),A                   ; Update current RAM bank variable
                    LD   A, $80
                    LD   (BaseAddr),A                  ; Base dump address at segm. 2
                    LD   HL, EditRam_banner
                    LD   IX, Memory_Edit
                    LD   B,E
                    CALL Bind_in_bank
                    CALL ViewEditDump                  ; dump bank to screen...
                    RET



; *****************************************************************************
;
;    View the contents of a specified memory bank (0 - 255).
;
.BV_command         LD   A,(RamBank)                   ; get current RAM bank
                    LD   L,A
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0211                      ; display menu at (15,2)
                    LD   DE,membank_prompt             ;
                    LD   HL,viewram_banner             ; 'View Mem. Bank'
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value
                    LD   A, $80
                    LD   (BaseAddr),A                  ; Base dump address at segm. 2
                    LD   HL, ViewRam_banner
                    LD   IX, Memory_View
                    LD   B,E
                    CALL Bind_in_bank
                    CALL ViewEditDump                  ; dump bank to screen...
                    RET



; *****************************************************************************
;
;    Clear the specified bank of the pseudo Ram Card (all bytes are set to 0).
;    The slot number of the bank's Ram Card will be examined if it contains
;    either a RAM filing device :RAM.x or it contains applications, :ROM.x/appl/.
;    It is not allowed to clear a bank of a RAM card that is used for the filing
;    system. A warning is given if Application software is stored on the card.
;
.RBCL_command       LD   A,(RamBank)                   ; get current RAM bank
                    LD   L,A
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0110                      ; display menu at (16,3)
                    LD   DE,membank_prompt             ;
                    LD   HL,RamCl_banner               ; 'Clear RAM Bank'
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value
                    LD   A,E
                    AND  @11000000                     ; get slot number (top two bits)
                    RLCA                               ; rotate slot number into bit 1,0
                    RLCA                               ; (which is a value between 0-3)
                    LD   D,A
                    LD   HL, RAM_wildcard
                    CALL CheckDevice                   ; is slot used by RAM filing device?
                    JP   C, ramcard_used               ; yes - bank not allowed to be reset
                    LD   A,D
                    LD   HL, ROM_wildcard
                    CALL CheckDevice                   ; check for an Application Card
                    CALL C, ackn_bankreset             ; Yes - report warning and await key press
                    CP   IN_ESC
                    RET  Z                             ; user pressed <ESC> - return...
                    LD   B,E
                    CALL ResetRamBank
                    CALL VerifyEmptyRamBank
                    JP   NZ, Write_protected           ; Ups - RAM Card was write protected

                    LD   BC,$0312                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,rbcl_prompt                ; 'Ram bank reset'.
                    LD   IX,RamCl_banner               ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET

.ackn_bankreset     PUSH DE                            ; preserve bank number...
                    LD   BC,$0228                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,rbclwarn_prompt
                    LD   IX,RamCl_banner               ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    POP  DE                            ; and wait key press.
                    RET



; *****************************************************************************
;
;    Clear the intire Ram Card (all bytes are set to 0). The slot number of the
;    Ram Card will be examined if it contains either a RAM filing device :RAM.x
;    or it contains applications, :ROM.x/appl/. It is not allowed to clear the
;    pseudo RAM card if either case is true.
;
.RCLC_command       LD   L, 2                          ; preset slot number to 2
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0110                      ; display menu at (16,3)
                    LD   DE,rclc_prompt                ;
                    LD   HL,Ramcrd_banner              ; 'Clear RAM Card'
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value
                    LD   A,E
                    AND  @00000011                     ; available slots are 0 - 3
                    LD   D,A
                    LD   HL, RAM_wildcard
                    CALL CheckDevice
                    JP   C, ramcard_used               ; RAM filing device found, error...
                    LD   A,D
                    LD   HL, ROM_wildcard
                    CALL CheckDevice
                    CALL C, ackn_bankreset             ; ROM card found in slot, acknowledge...
                    CP   IN_ESC
                    RET  Z

                    LD   A,E                           ; get slot number
                    RRCA                               ; slot may be cleared
                    RRCA                               ; slot number converted to slot bank range
                    OR   @00111111                     ; top bank in slot $xF
                    LD   E,A
                    LD   IX,$BFFE                      ; top address of bank
                    LD   B,E
                    CALL Bind_in_bank                  ; bind top bank into segment 2

                    LD   A,'z'
                    LD   (IX+0),'z'
                    LD   (IX+1),'z'                    ; write 'zz' at top two bytes of bank
                    CP   (IX+0)                        ; was it written?
                    JP   NZ, Write_protected           ; No - RAM Card was write protected

                    LD   D,0                           ; number of banks to clear (inkl. current)
.find_bottom_bank   INC  D
                    DEC  E                             ; search downwards in slot...
                    LD   B,E
                    CALL Bind_in_bank
                    CP   (IX+0)
                    JR   NZ, find_bottom_bank
                    CP   (IX+1)
                    JR   NZ, find_bottom_bank

.clear_banks_loop   INC  E                             ; top bank re-appeared, bottom bank is above...
                    PUSH DE
                    LD   B,E
                    CALL ResetRamBank                  ; and set all bytes to 0 in bank
                    POP  DE
                    DEC  D
                    JR   NZ, clear_banks_loop          ; clear banks in RAM card...

                    LD   BC,$0212                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,rclc2_prompt               ; 'Ram Card is cleared.'
                    LD   IX,Ramcrd_banner              ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET



; *****************************************************************************
;
;    Copy contents of an Eprom Application Card to the Pseudo RAM Card
;    - This command is only useful if the Zprom software is in slot 1 assuming that
;    V4 of the OZ is used (with internal 128K RAM identified as an expanded Z88),
;    or Zprom is part of the internal application ROM on an expanded Z88.
;
.COPY_command       LD   L, 3                          ; preset slot number to 3
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0110                      ; display menu at (16,3)
                    LD   DE,copy_prompt
                    LD   HL,copy_banner
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value
                    LD   A,E
                    AND  @00000011                     ; available slots are 0 - 3
                    LD   HL, ROM_wildcard
                    CALL CheckDevice
                    JP   NC, romcard_notfound          ; ROM Card not found

                    PUSH DE                            ; preserve slot number of ROM Card
                    LD   L, 2                          ; preset slot number to 2 (of RAM Card)
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0211                      ; display menu at (17,4)
                    LD   DE,rclc_prompt                ; "Enter slot number of RAM Card"
                    LD   HL,copy_banner
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    POP  BC
                    RET  Z                             ; Yes, abort command.
                    PUSH BC
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    LD   A,E
                    POP  DE
                    LD   D,A                           ; ROM Card slot in E, RAM Card slot in D
                    RET  C                             ; Ups - syntax error or illegal value
                    AND  @00000011                     ; available slots are 0 - 3
                    LD   HL, RAM_wildcard
                    CALL CheckDevice
                    JP   C, ramcard_used               ; RAM filing system Card detected

                    RRC  E
                    RRC  E
                    LD   A,@00111111
                    OR   E
                    LD   E,A                           ; top bank of ROM Card
                    RRC  D
                    RRC  D
                    LD   A,@00111111
                    OR   D
                    LD   D,A                           ; top bank of ROM Card

                    LD   B,E
                    CALL Bind_in_bank
                    LD   A, ($BFFC)                    ; get number of bank in ROM Card
                    DEC  A
                    LD   C,A
                    LD   A,E
                    SUB  C
                    LD   E,A                           ; begin at bottom bank of ROM Card
                    LD   A,D
                    SUB  C
                    LD   D,A                           ; to copy into bottom bank of RAM Card

                    LD   HL,0
                    LD   (RangeStart),HL
                    LD   HL,$3FFF
                    LD   (RangeEnd),HL                 ; copy whole bank...
                    INC  C                             ; total banks to copy

.copy_romcard       PUSH BC                            ; preserve counter
                    PUSH DE                            ; preserve source & dest. bank numbers
                    LD   B,E
                    CALL Bind_in_bank                  ; page in bank of ROM Card (segment 2)
                    CALL Get_Absrange
                    EX   DE,HL                         ; copy from ROM bank at (HL)
                    LDIR                               ; to buffer at (DE), BC bytes...
                    POP  BC
                    PUSH BC
                    CALL Bind_in_bank                  ; page in bank of RAM Card (segment 2)
                    CALL Get_Absrange                  ; copy from buffer at (HL)
                    LDIR                               ; to RAM bank at (DE), BC bytes...
                    CALL VerifyRamBank                 ; then verify RAM bank contents
                    JR   NZ, copy_aborted              ; RAM Card was write protected
                    POP  DE
                    INC  D
                    INC  E
                    POP  BC
                    DEC  C
                    JR   NZ, copy_romcard              ; copy all banks of ROM Card
                    CALL ClearMemBuffer                ; clear Zprom buffer.

                    LD   BC,$0312                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,copy2_prompt               ; 'ROM Card is copied succesfully."
                    LD   IX,copy_banner                ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET

.copy_aborted       POP  DE
                    POP  BC
                    JP   write_protected               ; "RAM Card write-protected"




; *****************************************************************************
;
;    Blow the contents of an Eprom Application Card to an empty Eprom.
;    - This command is only useful if the Zprom software is in slot 1 assuming that
;    V4 of the OZ is used (with internal 128K RAM identified as an expanded Z88),
;    or Zprom is part of the internal application ROM on an expanded Z88.
;
.CLONE_command      LD   L, 2                          ; preset slot number to 2
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0110                      ; display menu at (16,1)
                    LD   DE,copy_prompt
                    LD   HL,clone_banner
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.

                    CALL CheckBatteries
                    RET  C                             ; batteries are low - abort

                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value
                    LD   A,E
                    AND  @00000011                     ; available slots are 0 - 3
                    CP   3
                    JP   Z, slot3_reserved             ; slot 3 is used for EPROM to be programmed
                    LD   HL, ROM_wildcard
                    CALL CheckDevice
                    JP   NC, romcard_notfound          ; ROM Card not found

                    LD   A,3
                    LD   HL, RAM_wildcard
                    CALL CheckDevice
                    JP   C, ramcard_used               ; RAM filing system Card detected
                    LD   A,3
                    LD   HL, ROM_wildcard
                    CALL CheckDevice
                    JP   C, romcard_installed          ; ROM Card detected

                    RRC  E
                    RRC  E
                    LD   A,@00111111
                    OR   E
                    LD   E,A                           ; top bank of ROM Card in defined slot
                    LD   D,$3F                         ; top bank of slot 3 (virtual)

                    LD   B,E
                    CALL Bind_in_bank
                    LD   A, ($BFFC)                    ; get number of banks in ROM Card
                    DEC  A
                    LD   C,A
                    LD   A,E
                    SUB  C
                    LD   E,A                           ; begin at bottom bank of ROM Card
                    LD   A,D
                    SUB  C
                    LD   D,A                           ; to blow into bottom bank of empty EPROM Card

                    LD   HL,0
                    LD   (RangeStart),HL
                    LD   HL,$3FFF
                    LD   (RangeEnd),HL                 ; blow whole banks to EPROM Card
                    INC  C                             ; total banks to blow...

.blow_romcard       PUSH BC                            ; preserve counter
                    PUSH DE                            ; preserve source & dest. bank numbers
                    LD   B,E
                    CALL Bind_in_bank                  ; page in bank of ROM Card (segment 2)
                    CALL Get_Absrange
                    EX   DE,HL                         ; copy from ROM bank at (HL)
                    LDIR                               ; to buffer at (DE), BC bytes...
                    POP  AF
                    PUSH AF                            ; A = bank of slot 3 to blow
                    LD   (EprBank),A                   ; update global variable

                    CALL BlowBankRoutine               ; determine bank blowing algorithm in IX
                    LD   HL, RET_blowbank
                    PUSH HL
                    JP   (IX)                          ; then blow code into EPROM bank...

.RET_blowbank       JR   C, clone_aborted              ; - failed...
                    POP  DE
                    INC  D
                    INC  E
                    POP  BC
                    DEC  C
                    JR   NZ, blow_romcard              ; copy all banks of ROM Card
                    CALL ClearMemBuffer                ; clear Zprom buffer.

                    CALL_OZ(OS_Pur)                    ; clear machine timeout flag...
                    LD   BC,$0312                      ; position of window
                    LD   DE,$0530                      ; size of message window
                    LD   HL,clone_prompt
                    LD   IX,clone_banner               ; pointer to menu banner
                    CALL ReportWindow                  ; display (menu) window with message
                    RET

.clone_aborted      POP  DE                            ; EPROM programming aborted...
                    POP  BC
                    RET

.BlowBankRoutine    LD   A,(EpromType)
                    LD   IX, BlowFlashEprom
                    CP   0
                    RET  Z                             ; Eprom Type is Flash Card...
                    LD   IX, BlowEprom                 ; Eprom Type is 32K, 128K or 256K
                    RET



; *****************************************************************************
;
;    Check if the specified slot is used by a RAM filing device.
;
;    IN:  A = slot number (0 to 3)
;         HL = local pointer to device.
;
;    OUT: Fc = 1, Slot is used by device.
;         Fc = 0, Slot doesn't contain the specified device
;
.CheckDevice        PUSH BC
                    PUSH DE
                    PUSH HL
                    OR   $30                           ; ASCII '0' to '3'
                    LD   BC, 7
                    LD   DE, filenamebuffer            ; DE points at filenamebuffer
                    PUSH DE
                    LDIR                               ; copy wildcard into buffer
                    DEC  DE
                    DEC  DE
                    LD   (DE),A                        ; slot number for device

                    LD   B,0
                    POP  HL
                    PUSH HL
                    LD   A, 0
                    CALL_OZ(GN_OPW)                    ; open wildcard handler for ":RAM.x"
                    POP  DE                            ; DE points to buffer
                    LD   C,10
                    CALL_OZ(GN_WFN)
                    PUSH AF                            ; preserve error status
                    CALL_OZ(GN_WCL)                    ; close wild card handler
                    POP  AF                            ; return error status
                    CCF                                ; Fc = 1, if device is present...
                    POP  HL
                    POP  DE
                    POP  BC
                    RET

.RAM_wildcard       DEFM ":RAM.0", 0
.ROM_wildcard       DEFM ":ROM.0", 0



; *****************************************************************************
;
;    Verify contents of RAM bank with contents of buffer.
;
;    IN:  None.
;    OUT: Fz = 1, contents in RAM bank successfully written,
;         otherwise Fz = 0, write-protected.
;
.VerifyRamBank      CALL Get_AbsRange                  ; Get Range parameters
.verify_ramloop     LD   A,(DE)                        ; then verify range...
                    INC  DE
                    CPI
                    RET  NZ                            ; Byte didn't match, RAM Card was write protected,
                    JP   PE, verify_ramloop            ; an EPROM were installed, or the slot was empty
                    RET


; *****************************************************************************
;
;    Reset RAM Bank (set memory to 0).
;
;    IN:  B = Bank number to reset
;
.ResetRamBank       PUSH BC
                    PUSH DE
                    PUSH HL
                    CALL Bind_in_Bank                  ; bind bank to segment 2 ($8000-$BFFF)
                    LD   BC, 16384-1
                    LD   HL, $8000
                    LD   DE, $8001
                    LD   (HL),$FF                      ; reset to $FF (emulate empty EPROM)
                    LDIR                               ; Set whole bank to 0.
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; *****************************************************************************
;
;    Verify that RAM Bank is empty (all 0).
;
;    IN:  B = Bank number to verify
;
.VerifyEmptyRamBank PUSH BC
                    PUSH DE
                    PUSH HL
                    CALL Bind_in_Bank                  ; bind bank to segment 2 ($8000-$BFFF)
                    XOR  A
                    LD   BC, 16384
                    LD   HL, $8000
.check_empty_loop   CPI
                    JR   NZ, exit_vrframbank           ; Ups - byte wasn't reset...
                    JP   PE, check_empty_loop          ; check whole bank...
.exit_vrframbank    POP  HL
                    POP  DE
                    POP  BC
                    RET


; *****************************************************************************
;
.romcard_installed  LD   A, 20
                    CALL Write_err_msg                 ; "Slot 3 contains Application Card"
                    RET

; *****************************************************************************
;
.slot3_reserved     LD   A, 19
                    CALL Write_err_msg                 ; "Slot 3 is reserved for empty EPROM."
                    RET

; *****************************************************************************
;
.romcard_notfound   LD   A, 18
                    CALL Write_err_msg                 ; "ROM Card not available in slot"
                    RET

; *****************************************************************************
;
.write_protected    LD   A, 17
                    CALL Write_Err_msg                 ; "RAM Card is write-protected"
                    RET

; *****************************************************************************
;
.ramcard_used       LD   A, 16
                    CALL Write_err_msg                 ; "RAM Card is used by filing-system"
                    RET
