; *************************************************************************************
; EazyLink - Fast Client/Server File Management, including support for PCLINK II protocol
; (C) Gunther Strube (gbs@users.sourceforge.net) 1990-2011
;
; EazyLink is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; EazyLink is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with EazyLink;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id: fileio.asm 2638 2006-09-19 21:53:26Z gbs $
;
; *************************************************************************************


; *************************************************************************************
; Standard Z88 File Eprom Format.
;
; Save file received through serial port to Flash Memory file area 
; in slot C
;
; The routine does NOT handle automatical "deletion" of existing files
; that matches the filename (excl. device). This must be used by a call
; to <FileEprDeleteFile>.
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
; IN:
;          C = slot number (0, 1, 2 or 3)
;         IX = size of I/O buffer.
;         DE = pointer to I/O buffer, in segment 0/1.
;         HL = pointer to filename string (null-terminated), in segment 0/1.
;
; OUT:
;         Fc = 0, File successfully saved to Flash Card.
;              BHL = pointer to created File Entry in slot C.
;
;         Fc = 1,
;              File (Flash) Eprom not available in slot C:
;                   A = RC_NFE (not a recognized Flash Memory Chip)
;              Not sufficient space to store file (and File Entry Header):
;                   A = RC_Room
;              Flash Eprom Write Errors:
;                   If possible, the new File Entry is marked as deleted.
;                   A = RC_VPL, RC_BWR (see "error.def" for details)
;              Serial port problem (timeout, etc)
;
; Registers changed on return:
;    ...CDE../IXIY same
;    AFB...HL/.... different
;
; -------------------------------------------------------------------------
; Design & Programming (based on code from FileEprSaveRamFile / OZ 4.2)
;       Gunther Strube, Mar-Apr 2011
; -------------------------------------------------------------------------
;

        module FileEprSaveFile

        lib SetBlinkScreen, SetBlinkScreenOn
        lib MemReadByte
        lib AddPointerDistance

        xdef FileEprSaveFile,SlotWriteSupport

        xref FetchBytes,Msg_protocol_error,Msg_File_aborted

        include "error.def"
        include "fileio.def"
        include "memory.def"
        include "director.def"
        include "oz.def"
        include "blink.def"
        include "stdio.def"
        include "eprom.def"
        include "flashepr.def"
        include "rtmvars.def"

        defc SizeOfWorkSpace = 256         ; size of Workspace on stack, IY points at base...

        ; Relative offset definitions for allocated work buffer on stack
        defvars 0
             IObuffer  ds.w 1              ; Pointer to I/O buffer
             IObufSize ds.w 1              ; Size of I/O buffer
             CardType  ds.b 1              ; card/chip type (FE_28F, Fe_29F or 0 for UV Eprom)
             FileEntry ds.p 1              ; pointer to File Entry
             FileSize  ds.b 3              ; accumulated file size of data strem from serial port
             CardSlot  ds.b 1              ; slot number of File Eprom Card
             Heap                          ; Internal Workspace
        enddef


.FileEprSaveFile
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

        ld      a,c
        and     @00000011
        ld      (iy + CardSlot),a               ; preserve slot number of File Eprom Card
        ld      (iy + IObuffer),e
        ld      (iy + IObuffer+1),d             ; preserve pointer to external IO buffer
        push    ix
        pop     bc
        ld      (iy + IObufSize),c
        ld      (iy + IObufSize+1),b            ; preserve size of external IO buffer
        xor     a
        ld      (iy + FileSize),a
        ld      (iy + FileSize+1),a
        ld      (iy + FileSize+2),a             ; File size = 0 (will grow as stream is incoming)

        push    hl                              ; preserve ptr. to filename...
        push    iy
        pop     hl
        ld      bc,Heap                         ; B = 0, C = size of heap
        add     hl,bc                           ; point at workspace for File Entry Header...
        ld      d,h
        ld      e,l                             ; DE points at space for File Entry
        ex      (sp),hl                         ; preserve pointer to File Entry
        ld      c, SizeOfWorkSpace-Heap-16      ; B=0 (local ptr), C = max. size of exp. filename

        inc     de                              ; first byte of File entry is length of file name, DE = ready for '/'
        xor     a                               ;
