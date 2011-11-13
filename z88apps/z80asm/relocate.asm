; ********************************************************************************************************************
;
;     ZZZZZZZZZZZZZZZZZZZZ    8888888888888       00000000000
;   ZZZZZZZZZZZZZZZZZZZZ    88888888888888888    0000000000000
;                ZZZZZ      888           888  0000         0000
;              ZZZZZ        88888888888888888  0000         0000
;            ZZZZZ            8888888888888    0000         0000       AAAAAA         SSSSSSSSSSS   MMMM       MMMM
;          ZZZZZ            88888888888888888  0000         0000      AAAAAAAA      SSSS            MMMMMM   MMMMMM
;        ZZZZZ              8888         8888  0000         0000     AAAA  AAAA     SSSSSSSSSSS     MMMMMMMMMMMMMMM
;      ZZZZZ                8888         8888  0000         0000    AAAAAAAAAAAA      SSSSSSSSSSS   MMMM MMMMM MMMM
;    ZZZZZZZZZZZZZZZZZZZZZ  88888888888888888    0000000000000     AAAA      AAAA           SSSSS   MMMM       MMMM
;  ZZZZZZZZZZZZZZZZZZZZZ      8888888888888       00000000000     AAAA        AAAA  SSSSSSSSSSS     MMMM       MMMM
;
; Copyright (C) Gunther Strube, 1995-2006
;
; Z80asm is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Z80asm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with Z80asm;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
;
; ********************************************************************************************************************

     MODULE relocator

     XDEF relocator, SIZEOF_relocator


; *************************************************************************
;
; This routine will relocate a machine code program.
; A relocation table is placed immediatly after the relocation routine.
;
; The program that is to be relocated and executed are placed immediatly
; after the relocation table.
;
; The relocation routine expects IY to point at the start address, entry
; of the relocater. The relocater then calculates the correct origin for
; the relocated program. The BBC BASIC on the Z88 also setups the IY register
; during a BBC BASIC CALL command to execute local machine code.
;
; After completed relocation, the entry of the relocater is patched to
; JP <nn> which jumps directly to the executing program, if the relocated
; relocated code is called again.
;
; The following registers are affected by the initial relocation process:
;         AFBCDEHL/IX../........ same
;         ......../..IY/afbcdehl different
;
; As indicated above the outside world cannot use the alternate registers
; as parameter interface to the relocated program - the are smashed by the
; relocater.
;
.relocator          ex   af,af'                   ; preserve AF
                    exx                           ; preserve BC, DE, HL
                    push iy
                    pop  hl
                    ld   bc, #end_relocator-relocator

                    add  hl,bc                    ; absolute address of relocation table

                    ld   e,(hl)
                    inc  hl
                    ld   d,(hl)
                    push de                       ; DE = total of relocation offset elements
                    inc  hl
                    ld   c,(hl)
                    inc  hl
                    ld   b,(hl)                   ; total size of relocation offset elements
                    inc  hl
                    push hl                       ; preserve pointer to first relocation offset element
                    add  hl,bc
                    ld   b,h                      ; HL = pointer to current relocation address
                    ld   c,l                      ; BC = program ORG, first byte of program

.relocate_loop           ex   (sp),hl                  ; HL = pointer to relocation offset element
                         ld   a,(hl)
                         inc  hl                       ; ready for next relocation offset pointer
                         or   a
                         jr   nz, byte_offset
.extended_offset         ld   e,(hl)
                         inc  hl
                         ld   d,(hl)                   ; DE = extended offset pointer to next relocation address
                         inc  hl                       ; ready for next relocation offset pointer
                         jr   relocate_address

.byte_offset             ld   d,0
                         ld   e,a                      ; offset pointer to next relocation address
.relocate_address        ex   (sp),hl                  ; HL = pointer to current relocation address
                         add  hl,de                    ; new pointer at memory that contains relocation address
                         ld   e,(hl)
                         inc  hl
                         ld   d,(hl)
                         ex   de,hl
                         add  hl,bc                    ; HL = address relocated to program ORG in BC
                         ex   de,hl
                         ld   (hl),d
                         dec  hl
                         ld   (hl),e                   ; update relocated address back to memory

                         pop  de                       ; DE = pointer to relocation offset
                         ex   (sp),hl                  ; HL = index counter
                         dec  hl                       ; update index counter
                         ld   a,h
                         or   l                        ; all addresses relocated?
                         ex   (sp),hl                  ; index counter back on stack
                         push de                       ; pointer to relocation offset back on stack
                    jr   nz, relocate_loop
                    pop  af
                    pop  af                            ; remove redundant variables

; relocation of program completed. Patch the entry of the relocater to JP <nn> that
; jumps directly to the executing program, if the loaded program is executed again.
; Finish with restoring main registers and then execute program.
;
.relocation_finished
                    ld   (iy+0),$C3
                    ld   (iy+1),c
                    ld   (iy+2),b                 ; patch entry to JP <nn>, the relocated program
                    exx                           ; swap back to main BC, DE, HL
                    ex   af,af'                   ; and main AF
                    jp   (iy)                     ; execute relocated program...
.end_relocator

     DEFC SIZEOF_relocator = end_relocator - relocator

; ******************************************************************************
;
; The relocation table is placed here by the assembler.
; The format of the generated table is:
;
;    total_elements    ds.w 1
;    sizeof_table      ds.w 1
;    patchpointer_0    ds.b 1  --+
;    patchpointer_1    ds.b 1    |
;    ....                        |  sizeof_table
;    ....                        |
;    patchpointer_n    ds.b 1  --+
;
; The first patch pointer is an offset from the start of the program (.routine)
; to the first position of a location that contains a relocatable address.
; The following patchpointers are relative offsets from the current relocated
; address to the next.
; If the offset distance is larger than 255 bytes between two relocatable
; addresses, the following patchpointer is used:
;
;         0,<16bit patchpointer>
;
; which denotes the an offset from the current relocated address to the next.
; The 16 bit patch pointer is stored in the low byte, high byte order.
;

.routine
; the machine code to be relocated is placed immediately after the relocation table
