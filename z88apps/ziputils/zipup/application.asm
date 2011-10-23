; *************************************************************************************
;
; ZipUp - File archiving and compression utility to ZIP files, (c) Garry Lancaster, 1999-2006
; This file is part of ZipUp.
;
; ZipUp is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; ZipUp is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with ZipUp;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************


; ZipUp application static structures

        module  structures

include "dor.def"
include "data.def"

        xref    in_entry

; Application DOR

        org     appl_org

.in_dor defb    0,0,0   ; links to parent, brother, son
        defb    0,0,0
        defb    0,0,0
        defb    $83     ; DOR type - application
        defb    indorend-indorstart
.indorstart
        defb    '@'     ; key to info section
        defb    ininfend-ininfstart
.ininfstart
        defw    0
        defb    'U'     ; application key
        defb    ram_pages
        defw    0       ; overhead
        defw    0       ; unsafe workspace
        defw    0       ; safe workspace
        defw    in_entry; entry point
        defb    0       ; bank bindings
        defb    0
        defb    0
        defb    in_bank
        defb    at_bad+at_ones  ; bad app, only one instantiation allowed
        defb    0       ; no caps lock
.ininfend
        defb    'H'     ; key to help section
        defb    inhlpend-inhlpstart
.inhlpstart
        defw    in_topics
        defb    in_bank
        defw    in_commands
        defb    in_bank
        defw    in_help
        defb    in_bank
        defb    0,0,0   ; no tokens
.inhlpend
        defb    'N'     ; key to name section
        defb    innamend-innamstart
.innamstart
        defm    "ZipUp", 0
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
        defm    "OD", 0
        defm    "Delete", 0
        defb    (in_help1-in_help)/256
        defb    (in_help1-in_help)%256
        defb    $10
        defb    in_opts2-in_opts1

.in_opts2
        defb    in_opts3-in_opts2
        defb    $82
        defm    "OC", 0
        defm    "Compress", 0
        defb    (in_help2-in_help)/256
        defb    (in_help2-in_help)%256
        defb    $10
        defb    in_opts3-in_opts2

.in_opts3
        defb    in_opts_end-in_opts3
        defb    $83
        defm    "OP", 0
        defm    "Paths", 0
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
        defm    "A file archiving and compression utility", $7f
        defm    "(c) Garry Lancaster", $7f
        defm    "v1.02 - 23rd October 2011", $7f, $7f
        defb    0

.in_help_opts
        defb    $7f
        defm    "Each option can be toggled through up to three states", $7f
        defm    "The current state is shown in the options window", $7f, $7f
        defm    1, 245, " indicates the option is ON", $7f
        defm    1, 241, " indicates the option is ASK", $7f
        defm    "No marker indicates the option is off", $7f
        defb    0

.in_help1
        defb    $7f
        defm    "This option has three settings:", $7f, $7f
        defm    "ON (", 1, 245, "): delete files after archiving", $7f
        defm    "OFF: don't delete files", $7f
        defm    "ASK (", 1, 241, "): ask user whether to delete each file", $7f
        defb    0
.in_help2
        defb    $7f
        defm    "This option has two settings:", $7f, $7f
        defm    "ON (", 1, 245, "): fast compression", $7f
        defm    "OFF: no compression", $7f
        defb    0
.in_help3
        defb    $7f
        defm    "This option has two settings:", $7f, $7f
        defm    "ON (", 1, 245, "): store full paths in ZIP file", $7f
        defm    "OFF: store filenames only", $7f
        defb    0
.in_help5
        defb    $7f
        defm    "Exit the ZipUp application", $7f
        defb    0
