     XLIB FlashEprFileSave

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with FlashStore;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     LIB FlashEprCardId
     LIB FileEprAllocFilePtr
     LIB FileEprFreeSpace
     LIB FlashEprFileDelete
     LIB FlashEprWriteBlock
     LIB CheckBattLow

     include "error.def"
     include "fileio.def"
     include "memory.def"
     include "flashepr.def"


     DEFC SizeOfWorkSpace = 256         ; size of Workspace on stack, IY points at base...

     ; Relative offset definitions for allocated work buffer on stack
     ;
     DEFVARS 0
     {
          IObuffer  ds.w 1              ; Pointer to I/O buffer
          IObufSize ds.w 1              ; Size of I/O buffer
          Fhandle   ds.w 1              ; Handle of openend file
          FileEntry ds.p 1              ; pointer to File Entry
          Heap                          ; Internal Workspace
     }


; **************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Save single file to Flash Eprom (in slot 3).
;
; The routine does NOT handle automatical "deletion" of existing files
; that matches the filename (excl. device). This must be used by a call
; to <FlashEprFileDelete>.
;
; Should the actual process of blowing the file image fail, the new 
; File Entry will be marked as deleted (if possible).
;
; This routine will temporarily set the Vpp pin while blowing the file
; to the Flash Eprom.
;
; IN:
;         DE = pointer to I/O buffer, in segment 0.
;         BC = size of I/O buffer.
;
;         HL = pointer to filename string (null-terminated), in segment 0.
;              Filename may contain wildcards (to find first match)
;
; OUT:
;         Fc = 0, File successfully saved to Flash File Eprom.
;              BHL = pointer to created File Entry in slot 3.
;
;         Fc = 1,
;              File (Flash) Eprom not available in slot 3:
;                   A = RC_Onf (Object not found)
;              Not sufficient space to store file (and File Entry Header):
;                   A = RC_Room
;              Flash Eprom Write Errors:
;                   If possible, the new File Entry is marked as deleted.
;                   A = RC_VPL, RC_BWR (see "flashepr.def" for details)
;                   A = RC_Wp (Write-protected - batteries are low...)
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
; Design & Programming, Gunther Strube, InterLogic, Dec 1997 - Apr 1998
; -------------------------------------------------------------------------
;
.FlashEprFileSave
                    PUSH IX                       ; preserve IX
                    PUSH DE
                    PUSH BC                       ; preserve CDE

                    PUSH BC
                    LD   C,3                      ; check presence of FE in slot 3
                    CALL FlashEprCardId
                    POP  BC
                    JR   NC, process_file         ; Flash File Eprom was found...

                    LD   A, RC_Onf
                    SCF
.exit_completed     POP  DE
                    LD   C,E                      ; original C restored
                    POP  DE
                    POP  IX
                    RET                           ; Flash File Eprom was not found in slot 3

.process_file       PUSH IY                       ; preserve original IY
                    EXX                           ; use alternate registers temporarily
                    LD   HL,0
                    ADD  HL,SP
                    LD   IY, -SizeOfWorkSpace     ; create temporary work buffer on stack
                    ADD  IY,SP
                    LD   SP,IY
                    PUSH HL                       ; preserve a copy of original SP on return
                    EXX

                    LD   (IY + IObuffer),E
                    LD   (IY + IObuffer+1),D      ; preserve pointer to external IO buffer
                    LD   (IY + IObufSize),C
                    LD   (IY + IObufSize+1),B     ; preserve size of external IO buffer

                    CALL CheckBatteryStatus
                    JR   C, end_filesave          ; abort operation if batteries are low

                    PUSH HL                       ; preserve ptr. to filename...
                    PUSH IY
                    POP  HL
                    LD   BC,Heap                  ; B = 0, C = size of heap
                    ADD  HL,BC                    ; point at workspace for File Entry Header...
                    LD   D,H
                    LD   E,L                      ; DE points at space for File Entry
                    EX   (SP),HL                  ; preserve pointer to File Entry
                    LD   C, SizeOfWorkSpace-Heap-16 ; B=0 (local ptr), C = max. size of exp. filename
                    LD   A, OP_IN                 ; HL = ptr. to filename...
                    CALL_OZ(GN_Opf)               ; open file for input...
                    POP  HL                       ; ptr. to expanded filename
                    JP   C, end_filesave          ; Ups - system error, return back to caller...

                    LD   DE,5
                    ADD  HL,DE                    ; point at character before "/" (device skipped)
                    PUSH HL                       ; (length byte) - This is start of File Entry Header...

                    LD   A,C
                    SUB  7                        ; length of filename excl. device name...
                    LD   (HL),A
                    PUSH AF                       ; preserve length of filename
                    INC  A
                    LD   E,A
                    ADD  HL,DE                    ; point at beyond last character of filename...

                    LD   A, FA_EXT
                    LD   DE,0
                    CALL_OZ(OS_Frm)               ; get size of file image in DEBC (32bit integer)
                    LD   (HL),C
                    INC  HL
                    LD   (HL),B
                    INC  HL
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D                   ; File Entry now ready...

                    POP  AF                       ; length of filename (excl. device)
                    ADD  A,4+1                    ; total size = length of filename + 1 + file length
                    LD   H,0                      ;                                       (4 bytes)
                    LD   L,A
                    ADD  HL,BC
                    LD   B,H
                    LD   C,L
                    LD   HL,0
                    ADC  HL,DE
                    PUSH HL
                    PUSH BC

                    LD   C,3                      ; scan File Eprom in slot 3 for free space
                    CALL FileEprFreeSpace         ; returned in DEBC (Fc = 0, Eprom available...)

                    LD   H,B
                    LD   L,C                      ; HL = low word of 32bit free space...
                    POP  BC
                    SBC  HL,BC
                    EX   DE,HL                    ; HL = high word of 32bit free space...
                    POP  DE
                    SBC  HL,DE
                    JR   C, no_room               ; file size (incl. File Entry Header) > free space...

                    PUSH IX
                    POP  BC
                    LD   (IY + Fhandle),C
                    LD   (IY + Fhandle+1),B       ; preserve file handle

                    POP  HL                       ; ptr. to File Entry
                    CALL SaveToFlashEpr           ; Now, blow file to Flash Eprom...

                    PUSH AF                       ; preserve error status...
                    LD   C,(IY + Fhandle)
                    LD   B,(IY + Fhandle+1)
                    PUSH BC
                    POP  IX                       ; get file handle of open file
                    CALL_OZ(Gn_Cl)                ; close file
                    POP  AF

                    LD   L,(IY + FileEntry)
                    LD   H,(IY + FileEntry+1)
                    LD   B,(IY + FileEntry+2)     ; return pointer to new File Entry...

