     MODULE flash16

; ********************************************************************************************
; FlashStore, Application edition, V1.6.x
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
; ********************************************************************************************


; *****************************************************************************
; DEBUGGING OPTION:
;
; FlashStore may be executed by Intuition debugger application (#ZI) and run in
; the debugger "ugly" application RAM.
;
; Compile as:
;    mpm -DDEBUG -a -i fsapp
;
; The code will be compiled for $8000, removing application header. 
; Activate #ZI, then:
;    1) use .ML 8000
;    2) PC 8000
;    3) .T
;    4) .B <address>
;    and FlashStore is ready to be monitored!
;
; *****************************************************************************

if MSDOS | LINUX
     include "error.def"
     include "syspar.def"
     include "director.def"
     include "stdio.def"
     include "saverst.def"
     include "memory.def"
     include "integer.def"
     include "fileio.def"
     include "interrpt.def"
     include "flashepr.def"
     include "dor.def"
endif

; Library references
;

lib CreateFilename            ; Create file(name) (OP_OUT) with path
lib CreateWindow              ; Create windows...
lib RamDevFreeSpace           ; poll for free space on RAM device
lib ApplEprType               ; check for prescence application card in slot
lib CheckBattLow              ; Check Battery Low condition
lib FlashEprFileFormat        ; Create "oz" File Eprom or area on application card
lib FlashEprCardId            ; Return Intel Flash Eprom Device Code (if card available)
lib FlashEprBlockErase        ; Format Flash Eprom Block (64K)
lib FlashEprWriteBlock        ; Write a block of byte to Flash Eprom
lib FlashEprStdFileHeader     ; Write std. File Eprom Header on Flash Eprom.
lib FlashEprFileDelete        ; Mark file as deleted on Flash Eprom
lib FlashEprFileSave          ; Save RAM file to Flash Eprom
lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
lib FileEprFreeSpace          ; Return free space on File Eprom
lib FileEprCntFiles           ; Return total of active and deleted files
lib FileEprFirstFile          ; Return pointer to first File Entry on File Eprom
lib FileEprNextFile           ; Return pointer to next File Entry on File Eprom
lib FileEprFilename           ; Copy filename into buffer (null-term.) from cur. File Entry
lib FileEprFileSize           ; Return file size of current File Entry on File Eprom
lib FileEprFindFile           ; Find File Entry using search string (of null-term. filename)
lib FileEprFetchFile          ; Fetch file image from File Eprom, and store it to RAM file

if DEBUG
     ORG $8000
ELSE
     ORG $C000
ENDIF

DEFC SafeWorkSpaceSize = 64             ; 64 bytes for various variables...
DEFC RAM_pages = 6                      ; allocate 6 * 256 bytes contigous memory from $2000...

DEFVARS $2000
{
     BufferStart    ds.b 1024
     buf1           ds.b $40
     buf2           ds.b $80            ; filename buffer...     
     buf3           ds.b $80            ; for expanded filenames
}
DEFC BufferSize = buf1-BufferStart      ; buffer for file I/O at $2000

IF DEBUG
     DEFVARS $3000
ELSE
     DEFVARS $1FFE - SafeWorkSpaceSize
ENDIF
{         
     linecnt        ds.b 1
     nlen           ds.b 1              ; length of filename
     flen           ds.l 1              ; length of file (32bit)
     flenhdr        ds.l 1              ; length of File Entry Header
     delv           ds.l 1              ; pointer to <Deleted File> mark of File Entry
     fbnk           ds.b 1              ; Eprom Bank (relative)
     fadr           ds.w 1              ; Eprom Bank offset address
     free           ds.l 1              ; free bytes on Flash Eprom
     file           ds.l 1              ; total of files on Flash Eprom (active + deleted)
     fdel           ds.l 1              ; total of deleted files on Flash Eprom
     savedfiles     ds.l 1              ; total of files saved in a "Save" session
     flentry        ds.p 1              ; pointer to existing file entry
     status         ds.b 1              ; general purpose status flag
     wcard_handle   ds.w 1              ; Wildcard handle from GN_OPW
     availslots     ds.b 4              ; array of inserted File Eprom's in external slots
     curslot        ds.b 1              ; the current selected slot containing File Eprom (Area)
}

IF !DEBUG
; The Application DOR:
;
.FS_Dor
                    DEFB 0, 0, 0                  ; link to parent
                    DEFB 0, 0, 0
                    DEFB 0, 0, 0
                    DEFB $83                      ; DOR type - application ROM
                    DEFB DOREnd0-DORStart0        ; total length of DOR
.DORStart0          DEFB '@'                      ; Key to info section
                    DEFB InfoEnd0-InfoStart0      ; length of info section
.InfoStart0         DEFW 0                        ; reserved...
                    DEFB 'J'                      ; application key letter
                    DEFB RAM_pages                ; I/O buffer for FlashStore
                    DEFW 0                        ;
                    DEFW 0                        ; Unsafe workspace
                    DEFW SafeWorkSpaceSize        ; Safe workspace
                    DEFW FS_Entry                 ; Entry point of code in seg. 3
                    DEFB 0                        ; bank binding to segment 0 (none)
                    DEFB 0                        ; bank binding to segment 1 (none)
                    DEFB 0                        ; bank binding to segment 2 (none)
                    DEFB $3F                      ; bank binding to segment 3
                    DEFB AT_Ugly | AT_Popd        ; Ugly popdown
                    DEFB 0                        ; no caps lock on activation
.InfoEnd0           DEFB 'H'                      ; Key to help section
                    DEFB 12                       ; total length of help
                    DEFW FS_Dor
                    DEFB $3F                      ; point to topics (none)
                    DEFW FS_Dor
                    DEFB $3F                      ; point to commands (none)
                    DEFW FS_Help
                    DEFB $3F                      ; point to help
                    DEFW FS_Dor
                    DEFB $3F                      ; point to token base
                    DEFB 'N'                      ; Key to name section
                    DEFB NameEnd0-NameStart0      ; length of name
.NameStart0         DEFM "FlashStore",0
.NameEnd0           DEFB $FF
.DOREnd0

.FS_Help            DEFM $7F 
                    DEFM "Freeware utility by",$7F
                    DEFM "Thierry Peycru (Zlab) & Gunther Strube (InterLogic)",$7F
                    DEFM $7F
                    DEFM "Release V1.6.9, 9th February 1999",$7F
                    DEFM "(C) Copyright 1997-1999. All rights reserved",0


; *****************************************************************************
;
; We are somewhere in segment 3...
;
; Entry point for ugly popdown...
;
.FS_Entry
                    JP   app_main
                    SCF
                    RET
ENDIF

; ************************************************************************
;
.app_main
IF !DEBUG
                    LD   A,(IX+$02)          ; IX points at information block
                    CP   $20+RAM_pages       ; get end page+1 of contiguous RAM
                    JR   Z, continue_fs      ; end page OK, RAM allocated...

                    LD   A,$07               ; No Room for FlashStore, return to Index
                    CALL_OZ(Os_Bye)          ; FlashStore suicide...
.continue_fs
ENDIF
                    ld   a, sc_ena
                    call_oz(os_esc)          ; enable ESC detection

                    xor  a
                    LD   B,A
                    ld   hl,Errhandler
                    CALL_OZ os_erh           ; then install Error Handler...

                    CALL PollSlots           ; user selects a File Eprom Area in one of the ext. slots.
                    JP   C, suicide          ; no File Eprom's available
                    JP   NZ, suicide         ; user aborted

                    CALL ClearWindowArea     ; just clear whole window area available
                    CALL mainmenu
                    JP   suicide             ; main menu aborted, leave popdown...

; ************************************************************************
;
.mainmenu
                    CALL DispZlabLogo
                    CALL DispInterLogicLogo
                    CALL DispCmdWindow
                    CALL DispCtlgWindow
                    CALL FileEpromStatistics      ; parse for free space and total of files...

                    LD   HL, mainmenu
                    PUSH HL                       ; return address for functions...
.inp_main
                    CALL rdch
                    JR   NC,no_inp_err
                    CP   A
                    JR   inp_main
.no_inp_err
                    CP   IN_ESC
                    JP   Z, suicide
                    OR   $20
                    CP   's'
                    JP   Z, save_main
                    CP   'f'
                    JP   Z, fetch_main
                    CP   'r'
                    JP   Z, restore_main
                    CP   'c'
                    JP   Z, catalog_main
                    CP   '!'
                    JP   Z, format_main
                    CP   'd'
                    JP   Z, device_main
                    CP   'q'
                    JP   Z, suicide               ; exit this application deliberately...
                    JR   inp_main



