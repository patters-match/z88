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


     MODULE MTH_Zprom

     XDEF tokens_base
     XDEF Zprom_topics
     XDEF Zprom_commands
     XDEF Zprom_help
     XDEF Zprom_MTH_START,Zprom_MTH_END

     INCLUDE "applic.def"
     INCLUDE "stdio.def"

     ORG MTH_Zprom_ORG


.Zprom_MTH_START

     INCLUDE "tokens.asm"

; ********************************************************************************************************************
;
; topic entries for Zprom application...
;
.Zprom_Topics       DEFB 0                                                      ; start marker of topics

; 'INFO' topic
.topic_info         DEFB topic_info_end - topic_info                            ; length of topic definition
                    DEFM "INFO" , 0                                             ; name terminated by high byte
                    DEFB (topic_info_help - zprom_help) / 256                   ; high byte of rel. pointer
                    DEFB (topic_info_help - zprom_help) % 256                   ; low byte of rel. pointer
                    DEFB @00010010                                              ; this information topic has help
                    DEFB topic_info_end - topic_info
.topic_info_end

; 'CURSOR' topic
.topic_cursor       DEFB topic_cursor_end - topic_cursor                        ; length of topic definition
                    DEFM $A3 , 0
                    DEFB (topic_cursor_help - Zprom_help) / 256                 ; high byte of rel. pointer
                    DEFB (topic_cursor_help - Zprom_help) % 256                 ; low byte of rel. pointer
                    DEFB @00010000                                              ; topic has help page...
                    DEFB topic_cursor_end - topic_cursor
.topic_cursor_end

; 'MEMORY' topic
.topic_memory       DEFB topic_memory_end - topic_memory                        ; length of topic definition
                    DEFM $A9 , 0
                    DEFB (topic_memory_help - Zprom_help) / 256                 ; high byte of rel. pointer
                    DEFB (topic_memory_help - Zprom_help) % 256                 ; low byte of rel. pointer
                    DEFB @00010000                                              ; topic has help page...
                    DEFB topic_memory_end - topic_memory
.topic_memory_end

