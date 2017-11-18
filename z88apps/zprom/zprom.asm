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


     MODULE Zprom_DOR_entry

     XREF Zprom_entry

     include "applic.def"
     include "mthzprom.def"

     ORG Zprom_DOR


; 'Zprom' DOR:
;
                    DEFB 0, 0, 0                        ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                            ; DOR type - application ROM
                    DEFB DOREnd1-DORStart1              ; total length of DOR
.DORStart1          DEFB '@'                            ; Key to info section
                    DEFB InfoEnd1-InfoStart1            ; length of info section
.InfoStart1         DEFW 0                              ; reserved...
                    DEFB 'E'                            ; application key letter
                    DEFB 16384/256                      ; contiguous RAM size = 16K
                    DEFW 0                              ;
                    DEFW 0                              ; Unsafe workspace
                    DEFW Zprom_workspace                ; Safe workspace
                    DEFW Zprom_entry                    ; Entry point of code in seg. 3 (start of bank)
                    DEFB 0                              ; bank binding to segment 0
                    DEFB 0                              ; bank binding to segment 1
                    DEFB 0                              ; bank binding to segment 2
                    DEFB Zprom_bank                     ; bank binding to segment 3   (Zprom)
                    DEFB @00010010                      ; Bad application, 1 instantiation
                    DEFB 0                              ; no caps lock on activation
.InfoEnd1           DEFB 'H'                            ; Key to help section
                    DEFB 12                             ; total length of help
                    DEFW Zprom_topics
                    DEFB Zprom_MTH_bank                 ; point to topics
                    DEFW Zprom_commands
                    DEFB Zprom_MTH_bank                 ; point to commands
                    DEFW Zprom_help
                    DEFB Zprom_MTH_bank                 ; point to help
                    DEFW Zprom_token_base
                    DEFB Zprom_tokens_bank              ; point to token base
                    DEFB 'N'                            ; Key to name section
                    DEFB NameEnd1-NameStart1            ; length of name
.NameStart1         DEFM "Zprom", 0
.NameEnd1           DEFB $FF
.DOREnd1
