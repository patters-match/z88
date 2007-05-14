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
        xdef    Reset                           ; [Kernel1]/reset.asm
        xdef    ExpandMachine                   ; [Kernel1]/reset.asm

        xdef    OSAlmMain                       ; [Kernel1]/osalm.asm

        xdef    RstRdPanelAttrs                 ; [Kernel1]/nqsp.asm
        xdef    OSNqMain                        ; [Kernel1]/nqsp.asm
        xdef    OSSpMain                        ; [Kernel1]/nqsp.asm

        xdef    OSSr_Fus                        ; [Kernel1]/ossr.asm
        xdef    FreeMemHandle                   ; [Kernel1]/ossr.asm
        xdef    OSSR_main                       ; [Kernel1]/ossr.asm

        xdef    OSEpr                           ; [Kernel1]/eprom.asm

        xdef    OSIsq                           ; [Kernel1]/scrdrv1.asm
        xdef    OSWsq                           ; [Kernel1]/scrdrv1.asm
        xdef    OSOutMain                       ; [Kernel1]/scrdrv1.asm
        xdef    StorePrefixed                   ; [Kernel1]/scrdrv1.asm
        xdef    InitUserAreaGrey                ; [Kernel1]/scrdrv1.asm
        xdef    Chr2ScreenCode                  ; [Kernel1]/scrdrv1.asm
        xdef    ScrDrvAttrTable                 ; [Kernel1]/scrdrv1.asm
        xdef    GetCrsrYX                       ; [Kernel1]/scrdrv1.asm
        xdef    GetWindowNum                    ; [Kernel1]/scrdrv1.asm
        xdef    VDU2ChrCode                     ; [Kernel1]/scrdrv1.asm
        xdef    Zero_ctrlprefix                 ; [Kernel1]/scrdrv1.asm
        xdef    ScrD_GetNewXY                   ; [Kernel1]/scrdrv1.asm
        xdef    ScrD_PutChar                    ; [Kernel1]/scrdrv1.asm
        xdef    ScrD_PutByte                    ; [Kernel1]/scrdrv1.asm

        xdef    CopyMTHApp_Help                 ; [Kernel1]/mth1.asm
        xdef    CopyMTHHelp_App                 ; [Kernel1]/mth1.asm
        xdef    DrawTopicWd                     ; [Kernel1]/mth1.asm
        xdef    DrawMenuWd2                     ; [Kernel1]/mth1.asm
        xdef    DoHelp                          ; [Kernel1]/mth1.asm
        xdef    Help2Wd_bottom                  ; [Kernel1]/mth1.asm
        xdef    Help2Wd_Top                     ; [Kernel1]/mth1.asm
        xdef    InitHelpWd                      ; [Kernel1]/mth1.asm
        xdef    OpenAppHelpFile                 ; [Kernel1]/mth1.asm
        xdef    GetFirstCmdHelp                 ; [Kernel1]/mth1.asm
        xdef    Get2ndCmdHelp                   ; [Kernel1]/mth1.asm
        xdef    Get2ndTopicHelp                 ; [Kernel1]/mth1.asm
        xdef    GetTpcAttrByNum                 ; [Kernel1]/mth1.asm
        xdef    MTHPrintKeycode                 ; [Kernel1]/mth1.asm
        xdef    MTH_ToggleLT                    ; [Kernel1]/mth1.asm

        xdef    ChkStkLimits                    ; [Kernel1]/process1.asm
        xdef    ClearMemDE_HL                   ; [Kernel1]/process1.asm
        xdef    ClearUnsafeArea                 ; [Kernel1]/process1.asm
        xdef    Mailbox2Stack                   ; [Kernel1]/process1.asm
        xdef    OSPoll                          ; [Kernel1]/process1.asm

        xdef    ChkCardChange                   ; [Kernel1]/card1.asm
        xdef    StoreCardIDs                    ; [Kernel1]/card1.asm

        xdef    InitHandle                      ; [Kernel1]/misc1.asm
        xdef    RAMxDOR                         ; [Kernel1]/misc1.asm

        xdef    FileNameDate                    ; [Kernel1]/filesys1.asm
        xdef    IsSpecialHandle                 ; [Kernel1]/filesys1.asm
        xdef    OpenMem                         ; [Kernel1]/filesys1.asm
        xdef    OSDel                           ; [Kernel1]/filesys1.asm
        xdef    OSRen                           ; [Kernel1]/filesys1.asm

        xdef    MemCallAttrVerify               ; [Kernel1]/memory1.asm

        xdef    Key2Chr_tbl                     ; [Kernel1]/key2chrt.asm

        xdef    OSMap                           ; [Kernel1]/osmap.asm

        xdef    OSSci                           ; [Kernel1]/ossci.asm

        xdef    OSCli                           ; [Kernel1]/oscli.asm

        xdef    OSSiHrd1                        ; [Kernel1]/ossi1.asm
        xdef    OSSiSft1                        ; [Kernel1]/ossi1.asm
        xdef    OSSiEnq1                        ; [Kernel1]/ossi1.asm
        xdef    OSSiFtx1                        ; [Kernel1]/ossi1.asm
        xdef    OSSiFrx1                        ; [Kernel1]/ossi1.asm
        xdef    OSSiTmo1                        ; [Kernel1]/ossi1.asm

        xdef    OSPrtInit                       ; [Kernel1]/printer.asm
        xdef    OSPrtPrint                      ; [Kernel1]/printer.asm

        include "kernel1.def"                   ; get upper kernel references and map them into lower kernel project...

ENDIF