; 'EPROM' topic
.topic_eprom        DEFB topic_eprom_end - topic_eprom                          ; length of topic definition
                    DEFM $8F , 0                                                ; name terminated by high byte
                    DEFB (topic_eprom_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (topic_eprom_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB @00010000                                              ; topic has help page...
                    DEFB topic_eprom_end - topic_eprom
.topic_eprom_end
                    DEFB 0



; *****************************************************************************************************************************
;
.Zprom_commands     DEFB 0                                                      ; start of commands

.inf_about          DEFB inf_about_end - inf_about                              ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM "About Info Topics" , 0
                    DEFB (inf_about_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (inf_about_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_about_end - inf_about                              ; length of information command definition
.inf_about_end

.inf_slot3          DEFB inf_slot3_end - inf_slot3                              ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM "Slot 3 Hardw" , $DC , 0
                    DEFB (inf_slot3_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (inf_slot3_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_slot3_end - inf_slot3                              ; length of information command definition
.inf_slot3_end

.inf_cardman        DEFB inf_cardman_end - inf_cardman                          ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $D8 , " M" , $FD , "ager , " , $8F , "s" , 0
                    DEFB (inf_cardman_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (inf_cardman_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_cardman_end - inf_cardman                          ; length of information command definition
.inf_cardman_end

.inf_cardheader     DEFB inf_cardheader_end - inf_cardheader                    ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $D8 , " " , $D9 , 0
                    DEFB (inf_cardheader_help - Zprom_help) / 256               ; high byte of rel. pointer
                    DEFB (inf_cardheader_help - Zprom_help) % 256               ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_cardheader_end - inf_cardheader                    ; length of information command definition
.inf_cardheader_end

.inf_cardid         DEFB inf_cardid_end - inf_cardid                            ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $D8 , " ID" , 0
                    DEFB (inf_cardid_help - Zprom_help) / 256                   ; high byte of rel. pointer
                    DEFB (inf_cardid_help - Zprom_help) % 256                   ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_cardid_end - inf_cardid                            ; length of information command definition
.inf_cardid_end

.inf_instepr        DEFB inf_instepr_end - inf_instepr                          ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM "Install." , $FF , $AF , "'" , $DA , $D7 , 0
                    DEFB (inf_instepr_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (inf_instepr_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_instepr_end - inf_instepr                          ; length of information command definition
.inf_instepr_end

.inf_cardconv       DEFB inf_cardconv_end - inf_cardconv                        ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $D7 , " " , $D8 , " conven" , $CD , "s" , 0
                    DEFB (inf_cardconv_help - Zprom_help) / 256                 ; high byte of rel. pointer
                    DEFB (inf_cardconv_help - Zprom_help) % 256                 ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_cardconv_end - inf_cardconv                        ; length of information command definition
.inf_cardconv_end

.inf_romprog        DEFB inf_romprog_end - inf_romprog                          ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $D7 , " " , $B4 , "m" , $CE , " Tips" , 0
                    DEFB (inf_romprog_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (inf_romprog_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_romprog_end - inf_romprog                          ; length of information command definition
.inf_romprog_end

.inf_eprtypes       DEFB inf_eprtypes_end - inf_eprtypes                        ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM "Diff" , $FE , "ent " , $8F , " Types" , 0
                    DEFB (inf_eprtypes_help - Zprom_help) / 256                 ; high byte of rel. pointer
                    DEFB (inf_eprtypes_help - Zprom_help) % 256                 ; low byte of rel. pointer
                    DEFB $11                                                    ; information help page, new column
                    DEFB inf_eprtypes_end - inf_eprtypes                        ; length of information command definition
.inf_eprtypes_end

.inf_eprprec        DEFB inf_eprprec_end - inf_eprprec                          ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $8F , " precau" , $CD , "s" , 0
                    DEFB (inf_eprprec_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (inf_eprprec_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_eprprec_end - inf_eprprec                          ; length of information command definition
.inf_eprprec_end

.inf_banknum        DEFB inf_banknum_end - inf_banknum                          ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $BB , " Numb" , $FE , " Conven" , $CD , "s" , 0
                    DEFB (inf_banknum_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (inf_banknum_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_banknum_end - inf_banknum                          ; length of information command definition
.inf_banknum_end

.inf_comds          DEFB inf_comds_end - inf_comds                              ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $B9 , "s " , $CF , " " , $AF , 0
                    DEFB (inf_comds_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (inf_comds_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_comds_end - inf_comds                              ; length of information command definition
.inf_comds_end

.inf_numconv        DEFB inf_numconv_end - inf_numconv                          ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM "Numb" , $FE , " conven" , $CD , "s" , 0
                    DEFB (inf_numconv_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (inf_numconv_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_numconv_end - inf_numconv                          ; length of information command definition
.inf_numconv_end

.inf_cli            DEFB inf_cli_end - inf_cli                                  ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $AF , " " , $D0 , $B3 , "CLI" , 0
                    DEFB (inf_cli_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (inf_cli_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_cli_end - inf_cli                                  ; length of information command definition
.inf_cli_end

.inf_fileditor      DEFB inf_fileditor_end - inf_fileditor                      ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $AF , " as " , $CB , " " , $A7 , "or" , 0
                    DEFB (inf_fileditor_help - Zprom_help) / 256                ; high byte of rel. pointer
                    DEFB (inf_fileditor_help - Zprom_help) % 256                ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_fileditor_end - inf_fileditor                      ; length of information command definition
.inf_fileditor_end

.inf_fileutil       DEFB inf_fileutil_end - inf_fileutil                        ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM $AF , " as " , $CB , " Utility" , 0
                    DEFB (inf_fileutil_help - Zprom_help) / 256                 ; high byte of rel. pointer
                    DEFB (inf_fileutil_help - Zprom_help) % 256                 ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_fileutil_end - inf_fileutil                        ; length of information command definition
.inf_fileutil_end

.inf_pseudoram      DEFB inf_pseudoram_end - inf_pseudoram                      ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM "Pseudo RAM " , $D8 , ", Software" , 0
                    DEFB (inf_pseudoram_help - Zprom_help) / 256                ; high byte of rel. pointer
                    DEFB (inf_pseudoram_help - Zprom_help) % 256                ; low byte of rel. pointer
                    DEFB $11                                                    ; information help page, new column
                    DEFB inf_pseudoram_end - inf_pseudoram                      ; length of information command definition
.inf_pseudoram_end

.inf_romcopy        DEFB inf_romcopy_end - inf_romcopy                          ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM "Copy" , $CE , " " , $D7 , "'s" , 0
                    DEFB (inf_romcopy_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (inf_romcopy_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_romcopy_end - inf_romcopy                          ; length of information command definition
.inf_romcopy_end

.inf_aboutzp        DEFB inf_aboutzp_end - inf_aboutzp                          ; length of information command definition
                    DEFW 0                                                      ; command code , keyboard sequense
                    DEFM "About " , $AF , 0
                    DEFB (inf_aboutzp_help - Zprom_help) / 256                  ; high byte of rel. pointer
                    DEFB (inf_aboutzp_help - Zprom_help) % 256                  ; low byte of rel. pointer
                    DEFB $10                                                    ; information help page
                    DEFB inf_aboutzp_end - inf_aboutzp                          ; length of information command definition
.inf_aboutzp_end
                    DEFB 1                                                      ; end of this topic...

; <ENTER>
.cmd_enter          DEFB cmd_enter_end - cmd_enter                              ; length of command definition
                    DEFB IN_ENT                                                 ; command code
                    DEFM MU_ENT , 0                                             ; keyboard sequense
                    DEFM "ENTER" , 0
                    DEFB (cmd_enter_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (cmd_enter_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_enter_end - cmd_enter                              ; length of command definition
.cmd_enter_end

; <TAB>  HEX/ASCII Edit Cursor
.cmd_tab            DEFB cmd_tab_end - cmd_tab                                  ; length of command definition
                    DEFB IN_TAB                                                 ; command code
                    DEFM MU_TAB , 0                                             ; keyboard sequense
                    DEFM $94 , "/" , $9D , " " , $A3 , 0
                    DEFB (cmd_tab_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_tab_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_tab_end - cmd_tab                                  ; length of command definition
.cmd_tab_end

; ESC  Abort command
.cmd_esc            DEFB cmd_esc_end - cmd_esc                                  ; length of command definition
                    DEFB IN_ESC                                                 ; command code
                    DEFM IN_ESC , 0                                             ; keyboard sequense
                    DEFM "Abort " , $B9 , 0
                    DEFB (cmd_esc_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_esc_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_esc_end - cmd_esc                                  ; length of command definition
.cmd_esc_end

; Pre-select Eprom Type
.cmd_lf             DEFB cmd_lf_end - cmd_lf                                    ; length of command definition
                    DEFB LF                                                     ; command code
                    DEFM "J" , 0                                                ; keyboard sequense
                    DEFM "Next " , $8F , " type" , 0
                    DEFB (cmd_lf_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_lf_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_lf_end - cmd_lf                                    ; length of command definition
.cmd_lf_end

; Cursor Right
.cmd_right          DEFB cmd_right_end - cmd_right                              ; length of command definition
                    DEFB IN_RGT                                                 ; command code
                    DEFM IN_RGT , 0                                             ; keyboard sequense
                    DEFM $A3 , " Right" , 0
                    DEFB (cmd_right_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (cmd_right_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page
                    DEFB cmd_right_end - cmd_right                              ; length of command definition
.cmd_right_end

; Cursor Left
.cmd_left           DEFB cmd_left_end - cmd_left                                ; length of command definition
                    DEFB IN_LFT                                                 ; command code
                    DEFM IN_LFT , 0                                             ; keyboard sequense
                    DEFM $A3 , " Left" , 0
                    DEFB (cmd_left_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_left_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_left_end - cmd_left                                 ; length of command definition
.cmd_left_end

; Cursor Up
.cmd_up             DEFB cmd_up_end - cmd_up                                    ; length of command definition
                    DEFB IN_UP                                                  ; command code
                    DEFM IN_UP , 0                                              ; keyboard sequense
                    DEFM $A3 , " Up" , 0
                    DEFB (cmd_up_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_up_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_up_end - cmd_up                                    ; length of command definition
.cmd_up_end

; Cursor Down
.cmd_Down           DEFB cmd_down_end - cmd_down                                ; length of command definition
                    DEFB IN_DWN                                                 ; command code
                    DEFM IN_DWN , 0                                             ; keyboard sequense
                    DEFM $A3 , " Down" , 0
                    DEFB (cmd_down_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_down_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_down_end - cmd_down                                ; length of command definition
.cmd_down_end

; SHIFT Up  - Previous Dump Page
.cmd_sup            DEFB cmd_sup_end - cmd_sup                                  ; length of command definition
                    DEFB IN_SUP                                                 ; command code
                    DEFM IN_SUP , 0                                             ; keyboard sequense
                    DEFM "Previous " , $B1 , " Page" , 0
                    DEFB (cmd_sup_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_sup_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page, new column
                    DEFB cmd_sup_end - cmd_sup                                  ; length of command definition
.cmd_sup_end


; SHIFT Down  - Next Dump Page
.cmd_SDown          DEFB cmd_sdown_end - cmd_sdown                              ; length of command definition
                    DEFB IN_SDWN                                                ; command code
                    DEFM IN_SDWN , 0                                            ; keyboard sequense
                    DEFM "Next " , $B1 , " Page" , 0
                    DEFB (cmd_sdown_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (cmd_sdown_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_sdown_end - cmd_sdown                              ; length of command definition
.cmd_sdown_end

; DIAMOND Up  - Bottom of Bank Dump
.cmd_dup            DEFB cmd_dup_end - cmd_dup                                  ; length of command definition
                    DEFB IN_DUP                                                 ; command code
                    DEFM IN_DUP , 0                                             ; keyboard sequense
                    DEFM "Bot" , $DE , "m" , $FF , $BB , " " , $B1 , 0
                    DEFB (cmd_dup_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_dup_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_dup_end - cmd_dup                                  ; length of command definition
.cmd_dup_end

; DIAMOND Down  - Top of Bank Dump
.cmd_DDown          DEFB cmd_ddown_end - cmd_ddown                              ; length of command definition
                    DEFB IN_DDWN                                                ; command code
                    DEFM IN_DDWN , 0                                            ; keyboard sequense
                    DEFM "Top" , $FF , $BB , " " , $B1 , 0
                    DEFB (cmd_ddown_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (cmd_ddown_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_ddown_end - cmd_ddown                              ; length of command definition
.cmd_ddown_end

                    DEFB 1                                                      ; end of this topic

; @MBL  Memory Buffer Load
.cmd_mbl            DEFB cmd_mbl_end - cmd_mbl                                  ; length of command definition
                    DEFB Zprom_CC_mbl                                           ; command code
                    DEFM "MBL" , 0                                              ; keyboard sequense
                    DEFM $A9 , " " , $AD , " " , $BD , 0
                    DEFB (cmd_mbl_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_mbl_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_mbl_end - cmd_mbl                                  ; length of command definition
.cmd_mbl_end


; @MBS  Memory Buffer Save
.cmd_mbs            DEFB cmd_mbs_end - cmd_mbs                                  ; length of command definition
                    DEFB Zprom_CC_mbs                                           ; command code
                    DEFM "MBS" , 0                                              ; keyboard sequense
                    DEFM $A9 , " " , $AD , " Save" , 0
                    DEFB (cmd_mbs_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_mbs_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_mbs_end - cmd_mbs                                  ; length of command definition
.cmd_mbs_end

; @MBCL Memory Buffer Clear
.cmd_mbcl           DEFB cmd_mbcl_end - cmd_mbcl                                ; length of command definition
                    DEFB Zprom_CC_mbcl                                          ; command code
                    DEFM "MBCL" , 0                                             ; keyboard sequense
                    DEFM $80 , $A9 , " " , $AD , " Clear" , $80 , 0             ; text with tiny font...
                    DEFB (cmd_mbcl_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_mbcl_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00011000                                              ; command has help page, safe command
                    DEFB cmd_mbcl_end - cmd_mbcl                                ; length of topic command definition
.cmd_mbcl_end

; @ME   Memory Edit/Examine
.cmd_me             DEFB cmd_me_end - cmd_me                                    ; length of command definition
                    DEFB Zprom_CC_me                                            ; command code
                    DEFM "ME" , 0                                               ; keyboard sequense
                    DEFM $A9 , " " , $A7 , "/Exam" , $CF , "e" , 0
                    DEFB (cmd_me_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_me_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page, new column
                    DEFB cmd_me_end - cmd_me                                    ; length of command definition
.cmd_me_end

; @MV   Memory View
.cmd_mv             DEFB cmd_mv_end - cmd_mv                                    ; length of command definition
                    DEFB Zprom_CC_mv                                            ; command code
                    DEFM "MV" , 0                                               ; keyboard sequense
                    DEFM $A9 , " " , $9E , 0
                    DEFB (cmd_mv_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_mv_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, new column
                    DEFB cmd_mv_end - cmd_mv                                    ; length of command definition
.cmd_mv_end

; @MS   Memory Search
.cmd_ms             DEFB cmd_ms_end - cmd_ms                                    ; length of command definition
                    DEFB Zprom_CC_ms                                            ; command code
                    DEFM "MS" , 0                                               ; keyboard sequense
                    DEFM $A9 , " " , $BF , 0
                    DEFB (cmd_ms_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_ms_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_ms_end - cmd_ms                                    ; length of command definition
.cmd_ms_end


; @RBW  RAM Bank Write
.cmd_rbw            DEFB cmd_rbw_end - cmd_rbw                                  ; length of command definition
                    DEFB Zprom_CC_rbw                                           ; command code
                    DEFM "RBW" , 0                                              ; keyboard sequense
                    DEFM "Write" , $DF , "RAM " , $BB , 0
                    DEFB (cmd_rbw_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_rbw_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page, new column
                    DEFB cmd_rbw_end - cmd_rbw                                  ; length of command definition
.cmd_rbw_end


; @RBCL  Clear RAM Bank
.cmd_rbcl           DEFB cmd_rbcl_end - cmd_rbcl                                ; length of command definition
                    DEFB Zprom_CC_rbcl                                          ; command code
                    DEFM "RBCL" , 0                                             ; keyboard sequense
                    DEFM $80 , "Clear RAM " , $BB , $80 , 0
                    DEFB (cmd_rbcl_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_rbcl_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00011000                                              ; command has help page, safe
                    DEFB cmd_rbcl_end - cmd_rbcl                                ; length of command definition
.cmd_rbcl_end


; @RCLC  Clear RAM Card
.cmd_rclc           DEFB cmd_rclc_end - cmd_rclc                                ; length of command definition
                    DEFB Zprom_CC_rclc                                          ; command code
                    DEFM "RCLC" , 0                                             ; keyboard sequense
                    DEFM $80 , "Clear RAM " , $D8 , $80 , 0
                    DEFB (cmd_rclc_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_rclc_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00011000                                              ; command has help page, safe
                    DEFB cmd_rclc_end - cmd_rclc                                ; length of command definition
.cmd_rclc_end


; @BR Memory Bank Read
.cmd_br             DEFB cmd_br_end - cmd_br                                    ; length of command definition
                    DEFB Zprom_CC_br                                            ; command code
                    DEFM "BR" , 0                                               ; keyboard sequense
                    DEFM "Read from " , $A9 , " " , $BB , 0
                    DEFB (cmd_br_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_br_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_br_end - cmd_br                                    ; length of command definition
.cmd_br_end


; @BE  Memory Bank Edit
.cmd_be             DEFB cmd_be_end - cmd_be                                    ; length of command definition
                    DEFB Zprom_CC_be                                            ; command code
                    DEFM "BE" , 0                                               ; keyboard sequense
                    DEFM $A7 , " " , $A9 , " " , $BB , 0
                    DEFB (cmd_be_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_be_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_be_end - cmd_be                                    ; length of command definition
.cmd_be_end


; @BV  Memory Bank View
.cmd_bv             DEFB cmd_bv_end - cmd_bv                                    ; length of command definition
                    DEFB Zprom_CC_bv                                            ; command code
                    DEFM "BV" , 0                                               ; keyboard sequense
                    DEFM $9E , " " , $A9 , " " , $BB , 0
                    DEFB (cmd_bv_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_bv_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_bv_end - cmd_bv                                    ; length of command definition
.cmd_bv_end


; @BS  Memory Bank Search
.cmd_bs             DEFB cmd_bs_end - cmd_bs                                    ; length of command definition
                    DEFB Zprom_CC_bs                                            ; command code
                    DEFM "BS" , 0                                               ; keyboard sequense
                    DEFM $BF , " " , $A9 , " " , $BB , 0
                    DEFB (cmd_bs_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_bs_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_bs_end - cmd_bs                                    ; length of command definition
.cmd_bs_end

                    DEFB 1                                                      ; end of commands for this topic


; @EPROG  Program EPROM
.cmd_eprog          DEFB cmd_eprog_end - cmd_eprog                              ; length of command definition
                    DEFB Zprom_CC_eprog                                         ; command code
                    DEFM "EPROG" , 0                                            ; keyboard sequense
                    DEFM $80 , $B4 , " " , $8F , $80 , 0
                    DEFB (cmd_eprog_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (cmd_eprog_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB @00011000                                              ; command has help page, safe
                    DEFB cmd_eprog_end - cmd_eprog                              ; length of command definition
.cmd_eprog_end


; @FLBE  Flash Eprom Block Erase
.cmd_flbe           DEFB cmd_flbe_end - cmd_flbe                                ; length of command definition
                    DEFB Zprom_CC_flbe                                          ; command code
                    DEFM "FLBE" , 0                                             ; keyboard sequense
                    DEFM $80 , "Erase Flash " , $8F , $80 , 0
                    DEFB (cmd_flbe_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_flbe_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00011000                                              ; command has help page, safe
                    DEFB cmd_flbe_end - cmd_flbe                                ; length of command definition
.cmd_flbe_end

; @EPRD  Read EPROM
.cmd_eprd           DEFB cmd_eprd_end - cmd_eprd                                ; length of command definition
                    DEFB Zprom_CC_eprd                                          ; command code
                    DEFM "EPRD" , 0                                             ; keyboard sequense
                    DEFM $80 , "Read " , $8F , $80 , 0
                    DEFB (cmd_eprd_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_eprd_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00011000                                              ; command has help page, safe
                    DEFB cmd_eprd_end - cmd_eprd                                ; length of command definition
.cmd_eprd_end

; @EPCK  Check EPROM Bank
.cmd_epck           DEFB cmd_epck_end - cmd_epck                                ; length of command definition
                    DEFB Zprom_CC_epck                                          ; command code
                    DEFM "EPCK" , 0                                             ; keyboard sequense
                    DEFM "Check " , $8F , 0
                    DEFB (cmd_epck_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_epck_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_epck_end - cmd_epck                                ; length of command definition
.cmd_epck_end

; @EPVF   Verify EPROM Bank
.cmd_epvf           DEFB cmd_epvf_end - cmd_epvf                                ; length of command definition
                    DEFB Zprom_CC_epvf                                          ; command code
                    DEFM "EPVF" , 0                                             ; keyboard sequense
                    DEFM "V" , $FE , "ify " , $8F , 0
                    DEFB (cmd_epvf_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_epvf_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_epvf_end - cmd_epvf                                ; length of command definition
.cmd_epvf_end


; @COPY  Copy Application Card
.cmd_copy           DEFB cmd_copy_end - cmd_copy                                ; length of command definition
                    DEFB Zprom_CC_copy                                          ; command code
                    DEFM "COPY" , 0                                             ; keyboard sequense
                    DEFM "Copy " , $D7 , " " , $D8 , 0
                    DEFB (cmd_copy_help - Zprom_help) / 256                     ; high byte of rel. pointer
                    DEFB (cmd_copy_help - Zprom_help) % 256                     ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_copy_end - cmd_copy                                ; length of command definition
.cmd_copy_end


; @CLONE  Program (Blow) Application Card
.cmd_CLONE          DEFB cmd_CLONE_end - cmd_CLONE                              ; length of command definition
                    DEFB Zprom_CC_CLONE                                         ; command code
                    DEFM "CLONE" , 0                                            ; keyboard sequense
                    DEFM $80 , $B4 , " " , $D7 , " " , $D8 , $80 , 0
                    DEFB (cmd_CLONE_help - Zprom_help) / 256                    ; high byte of rel. pointer
                    DEFB (cmd_CLONE_help - Zprom_help) % 256                    ; low byte of rel. pointer
                    DEFB @00011000                                              ; command has help page, safe
                    DEFB cmd_CLONE_end - cmd_CLONE                              ; length of command definition
.cmd_CLONE_end


; @EV   View EPROM Bank
.cmd_ev             DEFB cmd_ev_end - cmd_ev                                    ; length of command definition
                    DEFB Zprom_CC_ev                                            ; command code
                    DEFM "EV" , 0                                               ; keyboard sequense
                    DEFM $9E , " " , $8F , " " , $BB , 0
                    DEFB (cmd_ev_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_ev_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page, new column
                    DEFB cmd_ev_end - cmd_ev                                    ; length of command definition
.cmd_ev_end

; @ES   Search in EPROM Bank
.cmd_es             DEFB cmd_es_end - cmd_es                                    ; length of command definition
                    DEFB Zprom_CC_es                                            ; command code
                    DEFM "ES" , 0                                               ; keyboard sequense
                    DEFM $BF , " " , $CF , " " , $8F , " " , $BB , 0
                    DEFB (cmd_es_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_es_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_es_end - cmd_es                                    ; length of command definition
.cmd_es_end

; @FLI  Flash Eprom Information
.cmd_fli            DEFB cmd_fli_end - cmd_fli                                  ; length of command definition
                    DEFB Zprom_CC_fli                                           ; command code
                    DEFM "FLI" , 0                                              ; keyboard sequense
                    DEFM "Flash " , $8F , " Info" , 0
                    DEFB (cmd_fli_help - Zprom_help) / 256                      ; high byte of rel. pointer
                    DEFB (cmd_fli_help - Zprom_help) % 256                      ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page, safe
                    DEFB cmd_fli_end - cmd_fli                                  ; length of command definition
.cmd_fli_end

; @ET     Define EPROM Type
.cmd_et             DEFB cmd_et_end - cmd_et                                    ; length of command definition
                    DEFB Zprom_CC_et                                            ; command code
                    DEFM "ET" , 0                                               ; keyboard sequense
                    DEFM $A5 , " " , $8F , " Type" , 0
                    DEFB (cmd_et_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_et_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010001                                              ; command has help page, new column
                    DEFB cmd_et_end - cmd_et                                    ; length of command definition
.cmd_et_end


; @EB     Define EPROM Bank
.cmd_eb             DEFB cmd_eb_end - cmd_eb                                    ; length of command definition
                    DEFB Zprom_CC_eb                                            ; command code
                    DEFM "EB" , 0                                               ; keyboard sequense
                    DEFM $A5 , " " , $8F , " " , $BB , 0
                    DEFB (cmd_eb_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_eb_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_eb_end - cmd_eb                                    ; length of command definition
.cmd_eb_end

; @ER     Define Bank Prog. Range
.cmd_er             DEFB cmd_er_end - cmd_er                                    ; length of command definition
                    DEFB Zprom_CC_er                                            ; command code
                    DEFM "ER" , 0                                               ; keyboard sequense
                    DEFM $A5 , " " , $BB , " " , $AB , 0
                    DEFB (cmd_er_help - Zprom_help) / 256                       ; high byte of rel. pointer
                    DEFB (cmd_er_help - Zprom_help) % 256                       ; low byte of rel. pointer
                    DEFB @00010000                                              ; command has help page
                    DEFB cmd_er_end - cmd_er                                    ; length of command definition
.cmd_er_end
                    DEFB 0                                                      ; end of command topic



; *******************************************************************************************************************
;
.Zprom_help         DEFB $7F
                    DEFM $AF , $81 , " V1.4.2 - " , $90 , " " , $C8 , " " , $8F , " " , $B4 , "m" , $FE , $81 , $7F
                    DEFM $B6 , $7F
                    DEFM $B7 , $7F
                    DEFM $7F , $80 , $AF , " may " , $F2 , $F1 , "us" , $DA , $DE , " produce illegal copies" , $FF , $90 , $7F
                    DEFM $C9 , "s. It was design" , $DA , $FA , " creative work - " , $F2 , " piracy!" , $80 , 0


.topic_cursor_help  DEFB $7F
                    DEFM "Please ref" , $FE , $DF , $BA , " help..." , 0


.topic_memory_help  DEFB $7F
                    DEFM $A1 , "se " , $BA , "s work on a 16K " , $AA , " " , $AE , " " , $D6 , "at " , $AF , $7F
                    DEFM "allocates on activa" , $CD , ". " , $A1 , " " , $AE , $D5 , "us" , $DA , "as a virtual" , $7F
                    DEFM $BC , $DF , "be " , $B5 , "m" , $DA , "on " , $8F , ", " , $BE , "ed" , $D3 , "a " , $CC , " from RAM, " , $7F
                    DEFM $BE , "ed" , $D3 , "a " , $BC , " from " , $8F , " or m" , $FD , "ipulat" , $DA , $D2 , $B3 , $A9 , $7F
                    DEFM $A7 , "or. " , $A1 , " " , $AE , $D5 , $C2 , $DA , "as " , $91 , "-" , $9F , "." , 0


.topic_eprom_help   DEFB $7F
                    DEFM $A1 , "se " , $BA , "s m" , $FD , "ipulate" , $B3 , $CF , "s" , $FE , "t" , $DA , $8F , " " , $CF , " slot 3." , $7F
                    DEFM $A1 , " " , $8F , $D5 ,  $C2 , $DA , "by us" , $CE , " " , $BC , " numb" , $FE , "s 00h - 3Fh," , $7F
                    DEFM "wh" , $FE , "e 3Fh ref" , $FE , "s " , $DE , $B3 , $DE , "p " , $BC , "." , 0


.topic_info_help    DEFB $7F
                    DEFM "Th" , $D4 , " sec" , $CD , $DB , "cov" , $FE , " gen" , $FE , "al aspects" , $FF , $AF , $D1 , "how" , $7F
                    DEFM $DE , " " , $CF , "stall " , $AF , "'" , $DA , $8F , " " , $C9 , "s " , $CF , $B3 , $90 , "." , 0


.cmd_mbl_help       DEFB 12
                    DEFM $BD , " a " , $CC , " " , $CF , $DE , $B3 , "16K " , $AE , ". A start " , $C2 , " " , $D4 , $7F
                    DEFM $EF , "i" , $DA , "(" , $91 , "-" , $9F , ")," , $D1 , "a " , $AC , " check" , $D5 , "made" , $7F
                    DEFM $FB , " " , $BE , $CE , ". " , $CB , "s may " , $F2 , " exceed" , $B3 , $AE , ". " , $A1 , $7F
                    DEFM $AE , $D5 , $F2 , " clear" , $DA , $FB , " " , $BE ,  $CE , ". " , $C3 , "s resided" , $7F
                    DEFM $CF , $B3 , $AC , " of" , $B3 , $CC , $DB , "be ov" , $FE , "written. Sev" , $FE , "al" , $7F
                    DEFM $CC , "s may" , $F1 , $BE , $DA , "at diff" , $FE , "ent " , $C2 , "es" , $DF , $FA , "m " , $A2 , $7F
                    DEFM "necessary " , $C9 , " " , $BC , "." , 0


.cmd_mbs_help       DEFB 12
                    DEFM "Save" , $B3 , $E1 , " " , $9B , " of" , $B3 , $AA , $7F
                    DEFM $AE , " from" , $B3 , $EF , "i" , $DA , $AC , "," , $DF , "a " , $CC , " " , $CF , " " , $7F
                    DEFM "one of" , $B3 , "resident RAM devices." , 0


.cmd_mbcl_help      DEFB 12
                    DEFM $C7 , $7F , $7F
                    DEFM "Clear (fill)" , $B3 , $AA , " " , $AE , $D3 , "FFh (255d). All" , $7F
                    DEFM "present " , $C4 , "s " , $CF , $B3 , $AE , $DB , "be lost." , 0


.cmd_me_help        DEFB 12
                    DEFM $A7 , " or " , $9E , $B3 , $9B , " of" , $B3 , $AA , " " , $AE , " beg" , $CF , "n" , $CE , $7F
                    DEFM "at" , $B3 , $EF , "i" , $DA , $C2 , " " , $CF , " " , $AC , " " , $91 , "-" , $9F , "." , $7F
                    DEFM $A7 , $CE , $DB , "be p" , $FE , $FA , "m" , $DA , "at" , $B3 , $AA , " cell" , $DF , "which " , $A2 , $7F
                    DEFM $A4 , $D5 , "po" , $CF , "t" , $CE , " at. Make a backup of" , $B3 , $AE , " " , $FB , $7F
                    DEFM $A8 , $CE , " - " , $D6 , $D4 , " ensures recov" , $FE , "y from " , $A8 , $CE , " problems." , $7F
                    DEFM $C3 , "s " , $CF , " " , $AC , " 20h-7Fh c" , $FD , $F1 , "typ" , $DA , "at" , $B3 , "keyboard " , $CF , $B3 , $7F
                    DEFM $9D , " " , $DC , "a, o" , $A2 , "rw" , $D4 , "e ent" , $FE , " " , $94 , " values. See also " , $87 , "MV." , 0


.cmd_mv_help        DEFM 12 , $7F , "See help page dur" , $CE , " " , $9E , "/" , $A7 , " (right side" , $FF , "screen)." , 0


.cmd_ms_help        DEFB 12
                    DEFM $BF , " " , $FA , " a " , $94 , " str" , $CE , " or" , $FC , $9D , " str" , $CE , " " , $CF , $B3 , $AA , $7F
                    DEFM $AE , " beg" , $CF , "n" , $CE , " at a " , $A6 , "d start " , $C2 , "." , $7F
                    DEFM $9D , " " , $C0 , $D5 , "match" , $DA , "as ent" , $FE , "ed. " , $9D , " str" , $CE , $D5 , $A6 , "d" , $7F
                    DEFM $D2 , " a ' as" , $B3 , "first char. " , $F4 , "" , $D5 , $94 , " " , $C4 , " " , $C0 , "." , $7F
                    DEFM "Type " , $94 , " " , $C4 , "s " , $D2 , "out spaces, eg. FF00AA1B . " , $9E , " Mode " , $D4 , $7F
                    DEFM "ent" , $FE , $DA , "at found " , $C2 , " if a match occurred, o" , $A2 , "rw" , $D4 , "e" , $7F
                    DEFM $C0 , " ends at " , $DE , "p " , $AE , "/" , $BC , " boundary." , 0

.cmd_rbw_help       DEFB 12
                    DEFM "Write" , $B3 , $AC , " " , $9B , " of" , $B3 , "" , $AE , " into" , $B3 , "" , $EF , "ied RAM" , $7F
                    DEFM $BC , " (previously write-enabled" , $D3 , "magnet in front" , $FF , "slot)." , $7F
                    DEFM "Action" , $D5 , "" , $F2 , " allowed if" , $B3 , $BC , "" , $D5 , "owned by a RAM Filing" , $7F
                    DEFM "Device. Try" , $DF , "relocate" , $B3 , "magnet if a 'write-protected'" , $7F
                    DEFM "message appears -" , $B3 , "switch inside" , $B3 , "RAM " , $D8 , " may " , $F2 , " have" , $7F
                    DEFM "enabled properly. Remember" , $DF , "remove magnet when finished;" , $7F
                    DEFM "a system reset" , $DB , "otherwise 'install' a normal RAM " , $D8 , "." , 0

.cmd_br_help        DEFB 12
                    DEFM "Read" , $B3 , "" , $AA , " " , $BC , " " , $9B , " in" , $B3 , $E1 , " " , $AC , " into the" , $7F
                    DEFM $AA , " " , $AE , ". Any " , $BC , " (00h-FFh) may" , $F1 , "" , $BE , "ed, whether from" , $7F
                    DEFM "a RAM " , $D8 , " or" , $FC , "" , $8F , " " , $D8 , " (or inside" , $B3 , "" , $D7 , "; 00h-1Fh)." , $7F
                    DEFM "Make sure that you have selected" , $B3 , "proper " , $AC , " " , $FB , $7F
                    DEFM $BE , "ing from a " , $AA , " " , $BC , "." , 0

.cmd_be_help        DEFB 12
                    DEFM $A7 , " (and " , $9E , ")" , $B3 , "" , $9B , "" , $FF , "a " , $AA , " " , $BC , ". All available" , $7F
                    DEFM $BC , "s in" , $B3 , "system may" , $F1 , "selected. However, RAM Filing" , $7F
                    DEFM "" , $D8 , "s must NOT" , $F1 , "altered - you may destroy your own " , $CC , "s." , $7F
                    DEFM $A1 , " main purpose" , $FF , "this " , $BA , "" , $D5 , "to " , $A8 , $B3 , "" , $9B , "" , $7F
                    DEFM "of" , $B3 , "write-enabled Pseudo RAM " , $D8 , "." , 0

.cmd_bv_help        DEFM 12 , $7F , "As " , $87 , "BE but only" , $DF , "view " , $AA , " " , $BC , " " , $9B , "." , 0

.cmd_bs_help        DEFM 12 , $7F
                    DEFM "Search in specified memory bank. Please refer to " , $87 , "MS command." , 0

.cmd_rbcl_help      DEFB 12
                    DEFM $C7 , $7F
                    DEFM "Clear (reset)" , $B3 , "" , $9B , "" , $FF , "a " , $EF , "ied " , $AA , " (RAM) " , $BC , "." , $7F
                    DEFM "Action" , $D5 , "" , $F2 , " allowed if" , $B3 , $BC , "" , $D5 , "owned by a RAM Filing" , $7F
                    DEFM "Device. WARNING: don't clear a " , $BC , " if" , $B3 , "" , $9B , " are" , $7F
                    DEFM "part" , $FF , "resident " , $C9 , " data structures (whether " , $ED , "-" , $7F
                    DEFM "table code or M.T.H.) that was previously installed into" , $7F
                    DEFM "the operating system. A System Crash" , $DB , "most likely occur" , $7F
                    DEFM "if 'partial' " , $C9 , "s" , $DD , "re-entered or " , $ED , "ted." , 0

.cmd_rclc_help      DEFB 12
                    DEFM $C7 , $7F
                    DEFM "Clear (reset all " , $BC , "s of)" , $B3 , "Pseudo RAM " , $D8 , "." , $7F
                    DEFM "Action" , $D5 , "" , $F2 , " allowed if" , $B3 , "" , $D8 , "" , $D5 , "allocated" , $DF , "a RAM" , $7F
                    DEFM "Filing Device. If" , $B3 , "RAM " , $D8 , " contains " , $C9 , " data" , $7F
                    DEFM "structures then perform" , $FC , "external soft reset IMMEDIATELY" , $7F
                    DEFM "after" , $B3 , "" , $D8 , " has been reset - this performs" , $B3 , "equivalent" , $7F
                    DEFM "action" , $FF , "removing" , $B3 , "" , $D8 , " from" , $B3 , "slot. Don't activate" , $7F
                    DEFM "INDEX; OZ gets very confused" , $D1 , "system handles" , $DB , "be lost." , 0

.cmd_copy_help      DEFB 12
                    DEFM "Copy a " , $D7 , " " , $D8 , " into" , $B3 , "Pseudo RAM " , $D8 , " (of equal size)." , $7F
                    DEFM "This" , $D5 , "" , $F2 , " allowed if" , $B3 , "RAM " , $D8 , " (in" , $B3 , "" , $EF , "ied slot)" , $7F
                    DEFM "is allocated" , $DF , "a RAM Filing Device." , 0

.cmd_clone_help     DEFB 12
                    DEFM $C7 , $7F , $7F
                    DEFM "Clone (blow" , $DF , "" , $8F , ")" , $FC , "entire " , $D7 , " " , $D8 , " from" , $B3 , "" , $EF , "ied" , $7F
                    DEFM "slot into" , $FC , "empty " , $8F , " " , $D8 , " in slot 3. Filing Devices and" , $7F
                    DEFM "empty slots" , $DD , "" , $F2 , " allowed" , $DF , "be replicated." , $7F
                    DEFM "Make sure" , $DF , "have selected" , $B3 , "correct " , $8F , " type" , $D3 , $87 , "ET" , $7F
                    DEFM "to blow" , $B3 , "data properly on" , $B3 , "" , $8F , " " , $D8 , "." , 0

.cmd_enter_help     DEFM 12 , $7F , "Activates" , $B3 , $BA , $B3 , "menu bar" , $D5 , "po" , $CF , "t" , $CE , " at." , 0


.cmd_tab_help       DEFB 12
                    DEFM $A1 , " " , $83 , " key" , $D5 , "only us" , $DA , "dur" , $CE , " " , $AA , " " , $A8 , $CE , "." , $7F
                    DEFM "Press" , $CE , " " , $83 , $DB , $DE , "ggle" , $B3 , $A4 , " movement " , $CF , $7F
                    DEFM $B3 , $94 , " " , $B2 , " " , $DC , "a or" , $B3 , $9D , " " , $B2 , " " , $DC , "a. " , $A1 , $7F
                    DEFM $A4 , " posi" , $CD , " still po" , $CF , "ts at" , $B3 , "same " , $AA , " cell." , 0


.cmd_lf_help        DEFM 12 , $7F , "See " , $87 , "ET." , 0


.cmd_esc_help       DEFM 12 , $7F , "Abort" , $FC , "activat" , $DA , $BA , "." , 0


.cmd_right_help     DEFB 12
                    DEFM $A0 , $7F
                    DEFM "Moves" , $B3 , $A4 , " " , $DE , $B3 , "next " , $94 , "/" , $9D , " " , $C4 , " " , $CF , " " , $A2 , $7F
                    DEFM $B2 , " w" , $CF , "dow. " , $A1 , " " , $A4 , " wraps " , $DE , $B3 , "first " , $C4 , " at " , $A2 , $7F
                    DEFM $E1 , " l" , $CF , "e if mov" , $DA , "beyond" , $B3 , "16" , $D6 , " " , $C4 , "." , 0


.cmd_left_help      DEFB 12
                    DEFM $A0 , $7F
                    DEFM "Moves" , $B3 , $A4 , " " , $DE , $B3 , "previous " , $94 , "/" , $9D , " " , $C4 , " " , $CF , " " , $A2 , $7F
                    DEFM $B2 , " w" , $CF , "dow. " , $A1 , " " , $A4 , " wraps " , $DE , $B3 , "16" , $D6 , " " , $C4 , " at " , $A2 , $7F
                    DEFM $E1 , " l" , $CF , "e if mov" , $DA , "beyond" , $B3 , "first " , $C4 , "." , 0


.cmd_up_help        DEFB 12
                    DEFM "Us" , $DA , $DE , " move" , $B3 , "menu bar upwards" , $D1 , $CF , " " , $7F
                    DEFM $9E , "/" , $A7 , " " , $A9 , "/" , $8F , " " , $BA , "s." , $7F
                    DEFM "If" , $B3 , $A4 , $D5 , "mov" , $DA , "beyond" , $B3 , "first l" , $CF , "e " , $CF , $B3 , $B2 , $7F
                    DEFM "w" , $CF , "dow, it" , $DB , "be scroll" , $DA , "1 l" , $CF , "e down " , $D0 , $B3 , $9B , " of" , $7F
                    DEFM "16 low" , $FE , " " , $C2 , "es (relative " , $DE , $B3 , $E1 , ")" , $DB , "be" , $7F
                    DEFM "d" , $D4 , "played. " , $C1 , " wrap occurs at " , $91 , $D1 , $9F , ", because" , $7F
                    DEFM $AF , " m" , $FD , "ipulates " , $C4 , " " , $CF , " 16K blocks." , 0


.cmd_down_help      DEFM 12 , $7F , $A1 , " rev" , $FE , "se ac" , $CD , $FF , $85 , "." , 0


.cmd_sup_help       DEFB 12
                    DEFM $A0 , $7F
                    DEFM "Move" , $DF , "& d" , $D4 , "play" , $B3 , $9B , $FF , "128 " , $C4 , "s low" , $FE , " " , $C2 , "es" , $7F
                    DEFM "relative " , $DE , $B3 , $E1 , " " , $DE , "p " , $C2 , " " , $CF , $B3 , $B2 , " w" , $CF , "dow." , $7F
                    DEFM $A1 , " " , $A4 , " rema" , $CF , "s at" , $B3 , $E1 , " w" , $CF , "dow posi" , $CD , "." , 0


.cmd_sdown_help     DEFM 12 , $7F , $A1 , " rev" , $FE , "se ac" , $CD , $FF , $86 , $85 , "." , 0


.cmd_dup_help       DEFB 12
                    DEFM $A0 , $7F
                    DEFM "Move" , $DF , "& d" , $D4 , "play" , $B3 , $9B , " of" , $B3 , "first" , $7F
                    DEFM "128 " , $C2 , "es of" , $B3 , $BC , "/" , $AE , "." , $7F
                    DEFM $A1 , " " , $A4 , " rema" , $CF , "s at" , $B3 , $E1 , " w" , $CF , "dow posi" , $CD , "." , 0


.cmd_ddown_help     DEFM 12 , $7F , $A1 , " rev" , $FE , "se ac" , $CD , $FF , $87 , $85 , "." , 0


.cmd_eprog_help     DEFB 12
                    DEFM $C7 , $7F
                    DEFM $A1 , " " , $E1 , " " , $8F , " " , $BC , $D1 , $AC , $DB , "be " , $B5 , "m" , $DA , $D2 , $7F
                    DEFM $A2 , " " , $9B , " of" , $B3 , $AA , " " , $AE , " at" , $B3 , $F0 , "cal " , $7F
                    DEFM $AC , ". Be" , $FA , "e " , $B5 , "m" , $CE , "," , $B3 , $BC , $DB , "be check" , $DA , $FA , " " , $FD , $7F
                    DEFM "empty " , $BC , ". " , $A1 , " screen" , $D5 , "temporarily switch" , $DA , "off dur" , $CE , $7F
                    DEFM $B5 , "m" , $CE , ". A v" , $FE , "ifica" , $CD , $D5 , $A2 , "n p" , $FE , $FA , "m" , $DA , $DE , " make sure" , $7F
                    DEFM $D6 , "at" , $B3 , $8F , " " , $9B , $D5 , "equal " , $DE , $B3 , $AA , " " , $AE , "." , $7F
                    DEFM "NB: Flash Eproms are blown with the screen switched on." , 0

.cmd_flbe_help      DEFB 12
                    DEFM "Erase complete Flash Eprom or a single block. This is" , $7F
                    DEFM "equivalent of using UV-light on a conventional Eprom." , $7F
                    DEFM "Each block spans 4 banks (64K). The 1Mb Flash Eprom" , $7F
                    DEFM "consists of 16 blocks (00h to 0Fh). The top most" , $7F
                    DEFM "block 0Fh defines banks $3C to $3F. Responding Yes" , $7F
                    DEFM "on the initial prompt will erase the whole card." , 0

.cmd_eprd_help      DEFB 12
                    DEFM $C7 , $7F
                    DEFM $A1 , " " , $9B , " of" , $B3 , $E1 , " " , $BC , $D1 , $AC , " of" , $B3 , $8F , $7F
                    DEFM $DB , "be read " , $CF , $DE , $B3 , $F0 , "cal " , $AE , " at" , $B3 , $A6 , "d " , $AC , "." , $7F
                    DEFM "Any previous " , $9B , " " , $CF , $B3 , $AE , $DB , "be lost." , 0


.cmd_epck_help      DEFB 12
                    DEFM "Check " , $D6 , "at" , $B3 , $E1 , " " , $BC , " " , $CF , $B3 , $E1 , " " , $AC , $7F
                    DEFM "of" , $B3 , $8F , $D5 , "free" , $DF , "be " , $B5 , "med." , $7F
                    DEFM "(A bl" , $FD , "k " , $8F , " conta" , $CF , "s only " , $C4 , "s" , $FF , "value FFh)" , $7F
                    DEFM "If" , $B3 , $8F , " " , $BC , " " , $AC , " conta" , $CF , "s us" , $DA , $C4 , "s," , $FC , $FE , "ror msg." , $7F
                    DEFM $DB , "be d" , $D4 , "played" , $D1 , "a warn" , $CE , " bleep " , $ED , "ted." , 0


.cmd_epvf_help      DEFB 12
                    DEFM "V" , $FE , "ify" , $B3 , $9B , " of" , $B3 , $AA , " " , $AE , " at" , $B3 , $E1 , " " , $AC , $7F
                    DEFM $D2 , $B3 , $E1 , " " , $BC , " of" , $B3 , $CF , "stall" , $DA , $8F , " (" , $DE , $F1 , "equal)." , 0


.cmd_ev_help        DEFB 12
                    DEFM $9E , $B3 , $9B , " of" , $B3 , $8F , " at" , $B3 , $E1 , " " , $BC , " " , $CF , " " , $A2 , $7F
                    DEFM $E1 , " " , $AC , " " , $CF , " " , $94 , $D1 , $9D , " representa" , $CD , "." , $7F
                    DEFM "See also " , $87 , "ME" , $D1 , $87 , "MV." , 0


.cmd_es_help        DEFB 12
                    DEFM $BF , " " , $CF , " " , $E1 , " " , $8F , " " , $BC , "." , $7F
                    DEFM "See " , $87 , "MS " , $FA , " fur" , $A2 , "r " , $9A , "."
                    DEFB 0

.cmd_fli_help       DEFB 12
                    DEFM "Display information about the Flash" , $7F
                    DEFM "Eprom card. The command will return the" , $7F
                    DEFM "Chip name, number of available 64K blocks" , $7F
                    DEFM "and total size of memory on the card."
                    DEFB 0

.cmd_et_help        DEFB 12
                    DEFM $A5 , $B3 , $8F , " type." , $A1 , " follow" , $CE , " " , $8F , "'s" , $DD , "available:" , $7F
                    DEFM $81 , "32K" , $81 , ", " , $81 , "128K" , $81 , ", " , $81 , "256K" , $81 , " UV light Eproms or "
                    DEFM $81 , "FLASH" , $81 , " Eprom." , $7F
                    DEFM "To select, type ei" , $A2 , "r" , $B3 , "size or press" , $7F
                    DEFM $87 , "J" , $DF , "choose one of" , $B3 , "available types." , $7F , $7F
                    DEFM "Please make sure " , $D6 , "at" , $B3 , "correct " , $8F , " type" , $D5 , "selected," , $7F
                    DEFM $FB , " " , $FD , "y " , $8F , " " , $B5 , "m" , $CE , $D5 , $ED , "ted." , 0


.cmd_eb_help        DEFB 12
                    DEFM $A5 , $B3 , $E1 , " " , $8F , " " , $BC , $DF , "be us" , $DA , "by relat" , $DA , $BA , "s." , $7F
                    DEFM $8F , " " , $BC , "s" , $DD , $A6 , "d " , $CF , $B3 , $AC , " 00h - 3Fh, wh" , $FE , "e 3Fh" , $7F
                    DEFM $D4 , $B3 , "physical ref" , $FE , "ence of" , $B3 , $DE , "p " , $BC , " of" , $B3 , $8F , ". " , $7F
                    DEFM $AF , " " , $CF , "t" , $FE , "nally adresses " , $BC , "s" , $DF , "slot 3 (C0h - FFh)." , 0


.cmd_er_help        DEFB 12
                    DEFM $A5 , $B3 , $E1 , " " , $8F , " " , $AC , $DF , "be us" , $DA , "by related" , $7F
                    DEFM $BA , "s. " , $A1 , " " , $AC , $D5 , "also us" , $DA , "at " , $AA , " " , $AE , " " , $BA , "s." , 0


.inf_about_help     DEFB 12
                    DEFM "In some of" , $B3 , "Info Help Topics" , $B3 , $8A , " , " , $89 , " symbols" , $7F
                    DEFM $CF , "dicates a rela" , $CD , $DF , $FD , "o" , $A2 , "r Help Topic. All " , $DE , "pics c" , $FD , $7F
                    DEFM "be read " , $CF , " r" , $D0 , "om ord" , $FE , ". To ga" , $CF , " absolute knowledge of" , $7F
                    DEFM "concepts, please study '" , $C8 , " Static Structures' " , $CF , $7F
                    DEFM $90 , " Develop" , $FE , "s' Notes V3." , 0

.inf_slot3_help     DEFB 12
                    DEFM $A1 , "re" , $D5 , "no system call" , $DF , "check whe" , $A2 , "r" , $FC , "empty " , $8F , " has" , $7F
                    DEFM "been " , $CF , "s" , $FE , "t" , $DA , "or " , $F2 , ". Only if a " , $D8 , " " , $D9 , $D5 , "present, " , $FD , $7F
                    DEFM $8F , $D5 , "recogn" , $D4 , $DA , "by" , $B3 , $D8 , " M" , $FD , "ag" , $FE , ". Us" , $CE , $B3 , $87 , "EV cmd." , $7F
                    DEFM $DE , " view a " , $BC , " " , $CF , " slot 3 while no " , $8F , $D5 , $CF , "s" , $FE , "ted," , $DB , $F2 ,  $7F
                    DEFM "affect" , $B3 , "system. Only spurious " , $C4 , "s" , $DB , "be d" , $D4 , "played." , $7F
                    DEFM $B4 , "m" , $CE , $FC , "empty slot has no effect ei" , $A2 , "r. First, " , $A2 , "re" , $7F
                    DEFM $DC , " " , $C4 , "s 'used'," , $D1 , "second, " , $B5 , "m" , $CE , $DB , $F2 , " succeed." , 0

.inf_cardman_help   DEFB 12
                    DEFM $A1 , " C.M." , $D5 , $FD , " " , $CF , "t" , $FE , "rupt s" , $FE , "vice rout" , $CF , "e " , $CF , $B3 , "op" , $FE , "at" , $CE , $7F
                    DEFM "system. It " , $F5 , "ly moni" , $DE , "rs" , $B3 , "ext" , $FE , "nal slots. Bo" , $D6 , " " , $CB , $7F
                    DEFM $8F , " " , $D9 , "s , " , $D7 , " " , $D9 , "s" , $DD , $CF , "st" , $FD , "tly recogn" , $D4 , "ed. Th" , $D4 , $7F
                    DEFM "happens " , $DE , "o when " , $AF , " has " , $B5 , "m" , $DA , "a " , $D9 , ", " , $D6 , "ough " , $A2 , $7F
                    DEFM "flap has " , $F2 , " been opened. " , $A1 , " recogn" , $D4 , $DA , $D7 , " " , $D9 , " " , $ED , "tes" , $7F
                    DEFM $A2 , " C.M." , $DF , $CF , "itiate" , $FC , $CF , "stalla" , $CD , " of" , $B3 , $C9 , "," , $7F
                    DEFM $D6 , "ough only partially. " , $8A , "Install." , $FF , $AF , "'" , $DA , $D7 , $89 , 0

.inf_cardheader_help
                    DEFB 12
                    DEFM $F0 , "fies" , $FC , $8F , " " , $D8 , " as a " , $CB , " " , $8F , " (m" , $FD , "ag" , $DA , "by FILER)" , $7F
                    DEFM "or" , $FC , $C8 , " " , $D8 , ". Top " , $BC , " (3Fh) " , $C2 , " 3FFEh &" , $7F
                    DEFM "3FFFh conta" , $CF , "s 'OZ' " , $FA , " Appl. " , $D8 , " , 'oz' " , $FA , " " , $CB , " " , $8F , "." , $7F
                    DEFM $A1 , " C.Hdr. also " , $CF , $FA , "ms" , $FF , "available " , $BC , "s on" , $B3 , $D8 , " (see" , $7F
                    DEFM $87 , "" , $D8 , " " , $CF , " INDEX). " , $A1 , " Appl. " , $D8 , " conta" , $CF , "s a unique " , $D8 , " ID" , $7F
                    DEFM "at 3FF8h-3FFAh" , $D1 , $FD , " Appl. Front DOR at 3FC0h. If no C.Hdr." , $7F
                    DEFM $D4 , " blown on" , $B3 , $8F , "," , $B3 , $90 , " " , $F0 , "fies" , $B3 , "slot as empty." , 0


.inf_cardid_help    DEFB 12
                    DEFM $D8 , " ID's " , $FA , " " , $C9 , " " , $D7 , "'s " , $F8 , " only" , $F1 , "obta" , $CF , $DA , "from" , $7F
                    DEFM "Cambridge Comput" , $FE , ". " , $A1 , " unique " , $D8 , " ID assures " , $D6 , "at" , $B3 , $D8 , $7F
                    DEFM "M" , $FD , "ag" , $FE , $D5 , "always aw" , $DC , " of" , $B3 , "ext" , $FE , "nally " , $CF , "s" , $FE , "t" , $DA , "applica-" , $7F
                    DEFM $CD , "s. Unknown effects " , $F8 , " happen if sev" , $FE , "al " , $D8 , "s sh" , $DC , $B3 , $7F
                    DEFM "same ID. If you haven't aquir" , $DA , $FD , "y ID's, borrow one " , $FA , $7F
                    DEFM "development use from a comm" , $FE , "cial " , $D8 , ", but remove it" , $7F
                    DEFM $FB , " " , $CF , "s" , $FE , "t" , $CE , " your own " , $C9 , " " , $D8 , "." , 0


.inf_instepr_help   DEFB 12
                    DEFM "When" , $B3 , $C9 , " " , $D7 , " has been " , $B5 , "m" , $DA , "(" , $D2 , " " , $D9 , ")," , $7F
                    DEFM "it has already been partially " , $CF , "stall" , $DA , "by" , $B3 , "C.M. " , $A1 , $7F
                    DEFM "INDEX only d" , $D4 , "plays" , $B3 , $C9 , " name (no shortcut). To" , $7F
                    DEFM $CF , "stall" , $B3 , $D7 , " " , $D8 , " prop" , $FE , "ly, remove" , $B3 , $D8 , " from " , $A2 , $7F
                    DEFM "slot, close" , $B3 , "flap," , $D1 , $A2 , "n " , $CF , "s" , $FE , "t" , $B3 , $D8 , " aga" , $CF , "." , $7F
                    DEFM "You may also issue a soft reset" , $D3 , $87 , "PURGE in INDEX." , $7F
                    DEFM "Atten" , $CD , ": " , $A1 , " C.M. " , $F8 , " get confus" , $DA , "if " , $F0 , "cal " , $D8 , " ID's" , $7F
                    DEFM "ex" , $D4 , "ts on " , $CF , "stall" , $DA , $D7 , "'s. " , $8A , $D8 , " ID," , $D8 , " " , $D9 , $89 , 0


.inf_cardconv_help  DEFB 12
                    DEFM "All " , $C9 , " data structures" , $DD , "reentr" , $FD , "t, i.e. " , $F8 , " be" , $7F
                    DEFM "put " , $FD , "ywh" , $FE , "e " , $CF , " a " , $BC , " " , $D2 , "out" , $B3 , "ne" , $DA , $DE , " re-assemble. By" , $7F
                    DEFM "conven" , $CD , " it" , $D5 , "adv" , $D4 , $DA , $DE , " put " , $A2 , "m " , $CF , $B3 , $DE , "p " , $BC , " (3Fh)" , $7F
                    DEFM $DE , "ge" , $A2 , "r " , $D2 , $B3 , $C8 , " " , $D7 , " " , $D9 , $D1 , "Front DOR." , $7F
                    DEFM "Th" , $D4 , " improves" , $B3 , "me" , $D6 , "od" , $FF , "extend" , $CE , " a multi-" , $C9 , $7F
                    DEFM $D7 , ". Put " , $C9 , " DORs " , $DE , "ge" , $A2 , "r" , $D1 , "use a shar" , $DA , "global" , $7F
                    DEFM "recursive " , $DE , "ken table" , $DF , "m" , $CF , "imize size" , $FF , "data structures." , 0


.inf_romprog_help   DEFB 12
                    DEFM "To prevent " , $FD , "y d" , $D4 , "astrous system crashes, always blow " , $A2 , $7F
                    DEFM $C9 , " code first (one or sev" , $FE , "al " , $C9 , "s at dif-" , $7F
                    DEFM "f" , $FE , "ent " , $BC , "s), " , $A2 , "n" , $B3 , $C9 , " data structures," , $D1 , "fi-" , $7F
                    DEFM "nally when all" , $D5 , "check" , $DA , $DE , $F1 , "at" , $B3 , "right places, " , $B5 , $7F
                    DEFM $A2 , " " , $C9 , " " , $D7 , " " , $D9 , " " , $D2 , $B3 , "Front DOR" , $D1 , $D8 , " ID." , $7F
                    DEFM "Please " , $F2 , "e, " , $D6 , "at" , $B3 , "system" , $D5 , "unaw" , $DC , " of" , $B3 , "code" , $D1 , "data" , $7F
                    DEFM "structures until a " , $D8 , " ID" , $D5 , "blown on" , $B3 , $D8 , "." , 0


.inf_banknum_help   DEFB 12
                    DEFM "Each slot " , $F8 , " " , $C2 , " 1MB. " , $90 , " views " , $AA , " " , $CF , " " , $BC , "s" , $FF , "16K," , $7F
                    DEFM "switch" , $DA , "around " , $CF , $B3 , "Z80 logical " , $C2 , " space. A slot con-" , $7F
                    DEFM "ta" , $CF , "s max. 64 " , $BC , "s (00h-3Fh), i.e. 64*16K = 1024K. " , $A1 , " fol-" , $7F
                    DEFM "low" , $CE , " " , $BC , " numb" , $FE , "s" , $DD , "wir" , $DA , $DE , " slots: 0:00h-3Fh, 1:40h-7Fh" , $7F
                    DEFM "2:80h-BFh, 3:C0h-FFh. Appl.data.structs. ref" , $FE , $DF , $BC , "s rela-" , $7F
                    DEFM "tive " , $DE , $B3 , "bot" , $DE , "m " , $BC , " of" , $B3 , "slot, ie. 3Fh ref" , $FE , " " , $DE , $B3 , $DE , "p" , $7F
                    DEFM $BC , ". " , $C8 , " " , $BC , " ref" , $FE , "ences" , $DD , $D6 , "us slot " , $CF , "dependent." , 0


.inf_eprtypes_help  DEFB 12
                    DEFM "It" , $D5 , "import" , $FD , "t " , $D6 , "at" , $B3 , "correct " , $8F , " type" , $D5 , "set up " , $FB , $7F
                    DEFM $8F , " " , $B5 , "m" , $CE , $D5 , $ED , "ted. You" , $DB , $F2 , " succe" , $DA , $CF , $7F
                    DEFM $B5 , "m" , $CE , " a 128K" , $D3 , "a 32K type setup!" , $7F
                    DEFM "If you do succeed" , $D3 , "a setup comb" , $CF , "a" , $CD , $D1 , "a diff" , $FE , "ent" , $7F
                    DEFM $8F , " type " , $CF , "stall" , $DA , $A2 , "n you" , $DD , "lucky. But don't rely on" , $7F
                    DEFM $C4 , "s hav" , $CE , " been " , $B5 , "m" , $DA , "prop" , $FE , "ly on " , $D6 , "at " , $8F , "!" , 0


.inf_eprprec_help   DEFB 12
                    DEFM "Always " , $FE , "ase " , $8F , "s at least " , $D6 , "ree times - " , $D6 , $D4 , " ensures no" , $7F
                    DEFM "unstable " , $C4 , "s " , $F2 , " prop" , $FE , "ly " , $FE , "ased. Secondly, nev" , $FE , " " , $ED , "te" , $7F
                    DEFM $A2 , " 'Catalogue " , $8F , "' " , $BA , " " , $CF , $B3 , $CB , "r on a cle" , $FD , " " , $8F , ";" , $7F
                    DEFM "a " , $CB , " " , $D9 , $DB , "au" , $DE , "matically" , $F1 , "blown, which " , $A2 , "n c" , $FD , $F2 , $7F
                    DEFM "be us" , $DA , "as" , $FC , $C9 , " " , $D7 , ". (" , $8F , " must" , $F1 , $FE , "as" , $DA , "aga" , $CF , ")" , 0


.inf_comds_help     DEFB 12
                    DEFM $AF , " has two levels" , $FF , $BA , " access. " , $A1 , " first level " , $D4 , $7F
                    DEFM $A2 , " " , $BA , "s d" , $D4 , "play" , $DA , $CF , $B3 , "ma" , $CF , " w" , $CF , "dow. Us" , $CE , $B3 , "arrow" , $7F
                    DEFM "keys" , $D1 , $88 , $DB , $ED , "te" , $B3 , $BA , ". " , $A1 , "y cause no" , $7F
                    DEFM "ac" , $CD , "s " , $D6 , "at c" , $FD , $F2 , $F1 , "rev" , $FE , "sed. " , $A1 , " second level " , $DC , $7F
                    DEFM $BA , "s" , $FF , "a high" , $FE , " priority or " , $F2 , " us" , $DA , "v" , $FE , "y often." , $7F
                    DEFM "S" , $CF , "ce " , $B5 , "m" , $CE , " , read" , $CE , $FC , $8F , $D5 , "a s" , $FE , "ious" , $7F
                    DEFM "ac" , $CD , "," , $B3 , $BA , "s must" , $F1 , "typ" , $DA , "at" , $B3 , "keyboard." , 0


.inf_numconv_help   DEFB 12
                    DEFM "All " , $A9 , $D1 , $8F , " " , $9A , ", " , $CF , "put" , $FF , $C2 , "es " , $D0 , $7F
                    DEFM "numb" , $FE , "s" , $DD , "p" , $FE , " " , $F4 , " " , $CF , " " , $94 , "a" , $F7 , " " , $F2 , "a" , $CD , ". Howev" , $FE , "," , $7F
                    DEFM "you have" , $B3 , "possibility" , $DF , "use " , $F7 , " numb" , $FE , "s " , $CF , "stead by" , $7F
                    DEFM $EF , "y" , $CE , " a '~' " , $CF , " front of" , $B3 , $C2 , "/numb" , $FE , ". It" , $D5 , $F2 , $7F
                    DEFM "possible" , $DF , "ent" , $FE , " " , $F7 , " numb" , $FE , "s " , $CF , $B3 ,  $A7 , " " , $A9 , " " , $B9 , "." , 0


.inf_cli_help       DEFB 12
                    DEFM "If m" , $FD , "y diff" , $FE , "ent " , $CC , "s has" , $DF , "be blown on " , $8F , ", a CLI " , $CC , $7F
                    DEFM "may help" , $DF , "get " , $D6 , $CE , "s done au" , $DE , "matically. Simply activate" , $7F
                    DEFM $C5 , "+K, type " , $C5 , "ZE (ex. " , $AF , ")," , $D1 , $A2 , "n beg" , $CF , " " , $B5 , "m" , $CE , " " , $CC , "s." , $7F
                    DEFM "Use shortcut sequenses" , $DF , "activate " , $BA , "s" , $D1 , "type " , $CC , " na-" , $7F
                    DEFM "mes" , $D3 , "complete pa" , $D6 , ". " , $A1 , "n s" , $DE , "p CLI" , $D3 , $C5 , "-K, " , $BE , " 'K.sgn'" , $7F
                    DEFM $CF , $DE , " PD., remove '~A-k'" , $D1 , "save renam" , $DA , $CC , " as pla" , $CF , " text." , $7F
                    DEFM $A1 , " " , $CC , " " , $F8 , " " , $A2 , "n" , $F1 , $ED , "ted" , $D1 , "do" , $B3 , $B5 , "m" , $CE , " " , $FA , " you!" , 0


.inf_fileditor_help DEFB 12
                    DEFM "S" , $CF , "ce " , $AF , " uses a 16K " , $AA , " " , $AE , " " , $FA , " " , $CF , "t" , $FE , "mediate s" , $DE , "rage" , $7F
                    DEFM "of " , $CC , "s" , $DF , "be " , $B5 , "m" , $DA , "on " , $8F , ", it" , $D5 , "also well suited" , $7F
                    DEFM "as a " , $CB , " " , $A7 , "or Utility. " , $BD , " a " , $CC , $D3 , $87 , "MBL, " , $A8 , " " , $A2 , $7F
                    DEFM $CC , " " , $CF , $B3 , $AE , $D3 , $87 , "ME," , $D1 , "save it back" , $D3 , $87 , "MBS." , 0


.inf_fileutil_help  DEFB 12
                    DEFM "S" , $CF , "ce " , $AF , " allows bo" , $D6 , " " , $BE , $CE , $DF , "& sav" , $CE , " " , $CC , "s from " , $A2 , $7F
                    DEFM $A9 , " " , $AD , ", it " , $F8 , " easily" , $F1 , "m" , $FD , "ag" , $DA , $DE , " m" , $FE , "ge " , $CC , "s or" , $7F
                    DEFM "split a " , $CC , $D3 , $AF , ". Th" , $D4 , $D5 , "useful when splitt" , $CE , " " , $FD , $7F
                    DEFM $8F , " " , $BC , " " , $CF , $DE , " separate " , $CC , "s. Howev" , $FE , "," , $B3 , $AE , " only h" , $FD , "-" , $7F
                    DEFM "dles " , $CC , "s " , $D2 , $CF , " a 16K " , $AC , ". Th" , $D4 , $D5 , "adequate " , $FA , " gen" , $FE , "al" , $7F
                    DEFM $C9 , " code m" , $FD , "agement. " , $A1 , " trick" , $D5 , $DE , " use" , $B3 , $87 , "ER" , $7F
                    DEFM "(" , $A5 , " " , $BB , " " , $AB , ") " , $BA , " " , $DE , "ge" , $A2 , "r" , $D3 , $87 , "MBL" , $D1 , $87 , "MBS." , 0

.inf_pseudoram_help DEFB 12
                    DEFM "Simply insert" , $B3 , "" , $D8 , ". " , $A1 , " system acknowledge it as" , $FC , $8F , $7F
                    DEFM "because it" , $D5 , "write-protected by default. Place" , $B3 , "magnet in" , $7F
                    DEFM "front of" , $B3 , "" , $D8 , " when data" , $D5 , "written. Remove" , $B3 , "magnet if" , $7F
                    DEFM "a soft reset must" , $F1 , "issued - otherwise" , $B3 , "system fetches it" , $7F
                    DEFM "as a normal RAM " , $D8 , ". There" , $D5 , "no battery backup on" , $B3 , "" , $D8 , "." , $7F
                    DEFM "Removing it from" , $B3 , "slot" , $DB , "clear" , $B3 , "" , $AA , ". " , $BD , "ed" , $7F
                    DEFM $C9 , " software must" , $F1 , "'installed' by a soft reset to" , $7F
                    DEFM $F1 , "acknowledged properly by" , $B3 , "operating system." , 0

.inf_romcopy_help   DEFB 12
                    DEFM $A1 , " act" , $FF , "produc" , $CE , " illegal copies" , $FF , $C8 , " " , $D8 , "s" , $D5 , "a" , $7F
                    DEFM "viola" , $CD , $B3 , "copyright law. " , $AF , " was made" , $DF , $CF , "troduce a" , $7F
                    DEFM "possibility" , $DF , "create " , $90 , " " , $C9 , "s " , $D2 , "out" , $B3 , "ne" , $DA , "of a" , $7F
                    DEFM "Z80 Cross Assembl" , $FE , $D1 , $FD , " " , $8F , " " , $B4 , "m" , $FE , " on a sta" , $CD , "ary" , $7F
                    DEFM "comput" , $FE , "," , $D1 , $DE , " extend" , $B3 , $AC , $FF , "softw" , $DC , " available " , $FA , $7F
                    DEFM $A2 , " " , $90 , ". Any m" , $D4 , "use" , $FF , $AF , $DB , "drastically und" , $FE , "m" , $CF , "e " , $A2 , $7F
                    DEFM $90 , " softw" , $DC , " market. Please don't let" , $B3 , $B5 , "m" , $FE , "s down!" , 0


.inf_aboutzp_help   DEFB 12
                    DEFM $AF , $D5 , $FD , " one-" , $CF , "st" , $FD , "tia" , $CD , " " , $C9 , " which allocates 16K" , $7F
                    DEFM "cont" , $CF , "uous " , $AA , " on entry. Due " , $DE , " stra" , $CF , " of" , $B3 , "op" , $FE , "at" , $CE , $7F
                    DEFM "system's " , $AA , ", " , $AF , " won't run on a st" , $D0 , "ard " , $90 , ". " , $A1 , " m" , $CF , "i-" , $7F
                    DEFM "mum requirement" , $D5 , "a 128K RAM " , $CF , " slot 1. Th" , $D4 , $DB , "allow room" , $7F
                    DEFM $FA , " " , $CC , " s" , $DE , "rage" , $D1 , "runn" , $CE , $FF , $90 , " " , $C9 , "s. Int" , $FE , "Logic" , $7F
                    DEFM "recommend 1MB RAM " , $FA , $B3 , $90 , " " , $C8 , " Assembl" , $FE , " Workbench" , $7F
                    DEFM $DE , " allow m" , $FD , "agement" , $FF , "large " , $C9 , " projects." , 0

.Zprom_MTH_END