; ****************************************************************************
;
.ClearWindowArea
                    LD   HL, winbackground
                    CALL_OZ(Gn_Sop)
                    RET
.winbackground      defm 1,"7#1",32,32,32+94,32+8,128
                    defm 1,"2C1",0



; ****************************************************************************
;
.DispCmdWindow
                    ld   a,'1' | 128
                    ld   bc,$0000
                    ld   de,$080D
                    ld   hl, cmds_banner
                    call CreateWindow

                    ld   hl, menu_ms
                    call_oz(Gn_Sop)
                    RET
.cmds_banner        
                    defm "Commands",0
.menu_ms
                    defm 1,"3@",32,32
                    defm 1,"B C",1,"B Catalogue",$0D,$0A
                    defm 1,"B S",1,"B Save",$0D,$0A
                    defm 1,"B F",1,"B Fetch",$0D,$0A
                    defm 1,"B R",1,"B Restore",$0D,$0A
                    defm 1,"B D",1,"B Device",$0D,$0A
                    defm 1,"B !",1,"B Format",$0D,$0A
                    defm 1,"B Q",1,"B Quit"
                    defm 1,"2-C"
                    defb 0


; ****************************************************************************
;
.DispCtlgWindow
                    ld   a,'2' | 128
                    ld   bc,$000F
                    ld   de,$0837
                    ld   hl, catalog_banner
                    call CreateWindow
                    ret

.catalog_banner     defm "FLASHSTORE v1.6.9, (C) 1997-99 Zlab & InterLogic",0


; ************************************************************************
;
; Scan external slots and display available File Eprom's from which the
; user selects an item.
;
; If no File Eprom Area was found, then slot 3 is examined for a Flash 
; Eprom Card to be created with a File Eprom Area (whole card or part).
; If found and user acknowledges, then slot 3 will be created with a File
; Eprom Area and selected as default.
;
; The selected Eprom will remain as the current File Eprom throughout
; the life of the instantiated FlashStore popdown.
;
; A small array, <availslots> is used to store the size of each File Eprom
; with the first byte indicating the total of File Eproms available.
;
.PollSlots
                    ld   hl, availslots+1    ; point to counter of available slots
                    push hl
                    ld   c,1                 ; begin with external slot 1
                    ld   e,0                 ; counter of available file eproms
.poll_loop
                    push bc                  ; preserve slot number...
                    call FileEprRequest      ; File Eprom Card or area available in slot C?
                    pop  bc
                    jr   c, no_fileepr
                    jr   nz, no_fileepr      ; no header was found, but a card was available of some sort
                         inc  e              ; File Eprom found
                         pop  hl
                         ld   (hl),d         ; size of file eprom in 16K banks
                         inc  hl
                         push hl
                         jr   next_slot
.no_fileepr
                         pop  hl
                         ld   (hl),0         ; indicate no file eprom
                         inc  hl
                         push hl
.next_slot                         
                    inc  c
                    ld   a,c
                    cp   4
                    jr   nz, poll_loop
                    
                    pop  hl
                    ld   hl, availslots
                    ld   (hl),e              ; store total of File Eprom's found

                    inc  e
                    dec  e
                    jr   nz, select_slot     ; File Eprom's were found, select one...
.check_slot3
                         ld   a,3                 ; no File Eprom's found
                         ld   (curslot),a         ; select slot 3 as default

                         ld   c,3
                         call FlashEprCardId      ; Flash Eprom in slot 3?
                         jr   nc, chip_found      ; Yes...
                         CALL greyscr
                         CALL DispCtlgWindow
.unkn_chip
                         ld   hl, cbad_ms
                         call DispErrMsg
                         scf
                         ret
.chip_found                                       ; a Flash Eprom was found, 
                         CALL greyscr
                         CALL DispCtlgWindow 
                         call format_main         ; format Flash Eprom for new File Eprom Area
                         ret
.select_slot
                    ld   a,e
                    cp   1
                    jr   z, select_default
                    
                    call SelectSlot          ; User selects a slot from a list...
                    jr   c, check_slot3      ; user aborted selection, ask user to create file area
                    ret
.select_default                              ; select the only File Eprom available
                    ld   hl, availslots+1
                    ld   b,3
                    ld   c,1
                    xor  a
.sel_slot_loop
                    cp   (hl)
                    jr   nz, found_slot
                    inc  hl
                    inc  c
                    djnz sel_slot_loop
.found_slot
                    ld   a,c
                    ld   (curslot),a         ; current slot selected...
                    cp   a
                    ret
                    

; ****************************************************************************
;
.SelectSlot
                    ld   a,'1' | 128 | 64
                    ld   bc,$0120
                    ld   de,$0516
                    ld   hl, selslot_banner
                    call CreateWindow
                    ld   hl, selvdu
                    call_oz  (GN_Sop)

                    ld   a,1                 ; begin from slot 1
                    ld   (curslot),a
.disp_slot_loop     
                    ld   hl, slottxt
                    call_oz(Gn_Sop)
                    ld   a,(curslot)
                    add  a,48
                    call_oz(OS_Out)          ; display slot number
                    ld   a, ' ' 
                    call_oz(OS_Out)

                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    jr   c, poll_for_ram_card
                         ld   hl, eprdev          ; d = size of File Area in 16K banks
                         jr   slotsize
.poll_for_ram_card
                    ld   a,(curslot)
                    ld   c,a
                    call RamDevFreeSpace
                    jr   c, poll_for_rom_card
                         ld   hl, ramdev
                         ld   d,a
                         jr   slotsize
.poll_for_rom_card
                    ld   a,(curslot)
                    ld   c,a
                    call ApplEprType
                    jr   c, empty_slot
                         ld   hl, romdev
                         ld   d,b                 ; display size of card as defined by ROM header
                         jr   slotsize
.empty_slot
                    ld   hl, emptytxt
                    call_oz(Gn_Sop)
                    jr   nextline
.slotsize
                    push bc
                    call_oz(Gn_Sop)     ; display device name...
                    pop  bc
                    ld   a,(curslot)
                    add  a,48
                    call_oz(Os_Out)     ; display device number (which is current slot number too)
                    call DispSlotSize   ; D = size of slot in 16K banks
.nextline
                    call_oz(Gn_Nln)
                    ld   a,(curslot)
                    inc  a
                    ld   (curslot),a
                    cp   4
                    jr   nz, disp_slot_loop

                    ; Now, user selects the appropriate :EPR device ...
                    ld   a,1
                    ld   (curslot),a              ; set menu bar at "slot 1"
.select_slot_loop
                    call UserMenu
                    ret  c                        ; user aborted selection
                    ld   hl, availslots
                    ld   a,(curslot)
                    ld   b,0
                    ld   c,a
                    add  hl,bc
                    xor  a
                    cp   (hl)
                    jr   z, select_slot_loop      ; user selected void or illegal slot
                    cp   a                        ; slot selected successfully
                    ret
.DispSlotSize
                    ld   hl,size1delm
                    call_oz(Gn_Sop)

                    LD   H,0
                    LD   L,D
                    CALL m16
                    EX   DE,HL          ; size in DE...
                    CALL DispEprSize

                    ld   hl,size2delm
                    call_oz(Gn_Sop)               
                    ret

.selslot_banner     defm "SELECT FILE AREA",0
.eprdev             defm ":EPR.",0
.ramdev             defm ":RAM.",0
.romdev             defm ":ROM.",0
.slottxt            defm "SLOT ",0
.emptytxt           defm "EMPTY",0
.size1delm          defm " [",0
.size2delm          defm "K]",0
.selvdu             defm 1,"3-SC"               ; no vertical scrolling, no cursor
                    defm 1,"2+T",0


; *************************************************************************************
;
.UserMenu
.menu_loop     CALL DisplMenuBar
               CALL rdch
               CALL RemoveMenuBar
               LD   HL, curslot
               CP   IN_ESC                        ; ESC?
               JR   Z, abort_select
               CP   IN_ENT                        ; ENTER?
               RET  Z                             
               CP   IN_DWN                        ; Cursor Down ?
               JR   Z, MVbar_down
               CP   IN_UP                         ; Cursor Up ?
               JR   Z, MVbar_up
               CP   '1'
               JR   C,menu_loop                   ; smaller than '1'
               CP   '4'
               JR   NC,menu_loop                  ; >= '4'
               SUB  A,48                          ; ['1'; '3'] keys selected
               LD   (HL),A
               CP   A
               RET
