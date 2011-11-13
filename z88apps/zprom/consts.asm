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


     MODULE Constants

     XDEF EprType_Prompt, StartRange_prompt, EndRange_Prompt, bank_prompt, addr_prompt
     XDEF flnm_prompt, Epvf_prompt, Epck_prompt, eprd_prompt, mbl_prompt, mbs_prompt, clear_prompt
     XDEF EprType_banner, EprBank_banner, ProgRange_banner, StartRange_banner
     XDEF startfile_banner, mrbl_banner, RamBank_banner, report_banner, eprd_banner
     XDEF epvf_banner, epck_banner, startmbs_banner, endmbs_banner
     XDEF mbsfln_banner, mbs_banner, mbl_banner, mbcl_banner
     XDEF EditMem_banner, ViewMem_banner, ViewEpr_banner
     XDEF DumpWindows, DispEditinfo
     XDEF Ms_banner, Es_banner, SearchAddr_prompt, Searchstrg_prompt, bs_banner
     XDEF eprg_prompt, eprg_banner
     XDEF fprg_prompt, fprg_banner
     XDEF ESCprompt, KeyPrompt
     XDEF Errmsg_lookup
     XDEF Appl_banner, Status_banner, EprTypeMsg, EprBankMsg, EpromTypes
     XDEF ProgRangeMsg
     XDEF ApplMenuWindow
     XDEF logo
     XDEF YesNoPrompt
     XDEF rbl_banner, editram_banner, viewram_banner
     XDEF RamWrt_banner, Ramcrd_banner, Membank_prompt
     XDEF rclc_prompt
     XDEF Memrd_banner
     XDEF RamCl_banner
     XDEF rbw_prompt, rbr_prompt
     XDEF RamBankMsg
     XDEF rbclwarn_prompt, rbcl_prompt, rclc2_prompt
     XDEF Copy_banner, copy_prompt, copy2_prompt
     XDEF Clone_banner, clone_prompt
     XDEF FlEprFormat0_banner, FlEprFormat_banner, FlEprFormat_prompt, FleprFmt0_prompt
     XDEF EprErase_prompt
     XDEF fble_banner, fble_prompt
     XDEF FlEprInfo_banner
     XDEF FlashEprTypes
     XDEF Error_banner
     XDEF fltst_prompt

     INCLUDE "defs.asm"
     INCLUDE "flashepr.def"


; ****************************************************************************************************************
;
; Static data definitions
;

.EpromTypes         DEFB 3                              ; 4 selection items (0 - 3)
                    DEFW EprSignal32 , Epr32            ; <Eprom Programming Signals> , <Ptr. to Mnemonic>
                    DEFW EprSignal128, Epr128
                    DEFW EprSignal128, Epr256
                    DEFW FlashEprom, FlashEpr

.Epr32              DEFM "32K", 0
.Epr128             DEFM "128K", 0
.Epr256             DEFM "256K", 0
.FlashEpr           DEFM "FLASH", 0

.FlashEprTypes
                    DEFB 7
                    DEFW FE_I28F004S5, 8, mnem_i004
                    DEFW FE_I28F008SA, 16, mnem_i008
                    DEFW FE_I28F008S5, 16, mnem_i8s5
                    DEFW FE_AM29F010B, 8, mnem_am010b
                    DEFW FE_AM29F040B, 8, mnem_am040b
                    DEFW FE_AM29F080B, 16, mnem_am080b
                    DEFW FE_AMIC29F040B, 8, mnem_amic40b

.mnem_i004          DEFM "INTEL 28F004S5 (512Kb, 8 x 64Kb sectors)", 0
.mnem_i008          DEFM "INTEL 28F008SA (1024Kb, 16 x 64Kb sectors)", 0
.mnem_i8S5          DEFM "INTEL 28F008S5 (1024Kb, 16 x 64Kb sectors)", 0
.mnem_am010b        DEFM "AMD AM29F010B (128Kb, 8 x 16K sectors)", 0
.mnem_am040b        DEFM "AMD AM29F040B (512Kb, 8 x 64K sectors)", 0
.mnem_am080b        DEFM "AMD AM29F080B (1024Kb, 16 x 64K sectors)", 0
.mnem_amic40b       DEFM "AMIC AM29F040B (512Kb, 8 x 64K sectors)", 0

