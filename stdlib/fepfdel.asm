     XLIB FlashEprFileDelete

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

     LIB FlashEprCardId
     LIB FlashEprWriteByte
     LIB FileEprFileEntryInfo
     LIB PointerNextByte


; **************************************************************************
;
; Standard Z88 File Eprom Format (using Flash Eprom Card).
;
; Mark File Entry as deleted on File Eprom (in slot 3), identified
; by BHL pointer (B=00h-3Fh, HL=0000h-3FFFh).
;
; This routine will temporarily set the Vpp pin while marking the
; file as deleted.
;
; IN:
;         BHL = pointer to File Entry
;
; OUT:
;         Fc = 0,
;              Marked as deleted.
;
;         Fc = 1,
;              A = RC_Onf, File (Flash) Eprom or File Entry not found in slot 3
;              A = RC_VPL, RC_BWR, Flash Eprom Write Error
;
; Registers changed on return:
;    A.BCDEHL/IXIY same
;    .F....../.... different
;
; --------------------------------------------------------------------------
; Design & Programming, Gunther Strube, InterLogic, Dec 1997 - Apr 1998
; --------------------------------------------------------------------------
;
.FlashEprFileDelete
                    PUSH HL
                    PUSH DE
                    PUSH BC                       ; preserve CDE
                    PUSH AF                       ; preserve AF, if possible

                    PUSH BC
                    PUSH HL                       ; preserve File Entry pointer...
                    LD   C,3                      
                    CALL FlashEprCardId           ; check FE in slot 3
                    POP  HL
                    POP  BC                    
                    JR   C, err_delfile           ; Flash Eprom not identified!

                    SET  7,B                      ; slot 3 mask
                    SET  6,B                      ; bank in slot 3
                    RES  7,H
                    SET  6,H                      ; (offset bound into segment 1 temporarily)

                    PUSH BC
                    PUSH HL
                    CALL FileEprFileEntryInfo
                    POP  HL
                    POP  BC
                    JR   C, err_delfile           ; File Entry was not found...
                    CALL PointerNextByte          ; point at start of filename, "/"

                    XOR  A
                    CALL FlashEprWriteByte        ; mark file as deleted with 0 byte
                    JR   C, err_delfile

                    POP  AF
                    CP   A                        ; Fc = 0, Fz = 1
.exit_delfile
                    POP  BC
                    POP  DE
                    POP  HL
                    RET
.err_delfile        POP  BC                       ; remove old AF, use new AF (error code and Fc = 1)
                    JR   exit_delfile
