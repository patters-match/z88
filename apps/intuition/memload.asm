
    MODULE MemoryLoad

    XREF Write_Msg
    XREF SkipSpaces, Get_constant
    XREF Input_buffer
    XREF Memory_Range
    XREF Use_IntErrhandler, RST_ApplErrhandler

    XDEF Memory_Load

    INCLUDE "defs.h"
    INCLUDE "fileio.def"
    INCLUDE "director.def"


; *******************************************************************************************
;
; Input memory address parameter
;
.Memory_Load        CALL SkipSpaces
                    JP   C, default_address   ; no parameter, use default value
                    LD   C,16
                    CALL Get_Constant         ; get DZ address (16bit hex value)
                    RET  C
                    JR   get_filename         ;

.default_address    LD   DE,$2000             ; load file at address

.get_filename       LD   HL, filename_prompt
                    CALL Write_Msg
                    PUSH DE
                    POP  IX

                    LD   HL, $0000
                    ADD  HL,SP
                    LD   D,H
                    LD   E,L                  ; DE = current SP
                    LD   BC,-34               ; allocate 34 byte filename buffer
                    ADD  HL,BC                ; HL = input buffer
                    LD   SP,HL                ; new SP Top of stack installed
                    PUSH DE                   ; remember old SP
                    PUSH IX                   ; preserve load address

                    INC  HL
                    LD   (HL),0               ; null-terminate start of buffer
                    DEC  HL
                    EX   DE,HL                ; DE points at start of buffer
                    LD   A,C                  ; max. 34 bytes to enter filename
                    CALL Input_buffer

                    CALL Use_IntErrhandler
                    LD   H,D
                    LD   L,E
                    LD   BC,34                ; B = 0 (local pointer), C = max length of expl. name
                    LD   A, OP_IN
                    CALL_OZ(Gn_Opf)           ; open file
                    JR   C, exit_memload      ; display error and return

                    XOR  A
                    LD   D,H
                    LD   E,L
                    LD   B,-1
                    CALL_OZ(Gn_Esa)           ; read filename at (DE)
                    CALL_OZ(Dc_Nam)           ; use filename to name 'Z80debug' application

                    LD   A,FA_EXT
                    LD   DE,0
                    CALL_OZ(Os_Frm)           ; get size of file in DEBC
                    LD   A,D
                    OR   E
                    JR   NZ, file_range

                    POP  HL                   ; get start load address of file
                    PUSH HL
                    ADD  HL,BC
                    DEC  HL                   ; address of last file byte in memory
                    LD   D,(IY + RamTopPage)  ;                                      ** V1.03
                    LD   E,0                  ;                                      ** V1.03
                    DEC  DE                   ; top address of allocated RAM
                    LD   A,D
                    CP   H                    ; last file byte higher than RamTop?
                    JR   C, file_range        ; Yes - file out of memory range

.load_file          POP  DE                   ; get start address
                    PUSH DE
                    LD   HL,0
                    CALL_OZ(Os_Mv)            ; load file into memory from start address
                    CALL_OZ(Gn_Cl)            ; close file
                    LD   HL, loaded_msg
                    CALL Write_Msg
                    JR   exit_memload

.file_range         CALL_OZ(Gn_Cl)
                    LD   HL, range_msg
                    CALL Write_Msg
                    CALL Memory_range

.exit_memload       POP  IX                   ; remove load address
                    POP  HL                   ; get original stack pointer
                    LD   SP,HL
                    CALL RST_ApplErrhandler
                    RET

.filename_prompt    DEFM "File:",0
.range_msg          DEFM "memory range!",0
.loaded_msg         DEFM "Loaded.",0