.abort_select  
               SCF
               RET
.MVbar_down    LD   A,(HL)                        ; get Y position of menu bar
               CP   3                             ; has m.bar already reached bottom?
               JR   Z,Mbar_topwrap
               INC  A
               LD   (HL),A                        ; update new m.bar position
               JR   menu_loop                     ; display new m.bar position

.Mbar_topwrap  LD   A,1
               LD   (HL),A
               JR   menu_loop

.MVbar_up      LD   A,(HL)                        ; get Y position of menu bar
               CP   1                             ; has m.bar already reached top?
               JR   Z,Mbar_botwrap
               DEC  A
               LD   (HL),A                        ; update new m.bar position
               JR   menu_loop

.Mbar_botwrap  LD   A,3
               LD   (HL),A
               JR   menu_loop


; *************************************************************************************
;
.DisplMenuBar  PUSH AF
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               LD   HL, xypos                     ; (old menu bar will be overwritten)
               CALL_OZ(Gn_Sop)
               LD   A,32                          ; display menu bar at (0,Y)
               CALL_OZ(Os_out)
               LD   A,(curslot)                   ; get Y position of menu bar
               DEC  A
               ADD  A,32                          ; VDU...
               CALL_OZ(Os_out)
               LD   HL,MenuBarOn                  ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  AF
               RET
.xypos         DEFM 1,"3@",0
.SelectMenuWindow
               DEFM 1,"2H1",1,"2-C",0     ; activate menu window, no Cursor...
.MenuBarOn     DEFM 1,"2+R"                     ; set reverse video
               DEFM 1,"2A",32+22,0          ; XOR 'display' menu bar (22 chars wide)

; *************************************************************************************
;
.RemoveMenuBar PUSH AF
               PUSH HL
               LD   HL,SelectMenuWindow
               CALL_OZ(Gn_Sop)
               LD   HL, xypos                     ; (old menu bar will be overwritten)
               CALL_OZ(Gn_Sop)
               LD   A,32                          ; display menu bar at (0,Y)
               CALL_OZ(Os_out)
               LD   A,(curslot)                   ; get Y position of menu bar
               DEC  A
               ADD  A,32                          ; VDU...
               CALL_OZ(Os_out)
               LD   HL,MenuBarOff                 ; now display menu bar at cursor
               CALL_OZ(Gn_Sop)
               POP  HL
               POP  AF
               RET
.MenuBarOff    DEFM 1,"2-R"                     ; set reverse video
               DEFM 1,"2A",32+22,0          ; apply 'display' menu bar (22 chars wide)



; ****************************************************************************
;
; Eprom Statistics from current File Eprom (Area)
;
; Fetch the following information:
;
; (file) = number of files
; (fdel) = number of deleted files
; (free) = free space
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.FileEpromStatistics
                    ld   bc,5
                    ld   hl, slot_br
                    ld   de, buf1
                    ldir
                    ld   a,(curslot)
                    add  a,48
                    ld   (de),a
                    inc  de
                    xor  a
                    ld   (de),a                   ; null-terminate banner

                    ld   a,'3' | 128 | 64
                    ld   bc,$0048
                    ld   de,$0814
                    ld   hl, buf1
                    call CreateWindow

                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    jr   nc, cont_statistics
                         ld   hl, nofepr_ms
                         call_oz (Gn_Sop)
                         ret
.cont_statistics                   
                    ld   a,(curslot)
                    ld   c,a
                    push bc                       ; preserve slot number
                    
                    call FileEprCntFiles          ; files on current File Eprom
                    add  hl,de                    ; total files = active + deleted
                    ld   (file),hl
                    ld   (fdel),de
     
                    pop  bc
                    push bc
                    call FileEprFirstFile
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e
                    jr   nz, getfreesp
                         ld   hl,(file)
                         dec  hl
                         ld   (file),hl
                         ld   hl,(fdel)
                         dec  hl
                         ld   (fdel),hl           ; don't include hidden file entry in statistics
.getfreesp
                    pop  bc                       ; c = slot number...
                    call FileEprFreeSpace         ; free space on current File Eprom
                    ld   (free),bc
                    ld   (free+2),de

                    ld   hl,lac
                    CALL_OZ gn_sop                ; centre justify...

                    CALL DisplayEpromSize

                    ld   hl,t704_ms
                    CALL_OZ gn_sop
                    ld   hl,free
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,bfre_ms
                    CALL_OZ gn_sop
                    CALL_OZ(Gn_Nln)

                    ld   hl,file
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,fisa_ms
                    CALL_OZ gn_sop
                    CALL_OZ(Gn_Nln)

                    ld   hl,fdel
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,fdel_ms
                    CALL_OZ gn_sop

                    ld   hl, nocur
                    CALL_OZ  GN_Sop
                    ret

.slot_br            defm "SLOT "
.lac                defm 1,"2JC",0
.t704_ms            defm 1,"3@",33,34,0
.bfre_ms            defm " bytes free",0
.fisa_ms            defm " files saved",0
.fdel_ms            defm " files deleted",0
.nocur              defm 1,"2-C",0
.nofepr_ms          defm 13,10,13,10,1,"2JC",1,"2+F"
                    defm "No File Area",13,10,"available"
                    defm 1,"2JN",1,"3-FC",0


; ****************************************************************************
;
.DisplayEpromSize
                    LD   HL, t701_ms
                    CALL_OZ(GN_Sop)

                    ld   a,(curslot)
                    ld   c,a
                    CALL FileEprRequest

                    LD   H,0
                    LD   L,D            ; D = total of banks as defined by File Eprom Header
                    CALL m16
                    EX   DE,HL          ; size in DE...

                    LD   A,B
                    CP   $3F            ; is header located in top bank?
                    JR   Z, true_size   ; Yes - real File Eprom found...

                    LD   HL, flashvdu
                    CALL_OZ(Gn_Sop)
                    CALL DispEprSize
                    LD   HL, ksize
                    CALL_OZ(Gn_sop)
                    LD   HL,fepr
                    CALL_OZ(Gn_Sop)
                    RET

.true_size          LD   HL, tinyvdu
                    CALL_OZ(Gn_Sop)
                    CALL DispEprSize
                    LD   HL, ksize
                    CALL_OZ(Gn_sop)
                    LD   HL,fepr
                    CALL_OZ(Gn_Sop)
                    RET

.DispEprSize        LD   B,D
                    LD   C,E
                    LD   HL,2
                    CALL IntAscii
                    CALL_OZ(Gn_Sop)     ; display size of File Eprom
                    RET

.t701_ms            defm 1,"3@",33,33,0
.flashvdu           DEFM 1,"2+F"
.tinyvdu            DEFM 1,"2+T",0
.ksize              DEFM "K ",0
.fepr               DEFM "FILE EPROM",1,"3-TF",0



; ****************************************************************************
;
; Multiply HL * 16, result in HL.
;
.m16
                    PUSH BC
                    LD   B,4
.multiply_loop      ADD  HL,HL
                    DJNZ multiply_loop  ; banks * 16K = size of card in K
                    POP  BC
                    RET


; ****************************************************************************
;
; Display Window bar (below windows title) with caption text identified by HL pointer
;
.wbar
                    PUSH HL
                    LD   HL,bar1_sq
                    CALL_OZ gn_sop
                    POP  HL
                    CALL_OZ gn_sop
                    LD   HL,bar2_sq
                    CALL_OZ gn_sop
                    RET
.bar1_sq            defm 1,"4+TUR",1,"2JC",1,"3@  ",0
.bar2_sq            defm 1,"3@  ",1,"2A",87,1,"4-TUR",1,"2JN",0



; ***************************************************************************
;
; Display slot selection window to choose another Flash Eprom Device
;
.device_main        
                    CALL greyscr
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call SelectSlot          ; user selects a File Eprom Area in one of the ext. slots.
                    pop  bc
                    jp   c, suicide          ; no File Eprom's available, kill FlashStore popdown...
                    ret  z                   ; user selected a device...
                    
                    ld   a,c
                    ld   (curslot),a         ; user aborted selection, restore original slot...
                    ret