.end_filesave       EXX
                    POP  HL
                    LD   SP,HL                    ; install original SP
                    EXX
                    POP  IY                       ; original IY restored
                    JP   exit_completed           ; return to caller...

.no_room            POP  HL                       ; remove redundant pointer to File Entry in buffer...
                    CALL_OZ(Gn_Cl)                ; close file (not going to be saved...)
                    LD   A, RC_Room
                    SCF                           ; indicate "No Room in Flash Eprom"...
                    JR   end_filesave


; **************************************************************************
;
; IN:
;    HL = pointer to File Entry
;
.SaveToFlashEpr     
                    PUSH HL
                    LD   C,3
                    CALL FileEprAllocFilePtr      ; BHL = ptr. to free file space on File Eprom
                    LD   (IY + FileEntry),L
                    LD   (IY + FileEntry+1),H
                    LD   (IY + FileEntry+2),B     ; preserve pointer to new File Entry

                    POP  DE
                    CALL SaveFileEntry
                    JR   C, exit_save             ; saving of File Entry failed...
.save_file_loop
                    CALL LoadBuffer               ; Load block of bytes from file into external buffer
                    JR   Z, exit_save             ; EOF reached...

                    LD   C, MS_S1                 ; use segment 1 to blow bytes...
                    CALL FlashEprWriteBlock       ; blow buffer to Flash Eprom at BHL...
                    JR   NC, save_file_loop

                    CALL C,MarkDeleted            ; File was not blown properly...
.exit_save          
                    RET


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
;         BHL = pointer beyond last byte of file entry
;    Fc = 1, save failed...
;         BHL = pointer to File Entry marked as deleted.
;         A = RC_xxx error code
;
; Registers changed on return:
;    ....DE../..IY same
;    AFBC..HL/IX.. different
;
.SaveFileEntry      PUSH BC
                    LD   A,(DE)                   ; length of filename
                    ADD  A,4+1                    ; total size = length of filename + 1 (file length byte)
                    LD   B,0                      ;              + 4 (32bit file length)
                    LD   C,A
                    PUSH BC                       ; DE = ptr. to File Entry
                    POP  IX                       ; length of File Entry in IX
                    POP  BC                       ; BHL = pointer to free space on Eprom
                    LD   C, MS_S1                 ; use segment 1 to blow bytes...
                    CALL FlashEprWriteBlock       ; blow File Entry to Flash Eprom
                    RET  NC
                    CALL C,MarkDeleted            ; File Entry was not blown properly
                    RET


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
                    PUSH AF
                    LD   L,(IY + FileEntry)
                    LD   H,(IY + FileEntry+1)
                    LD   B,(IY + FileEntry+2)     ; return pointer to new File Entry...
                    CALL FlashEprFileDelete       ; mark entry as deleted
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
;         A = RC_Wp
;    Fc = 0, Battery Power is operational for Flash Eprom action
;
.CheckBatteryStatus CALL CheckBattLow
                    RET  NC
                    LD   A, RC_Wp                 ; indicate that Flash Eprom is write
                    SCF                           ; protected when batteries are low
                    RET


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
;    ..BC..HL/..IY same
;    AF..DE../IX.. different
;
.LoadBuffer
                    PUSH BC
                    PUSH HL

                    LD   C,(IY + Fhandle)
                    LD   B,(IY + Fhandle+1)
                    PUSH BC
                    POP  IX                       ; get file handle of open file
                    LD   A,FA_EOF
                    LD   DE,0
                    CALL_OZ (Os_Frm)
                    JR   Z, exit_loadbuffer       ; EOF!

                    LD   C,(IY + IObufsize)
                    LD   B,(IY + IObufsize+1)     ; Buffer Size
                    PUSH BC
                    LD   E,(IY + IObuffer)
                    LD   D,(IY + IObuffer+1)      ; Pointer to Buffer Start
                    PUSH DE
                    LD   HL,0
                    CALL_OZ (Os_Mv)               ; load max. 1K of file into buffer
                    POP  DE
                    CP   A
                    POP  HL
                    SBC  HL,BC                    ; BC = possible bytes read past EOF (or none)
                    PUSH HL                       ; Fz = 1, indicates EOF!
                    POP  IX                       ; actual size of buffer
.exit_loadbuffer
                    POP  HL
                    POP  BC
                    RET
