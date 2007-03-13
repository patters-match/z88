        module FileEprSaveRamFile

; **************************************************************************************************
; File Area functionality.
;
; This file is part of the Z88 operating system, OZ.     0000000000000000      ZZZZZZZZZZZZZZZZZZZ
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
; ***************************************************************************************************

        xdef FileEprSaveRamFile

        lib OZSlotPoll, SetBlinkScreen

        xref FlashEprCardId, FileEprDeleteFile, FlashEprWriteBlock
        xref FileEprFreeSpace
        xref FileEprNewFileEntry
        xref SetBlinkScreenOn

        include "error.def"
        include "fileio.def"
        include "memory.def"


        defc SizeOfWorkSpace = 256         ; size of Workspace on stack, IY points at base...

        ; Relative offset definitions for allocated work buffer on stack
        defvars 0
             IObuffer  ds.w 1              ; Pointer to I/O buffer
             IObufSize ds.w 1              ; Size of I/O buffer
             Fhandle   ds.w 1              ; Handle of openend file
             FileEntry ds.p 1              ; pointer to File Entry
             CardSlot  ds.b 1              ; slot number of File Eprom Card
             Heap                          ; Internal Workspace
        enddef


; **************************************************************************
;
; Standard Z88 File Eprom Format.
;
; Save RAM file to Flash Memory or UV Eprom file area in slot C.
;
; The routine does NOT handle automatical "deletion" of existing files
; that matches the filename (excl. device). This must be used by a call
; to <FlashEprFileDelete>.
;
; Should the actual process of blowing the file image fail, the new
; File Entry will be marked as deleted, if possible.
;
; -------------------------------------------------------------------------
; The screen is turned off while saving a file to flash file area that is in
; the same slot as the OZ ROM. During saving, no interference should happen
; from Blink, because the Blink reads the font bitmaps each 1/100 second:
;    When saving a file is part of OZ ROM chip, the font bitmaps are suddenly
;    unavailable which creates violent screen flickering during chip command mode.
;    Further, and most importantly, avoid Blink doing read-cycles while
;    chip is in command mode.
; By switching off the screen, the Blink doesn't read the font bit maps in
; OZ ROM, and the Flash chip can be in command mode without being disturbed
; by the Blink.
; -------------------------------------------------------------------------
;
; Important:
; INTEL I28Fxxxx series Flash chips require the 12V VPP pin in slot 3
; to successfully blow data to the memory chip. If the Flash Eprom card
; is inserted in slot 1 or 2, this routine will report a programming failure.
;
; It is the responsibility of the application (before using this call) to
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; Equally, the application should evaluate that saving to a file are on an 
; UV Eprom only can be performed in slot 3. This routine will report failure
; if saving a file to slots 0, 1 or 2.
;
; IN:
;          C = slot number (0, 1, 2 or 3)
;         IX = size of I/O buffer.
;         DE = pointer to I/O buffer, in segment 0.
;         HL = pointer to filename string (null-terminated), in segment 0.
;              Filename may contain wildcards (to find first match)
; OUT:
;         Fc = 0, File successfully saved to Flash File Eprom.
;              BHL = pointer to created File Entry in slot C.
;
;         Fc = 1,
;              File (Flash) Eprom not available in slot A:
;                   A = RC_NFE (not a recognized Flash Memory Chip)
;              Not sufficient space to store file (and File Entry Header):
;                   A = RC_Room
;              Flash Eprom Write Errors:
;                   If possible, the new File Entry is marked as deleted.
;                   A = RC_VPL, RC_BWR (see "flashepr.def" for details)
;
;              RAM File was not found, or other filename related problems:
;                   A = RC_Onf
;                   A = RC_Ivf
;                   A = RC_use
;
; Registers changed on return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
; -------------------------------------------------------------------------
; Design & Programming
;       Gunther Strube, Dec 1997-Apr 1998, Sep 2004, Aug 2006, Nov 2006, Mar 2007
; -------------------------------------------------------------------------
;
.FileEprSaveRamFile
        push    ix                              ; preserve IX
        push    de
        push    bc                              ; preserve CDE


