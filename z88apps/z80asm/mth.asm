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

     MODULE MTH_z80asm

     XDEF z80asm_topics
     XDEF z80asm_commands
     XDEF z80asm_help
     XDEF z80asm_MTH_END

     INCLUDE "stdio.def"
     INCLUDE "applic.def"


     ORG MTH_z80asm_ORG


; ********************************************************************************************************************
;
; topic entries for z80asm application...
;
.z80asm_topics      DEFB 0                                                      ; start marker of topics

; 'INFO' topic
.z80asm_info_topic  DEFB z80asm_info_topic_end - z80asm_info_topic
                    DEFM "INFO"
                    DEFB (topic_info_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (topic_info_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB @00010010                                              ; info topic has help...
                    DEFB z80asm_info_topic_end - z80asm_info_topic
.z80asm_info_topic_end

                    DEFB 0


; *****************************************************************************************************************************
;
.z80asm_commands    DEFB 0                                                      ; start of commands

; "Command line options 1"
.z80asm_cmd1        DEFB z80asm_cmd1_end - z80asm_cmd1
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Command line options 1", 0
                    DEFB (info_cmd1_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd1_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd1_end - z80asm_cmd1
.z80asm_cmd1_end

; "Command line options 2"
.z80asm_cmd2        DEFB z80asm_cmd2_end - z80asm_cmd2
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Command line options 2", 0
                    DEFB (info_cmd2_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd2_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd2_end - z80asm_cmd2
.z80asm_cmd2_end

; "Compilation, Z88 memory"
.z80asm_cmd3        DEFB z80asm_cmd3_end - z80asm_cmd3
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Compilation, Z88 memory", 0
                    DEFB (info_cmd3_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd3_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd3_end - z80asm_cmd3
.z80asm_cmd3_end

; "Modular file design"
.z80asm_cmd4        DEFB z80asm_cmd4_end - z80asm_cmd4
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Modular file design", 0
                    DEFB (info_cmd4_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd4_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd4_end - z80asm_cmd4
.z80asm_cmd4_end

; "Date stamp control"
.z80asm_cmd5        DEFB z80asm_cmd5_end - z80asm_cmd5
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Date stamp control", 0
                    DEFB (info_cmd5_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd5_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd5_end - z80asm_cmd5
.z80asm_cmd5_end

; "Source files"
.z80asm_cmd6        DEFB z80asm_cmd6_end - z80asm_cmd6
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM $81, ".asm", $81, " source files", 0
                    DEFB (info_cmd6_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd6_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd6_end - z80asm_cmd6
.z80asm_cmd6_end

; ".err, .sym files"
.z80asm_cmd7        DEFB z80asm_cmd7_end - z80asm_cmd7
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM $81, ".err", $81, ", ", $81, ".sym", $81, " files", 0
                    DEFB (info_cmd7_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd7_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd7_end - z80asm_cmd7
.z80asm_cmd7_end

; ".obj, .bin files"
.z80asm_cmd8        DEFB z80asm_cmd8_end - z80asm_cmd8
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM $81, ".obj", $81, ", ", $81, ".bin", $81, " files", 0
                    DEFB (info_cmd8_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd8_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd8_end - z80asm_cmd8
.z80asm_cmd8_end

; ".def, .map files"
.z80asm_cmd9        DEFB z80asm_cmd9_end - z80asm_cmd9
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM $81, ".def", $81, ", ", $81, ".map", $81, " files", 0
                    DEFB (info_cmd9_help - z80asm_help) / 256                   ; high byte of rel. pointer
                    DEFB (info_cmd9_help - z80asm_help) % 256                   ; low byte of rel. pointer
                    DEFB $11                                                    ; new column
                    DEFB z80asm_cmd9_end - z80asm_cmd9
.z80asm_cmd9_end

; "Scope of identifiers"
.z80asm_cmd10       DEFB z80asm_cmd10_end - z80asm_cmd10
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Scope of identifiers", 0
                    DEFB (info_cmd10_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd10_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd10_end - z80asm_cmd10
.z80asm_cmd10_end

; "Defining address labels"
.z80asm_cmd11       DEFB z80asm_cmd11_end - z80asm_cmd11
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Defining address labels", 0
                    DEFB (info_cmd11_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd11_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd11_end - z80asm_cmd11
.z80asm_cmd11_end

; "Conditional assembly"
.z80asm_cmd12       DEFB z80asm_cmd12_end - z80asm_cmd12
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Conditional assembly", 0
                    DEFB (info_cmd12_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd12_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd12_end - z80asm_cmd12
.z80asm_cmd12_end

; "MODULE, ORG directives"
.z80asm_cmd13       DEFB z80asm_cmd13_end - z80asm_cmd13
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM $81, "MODULE", $81, ", ", $81, "ORG", $81, " directives", 0
                    DEFB (info_cmd13_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd13_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd13_end - z80asm_cmd13
.z80asm_cmd13_end

; "INCLUDE directive"
.z80asm_cmd14       DEFB z80asm_cmd14_end - z80asm_cmd14
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM $81, "INCLUDE", $81, " directive", 0
                    DEFB (info_cmd14_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd14_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd14_end - z80asm_cmd14
.z80asm_cmd14_end

; "BINARY directive"
.z80asm_cmd15       DEFB z80asm_cmd15_end - z80asm_cmd15
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM $81, "BINARY", $81, " directive", 0
                    DEFB (info_cmd15_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd15_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd15_end - z80asm_cmd15
.z80asm_cmd15_end

; "Library object modules"
.z80asm_cmd16       DEFB z80asm_cmd16_end - z80asm_cmd16
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Library object modules", 0
                    DEFB (info_cmd16_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd16_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd16_end - z80asm_cmd16
.z80asm_cmd16_end

; "OZ directives"
.z80asm_cmd17       DEFB z80asm_cmd17_end - z80asm_cmd17
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "OZ directives", 0
                    DEFB (info_cmd17_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd17_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $11
                    DEFB z80asm_cmd17_end - z80asm_cmd17
.z80asm_cmd17_end

; "Allocation directives"
.z80asm_cmd18       DEFB z80asm_cmd18_end - z80asm_cmd18
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Allocation directives", 0
                    DEFB (info_cmd18_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd18_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd18_end - z80asm_cmd18
.z80asm_cmd18_end

; "Variable declaration"
.z80asm_cmd19       DEFB z80asm_cmd19_end - z80asm_cmd19
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Variable declaration", 0
                    DEFB (info_cmd19_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd19_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd19_end - z80asm_cmd19
.z80asm_cmd19_end

; "Enumeration declaration"
.z80asm_cmd20       DEFB z80asm_cmd20_end - z80asm_cmd20
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Enumeration declaration", 0
                    DEFB (info_cmd20_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd20_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd20_end - z80asm_cmd20
.z80asm_cmd20_end

; "Constant declaration"
.z80asm_cmd21       DEFB z80asm_cmd21_end - z80asm_cmd21
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Constant declaration", 0
                    DEFB (info_cmd21_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd21_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd21_end - z80asm_cmd21
.z80asm_cmd21_end

; "Arithmetic processing"
.z80asm_cmd22       DEFB z80asm_cmd22_end - z80asm_cmd22
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Arithmetic processing", 0
                    DEFB (info_cmd22_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd22_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd22_end - z80asm_cmd22
.z80asm_cmd22_end

; "Expressions"
.z80asm_cmd23       DEFB z80asm_cmd23_end - z80asm_cmd23
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Expressions", 0
                    DEFB (info_cmd23_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd23_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd23_end - z80asm_cmd23
.z80asm_cmd23_end

; "Arithmetic operators"
.z80asm_cmd24       DEFB z80asm_cmd24_end - z80asm_cmd24
                    DEFW 0                                                      ; command code, keyboard sequense
                    DEFM "Arithmetic operators", 0
                    DEFB (info_cmd24_help - z80asm_help) / 256                  ; high byte of rel. pointer
                    DEFB (info_cmd24_help - z80asm_help) % 256                  ; low byte of rel. pointer
                    DEFB $10
                    DEFB z80asm_cmd24_end - z80asm_cmd23
.z80asm_cmd24_end

                    DEFB 0


; ***************************************************************************************************************
;
; Help pages for topics and commands:
;
.z80asm_help        DEFM $81, "Z80 Module Assembler V1.0.4B - ", $90, " ", $C8, " development", $81, $7F
                    DEFM $B6, $7F
                    DEFM $B7, $7F
                    DEFM $80
                    DEFM "z80asm is a module assembler, linker and library manager.", $7F
                    DEFM "Several z80asm applications may be created for different file", $7F
                    DEFM "compilations. Each file may have any size. Infinite number", $7F
                    DEFM "of files may be compiled - the Z88 memory is the limit."
                    DEFM $80, 0

.topic_info_help    DEFB $7F
                    DEFM "The following information help pages describe the various", $7F
                    DEFM "features, including command line options, file types, source", $7F
                    DEFM "file structure, modular file design, syntax of all", $7F
                    DEFM "directives, using, creating libraries, arithmetic operators,", $7F
                    DEFM "expressions and scope of identifiers."
                    DEFB 0

.info_cmd1_help     DEFB 12
                    DEFM "Syntax: [{", $81, "-", $81, "option}] {module {module}} | #projectfile", $7F
                    DEFM "Options will toggle current assembler directives", $7F
                    DEFM "combined. Module filenames are specified without extension", $7F
                    DEFM "(added automatically by z80asm). Wildcards may be used.", $7F
                    DEFM "Link/relocate object modules: ", $81, "-b", $81, ".", $7F
                    DEFM "Date stamp control (assemble only updated source files): ", $81, "-d", $81, ".", $7F
                    DEFM "Create symbol file for each source module: ", $81, "-s", $81, ".", $7F
                    DEFM "Create ", $81, "XDEF", $81, " file with global symbols of all modules: ", $81, "-g", $81, "."
                    DEFB 0

.info_cmd2_help     DEFB 12
                    DEFM "Create address map file (after linking): ", $81, "-m", $81, ".", $7F
                    DEFM "Create library from object modules: ", $81, "-x", $81, "", $80, "filename", $80, ".", $7F
                    DEFM "Link routines from ", $81, ".lib", $81, " library file(s): ", $81, "-i", $81, "", $80, "[filename]", $80, ".", $7F
                    DEFM "Define explicit origin (override 1. module ORG): ", $81, "-r", $81, "", $80, "$org", $80, "", $7F
                    DEFM "Prefix compiled code with relocation header: ", $81, "-R", $81, "", $7F
                    DEFM "Split assembled code into 16K blocks: ", $81, "-c", $81, "", $7F
                    DEFM "Define symbol name (of value -1) for all modules: ", $81, "-D", $81, "", $80, "name", $80, $7F
                    DEFM "(The DEFINE directive sustains name for a single module only)"
                    DEFB 0

.info_cmd3_help     DEFB 12
                    DEFM "We recommend 1MB RAM for large compilation projects but 128K", $7F
                    DEFM "or 512K is adequate. With sufficient RAM, object files can", $7F
                    DEFM "be generated and completed with linking to create the execu-", $7F
                    DEFM "table file. This may be a problem with limited memory.", $7F
                    DEFM "Using date stamp control the process may be separated in two", $7F
                    DEFM "phases: compile all into object files (and no symbol files),", $7F
                    DEFM "then delete source files. End with linking (most memory de-", $7F
                    DEFM "manding phase). With limited memory, deselect the map file."
                    DEFB 0

.info_cmd4_help     DEFB 12
                    DEFM "To improve compilation of large application projects and to", $7F
                    DEFM "save runtime memory, it is necessary to split the", $7F
                    DEFM "application program into separate source file modules to", $7F
                    DEFM "save time and memory usage overhead. The command line allows", $7F
                    DEFM "specification of multiple source files to be compiled into", $7F
                    DEFM "executable code. Project files may also be specified with a", $7F
                    DEFM "leading #, e.g. #z80asm. They contain all module filenames", $7F
                    DEFM "separated with <CR> (plain text files)."
                    DEFB 0

.info_cmd5_help     DEFB 12
                    DEFM "With modular design available it is not necessary to recom-", $7F
                    DEFM "pile a whole project of files, if only a single source", $7F
                    DEFM "module has been updated. Only that source module will be", $7F
                    DEFM "assembled to generate the necessary object file - the other", $7F
                    DEFM "modules are ignored, until the linking process begins (which", $7F
                    DEFM "then involves all object modules). Use the ", $81, "-d", $81, " option at the", $7F
                    DEFM "command line to enable this facility."
                    DEFB 0

.info_cmd6_help     DEFB 12
                    DEFM "Source files are identified with the ", $81, ".asm", $81, " extension and", $7F
                    DEFM "contain the Z80 assembler mnemonics and directives. A source", $7F
                    DEFM "file will be compiled into an object file. z80asm expects", $7F
                    DEFM "each line to be terminated by a CR, LF or CRLF. White spaces", $7F
                    DEFM "are ignored (ASCII 0-31). Text may be written in upper or", $7F
                    DEFM "lower case. Comments are identified with a semicolon. Source", $7F
                    DEFM "files may be written in PipeDream (as plain text) or another", $7F
                    DEFM "editor on stationary computers (transferred with EasyLink)."
                    DEFB 0

.info_cmd7_help     DEFB 12
                    DEFM "Error files are created with the ", $81, ".err", $81, " extension and use the", $7F
                    DEFM "file name of the current source module. The file contains", $7F
                    DEFM "error messages for the related line number in the source", $7F
                    DEFM "file. The defined symbol values of the current source file", $7F
                    DEFM "compilation may be written to a ", $81, ".sym", $81, " file named as the", $7F
                    DEFM "current source file. Label address symbols are relative to", $7F
                    DEFM "the start of the module code. Constants are absolute values.", $7F
                    DEFM "", $81, ".sym", $81, " files may be toggled with the ", $81, "-s", $81, " option."
                    DEFB 0

.info_cmd8_help     DEFB 12
                    DEFM "", $81, ".obj", $81, " files contain information of local, global label and", $7F
                    DEFM "constant declarations, expressions with relocatable addres-", $7F
                    DEFM "ses, the module name and the un-patched machine code.", $7F
                    DEFM "", $81, ".bin", $81, " files are the output of all linked, relocated ", $81, ".obj", $81, "", $7F
                    DEFM "module files. The ", $81, ".bin", $81, " file name are formed from the first", $7F
                    DEFM "specified source module. ", $81, ".bin", $81, " files are the only file type", $7F
                    DEFM "that can be executed by the Z80 processor. You may split", $7F
                    DEFM "them into 16K boundary ", $81, ".bn#", $81, " files with the ", $81, "-c", $81, " option."
                    DEFB 0

.info_cmd9_help     DEFB 12
                    DEFM "", $81, ".def", $81, " definition files uses the file name of the first", $7F
                    DEFM "source module, and contains a tabulated list of constant", $7F
                    DEFM "definitions that defines all global address (label) decla-", $7F
                    DEFM "rations after a compilation. ", $81, ".map", $81, " files contains two tabu-", $7F
                    DEFM "lated lists of all relocated labels from all modules and", $7F
                    DEFM "their corresponding addresses. They are ordered alphabeti-", $7F
                    DEFM "cally and numerically for cross reference. ", $81, "-R", $81, " relocated", $7F
                    DEFM "files use ORG 0, which will be reflected in the map file."
                    DEFB 0

.info_cmd10_help    DEFB 12
                    DEFM "To facilitate modular design two directives are implemented:", $7F
                    DEFM "", $81, "XREF", $81, " ", $80, "name", $80, "; symbol is defined in another module. ", $81, "XDEF", $81, " ", $80, "name", $80,     ";", $7F
                    DEFM "symbol is available to all linked modules. Symbols that has", $7F
                    DEFM "not been previously declared with ", $81, "XREF", $81, " or ", $81, "XDEF", $81, ", will be", $7F
                    DEFM "identified as local module symbols. Several declarations may", $7F
                    DEFM "be combined with comma. Linking cannot complete if an ", $81, "XREF", $81, "", $7F
                    DEFM "name is not ", $81, "XDEF", $81, "'ed in another module."
                    DEFB 0

.info_cmd11_help    DEFB 12
                    DEFM "A label name is declared with a leading full stop, e.g.", $7F
                    DEFM "", $80, ".main", $80, ", and is case independent. A label must be declared", $7F
                    DEFM "before any statements (mnemonics, directives) on the cur-", $7F
                    DEFM "rent source line. Labels may be defined as the sole state-", $7F
                    DEFM "ment on a line. Label names (without full stop) may be used", $7F
                    DEFM "freely in expressions to refer as addresses in source files.", $7F
                    DEFM "The scope of labels are declared with ", $81, "XREF", $81, " or ", $81, "XDEF", $81, "."
                    DEFB 0

.info_cmd12_help    DEFB 12
                    DEFM "To separate various sections in source files to be assembled", $7F
                    DEFM "only at dependent conditions, the ", $81, "IF", $81, " <expr>, ", $81, "ELSE", $81, " and ", $81, "ENDIF", $81, "", $7F
                    DEFM "directives may be used, all to be placed on separate lines.", $7F
                    DEFM "Nesting of several ", $81, "IF", $81, " statements may be formed. The ", $81, "ELSE", $81, "", $7F
                    DEFM "directive may be left out to create simple conditions.", $7F
                    DEFM "A standard symbol, ", '"', "Z88", '"', ", is defined as TRUE during compi-", $7F
                    DEFM "lation, e.g. to be used for conditional assembly. The", $7F
                    DEFM $81, "DEFINE", $81, " ", $80, "name", $80, " directive is also well suited for this purpose."
                    DEFB 0

.info_cmd13_help    DEFB 12
                    DEFM "Each source file module must be specified with a name. This", $7F
                    DEFM "is necessary when generating global definition files, add-", $7F
                    DEFM "ress map files, and when extracting routines from libraries", $7F
                    DEFM "to be added into user program code. Simply write ", $7F
                    DEFM $81, "MODULE", $81, " ", $80, "name", $80, ". The start address of the", $7F
                    DEFM "linked and executable code is defined by the first module.", $7F
                    DEFM "Use the ", $81, "ORG", $81, " directive or z80asm will request if not defined.", $7F
                    DEFM "You can override the origin with the explicit ", $81, "-r", $81, " option."
                    DEFB 0

.info_cmd14_help    DEFB 12
                    DEFM "", $81, "INCLUDE", $81, " allows inclusion of other source files into the cur-", $7F
                    DEFM "rent source file module, which will be parsed from the line", $7F
                    DEFM "of the ", $81, "INCLUDE", $81, " directive. The file name is specified in", $7F
                    DEFM "double quotes, e.g. ", $81, "INCLUDE", $81, " ", $80, "", '"', "//stdio.def", '"', "", $80, ". Nesting of inc-", $7F
                    DEFM "lude files is allowed. Avoid (mutual) recursion of include", $7F
                    DEFM "files since this overflows the z80asm appl. stack and", $7F
                    DEFM "crashes the Z88. A preceeding '#' in the filename inserts", $7F
                    DEFM "the standard wildcard ", '"', ":*//*", '"', ", to place a file anywhere."
                    DEFB 0

.info_cmd15_help    DEFB 12
                    DEFM "The ", $81, "BINARY", $81, " directive allows binary data to be merged from a", $7F
                    DEFM "file directly at the assembler PC - a sort of external ", $81, "DEFM", $81, "", $7F
                    DEFM "feature. This could be useful for application data", $7F
                    DEFM "structures which are position independent. The file name is", $7F
                    DEFM "specified in double quotes, e.g.: ", $81, "BINARY", $81, " ", $80, "", '"', "//applstrct.bin", '"', "", $80, ".", $7F
                    DEFM "You could even use it as a feature to merge (relocatable)", $7F
                    DEFM "machine code routines."
                    DEFB 0

.info_cmd16_help    DEFB 12
                    DEFM "Standard routines from a library may be added to user pro-", $7F
                    DEFM "gram code. 1) refer to the library routine to be added using", $7F
                    DEFM "the ", $81, "LIB", $81, " directive in your source module. 2) libraries may be", $7F
                    DEFM "specified using the cmd.line ", $81, "-i", $81, " option. Libraries are groups", $7F
                    DEFM "of configured object modules: Each module subroutine is", $7F
                    DEFM "declared globally available with ", $81, "XLIB", $81, ". Library modules", $7F
                    DEFM "may also refer to other library modules using the ", $7F
                    DEFM $81, "LIB", $81, " directive."
                    DEFB 0

.info_cmd17_help    DEFB 12
                    DEFM "Since macroes are not implemented (yet), two mnemonics have", $7F
                    DEFM "been implemented to improve flexibility:", $7F
                    DEFM "", $81, "CALL_OZ", $81, "(parameter) - RST 20h OZ interface (", $80, "DC_", $80, ",", $80, "GN_", $80, ",", $80, "OS_", $80    , ").", $7F
                    DEFM "", $81, "FPP", $81, "(parameter) - RST 18h floating point interface (", $80, "FP_", $80, ").", $7F
                    DEFM "The directives automatically allocate the necessary space", $7F
                    DEFM "for 8 or 16 bit parameter sizes. Always define OZ defini-", $7F
                    DEFM "tions before the OZ directives (e.g. by ", $81, "INCLUDE", $81, "'ing the", $7F
                    DEFM "appropriate standard OZ definition files at the beginning)."
                    DEFB 0

.info_cmd18_help    DEFB 12
                    DEFM "To allocate space, store text strings and integer constants", $7F
                    DEFM "into the current module code, ", $81, "DEFS", $81, ", ", $81, "DEFM", $81, ", ", $81, "DEFB", $81, ", ", $81, "DEFW", $81,     " and", $7F
                    DEFM "", $81, "DEFL", $81, " are used. ", $81, "DEFM", $81, " defines strings, e.g. ", $80, "", '"', "abc", '"', ", 13", $80, ". The", $7F
                    DEFM "other directives expect an arithmetic expression as para-", $7F
                    DEFM "meter. Several constants may be defined, separated by a", $7F
                    DEFM "comma. ", $81, "DEFS", $81, " <b>, allocate space (filled as 0). ", $81, "DEFB", $81, ", define", $7F
                    DEFM "byte; ", $81, "DEFW", $81, ", define word; ", $81, "DEFL", $81, ", define long word (32bit)."
                    DEFB 0

.info_cmd19_help    DEFB 12
                    DEFM "Define groups of variable adresses and their sizes with", $7F
                    DEFM "", $81, "DEFVARS", $81, " ", $80, "orig", $80, " ", $81, "{", $81, " [variable] ", $81, "DS.", $81, "size x ", $81, "}", $81    , ". ", $80, "orig", $80, " defines the", $7F
                    DEFM "origin of variables. Each variable name are specified on", $7F
                    DEFM "separate lines between ", $81, "{}", $81, ". ", $81, "DS", $81, " defines the variable size,", $7F
                    DEFM "specified as: .B=8bit .W=16bit .L=32bit .P=pointer (offset,", $7F
                    DEFM "bank). x = size multiplier. Create dynamic data structure", $7F
                    DEFM "records with ", $80, "orig", $80, "=0; a name following the last size", $7F
                    DEFM "definition automatically defines the record structure size."
                    DEFB 0

.info_cmd20_help    DEFB 12
                    DEFM "Definition of a set of symbols is created with ", $81, "DEFGROUP {}", $81, ".", $7F
                    DEFM "Symbol names are separated with comma and may be defined on", $7F
                    DEFM "several lines. The first symbol is assigned default 0, con-", $7F
                    DEFM "tinued with values of the following names in ascending or-", $7F
                    DEFM "der. Symbol names may be assigned with expressions: ", $81, "{", $81, "nil,", $7F
                    DEFM "ident=12, newline=sym_null, next", $81, "}", $81, ". The next (following) sym-", $7F
                    DEFM "bol are assigned with the new constant + 1. Useful for names", $7F
                    DEFM "that needs re-arrangement during a development phase."
                    DEFB 0

.info_cmd21_help    DEFB 12
                    DEFM "To define constants, use ", $81, "DEFC", $81, " name ", $81, "=", $81, " <expression>. The", $7F
                    DEFM "expression must not contain forward referenced names, but", $7F
                    DEFM "only already declared names (labels or other constants).", $7F
                    DEFM "Several constant definitions may be combined on the same", $7F
                    DEFM "line, separated with a comma. All names defined in source", $7F
                    DEFM "files (labels, constant names, variables and enumerations)", $7F
                    DEFM "are automatically converted to upper case by the assembler", $7F
                    DEFM "during compilation. ISO characters may be used in names."
                    DEFB 0

.info_cmd22_help    DEFB 12
                    DEFM "All constants and expressions are evaluated internally as", $7F
                    DEFM "32bit signed integers by z80asm. Whenever a value parameter", $7F
                    DEFM "is requested in a Z80 mnemonic or directive, an expression", $7F
                    DEFM "is allowed. Three types of expressions are available:", $7F
                    DEFM "logical expressions using relational operators, arithmetic", $7F
                    DEFM "expressions and string expressions. With the ", $81, "DEFM", $81, $7F
                    DEFM "storage directive strings and 8bit (byte) expressions can be", $7F
                    DEFM "concatanated using the ", $81, "&", $81, " operator."
                    DEFB 0

.info_cmd23_help    DEFB 12
                    DEFM "Evaluates into a constant and may contain identifier names,", $7F
                    DEFM "constants, operators and brackets ", $81, "()", $81, " to identify subexpres-", $7F
                    DEFM "sions. Constants may be a ", $81, "$", $81, "<hex num.>, ", $81, "@", $81, "<8bit binary num.>,", $7F
                    DEFM "decimal number or a character constant, e.g. ", $81, "'", $81, "z", $81, "'", $81, ". Relations", $7F
                    DEFM "may be defined by: ", $81, "<", $81, ", ", $81, "<=", $81, ", ", $81, "=", $81, ", ", $81, "<>", $81, ", ", $81, "=>", $81,     ", ", $81, "!", $81, " (logical not). They", $7F
                    DEFM "evaluate into TRUE (-1) or FALSE (0). The standard identifi-", $7F
                    DEFM "er ", $81, "ASMPC", $81, " returns the current assembler program counter, e.g.", $7F
                    DEFM "to determine string lengths, use ASMPC - string_end ."
                    DEFB 0

.info_cmd24_help    DEFB 12
                    DEFM "The following operators may be used in expressions: ", $81, "+", $81, "", $7F
                    DEFM "(addition), ", $81, "-", $81, " (subtraction, unary minus), ", $81, "*", $81, " (multiply), ", $81, "/", $81, "", $7f
                    DEFM "(division), ", $81, "%", $81, " (modulus), ", $81, "^", $81, " (power), ", $81, "~", $81, " (binary AND), ", $81, "|", $81, "", $7F
                    DEFM "(binary OR), ", $81, ":", $81, " (binary XOR). ", $81, "#", $81, "<expr> convert to a constant", $7F
                    DEFM "expression (to avoid addition of relocation offset in add-", $7F
                    DEFM "ress expressions). The binary operators may also be used to", $7F
                    DEFM "form complex relational expressions. Evaluation precedence,", $7F
                    DEFM "highest first: #; < <= <> = => >; (); !; ~|:; ^; */%; +-"
                    DEFB 0

.z80asm_MTH_END
