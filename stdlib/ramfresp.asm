     XLIB RamDevFreeSpace

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

     LIB SafeSegmentMask, MemDefBank

     include "memory.def"
     include "error.def"

; ********************************************************************
;
; This library routine returns the available space of a RAM device.
;
; IN:
;    A = slot number (0 for internal)
;
; OUT:
;    Fc = 0, it is a RAM device
;         A = total number of banks in Ram Card ($40 for 1MB)
;         DE = free pages (1 page = 256 bytes)
;
;    Fc = 1, it is not a RAM device
;         A = RC_ONF (Object not found)
;
;    Registers changed after return:
;         ..BC..HL/IXIY same
;         AF..DE../...  different
;
; ---------------------------------------------------------------
; Design & programming by Thierry Peycru, Zlab, May 1998
; ---------------------------------------------------------------
;
.RamDevFreeSpace
                    push bc
                    push hl
                    rrca                     ;first, get the first device bank
                    rrca
                    and  @11000000
                    jr   nz,not_internal
                    ld   a,$21               ;header of internal slot is in $21
.not_internal
                    ld   b,a                 ;first slot bank
                    call SafeSegmentMask
                    ld   h,a                 ;start of bank in hl
                    ld   l,0
                    rlca
                    rlca
                    ld   c,a                 ;segment
                    call MemDefBank
                    push bc                  ;preserve original bank binding status

                    ld   e,(hl)              ; should be $5A
                    inc  hl
                    ld   d,(hl)              ; should be $A5
                    inc  hl
                    ex   de,hl
                    ld   bc,$A55A            ;RAM device header
                    cp   a
                    sbc  hl,bc
                    jr   nz,not_ram_device
                    ex   de,hl

                    ld   a,(hl)              ;number of banks in RAM Card
                    inc  a                   ;even if internal (-1 for the system bank $20)
                    and  @01111110           ;from 2 (32K) to 64 (1024K)
                    ld   b,a                 ;actual number of banks
                    push bc                  ;save it for exit

                    xor  a                   
                    inc  h                   ;data start at $0100
                    ld   l,a            
                    ld   d,a                 ;free pages in DE
                    ld   e,a

                    ld   c,b                 ;parse table of B(anks) * 64 pages
.device_scan_loop                            
                    ld   b,64                ;total of pages in a bank...
.bank_scan_loop
                    ld   a,(hl)
                    inc  hl
                    or   (hl)                ;must be 00 if free
                    inc  hl
                    jr   nz,page_used
                    inc  de
.page_used
                    djnz bank_scan_loop
                    dec  c
                    jr   nz, device_scan_loop

                    pop  af                  ;return number of banks in RAM Card
                    cp   a                   ;signal success (Fc = 0)
.exit_RamDevFreeSpace
                    pop  bc                  ;restore original bank binding
                    call MemDefBank

                    pop  hl
                    pop  bc
                    ret
.not_ram_device
                    ld   a,RC_ONF            ;RAM device not found
                    scf                      ;signal failure...
                    jr   exit_RamDevFreeSpace
