; **************************************************************************************************
; OZ kernel in Bank 7, starting at address $8000.
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
; $Id$
;***************************************************************************************************

        Module Kernel_Upper16K

        org $8000

IF COMPILE_BINARY
        xdef    ExtQualifiers                   ; bank0/kbd.asm
        xdef    ResetTimeout                    ; bank0/nmi.asm
        xdef    InitBufKBD_RX_TX                ; bank0/buffer.asm
        xdef    Reset3                          ; bank0/reset13.asm
        xdef    NQAin                           ; bank0/process2.asm
        xdef    AddRAMCard                      ; bank0/cardmgr.asm
        xdef    NqSp_ret                        ; bank0/spnq0.asm
        xdef    TogglePrFilter                  ; bank0/pfilter0.asm
        xdef    OSSp_PAGfi                      ; bank0/pagfi.asm

        xdef    IntSecond                       ; bank0/int.asm
        xdef    DecActiveAlm                    ; bank0/int.asm
        xdef    IncActiveAlm                    ; bank0/int.asm
        xdef    MaySetPendingAlmTask            ; bank0/int.asm

        xdef    SetPendingOZwd                  ; bank0/misc3.asm

        xdef    OSFramePop                      ; bank0/misc4.asm
        xdef    OSFramePush                     ; bank0/misc4.asm

        xdef    AtoN_upper                      ; bank0/misc5.asm
        xdef    ClearMemHL_A                    ; bank0/misc5.asm
        xdef    CopyMemBHL_DE                   ; bank0/misc5.asm
        xdef    CopyMemDE_BHL                   ; bank0/misc5.asm
        xdef    CopyMemDE_HL                    ; bank0/misc5.asm
        xdef    CopyMemHL_DE                    ; bank0/misc5.asm
        xdef    FixPtr                          ; bank0/misc5.asm
        xdef    GetOSFrame_DE                   ; bank0/misc5.asm
        xdef    GetOSFrame_HL                   ; bank0/misc5.asm
        xdef    KPrint                          ; bank0/misc5.asm
        xdef    MS1BankA                        ; bank0/misc5.asm
        xdef    MTH_ToggleLT                    ; bank0/misc5.asm
        xdef    PeekHLinc                       ; bank0/misc5.asm
        xdef    PokeBHL                         ; bank0/misc5.asm
        xdef    PokeHLinc                       ; bank0/misc5.asm
        xdef    PutOSFrame_BC                   ; bank0/misc5.asm
        xdef    PutOSFrame_DE                   ; bank0/misc5.asm
        xdef    PutOSFrame_HL                   ; bank0/misc5.asm
        xdef    ReserveStkBuf                   ; bank0/misc5.asm
        xdef    S2VerifySlotType                ; bank0/misc5.asm

        xdef    AllocHandle                     ; bank0/handle.asm
        xdef    FreeHandle                      ; bank0/handle.asm
        xdef    VerifyHandle                    ; bank0/handle.asm
        xdef    ResetHandles                    ; bank0/handle.asm

        xdef    MountAllRAM                     ; bank0/resetx.asm
        xdef    Chk128KB                        ; bank0/resetx.asm

        xdef    OSNqMemory                      ; bank0/memory.asm
        xdef    OSSp_89                         ; bank0/memory.asm

        xdef    loc_CD42                        ; bank0/dor.asm
        xdef    DORHandleFreeDirect             ; bank0/dor.asm
        xdef    DORHandleFree                   ; bank0/dor.asm
        xdef    DORHandleInUse                  ; bank0/dor.asm

        xdef    DrawOZwd                        ; bank0/ozwindow.asm
        xdef    OZwd__fail                      ; bank0/ozwindow.asm
        xdef    OZwd_card                       ; bank0/ozwindow.asm
        xdef    OZwd_index                      ; bank0/ozwindow.asm

        xdef    ChgHelpFile                     ; bank0/mth2.asm
        xdef    CopyAppPointers                 ; bank0/mth2.asm
        xdef    DrawCmdHelpWd                   ; bank0/mth2.asm
        xdef    DrawMenuWd                      ; bank0/mth2.asm
        xdef    DrawTopicHelpWd                 ; bank0/mth2.asm
        xdef    FilenameDOR                     ; bank0/mth2.asm
        xdef    GetAppDOR                       ; bank0/mth2.asm
        xdef    GetHlpHelp                      ; bank0/mth2.asm
        xdef    GetHlp_sub                      ; bank0/mth2.asm
        xdef    InputEmpty                      ; bank0/mth2.asm
        xdef    MTHPrint                        ; bank0/mth2.asm
        xdef    MTHPrintKeycode                 ; bank0/mth2.asm
        xdef    MTHPrintTokenized               ; bank0/mth2.asm
        xdef    MayMTHPrint                     ; bank0/mth2.asm
        xdef    NextAppDOR                      ; bank0/mth2.asm
        xdef    PrevAppDOR                      ; bank0/mth2.asm
        xdef    PrintTopic                      ; bank0/mth2.asm
        xdef    PrntAppname                     ; bank0/mth2.asm
        xdef    SetActiveAppDOR                 ; bank0/mth2.asm
        xdef    SetHlpAppChgFile                ; bank0/mth2.asm
        xdef    aRom_Help                       ; bank0/mth2.asm

        xdef    Get2ndTopicHelp                 ; bank0/mth3.asm
        xdef    GetCmdAttrByNum                 ; bank0/mth3.asm
        xdef    GetFirstCmdHelp                 ; bank0/mth3.asm
        xdef    GetFirstNonInfoTopic            ; bank0/mth3.asm
        xdef    GetFirstTopicHelp               ; bank0/mth3.asm
        xdef    GetNextCmdAttr                  ; bank0/mth3.asm
        xdef    GetNextCmdHelp                  ; bank0/mth3.asm
        xdef    GetNextNonInfoTopic             ; bank0/mth3.asm
        xdef    GetNextTopicHelp                ; bank0/mth3.asm
        xdef    GetNonInfoTopicByNum            ; bank0/mth3.asm
        xdef    GetTpcAttrByNum                 ; bank0/mth3.asm

        xdef    InitHlpActiveCmd                ; bank0/process3.asm
        xdef    InitHlpActiveHelp               ; bank0/process3.asm
        xdef    SetHlpActiveHelp                ; bank0/process3.asm

        xdef    RdStdinNoTO                     ; bank0/osin.asm
        xdef    sub_EF92                        ; bank0/osin.asm
        xdef    sub_EFBB                        ; bank0/osin.asm
        xdef    RdKbBuffer                      ; bank0/osin.asm

        xdef    FreeMemData                     ; bank0/filesys3.asm
        xdef    FreeMemData0                    ; bank0/filesys3.asm
        xdef    InitFsMemHandle                 ; bank0/filesys3.asm
        xdef    InitMemHandle                   ; bank0/filesys3.asm
        xdef    MvToFile                        ; bank0/filesys3.asm
        xdef    RdFileByte                      ; bank0/filesys3.asm
        xdef    RewindFile                      ; bank0/filesys3.asm
        xdef    SetMemHandlePos                 ; bank0/filesys3.asm
        xdef    WrFileByte                      ; bank0/filesys3.asm

        xdef    GetWindowFrame                  ; bank0/scrdrv2.asm
        xdef    NqRDS                           ; bank0/scrdrv2.asm

        xdef    InitWindowFrame                 ; bank0/scrdrv3.asm
        xdef    ResetWdAttrs                    ; bank0/scrdrv3.asm
        xdef    InitSBF                         ; bank0/scrdrv3.asm

        xdef    Beep_X                          ; bank0/scrdrv4.asm
        xdef    CallFuncDE                      ; bank0/scrdrv4.asm
        xdef    ClearCarry                      ; bank0/scrdrv4.asm
        xdef    ClearEOL                        ; bank0/scrdrv4.asm
        xdef    ClearEOW                        ; bank0/scrdrv4.asm
        xdef    ClearScr                        ; bank0/scrdrv4.asm
        xdef    CursorDown                      ; bank0/scrdrv4.asm
        xdef    CursorLeft                      ; bank0/scrdrv4.asm
        xdef    CursorRight                     ; bank0/scrdrv4.asm
        xdef    CursorUp                        ; bank0/scrdrv4.asm
        xdef    FindSDCmd                       ; bank0/scrdrv4.asm
        xdef    GetWdStartXY                    ; bank0/scrdrv4.asm
        xdef    MoveToXY                        ; bank0/scrdrv4.asm
        xdef    NewXValid                       ; bank0/scrdrv4.asm
        xdef    NewYValid                       ; bank0/scrdrv4.asm
        xdef    OSBlp                           ; bank0/scrdrv4.asm
        xdef    PutBoxChar                      ; bank0/scrdrv4.asm
        xdef    ResetScrAttr                    ; bank0/scrdrv4.asm
        xdef    RestoreScreen                   ; bank0/scrdrv4.asm
        xdef    SaveScreen                      ; bank0/scrdrv4.asm
        xdef    ScrDrvGetAttrBits               ; bank0/scrdrv4.asm
        xdef    ScreenBL                        ; bank0/scrdrv4.asm
        xdef    ScreenCR                        ; bank0/scrdrv4.asm
        xdef    ScreenClose                     ; bank0/scrdrv4.asm
        xdef    ScreenOpen                      ; bank0/scrdrv4.asm
        xdef    ScrollDown                      ; bank0/scrdrv4.asm
        xdef    ScrollUp                        ; bank0/scrdrv4.asm
        xdef    SetScrAttr                      ; bank0/scrdrv4.asm
        xdef    ToggleScrDrvFlags               ; bank0/scrdrv4.asm

        include "../bank0/kernel0.def"          ; get bank 0 references and map them into bank 7 project...
ENDIF