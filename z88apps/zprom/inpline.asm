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


    MODULE InputLine


    XREF DisplayMenu
    XREF Zprom_ERH
    XREF Display_string
    XREF IntHexConv

    XDEF InpLine, InpSelectLine, FindItem, GetItemPtr, ClearEditBuffer
    XDEF DispItemDescr
    XDEF PresetBuffer_hex16, PresetBuffer_hex8
    XDEF FetchCurPath


    INCLUDE "defs.asm"
    INCLUDE "stdio.def"
    INCLUDE "syspar.def"
    INCLUDE "saverst.def"
    INCLUDE "memory.def"



; ******************************************************************************************************
;
; Standard input line routine in menu window of width 42, height 4 (2 lines of user input).
; All input will be entered into buffer 'EditBuffer'
;
; IN:   BC: (X,Y) of menu window
;       DE: pointer to input prompt message
;       HL: pointer to menu window banner
;        A: Cursor position in buffer
;
; OUT    A: Last key pressed - either <ENTER> or <ESC>.
;       DE: local pointer to start of buffer
;        B: Length of Input line including null-terminator
;        C: cursor position in buffer (rel. to start of buffer)
;
; All registers except IX,IY changed on return
;
.Inpline            CALL Init_Inputline
                    LD   C,A                            ; cursor position in buffer
                    LD   A,(BufSize)                    ; max. buffer length
                    LD   B,A
                    
                    LD   DE,EditBuffer                  ; DE points at beginning of buffer
                    CALL DisplayMenu                    ; display the menu and input line...
.inpline_loop       LD   A,@00100001                    ; Single Line Lock, info in buffer
                    LD   HL,CurPos                      ; set cursor position for input
                    CALL_OZ (Gn_Sop)
                    LD   L,40                           ; window is 40 chars wide
                    CALL_OZ (Gn_Sip)                    ; edit & type file name...
                    RET  NC                             ; <ENTER> pressed - filename entered.
                    CALL C, Zprom_ERH
                    PUSH AF
                    LD   A,(BufSize)                    ; re-initiate buffer length
                    LD   B,A
                    POP  AF
                    BIT  GetMail,(IY + 0)
                    CALL NZ,Fetch_mail                  ; try to fetch filename from Filer...
                    JR   inpline_loop
.CurPos             DEFM 1, "2JN"                       ; use normal justify...
                    DEFM 1, "3@", 33, 33, 1, "2+C", 0   ; set cursor at (1,1) flashing...
                    