; ***************************************************************************
;
; Save Files to Flash Eprom
;
.save_main          call cls
                    call CheckBatteryStatus
                    ret  c                        ; batteries are low - operation aborted

                    ld   a,(curslot)
                    cp   3
                    jr   z, init_save_main
                         ld   hl, nosave_ms
                         call disperrmsg          ; "files can only be saved in slot 3."
                    ret
.init_save_main
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    ret  c

                    ld   hl,0
                    ld   (savedfiles),hl     ; reset counter to No files saved...
.fname_sip
                    call cls
                    ld   hl,fsv1_br
                    call wbar
                    ld   hl,wcrd_ms
                    call sopnln

                    LD   HL,fnam_ms
                    CALL_OZ gn_sop

                    ld   bc,$0080
                    ld   hl,curdir
                    ld   de,buf3
                    CALL_OZ gn_fex           ; pre-insert current path at command line...
                    ld   a,'/'
                    ld   (de),a
                    inc  de
                    xor  a
                    ld   (de),a
                    inc  c                   ; C = set cursor to char after path...

                    LD   DE,buf3
                    LD   A,@00100011
                    LD   B,$40
                    LD   L,$20
                    CALL_OZ gn_sip
                    jp   nc,save_mailbox
                    CP   RC_SUSP
                    JR   Z, fname_sip
                    CALL ReportStdError
                    RET

.fsv1_br            DEFM "SAVE FILES TO FLASH EPROM",0
.wcrd_ms            DEFM " Wildcards are allowed.",0
.fnam_ms            DEFM 1,"2+C Filename: ",0
.nosave_ms          DEFM "Files can only be saved in slot 3.",$0D,$0A,0

.save_mailbox
                    call cls
                    ld   hl,fsv2_br
                    call wbar

                    ld   bc,$0080
                    ld   hl,buf3
                    ld   de,buf1
                    CALL_OZ gn_fex
                    CALL C, ReportStdError             ; illegal wild card string
                    JR   C, end_save

                    xor  a
                    ld   b,a
                    LD   HL,buf1
                    CALL_OZ gn_opw
                    CALL C, ReportStdError             ; wild card string illegal or no names found
                    JR   C, end_save                   ; no files to save...
                    LD   (wcard_handle),IX
.next_name
                    CALL CheckBatteryStatus
                    JR   C, save_completed             ; abort operation if batteries are low

                    LD   DE,buf2
                    LD   C,$80                         ; write found name at (buf2) using max. 128 bytes
                    LD   IX,(wcard_handle)
                    CALL_OZ(GN_Wfn)
                    JR   C, save_completed
                    CP   Dn_Fil                        ; file found?
                    JR   NZ, next_name
.re_save
                    CALL file_save                     ; Yes, save to Flash File Eprom...
                    JR   NC, next_name                 ; saved successfully, fetch next file..

                    CP   RC_BWR
                    JR   Z, re_save                    ; not saved successfully to Flash Eprom, try again...
                    CALL ReportStdError                ; display all other std. errors...
.save_completed
                    LD   IX,(wcard_handle)
                    CALL_OZ(GN_Wcl)                    ; All files parsed, close Wild Card Handler
.end_save
                    LD   HL,(savedfiles)
                    LD   A,H
                    OR   L
                    CALL NZ, DispFilesSaved
                    CALL Z, DispNoFiles
                    CALL DispErrMsg                    ; wait for ESC key, then back to main menu
                    RET

.DispFilesSaved     PUSH AF
                    PUSH HL
                    ld   hl,savedfiles                 ; display no of files saved...
                    call IntAscii
                    CALL_OZ gn_sop
                    LD   HL,ends0_ms                   ; " file"
                    CALL_OZ(GN_Sop)
                    POP  HL
                    LD   A,H
                    XOR  L
                    CP   1
                    JR   Z, endsx
                    LD   A, 's'
                    CALL_OZ(OS_Out)
.endsx              LD   HL, ends1_ms
                    POP  AF
                    RET

.DispNoFiles        LD   HL, ends2_ms                  ; "No files saved".
                    RET

.filesaved          LD   HL,(savedfiles)               ; another file has been saved...
                    INC  HL
                    LD   (savedfiles),HL               ; savedfiles++
                    RET

.curdir             defm ".",0
.fsv2_br            defm "SAVING TO FLASH EPROM ...",0
.ends0_ms           defm " file",0
.ends1_ms           defm " has been saved.",$0D,$0A,0
.ends2_ms           defm "No files saved.",$0D,$0A,0
.savf_ms            defm $0D,$0A,"Saving ",0

.fext0_ms           defm "Size : (Header = ",0
.fext1_ms           defm ",File image = ",0
.fext2_ms           defm ") ",0
.byte_ms            defm " bytes",$0D,$0A,0



; **************************************************************************
;
; Save file to Flash Eprom, filename at (buf2), null-terminated.
;
.file_save
                    LD   BC,$0080
                    LD   HL,buf2
                    LD   DE,buf3                       ; expanded filename may have 128 byte size...
                    LD   A, op_in
                    CALL_OZ(GN_Opf)
                    RET  C

                    LD   A,C
                    SUB  7
                    LD   (nlen),A                      ; length of filename excl. device name...
                    LD   A,fa_ext
                    LD   DE,0
                    CALL_OZ(OS_Frm)                    ; file size in DEBC...
                    CALL_OZ(Gn_Cl)                     ; close file

                    LD   (flen),BC
                    LD   (flen+2),DE

                    XOR  A
                    OR   B
                    OR   C
                    OR   D
                    OR   E
                    JP   Z, file_zero_length

                    LD   A,(nlen)                      ; calculate size of File Entry Header
                    ADD  A,4+1                         ; total size = length of filename + 1 + 32bit file length
                    LD   H,0
                    LD   L,A
                    LD   (flenhdr),HL
                    LD   HL,0
                    LD   (flenhdr+2),HL                ; size of File Entry Header

                    LD   HL,savf_ms
                    CALL_OZ gn_sop
                    LD   HL,buf3                       ; display expanded filename
                    call sopnln

                    LD   DE,buf3+6                     ; point at filename (excl. device name), null-terminated
                    CALL FindFile                      ; find File Entry of old file, if present

                    ; "File size : (header = xx & file image = xxxx) xxxxx bytes ..."

                    ld   hl,fext0_ms
                    CALL_OZ gn_sop
                    ld   hl,flenhdr
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,fext1_ms
                    CALL_OZ gn_sop
                    ld   hl,flen
                    call IntAscii
                    CALL_OZ gn_sop
                    ld   hl,fext2_ms
                    CALL_OZ gn_sop

                    ld   hl,(flen)
                    ld   bc,(flenhdr)
                    add  hl,bc
                    ld   (flen),hl
                    ld   a,(flen+2)
                    adc  a,0
                    ld   (flen+2),a                    ; flen = flen + flenhdr

                    ld   hl,flen
                    call IntAscii
                    CALL_OZ gn_sop

                    ld   hl,byte_ms
                    CALL_OZ gn_sop

                    ld   bc, BufferSize
                    ld   de, BufferStart
                    ld   hl, buf3
                    call FlashEprFileSave
                    jr   c, filesave_err               ; write error or no room for file...

                    CALL DeleteOldFile                 ; mark previous file as deleted, if any...
                    CALL filesaved
                    LD   HL,fsok_ms
                    CALL sopnln
                    CP   A
                    RET
.filesave_Err
                    CP   RC_BWR
                    JR   Z, file_wrerr                 ; not written properly to Flash Eprom
                    CP   RC_VPL
                    JR   Z, file_wrerr                 ; VPP not set (should not happen)
                    SCF
                    RET                                ; otherwise, return with std. OZ errors...

.file_wrerr         LD   HL, blowerrmsg
                    CALL DispErrMsg
                    SCF
                    RET

.file_zero_length
                    LD   HL,buf3                       ; display expanded filename
                    call sopnln
                    LD   HL,zerolen_msg
                    call sopnln
                    CP   A
                    RET


.fsok_ms            DEFM " Done.",$0D,$0A,0
.blowerrmsg         DEFM "File was not saved properly - will be re-saved.",$0D,$0A,0
.zerolen_msg        DEFM "File has zero length - ignored.",$0D,$0A,0