.cpy_flnm                                       ; copy filename into entry from argument pointer in HL
        cp      (hl)                            ; reached null-terminator of filename?
        jr      z, flnm_copied                  ; yes, successfully copied filename into entry
        ldi
        inc     b                               ; B = size of filename
        dec     c
        inc     c
        dec     c
        jr      z, flnm_copied                  ; max filename length reached...
        jr      cpy_flnm
.flnm_copied
        pop     hl
        push    hl                              ; (length byte) - This is start of File Entry Header...

        ld      a,b
        ld      (hl),b                          ; length of filename...

        ld      a,$ff                           ; length of file entry not yet known (file stream to be received)
        ld      (de),a                          ; DE points to 4-byte length of file image
        inc     de
        ld      (de),a
        inc     de
        ld      (de),a
        inc     de
        xor     a
        ld      (de),a                          ; last byte of file size always 0 (24 bit > 1Mb!)
        inc     de                              ; File Entry now ready...

        ld      c,(iy + CardSlot)               ; scan File Eprom in slot X for eprom card type
        ld      a,FEP_Cdid
        oz      OS_Fep
        jr      nc, flashtype
        pop     hl
        jr      end_filesave                    ; not a flash chip, abort with Fc = 1...
.flashtype
        ld      (IY + CardType),A               ; preserve card type of chip in slot C

        ld      a,c                             ; is OZ running in slot C?
        oz      OS_Ploz
        call    nz,SetBlinkScreen               ; yes, saving file to file area in OZ ROM (slot 0 or 1) requires LCD turned off

        pop     hl                              ; HL = ptr. to File Entry in stack variable area
        call    ReceiveFileEntry                ; Now, receive file from serial port and blow it to Flash file area...

        call    SetBlinkScreenOn                ; then always turn on screen after save file operation
        call    GetFileEntry                    ; BHL <- (IY + FileEntry)
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


; **************************************************************************
; Whenever a byte has been loaded into the buffer, update the total file size.
; When the File has been blown completely to the file area, the file size is 
; post-updated into the File Entry Header.
;
; IN:
;    None
; Out:
;    Updated 3-byte file size in (IY+FileSize)
;
.FileEntrySizeCounter
        ld      a,1
        add     a,(iy + FileSize)
        inc     (iy + FileSize)                 
        ret     nc                              ; FileSize++ didn't go to zero (Fc = 1)
        ld      a,1
        add     a,(iy + FileSize+1)
        inc     (iy + FileSize+1)
        ret     nc
        inc     (iy + FileSize+2)
        ret


; **************************************************************************
; Post-update the length of the file entry from IY + FileSize
; to File Entry.
;
; IN:
;    None
;
.BlowFileEntrySize
        push    af
        call    GetFileEntry                    ; get BHL pointer to start of File Entry in file area
        xor     a
        call    MemReadByte                     ; get length of file entry (file)name
        ld      c,0
        ld      d,c
        ld      e,a                             ; CDE = length of filename
        inc     de                              ; adjust length to point at first byte of file length block
        call    AddPointerDistance              ; BHL points at low byte of (4-byte) file image length 

        push    iy
        pop     ix                              ; length of File Entry in IX
        ld      de,FileSize
        add     ix,de
        push    ix 
        pop     de                              ; point at 24-bit file length "block", IY+FileSize 

        ld      c,(iy + CardType)               ; C = Flash card type
        ld      ix,3                            ; blow three bytes
        res     7,h
        set     6,h                             ; use segment 1 to blow bytes...
        ld      a,FEP_Wrbl
        oz      OS_fep                          ; blow File Entry file size from DE to Flash Eprom at BHL
        pop     af
        ret  


; **************************************************************************
; IN:
;     C = slot number to blow file entry
;    HL = pointer to File Entry
;
; OUT:
;   Fc = 1, serial port problems
;
.ReceiveFileEntry
        push    hl
        ld      a,EP_New
        oz      OS_Epr                          ; BHL = ptr. to free file space on File Eprom Card for new File Entry
        ld      (iy + FileEntry),l
        ld      (iy + FileEntry+1),h
        ld      (iy + FileEntry+2),b            ; preserve pointer to new File Entry
        pop     de
        ld      a,(de)                          ; length of filename
        add     a,4+1                           ; total size = length of filename + 1 (file length byte)
        ld      c,a                             ;                                 + 4 (32bit file length)

        ld      a,(iy + CardType)
        call    SaveFlashFileEntry              ; Blow File Entry Header of C length to Flash
        ret     c                               ; Ups, saving of File Entry header failed...

