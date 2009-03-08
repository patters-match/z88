; *************************************************************************************
; 32bit Cyclic Redundancy Checksum Management
; CRC algorithm from UnZip, by Garry Lancaster, Copyright 1999, released as GPL.
;
; CRC is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; CRC is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with CRC;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************


     module crc

     include "fileio.def"

     xdef CrcFile, CrcBuffer
     xref crctable


; *************************************************************************************
;
; Perform a CRC-32 of file, already opened by caller, from current file pointer until EOF.
; If the complete file is to be CRC'ed then it is vital that the current file pointer
; is at the beginning of the file (use FA_PTR / OS_FWM to reset file pointer) before
; executing this routine.
;
; In:
;    IX = handle of opened file
;    DE = pointer to CRC buffer
;    BC = size of CRC buffer
;
; Out:
;    Fc = 0,
;    DEHL = CRC
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.CrcFile            call initCrc             ; initialise CRC register D'E'B'C' to FFFFFFFF
.scanfile           push bc
                    push de
                    push bc
                    ld   hl,0
                    call oz_os_mv            ; read bytes from file (and preserve alternate bc, de)
                    pop  hl
                    cp   a
                    sbc  hl,bc
                    jr   z,crcend            ; move on if no bytes read
                    ld   b,h
                    ld   c,l                 ; BC=#bytes actually read
                    pop  hl
                    push hl
                    call CrcIterateBuffer    ; accumulate CRC on current value in D'E'B'C'
                    pop  de
                    pop  bc
                    jr   scanfile
.crcend
                    pop  af
                    pop  af
                    call CrcResult           ; get current CRC in D'E'B'C' and complement in
                    cp   a                   ; return in DEHL as CRC result
                    ret                      ; Fc = 0
.oz_os_mv
                    exx
                    push bc
                    push de
                    exx
                    call_oz(os_mv)
                    exx
                    pop  de
                    pop  bc
                    exx
                    ret
; *************************************************************************************


; *************************************************************************************
; the BBC BASIC boot loader performs a CRC32 check from .CrcCheckRomUpdate to .end_CrcBuffer
; the address range is $2A2F TO $2A7C

; *************************************************************************************
; CRC check of complete BBC BASIC RomUpdate program.
; Register parameters are supplied by USR routine from BBC BASIC
;
; IN:
;    BC = size of code to CRC check
;    HL = start of code to CRC check
;
; OUT:
;    HL H'L' = CRC of RomUpdate code (HL is most significant word)
;
.CrcCheckRomUpdate
                    call CrcBuffer
                    ex   de,hl
                    push de
                    exx
                    pop  hl
                    exx                      ; return CRC value in HL H'L'
                    ret                      ; (which is assigned to int variable in BBC BASIC from USR() function)
; *************************************************************************************


; *************************************************************************************
;
; Perform complete CRC of specified buffer contents.
; CRC value is initialized to FFFFFFFF before buffer scan and result is complemented
; and returned in DEHL.
;
; In:
;    HL= pointer to CRC buffer
;    BC = size of CRC buffer
;
; Out:
;    DEHL = CRC
;
; Registers changed after return:
;    ......../IXIY same
;    AFBCDEHL/.... different
;
.CrcBuffer
                    call initCrc
                    call CrcIterateBuffer
                    call CrcResult
                    ret
.initCrc
                    exx
                    ld   de,$FFFF            ; initialise CRC register D'E'B'C'
                    ld   bc,$FFFF
                    exx
                    ret
.CrcIterateBuffer
                    ld   a,(hl)              ; get byte
                    inc  hl                  ; increment address
                    dec  bc                  ; decrement bytes left
                    exx
                    xor  c
                    ld   l,a
                    xor  a
                    sla  l
                    rla
                    sla  l
                    rla                      ; AL=4xCRC index byte
                    add  a,crctable/256
                    ld   h,a                 ; HL=index into CRC table
                    ld   a,(hl)
                    inc  hl
                    xor  b
                    ld   c,a                 ; shift and XOR 2nd byte to low
                    ld   a,(hl)
                    inc  hl
                    xor  e
                    ld   b,a                 ; shift and XOR 3rd byte to 2nd
                    ld   a,(hl)
                    inc  hl
                    xor  d
                    ld   e,a                 ; shift and XOR high byte to 3rd
                    ld   d,(hl)              ; get new high byte
                    exx
                    ld   a,b
                    or   c
                    jr   nz,CrcIterateBuffer ; back for more
                    ret
.CrcResult
                    exx
                    ld   a,d
                    cpl
                    ld   d,a                 ; complement high byte
                    ld   a,e
                    cpl
                    ld   e,a                 ; complement 3rd byte
                    ld   a,b
                    cpl
                    ld   h,a                 ; complement 2nd byte
                    ld   a,c
                    cpl
                    ld   l,a                 ; complement low byte
                    ret                      ; exit with DEHL=CRC

.end_CrcBuffer

; the BBC BASIC boot loader performs a CRC32 check from .CrcCheckRomUpdate to .end_CrcBuffer
; the address range is $2A2F TO $2A7C