; ******************************************************************************************************
;
; Standard input line routine in menu window of width 42, height 4 (2 lines of user input) with
; option to select an item during input by pressing ^J.
; The Input buffer is cleared and preset with the current Item, indexed by value at (HL').
; All input will be entered into buffer 'EditBuffer'
;
; IN:   BC : (X,Y) of menu window
;       DE : Pointer to input prompt message
;       HL : Pointer to menu window banner
;        A : Current Item Index
;       IX : Pointer to Item Selection Block (base of)
;
; OUT    A: Last key pressed - either <ENTER> or <ESC>.
;       DE: local pointer to start of buffer
;        B: Length of Input line including null-terminator
;        C: cursor position in buffer (rel. to start of buffer)
;
; Register status on return:
;
; ....DE../IXIY/........  same
; AFBC..HL/..../afbcdehl  different
;
.InpSelectline      CALL Init_Inputline                 ; store menu definitions
                    CALL ClearEditBuffer
                    LD   DE,EditBuffer                  ; DE points at beginning of buffer
                    CALL GetItemDescrPtr                ; get pointer to Item Description in HL
                    CALL SetItemBuffer                  ; preset buffer with Item Description
                    CALL DisplayMenu                    ; Display the menu and input line...
                    PUSH AF
                    LD   A,(BufSize)                    ; max. buffer length
                    LD   B,A
                    POP  AF
                    LD   C,0                            ; cursor position at start of buffer
.inpSelectline_loop PUSH AF                             ; preserve current Item Index
                    LD   A,@00101001                    ; Single Line Lock, info in buffer
                    LD   HL,CurPos                      ; set cursor position for input
                    CALL_OZ (Gn_Sop)
                    LD   L,40                           ; window is 40 chars wide
                    CALL_OZ (Gn_Sip)                    ; edit & type file name...
                    JR   NC, examine_keycode            ; key code returned - examine...
                    CALL Zprom_ERH                      ; redraw screen, if necessary...
.examine_keycode    POP  HL                             ; current Item Index in H
                    CP   IN_ENT                         ; input ended?
                    RET  Z
                    CP   IN_ESC                         ; input aborted?
                    RET  Z
                    CP   LF                             ; ^J pressed?
                    LD   A,H                            ; Item Index back in A
                    CALL Z,SelectNextItem               ; preset buffer with next item
                    PUSH AF
                    LD   A,(BufSize)                    ; re-initiate buffer length
                    LD   B,A
                    POP  AF
                    JR   inpSelectline_loop


; ******************************************************************************************
;
.Init_Inputline     LD   (MenuPosition),BC              ; save position of menu window
                    LD   (MenuPrompt),DE                ; save pointer to menu prompt
                    LD   (MenuBanner),HL                ; save pointer to menu banner
                    LD   HL,DisplayMenu
                    LD   (MenuWindow),HL
                    LD   HL,$042A                       ; width 42, height 4
                    LD   (MenuSize),HL
                    RET


; *******************************************************************************************
;
.SelectNextItem     CALL ClearEditBuffer                ; first reset buffer
                    CALL GetNextItemIndex               ; get next item index in A
                    CALL GetItemDescrPtr                ; return ptr. in HL
                    CALL SetItemBuffer                  ; copy Item Description into buffer
                    LD   HL,CurPos                      ; set cursor position at start of input line
                    CALL_OZ (Gn_Sop)
                    LD   HL,clear_line                  ; cls input line...
                    CALL_OZ (Gn_Sop)
                    RET
.clear_line         DEFM 1, "3N", 32+39, 32, 0          ; display 39 spaces from start of line...


; *******************************************************************************************
;
; Preset buffer with Item Description.
;
; IN:   HL = Pointer to Item Description
;       DE = Pointer to start of Buffer
;
.SetItemBuffer      PUSH AF                             ; preserve Item Index
                    PUSH DE                             ; preserve ptr to start of buffer
.copy_item_loop     LD   A,(HL)
                    CP   0                              ; end of Item Description?
                    JR   Z,itemdescr_copied
                    LD   (DE),A
                    INC  DE
                    INC  HL
                    JR   copy_item_loop
.itemdescr_copied   POP  DE                             ; ptr. to start of Buffer restored
                    POP  AF                             ; restore Item Index
                    RET


; ******************************************************************************
;
; IN:    A  = Current Item Index
;       IX  = Pointer to Item Selection Block (base of)
;
; OUT:  A   = Next Item Index
;
.GetNextItemIndex   CP   (IX+0)                         ; get max index number
                    JR   NZ,inc_item_index
                    LD   A,0
                    RET
.inc_item_index     INC  A
                    RET


; *********************************************************************************
;
; Get Pointer to Item (return pointer to [<Item>,<ptr. to Item descr.>] .
;
;  IN:  A  = Item Index
;       IX = Pointer to Item Selection Block (base of)
;
; OUT:  HL = Pointer to Item
;
.GetItemPtr         PUSH AF
                    PUSH BC
                    PUSH IX
                    POP  HL
                    INC  HL                             ; point at first item (word)
                    RLCA
                    RLCA                                ; A * 4 - each item uses 4 bytes...
                    LD   C,A
                    LD   B,0
                    ADD  HL,BC                          ; HL points at item
                    POP  BC
                    POP  AF
                    RET


; *********************************************************************************
;
; Get Pointer to Item Description.
;
;  IN:  A  = Item Index
;       IX = Pointer to Item Selection Block (base of)
;
; OUT:  HL = Pointer to Item Description
;
.GetItemDescrPtr    PUSH AF
                    PUSH DE
                    PUSH IX
                    POP  HL
                    INC  HL                             ; point at first item (word)
                    RLCA
                    RLCA                                ; A * 4 - each item uses 4 bytes...
                    LD   E,A
                    LD   D,0
                    ADD  HL,DE                          ; HL points at item
                    INC  HL
                    INC  HL                             ; point at pointer to Item Descr.
                    LD   E,(HL)
                    INC  HL
                    LD   D,(HL)
                    EX   DE,HL                          ; pointer to Item Description
                    POP  DE
                    POP  AF
                    RET


; ******************************************************************************
;
; Display the description of item in current window at cursor position
; of the currently selected item.
; IN: A  = Item Index
;     IX = pointer to Item Selection Block (base of)
;
.DispItemDescr      PUSH HL
                    PUSH DE
                    PUSH BC
                    PUSH AF
                    CALL GetItemDescrPtr                ; return pointer to Item Description
                    CALL Display_string                 ; display item description
                    POP  AF
                    POP  BC
                    POP  DE
                    POP  HL
                    RET


; ******************************************************************************************************
;
; Find Item Description in Item Selection Block
;
; IN : DE = Pointer to description to search for (null-terminated)
;           (Usually pointer to an input buffer)
;      IX = Pointer to Item Selection Block (base of)
;
; OUT:  A = Index of found Item / -Description (Fc = 0 - found).
;      Fc = 1, string wasn't found in Item Selection Block
;
.FindItem           PUSH BC
                    LD   A,0                            ; get first Item description
                    LD   B,0                            ; HL is a local pointer
.finditem_loop      CALL GetItemDescrPtr                ; pointer to Descr. in HL
                    PUSH AF
                    CALL_OZ(Gn_Cme)                     ; compare strings
                    JR   Z,found_item                   ; - equal...
                    POP  AF                             ; restore Item Index
                    CP   (IX+0)                         ; was this the last item?
                    JR   Z,item_not_found
                    INC  A                              ; no, compare string with next Item Descr.
                    JR   finditem_loop
.found_item         POP  AF                             ; restore item desciption index
                    POP  BC
                    CP   A                              ; Fc = 0, found Item Index in A
                    RET
.item_not_found     POP  BC
                    SCF                                 ; Item Description wasn't found
                    RET


; ******************************************************************************************************
;
.ClearEditBuffer    PUSH HL
                    PUSH DE
                    PUSH BC
                    PUSH AF
                    LD   A,(BufSize)                    ; get size of edit buffer
                    LD   B,A
                    POP  AF
                    LD   HL,EditBuffer
.clearbuf_loop      LD   (HL),0                         ; put null's in buffer
                    INC  HL
                    DJNZ clearbuf_loop
                    POP  BC
                    POP  DE
                    POP  HL
                    RET


; ************************************************************************************************
;
; Fetch the current directory path into buffer.
; Buffer must have a minimum of 64 bytes length.
; DE must point to buffer (local pointer).
; A '/' is automatically appended to path name.
;
; Returns C = length of path.
;
; Register status on return:
;
;   AFB.DEHL/IXIY     same
;   ...C..../....     different
;
;
.FetchCurPath       PUSH HL
                    PUSH BC
                    PUSH AF
                    PUSH DE                             ; remember start of buffer
                    LD   BC,NQ_DEV
                    CALL_OZ (Os_Nq)                     ; get current device at extended address
                    LD   C,6
                    CALL_OZ (Os_Bhl)                    ; copy device into buffer (always 6 bytes long)
                    LD   B,0                            ; move DE to end of device name...
                    EX   DE,HL
                    ADD  HL,BC
                    EX   DE,HL                          ; DE ready for current directory
                    LD   BC,NQ_DIR
                    CALL_OZ (Os_Nq)                     ; get ...
                    LD   C,56                           ; copy path into buffer, only up to max.
                    CALL_OZ (Os_Bhl)                    ; size of buffer.
                    LD   B,0
                    EX   DE,HL
                    LD   A,0
                    CPIR                                ; find null-terminator of directory path
                    DEC  HL                             ; point at null
                    LD   (HL),'/'                       ; append directory name separator
                    INC  HL
                    LD   (HL),0                         ; null-terminate...
                    POP  DE
                    CP   A
                    SBC  HL,DE                          ; length of path from start of buffer in HL
                    POP  AF                             ; restore
                    POP  BC                             ; restore
                    LD   C,L                            ; return length in C
                    POP  HL                             ; restore
                    RET


; *************************************************************************************************
; Preset Edit buffer with 8bit ASCII Hexadecimal value
;
; IN:   L (8 bit integer)
;
.PresetBuffer_Hex8  PUSH BC
                    PUSH DE
                    PUSH HL
                    CP   A
                    CALL IntHexConv                     ; convert to ASCII HEX in BC
                    CALL ClearEditBuffer
                    LD   HL,EditBuffer
                    LD   (HL),B
                    INC  HL
                    LD   (HL),C                         ; and put it in edit buffer
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; *************************************************************************************************
; Preset Edit buffer with 16bit ASCII Hexadecimal value
;
; IN:   HL (16bit integer)
;
.PresetBuffer_Hex16 PUSH BC
                    PUSH DE
                    PUSH HL
                    SCF
                    CALL IntHexConv                     ; convert to ASCII HEX in DEBC
                    CALL ClearEditBuffer
                    LD   HL,EditBuffer
                    LD   (HL),D
                    INC  HL
                    LD   (HL),E                         ; high byte ASCII HEX byte
                    INC  HL
                    LD   (HL),B
                    INC  HL
                    LD   (HL),C                         ; low byte ASCII HEX byte
                    POP  HL
                    POP  DE
                    POP  BC
                    RET


; *************************************************************************************************
;
; Try to read mail into the input buffer
;
;  IN: B  = max buffer length
;      DE = pointer to start of buffer
;
; Register status on return:
;
;   AFB.DE../IXIY     same
;   ...C..HL/....     different
;
.Fetch_mail         PUSH AF
                    PUSH BC
                    PUSH DE                            ; preserve input parameters
                    LD   C,B                           ; C identifies max. length
                    LD   B,0                           ; local pointer
                    EX   DE,HL                         ; (B=0) HL
                    LD   DE,filename_type
                    LD   A, SR_RPD
                    CALL_OZ(Os_Sr)                     ; read mail, if present...
                    JR   NC, alter_cursor              ; fetched, set cursor at end of name...
                    POP  DE
                    POP  BC
                    POP  AF
                    RET
.alter_cursor       LD   L,C                           ; length of mail
                    POP  DE
                    POP  BC
                    LD   C,L                           ; will set cursor to end of line
                    POP  AF
                    RET

.filename_type      DEFM "NAME", 0                    ; mail is of filename type
