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


    MODULE ErrorMessages

    XREF Display_string, ReadKeyboard, IntHexDisp_H
    XREF DisplayMenu
    XREF ErrMsg_lookup, ESCPrompt
    XREF Error_banner

    XDEF Get_errmsg
    XDEF Write_Err_Msg, DispErrWindow, Disp_EprAddrError, SetupErrWindow
    XDEF Illegal_hexV, Syntax_error, File_IO_error, Out_of_Bufrange
    XDEF File_Buffer_Bndry, Illegal_bankref, Illegal_range, Save_not_complete


    INCLUDE "defs.asm"


; *******************************************************************
.Illegal_hexV       PUSH AF
                    LD   A,0
                    CALL Write_Err_Msg
                    POP  AF
                    SCF
                    RET

; *******************************************************************
.Syntax_Error       PUSH AF
                    LD   A,1
                    CALL Write_Err_Msg
                    POP  AF
                    SCF
                    RET

; *******************************************************************
.File_IO_Error      PUSH AF
                    LD   A,5
                    CALL Write_Err_Msg
                    POP  AF
                    SCF
                    RET

; *******************************************************************
.Out_of_Bufrange    PUSH AF
                    LD   A,6
                    CALL Write_Err_Msg
                    POP  AF
                    SCF
                    RET

; *******************************************************************
.File_Buffer_Bndry  PUSH AF
                    LD   A,7
                    CALL Write_Err_Msg
                    POP  AF
                    SCF
                    RET

; *******************************************************************
.Illegal_bankref    PUSH AF
                    LD   A,8
                    CALL Write_Err_Msg
                    POP  AF
                    SCF
                    RET

; *******************************************************************
.Illegal_range      PUSH AF
                    LD   A,9
                    CALL Write_Err_Msg
                    POP  AF
                    SCF
                    RET

; *******************************************************************
.Save_not_complete  PUSH AF
                    LD   A,10
                    CALL Write_Err_Msg
                    POP  AF
                    SCF
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

.Get_ESC_key        CALL ReadKeyboard
                    CP   27
                    JR   NZ, Get_esc_key
                    RET


; ***********************************************************************************************************
; Error opcode in A
;
.SetupErrWindow     LD   HL,$0128                       ; postion of error window
                    LD   (MenuPosition),HL
                    LD   HL,$0528                       ; size of error window
                    LD   (MenuSize),HL
                    CALL Get_errmsg                     ; return pointer to err. msg from opcode in A
                    LD   (MenuPrompt),HL                ; pointer to prompt (error message)
                    LD   HL,Error_banner                ; pointer to menu banner
                    LD   (MenuBanner),HL
                    RET


; ***********************************************************************************************************
; Display error message and address in HEX format. Address is fetched in 'ReProgram' variable
; Error opcode in A
;
.Disp_EprAddrError  PUSH AF
                    LD   A,(ReProgram+1)                ; the address of byte in EPROM
                    AND  @00111111                      ; that didn't match in the buffer.
                    LD   (ReProgram+1),A                ; high byte of address converted to bank offset
                    POP  AF
                    CALL SetupErrWindow
                    CALL DispErrAddr                    ; display error (menu) window with error message
                    CALL Get_ESC_key
                    RET

.DispErrAddr        LD   HL,DispErrAddr                 ; point at re-draw routine
                    LD   (MenuWindow),HL                ; Zprom Wman. is now aware of this menu...
                    CALL DisplayMenu
                    LD   HL,(ReProgram)                 ; get address in Eprom of byte already used
                    SCF
                    CALL IntHexDisp_h                   ; display address in hex
                    LD   HL,ESCPrompt
                    CALL Display_string                 ; And the additional 'Press any key' message
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