; **************************************************************************
;
; Find file on current File Eprom, identified by DE pointer string (null-terminated),
; and preserve pointer in (flentry).
;
; IN:
;         DE = pointer to search string (filename)
;
.FindFile
                    LD   A,$FF
                    LD   H,A
                    LD   L,A
                    LD   (flentry),HL
                    LD   (flentry+2),A                 ; preset found File Entry to <None>...

                    LD   A,(curslot)
                    LD   C,A
                    CALL FileEprFindFile               ; search for filename on File Eprom...
                    RET  C                             ; File Eprom or File Entry was not available
                    RET  NZ                            ; File Entry was not found...

                    LD   A,B
                    LD   (flentry+2),A
                    LD   (flentry),HL                  ; preserve ptr to current File Entry...
                    RET



; **************************************************************************
;
; Mark File Entry as deleted, if a valid pointer is registered in (flentry).
;
; IN:
;         BHL = (flentry)
;
.DeleteOldFile
                    LD   A,(flentry+2)
                    CP   $FF                      ; Valid pointer to File Entry?
                    RET  Z

                    LD   B,A
                    LD   HL,(flentry)
                    CALL FlashEprFileDelete       ; Mark old File Entry as deleted
                    RET  C                        ; File Eprom not found or write error...

                    LD   HL, oldv_ms
                    CALL sopnln
                    RET

.oldv_ms            DEFM "Previous version deleted.",0



; **************************************************************************
;
; Fetch file from File Eprom.
; User enters name of file that will be searched for, and if found,
; fetched into a specified RAM file.
;
.fetch_main
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    ret  c

                    call cls
                    ld   hl,fetch_br
                    call wbar
                    ld   hl,exct_ms
                    call sopnln
                    ld   hl,fnam_ms
                    CALL_OZ gn_sop

                    LD   HL,buf1                  ; preset input line with '/'
                    LD   (HL),'/'
                    INC  HL
                    LD   (HL),0
                    DEC  HL
                    EX   DE,HL

                    LD   A,@00100011
                    LD   BC,$4001
                    LD   L,$20
                    CALL_OZ gn_sip
                    jr   c,sip_error
                    CALL_OZ gn_nln

                    call file_fetch
                    JR   C, fetch_error
                    RET
.sip_error
                    CP   rc_susp
                    JR   Z,fetch_main
                    RET
.fetch_error
                    PUSH AF
                    LD   B,0
                    LD   HL, buf3                 ; an error occurred, delete file...
                    CALL_OZ(Gn_Del)
                    POP  AF
                    CALL_OZ gn_err                ; display I/O error (or related)
                    RET

.fetch_br           DEFM "FETCH FROM EPROM",0
.exct_ms            DEFM " Enter exact filename (no wildcard).",0
                                        


; **************************************************************************
;
.file_fetch
                    LD   A,(curslot)
                    LD   C,A
                    LD   DE,buf1
                    CALL FileEprFindFile     ; search for <buf1> filename on File Eprom...
                    ret  c                   ; File Eprom or File Entry was not available
                    ret  nz                  ; File Entry was not found...

                    ld   a,b                 ; File entry found
                    ld   (fbnk),a
                    ld   (fadr),hl           ; preserve pointer to found File Entry...
                    LD   A,(curslot)
                    LD   C,A
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e                   ; is file empty (zero lenght)?
                    jr   nz, get_name        
                         ld   a, RC_EOF
                         scf                 ; indicate empty file...
                         ret                      
.get_name
                    ld   hl,ffet_ms          ; get destination filename from user...
                    CALL_OZ gn_sop
                    ld   de,buf1
                    LD   A,@00100011         ; buffer has filename
                    LD   BC,$4000
                    LD   L,$20
                    CALL_OZ gn_sip
                    jr   nc,open_file
                    cp   rc_susp
                    jr   z,get_name
                    ret  c                   ; user aborted...
.open_file
                    CALL_OZ(GN_Nln)
                    ld   hl,buf1
                    call PromptOverWrFile
                    jr   c, check_fetch_abort; file doesn't exist (or in use), or user aborted
                    jr   z, create_file      ; file exists, user acknowledged Yes...
                    CP   A
                    RET                      ; user acknowledged no, just return to main...
.check_fetch_abort
                    CP   RC_EOF
                    JR   NZ, create_file
                         CP   A
                         RET                 ; abort file fetching, indicate success
.create_file
                    ld   bc,$80
                    ld   hl,buf1
                    ld   de,buf3             ; generate expanded filename...
                    CALL_OZ (Gn_Fex)
                    ret  c                   ; invalid filename...

                    ld   b,0                 ; (local pointer)
                    ld   hl,buf3             ; pointer to filename...
                    call CreateFilename      ; create file with and path
                    ret  c

                    CALL_OZ gn_nln           ; IX = handle of created file...
                    ld   hl,fetf_ms
                    CALL_OZ gn_sop
                    ld   hl,buf3
                    call sopnln              ; display created RAM filename (expanded)...

                    LD   A,(fbnk)
                    LD   B,A
                    LD   HL,(fadr)
                    LD   A,(curslot)
                    LD   C,A
                    CALL FileEprFetchFile    ; fetch file from current File Eprom
                    PUSH AF                  ; to RAM file, identified by IX handle
                    CALL_OZ(Gn_Cl)           ; then, close file.
                    POP  AF
                    RET  C

                    LD   HL, done_ms
                    CALL DispErrMsg
                    CP   A                   ; Fc = 0, File successfully fetched into RAM...
                    RET

.fetf_ms            DEFM 1,"2+C Fetching to ",0
.done_ms            DEFM " Completed.",$0D,$0A,0
.ffet_ms            DEFM 13," Fetch as : ",0
.exis_ms            DEFM 13," Overwrite RAM file : ",0



; ****************************************************************************
;
; Restore ALL active files into a user defined RAM device (or path)
;
.restore_main
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    ret  c

                    CALL cls
                    LD   HL,rest_banner
                    CALL wbar
                    LD   HL,defdst_msg
                    CALL sopnln
                    LD   HL,dest_msg
                    CALL_OZ gn_sop
                    CALL GetDefaultDevice
                    LD   DE,buf1
                    LD   A,@00100011
                    LD   BC,$4007
                    LD   L,$20
                    CALL_OZ gn_sip

; add some code here for ESC detection...

                    jr   nc, process_path
                    CP   rc_susp
                    JR   Z,restore_main      ; user aborted command...
                    RET
.process_path
                    ld   bc,$80
                    ld   hl,buf1
                    ld   de,buf2             ; generate expanded path, if possible...
                    CALL_OZ (Gn_Fex)
                    jr   c, inv_path         ; invalid path

                    AND  @10111000
                    JR   NZ, illg_wc         ; wildcards not allowed...
                    JR   adjust_path

.illg_wc            LD   HL, illgwc_msg
                    CALL DispErrMsg
                    JR   restore_main        ; syntax error in path name

.inv_path           LD   HL, invpath_msg
                    CALL DispErrMsg
                    JR   restore_main
.no_files
                    LD   HL, noeprfilesmsg
                    CALL DispErrMsg
                    RET
.adjust_path
                    DEC  DE
                    LD   A,(DE)              ; assure that last character of path
                    CP   '/'                 ; is not a "/"...
                    JR   NZ,path_ok
                    DEC  DE
.path_ok            INC  DE                  ; DE points at merge position,
                                             ; ready to receive filenames from File Eprom...
                    CALL_OZ GN_nln
                    CALL PromptOverwrite     ; prompt for all existing files to be overwritten
                    CALL_OZ GN_nln

                    LD   A,(curslot)
                    LD   C,A
                    CALL FileEprFirstFile    ; get pointer to first file on Eprom
                    JR   C, no_files         ; Ups - the card was empty or not present...
.restore_loop       
                    LD   A,(curslot)
                    LD   C,A                 
                    CALL FileEprFilename     ; get filename at (DE)
                    JR   C, restore_completed; all file entries scanned...
                    JR   Z, fetch_next       ; File Entry marked as deleted, get next...

                    PUSH DE                  ; preserve local ptr to filename buffer...
                    CALL FileEprFileSize
                    LD   A,C
                    OR   D
                    OR   E
                    POP  DE                  ; is file empty (zero length)?
                    JR   Z, fetch_next       ; yes, try to fetch next...

                    PUSH BC
                    PUSH HL                  ; preserve pointer temporarily...

                    LD   HL,fetf_ms          ; "Fetching to "
                    CALL_OZ gn_sop
                    LD   HL,buf2
                    CALL_OZ(Gn_Sop)          ; display RAM filename...

                    LD   HL,status
                    BIT  0,(HL)
                    JR   NZ, restore_file    ; default - overwrite files...

                    LD   HL, buf2
                    call PromptOverWrFile
                    jr   c, check_rest_abort
                    jr   z, overwr_file      ; file exists, user acknowledged Yes...
                    jr   restore_ignored     ; file exists, user acknowledged No...
