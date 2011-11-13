;          ZZZZZZZZZZZZZZZZZZZZ
;        ZZZZZZZZZZZZZZZZZZZZ
;                     ZZZZZ
;                   ZZZZZ
;                 ZZZZZ           PPPPPPPPPPPPPP     RRRRRRRRRRRRRR       OOOOOOOOOOO     MMMM       MMMM
;               ZZZZZ             PPPPPPPPPPPPPPPP   RRRRRRRRRRRRRRRR   OOOOOOOOOOOOOOO   MMMMMM   MMMMMM
;             ZZZZZ               PPPP        PPPP   RRRR        RRRR   OOOO       OOOO   MMMMMMMMMMMMMMM
;           ZZZZZ                 PPPPPPPPPPPPPP     RRRRRRRRRRRRRR     OOOO       OOOO   MMMM MMMMM MMMM
;         ZZZZZZZZZZZZZZZZZZZZZ   PPPP               RRRR      RRRR     OOOOOOOOOOOOOOO   MMMM       MMMM
;       ZZZZZZZZZZZZZZZZZZZZZ     PPPP               RRRR        RRRR     OOOOOOOOOOO     MMMM       MMMM


; **************************************************************************************************
; This file is part of Zprom.
;
; Zprom is free software; you can redistribute it and/or modify it under 
; the terms of the GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; Zprom is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with the Zprom; 
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
; 
;
;***************************************************************************************************


    MODULE Search_Memory

    XREF Ms_banner, Es_banner, SearchAddr_prompt, Searchstrg_prompt
    XREF Bs_banner
    XREF Bind_in_bank
    XREF InpLine, ClearEditBuffer, PresetBuffer_hex16
    XREF Get_constant, SkipSpaces, GetChar, ConvHexByte
    XREF Write_Err_Msg, Out_of_bufrange, Syntax_error
    XREF Memory_View
    XREF PresetBuffer_Hex8, Membank_prompt

    XDEF MS_command, ES_command, BS_command


    INCLUDE "defs.asm"
    INCLUDE "stdio.def"


; ************************************************************************************************
; CC_ms     -   Memory Search
;
.MS_command         LD   A,$20
                    LD   (BaseAddr),A                   ; base addr. of buffer is $2000
                    LD   HL, Ms_banner                  ; 'Search in Memory:'
                    LD   (Banner),HL
                    CALL Search_Memory
                    RET


; ************************************************************************************************
; CC_es     -   Eprom Search
;
.ES_command         LD   A,$80
                    LD   (BaseAddr),A                   ; Base address of bank in segment 2
                    LD   HL, Es_banner                  ; 'Search in Eprom:'
                    LD   (Banner),HL

                    LD   A,(EprBank)                    ; get current EPROM bank
                    LD   B,A
                    CALL Bind_in_bank
                    CALL Search_Memory
                    RET


; ************************************************************************************************
; CC_bs     -   Bank Search
;
.BS_command         LD   A,(RamBank)                   ; get current RAM bank
                    LD   L,A
                    CALL PresetBuffer_Hex8             ; preset buffer with current bank
                    LD   A,3                           ; set cursor at end of bank number
                    LD   BC,$0110                      ; display menu at (16,3)
                    LD   DE,Membank_prompt             ; prompt 'Define Memory Bank (00h-FFh):'
                    LD   HL,Bs_banner                  ; 'Search in Bank'
                    CALL InpLine                       ; enter address
                    CP   IN_ESC                        ; <ESC> pressed during input?
                    RET  Z                             ; Yes, abort command.
                    LD   C,8
                    EX   DE,HL                         ; get bank number
                    CALL Get_Constant
                    RET  C                             ; Ups - syntax error or illegal value

                    LD   A,$80
                    LD   (BaseAddr),A                   ; Base address of bank in segment 2
                    LD   HL, Bs_banner                  ; 'Search in Bank:'
                    LD   (Banner),HL

                    LD   B,E
                    CALL Bind_in_bank                   ; get specified bank into segment
                    CALL Search_Memory
                    RET



