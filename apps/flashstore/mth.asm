; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sourceforge.net) & Thierry Peycru (pek@free.fr), 1997-2004
;
; FlashStore is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; FlashStore is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************


     MODULE Mth

     XDEF FlashStoreTopics
     XDEF FlashStoreCommands
     XDEF FlashStoreHelp

     include "fsapp.def"

     
; ********************************************************************************************************************
;
; topic entries for FlashStore popdown...
;
.FlashStoreTopics   DEFB 0                                                      ; start marker of topics

; 'COMMANDS' topic
.topic_cmds         DEFB topic_cmds_end - topic_cmds                            ; length of topic definition
                    DEFM "Commands", 0                                          ; name terminated by high byte
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000000
                    DEFB topic_cmds_end - topic_cmds
.topic_cmds_end
                    DEFB 0


; *****************************************************************************************************************************
;
.FlashStoreCommands DEFB 0                                                      ; start of commands

; @SC Select Card
.cmd_sc             DEFB cmd_sc_end - cmd_sc                                    ; length of command definition
                    DEFB FlashStore_CC_sc                                       ; command code
                    DEFM "SC" , 0                                               ; keyboard sequense
                    DEFM "Select Card", 0
                    DEFB (cmd_sc_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_sc_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_sc_end - cmd_sc                                    ; length of command definition
.cmd_sc_end

; @CF Catalogue Files
.cmd_cf             DEFB cmd_cf_end - cmd_cf                                    ; length of command definition
                    DEFB FlashStore_CC_cf                                       ; command code
                    DEFM "CF" , 0                                               ; keyboard sequense
                    DEFM "Catalogue Files", 0
                    DEFB (cmd_cf_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_cf_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_cf_end - cmd_cf                                    ; length of command definition
.cmd_cf_end

; @CE Catalogue Files (hidden)
.cmd_ce             DEFB cmd_ce_end - cmd_ce                                    ; length of command definition
                    DEFB FlashStore_CC_cf                                       ; command code
                    DEFM "CE" , 0                                               ; keyboard sequense
                    DEFM 0
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000100                                              ; command is hidden (no help)
                    DEFB cmd_ce_end - cmd_ce                                    ; length of command definition
.cmd_ce_end

; @SV Select RAM Device
.cmd_sv             DEFB cmd_sv_end - cmd_sv                                    ; length of command definition
                    DEFB FlashStore_CC_sv                                       ; command code
                    DEFM "SV" , 0                                               ; keyboard sequense
                    DEFM "Select RAM Device", 0
                    DEFB (cmd_sv_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_sv_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_sv_end - cmd_sv                                    ; length of command definition
.cmd_sv_end

; @FS File Save
.cmd_fs             DEFB cmd_fs_end - cmd_fs                                    ; length of command definition
                    DEFB FlashStore_CC_fs                                       ; command code
                    DEFM "FS" , 0                                               ; keyboard sequense
                    DEFM "File Save", 0
                    DEFB (cmd_fs_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fs_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page, new column
                    DEFB cmd_fs_end - cmd_fs                                    ; length of command definition
.cmd_fs_end

; @ES File Save (Hidden)
.cmd_es             DEFB cmd_es_end - cmd_es                                    ; length of command definition
                    DEFB FlashStore_CC_fs                                       ; command code
                    DEFM "ES" , 0                                               ; keyboard sequense
                    DEFM 0
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000100                                              ; hidden command 
                    DEFB cmd_es_end - cmd_es                                    ; length of command definition
.cmd_es_end

; @FL File Load
.cmd_fl             DEFB cmd_fl_end - cmd_fl                                    ; length of command definition
                    DEFB FlashStore_CC_fl                                       ; command code
                    DEFM "FL" , 0                                               ; keyboard sequense
                    DEFM "File Load", 0
                    DEFB (cmd_fl_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fl_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_fl_end - cmd_fl                                    ; length of command definition
.cmd_fl_end

; @EF File Load (Hidden)
.cmd_ef             DEFB cmd_ef_end - cmd_ef                                    ; length of command definition
                    DEFB FlashStore_CC_fl                                       ; command code
                    DEFM "EF" , 0                                               ; keyboard sequense
                    DEFM 0
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000100                                              ; hidden command 
                    DEFB cmd_ef_end - cmd_ef                                    ; length of command definition
.cmd_ef_end

; @FE File Erase
.cmd_fe             DEFB cmd_fe_end - cmd_fe                                    ; length of command definition
                    DEFB FlashStore_CC_fe                                       ; command code
                    DEFM "FE" , 0                                               ; keyboard sequense
                    DEFM "File Erase", 0
                    DEFB (cmd_fe_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_fe_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_fe_end - cmd_fe                                    ; length of command definition
.cmd_fe_end

; @ER File Erase (Hidden)
.cmd_er             DEFB cmd_er_end - cmd_er                                    ; length of command definition
                    DEFB FlashStore_CC_fe                                       ; command code
                    DEFM "ER" , 0                                               ; keyboard sequense
                    DEFM 0
                    DEFB 0                                                      ; high byte of rel. pointer
                    DEFB 0                                                      ; low byte of rel. pointer
                    DEFB @00000100                                              ; hidden command 
                    DEFB cmd_er_end - cmd_er                                    ; length of command definition
.cmd_er_end

; @BF Backup RAM Files
.cmd_bf             DEFB cmd_bf_end - cmd_bf                                    ; length of command definition
                    DEFB FlashStore_CC_bf                                       ; command code
                    DEFM "BF" , 0                                               ; keyboard sequense
                    DEFM "Backup RAM Files", 0
                    DEFB (cmd_bf_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_bf_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_bf_end - cmd_bf                                    ; length of command definition
.cmd_bf_end

; @RF Restore RAM Files
.cmd_rf             DEFB cmd_rf_end - cmd_rf                                    ; length of command definition
                    DEFB FlashStore_CC_rf                                       ; command code
                    DEFM "RF" , 0                                               ; keyboard sequense
                    DEFM "Restore RAM Files", 0
                    DEFB (cmd_rf_help - FlashStoreHelp) / 256                   ; high byte of rel. pointer
                    DEFB (cmd_rf_help - FlashStoreHelp) % 256                   ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_rf_end - cmd_rf                                    ; length of command definition
.cmd_rf_end

; @FORMAT Erase File Area
.cmd_format         DEFB cmd_format_end - cmd_format                            ; length of command definition
                    DEFB FlashStore_CC_format                                   ; command code
                    DEFM "FORMAT" , 0                                           ; keyboard sequense
                    DEFM "Format File Area", 0
                    DEFB (cmd_format_help - FlashStoreHelp) / 256               ; high byte of rel. pointer
                    DEFB (cmd_format_help - FlashStoreHelp) % 256               ; low byte of rel. pointer
                    DEFB @00011001                                              ; command has help page, new column, safe
                    DEFB cmd_format_end - cmd_format                            ; length of command definition
.cmd_format_end

; @ABOUT About FlashStore
.cmd_about          DEFB cmd_about_end - cmd_about                              ; length of command definition
                    DEFB FlashStore_CC_format                                   ; command code
                    DEFM "ABOUT", 0                                             ; keyboard sequense
                    DEFM "About FlashStore", 0
                    DEFB (cmd_about_help - FlashStoreHelp) / 256                ; high byte of rel. pointer
                    DEFB (cmd_about_help - FlashStoreHelp) % 256                ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_about_end - cmd_about                              ; length of command definition
.cmd_about_end

                    DEFB 0                                                      ; end of commands

; *******************************************************************************************************************
;
.FlashStoreHelp     
                    DEFM "Release V1.7.rc2, December 2004",$7F, $7F
                    DEFM "Manage files on Rakewell Flash Cards.", $7F
                    DEFM "Open Source Utility from http://z88.sf.net", 0

.cmd_sc_help
                    DEFM $7F
                    DEFM "Help Page for 'Select Card' command"
                    DEFB 0
.cmd_cf_help
                    DEFM $7F
                    DEFM "Help Page for 'Catalogue Files' command"
                    DEFB 0
.cmd_sv_help
                    DEFM $7F
                    DEFM "Help Page for 'Select RAM Device' command"
                    DEFB 0
.cmd_fs_help
                    DEFM $7F
                    DEFM "Help Page for 'File Save' command"
                    DEFB 0
.cmd_fl_help
                    DEFM $7F
                    DEFM "Help Page for 'File Load' command"
                    DEFB 0
.cmd_fe_help
                    DEFM $7F
                    DEFM "Help Page for 'File Erase' command"
                    DEFB 0
.cmd_bf_help
                    DEFM $7F
                    DEFM "Help Page for 'Backup RAM Files' command"
                    DEFB 0
.cmd_rf_help
                    DEFM $7F
                    DEFM "Help Page for 'Restore RAM Files' command"
                    DEFB 0
.cmd_format_help
                    DEFM $7F
                    DEFM "Help Page for 'Format File Area' command"
                    DEFB 0
.cmd_about_help
                    DEFM $7F
                    DEFM "Help Page for 'About FlashStore' command"
                    DEFB 0