.check_rest_abort
                         cp   RC_EOF
                         jr   nz, restore_file    ; file doesn't exist (or in use)
                              POP  HL
                              POP  BC
                              CP   A         ; restore command aborted.                             
                              RET
.restore_ignored
                    CALL_OZ(Gn_Nln)
                    POP  HL
                    POP  BC
                    JR   fetch_next          ; user acknowledged No, get next file
.overwr_file
                    LD   HL, fetch_ms
                    CALL_OZ(Gn_Sop)

.restore_file       LD   B,0                 ; (local pointer)
                    LD   HL,buf2             ; pointer to filename...
                    CALL CreateFilename      ; create file with implicit path...

                    POP  HL                  ; IX = file handle...
                    POP  BC                  ; restore pointer to current File Entry
                    JR   C, filecreerr       ; not possible to create file, exit restore...

                    LD   A,(curslot)
                    LD   C,A                 
                    CALL FileEprFetchFile    ; fetch file from File Eprom
                    PUSH AF                  ; to RAM file, identified by IX handle
                    CALL_OZ(Gn_Cl)           ; then, close file.
                    POP  AF
                    JR   C, filecreerr       ; not possible to transfer, exit restore...

                    PUSH BC
                    PUSH HL
                    LD   HL, fsok_ms
                    CALL_OZ(GN_Sop)          ; "Done"
                    POP  HL
                    POP  BC
.fetch_next
                    LD   A,(curslot)
                    LD   C,A                 
                    CALL FileEprNextFile     ; get pointer to next File Entry...
                    JR   NC, restore_loop
.restore_completed
                    CALL_OZ GN_nln
                    LD   HL, done_ms
                    CALL DispErrMsg
                    RET
.filecreerr
                    CALL_OZ(Gn_Err)          ; report fatal error and exit to main menu...
                    RET


; ****************************************************************************
;
; Prompt user to to overwrite all existing files (in RAM) when restoring
;
; IN: None
;
; OUT:
;    (status), bit 1 = 1 if all files are to be overwritten...
;
.PromptOverWrite    PUSH DE
                    PUSH HL
                    LD   HL,status
                    SET  0,(HL)              ; preset to Yes (to overwrite existing files)

                    LD   HL, promptovwrite_msg
                    LD   DE, no_ms
                    CALL YesNo
                    JR   C, exit_promptoverwr
                    JR   Z, exit_promptoverwr; Yes selected...

                    LD   HL,status
                    RES  0,(HL)              ; No selected (to overwrite existing files)
.exit_promptoverwr
                    POP  HL
                    POP  DE
                    RET

.rest_banner        DEFM "RESTORE ALL FILES FROM EPROM",0
.fetch_ms           DEFM $0D,$0A," Fetching... ",0
.promptovwrite_msg  DEFM " Overwrite RAM files? ",0
.defdst_msg         DEFM " Enter Device/path.",0
.dest_msg           DEFM 1,"2+C Device: ",0
.illgwc_msg         DEFM $0D,$0A,"Wildcards not allowed.",0
.invpath_msg        DEFM $0D,$0A,"Invalid Path",0



; ****************************************************************************
;
; Prompt user to to overwrite file, if it exist.
;
; IN:
;    HL = (local) ptr to filename (null-terminated)
;
; OUT:
;    Fc = 0, file exists
;         Fz = 1, Yes, user acknowledged overwrite file
;         Fz = 0, No - acknowledged preserve file
;
;    Fc = 1,
;         file doesn't exists or
;         or user aborted with ESC (during Yes/No) prompt.
;         
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.. different
;
.PromptOverWrFile   PUSH BC
                    PUSH DE
                    PUSH HL
                    PUSH IX

                    LD   A, OP_IN
                    LD   BC,$0040            ; expanded file, room for 64 bytes
                    LD   D,H
                    LD   E,L
                    CALL_OZ (GN_Opf)
                    JR   C, exit_overwrfile  ; file not available
                    CALL_OZ(GN_Cl)

                    CALL_OZ GN_nln
                    LD   HL, exis_ms
                    LD   DE, yes_ms
                    CALL yesno               ; file exists, prompt "Overwrite file?"
                    JR   Z,exit_overwrfile
.check_ESC
                    CP   IN_ESC
                    JR   Z, abort_file
                         OR   A
                         JR   exit_overwrfile
.abort_file
                    LD   A,RC_EOF
                    OR   A                   ; Fz = 0, Fc = 1
                    SCF

.exit_overwrfile    POP  IX
                    POP  HL
                    POP  DE
                    POP  BC
                    RET



; ****************************************************************************
;
; Put Default Device (Panel setting) at (buf1).
;
.GetDefaultDevice
                    LD    A, 64
                    LD   BC, PA_Dev                    ; Read default device
                    LD   DE, buf1                      ; buffer for device name
                    PUSH DE                            ; save pointer to buffer
                    CALL_OZ (Os_Nq)
                    POP  DE
                    LD   B,0
                    LD   C,A                           ; actual length of string...
                    EX   DE,HL
                    ADD  HL,BC
                    LD   (HL),0                        ; null-terminate device name
                    RET


; ****************************************************************************
;
; Display name and size of stored files on Flash Eprom.
;
.catalog_main
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest
                    ret  c                        ; abort - FE apparently not available...

                    call cls
                    ld   a,(curslot)
                    ld   c,a
                    push bc
                    call FileEprFirstFile         ; return BHL pointer to first File Entry
                    call FileEprFileSize
                    ld   a,c
                    or   d
                    or   e
                    pop  de
                    jr   nz, dispfirstentry       ; is it the hidden system file entry?
                         ld   c,e
                         call FileEprNextFile     ; yes, skip it and display rest of filenames...
.dispfirstentry
                    ld   a,b
                    ld   (fbnk),a
                    ld   (fadr),hl
                    jr   nc, init_cat

                    ld   hl, noeprfilesmsg
                    CALL DispErrMsg
                    RET
.init_cat
                    ld   iy,status
                    res  0,(iy+0)                 ; preset to ignore del. files
                    res  1,(iy+0)                 ; preset to no lines displayed

                    xor  a
                    ld   hl, linecnt
                    ld   (hl),a

                    ld   hl, prompt_delfiles_ms
                    ld   de, no_ms
                    call yesno
                    jr   nz, begin_catalogue
                    set  0,(iy+0)                 ; display all files...
.begin_catalogue
                    call cls
.cat_main_loop
                    ld   a,(fbnk)
                    ld   b,a
                    ld   hl,(fadr)
                    ld   a,(curslot)
                    ld   c,a
                    ld   de, buf3            ; write filename at (DE), null-terminated
                    call FileEprFilename     ; copy filename from current file entry
                    jp   c, end_cat          ; Ups - last file(name) has been displayed...
                    jr   nz, disp_filename   ; active file, display...

                    ex   af,af'
                    bit  0,(iy+0)
                    jr   z,get_next_filename ; ignore deleted file(name)...
                    ex   af,af'

.disp_filename      set  1,(iy+0)            ; indicate display of filename...
                    push bc
                    push hl

                    push de
                    call nz,norm_aff
                    call z,tiny_aff
                    pop  hl
                    CALL_OZ(Gn_sop)          ; display filename

                    pop  hl
                    pop  bc
                    push bc
                    push hl
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprFileSize     ; get size of File Entry in CDE
                    ld   (flen),de
                    ld   b,0
                    ld   (flen+2),bc

                    call jrsz_aff
                    ld   hl,flen
                    call IntAscii
                    CALL_OZ gn_sop           ; display size of current File Entry
                    call jnsz_aff
                    pop  hl
                    pop  bc
.get_next_filename
                    call FileEprNextFile     ; get pointer to next File Entry in BHL...
                    ld   (fadr),hl
                    ld   a,b
                    ld   (fbnk),a

                    bit  1,(iy+0)
                    jr   z, cat_main_loop    ; no file were displayed, fetch new filename

                    res  1,(iy+0)
                    ld   hl, linecnt
                    inc  (hl)
                    ld   a,7
                    cp   (hl)
                    jr   nz,next_row
                    ld   (hl),0
                    call pwait
                    cp   rc_esc
                    jr   nz,new_page
                    ret
