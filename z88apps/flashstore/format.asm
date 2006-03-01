; *************************************************************************************
; FlashStore
; (C) Gunther Strube (gbs@users.sf.net) & Thierry Peycru (pek@users.sf.net), 1997-2005
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

Module FileAreaFormat

; This module contains functionality to format the file area on Flash Cards.

     xdef FormatCommand, execute_format, FlashWriteSupport, CheckFlashCardID
     xdef PollFileFormatSlots
     xdef noformat_msg

     lib FlashEprFileFormat        ; Create "oz" File Eprom or area on application card
     lib FlashEprCardId            ; Return Intel Flash Eprom Device Code (if card available)
     lib FileEprRequest            ; Check for presence of Standard File Eprom Card or Area in slot
     lib ApplEprType               ; check for presence of application card in slot

     xref PollFileArea             ; browse.asm
     xref ResetWatermark           ; browse.asm
     xref FileEpromStatistics      ; filestat.asm
     xref SelectFileArea           ; selectcard.asm
     xref done_msg                 ; fetchfile.asm
     xref DispMainWindow,ResSpace  ; fsapp.asm
     xref sopnln, ungreyscr, cls   ; fsapp.asm
     xref yesno,no_msg             ; fsapp.asm
     xref GetCurrentSlot           ; fsapp.asm
     xref DispSlotErrorMsg         ; errmsg.asm
     xref NoAppFileAreaMsg         ; errmsg.asm
     xref disp_empty_flcard_msg    ; errmsg.asm
     xref DispErrMsg               ; errmsg.asm

     ; system definitions
     include "stdio.def"
     include "memory.def"
     include "error.def"

     ; FlashStore popdown variables
     include "fsapp.def"


; *************************************************************************************
;
; Format Flash Card / (Re)Create File Area.
;
; Out:
;         Fc = 0,
;              Fz = 0, User prompted No to Format
;              Fz = 1, User performed format.
;         Fc = 1, Format process failed.
;
.FormatCommand
                    call PollFileFormatSlots      ; investigate slots 1-3 for Flash Cards that can be formatted
                    or   a
                    jr   z, no_format_available   ; no Flash Cards available that may be formatted...
                    jr   FormatFileArea
.no_format_available
                    LD   HL, ffm1_bnr
                    CALL DispMainWindow           ; create main window when displaying error message
                    LD   HL, noformat_msg         ; on FlashStore popdown startup.
                    CALL DispErrMsg
                    scf
                    ret
.FormatFileArea
                    cp   1
                    jr   z, preselect_slot
                    ld   hl, ffm1_bnr
                    CALL SelectFileArea           ; several file areas can be formatted, select one...
                    ret  c                        ; user aborted selection
                    call GetCurrentSlot           ; C = (curslot)
                    CALL FlashWriteSupport
                    ret  c                        ; user selected a non-formattable file-area...
                    LD   HL, ffm1_bnr
                    CALL DispMainWindow           ; redraw main catalogue window for format command interaction...
                    JR   execute_format
.preselect_slot
                    ld   a,c
                    ld   (curslot),a              ; the selected slot...
.execute_format
                    call ungreyscr
                    CALL FileEpromStatistics
                    ld   hl,ffm1_bnr
                    CALL DispMainWindow

                    call GetCurrentSlot           ; C = (curslot)
                    PUSH BC
                    CALL FileEprRequest           ; C = slot number...
                    POP  BC
                    JR   Z, area_found
                         PUSH BC
                         CALL ApplEprType         ; C = slot number...
                         POP  BC
                         JR   C, displ_noaplepr
                              CALL NoAppFileAreaMsg
                              JR   ackn_format
.displ_noaplepr
                              CALL disp_empty_flcard_msg  ; "Empty Flash Card in slot x"
                              JR   ackn_format
.area_found
                         CALL Disp_reformat_msg    ; "Re-format File Area (All data will be lost)."
.ackn_format
                    ld   hl,disp_filefmt_ask_msg
                    ld   de,no_msg
                    call yesno
                    jr   nz, exit_ffa

                    call cls

                    ld   hl,ffm2_msg
                    CALL_OZ GN_Sop

                    call GetCurrentSlot           ; C = (curslot)
                    CALL FlashEprFileFormat       ; erase blocks of file area & blow "oz" header at top

                    push af
                    call PollFileArea             ; reset file area information
                    pop  af

                    JR   C, formaterr             ; or at top of free area.

                    call cls
                    ld   hl,ffm3_msg
                    CALL_OZ GN_Sop

                    LD   HL, wroz_msg
                    CALL_OZ GN_Sop
                    LD   HL,done_msg
                    CALL sopnln

                    CALL ResSpace
.exit_ffa
                    CP   A                        ; Signal success (Fc = 0, Fz = 1)
                    RET
.formaterr                                        ; current block was not formatted properly...
                    call cls
                    LD   HL, fferr_msg
                    CALL DispErrMsg
                    CALL ResetWatermark
                    RET
; *************************************************************************************


; *************************************************************************************
; Return no of formatable file areas, available in inserted Flash Cards in slots 1-3.
;
; IN:
;     None.
; OUT:
;     A = formatable file areas (on for each slot, 1 - 3).
;     C = slot number for a default formatable File Area (if A>0)
;
.PollFileFormatSlots
                    push de
                    push bc
                    push hl

                    ld   hl, availslots+1    ; point to counter of available slots
                    push hl
                    ld   c,1                 ; begin with external slot 1
                    ld   e,0                 ; counter of available file eproms
