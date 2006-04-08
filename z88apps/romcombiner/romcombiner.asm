; *************************************************************************************
; RomCombiner
; (c) Garry Lancaster, 2000-2005 (yahoogroups@zxplus3e.plus.com)
;
; RomCombiner is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomCombiner is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomCombiner;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

; RomCombiner M/C routines to read/write ROM pages

     module romcode

     org $ba00

     ; These libraries refer to V0.8 of stdlib:
     lib FlashEprCardID, FlashEprCardErase, FlashEprBlockErase, FlashEprWriteBlock

     include "flashepr.def"
     include "memory.def"

; The BLOWBANK routine blows page B (00-3f) to standard EPROM type C,
; with data stored at DE. On exit, HL=0 if successful, or address
; of failed byte (in segment 3)
; If C=0, blows a page of a Flash EPROM

.blowbank
     xor  a
     cp   c              ; is it a FLASH eprom?
     jr   z,blowflash    ; move on if so
     ld   hl,$c000
     ld   a,($4D3)
     push af
     ld   a,b
     or   $c0            ; mask for slot 3
     ld   ($4D3),a
     out  ($D3),a
.nextbyte
     ld   b,75
     ld   a,c
     out  ($B3),a
.proloop
     ld   a,$0E
     out  ($B0),a
     ld   a,(de)
     ld   (hl),a
     ld   a,$04
     out  ($B0),a
     ld   a,(de)
     cp   (hl)
     jr   z,byteok
     djnz proloop
     jr   exit
.byteok
     ld   a,76
     sub  b
     ld   b,a
.ovploop
     out  ($B0),a
     ld   a,(de)
     ld   (hl),a
     ld   a,$04
     out  ($B0),a
     djnz ovploop
     inc  de
     inc  hl
     ld   a,h
     or   l
     jr   nz,nextbyte
.exit
     ld   a,$05
     out  ($B0),a
.exit2
     pop  af
     ld   ($4D3),a
     out  ($D3),a
     ret

.blowflash
     push bc
     ld   c,3            ; use slot 3 as default for all Flash Cards
     call FlashEprCardID
     pop  bc
     ld   hl,$c000
     ret  c              ; exit if not Flash card
     set  7,b            ; A = Flash Card type (returned from FlashEprCardID)
     set  6,b            ; bank no. in B points into slot 3
     ld   c,ms_s3        ; use segment 3 to blow in
     ld   hl,0           ; destination start address of bank
     ld   iy,$4000       ; whole page
     call FlashEprWriteBlock
     ret  nc             ; exit if no error
     ld   de,$c000
     add  hl,de          ; else give address in seg 3
     ret

; Subroutine to check blocks of an EPROM are properly erased
; On entry, B=bank to check (00-3f)
; On exit, HL=0 if no error, or $ffff if error

.checkbank
     ld   a,($4D3)
     push af
     ld   a,b
     or   $c0            ; mask for slot 3
     ld   ($4D3),a
     out  ($D3),a
     ld   hl,$c000
     ld   a,$ff
     ld   c,64           ; 64 x 256 bytes=16K
.cknextpage
     ld   b,0
.cknextbyte
     and  (hl)
     inc  hl
     djnz cknextbyte
     dec  c
     jr   nz,cknextpage
     inc  a
     jr   z,exit2        ; exit with HL=0 if all bytes $ff
     dec  hl             ; else flag error with HL=$ffff
     jr   exit2

; The READBANK routine reads page B to address DE

.readbank
     ld   a,($4D3)
     push af
     ld   a,b
     ld   ($4D3),a
     out  ($D3),a
     ld   hl,$C000
     ld   bc,$4000
     ldir
     jr   exit2

; Subroutine to erase blocks of a Flash EPROM
; On entry, E=block to erase ($ff=all)
; On exit, HL=0 if no error, or $ffff if error

.eraseflash
     ld   c,3
     call FlashEprCardID ; check for Flash EPROM in slot 3
     ld   hl,$ffff
     jr   c,eraseerr     ; exit if not Flash device
     ld   a,e
     cp   $ff
     jr   z,eraseall     ; erase whole card

     ld   b,e            ; erase block in slot 3
     call FlashEprBlockErase
     jr   checkerror
.eraseall                ; erase complete card in slot 3
     call FlashEprCardErase
.checkerror
     jr   c,eraseerr
     ld   hl,0
     ret
.eraseerr
     ld   hl,$ffff
     ret