.new_page
                    ld   a,(curslot)
                    ld   c,a
                    call FileEprRequest                   
                    jr   nc,ok_new_page
                    ld   a,rc_fail
                    CALL_OZ gn_err
                    RET
.ok_new_page
                    call cls
                    jp   cat_main_loop
.next_row
                    CALL_OZ gn_nln
                    jp   cat_main_loop

.norm_aff           ld   hl,norm_sq
                    jr   dispsq
.tiny_aff           ld   hl,tiny_sq
                    jr   dispsq
.jrsz_aff           ld   hl,jrsz_sq
                    jr   dispsq
.jnsz_aff           ld   hl,jnsz_sq
.dispsq             push af
                    CALL_OZ gn_sop
                    pop  af
                    ret
.end_cat
                    ld   hl,endf_ms
                    CALL_OZ gn_sop
                    call pwait
                    ret

.noeprfilesmsg      DEFM "Empty Eprom.",$0D,$0A,0
.norm_sq            defm 1,"2-G",1,"4+TRUF",1,"4-TRU ",0
.tiny_sq            defm 1,"5+TRGUd",1,"3-RU ",0
.jrsz_sq            defm 1,"2JR",0
.jnsz_sq            defm 1,"2JN",0
.endf_ms            defm 1,"2-G",1,"4+TUR END ",1,"4-TUR",0
.prompt_delfiles_ms defm "Show deleted files? ",0


; **************************************************************************
;
; Format Flash Eprom and write "oz" File Eprom Header.
;
; Out:
;         Fc = 0,
;              Fz = 0, User prompted No to Format
;              Fz = 1, User performed format.
;         Fc = 1, Format process failed.
;
.format_main
                    call cls

.init_format_main
                    call FormatCard
                    ret  c
                    ret  nz
                    
                    call save_null_file           ; save the hidden "null" file to avoid FE bootstrapping
                    ret  c                        ; return errors state
                    
                    ld   a,3
                    ld   (curslot),a              ; automatically select slot 3 as new default...
                    cp   a                        ; otherwise indicate "Flash Eprom formatted"...
                    ret
.FormatCard                   
                    call CheckBatteryStatus       ; don't format Flash Eprom
                    ret  c                        ; if Battery Low is enabled...
                    
                    ld   c,3
                    CALL FlashEprCardId
                    JP   C, unkn_chip             ; Ups - Flash Eprom not available in slot 3

                    ld   hl,ffm1_br
                    call wbar                     ; "Format Flash eprom" head line

                    LD   C,3
                    CALL FileEprRequest
                    JR   NC, area_found
                         LD   C,3
                         CALL ApplEprType
                         JR   C, displ_noaplepr
                              LD   HL,fmt2_ms     ; "No File Area on Application Rom."
                              CALL sopnln
                              JR   ackn_format                                                 
.displ_noaplepr
                              LD   HL,fmt1_ms     ; "No File Area on Flash Eprom."
                              CALL sopnln
                              JR   ackn_format                   
.area_found
                         LD   HL,fmt3_ms          ; "Re-format File Area (All data will be lost)."
                         CALL sopnln
.ackn_format
                    ld   hl,sure_ms
                    ld   de,no_ms
                    call yesno
                    ret  nz

                    call cls
                    ld   hl,ffm2_br
                    call wbar
                    CALL_OZ gn_nln

                    CALL_OZ gn_nln
                    LD   HL,wroz_ms
                    CALL sopnln

                    CALL FlashEprFileFormat       ; blow "oz" header on top of Card
                    JR   C, WriteHdrError         ; or at top of free area.

                    CALL ResSpace
                    CP   A                        ; Signal success (Fc = 0, Fz = 1)
                    RET
.formaterr                                        ; current block was not formatted properly...
                    CP   RC_ROOM
                    JR   Z, applc_full
                         LD   HL, fferr_ms
                         CALL DispErrMsg
                    RET
.writeHdrError                                    ; File Eprom Header was not blown properly...
                    CP   RC_ROOM
                    JR   Z, applc_full
                         LD   HL, hdrerr_ms
                         CALL DispErrMsg
                         RET
.applc_full
                         LD   HL, hdrerr_ms
                         CALL DispErrMsg
                    RET
.save_null_file
                    ld   b,0
                    ld   hl,0                ; blow null file at bottom of card
                    ld   de, nullfile
                    ld   c, MS_S1            ; use segment 1 to blow the bytes...
                    ld   ix,6                ; Initial File Entry is 6 bytes long...
                    call FlashEprWriteBlock
                    ret                 
.nullfile           
                    defb 1, 0, 0, 0, 0, 0

.hdrerr_ms          defm "Header not written properly!",$0D,$0A,0
.applc_full_ms      defm "No room for File Area on Application Rom.",$0D,$0A,0
.fferr_ms           defm "File Area was not formatted/erased properly!",$0D,$0A,0
.ffm1_br            defm "FORMAT FLASH EPROM",0
.ffm2_br            defm "Formatting Flash Eprom - please wait...",0
.sure_ms            defm 1,"2+C",13,"Format (or create new) area in slot 3? ",0
.wroz_ms            DEFM " Writing File Eprom Header...",$0D,$0A,0
.fmt1_ms            DEFM 1,"BNo File Area on Flash Eprom.",1,"B",0
.fmt2_ms            DEFM 1,"BNo File Area on Application Rom.",1,"B",0
.fmt3_ms            DEFM 1,"BRe-format File Area in slot 3 (All data will be lost).",1,"B",0
.cbad_ms            defm 1,"BFlash Eprom not found in slot 3.",1,"B",0
                    


; ****************************************************************************
;
; Various standard routines
;


; ****************************************************************************
;
.sopnln
                    CALL_OZ gn_sop
                    CALL_OZ gn_nln
                    RET


; ****************************************************************************
;
.greyscr
                    PUSH HL
                    LD   HL,grey_ms
                    CALL_OZ gn_sop
                    POP  HL
                    RET
.grey_ms            defm 1,"6#8  ",$7E,$28,1,"2H8",1,"2G+",0



; ****************************************************************************
;
.cls
                    PUSH AF
                    PUSH HL
                    
                    LD   HL, clsvdu
                    CALL_OZ Gn_Sop

                    POP  HL
                    POP  AF
                    RET
.clsvdu             DEFM 1,"2H2",12,0


; ****************************************************************************
;
.rdch
                    CALL_OZ os_in
                    JR   NC,rd2
                    CP   RC_ESC
                    JR   Z, ret_esc
                    SCF
                    RET
.ret_esc
                    LD   A, IN_ESC
                    RET
.rd2
                    CP   0
                    RET  NZ
                    CALL_OZ os_in
                    RET


; ****************************************************************************
;
.pwait
                    LD   A,sr_pwt
                    CALL_OZ os_sr
                    JR   NC,pw2
                    CP   rc_susp
                    JR   Z,pwait
                    SCF
                    RET
.pw2
                    CP   0
                    RET  NZ
                    CALL_OZ os_in
                    RET


; ****************************************************************************
;
.yesno
                    CALL_OZ gn_sop
.yesno_loop         LD   H,D
                    LD   L,E
                    CALL_OZ gn_sop
                    CALL_OZ(OS_Pur)          ; make sure no keys in sys. inp. buffer...
                    CALL rdch
                    RET  C
                    CP   IN_ESC
                    JR   Z, abort_yesno
                    CP   13
                    JR   NZ,yn1
                    LD   A,E
                    CP   yes_ms % 256        ; Yes, Fc = 0, Fz = 1
                    RET  Z
                    OR   A                   ; No, Fc = 0, Fz = 0
                    RET
.abort_yesno
                    OR   A                   ; ESC pressed
                    RET                      ; return Fc = 0, Fz = 0
.yn1
                    OR   32
                    CP   'y'
                    JR   NZ,yn2
                    LD   DE,yes_ms
                    JR   yesno_loop
.yn2
                    CP   'n'
                    JR   NZ,yesno
                    LD   DE,no_ms
                    JR   yesno_loop
.yes_ms             defm 1,"2+CYes",8,8,8,0
.no_ms              defm 1,"2+CNo ",8,8,8,0



; ****************************************************************************
;
; Convert integer in HL (or BC) to Ascii string, which is written to (buf1) 
; and null-terminated.
;
; HL points at Ascii string, null-terminated.
;
.IntAscii
                    PUSH AF
                    PUSH DE
                    xor  a
                    ld   de,buf1
                    push de
                    CALL_OZ(GN_Pdn)
                    XOR  A
                    LD   (DE),A
                    POP  HL
                    pop  de
                    POP  AF
                    RET


