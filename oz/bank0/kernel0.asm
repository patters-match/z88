; **************************************************************************************************
; OZ kernel in Bank 0, starting at address $C000.
;
; This file is part of the Z88 operating system, OZ      0000000000000000      ZZZZZZZZZZZZZZZZZZZ
;                                                       000000000000000000   ZZZZZZZZZZZZZZZZZZZ
; OZ is free software; you can redistribute it and/    0000            0000              ZZZZZ
; or modify it under the terms of the GNU General      0000            0000            ZZZZZ
; Public License as published by the Free Software     0000            0000          ZZZZZ
; Foundation; either version 2, or (at your option)    0000            0000        ZZZZZ
; any later version. OZ is distributed in the hope     0000            0000      ZZZZZ
; that it will be useful, but WITHOUT ANY WARRANTY;    0000            0000    ZZZZZ
; without even the implied warranty of MERCHANTA-       000000000000000000   ZZZZZZZZZZZZZZZZZZZZ
; BILITY or FITNESS FOR A PARTICULAR PURPOSE. See        0000000000000000  ZZZZZZZZZZZZZZZZZZZZ
; the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with OZ; see the file
; COPYING. If not, write to:
;                                  Free Software Foundation, Inc.
;                                  59 Temple Place-Suite 330,
;                                  Boston, MA 02111-1307, USA.
;
; Implementation, comments, and definitions
; (C) Jorma Oksanen (jorma.oksanen@gmail.com), 2003
; (C) Thierry Peycru (pek@users.sf.net), 2005-2006
; (C) Gunther Strube (gbs@users.sf.net), 2005-2006
;
; $Id$
;***************************************************************************************************

        Module Kernel_Lower16K

        org $C000

IF COMPILE_BINARY
        xdef    Reset2                          ; bank7/reset2.asm
        xdef    Reset5                          ; bank7/reset5.asm
        xdef    OSAlmMain                       ; bank7/osalm.asm
        xdef    RstRdPanelAttrs                 ; bank7/nqsp.asm
        xdef    OSNqMain                        ; bank7/nqsp.asm
        xdef    OSSpMain                        ; bank7/nqsp.asm
        xdef    OSSr_Fus                        ; bank7/ossr.asm
        xdef    FreeMemHandle                   ; bank7/ossr.asm
        xdef    OSSR_main                       ; bank7/ossr.asm
        xdef    OSEprTable                      ; bank7/eprom.asm

        xdef    OSIsq                           ; bank7/scrdrv1.asm
        xdef    OSWsq                           ; bank7/scrdrv1.asm
        xdef    OSOutMain                       ; bank7/scrdrv1.asm
        xdef    StorePrefixed                   ; bank7/scrdrv1.asm
        xdef    InitUserAreaGrey                ; bank7/scrdrv1.asm
        xdef    Chr2ScreenCode                  ; bank7/scrdrv1.asm
        xdef    ScrDrvAttrTable                 ; bank7/scrdrv1.asm
        xdef    GetCrsrYX                       ; bank7/scrdrv1.asm
        xdef    GetWindowNum                    ; bank7/scrdrv1.asm
        xdef    VDU2ChrCode                     ; bank7/scrdrv1.asm
        xdef    Zero_ctrlprefix                 ; bank7/scrdrv1.asm
        xdef    ScrD_GetNewXY                   ; bank7/scrdrv1.asm
        xdef    ScrD_PutChar                    ; bank7/scrdrv1.asm
        xdef    ScrD_PutByte                    ; bank7/scrdrv1.asm

        xdef    CopyMTHApp_Help                 ; bank7/mth1.asm
        xdef    CopyMTHHelp_App                 ; bank7/mth1.asm
        xdef    DrawTopicWd                     ; bank7/mth1.asm
        xdef    DrawMenuWd2                     ; bank7/mth1.asm
        xdef    DoHelp                          ; bank7/mth1.asm
        xdef    Help2Wd_bottom                  ; bank7/mth1.asm
        xdef    Help2Wd_Top                     ; bank7/mth1.asm
        xdef    InitHelpWd                      ; bank7/mth1.asm
        xdef    OpenAppHelpFile                 ; bank7/mth1.asm

        xdef    ChkStkLimits                    ; bank7/process1.asm
        xdef    ClearMemDE_HL                   ; bank7/process1.asm
        xdef    ClearUnsafeArea                 ; bank7/process1.asm
        xdef    Mailbox2Stack                   ; bank7/process1.asm
        xdef    OSPoll                          ; bank7/process1.asm
        xdef    ChkCardChange                   ; bank7/card1.asm
        xdef    StoreCardIDs                    ; bank7/card1.asm
        xdef    InitHandle                      ; bank7/misc1.asm
        xdef    RAMDORtable                     ; bank7/misc1.asm
        xdef    RAMxDOR                         ; bank7/misc1.asm
        xdef    FileNameDate                    ; bank7/filesys1.asm
        xdef    IsSpecialHandle                 ; bank7/filesys1.asm
        xdef    OpenMem                         ; bank7/filesys1.asm
        xdef    OSDel                           ; bank7/filesys1.asm
        xdef    OSRen                           ; bank7/filesys1.asm
        xdef    MemCallAttrVerify               ; bank7/memory1.asm
        xdef    Key2Chr_tbl                     ; bank7/key2chrt.asm
        xdef    KeymapTable                     ; mth/keymap.asm
        xdef    OSMap                           ; bank7/osmap.asm
        xdef    OSSci                           ; bank7/ossci.asm
        xdef    OSCli                           ; bank7/oscli.asm

        include "../bank7/kernel7.def"          ; get kernel references from bank 7 and map them into bank 0 project...
        include "../mth/keymap.def"             ; get references for keymaps in MTH bank and bind them into bank 0 project...
ENDIF