.Error_banner       DEFM "Error:", 0
.status_banner      DEFM "ZPROM SETTINGS:", 0
.viewmem_banner     DEFM "VIEW MEMORY", 0
.editmem_banner     DEFM "EDIT MEMORY", 0
.editram_banner     DEFM "EDIT MEM. BANK", 0
.viewepr_banner     DEFM "VIEW EPROM BANK", 0
.viewram_banner     DEFM "VIEW MEM. BANK", 0
.mbcl_banner        DEFM "Clear Memory Buffer", 0
.Ramcl_banner       DEFM "Clear RAM Bank", 0
.Ramcrd_banner      DEFM "Clear RAM Card", 0
.mbl_banner         DEFM "Load File into Buffer", 0
.rbl_banner         DEFM "Load buffer into RAM Bank", 0
.startfile_banner   DEFM "Load File at start range", 0
.EprType_banner     DEFM "Define Eprom Type", 0
.Eprd_banner        DEFM "Read Eprom Range into Buffer", 0
.Memrd_banner       DEFM "Read Memory Bank Range into Buffer", 0
.RamWrt_banner      DEFM "Write RAM Bank at Range", 0
.copy_banner        DEFM "Copy Application Card to RAM Card", 0
.clone_banner       DEFM "Clone Application Card to EPROM", 0
.Eprg_banner        DEFM "Program Eprom Bank at Range", 0
.Fprg_banner        DEFM "Program Flash Eprom at Range", 0
.EprBank_banner     DEFM "Define Eprom Bank (00h-3Fh)", 0
.FlEprFormat0_banner DEFM "Erase Flash Eprom", 0
.FlEprFormat_banner DEFM "Erase Flash Eprom Sector", 0
.FlEprInfo_banner   DEFM "Flash Eprom Information", 0
.ProgRange_banner   DEFM "Define Eprom Range (0000h-3FFFh)", 0
.startmbs_banner    DEFM "Define Start Range to save", 0
.endmbs_banner      DEFM "Define End Range to save", 0
.mbsfln_banner      DEFM "Filename for Buffer Range", 0
.epvf_banner        DEFM "Verify Eprom Bank at Range", 0
.epck_banner        DEFM "Check Eprom Bank at Range", 0
.ms_banner          DEFM "SEARCH IN MEMORY", 0
.es_banner          DEFM "SEARCH IN EPROM", 0
.bs_banner          DEFM "SEARCH IN BANK", 0
.report_banner      DEFM "Report:", 0

.epck_prompt        DEFM "Eprom Bank at Range is NOT USED.", 0
.EprType_prompt     DEFM "Enter Eprom size in K or press ", 1, $2B, "J:", 0
.epvf_prompt        DEFM "Eprom Range verified.", 0
.eprg_prompt        DEFM "Eprom Bank programmed.", 0
.fprg_prompt        DEFM "Flash Eprom Bank programmed.", 0
.fble_prompt        DEFM "Flash Eprom Sector erased.", 0
.mbs_prompt         DEFM "Buffer Range saved to file.", 0
.rbw_prompt         DEFM "Buffer Range written to RAM bank.", 0
.mbl_prompt         DEFM "File loaded into buffer.", 0
.flnm_prompt        DEFM "Enter Filename:", 0
.startrange_prompt  DEFM "Enter Start Range:", 0
.endrange_prompt    DEFM "Enter End Range:", 0
.bank_prompt        DEFM "Enter Bank Number:", 0
.MemBank_prompt     DEFM "Define Memory Bank (00h-FFh):", 0
.searchAddr_prompt  DEFM "Enter Start Search Address:", 0
.searchStrg_prompt  DEFM "Enter Search String:", 0
.addr_prompt        DEFM "Enter Offset Address:", 0
.eprd_prompt        DEFM "Eprom Range copied to buffer.", 0
.rbr_prompt         DEFM "Memory Bank Range copied to buffer.", 0
.clear_prompt       DEFM "Buffer reset.", 0
.rbclwarn_prompt    DEFM "WARNING: Card contains Application Software.", 0
.rbcl_prompt        DEFM "RAM Bank is cleared.", 0
.rclc_prompt        DEFM "Enter slot number of RAM Card:", 0
.copy_prompt        DEFM "Enter slot number of ROM Card:", 0
.copy2_prompt       DEFM "ROM Card is successfully copied.", 0
.rclc2_prompt       DEFM "RAM Card is cleared.", 0
.clone_prompt       DEFM "EPROM Card successfully programmed.", 0
.FlEprFormat_prompt DEFM "Flash Eprom Sector (00h-0Fh):", 0
.FleprFmt0_prompt   DEFM "Erase complete Flash Eprom?", 0
.EprErase_prompt    DEFM "Flash Eprom erased completely.", 0
.fltst_prompt       DEFM "Messages are available in ", '"', "/eprlog", '"', " file.", 0
.ESCPrompt          DEFM 1, "2JC", 1, "3@", 32, 34
                    DEFM 1, "F", "Press ", 1, $E4, " to resume", 1, "F"
                    DEFM 1, "2JN", 0