.save_flash_file_loop
        call    ReceiveBuffer                   ; Receive block of bytes from serial port into buffer, block size in IX
        push    af                              ; preserve error condition of the received block

        ld      c,(iy + CardType)               ; C = get card type of inserted Flash Card
        res     7,h
        set     6,h                             ; use segment 1 to blow bytes...
        ld      a,FEP_Wrbl
        oz      OS_fep                          ; blow File Entry file size from DE to Flash Eprom at BHL
        jr      nc, eval_bufstatus
        pop     hl                              ; remove previous buffer status - now irrelevant..
.ErrFileEntry
        call    MarkDeleted                     ; error blowing this block to file area, File not blown properly - try to mark as deleted..
        call    BlowFileEntrySize               ; also blow actual file size (even if incomplete!)
        ret                                     ; ABORT (Fc = 1)!
.eval_bufstatus
        pop     af                              ; block was succesfully blown to file area, check received buffer status
        jr      c,ErrFileEntry                  ; serial port error, mark File Entry deleted with incomplete file size.
        jr      nz,save_flash_file_loop         ; block done in File Area, more file data to come from serial port...
        call    BlowFileEntrySize               ; end of file or timeout - blow file size and leave file "active"
        ret


; **************************************************************************
; Save File Entry to File Area in Flash card at BHL
;
; IN:
;    C = length of file entry header
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
.SaveFlashFileEntry
        push    bc
        ld      b,0
        push    bc                              ; DE = ptr. to File Entry
        pop     ix                              ; length of File Entry in IX
        pop     bc                              ; BHL = pointer to free space on Eprom
        ld      c,(IY + CardType)               ; flash chip card type...
        res     7,h
        set     6,h                             ; use segment 1 to blow bytes...
        ld      a,FEP_Wrbl
        oz      OS_fep                          ; blow File Entry to Flash Eprom
        ret     nc                              ; Fc = 0, A = FE_xx chip type

        ; File Entry was not blown properly, mark it as 'deleted'...


; **************************************************************************
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
        call    GetFileEntry                    ; BHL <- (IY + FileEntry)
        ld      a,EP_Delete
        oz      OS_Epr                          ; mark entry as deleted
        pop     af
        ret


; *****************************************************************************
; Receive a chunk from the file through the serial port into buffer of <BufferSize> bytes
;
; IN:
;    None.
;
; OUT:
;    Fz = 1, if EOF or Serial port timeout was reached...
;    Fc = 1, Serial port related error was reached...
;
;    Fc = 0, Fz = 0, buffer loaded with file contents...
;         IX = actual size of buffer to save, less than or equal to <IObufsize>.
;         DE = pointer to start of buffer
;
; Register changed after return:
;    A.BC..HL/..IY same
;    .F..DE../IX.. different
;
.ReceiveBuffer
        push    bc
        push    af
        push    hl

        ld      e,(iy + IObufsize)
        ld      d,(iy + IObufsize+1)            ; Buffer Size
        ld      l,(iy + IObuffer)
        ld      h,(iy + IObuffer+1)             ; Pointer to Buffer Start
        ld      ix, 0                           ; total bytes stored in buffer

.receive_fentry_loop
        PUSH    IX                              ; preserve IX buffer counter
        CALL    FetchBytes                      ; get byte from serial port with IX = serial port handle for OZ..
        POP     IX
        JR      C,exit_receivebuffer
        JR      Z,exit_receivebuffer
        CP      $FF                             ; fetched an ESC id?
        LD      A,B
        JR      NZ, byte_to_fileentry           ; no, still receiving byte to file
        CP      'E'                             ; is it ESC 'E' ?
        JR      Z, exit_receivebuffer           ; Yes
        CALL    Msg_protocol_error
        CALL    Msg_File_aborted
        JR      exit_receivebuffer

