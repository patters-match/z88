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


; Definitions of variables in save workspace:
; All variables refer to offset position from base of workspace, which is x number of bytes below
; $1FFD. IY is set as base to safe workspace.
; When the application screen is corrupted, a subroutine is called to re-draw the screen
; at the time when the application was excited. On re-entry the screen will be blank, and
; it is necessary to re-draw the screen. The two pointers below refer to the two subroutines
; that will re-draw the screen. if the contents of the rel.pointer is 0, then no subroutine
; will be called (this is only needed, if no menu window had been drawn and only a main.
; window were active.

     INCLUDE "applic.def"


DEFVARS $1FFD - Zprom_workspace + 1
{
     Statusbyte1    ds.b 1    ; status flags
     MainWindow     ds.w 1    ; main window subroutine (2 bytes)
     MenuWindow     ds.w 1    ; menu window subroutine (2 bytes)

     SC             ds.b 1    ; Horisontal Start Cursor      (1 byte)
     CI             ds.b 1    ; Horisontal Cursor Increment  (1 byte)
     CX             ds.b 1    ; Horisontal Cursor Movement   (1 byte)
     CY             ds.b 1    ; Vertical Cursor Movement     (1 byte)
     TopAddr        ds.w 1    ; Address of first byte in edit window (2 bytes)
     BotAddr        ds.w 1    ; Address of last byte + 1 in edit window (2 bytes)
     EpromType      ds.b 1    ; Current EPROM type: $48 = 32K, &69 = 128K,256K, $00 = Flash 1MB (1 byte)
     RangeStart     ds.w 1    ; EPROM Programming Range start (2 bytes)
     RangeEnd       ds.w 1    ; EPROM Programming Range end   (2 bytes)
     EprBank        ds.b 1    ; Current EPROM bank  (1 byte)
     RamBank        ds.b 1    ; current pseudo RAM bank (1 byte)

     Banner         ds.w 1    ; Contains pointer to a banner  (2 bytes) - only View/Edit Bank,Memory
     BaseAddr       ds.b 1    ; High byte of Base address of EDIT/VIEW MEMORY/EPROM  (1 byte)

     ReProgram      ds.w 1    ; Address to re-program in EPROM bank (2 bytes)
     ReProgByte     ds.b 1    ; Byte to be re-programmed (1 byte)

     EprSelection   ds.b 1    ; Index to Eprom type selection block (1 byte)

     MenuBarPosn    ds.b 1    ; Y position of menu bar in main menu (1 byte)
     MenuBanner     ds.w 1    ; pointer to menu banner of current menu (2 bytes)
     MenuPosition   ds.w 1    ; (X,Y) of current menu window (2 bytes)
     MenuSize       ds.w 1
     MenuPrompt     ds.w 1    ; pointer to menu input prompt (2 bytes)
     YesNoPrompt    ds.w 1    ; pointer to "Yes" or "No" prompt

     Bufsize        ds.b 1    ; size of edit buffer (1 byte)
     EditBuffer     ds.b 128  ; edit line buffer (128 bytes)
     filenamebuffer ds.b 64   ; buffer filenames, etc.
}

; Various Zprom Constant Mnemonics:
;
DEFC  EprSignal32  = $48, EprSignal128 = $69, FlashEprom = $00

; Statusbyte1 bit mnemonics:
DEFC ViewEdit = 0  ;  BIT 0: View/Edit memory flag.
DEFC HexAscii = 1  ;  BIT 1: HEX/ASCII cursor flag.
DEFC ActvCmd  = 2  ;  BIT 2: Command active.
DEFC MWinGrey = 3  ;  BIT 3: Main window grey'ed.
DEFC GetMail  = 4  ;  BIT 4: Read mail filename in inputline
