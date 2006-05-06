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
; $Id$
;
; ********************************************************************************************************************

;    Development history:

;    Dec 1993: Work begun on Z88 assembler based on early work from '92, '93.

;    Jan 1994: V0.1
;              Parsing of all instructions implemented.
;              avltree algorithm cleared with dangerous bugs
;              malloc & mfree cleared with some bugs
;              expression parsing & evaluation implemented
;              code generation implemented
;              pass2 implemented
;              object file logic implemented (partial level 00)
;              first draft link algorithm programmed (not interfaced with assembler yet)

;    Mar 1994: V0.11
;              Windows created for messages and input.
;              Command line implemented with limited input facilies (only file name entry)
;              All initial code to handle listing file manipulation removed. The Z88
;                   version will not create listing files, but a symbol file instead.
;                   This has reduces the present code size with 380 bytes and speed improvement
;                   during pass1 parsing & code generation (particulary symbol manipulation).
;              Message for time used to assemble files is now displayed.

;    11.04.94: V0.12
;              Multiple files assembly logic implemented.
;              Error files implemented. Error files are removed if no errors occurred in module.
;                   Object files are removed if errors occurred during assembly of module.
;              Improved source file reading.
;              .ReleaseModules and .ReleaseFile subroutines removed - during command line and
;                   after compilation,  all memory pools are released in stead. This has
;                   also reduced the code with 241 bytes!
;              Level 00 of object files implemented (library reference names stored to object file)

;    12.04.94: V0.13
;              DEFVARS implemented.

;    13.04.94: V0.14
;              DEFGROUP implemented.
;              Bug in .StoreExpr fixed:
;                   Infix expression wasn't paged in when searching for null-terminator. This resulted
;                   in strange object file information.
;              Bug in .Z80pass2 fixed:
;                   RANGE_JROFFSET expressions were stored to object file.
;              Bug in .LD_index8bit_indrct fixed:
;                   Register pointer to store opcode were smashed before executed.
;                   Wrong index opcode were also stored to code buffer.

;    14.04.94: V0.15
;              Bug in .LD_address_indrct fixed:
;                   LD (nn),A stored incorrect opcode.
;                   LD (nn),IX stored incorrect opcode.
;              Bug in .EX_fn fixed:
;                   EX (SP),IX ;  EX (SP),IY  opcodes were swapped
;              Bug in .PushPop_instr fixed:
;                   IX, IY opcodes wasn't stored. Illegal instructions were not reported
;              Bug in .BitTest_instr:
;                   IX, IY opcodes stored illegal opode.
;              Bug in .RotShift_instr:
;                   IX, IY opcodes stored illegal opode.
;              Bug in .ArithLog8_instr fixed:
;                   IX, IY opcodes wasn't stored properly
;              Bug in .DEC_fn fixed:
;                   When a 16bit register were found, .INC_fn were called!
;              Bug in .IncDec_8bit_instr fixed:
;                   IX, IY opcodes were calculated and stored incorrectly
;              Bug in .Z80pass2 fixed:
;                   JR relative address offset were smashed before patched into code file
;              Bug in .StoreExpr fixed:
;                   Max. search length wasn't set up before finding the null-terminator
;                   in the infix expression. Random values of register C were used before.
;                   If C were less than the actual length, B became decreased, and the
;                   bank number for the infix expression became smashed.
;              .ParseNumExpr altered:
;                   The patch pointer (codeptr) is now saved in the expression record. This
;                   is now consistant with the C version of the assembler.
;              .Pass2Info altered:
;                   The code for storing the patch pointer is removed.
;              .StoreExpr altered:
;                   .StoreExpr now fetches the patch pointer directly from the expression record.

