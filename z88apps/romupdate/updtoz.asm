; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2006
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     MODULE UpdateOZrom

     ; OZ system defintions
     include "error.def"
     include "memory.def"
     include "fileio.def"
     include "sysvar.def"

     ; RomUpdate runtime variables
     include "romupdate.def"

     xdef Update_OzRom
     xref suicide, FlashWriteSupport


; *************************************************************************************
; Update OZ ROM to slot 0
;
.Update_OzRom
                    ld   c,0                            ; make sure that we have an AMD/STM 512K flash chip in slot 0
                    call FlashWriteSupport

                    ld   iy,ozbanks                     ; get ready for first oz bank entry of [total_ozbanks]


                    jp   suicide                        ; OZ ROM issues a hard reset when done (for now we just exit RomUpdate back to INDEX)



; *************************************************************************************
; Convert [File Block Number, Bank] to extended memory pointer.
; Bank number = 0 evaluation (the last block in the file) is not handled.
;
; IN:
;    C = MS_Sx        segment specifier (C=0, no segment specifier)
;    D = Bank number  (of block)
;    E = Block number (64 byte file sector)
;
; OUT:
;    BHL = pointer to start of 64 byte sector (for specified segment)
;
; Registers changed after return:
;    A..CDE../IXIY same
;    .FB...HL/.... different
;
.Sector2MemPtr
        ld      b, d                            ; bank
        ld      h, e
        ld      l, c
        srl     h
        rr      l
        rr      h                               ; SSeeeeee
        rr      l                               ; ee000000
        ret
