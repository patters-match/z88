     XLIB FlashEprFileFormat

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

     LIB FlashEprCardId, FlashEprBlockErase, FlashEprStdFileHeader, FileEprRequest
     
     include "flashepr.def"

; ************************************************************************
;
; Flash Eprom File Area Formatting.
;
; Create/reformat an "oz" File Area below application Rom Area, or
; on empty Flash Eprom to create a normal "oz" File Eprom. 
;
; Defining 8 banks in the ROM Front DOR for applications will leave 58
; banks for file storage. This scheme is however always performed with
; only formatting the Flash Eprom in free modulus 64K blocks, ie.
; having defined 5 banks for ROM would "waste" three banks for 
; applications.
;
; Hence, ROM Front DOR definitions should always define bank reserved 
; for applications in modulus 64K, eg. 4 banks, 8, 12, etc...
;
; Important: 
; Third generation AMD Flash Memory chips may be erased/programmed in all 
; available slots (1-3). Only INTEL I28Fxxxx series Flash chips require 
; the 12V VPP pin in slot 3 to successfully erase or blow data on the
; memory chip. If the Flash Eprom card is inserted in slot 1 or 2, 
; this routine will report a programming failure. 
;
; It is the responsibility of the application (before using this call) to 
; evaluate the Flash Memory (using the FlashEprCardId routine) and warn the 
; user that an INTEL Flash Memory Card requires the Z88 slot 3 hardware, so
; this type of unnecessary error can be avoided.
;
; IN:
;    C = slot number (1, 2 or 3) of Flash Memory Card
;
; OUT:
;    Success:
;         Fc = 0, 
;         BHL = absolute pointer to "oz" header in card
;         C = Number of 16K banks of File Eprom Area
;
;         All sectors erased and a new header blown.
;
;    Failure:
;         Fc = 1
;             A = RC_ONF (File Eprom Card / Area not available; possibly no card in slot)
;             A = RC_ROOM (No room for File Area; all banks used for applications)
;             A = RC_NFE (not a recognized Flash Memory Chip)
;             A = RC_BER (error occurred when erasing block/sector)
;             A = RC_BWR (couldn't write header to Flash Memory)
;             A = RC_VPL (Vpp Low Error)
;
; Registers changed after return:
;    ....DE../IXIY same
;    AFBC..HL/.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Apr 1998, Aug 2004
; ----------------------------------------------------------------------
;
.FlashEprFileFormat
                    PUSH DE
                    PUSH BC
                    PUSH HL

                    CALL FileEprRequest           ; get pointer to File Eprom Header (or potential) in slot C
                    JR   C,format_error           ; No File Eprom available...

                    CALL ErasePtBlocks            ; always erase available file area (all sectors)
                    JR   C,format_error
.just_fehdr                                       ; empty banks are assumed below header (containing FF's)...
                    CALL FlashEprStdFileHeader    ; Create "oz" File Eprom Header in absolute bank B
                    JR   C,format_error

                    LD   HL,$3FC0                 ; BHL = absolute pointer to "oz" header in slot
                    CP   A                        ; Fc = 0, C = Number of 16K banks of File Area
                    POP  DE                       ; ignore old HL
                    POP  DE                       ; ignore old BC
                    POP  DE                       ; original DE restored
                    RET
.format_error
                    POP  HL
                    POP  BC
                    POP  DE
                    RET


; ************************************************************************
;
; Erase all sectors in Flash File Eprom, from the top (that includes
; the File Eprom Header) and downwards to the bottom of the card.
;
; IN:
;    B = Top bank of File Eprom (absolute bank with embedded slot mask)
;    C = Number of 16K banks in File Eprom Area
;
; OUT:
;    Fc = 0, 
;         Partition on Flash Eprom erased successfully.
;         (contains $FF bytes)
;    Fc = 1, 
;         A = RC_NFE (not a recognized Flash Memory Chip)
;         A = RC_BER (error occurred when erasing block/sector)
;         A = RC_VPL (Vpp Low Error)
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;    
.ErasePtBlocks
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   E,C                 ; preserve bank count of FE area
                    LD   A,B
                    AND  @11000000
                    RLCA
                    RLCA                     
                    LD   C,A                 ; Flash Memory card is in slot C
                    CALL FlashEprCardId      ; get the Card ID in HL...
                    JR   C, exit_ErasePtBlocks
                    PUSH DE
                    LD   DE,FE_AM29F010B
                    SBC  HL,DE               ; AM29F010B Flash Memory in slot C?
                    POP  DE
                    JR   NZ, _64K_block_fe   ; no, it's a 64K sector architecture Flash Memory
                                             ; yes, identified the 16K sector architecture Flash Memory
                    LD   B,E                 ; E = total of 16K sectors to be erased
                    DEC  B                   ; B = top sector to be erased (total-1)
                    JR   erase_PT_loop
._64K_block_fe                    
                    SRL  E
                    SRL  E                   ; E = total of 64K sectors (banks/4) to be erased...
                    LD   B,E
                    DEC  B                   ; B = top sector to be erased (total-1)
.erase_PT_loop
                    CALL FlashEprBlockErase  ; format sector B of partition in slot C
                    JR   C, exit_ErasePtBlocks ; get out if an error occurred...
                    DEC  B                   ; next (lower) block to erase
                    DEC  E
                    JR   NZ, erase_PT_loop   ; erase all blocks specified...
                    CP   A                   ; Fc = 0, all blocks successfully erased
.exit_ErasePtBlocks
                    POP  HL
                    POP  DE
                    POP  BC
                    RET