;    15.04.94: V0.16
;              .Getsym altered:
;                   '#' is now also accepted as part of a name identifier (only as the first char).
;              "Z88" standard identifier created when assembler begins processing the module.
;              .EvalLogExpr didn't return proper value of evaluated IF expression.
;              Bug in .ELSE_mnem, .ENDIF_mnem and .IF_mnem fixed:
;                   In both names the length byte was 1 too large (identifiying the length byte
;                   of the next name to be the last character of the current name).
;              File names of specified modules from the keyboard are now displayed while checked by
;                   the assembler.
;              All expressions that might have been generated in pass1 are now released in main
;                   main assembler loop (the current modules' expressions). This is necessary if
;                   pass2 is never called. If not released, it can easily produce 350K of
;                   expressions that never are released in a large compilation.
;    25.04.94: Flag introduced in expression header to identify when an expression is stored to the
;                   object file. Previously, redundancy of expressions appeared in the object file when
;                   several components in expressions were partially declared, resulting in saving the
;                   expression both in pass1 and pass2.
;              Label declarations are now per default touched when created.

;    26.04.94: V0.17
;              Program code split into two banks, and linked with 'extcall' library routine. Pass1 & pass2
;                   resides in main (entry) bank. Linking & various subroutines resides in external bank.

;    28.04.94: V0.18
;              File date stamp control implemented. It is now possible to compile a whole project and only
;                   re-assemle a few source files. It is also possible to first assemble all source files,
;                   generating object files, then delete the source files and only use the object files during
;                   the linking processs. This is very useful for Z88 users with limited RAM installed.
;              Module size after successfull assembly is now displayed.
;    29.04.94  Bug in .CreateFileName fixed:
;                   Gn_Esa some times corrupts the file name when the extension is added to the file name.
;                   The OZ call is now replaced with hand written code. It uses a few bytes more, but saves
;                   time!
;    30.04.94  codesize variable wasn't reset at beginning of assembly (.asmSourceFiles).
;              .Disp_allocmem now also displays estimated free memory.
;              z80asm is named as 'InterLogic' on initial start, and is then named with the first module
;                   file name.

;    02.05.94: V0.19
;              New much improved algorithms implemented to read source files via large buffer. This reduces
;                   the amount of OZ calls to read/parse the source files.
;    03.05.94  Bug in .Factor fixed:
;                   The single quote subroutine called the .Infix_operator with the wrong expression header
;                   pointer and used the lineptr variable instead.
;              Bug in CreateSrcFilename fixed:
;                   Calculating the new length of the file name with extension didn't incorporate the null-
;                   terminator.

;    04.05.94: V0.20
;              Symbol file algorithms implemented.
;              ASSEMBLE_ERROR now reset for each new source file being assembled (caused problems in prev.
;                   versions.

;    05.05.94: V0.21
;              Global definition file algorithms implemented.
;    06.05.94  Global definition file wasn't closed. if I/O error occurred at initial assembly. Now fixed.
;              The ":ram.-/temp.buf" file is now deleted at the end of the main assembler loop.
;              Selected RTM flag messages are now displayed in status window.

;    10.05.94: V0.22
;              Command line re-written. Wildcards now accepted as part of file names.
;              RTM flags now recognized and displayed.
;              Minor bug fixed in .asmSourceFile: A RET NZ was made if ASMERROR were detected - object &
;              symbol files weren't deleted.

;    24.05.94: V0.23
;              Information help command entries implemented. Help text written presently no room for it on ROM.
;              z80asm application reference naming re-written: The ref. name is now updated only when a file
;                  legally exists, or named with the project file if that is being used.
;              Level 01 in object files implemented.
;              Object file header checked when opened.
;              Global definition file only created if the first source file can be opened (exists).

;    25.05.94
;              Create library file implemented. However, object files are assumed not to exceed 64K size.

;    27.05.94
;              Create-library filename rewritten.
;              Make-library rewritten. Filename of object filename now displayed short (without path).
;              .Copy_file prepared for 24bit file sizes, but cannot yet handle those sizes.

;    28.05.94: V0.24
;              .Copy_file now handles copying of 24bit file sizes, specified in ABC registers.

;    29.05.94
;              .DEFVARS optimized: "DS" ident now checked with .memcompare library routine.
;              "DS" identifier no longer part of standard lookup identifier commands (.PrsIdent) .

;    07.06.94
;              .NewLibrary implemented: data structures for library file manipulation during linking
;                   prepared. The command line now accepts -i for specification of library files.

;    21.06.94: V0.25
;              DEFVARS now allows an evaluable expression when defining the offset.

;    21.06.94: V0.29
;              Algorithms for linking of modules implemented, but not yet tested

;    24.06.94
;              This is a great day: The assembler completed linking successfully the first time at 12.07pm.
;                   Linking of libraries has not yet been tested.

;    25.06.94: V0.30
;              z80asm finally links object modules and libraries. Performed successfully 11.01 on its own
;                   z80asm source files. Many small bugs have been fixed in linker algorithms. Typically
;                   stack and pointer assignment related bugs.
;                   "Linking lib. module <>" message changed to "Library module <>".
;                   Binary output not tested for correct relocated addressing and code linking.
;              .InsertSym altered to get compare routine via IX register and module owner via ahl registers.
;                   Appropriate routines in assembler has been modified accordingly.

;    26.06.94: V0.31
;              Mapfile routines implemented.
;              Bug fixed in .ReadNames: parameter for .InsertSym, pointer to module owner, wasn't setup properly.

;    02.07.94: V0.32
;              Bug in .DEFM_fn fixed: ASMPC variable wasn't updated correctly on 8 bit expression.

;    03.07.94:      Bug in .WriteWord fixed: Buffer counter wasn't updated correctly.
               .WriteWord optimised.

;    05.07.94: V0.33
;              Bug in .eval_binconstant fixed: wrong bit number SET when collected.
;              At 15.03, z80asm compiled itself successfully for the first time.

;    09.07.94:      Initial runtime flags now set to DATESTAMP, SYMBOL FILE, MAP FILE & LINKING.
;              (no global definitions, no libraries)
;              minor optimization in pass2: (codeptr) now used as length of generated code (previous (FA_EXT on cdefile).
;              size-of-module-message now also displayed if no bytes generated.

; (24.04.95) z80asm project paused (almost a year)...
; The original z80asm C version has changed considerably with many new features and improvements. The Z88 assembler
; project implies major work to get into the finish line:

;    24.04.95:      AVL-tree library routines improved to manipulate the user data via a sub-record (defined by a
;              pointer to the data). This enables a standard interface to the AVL-tree data manipulation. z80asm symbol
;              logic been altered to facilitate the new concept.
;              .GetPointer, .GetVarPointer & .AllocVarPointer have been move to the standard library.
;              .ReleaseSymbol removed. .FreeSym implemented as service routine to .delete_all library routine (which
;              releases the allocated AVL-tree back to OZ memory)
;              Origin now always stored in pass 2 (for first module) (even if not defined). Explicit origin used if
;              specified.
;              Z80pass2: Local, Global & library reference are stored to object file using new standard library routines.
;              The assembler PC mnemonic address 'ASMPC' renamed to 'asm_pc': this would otherwise coinside with the
;              standard 'ASMPC' identifier.

;    27.04.95:      z80asm now compiled as one executable file, with ORG at $8000.

;    28.04.95:      Explicit "ASMPC" logic removed from .DefineSymbol and .Factor. 'ASMPC' now initially created for each
;              assembler module in .asmSourceFiles.
;                   DEFINE command implementation completed. .DefineDefSym implemented.

;    22.05.95       Bug fixes of new implementation during 22.04 - 28.04. z80asm now handles symbol tables properly.

;    23.05.95: V0.34
;              .Infix_name changed to use .strcpy library routine.
;              .LoadBuffer, .Fetchline, .Getsym, .DEFM_fn, .Fetchfilename improved to handle both CR and LF as <newline>.

;    24.05.95  .DEFM_fn slightly improved.
;              V0.34 successfully compiled the ZetriZ source files (13 minutes to finish!).

;    26.05.95: V0.35
;              ASMPC logic in symbol table, pass1 & linking implemented completely.
;              Map file now only created if z80bin (linking) activated.
;              DEFVARS rewritten and implemented with allowed evaluable expression as size specifier.
;              DEFGROUP improved with expression assigment.
;              ".sym" file is now written using the standard .ascorder library routine.
;              ".map" file is now written using the standard .transfer, .reorder and .ascorder library routines.
;              ".def" file is now written using the standard .ascorder library routine.

;    28.05.95
;              Bug fixed in .Parseline: label wasn't ignored during a FALSE <IF> section.
;              Symbol file option was accidentally reset in 'linkmod.asm'.
;              Default library filename wildcard implemented (if no filename specified).

;    29.05.95  V0.36
;              Symbols changed: '^' now identifies raise-to-power. ':' identifies binary-xor.
;              Raise-to-power algorithms added to expression parsing & evaluation.
;              logical-not algorithms moved to correct syntax level.
;              constant-expression identifier '#' implemented.
;              Bug fixed in .ParseDefvarsize: fieldsize wasn't initialized to 0.
;              Bug in .DefGroup_fn fixed: assignment expression doesn't skip next line anymore.
;              Bug in .DefineDefSym fixed: symbol wasn't preset with SYMDEF and SYMDEFINED flags.
;              Bug in .Readexpr fixed: updating of the ASMPC symbol value was not set up properly.

;    30.05.95
;              Compiled all z80asm files successfully on the Z88, generating symbol files, object files,
;              z80asm.bin and a .map file in 1 hour, 6 minutes. Total workspace used was 149K! The code file
;              matched 100% with cross assembled version on ATARI/SMSQ.
;              Displayed filenames (during pass1 and linking) are now compressed to fit on a single line in window "5".
;              Code generation Pass1 displays line numbers of parsing source files.
;              Linking pass 1 displays total number of a module's symbols.
;              Linking pass 2 displays total number of expressions evaluated (from all modules).

;    31.05.95: V0.37
;              Application window area is filled with 'z80asm' text before windows are drawn.
;              Explicit origin from command line implemented.
;              Origin now also prompted if not defined (by command line or in the first source file) when linking begins.
;              Bug in .Getconstant fixed: hexadecimal digits were not checked for proper range ['0';'9','A';'F'].

;    01.06.95  -D option implemented at command line. .AllocId, now renamed as CopyId, rewritten to use standard library
;              .strcpy routine. -D symbols are created into the static symbol area and copied to the current local
;              symbols (hence the 'static' name). The tree-copy-process is performed by standard library routine .copy .
;              #module-file logic now improved to read CR, LF and CRLF as EOL indicator.
;              Bug fixed in .asmSourceFiles: After deleting symbols, the root variables wasn't properly reset to NULL.

;    02.06.95  .Open_file changed slightly: GN_OPF calculates null as part of length - strings in z80asm doesn't.
;              .CreateSrcFilename changed slightly: string length calculated is now exclusive null.
;              .CreateFileName adjust for above fixes.
;              Bug in .Infix_Name fixed: length byte was read locally. Now uses .Read_byte. This bug were introduced 01.06.95
;              Bug in .CopyID fixed: length byte was read locally. Now uses .Read_byte. This bug were introduced 01.06.95
;              Today, z80asm successfully compiled the current library.

;    28.06.95  V0.38
;              Status window changed to allowed up to 8 messages.
;              Codesize message displayed after pass1 linking.
;              -R option implemented (Relocation header). Map-file now also reflect relocation addresses.
;              -c option parameter implemented at command line, but not yet for 16K file boundaries.

;    03.07.93  V0.39
;              -c option implemented (compiled code split into 16K modules).

;    05.07.95  V0.40
;              Undocumented Z80 instructions implemented.
;              Default path identifier '#' implemented for INCLUDE and BINARY directives.
;              - The Z88 assembler is now at the same implementation level as the ANSI C version (V0.59).

;    13.07.95  V0.41
;              Syntax parsing in DEFB, DEFW and DEFL directives improved.

;    14.11.95  V1.00
;              Last internal change before official release:
;                   XLIB now improved to issue an internal MODULE <name>. This is more logical because
;                   only one XLIB is performed for a standard library module. Also, the source code
;                   looks more logical. Standard library source module files have been modified to not
;                   include the MODULE directive.

;    26.1.97   V1.01
;              Well, a big pause, but a few things fixed:
;                   .GetSym slightly changed for <CRLF> handling (better algorithm on identifying Newline).
;                   .Forward_newline rewritten (contained bug).
;                   .Backward_newline changed, due to bug in calculating the searched block and a CRLF.
;                   - z80asm now handles CR, LF and CRLF seamlessly on parsing source files.
;
;                   New feature added:
;                   Pressing <SQUARE><ESC> will abort the current compilation process; this is for
;                   stages Pass1 source module compilation and linking.
;                   Several procedures in Z80pass1.asm and modlink.asm altered for keyboard abortion.
;
;                   Message "Using <objectfile>" now displayed when an object file is newer than source file.
;                   Message window changed (bottom line removed) to allow for one additional line.
;
;    17.12.97  V1.02
;              Bug in Z80pass2, .pass2_patch_32sign fixed:
;                   Call to <write_fptr> was not set up properly. B = 0 to write (longint) local variable to file...
;              Bug in WriteLong fixed:
;                   Physical code pointer was updated with 8 instead of 4.
