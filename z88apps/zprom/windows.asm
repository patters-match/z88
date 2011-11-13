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


    MODULE Application_windows

    LIB CreateWindow, GreyApplWindow

    XREF DisplMenuBar, Display_string, Display_char, IntHexDisp_H
    XREF Appl_banner, Status_banner, EprTypeMsg, EprBankMsg, EpromTypes, RamBankMsg
    XREF ProgRangeMsg
    XREF DispItemDescr
    XREF ApplMenuWindow
    XREF KeyPrompt, ReadKeyboard

    XDEF xypos
    XDEF ApplWindow, MainMenuWindow, StatusWindow, RedrawScreen
    XDEF ReportWindow, DispKeyWindow
    XDEF YesNoWindow
    XDEF DisplayMenu


    INCLUDE "defs.asm"
    INCLUDE "stdio.def"



; ************************************************************************************************
;
; Main application window
;
; Register status on return:
;
; ......../IXIY  same
; AFBCDEHL/....  different
;
;
.ApplWindow         LD   HL,ApplWindow                  ; subroutine
                    LD   (MainWindow),HL                ; rel. pointer to main window redraw
                    CALL GreyApplWindow
                    LD   A,192 | '2'                    ; open main application window
                    LD   BC, $000F                      ; window coordinate (0,16)
                    LD   DE, $0819                      ; width, height (25,8)
                    LD   HL, comds_banner               ; window banner
                    CALL CreateWindow                   ; create according to parameters
                    CALL MainMenuWindow
                    CALL StatusWindow
                    RET
.comds_banner       DEFM "DIRECT COMMANDS:", 0


; ******************************************************************************************
;
.MainMenuWindow     LD   HL,ApplMenuWindow
                    CALL_OZ(Gn_sop)                     ; first display the menu
                    CALL DisplMenuBar                   ; display main menu & cursor bar
                    RET


; ******************************************************************************************
;
; All registers different on return
;
.StatusWindow       LD   A, 192 | '4'                   ; open main application window
                    LD   BC, $002A                      ; window coordinate (43,0)
                    LD   DE, $081C                      ; height, width (28,8)
                    LD   HL, status_banner              ; window banner
                    CALL CreateWindow                   ; create according to parameters, Cursor pos. reset

                    LD   HL, EprTypeMsg                 ; 'Eprom Type'
                    CALL Display_string
                    LD   HL, VDUcolon
                    CALL Display_string
                    LD   A,(EprSelection)               ; get current selected Eprom
                    LD   IX,EpromTypes
                    CALL DispItemDescr
                    LD   HL, VDUnewline                 ; use normal font and set cursor to new line.
                    CALL Display_string

                    LD   HL, EprBankMsg                 ; 'Eprom Bank'
                    CALL Display_string
                    LD   HL, VDUcolon
                    CALL Display_string
                    LD   A,(EprBank)                    ; get Eprom Bank
                    LD   L,A
                    CP   A
                    CALL IntHexDisp_h                   ; display Eprom Bank as Hex
                    LD   HL, VDUnewline                 ; use normal font and set cursor to new line.
                    CALL Display_string

                    LD   HL, RamBankMsg                 ; 'Memory Bank'
                    CALL Display_string
                    LD   HL, VDUcolon
                    CALL Display_string
                    LD   A,(RamBank)                    ; get RAM Bank
                    LD   L,A
                    CP   A
                    CALL IntHexDisp_h                   ; display Eprom Bank as Hex
                    LD   HL, VDUnewline                 ; use normal font and set cursor to new line.
                    CALL Display_string
                    
                    LD   HL, ProgRangeMsg               ; 'Eprom Range'
                    CALL Display_string
                    LD   HL, VDUcolon                   ; move cursor to tab(24) and use bold font...
                    CALL Display_string
                    LD   HL,(RangeStart)
                    SCF
                    CALL IntHexDisp_h                   ; display start range as Hex
                    LD   HL, RangeSep                   ; ' - '
                    CALL Display_string
                    LD   HL, (RangeEnd)
                    SCF
                    CALL IntHexDisp_h                   ; display end range as Hex
                    LD   HL, VDUnewline                 ; use normal font and set cursor to new line.
                    CALL Display_string
                    RET