.process_file
        push    iy                              ; preserve original IY
        exx                                     ; use alternate registers temporarily
        ld      hl,0
        add     hl,sp
        ld      iy, -SizeOfWorkSpace            ; create temporary work buffer on stack
        add     iy,sp
        ld      sp,iy
        push    hl                              ; preserve a copy of original SP on return
        exx

        and     @00000011
        ld      (iy + CardSlot),c               ; preserve slot number of File Eprom Card
        ld      (iy + IObuffer),e
        ld      (iy + IObuffer+1),d             ; preserve pointer to external IO buffer
        push    ix
        pop     bc
        ld      (iy + IObufSize),c
        ld      (iy + IObufSize+1),b            ; preserve size of external IO buffer

        push    hl                              ; preserve ptr. to filename...
        push    iy
        pop     hl
        ld      bc,Heap                         ; B = 0, C = size of heap
        add     hl,bc                           ; point at workspace for File Entry Header...
        ld      d,h
        ld      e,l                             ; DE points at space for File Entry
        ex      (sp),hl                         ; preserve pointer to File Entry
        ld      c, SizeOfWorkSpace-Heap-16      ; B=0 (local ptr), C = max. size of exp. filename
        ld      a, OP_IN                        ; HL = ptr. to filename...
        oz      GN_Opf                          ; open file for input...
        pop     hl                              ; ptr. to expanded filename
        jp      c, end_filesave                 ; Ups - system error, return back to caller...

        ld      de,5
        add     hl,de                           ; point at character before "/" (device skipped)
        push    hl                              ; (length byte) - This is start of File Entry Header...

        ld      a,c
        sub     7                               ; length of filename excl. device name...
        ld      (hl),a
        push    af                              ; preserve length of filename
        inc     a
        ld      e,a
        add     hl,de                           ; point at beyond last character of filename...

        ld      a, FA_EXT
        ld      de,0
        oz      OS_Frm                          ; get size of file image in DEBC (32bit integer)
        ld      (hl),c
        inc     hl
        ld      (hl),b
        inc     hl
        ld      (hl),e
        inc     hl
        ld      (hl),d                          ; File Entry now ready...

        pop     af                              ; length of filename (excl. device)
        add     a,4+1                           ; total size = length of filename + 1 + file length
        ld      h,0                             ;                                       (4 bytes)
        ld      l,a
        add     hl,bc
        ld      b,h
        ld      c,l
        ld      hl,0
        adc     hl,de
        push    hl
        push    bc

        ld      c,(iy + CardSlot)               ; scan File Eprom in slot X for free space
        call    FileEprFreeSpace                ; returned in DEBC (Fc = 0, Eprom available...)

        ld      h,b
        ld      l,c                             ; HL = low word of 32bit free space...
        pop     bc
        sbc     hl,bc
        ex      de,hl                           ; HL = high word of 32bit free space...
        pop     de                              ; DE = high word of file size
        sbc     hl,de
        jr      c, no_room                      ; file size (incl. File Entry Header) > free space...

        ld      c,(iy + CardSlot)
        call    OZSlotPoll                      ; is OZ running in slot C?
        call    nz,SetBlinkScreen               ; yes, saving file to file area in OZ ROM (slot 0 or 1) requires LCD turned off

        push    ix
        pop     bc
        ld      (iy + Fhandle),c
        ld      (iy + Fhandle+1),b              ; preserve file handle

        pop     hl                              ; ptr. to File Entry
        call    SaveToFlashEpr                  ; Now, blow file to Flash Eprom...

        call    SetBlinkScreenOn                ; always turn on screen after save file operation

        push    af                              ; preserve error status...
        ld      c,(iy + Fhandle)
        ld      b,(iy + Fhandle+1)
        push    bc
        pop     ix                              ; get file handle of open file
        oz      Gn_Cl                           ; close file
        pop     af

        ld      l,(iy + FileEntry)
        ld      h,(iy + FileEntry+1)
        ld      b,(iy + FileEntry+2)            ; return pointer to new File Entry...
.end_filesave
        exx
        pop     hl
        ld      sp,hl                           ; install original SP
        exx
        pop     iy                              ; original IY restored

        pop     de
        ld      c,e                             ; original C restored
        pop     de
        pop     ix
        ret

.no_room
        pop     hl                              ; remove redundant pointer to File Entry in buffer...
        oz      Gn_Cl                           ; close file (not going to be saved...)
        ld      a, RC_Room
        scf                                     ; indicate "No Room in Flash Eprom"...
        jr      end_filesave