.KeyPrompt          DEFM 1, "2JC", 1, "3@", 32, 34
                    DEFM 1, "F", "Press any key to continue", 1, "F"
                    DEFM 1, "2JN", 0

.EprTypeMsg         DEFM "Eprom Type", 0
.EprBankMsg         DEFM "Eprom Bank", 0
.ProgRangeMsg       DEFM "Buffer Range", 0
.RamBankMsg         DEFM "Memory Bank", 0

.Errmsg_lookup      DEFW Error_msg_00
                    DEFW Error_msg_01
                    DEFW Error_msg_02
                    DEFW Error_msg_03
                    DEFW Error_msg_03
                    DEFW Error_msg_05
                    DEFW Error_msg_06
                    DEFW Error_msg_07
                    DEFW Error_msg_08
                    DEFW Error_msg_09
                    DEFW Error_msg_10
                    DEFW Error_msg_11
                    DEFW Error_msg_12
                    DEFW Error_msg_13
                    DEFW Error_msg_14
                    DEFW Error_msg_15
                    DEFW Error_msg_16
                    DEFW Error_msg_17
                    DEFW Error_msg_18
                    DEFW Error_msg_19
                    DEFW Error_msg_20
                    DEFW Error_msg_21
                    DEFW Error_msg_22
                    DEFW Error_msg_23

.Error_Msg_00       DEFM "Illegal Hex Value.", 0
.Error_Msg_01       DEFM "Syntax Error.", 0
.Error_Msg_02       DEFM "Too large integer.", 0
.Error_Msg_03       DEFM "String not found.", 0
.Error_Msg_05       DEFM "File I/O error.", 0
.Error_Msg_06       DEFM "Buffer/Bank Range exceeded.", 0
.Error_Msg_07       DEFM "File exceeds Buffer Boundary.", 0
.Error_Msg_08       DEFM "Illegal Bank Reference.", 0
.Error_Msg_09       DEFM "Illegal Range Definition.", 0
.Error_Msg_10       DEFM "Buffer Range saved partially.", 13, 10
                    DEFM "No room for file.", 0
.Error_Msg_11       DEFM "Eprom already used at ", 0
.Error_Msg_12       DEFM "Incorrect match found in Eprom at ", 0
.Error_msg_13       DEFM "Byte incorrectly blown in Eprom at ", 0
.Error_msg_14       DEFM "Unknown Eprom type.", 0
.Error_msg_15       DEFM "File exists, overwrite?", 0
.Error_msg_16       DEFM "Slot is used by RAM filing system.", 0
.Error_msg_17       DEFM "RAM Card was write-protected.", 0
.Error_msg_18       DEFM "ROM Card not available in slot.", 0
.Error_msg_19       DEFM "Slot 3 is reserved for empty EPROM.", 0
.Error_msg_20       DEFM "Slot 3 contains Application Card.", 0
.Error_msg_21       DEFM 0
.Error_msg_22       DEFM "Flash Eprom Sector couldn't be formatted.", 0
.Error_msg_23       DEFM "Flash Eprom was not available in slot.", 0

.ApplMenuWindow     DEFM 1, "2C2", 1, "T"                     ; select window for output, tiny font...
                    DEFM " LOAD FILE INTO BUFFER", 10, 13
                    DEFM " VIEW BUFFER", 10, 13
                    DEFM " VIEW EPROM BANK", 10, 13
                    DEFM " DEFINE EPROM BANK", 10, 13
                    DEFM " EPROM PROGRAMMING RANGE", 10, 13
                    DEFM " SELECT EPROM TYPE", 1, "T", 0

.DumpWindows        DEFM 1, 55, 35, '2', 32+1, 32, 32+73, 32+8, 129                 ; Dump window
                    DEFM 1, 55, 35, '3', 108, 32, 48, 40, 129                       ; Dump Info window
                    DEFM 1, 50, 73, '3'                       ; select info window
                    DEFM 1, "3+TR", 1, "2A", 32+16            ; Tiny & reverse applied at top line
                    DEFM 1, "2JC", 1, "3@", 32, 32, 0         ; Cursor at top left corner - Display banner centre justified

.DispEditInfo       DEFM 1, "3-TR", 1, "2JN", 10, 13          ; normal justification
                    DEFM "Bottom Bank  ", 1, 43, 1, 243
                    DEFM "Top Bank     ", 1, 43, 1, 242
                    DEFM "Page Up    ", 1, 45, 1, 243
                    DEFM "Page Down  ", 1, 45, 1, 242
                    DEFM "Cursor  ", 1, 240, 1, 241, 1, 242, 1, 243
                    DEFM "Hex/Ascii    ", 1, 226
                    DEFM "Quit Dump    ", 1, $E4
                    DEFM 1, "2C2", 1, "2+C", 0                ; select & clear window '2' for dump output
