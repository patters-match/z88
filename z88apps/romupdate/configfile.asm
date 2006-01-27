; *************************************************************************************
; RomUpdate
; (C) Gunther Strube (gbs@users.sf.net) 2005-2006
;
; RomUpdate is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; RomUpdate is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with RomUpdate;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

     MODULE ConfigFile

     lib IsSpace, IsAlpha, IsAlNum, IsDigit, StrChr, ToUpper

     xdef ReadConfigFile
     xref ErrMsgNoCfgfile, ErrMsgCfgSyntax

     include "stdio.def"
     include "fileio.def"
     include "fpp.def"

     ; RomUpdate runtime variables
     include "romupdate.def"


; *************************************************************************************
; Load parameters from 'romupdate.cfg' file.
;
.ReadConfigFile
                    ld   bc,128
                    ld   hl,cfgfilename                 ; (local) filename to card image
                    ld   de,filename                    ; output buffer for expanded filename (max 128 byte)...
                    ld   a, OP_IN
                    oz   GN_Opf
                    jp   c,ErrMsgNoCfgfile              ; couldn't open config file!

                    ld   hl,0
                    ld   (cfgfilelineno),hl             ; lineno = 0 (we haven't yet loaded a line...)
                    call LoadBuffer                     ; load config file into memory
                    ld   (nextline),hl                  ; init pointer to beginning of first line
                    call FetchLine                      ; read the 'RomUpdateCrc=XXXXXXXX' line (not parsed)
                    oz   GN_Cl                          ; config file loaded, just close handle...

                    call FetchLine                      ; get next line, containing the 'CFG.Vx' identification
                    jp   z,ErrMsgCfgSyntax              ; premature EOF!
                    call GetSym
                    cp   sym_name
                    jp   nz,ErrMsgCfgSyntax             ; 'CFG' was not identified...
                    call GetSym
                    cp   sym_fullstop
                    jp   nz,ErrMsgCfgSyntax             ; '.' was not identified...
                    call GetSym
                    cp   sym_name
                    jp   nz,ErrMsgCfgSyntax             ; 'Vx' was not identified...
                    ld   hl,(Ident+1)
                    ld   de, '1'<<8 | 'V'
                    sbc  hl,de
                    jp   nz,ErrMsgCfgSyntax             ; For now, "V1" is default config file format
.fetch_appfile_spec
                    call FetchLine                      ; fetch line containing the file image specification
                    jp   z,ErrMsgCfgSyntax              ; premature EOF!
                    call GetSym
                    cp   sym_dquote
                    jr   nz,fetch_appfile_spec

                    ; parse application file image specification...
                    call GetBankFilename                ; read "filename" ...

                    call GetSym
                    cp   sym_comma                      ; skip comma...
                    jp   nz,ErrMsgCfgSyntax

                    call GetSym                         ; get bank file image CRC
                    call GetConstant
                    jp   nz,ErrMsgCfgSyntax             ; specified CRC value was illegal...
                    exx
                    ld   (bankfilecrc),bc
                    ld   (bankfilecrc+2),de             ; 32bit CRC value in 'debc
                    exx

                    call GetSym
                    cp   sym_comma                      ; skip comma...
                    jp   nz,ErrMsgCfgSyntax

                    call GetSym                         ; get location of application DOR in bank file
                    call GetConstant
                    jp   nz,ErrMsgCfgSyntax             ; specified DOR value was illegal...
                    exx
                    ld   (bankfiledor),bc               ; location of application DOR in bank file
                    exx
                    ret
; *************************************************************************************


; *************************************************************************************
; Read bank filename from current position in config file into (bankfilename) var.
; Max. 127 chars is read. Filename is null-terminated in variable.
;
.GetBankFilename
                    ld   hl,(lineptr)                   ; point at first char of bank image filename
                    ld   de,bankfilename
                    ld   b,127
.bnkflnm_loop
                    dec  b
                    jr   z, fetched_flnm                ; read max 127 chars of filename...
                    ld   a,(hl)
                    cp   '"'
                    jr   z, fetched_flnm
                    ld   (de),a
                    inc  hl
                    inc  de
                    jr   bnkflnm_loop
.fetched_flnm
                    inc  hl                             ; move beyond " terminator...
                    ld   (lineptr),hl                   ; (to get ready to read next symbol)
                    xor  a
                    ld   (de),a                         ; null-terminate filename string
                    ret
; *************************************************************************************


; *************************************************************************************
;
; GetSym - read a symbol from the current position of the file's current line.
;
;  IN:    None.
; OUT:    A = symbol identifier
;         (sym) contains symbol identifier
;         (Ident) contains symbol (beginning with a length byte)
;         (lineptr) is updated to point at the next character in the line
;
; Registers changed after return:
;
;    ..BCDEHL/IXIY  same
;    AF....../....  different
;
.GetSym             push bc
                    push de
                    push hl

                    xor  a
                    ld   de, ident                ; DE always points at length byte...
                    ld   (de),a                   ; initialise Ident to zero length
                    ld   bc, ident+1              ; point at pos. for first byte

                    ld   hl,(lineptr)
.skiplead_spaces    ld   a,(hl)
                    cp   cr
                    jr   z, newline_symbol        ; CR or CRLF as newline
                    cp   lf
                    jr   z, newline_symbol        ; LF as newline

                    cp   0
                    jr   z, nonspace_found        ; EOL reached
                    call isspace
                    jr   nz, nonspace_found
                    inc  hl                       ; white space...
                    jr   skiplead_spaces

.nonspace_found     push hl                       ; preserve lineptr
                    ld   hl, separators
                    call strchr                   ; is byte a separator?
                    pop  hl
                    jr   nz, separ_notfound

                    ; found a separator - return
                    ld   (sym),a                  ; pos. in string is separator symbol
                    inc  hl
                    ld   (lineptr),hl             ; prepare for next read in line
                    jr   exit_getsym

.newline_symbol     ld   a,sym_newline
                    ld   (sym),a
                    jr   exit_getsym

.separ_notfound     ld   a,(hl)                   ; get first byte of identifier
                    cp   '$'                      ; identifier a hex constant?
                    jr   z, found_hexconst
                    cp   '@'                      ; identifier a binary constant?
                    jr   z, found_binconst
                    call isdigit                  ; identifier a decimal constant?
                    jr   z, found_decmconst
.test_alpha         call isalpha                  ; identifier a name?
                    jr   nz, found_rubbish
.found_name         ld   a,sym_name
                    jr   read_identifier

.found_decmconst    ld   a, sym_decmconst
                    jr   fetch_constant

.found_hexconst     ld   a,sym_hexconst
                    jr   fetch_constant

.found_binconst     ld   a,sym_binconst
                    jr   fetch_constant

.found_rubbish      ld   a,sym_nil
.read_identifier    ld   (sym),a                  ; new symbol found - now read it...
                    xor  a                        ; Identifier has initial zero length

.name_loop          cp   max_idlength             ; identifier reached max. length?
                    jr   z,exit_getsym
                    ld   a,(hl)                   ; get byte from current line position
                    call isspace
                    jr   z, ident_complete        ; separator encountered...
                    push hl
                    ld   hl,separators            ; test for other separators
                    call strchr
                    pop  hl
                    jr   z, ident_complete        ; another separator encountered
                    ld   a,(hl)
                    call isalnum                  ; byte alphanumeric?
                    jr   nz, illegal_ident
                    call toupper                  ; name is converted to upper case
                    ld   (bc),a                   ; new byte in name stored
                    inc  bc
                    inc  hl
                    ld   (lineptr),hl
                    ex   de,hl
                    inc  (hl)                     ; update length of identifer
                    ld   a,(hl)
                    ex   de,hl
                    jr   name_loop                ; get next byte for identifier

.illegal_ident      ld   a,sym_nil
                    ld   (sym),a
                    jr   exit_getsym

.ident_complete     xor  a
                    ld   (bc),a                   ; null-terminate identifier
.exit_getsym        ld   a,(sym)
                    pop  hl
                    pop  de
                    pop  bc
                    ret

.fetch_constant     ld   (sym),a                  ; new symbol found - now read it...
                    xor  a
.constant_loop      cp   max_idlength             ; identifier reached max. length?
                    jr   z,exit_getsym
                    ld   a,(hl)                   ; get byte from current line position
                    call isspace
                    jr   z, ident_complete        ; separator encountered...
                    push hl
                    ld   hl,separators            ; test for other separators
                    call strchr
                    pop  hl
                    jr   z, ident_complete        ; another separator encountered
                    ld   a,(hl)
                    call toupper
                    ld   (bc),a                   ; new byte of identifier stored
                    inc  bc
                    inc  hl
                    ld   (lineptr),hl             ; update lineptr variable
                    ex   de,hl
                    inc  (hl)                     ; update length of identifer
                    ld   a,(hl)
                    ex   de,hl
                    jr   constant_loop            ; get next byte for identifier
; *************************************************************************************


; *************************************************************************************
;
; GetConstant - parse the current line for a constant (decimal, hex or binary)
;               and return a signed long integer.
;
;  IN:    None.
; OUT:    debc = long integer representation of parsed ASCII constant
;         Fc = 0, if integer collected, otherwise Fc = 1 (syntax error)
;
; Registers changed after return:
;
;    ......../IXIY  ........ same
;    AFBCDEHL/....  afbcdehl different
;
.GetConstant        ld   hl,ident
                    ld   a,(sym)
                    cp   sym_hexconst
                    jr   z, eval_hexconstant
                    cp   sym_binconst
                    jr   z, eval_binconstant
                    cp   sym_decmconst
                    jr   z, eval_decmconstant
                    scf
                    ret                           ; not a constant...

.eval_binconstant   ld   a,(hl)                   ; get length of identifier
                    inc  hl
                    inc  hl                       ; point at first binary digit
                    dec  a                        ; binary digits minus binary id '@'
                    cp   0
                    jr   z, illegal_constant
                    cp   9                        ; max 8bit binary number
                    jr   nc, illegal_constant
                    ld   b,a
                    ld   c,0                      ; B = bitcounter, C = bitcollector
.bitcollect_loop    rlc  c
                    ld   a,(hl)                   ; get ASCII bit
                    inc  hl
                    cp   '0'
                    jr   z, get_next_bit
                    cp   '1'
                    jr   nz, illegal_constant
                    set  0,c
.get_next_bit       djnz bitcollect_loop
                    push bc                       ; all bits collected & converted in C
                    exx
                    ld   de,0                     ; most significant word of long
                    pop  bc                       ; least significant word of long
                    exx
                    cp   a                        ; NB: bit constant always unsigned
                    ret

.eval_hexconstant   ld   a,(hl)                   ; get length of identifier
                    inc  hl
                    dec  a
                    cp   0
                    jr   z, illegal_constant
                    cp   9
                    jr   nc, illegal_constant     ; max 8 hex digits (signed long)
                    ld   b,0
                    ld   c,a
                    add  hl,bc                    ; point at least significat nibble
                    ld   de,longint               ; point at space for long integer
                    ld   c,0
                    ld   (longint),bc             ; clear long buffer (low word)
                    ld   (longint+2),bc           ; clear long buffer (high word)
                    ld   b,a                      ; number of hex nibbles to process
.readhexbyte_loop   ld   a,(hl)
                    dec  hl
                    call convhexnibble            ; convert towards most significant byte
                    ret  c                        ; illegal hex byte encountered
                    ld   (de),a                   ; lower nibble of byte processed
                    dec  b
                    jr   z, nibbles_parsed
                    ld   c,a
                    ld   a,(hl)
                    dec  hl
                    call convhexnibble
                    ret  c
                    sla  a                        ; upper half of nibble processed
                    sla  a
                    sla  a
                    sla  a                        ; into bit 7 - 4.
                    or   c                        ; merge the two nibbles
                    ld   (de),a                   ; store converted integer byte
                    inc  de
                    djnz readhexbyte_loop         ; continue until all hexnibbles read
.nibbles_parsed     exx
                    ld   de,(longint+2)           ; high word of hex constant
                    ld   bc,(longint)             ; low word of hex constant
                    exx
                    cp   a                        ; Fz = 1, successfully converted
                    ret                           ; return hex constant in debc

.eval_decmconstant  inc  hl                       ; point at first char in identifier
                    fpp  (fp_val)                 ; get value of ASCII constant
                    ret  c                        ; Fz = 0, Fc = 1 - syntax error
                    push hl
                    exx
                    pop  de
                    ld   b,h
                    ld   c,l
                    exx
                    xor  a
                    cp   c                        ; only integer format allowed
                    ret

.illegal_constant   scf                           ; Fc = 1, syntax error
                    ret
.ConvHexNibble
                    cp   'A'
                    jr   nc,hex_alpha             ; digit >= "A"
                    cp   '0'
                    ret  c                        ; digit < "0"
                    cp   ':'
                    ccf
                    ret  c                        ; digit > "9"
                    sub  48                       ; digit = ["0"; "9"]
                    ret
.hex_alpha          cp   'G'
                    ccf
                    ret  c                        ; digit > "F"
                    sub  55                       ; digit = ["A"; "F"]
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Load complete config file into buffer (it will never exceed 16K!)
;
;  IN:
;         IX = file handle
;
; OUT:    HL = pointer to start of buffer information.
;         DE = pointer to end of buffer information
;         Fz = 1, if EOF reached, otherwise Fz = 0
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.LoadBuffer
                    ld   bc, SIZEOF_LINEBUFFER-1  ; read max. bytes into buffer, if possible
                    ld   hl,0
                    ld   de, linebuffer           ; point at buffer to load file bytes
                    oz   OS_Mv                    ; read bytes from file

                    cp   a                        ; Fc = 0
                    ld   hl, SIZEOF_LINEBUFFER-1
                    sbc  hl,bc
                    ld   b,h
                    ld   c,l                      ; number of bytes read physically from file

                    ex   de,hl
                    dec  hl                       ; HL points at end of block
                    ld   (bufferend),hl           ; end of buffer is byte after last newline
                    ld   (hl),0                   ; null-terminate end of loaded information

                    ld   de, (bufferend)          ; DE: return L-end
                    ld   hl, linebuffer           ; HL: return L-start
                    ret
; *************************************************************************************


; *************************************************************************************
;
; Fetch a line from the config file
;
; return Fz = 1, if EOF file reached.
;
.FetchLine          push bc
                    push de
                    push hl

                    ld   hl,(nextline)            ; get beginning of new line in buffer
                    ld   de,(bufferend)
                    ld   a,h
                    cp   d
                    jr   nz, get_next_line
                    ld   a,l
                    cp   e
                    jr   z,exit_fetchline         ; EOF reached, return Fz = 1...
.get_next_line
                    ld   (lineptr),hl
                    ex   de,hl
                    cp   a
                    sbc  hl,de                    ; {bufferend - lineptr}
                    ld   b,h
                    ld   c,l                      ; search max characters for CR
                    ex   de,hl
                    call forward_newline

.new_lineptr        ld   (nextline),hl            ; HL points at beginning of new line
                    ld   hl,(cfgfilelineno)
                    inc  hl
                    ld   (cfgfilelineno),hl       ; lineno++
                    or   a                        ; Fz = 0, EOF not reached yet...

.exit_fetchline     pop  hl
                    pop  de
                    pop  bc
                    ret
; *************************************************************************************


; *************************************************************************************
;
;    Find NEWLINE character ahead. Search for the following newline characters:
;         1)   search CR
;         2)   if CR was found, check for a trailing LF (MSDOS newline) to be
;              bypassed, pointing at the first char of the next line.
;         3)   if CR wasn't found, then try to search for LF.
;         4)   if LF wasn't found, return pointer to the end of the buffer.
;
;    IN:  HL = start of search pointer, BC = max. number of bytes to search.
;    OUT: HL = pointer to first char of new line or end of buffer.
;
; Registers changed after return:
;
;    ......../IXIY  same
;    AFBCDEHL/....  different
;
.forward_newline    ld   d, cr                    ; HL = line, BC = bufsize
                    ld   e, lf
.srch_nwl_loop                                    ; do while
                    ld   a,d                      ; {
                    cp   (hl)                          ; if ( *line != CR)
                    jr   z, check_trail_lf             ; {
                         ld   a,e                      ;
                         cp   (hl)                          ; if ( *line++ == LF )
                         inc  hl                                 ;
                         ret  z                                  ; return line   /* LF */
                         dec  bc                       ; }
                         ld   a,b
                         or   c
                         ret  z
                         jr   srch_nwl_loop
                                                       ; else {
.check_trail_LF          inc  hl                            ; if (++*line != LF)
                         ld   a,e                                ; return line   /* CR */
                         cp   (hl)                               ;
                         ret  nz                            ; else
                         inc  hl                                 ; return ++line /* CRLF */
                         ret                           ; }
                                                  ; }
                                                  ; while (--bufsize)
; *************************************************************************************


.separators         defb end_separators - start_separators
.start_separators   defm 0, '"', "'", ";,.({})+-*/%^=&~|:!<>#", 13, 10
.end_separators

.cfgfilename        defm "romupdate.cfg",0
