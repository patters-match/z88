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

     LIB FlashEprBlockErase
     LIB FlashEprStdFileHeader
     LIB FileEprRequest
     

; ************************************************************************
;
; Flash Eprom File Area Formatting.
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
; IN:
;    -
;
; OUT:
;    Success:
;         Fc = 0, File Area on Flash Eprom erased successfully.
;         (Complete File Area contains $FF bytes, and an "oz" Header)
;
;    Failure:
;         Fc = 1
;         A = Error code
;             Reasons might be:
;             Flash Eprom not available (RAM or conventional EPROM)
;             Blocks could not be formatted, 
;             Header wasn't created 
;             No File Eprom space available on card
;
; Registers changed after return:
;    ..BCDEHL/IXIY same
;    AF....../.... different
;
; ----------------------------------------------------------------------
; Design & programming by Gunther Strube, Dec 1997-Apr 1998, Aug 2004
; ----------------------------------------------------------------------
;
.FlashEprFileFormat
                    PUSH BC
                    PUSH DE
                    PUSH HL

                    LD   C,3                      ; slot 3...
                    CALL FileEprRequest           ; get pointer to File Eprom Header (or potential)
                    JR   C, exit_format           ; No File Eprom available
                    
                    LD   C,B                      ; B = Top Bank of File Area (or potential)
                    INC  C                        ; C = total of 16K banks to be erased...
                    CALL ErasePtBlocks       

                    CALL FlashEprStdFileHeader    ; Create "oz" File Eprom Header in Top Bank 
                    JR   C,exit_format
                    LD   HL,$3FC0                 ; return pointer to "oz" header
                    LD   A,B
                    INC  A                        ; 
                    SRL  A
                    SRL  A                        ; return A = File Eprom size in blocks
                    CP   A
.exit_format
                    POP  HL
                    POP  DE
                    POP  BC
                    RET



; ************************************************************************
;
; Erase Blocks in Flash Eprom Partition
;
; IN:
;    B = Top bank of Partition
;    C = Number of 16K banks in partitition
;
; OUT:
;    Fc = 0, Partition on Flash Eprom erased successfully.
;    (contains $FF bytes)
;
; Registers changed after return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;    
.ErasePtBlocks
                    PUSH AF
                    PUSH BC

                    LD   A,B
                    SRL  A
                    SRL  A
                    AND  @00001111           
                    LD   B,A                 ; B = Top Block Number of Partition
                    
                    SRL  C
                    SRL  C                   ; C = total of 64K blocks to be erased...
.erase_PT_loop
                    LD   A,B
                    CALL FlashEprBlockErase  ; format block B of partition
                    JR   C, erase_PT_loop    ; erase block until completed successfully
                    DEC  B                   ; next (lower) block to erase
                    DEC  C
                    JR   NZ, erase_PT_loop   ; erase all blocks of partition...
          
                    POP  BC
                    POP  AF
                    CP   A                   ; Fc = 0 always...
                    RET
