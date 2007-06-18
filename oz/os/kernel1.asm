; **************************************************************************************************
; OZ Kernel 1, starting at address $8000.
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
        xdef    ExtQualifiers                   ; [Kernel0]/kbd.asm

        xdef    ResetTimeout                    ; [Kernel0]/nmi.asm

        xdef    InitBufKBD_RX_TX                ; [Kernel0]/buffer.asm
        xdef    BfPur                           ; [Kernel0]/buffer.asm

        xdef    NQAin                           ; [Kernel0]/process2.asm

        xdef    AddRAMCard                      ; [Kernel0]/cardmgr.asm

        xdef    NqSp_ret                        ; [Kernel0]/spnq0.asm

        xdef    OSSp_PAGfi                      ; [Kernel0]/pagfi.asm

        xdef    IntSecond                       ; [Kernel0]/int.asm
        xdef    DecActiveAlm                    ; [Kernel0]/int.asm
        xdef    IncActiveAlm                    ; [Kernel0]/int.asm
        xdef    MaySetPendingAlmTask            ; [Kernel0]/int.asm

        xdef    SetPendingOZwd                  ; [Kernel0]/misc3.asm

        xdef    OSFramePop                      ; [Kernel0]/misc4.asm
        xdef    OSFramePush                     ; [Kernel0]/misc4.asm
        xdef    OSBixS1                         ; [Kernel0]/misc4.asm
        xdef    OSBoxS1                         ; [Kernel0]/misc4.asm

        xdef    AtoN_upper                      ; [Kernel0]/misc5.asm
        xdef    ClearMemHL_A                    ; [Kernel0]/misc5.asm
        xdef    CopyMemBHL_DE                   ; [Kernel0]/misc5.asm
        xdef    CopyMemDE_BHL                   ; [Kernel0]/misc5.asm
        xdef    CopyMemDE_HL                    ; [Kernel0]/misc5.asm
        xdef    CopyMemHL_DE                    ; [Kernel0]/misc5.asm
        xdef    FixPtr                          ; [Kernel0]/misc5.asm
        xdef    GetOSFrame_DE                   ; [Kernel0]/misc5.asm
        xdef    GetOSFrame_HL                   ; [Kernel0]/misc5.asm
        xdef    KPrint                          ; [Kernel0]/misc5.asm
        xdef    MS1BankA                        ; [Kernel0]/misc5.asm
        xdef    PeekBHL, PeekBHLinc, PeekHLinc  ; [Kernel0]/misc5.asm
        xdef    IncBHL                          ; [Kernel0]/misc5.asm
        xdef    PokeBHL                         ; [Kernel0]/misc5.asm
        xdef    PokeHLinc                       ; [Kernel0]/misc5.asm
        xdef    PutOSFrame_BC                   ; [Kernel0]/misc5.asm
        xdef    PutOSFrame_DE                   ; [Kernel0]/misc5.asm
        xdef    PutOSFrame_HL                   ; [Kernel0]/misc5.asm
        xdef    PutOSFrame_BHL                  ; [Kernel0]/misc5.asm
        xdef    PutOSFrame_CDE                  ; [Kernel0]/misc5.asm
        xdef    ReserveStkBuf                   ; [Kernel0]/misc5.asm
        xdef    S2VerifySlotType                ; [Kernel0]/misc5.asm
        xdef    ScrDrv_SOH_A

        xdef    AllocHandle                     ; [Kernel0]/handle.asm
        xdef    FreeHandle                      ; [Kernel0]/handle.asm
        xdef    VerifyHandle                    ; [Kernel0]/handle.asm
        xdef    ResetHandles                    ; [Kernel0]/handle.asm

        xdef    OSNqMemory                      ; [Kernel0]/memory.asm
        xdef    OSSp_89                         ; [Kernel0]/memory.asm
        xdef    InitRAM                         ; [Kernel0]/memory.asm
        xdef    MarkSwapRAM                     ; [Kernel0]/memory.asm
        xdef    MarkSystemRAM                   ; [Kernel0]/memory.asm
        xdef    Chk128KB                        ; [Kernel0]/memory.asm
        xdef    Chk128KBslot0                   ; [Kernel0]/memory.asm
        xdef    FirstFreeRAM                    ; [Kernel0]/memory.asm
        xdef    MountAllRAM                     ; [Kernel0]/memory.asm

        xdef    GetDORType                      ; [Kernel0]/dor.asm
        xdef    DORHandleFreeDirect             ; [Kernel0]/dor.asm
        xdef    DORHandleFree                   ; [Kernel0]/dor.asm
        xdef    DORHandleInUse                  ; [Kernel0]/dor.asm

        xdef    DrawOZwd                        ; [Kernel0]/ozwindow.asm
        xdef    OZwd__fail                      ; [Kernel0]/ozwindow.asm
        xdef    OZwd_card                       ; [Kernel0]/ozwindow.asm
        xdef    OZwd_index                      ; [Kernel0]/ozwindow.asm

        xdef    ChgHelpFile                     ; [Kernel0]/mth0.asm
        xdef    CopyAppPointers                 ; [Kernel0]/mth0.asm
        xdef    DrawCmdHelpWd                   ; [Kernel0]/mth0.asm
        xdef    DrawMenuWd                      ; [Kernel0]/mth0.asm
        xdef    DrawTopicHelpWd                 ; [Kernel0]/mth0.asm
        xdef    FilenameDOR                     ; [Kernel0]/mth0.asm
        xdef    GetAppDOR                       ; [Kernel0]/mth0.asm
        xdef    GetHlpHelp                      ; [Kernel0]/mth0.asm
        xdef    GetHlp_sub                      ; [Kernel0]/mth0.asm
        xdef    InputEmpty                      ; [Kernel0]/mth0.asm
        xdef    MTHPrint                        ; [Kernel0]/mth0.asm
        xdef    MTHPrintKeycode                 ; [Kernel0]/mth0.asm
        xdef    MTHPrintTokenized               ; [Kernel0]/mth0.asm
        xdef    MayMTHPrint                     ; [Kernel0]/mth0.asm
        xdef    NextAppDOR                      ; [Kernel0]/mth0.asm
        xdef    PrevAppDOR                      ; [Kernel0]/mth0.asm
        xdef    PrintTopic                      ; [Kernel0]/mth0.asm
        xdef    PrntAppname                     ; [Kernel0]/mth0.asm
        xdef    SetActiveAppDOR                 ; [Kernel0]/mth0.asm
        xdef    SetHlpAppChgFile                ; [Kernel0]/mth0.asm
        xdef    aRom_Help                       ; [Kernel0]/mth0.asm
        xdef    GetAttr                         ; [Kernel0]/mth0.asm
        xdef    GetHlpCommands                  ; [Kernel0]/mth0.asm
        xdef    GetCmdTopicByNum                ; [Kernel0]/mth0.asm
        xdef    GetRealCmdPosition              ; [Kernel0]/mth0.asm
        xdef    GetHlpTopics                    ; [Kernel0]/mth0.asm
        xdef    SkipNtopics                     ; [Kernel0]/mth0.asm
        xdef    MTH_ToggleLT                    ; [Kernel1]/mth1.asm

        xdef    InitHlpActiveCmd                ; [Kernel0]/process3.asm
        xdef    InitHlpActiveHelp               ; [Kernel0]/process3.asm
        xdef    SetHlpActiveHelp                ; [Kernel0]/process3.asm

        xdef    RdStdinNoTO                     ; [Kernel0]/osin.asm
        xdef    sub_EF92                        ; [Kernel0]/osin.asm
        xdef    sub_EFBB                        ; [Kernel0]/osin.asm
        xdef    RdKbBuffer                      ; [Kernel0]/osin.asm

        xdef    FreeMemData                     ; [Kernel0]/filesys3.asm
        xdef    FreeMemData0                    ; [Kernel0]/filesys3.asm
        xdef    InitFsMemHandle                 ; [Kernel0]/filesys3.asm
        xdef    InitMemHandle                   ; [Kernel0]/filesys3.asm
        xdef    MvToFile                        ; [Kernel0]/filesys3.asm
        xdef    RdFileByte                      ; [Kernel0]/filesys3.asm
        xdef    RewindFile                      ; [Kernel0]/filesys3.asm
        xdef    SetMemHandlePos                 ; [Kernel0]/filesys3.asm
        xdef    WrFileByte                      ; [Kernel0]/filesys3.asm

        xdef    GetWindowFrame                  ; [Kernel0]/scrdrv2.asm
        xdef    NqRDS                           ; [Kernel0]/scrdrv2.asm

        xdef    InitWindowFrame                 ; [Kernel0]/scrdrv3.asm
        xdef    ResetWdAttrs                    ; [Kernel0]/scrdrv3.asm
        xdef    InitSBF                         ; [Kernel0]/scrdrv3.asm

        xdef    Beep_X                          ; [Kernel0]/scrdrv4.asm
        xdef    CallFuncDE                      ; [Kernel0]/scrdrv4.asm
        xdef    ClearCarry                      ; [Kernel0]/scrdrv4.asm
        xdef    ClearEOL                        ; [Kernel0]/scrdrv4.asm
        xdef    ClearEOW                        ; [Kernel0]/scrdrv4.asm
        xdef    ClearScr                        ; [Kernel0]/scrdrv4.asm
        xdef    CursorDown                      ; [Kernel0]/scrdrv4.asm
        xdef    CursorLeft                      ; [Kernel0]/scrdrv4.asm
        xdef    CursorRight                     ; [Kernel0]/scrdrv4.asm
        xdef    CursorUp                        ; [Kernel0]/scrdrv4.asm
        xdef    FindSDCmd                       ; [Kernel0]/scrdrv4.asm
        xdef    GetWdStartXY                    ; [Kernel0]/scrdrv4.asm
        xdef    MoveToXY                        ; [Kernel0]/scrdrv4.asm
        xdef    NewXValid                       ; [Kernel0]/scrdrv4.asm
        xdef    NewYValid                       ; [Kernel0]/scrdrv4.asm
        xdef    OSBlp                           ; [Kernel0]/scrdrv4.asm
        xdef    PutBoxChar                      ; [Kernel0]/scrdrv4.asm
        xdef    ResetScrAttr                    ; [Kernel0]/scrdrv4.asm
        xdef    RestoreScreen                   ; [Kernel0]/scrdrv4.asm
        xdef    SaveScreen                      ; [Kernel0]/scrdrv4.asm
        xdef    ScrDrvGetAttrBits               ; [Kernel0]/scrdrv4.asm
        xdef    ScreenBL                        ; [Kernel0]/scrdrv4.asm
        xdef    ScreenCR                        ; [Kernel0]/scrdrv4.asm
        xdef    ScreenClose                     ; [Kernel0]/scrdrv4.asm
        xdef    ScreenOpen                      ; [Kernel0]/scrdrv4.asm
        xdef    ScrollDown                      ; [Kernel0]/scrdrv4.asm
        xdef    ScrollUp                        ; [Kernel0]/scrdrv4.asm
        xdef    SetScrAttr                      ; [Kernel0]/scrdrv4.asm
        xdef    ToggleScrDrvFlags               ; [Kernel0]/scrdrv4.asm

        xdef    WrRxc                           ; [Kernel0]/ossi0.asm
        xdef    EI_TDRE                         ; [Kernel0]/ossi0.asm

        xdef    Keymap_UK
        xdef    Keymap_FR
        xdef    Keymap_DE
        xdef    Keymap_DK
        xdef    Keymap_FI

        include "kernel0.def"                   ; get kernel 0 references and map them into kernel 1 project...
        include "../mth/keymaps.def"            ; get references for keymaps in MTH bank and bind them into kernel 1 project...
ENDIF