.VDUcolon           DEFM 1, "2X", 32+12, ": ", 1, "B", 0
.VDUnewline         DEFM 1, "2-C", 1, "B", 10, 13, 0
.RangeSep           DEFM " - ", 0



; ******************************************************************************************
;
; Redraw application screen, using the two pointers to main window and menu window
; drawing subroutines.
;
; No registers affected
;
.RedrawScreen       PUSH AF
                    PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX
                    EXX
                    PUSH HL
                    PUSH DE
                    PUSH BC
                    EXX
                    EX   AF,AF'
                    PUSH AF
                    EX   AF,AF'
                    LD   HL,(MainWindow)                ; HL points at subroutine
                    LD   DE,redraw1
                    PUSH DE                             ; return address from subroutine
                    JP   (HL)                           ; CALL subroutine...

.redraw1            LD   HL,(MenuWindow)                ; get ptr. to menu window subroutine
                    LD   A,H
                    OR   L                              ; NULL pointer?
                    JR   Z, redraw2                     ; no subroutine to menu window
                    LD   DE,redraw2
                    PUSH DE                             ; return address from subroutine
                    JP   (HL)                           ; CALL subroutine...

.redraw2            EX   AF,AF'                         ; application screen redrawn
                    POP  AF                             ; restore registers
                    EX   AF,AF'
                    EXX
                    POP  BC
                    POP  DE
                    POP  HL
                    EXX
                    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    POP  AF
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
;    Display prompt and wait for a Yes or No keyboard response
;
;    IN:  BC = window position
;         DE = size of window
;         HL = pointer to null-terminated prompt, message
;         IX = window banner
;
;    OUT:
;         Fz = 1, Yes was selected.
;         Fz = 0, No was selected.
;
.YesNoWindow        LD   (MenuPrompt),HL               ; prompt parameter saved
                    LD   (MenuSize),DE                 ; size of window parameter stored
                    LD   (MenuPosition),BC             ; window position parameter saved
                    LD   (MenuBanner),IX               ; window banner parameter stored

                    LD   HL, no_ms
                    LD   (YesNoPrompt),HL
                    LD   HL,DispYesNoWindow
                    LD   (MenuWindow),HL               ; Zprom Wman. is now aware of this menu...
                    CALL DisplayMenu
                    LD   HL, yesnoline
                    CALL Display_string
                    CALL YesNo
                    RET

.DispYesNoWindow    CALL DisplayMenu
                    LD   HL, yesnoline
                    CALL Display_string
                    LD   HL,(YesNoPrompt)
                    CALL Display_string                 ; And the additional "Yes" or "No" message
                    RET

.YesNo              LD   HL,(YesNoPrompt)
                    CALL Display_string
                    CALL ReadKeyboard
                    CP   IN_ESC
                    JR   Z, esc_pressed
                    CP   IN_ENT
                    JR   NZ,yn1
                    LD   A,L
                    CP   yes_ms % 256
                    RET  Z                             ; Fz = 1 (Fc = 0), Yes was selected...
                    OR   A                             ; Fz = 0 (fc = 0), No was selected...
                    RET
.esc_pressed        SCF
                    RET
.yn1
                    OR   32
                    CP   'y'
                    JR   NZ,yn2
                    LD   HL,yes_ms
                    LD   (YesNoPrompt),HL
                    JR   YesNo
.yn2
                    CP   'n'
                    JR   NZ,YesNo
                    LD   HL,no_ms
                    LD   (YesNoPrompt),HL
                    JR   YesNo
.yes_ms             DEFM 1, "2+C", 1, "2X", 33, "Yes", 8, 8, 8, 0
.no_ms              DEFM 1, "2+C", 1, "2X", 33, "No ", 8, 8, 8, 0
.yesnoline          DEFM 13, 10, 1, "2JN", 0



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
