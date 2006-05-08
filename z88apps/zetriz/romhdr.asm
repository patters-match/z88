; *************************************************************************************
; ZetriZ
; (C) Gunther Strube (gbs@users.sf.net) 1995-2006
;
; ZetriZ is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; ZetriZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with ZetriZ;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

    MODULE RomHeader

    ORG $3FC0

; Application front DOR, in top bank of EPROM, starting at $3FC0
; First Application DOR will be located at $0000, bank $3F:

.appl_front_dor     DEFB 0, 0, 0                ; link to parent...
                    DEFB 0, 0, 0                ; no help DOR
                    DEFW 0                      ; offset of code in bank
                    DEFB $3F                    ; in top bank of eprom
                    DEFB $13                    ; DOR type - ROM front DOR
                    DEFB 8                      ; length of DOR
                    DEFB 'N'
                    DEFB 5                      ; length of name and terminator
                    DEFM "APPL", 0
                    DEFB $FF                    ; end of application front DOR

                    DEFS 37                     ; blanks to fill-out space.

.eprom_header       DEFW $0052                  ; $3FF8 Card ID for this application ROM
                    DEFB @00000100              ; $3FFA Denmark country code is 4
                    DEFB $80                    ; $3FFB external application
                    DEFB $01                    ; $3FFC size of EPROM (1 banks of 16K)
                    DEFB 0                      ; $3FFD subtype of card ...
.eprom_adr_3FFE     DEFM "OZ"                   ; $3FFE card is an application ROM
.EpromTop