; ***********************************************************************
;
; Search memory facility.
;
; The user specifies a search string, inputted either as binary hex
; values or as an ASCII string (no equal case search!). A ' symbol
; identifies an ASCII string, the default identifies HEX bytes.
;
; The search start search address and an optional bank number are installed
; in DE' and HL'. BC' = HL' to test whether searching has wrapped to original
; search address.
;
; Registers affected on return:
;
; ......../......../IXIY same
; AFBCDEHL/afbcdehl/.... different
;
.Search_memory      CALL ClearEditBuffer                ; empty before new input...
                    LD   HL,(RangeStart)                ; get cur. Start Prog. Range
                    CALL PresetBuffer_Hex16             ; preset buffer with ...
                    LD   A,4                            ; set cursor at end of address
                    LD   BC,$0212                       ; display menu at (18,2)
                    LD   HL,(banner)                    ; menu banner in HL
                    LD   DE,SearchAddr_prompt           ; prompt 'Enter Start Search Address:'
                    CALL Inpline                        ; enter an address
                    CP   IN_ESC
                    RET  Z                              ; ESC pressed, return to main menu

                    EX   DE,HL                          ; HL points at start of input buffer
                    LD   C,16
                    CALL Get_constant                   ; convert ASCII to 16 bit integer
                    RET  C                              ; return if an error occurred

                    LD   A,D                            ; get high byte of start address
                    AND  @11000000                      ; bank range 0000h - 3FFFh
                    JP   NZ, Out_of_Bufrange            ; 'out of buffer/bank range'
                    LD   (TopAddr),DE                   ; save start search address in 'TopAddr' temporarily

                    LD   A,0                            ; set cursor at start position
                    LD   BC,$0314                       ; display menu at (20,3)
                    LD   HL,(banner)                    ; 'Load file at address:'
                    LD   DE,SearchStrg_prompt           ; prompt 'Enter Search string:'
                    CALL ClearEditBuffer                ; empty before new input...
                    CALL Inpline                        ; enter an address
                    CP   IN_ESC
                    RET  Z                              ; ESC pressed, return to main menu

                    LD   H,D                            ; HL points at start of input buffer
                    LD   L,E
                    CALL SkipSpaces
                    JP   C, Syntax_Error                ; no line contents...
                    CALL GetChar
                    CP   '''
                    JR   Z, get_ascii_str
                    DEC  HL                             ; unget char
                    JR   get_hex_str

.get_ascii_str      LD   C,B                            ; B = lenght of search string + 1
                    DEC  C                              ; length of string excl. null-terminator
                    DEC  C                              ; excl. string identifier.
                    LD   D,H                            ; DE points at start of string
                    LD   E,L
                    JR   search_string                  ; HL always points at start of string

.get_hex_str        LD   C,0                            ; counter of search string length
.get_hexstr_loop    CALL GetChar
                    CP   0                              ; an illegal hex byte or the null-terminator?
                    JR   Z, end_hexinput                ; end of line reached
                    DEC  HL                             ; let subroutine read the char...
                    CALL ConvHexByte                    ; get a hex byte
                    RET  C                              ; Ups - illegal hex byte...
                    LD   (DE),A                         ; store hex byte into string
                    INC  DE
                    INC  C
                    JR   get_hexstr_loop                ; get next hex byte until null-terminator.

.end_hexinput       LD   H,D
                    LD   L,E                            ; DE points at last converted hex number
                    LD   B,0
                    CP   A
                    SBC  HL,BC                          ; HL = start of search string
                    LD   D,H                            ; DE = start of search string
                    LD   E,L                            ; HL always points at start of string


; begin search in memory...
; HL = start of search string (always)
; DE = start of search string
;
.Search_string      EXX
                    LD   DE,(TopAddr)                   ; get start search address
                    LD   A,(BaseAddr)                   ; use HL as absolute pointer
                    ADD  A,D
                    LD   H,A                            ; calculated from Base Address
                    LD   L,E                            ; and added with offset from DE
                    EXX

                    LD   B,0                            ; index counter of match in string reset...
.search_loop        EXX
                    LD   A,(BaseAddr)                   ; use HL as absolute pointer
                    ADD  A,D
                    LD   H,A                            ; calculated from Base Address
                    LD   L,E                            ; and added with offset from DE
                    INC  DE                             ; move offset pointer for next match...
                    EXX
                    LD   A,B
                    CP   C                              ; whole string match with memory?
                    JR   Z, string_match                ; Yes, search finished...

; search not finished, compare current byte in string with memory...
                    LD   A,(DE)                         ; get char from current string search pointer
                    EXX                                 ; use alternate set...
                    CP   (HL)                           ; does memory match with string byte?
                    EXX                                 ; use main set.
                    JR   Z, bytes_match                 ; Yes, byte equal, update various pointers...
                    LD   B,0
                    LD   D,H                            ; No match, reset to start of search string
                    LD   E,L                            ; reset pointers to start of string
                    EXX                                 ; calculate absolute address from offset in DE
                    LD   A,D
                    AND  @11000000                      ; DE only in range 0000h - 3FFFh
                    EXX
                    JR   Z,search_loop
                    LD   A,3
                    CALL Write_Err_Msg
                    RET

.bytes_match        INC  B                              ; a match in the string was found,
                    INC  DE                             ; update string pointers...
                    JR   search_loop                    ; addresses do not match, continue searching...

.string_match       EXX
                    PUSH HL
                    EXX
                    POP  HL
                    CP   A
                    LD   B,0
                    SBC  HL,BC                          ; set found address to start of string
                    LD   A,H
                    PUSH HL
                    LD   HL, BaseAddr
                    SUB  (HL)                           ; convert address to 16K bank offset
                    POP  HL
                    LD   H,A
                    LD   (TopAddr),HL                   ; store Top Address for dump subroutine.
                    CALL Memory_View                    ; display a dump of the found string.
                    RET
