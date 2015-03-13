; *************************************************************************************
;
; UnZip - File extraction utility for ZIP files, (c) Garry Lancaster, 1999-2006
; This file is part of UnZip.
;
; UnZip is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; UnZip is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with UnZip;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; *************************************************************************************

; Unzip application static structures

        module  structures

include "dor.def"
include "data.def"

        xref    in_entry

; Application DOR

        org     appl_org

.in_dor defb    0,0,0           ; links to parent, brother, son
        defw    brother_add
        defb    brother_bank
        defb    0,0,0
        defb    $83             ; DOR type - application
        defb    indorend-indorstart
.indorstart
        defb    '@'             ; key to info section
        defb    ininfend-ininfstart
.ininfstart
        defw    0
        defb    'U'             ; application key
        defb    ram_pages
        defw    0               ; overhead
        defw    0               ; unsafe workspace
        defw    0               ; safe workspace
        defw    in_entry        ; entry point
        defb    0               ; bank bindings
        defb    0
        defb    0
        defb    in_bank
        defb    at_bad
        defb    0               ; no caps lock
.ininfend
        defb    'H'             ; key to help section
        defb    inhlpend-inhlpstart
.inhlpstart
        defw    in_topics
        defb    in_bank
        defw    in_commands
        defb    in_bank
        defw    in_help
        defb    in_bank
        defw    in_tokens
        defb    in_bank
.inhlpend
        defb    'N'             ; key to name section
        defb    innamend-innamstart
.innamstart
        defm    "Unzip", 0
.innamend
        defb    $ff
.indorend

; Topic entries

.in_topics
        defb    0
.inopt_topic
        defb    inopt_topend-inopt_topic
        defm    "OPTIONS", 0
        defb    (in_help_opts-in_help)/256
        defb    (in_help_opts-in_help)%256
        defb    $11
        defb    inopt_topend-inopt_topic
.inopt_topend

.incom_topic
        defb    incom_topend-incom_topic
        defm    "COMMANDS", 0
        defb    0
        defb    0
        defb    0
        defb    incom_topend-incom_topic
.incom_topend
        defb    0

; Command entries

.in_commands
        defb    0
.in_opts1
        defb    in_opts2-in_opts1
        defb    $81
        defm    "OE", 0
        defm    "E", $85, 0
        defb    (in_help1-in_help)/256
        defb    (in_help1-in_help)%256
        defb    $10
        defb    in_opts2-in_opts1

.in_opts2
        defb    in_opts3-in_opts2
        defb    $82
        defm    "OO", 0
        defm    "O", $8b, 0
        defb    (in_help2-in_help)/256
        defb    (in_help2-in_help)%256
        defb    $10
        defb    in_opts3-in_opts2

.in_opts3
        defb    in_opts_end-in_opts3
        defb    $83
        defm    "OP", 0
        defm    "P", $87, 0
        defb    (in_help3-in_help)/256
        defb    (in_help3-in_help)%256
        defb    $10
        defb    in_opts_end-in_opts3
.in_opts_end
        defb    1

.in_coms1
        defb    in_coms_end-in_coms1
        defb    $80
        defm    "Q", 0
        defm    "Quit", 0
        defb    (in_help5-in_help)/256
        defb    (in_help5-in_help)%256
        defb    $10
        defb    in_coms_end-in_coms1
.in_coms_end
        defb    0


; Help entries

.in_help
        defb    $7f
        defm    "A", $83, " e", $85, "ion utility for ZIP", $8d, $7f
        defm    "(c) Garry Lancaster", $7f
        defm    "v1.14 - 13th March 2015", $7f, $7f
        defb    0

.in_help_opts
        defb    $7f
        defm    "Each ", $80, " can be toggled through up", $88, "three ", $84, "s", $7f
        defm    "The current ", $84, $81, "shown in", $82, $80, "s window", $7f, $7f
        defb    0

.in_help1
        defm    $94, $8e
        defm    $86, $8f, "all", $8d, " automatically", $7f
        defm    $89, "view", $83, " details only", $7f
        defm    $8a, $90, $8f, "each", $83, $7f
        defb    0
.in_help2
        defm    $94, $8e
        defm    $86, "always", $93
        defm    $89, "never", $93
        defm    $8a, $90, "o", $8b, " each", $83, $7f
        defb    0
.in_help3
        defm    $94, "two", $8c
        defm    $86, $8f, "to", $91
        defm    $89, "ignore", $91
        defb    0
.in_help5
        defb    $7f
        defm    "Exit", $82, "Unzip application", $7f
        defb    0

; Tokens

.in_tokens
        defb    $0d
        defb    $15
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
        defw    toka-in_tokens
        defw    tokb-in_tokens
        defw    tokc-in_tokens
        defw    tokd-in_tokens
        defw    toke-in_tokens
        defw    tokf-in_tokens
        defw    tok10-in_tokens
        defw    tok11-in_tokens
        defw    tok12-in_tokens
        defw    tok13-in_tokens
        defw    tok14-in_tokens
        defw    tokend-in_tokens

.tok0   defm    "option"
.tok1   defm    " is "
.tok2   defm    " the "
.tok3   defm    " file"
.tok4   defm    "state"
.tok5   defm    "xtract"
.tok6   defm    "ON (", 1, 245, "): "
.tok7   defm    "aths"
.tok8   defm    " to "
.tok9   defm    "OFF: "
.toka   defm    "ASK (", 1, 241, "): "
.tokb   defm    "verwrite"
.tokc   defm    " settings:", $7f, $7f

.tokd   defm    $83, "s"
.toke   defm    "three", $8c
.tokf   defm    "e", $85, " "
.tok10  defm    "ask user whether", $88
.tok11  defm    " p", $87, " specified in ZIP", $83, $7f
.tok12  defm    "each", $83
.tok13  defm    " o", $8b, " existing", $83, "s", $7f
.tok14  defm    $7f, "This ", $80, " has "
.tokend