; byte in A to file...
.byte_to_fileentry
        CP      LF                              ; is it a line feed?
        JR      NZ,no_linefeed
        LD      A,(CRLF_flag)                   ; check CRLF flag
        CP      $FF                             ; active?
        LD      A,LF
        JR      NZ,no_linefeed                  ; not active - write LF to file...
        JR      receive_fentry_loop              ; - ignore LF (reverse CRLF) and fetch next byte...
.no_linefeed
        CALL    Byte2Buffer                     ; put byte into buffer
        JR      Z,flush_receivebuffer           ; buffer full...
        JR      receive_fentry_loop             ; fetch next byte from serial port
.flush_receivebuffer
        ld      a,$ff
        or      a                               ; Fc = 0, Fz = 0, make sure NOT to indicate EOF or error!
.exit_receivebuffer
        ld      e,(iy + IObuffer)
        ld      d,(iy + IObuffer+1)             ; Always return pointer to Buffer Start

        pop     hl
        pop     bc
        ld      a,b                             ; restore original A
        pop     bc
        ret
.Byte2Buffer
        LD      (HL),A                        ; put byte into buffer
        INC     HL                            ; ready for next byte
        INC     IX                            ; current size of buffer updated with new byte
        CALL    FileEntrySizeCounter          ; update global file size, reflecting latest received byte
        CP      A
        PUSH    HL
        PUSH    IX
        POP     HL
        SBC     HL,DE                         ; is buffer full (total received bytes == buffer size)?
        POP     HL
        RET                                   ; return Fc = 0, Fz = 1, if buffer full


; *****************************************************************************
; BHL <- (IY + FileEntry)
;
.GetFileEntry
        ld      l,(iy + FileEntry)
        ld      h,(iy + FileEntry+1)
        ld      b,(iy + FileEntry+2)            ; get File Entry pointer
        ret


; ***************************************************************************************************
; Get slot number C (embedded in Bank number B).
;
; In:
;       B = absolute bank number
; Out:
;       C = slot number which bank B is part of
;
; Registers changed after return:
;    AFB.DEHL/IXIY same
;    ...C..../.... different
;
.GetSlotNo
        push    af
        ld      a,b
        and     @11000000
        rlca
        rlca
        ld      c,a                             ; slot C (of bank B)
        pop     af
        ret


; ***************************************************************************************************
;
; Validate the Flash Card/UV Eprom erase/write functionality in the specified slot.
; If the Card in the specified slot contains an Intel chip, the slot must be 3 for format,
; save and delete functionality.
; If the Card in the specified slot contains an UV Eprom, the slot must be 3 for erasing,
; saving files and creating file header.
; Report an error to the caller with Fc = 1, if an Intel Flash chip was recognized
; in all slots except 3.
; Report an error if to the caller with Fc = 1, if an UV Eprom (with a file area) was
; recognized in all slots except 3.
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
.SlotWriteSupport
                    push hl
                    push de
                    push bc
                    push af
                    ld   a,FEP_Cdid
                    oz   OS_Fep
                    jr   nc, flashcard_found
                    ld   a,EP_Req
                    oz   OS_Epr
                    jr   z, fa_epr_found
                    or   c                   ; Fz = 0, indicate no Flash Card available in slot
                    scf                      ; Fc = 1, indicate no erase/write support either...
                    jr   exit_chckflsupp
.fa_epr_found                                ; File area found on UV Eprom in slot C
                    pop  af
                    pop  bc
                    or   c                   ; Fz = 0, indicate UV Eprom
                    scf                      ; Fc = 1, no erase/write support
                    pop  de
                    pop  hl
                    ret
.flashcard_found
                    ld   a,c
                    cp   3
                    jr   z, end_chckflsupp   ; erase/write works for all flash cards in slot 3 (Fc=0, Fz=1)
                    ld   a,FE_INTEL_MFCD
                    cp   h
                    jr   z, err_chckflsupp   ; Intel flash chip found in slot 0,1 or 2.
                    cp   a                   ; No, we found an AMD/compatible Flash chip (Fc=0, Fz=1)
                    jr   end_chckflsupp
.err_chckflsupp
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
; ***************************************************************************************************
