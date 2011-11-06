; *************************************************************************************
; Installer/Bootstrap/Packages (c) Garry Lancaster 1998-2011
;
; Installer/Bootstrap/Packages is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2, or (at your option) any later version.
; Installer/Bootstrap/Packages is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with
; Installer/Bootstrap/Packages; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

; Token entries

        module  tokens

        xdef    in_tokens

.in_tokens
        defb    9
        defb    10
        defw    tok0-in_tokens
        defw    tok1-in_tokens
        defw    tok2-in_tokens
        defw    tok3-in_tokens
        defw    tok4-in_tokens
        defw    tok5-in_tokens
        defw    tok6-in_tokens
        defw    tok7-in_tokens
        defw    tok8-in_tokens
        defw    tok9-in_tokens
        defw    tokend-in_tokens
.tok0
        defm    1,"T"
.tok1
        defm    "nstall"
.tok2
        defm    " by Garry Lancaster"
.tok3
        defm    " applications"

; Website address used to live in token 4
.tok4
        defm    "                                                      "

.tok5
        defm    " - 13th May 2001"
.tok6
        defm    " utility"
.tok7
        defm    " in "
.tok8
        defm    "locked"
.tok9
        defm    " banks"
.tokend