; **************************************************************************
;
; IN:
;    HL = pointer to File Entry
;
.SaveToFlashEpr
        push    hl
        ld      c,(iy + CardSlot)
        call    FileEprNewFileEntry             ; BHL = ptr. to free file space on File Eprom Card
        ld      (iy + FileEntry),l
        ld      (iy + FileEntry+1),h
        ld      (iy + FileEntry+2),b            ; preserve pointer to new File Entry
        pop     de
        call    SaveFileEntry
        ret     c                               ; saving of File Entry failed...
.save_file_loop                                          ; A = chip type to blow data
        call    LoadBuffer                      ; Load block of bytes from file into external buffer
        ret     z                               ; EOF reached...

        call    FlashEprWriteBlock              ; blow buffer to Flash Eprom at BHL...
        jr      c,MarkDeleted                   ; exit saving, File was not blown properly (try to mark it as deleted)...
        jr      save_file_loop


; **************************************************************************
;
; Save File Entry to Flash File Eprom at BHL
;
; IN:
;    DE = (local) pointer to File Entry
;    BHL = pointer to free space on File Eprom
;
; OUT:
;    Fc = 0, File Entry successfully saved to File Eprom
;         A = FE_xx chip type
;         BHL = pointer beyond last byte of file entry
;    Fc = 1, save failed...
;         BHL = pointer to File Entry marked as deleted.
;         A = RC_xxx error code
;
; Registers changed on return:
;    ....DE../IXIY same
;    AFBC..HL/.... different
;
.SaveFileEntry
        push    bc
        ld      a,(de)                          ; length of filename
        add     a,4+1                           ; total size = length of filename + 1 (file length byte)
        ld      b,0                             ;              + 4 (32bit file length)
        ld      c,a
        push    bc                              ; DE = ptr. to File Entry
        pop     ix                              ; length of File Entry in IY
        pop     bc                              ; BHL = pointer to free space on Eprom
        ld      c, 0                            ; flash chip type to be detected dynamically...
        res     7,h
        set     6,h                             ; use segment 1 to blow bytes...
        call    FlashEprWriteBlock              ; blow File Entry to Flash Eprom
        ret     nc                              ; Fc = 0, A = FE_xx chip type

        ; File Entry was not blown properly, mark it as 'deleted'...


; **************************************************************************
;
; Mark File Entry as deleted, if possible
;
; IN:
;    None.
;
; OUT:
;    BHL = pointer to File Entry
;
; Registers changed on return:
;    AF.CDE../IXIY same
;    ..B...HL/.... different
;
.MarkDeleted
        push    af
        ld      l,(iy + FileEntry)
        ld      h,(iy + FileEntry+1)
        ld      b,(iy + FileEntry+2)            ; return pointer to new File Entry...
        call    FileEprDeleteFile               ; mark entry as deleted
        pop     af
        ret


; *****************************************************************************
;
; Load a chunk from the file into buffer of <BufferSize> bytes
;
; IN:
;    None.
;
; OUT:
;    Fz = 1, if EOF was reached...
;
;    Fz = 0, buffer loaded with file contents...
;         IX = actual size of buffer to save, less than or equal to <IObufsize>.
;         DE = pointer to start of external buffer
;
; Register changed after return:
;    A.BC..HL/..IY same
;    .F..DE../IX.. different
;
.LoadBuffer
        push    bc
        push    af
        push    hl

        ld      c,(iy + Fhandle)
        ld      b,(iy + Fhandle+1)
        push    bc
        pop     ix                              ; get file handle of open file
        ld      a,FA_EOF
        ld      de,0
        oz      Os_Frm
        jr      z, exit_loadbuffer              ; EOF!

        ld      c,(iy + IObufsize)
        ld      b,(iy + IObufsize+1)            ; Buffer Size
        push    bc
        ld      e,(iy + IObuffer)
        ld      d,(iy + IObuffer+1)             ; Pointer to Buffer Start
        push    de
        ld      hl,0
        oz      Os_Mv                           ; load max. BC bytes of file into buffer
        pop     de
        cp      a                               ; Fc = 0
        pop     hl
        sbc     hl,bc                           ; BC = possible bytes read past EOF (or none)
        push    hl                              ; Fz = 1, indicates EOF!
        pop     ix                              ; actual size of buffer
.exit_loadbuffer
        pop     hl
        pop     bc
        ld      a,b                             ; restore original A
        pop     bc
        ret