; ************************************************************************
;
; Display error code value in hex.
; User then presses ESC to continue
;
;.DispErrorCode      PUSH AF
;                    PUSH HL

;                    LD   HL, errcodemsg
;                    CALL_OZ(Gn_Sop)
;                    CALL hexbyte
;                    LD   A,'h'
;                    CALL_OZ(OS_out)
;                    CALL_OZ(Gn_Nln)
;                    CALL ResSpace

;                    POP  HL
;                    POP  AF
;                    RET
;.errcodemsg         DEFM "Error code returned: ",0


; ************************************************************************
;
; User is prompted with "Press SPACE to Resume". The keyboard is then scanned
; for the SPACE key.
;
; The routine returns when the user has pressed ESC.
;
; Registers changed after return:
;    None.
;
.ResSpace
                    PUSH AF
                    PUSH HL
                    LD   HL,ResSpace_ms
                    CALL_OZ gn_sop
.escin
                    CALL rdch
                    JR   C,escin
                    CP   32
                    JR   NZ,escin
                    POP  HL
                    POP  AF
                    RET
.ResSpace_ms        DEFM 1,"3+FTPRESS ",1,SD_SPC," TO RESUME",1,"4-FTC",$0D,$0A,0



; ************************************************************************
;
.hexbyte
                    push hl
                    push de
                    push af
                    and 240
                    rra
                    rra
                    rra
                    rra
                    call affq
                    pop  af
                    and  15
                    call affq
                    pop  de
                    pop  hl
                    ret
.affq
                    ld   h,0
                    ld   l,a
                    ld   de,hexnumb_list
                    add  hl,de
                    ld   a,(hl)
                    CALL_OZ os_out
                    ret
.hexnumb_list       defm "0123456789ABCDEF",0



; ****************************************************************************
;
; Write Error message, and wait for ESC wait to be acknowledged.
;
; Registers changed after return:
;    AFBCDE../IXIY same
;    ......HL/.... different
;
.DispErrMsg
                    PUSH AF                  ; preserve error status...
                    PUSH HL
                    CALL sopnln
                    CALL ResSpace            ; "Press ESC to resume" ...
                    POP  HL
                    POP  AF
                    RET


; ****************************************************************************
;
.ReportStdError     PUSH AF
                    CALL_OZ(Gn_Err)
                    POP  AF
                    RET


; *****************************************************************************
;
; Check for Battery Low status and report to user, if enabled.
;
; IN:
;    None.
;
; Out:
;    Fc = 1, if Battery Low Status is enabled
;         A = RC_WP (Flash Eprom Write Protected)
;    Fc = 0, Battery Power is operational for Flash Eprom action
;
.CheckBatteryStatus CALL CheckBattLow
                    RET  NC

                    PUSH HL
                    LD   HL, battlowmsg
                    CALL DispErrMsg
                    POP  HL

                    LD   A, RC_Wp                 ; general failure...
                    SCF
                    RET

.battlowmsg         DEFM "Batteries are low.",$0D,$0A,0


; ****************************************************************************
;
; FlashStore Error Handler
;
.ErrHandler
                    RET  Z
                    CP   rc_susp
                    JR   Z,dontworry
                    CP   rc_esc
                    JR   Z,akn_esc
                    CP   rc_quit
                    JR   Z,suicide
                    CP   A
                    RET
.akn_esc
                    LD   A,1                 ; acknowledge ESC detection
                    CALL_OZ os_esc
.dontworry
                    cp   a                   ; all other RC errors are returned to caller
                    RET
.suicide            xor  a
                    CALL_OZ(os_bye)          ; perform suicide, focus to Index...
.void               JR   void



; ************************************************************************
;
.DispZlabLogo
                    LD   HL, zlab_logo
                    CALL_OZ(Gn_Sop)
                    RET
.zlab_logo
                    defm 1,138,"=",64,63,32,39,39,39,38,36,32
                    defm 1,138,"=",65,63,128,63,63,48,128,128,3
                    defm 1,138,"=",66,63,128,63,63,3,15,60,48
                    defm 1,138,"=",67,63,1,57,57,49,1,1,1
                    defm 1,138,"=",68,32,32,35,39,39,32,38,38
                    defm 1,138,"=",69,15,60,48,63,63,128,3,6
                    defm 1,138,"=",70,128,128,3,63,63,128,35,22
                    defm 1,138,"=",71,9,25,57,57,57,1,33,17
                    defm 1,138,"=",72,38,38,38,38,38,39,32,63
                    defm 1,138,"=",73,6,7,6,6,6,54,128,63
                    defm 1,138,"=",74,22,55,22,22,22,23,128,63
                    defm 1,138,"=",75,17,33,17,9,9,49,1,63

                    defm 1,"2H7"
                    defm 1,"3@",35,34,1,"2?","@",1,"2?","A",1,"2?","B",1,"2?","C"
                    defm 1,"3@",35,35,1,"2?","D",1,"2?","E",1,"2?","F",1,"2?","G"
                    defm 1,"3@",35,36,1,"2?","H",1,"2?","I",1,"2?","J",1,"2?","K"
                    defb 0


; ************************************************************************
;
. DispInterLogicLogo
                    LD   HL, InterLogic_logo
                    CALL_OZ(Gn_Sop)
                    RET

.InterLogic_logo    defb 1, 138, '=', 'L', @10000000, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000 
                    defb 1, 138, '=', 'M', @10000000, @10000000, @10000000, @10010000, @10010001, @10000010, @10010000, @10010000
                    defb 1, 138, '=', 'N', @10000000, @10000000, @10000000, @10000000, @10000000, @10101011, @10010000, @10000000
                    defb 1, 138, '=', 'O', @10000000, @10000000, @10000000, @10100000, @10100001, @10111011, @10100001, @10100000
                    defb 1, 138, '=', 'P', @10000000, @10000000, @10000000, @10100010, @10000010, @10110011, @10000010, @10100010
                    defb 1, 138, '=', 'Q', @10000000, @10000000, @10000000, @10000000, @10000000, @10110000, @10000000, @10000000
                    defb 1, 138, '=', 'R', @10000000, @10000000, @10000111, @10000111, @10000111, @10000111, @10000011, @10000011
                    defb 1, 138, '=', 'S', @10000000, @10000000, @10111111, @10111111, @10101111, @10101110, @10101101, @10101110
                    defb 1, 138, '=', 'T', @10000000, @10000000, @10111111, @10111111, @10011111, @10101110, @10110101, @10101110
                    defb 1, 138, '=', 'U', @10000000, @10000000, @10111111, @10111111, @10011110, @10111110, @10110111, @10101110
                    defb 1, 138, '=', 'V', @10000000, @10000000, @10111111, @10111111, @10111110, @10111101, @10111011, @10111101
                    defb 1, 138, '=', 'W', @10000000, @10000000, @10111100, @10111100, @10111100, @10111100, @10111000, @10111000
                    defb 1, 138, '=', 'X', @10000001, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000
                    defb 1, 138, '=', 'Y', @10101111, @10111111, @10011111, @10000111, @10000001, @10000000, @10000000, @10000000
                    defb 1, 138, '=', 'Z', @10011111, @10111111, @10111111, @10111111, @10111111, @10001111, @10000000, @10000000
                    defb 1, 138, '=', 'a', @10011110, @10111111, @10111111, @10111111, @10111111, @10111111, @10000000, @10000000
                    defb 1, 138, '=', 'b', @10111110, @10111111, @10111111, @10111100, @10110000, @10000000, @10000000, @10000000
                    defb 1, 138, '=', 'c', @10110000, @10100000, @10000000, @10000000, @10000000, @10000000, @10000000, @10000000

                    defm 1,"2H7"
                    defm 1,"3@",34,37,1,"2?","L",1,"2?","M",1,"2?","N",1,"2?","O",1,"2?","P",1,"2?","Q"
                    defm 1,"3@",34,38,1,"2?","R",1,"2?","S",1,"2?","T",1,"2?","U",1,"2?","V",1,"2?","W"
                    defm 1,"3@",34,39,1,"2?","X",1,"2?","Y",1,"2?","Z",1,"2?","a",1,"2?","b",1,"2?","c"
                    defb 0


; *****************************************************************************
;
; Library calls are added here by linker...
;