.poll_format_loop
                    push bc                  ; preserve slot number...
                    call FileEprRequest      ; File Eprom Card or area available in slot C?
                    ld   a,c
                    pop  bc
                    jr   c, check_empty_fep
                         call FlashWriteSupport ; active or potential file area found, check if there's format support
                         jr   c, no_feprformat
.found_feprformat        inc  e              ; Formatable Flash Card found in slot
                         pop  hl
                         ld   (hl),a         ; size of Flash File Area in 16K banks
                         inc  hl
                         push hl
                         jr   next_feprslot
.check_empty_fep
                         call FlashWriteSupport
                         jr   c, no_feprformat
                         jr   nz, no_feprformat
                         ld   a,b            ; empty, formattable flash card has B banks available...
                         jr   found_feprformat
.no_feprformat
                         pop  hl
                         ld   (hl),0         ; indicate no formatable flash file area
                         inc  hl
                         push hl
.next_feprslot
                    inc  c
                    ld   a,c
                    cp   4
                    jr   nz, poll_format_loop

                    ld   a,e
                    pop  hl
                    ld   (availslots),a      ; store total of Formatable Flash File Areas
                    or   a
                    jr   z, end_pollformat   ; no formatable file areas found...

                    ld   hl,availslots+3
                    dec  c                   ; get default formatable slot in c, starting at 3...
.check_default_loop
                    ld   b,(hl)
                    inc  b
                    dec  b
                    jr   nz, end_pollformat
                    dec  hl
                    dec  c
                    jr   nz,check_default_loop
.end_pollformat
                    pop  hl
                    pop  de
                    ld   b,d                 ; orignal B restored
                    pop  de
                    cp   a                   ; Fc = 0
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Validate the Flash Card erase/write functionality in the specified slot.
; If the Flash Card in the specified slot contains an Intel chip, the
; slot must be 3 for format, save and delete functionality.
; Report an error to the caller with Fc = 1, if an Intel Flash chip was recognized
; in all slots except 3.
;
; (This routine is called by format, save & delete functionality in FlashStore)
;
; IN:
;    C = slot number
;
; OUT:
;    Fz = 1, if a Flash Card is available in the current slot (Fz = 0, no Flash Card available!)
;         B = size of card in 16K banks
;    Fc = 1, if no erase/write support is available for current slot.
;
; Registers changed after return:
;    A..CDEHL/IXIY same
;    .FB...../.... different
;
.FlashWriteSupport
                    push hl
                    push de
                    push bc
                    push af
                    call CheckFlashCardID
                    jr   nc, flashcard_found
                    or   c                   ; Fz = 0, indicate no Flash Card available in slot
                    scf                      ; Fc = 1, indicate no erase/write support either...
                    jr   exit_chckflsupp
.flashcard_found
                    ld   a,c
                    cp   3
                    jr   z, end_chckflsupp   ; erase/write works for all flash cards in slot 3 (Fc=0, Fz=1)
                    ld   a,$01
                    cp   h                   ; Intel flash chip in slot 0,1 or 2?
                    jr   z, end_chckflsupp   ; No, we found an AMD Flash chip (erase/write allowed, Fc=0, Fz=1)
                    cp   a                   ; (Fz=1, indicate that Flash is available..)
                    scf                      ; no erase/write support in slot 0,1 or 2 with Intel Flash...
.end_chckflsupp
                    pop  de
                    ld   a,d                 ; A restored (f changed)
                    pop  de
                    ld   c,e                 ; C restored (B = total of 16K banks on card)
                    pop  de                  ; DE restored
                    pop  hl                  ; HL restored
                    ret
.exit_chckflsupp
                    pop  de
                    ld   a,d                 ; A restored (f changed)
                    pop  bc
                    pop  de
                    pop  hl
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Check/Fetch Flash Card ID (Manufacturer & Device Code)
;
; IN:
;    C = Slot Number
;
; Out:
;    Register status from FlashEprCardId library routine
;    (flashid) variable updated: FFFF = no Flash Card found, otherwise HL -> (flashid)
;
.CheckFlashCardID
                    call FlashEprCardId
                    jr   c, no_flash_found
                    ld   (flashid),hl
                    ret
.no_flash_found     ld   hl,-1
                    ld   (flashid),hl
                    ret
; *************************************************************************************


; *************************************************************************************
.disp_reformat_msg
                    PUSH HL
                    LD   HL, reformat_msgs
                    CALL DispSlotErrorMsg
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
.disp_filefmt_ask_msg
                    PUSH HL
                    LD   HL, filefmt_msgs
                    CALL DispSlotErrorMsg
                    POP  HL
                    RET
; *************************************************************************************


; *************************************************************************************
; constants

.noformat_msg       DEFM 1,"BNo Flash Card was available to be formatted", 13, 10, "or no File Area found in slots 1-3.",1,"B", 13, 10, 0

.fferr_msg          DEFM "File Area not formatted properly!",$0D,$0A,0
.ffm1_bnr           DEFM "FORMAT FILE AREA ON FLASH CARD",0
.ffm2_msg           DEFM 13, 10, 1, "F Formatting File Area ... ", 1, "F", 0
.ffm3_msg           DEFM 13, 10, " File Area formatted.", 13, 10, 0
.wroz_msg           DEFM " Writing File Area Header... ",0

.reformat_msgs      DEFW reformat1_msg
                    DEFW reformat2_msg
.reformat1_msg      DEFM 13, 10, 1,"BRe-format File Area in slot ",0
.reformat2_msg      DEFM " (All data is lost).",1,"B",0

.filefmt_msgs       DEFW filefmt_ask1_msg
                    DEFW filefmt_ask2_msg
.filefmt_ask1_msg   DEFM 1,"2+C",13,"Format (or create new) file area in slot ",0
.filefmt_ask2_msg   DEFM "? ",0
