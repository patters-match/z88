     XLIB FlashEprStdFileHeader

; **************************************************************************************************
; This file is part of the Z88 Standard Library.
;
; The Z88 Standard Library is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; The Z88 Standard Library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the
; Z88 Standard Library; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
; $Id$  
;
;***************************************************************************************************

     LIB FlashEprCardId, FlashEprWriteBlock

     INCLUDE "saverst.def"
     INCLUDE "memory.def"


; ************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Blow File Eprom "oz" header on Flash Eprom, in specified bank (which 
; is part of the slot that the Flash Memory Card have been inserted into).
;
; Traditional File Eprom's use the whole card with header in top bank $3F.
;
; Pseudo File Eproms might be part of Application cards below the 
; reserved application area (as specified by the ROM Front DOR).
;
; Important: 
; Third generation AMD Flash Memory chips may be programmed in all 
; available slots (1-3). Only INTEL I28Fxxxx series Flash chips require 
; the 12V VPP pin in slot 3 to successfully blow the File Eprom header on 
; the memory chip. If the Flash Eprom card is inserted in slot 1 or 2, 
; this routine will report a programming failure. 
;
; It is the responsibility of the application (before using this call) to 
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the 
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; In:
;    B = Absolute Bank (00h - FFh) where to blow header (at offset $3FC0)
;        (bits 7,6 indicate slot number)
;
; Out:
;    Success:
;         Fc = 0, File Eprom Header successfully blown to Flash Eprom
;
;    Failure:
;         Fc = 1
;         A = RC_BWR (couldn't write header to Flash Memory)
;         A = RC_NFE (not a recognized Flash Memory Chip)
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
; ------------------------------------------------------------------------
; Design & programming by
;    Gunther Strube, InterLogic, Dec 1997 - Aug 1998
;    Thierry Peycru, Zlab, Dec 1997
; ------------------------------------------------------------------------
;
.FlashEprStdFileHeader

                    PUSH BC
                    PUSH AF
                    PUSH DE
                    PUSH HL
                    PUSH IX

                    LD   HL,0
                    ADD  HL,SP
                    LD   IX,-66
                    ADD  IX,SP                    ; IX points at start of buffer
                    LD   SP,IX                    ; 64 byte buffer created...
                    PUSH HL                       ; preserve original SP

                    PUSH BC                       ; preserve bank number for header

                    PUSH IX
                    POP  HL
                    LD   B,$37                    ; 55 bytes of $00 from $3FC0
                    XOR  A
.wri0_loop          LD   (HL),A
                    INC  HL
                    DJNZ wri0_loop

                    LD   (HL),1
                    INC  HL

                    PUSH HL
                    LD   A,sr_rnd
                    CALL_OZ OS_SR
                    POP  HL
                    LD   (HL),E
                    INC  HL
                    LD   (HL),D                   ; low word random ID...
                    INC  HL

                    LD   BC,6
                    EX   DE,HL
                    LD   HL, stdromhdr
                    LDIR
                    POP  BC                       ; blow header at bank B
                    
                    PUSH BC
                    RES  7,B
                    RES  6,B
                    INC  B
                    LD   (IX + $3C),B             ; total of banks on File Eprom = Bank+1
                    POP  BC 

                    PUSH IX
                    POP  DE                       ; start of File Eprom Header
                    LD   C, MS_S1                 ; use segment 1 to blow bytes
                    LD   HL, $3FC0                ; blown at address B,$3FC0
                    LD   IY, 64                   ; of size

                    CALL FlashEprWriteBlock       ; blow header...

                    POP  HL
                    LD   SP,HL                    ; restore original Stack Pointer

                    POP  IX                       ; restore registers...
                    POP  HL
                    POP  DE
                    POP  BC
                    LD   A,B                      ; A restored
                    POP  BC
                    RET

.stdromhdr          DEFB $01, $80, $40, $7C, $6F, $7A
