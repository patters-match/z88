
	MODULE mthtext

	XDEF	Z80dbg_topics
	XDEF	Z80dbg_commands
	XDEF	Z80dbg_help
	XDEF	Z80dbg_MTH_END


	INCLUDE "defs.h"
	INCLUDE "stdio.def"


; *********************************************************************************************************************
;
; topic entries for	Z80dbg applications...
;
.Z80dbg_topics		DEFB	0											; start marker	of topics

; 'INFO' topic
.topic_info		DEFB	topic_info_end	- topic_info						; length of topic definition
				DEFM	"INFO"										; name terminated by high byte
				DEFB	(topic_info_help - Z80dbg_help) / 256				; high byte of	rel.	pointer
				DEFB	(topic_info_help - Z80dbg_help) % 256				; low byte of rel. pointer
				DEFB	@00010010										; this information topic	has help
				DEFB	topic_info_end	- topic_info
.topic_info_end
				DEFB	0



; *********************************************************************************************************************
;
.Z80dbg_commands	DEFB	0											; start of commands

; Syntax definition	in help
.inf_syntax		DEFB	inf_syntax_end	- inf_syntax						; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"syntax us", $DA, $CF, " help"
				DEFB	(inf_syntax_help - Z80dbg_help) / 256				; high byte of	rel.	pointer
				DEFB	(inf_syntax_help - Z80dbg_help) % 256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_syntax_end	- inf_syntax						; length of information command definition
.inf_syntax_end

; Using parameter constants
.inf_parconsts		DEFB	inf_parconsts_end -	inf_parconsts					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"us", $CE, " ", $F6, " ", $F5, "s"
				DEFB	(inf_parconsts_help	- Z80dbg_help)	/ 256			; high byte of	rel.	pointer
				DEFB	(inf_parconsts_help	- Z80dbg_help)	% 256			; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_parconsts_end -	inf_parconsts					; length of information command definition
.inf_parconsts_end

; Register manipulation I
.inf_regmanip1		DEFB	inf_regmanip1_end -	inf_regmanip1					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	$EA, " m", $FD, "ipula", $CD, " 1"
				DEFB	(inf_regmanip1_help	- Z80dbg_help)	/ 256			; high byte of	rel.	pointer
				DEFB	(inf_regmanip1_help	- Z80dbg_help)	% 256			; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_regmanip1_end -	inf_regmanip1					; length of information command definition
.inf_regmanip1_end

; Register manipulation II
.inf_regmanip2		DEFB	inf_regmanip2_end -	inf_regmanip2					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	$EA, " m", $FD, "ipula", $CD, " 2"
				DEFB	(inf_regmanip2_help	- Z80dbg_help)	/ 256			; high byte of	rel.	pointer
				DEFB	(inf_regmanip2_help	- Z80dbg_help)	% 256			; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_regmanip2_end -	inf_regmanip2					; length of information command definition
.inf_regmanip2_end

; Register commands
.inf_regcmds		DEFB	inf_regcmds_end - inf_regcmds						; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	$EA, " ", $BA, "s"
				DEFB	(inf_regcmds_help -	Z80dbg_help) /	256				; high byte of	rel.	pointer
				DEFB	(inf_regcmds_help -	Z80dbg_help) %	256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_regcmds_end - inf_regcmds						; length of information command definition
.inf_regcmds_end

; Flag register toggle cmds
.inf_flagreg		DEFB	inf_flagreg_end - inf_flagreg						; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	$EC, " ", $EA, " ", $BA, "s"
				DEFB	(inf_flagreg_help -	Z80dbg_help) /	256				; high byte of	rel.	pointer
				DEFB	(inf_flagreg_help -	Z80dbg_help) %	256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_flagreg_end - inf_flagreg						; length of information command definition
.inf_flagreg_end

; Number conversion	display
.inf_numcnv		DEFB	inf_numcnv_end	- inf_numcnv						; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"number conversion display"
				DEFB	(inf_numcnv_help - Z80dbg_help) / 256				; high byte of	rel.	pointer
				DEFB	(inf_numcnv_help - Z80dbg_help) % 256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_numcnv_end	- inf_numcnv						; length of information command definition
.inf_numcnv_end

; Executing Z80 instructions
.inf_execz80		DEFB	inf_execz80_end - inf_execz80						; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	$ED, "t", $CE, " Z80 instruc", $CD, "s"
				DEFB	(inf_execz80_help -	Z80dbg_help) /	256				; high byte of	rel.	pointer
				DEFB	(inf_execz80_help -	Z80dbg_help) %	256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_execz80_end - inf_execz80						; length of information command definition
.inf_execz80_end

; Runtime	flags I
.inf_rtmflags1		DEFB	inf_rtmflags1_end -	inf_rtmflags1					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"RTM ", $EC, "s 1"
				DEFB	(inf_rtmflags1_help	- Z80dbg_help)	/ 256			; high byte of	rel.	pointer
				DEFB	(inf_rtmflags1_help	- Z80dbg_help)	% 256			; low byte of rel. pointer
				DEFB	$11											; information help page,	new column
				DEFB	inf_rtmflags1_end -	inf_rtmflags1					; length of information command definition
.inf_rtmflags1_end

; Runtime	flags II
.inf_rtmflags2		DEFB	inf_rtmflags2_end -	inf_rtmflags2					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"RTM ", $EC, "s 2"
				DEFB	(inf_rtmflags2_help	- Z80dbg_help)	/ 256			; high byte of	rel.	pointer
				DEFB	(inf_rtmflags2_help	- Z80dbg_help)	% 256			; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_rtmflags2_end -	inf_rtmflags2					; length of information command definition
.inf_rtmflags2_end

; Runtime	flags III
.inf_rtmflags3		DEFB	inf_rtmflags3_end -	inf_rtmflags3					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"RTM ", $EC, "s 3"
				DEFB	(inf_rtmflags3_help	- Z80dbg_help)	/ 256			; high byte of	rel.	pointer
				DEFB	(inf_rtmflags3_help	- Z80dbg_help)	% 256			; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_rtmflags3_end -	inf_rtmflags3					; length of information command definition
.inf_rtmflags3_end

; Runtime	flags IV
.inf_rtmflags4		DEFB	inf_rtmflags4_end -	inf_rtmflags4					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"RTM ", $EC, "s 4"
				DEFB	(inf_rtmflags4_help	- Z80dbg_help)	/ 256			; high byte of	rel.	pointer
				DEFB	(inf_rtmflags4_help	- Z80dbg_help)	% 256			; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_rtmflags4_end -	inf_rtmflags1					; length of information command definition
.inf_rtmflags4_end

; Z80 Instr. disassembly
.inf_z80dz		DEFB	inf_z80dz_end - inf_z80dz						; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"Z80 instr. disassembly"
				DEFB	(inf_z80dz_help - Z80dbg_help) / 256				; high byte of	rel.	pointer
				DEFB	(inf_z80dz_help - Z80dbg_help) % 256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_z80dz_end - inf_z80dz						; length of information command definition
.inf_z80dz_end

; Memory commands I
.inf_memcmds1		DEFB	inf_memcmds1_end - inf_memcmds1					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	$AA, " ", $BA, "s"
				DEFB	(inf_memcmds1_help - Z80dbg_help) / 256				; high byte of	rel.	pointer
				DEFB	(inf_memcmds1_help - Z80dbg_help) % 256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_memcmds1_end - inf_memcmds1					; length of information command definition
.inf_memcmds1_end


; Window management
.inf_winman		DEFB	inf_winman_end	- inf_winman						; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	$F3, " m", $FD, "agement"
				DEFB	(inf_winman_help - Z80dbg_help) / 256				; high byte of	rel.	pointer
				DEFB	(inf_winman_help - Z80dbg_help) % 256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_winman_end	- inf_winman						; length of information command definition
.inf_winman_end

; Miscellaneous commands
.inf_misc			DEFB	inf_misc_end -	inf_misc							; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"miscell", $FD, "eous ", $BA, "s"
				DEFB	(inf_misc_help	- Z80dbg_help)	/ 256				; high byte of	rel.	pointer
				DEFB	(inf_misc_help	- Z80dbg_help)	% 256				; low byte of rel. pointer
				DEFB	$10											; information help page,	new column
				DEFB	inf_misc_end -	inf_misc							; length of information command definition
.inf_misc_end

; CLI log	file	management
.inf_clilog		DEFB	inf_clilog_end	- inf_clilog						; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"CLI log ", $CC, " m", $FD, "agement"
				DEFB	(inf_clilog_help - Z80dbg_help) / 256				; high byte of	rel.	pointer
				DEFB	(inf_clilog_help - Z80dbg_help) % 256				; low byte of rel. pointer
				DEFB	$11											; information help page
				DEFB	inf_clilog_end	- inf_clilog						; length of information command definition
.inf_clilog_end

; Keyboard handling
.inf_keyboard		DEFB	inf_keyboard_end - inf_keyboard					; length of information command definition
				DEFW	0											; command	code, keyboard sequense
				DEFM	"keyboard h", $D0, "l", $CE
				DEFB	(inf_keyboard_help - Z80dbg_help) / 256				; high byte of	rel.	pointer
				DEFB	(inf_keyboard_help - Z80dbg_help) % 256				; low byte of rel. pointer
				DEFB	$10											; information help page
				DEFB	inf_keyboard_end - inf_keyboard					; length of information command definition
.inf_keyboard_end
				DEFB	0



; *******************************************************************************************************************
; Help pages for Z80dbg info topics

.Z80dbg_help		DEFM	$7F, $E9, $81, " V1.1 - Z80 mach", $CF, "e code debugging", $81, $7F
				DEFM	$B6, $7F
				DEFM	$B7, 0

.topic_info_help
				DEFM	$7F, "Descrip", $CD, $FF, $E9, " ", $BA, "s.", 0


.inf_syntax_help	DEFM	1, "2JN", 12
				DEFM	"<>  ", $FC, "entity. Th", $D4, "", $D5, "usually", $FC, "8", $F9, " or 16", $F9, " ", $F5, ".", $7F
				DEFM	"[]   entity may", $F1, "ignored. A ", $F4, " replaces ", $F6, ".", $7F
				DEFM	"|    OR clause. Ei", $A2, "r first OR second entity may", $F1, "used.", $7F
				DEFM	".    ", $B9, " ", $F0, "fi", $FE, " (full s", $DE, "p).", $7F
				DEFM	"<n>  ", $F0, "fies", $FC, "8", $F9, " ", $F5, " or ", $EA, ".", $7F
				DEFM	$E6, " ", $F0, "fies a 16", $F9, " ", $F5, " or ", $EA, ".", $7F
				DEFM	"<b>  ", $F0, "fies", $FC, "absolute ", $BC, " numb", $FE, " (00h-FFh).", 0

.inf_parconsts_help	DEFB	12
				DEFM	"All ", $F5, " ", $F6, "s use ", $94, "a", $F7, " ", $FA, "m as ", $F4, ", ie.", $7F
				DEFM	"us", $CE, " no lead", $CE, " ", $F5, " ", $EF, "i", $FE, ". ", $A1, " ", $F7, " ", $FA, "m", $D5, "spe-", $7F
				DEFM	"cified", $D3, "a lead", $CE, " ~. ", $AB, $D5, "0-65535. ", $A1, " b", $CF, "ary ", $FA, "m ", $D4, "", $7F
				DEFM	$EF, "ied", $D3, "a lead", $CE, " @. Only 8 ", $F9, "s", $D5, "allowed. Legal", $7F
				DEFM	$AC, $D5, "0-255. ", $9D, " ", $FA, "m", $D5, $EF, "ied", $D3, "a lead", $CE, " '.", $7F
				DEFM	"Only charact", $FE, "s from keyboard ", $DC, " obta", $CF, "able. B", $CF, "ary", $D1, $7F
				DEFM	$9D, " ", $F5, "s resets high ", $C4, $FF, "16", $F9, " source.", 0

.inf_regmanip1_help	DEFM	1, "2JN", 12
				DEFM	$81, ".R", $81, "  ", $EB, "contents", $FF, "all Z80 ", $EA, "s.", $7F
				DEFM	$7F
				DEFM	"<reg8>", $E8, ", <reg16>", $E7, $7F
				DEFM	"If no ", $EA, " ", $F6, $D5,  $EF, "ied,", $B3, "contents", $FF, $D6, "at", $7F
				DEFM	$EA, $D5, "d", $D4, "play", $DA, $CF, " ", $94, "a", $F7, $D1, "b", $CF, "ary ", $FA, "m. Th", $D4, "", $7F
				DEFM	"applies also", $DF, $EC, " ", $EA, " ", $DE, "ggle ", $BA, "s.", 0

.inf_regmanip2_help	DEFM	12
				DEFM	"Upp", $FE, " case lett", $FE, "s ", $F0, "fy ma", $CF, " ", $EA, "s (eg. BC), low", $FE, $7F
				DEFM	"case lett", $FE, "s ", $F0, "fy alt", $FE, "nate ", $EA, "s. ", $A1, " ", $EA, $7F
				DEFM	$F6, " may", $F1, "a ", $EA, " ", $F0, "fi", $FE, " or a ", $F5, ".", $7F
				DEFM	"Us", $CE, " ", $EA, " ", $F0, "fi", $FE, "s implies use", $FF, "appropriate", $7F
				DEFM	"types, e.g. BC hl (assign", $CE, " alt", $FE, "nate HL", $DF, "ma", $CF, " BC),", $7F
				DEFM	"o", $A2, "rw", $D4, "e a syntax ", $FE, "ror", $D5, "reported.", 0

.inf_regcmds_help	DEFM	1, "2JN", 12
				DEFM	"B", $E8, ", C", $E8, ", BC", $E7, ", b", $E8, ", c", $E8, ", bc", $E7, $7F
				DEFM	"D", $E8, ", E", $E8, ", DE", $E7, ", d", $E8, ", e", $E8, ", de", $E7, $7F
				DEFM	"H", $E8, ", L", $E8, ", HL", $E7, ", h", $E8, ", l", $E8, ", hl", $E7, $7F
				DEFM	"A", $E8, ", a", $E8, $7F
				DEFM	"IX", $E7, ", IY", $E7, ", SP", $E7, ", PC", $E7, $7F
				DEFM	$7F
				DEFM	$EA, " contents ", $DC, " d", $D4, "play", $DA, "if no ", $F6, $D5, $EF, "ied.", 0

.inf_flagreg_help	DEFM	1, "2JN", 12
				DEFM	"F       ", $EB, $EC, " ", $EA, ".", $7F
				DEFM	"FZ ", $E5, " Set/Reset Z", $FE, "o ", $EC, ".", $7F
				DEFM	"FC ", $E5, " Set/Reset Carry ", $EC, ".", $7F
				DEFM	"FV ", $E5, " Set/Reset Ov", $FE, "flow ", $EC, ".", $7F
				DEFM	"FE ", $E5, " Parity ", $EC, " (same as FV).", $7F
				DEFM	"FP ", $E5, " Set Plus/M", $CF, "us ", $EC, " (M", $CF, "us=0).", $7F
				DEFM	"FS ", $E5, " Set/Reset Sign ", $EC, ".", 0

.inf_numcnv_help	DEFM	1, "2JN", 12
				DEFM	"$ <", $94, ">    ", $EB, "8", $F9, " value ", $CF, " ", $F7, ", b", $CF, "ary ", $FA, "m.", $7F
				DEFM	"@ <b", $CF, "ary> ", $EB, "8", $F9, " value ", $CF, " ", $94, $D1, $F7, " ", $FA, "m.", $7F
				DEFM	"~ <", $F7, ">", $EB, "8/16", $F9, " value ", $CF, " ", $94, " ", $FA, "m.", $7F
				DEFM	"' <char>   ", $EB, $9D, " char ", $CF, " ", $94, $D1, "b", $CF, "ary ", $FA, "m.", $7F
				DEFM	'"', " <", $94, ">    ", $EB, "8", $F9, " ", $94, " value ", $CF, " ", $9D, " ", $FA, "m.", 0

.inf_execz80_help	DEFM	1, "2JN", 12
				DEFM	$81, ".", $81, " Execute next ", $CF, "struc", $CD, "(s) at (PC), moni", $DE, "red.", $7F
				DEFM	"  (", $EE, " depends on RTM ", $EC, " sett", $CE, "s)", $7F
				DEFM	$7F
				DEFM	$81, ".G", $81, " Release ", $C9, " moni", $DE, "r", $CE, $DF, "Z80 processor.", $7F
				DEFM	"   (", $A2, " processor ", $ED, "tes", $B3, $C9, " at full speed)", 0

.inf_rtmflags1_help	DEFM	1, "2JN", 12
				DEFM	"All ", $EC, "s c", $FD, $F1, $DE, "ggl", $DA, $81, "ON", $81, " (+) or ", $81, "OFF", $81, " (-). If a ", $EC, " ", $D4, "", $7F
				DEFM	$EF, "i", $DA, $D2, "out ", $F6, ", it", $DB, "be ", $CF, "v", $FE, "t", $DA, "from ", $A2, $7F
				DEFM	$E1, " state.", $7F
				DEFM	$81, ".S", $81, $EB, $E1, " ", $EC, " status.", $7F
				DEFM	$81, ".Z", $81, " ", $E5, $EB, "mnem.", $FF, "Z80 ", $CF, "struc", $CD, $DF, "be ", $ED, "ted.", $7F
				DEFM	$81, ".X", $81, " ", $E5, " ", $B1, " Z80 ", $EA, "s ", $FB, " ", $CF, "struc", $CD, " ", $EE, ".", $7F
				DEFM	"NB: Au", $DE, " d", $D4, "assembly may corrupt ", $C9, " ", $F3, "s.", 0

.inf_rtmflags2_help	DEFM	1, "2JN", 12
				DEFM	$81, ".K", $81, "  ", $E5, " Allow ", $EE, " break from keyboard", $D3, $86, $87, ".", $7F
				DEFM	$81, ".T", $81, "  ", $E5, " Trace mode (ON) / s", $CE, "le step mode (OFF).", $7F
				DEFM	$81, ".TS", $81, " ", $E5, " Trace until encount", $FE, $DA, "RET ", $CF, "struc", $CD, ".", 0

.inf_rtmflags3_help	DEFM	12
				DEFM	"All break features below (except ", $FA, " l", $D4, "t", $CE, " ", $BA, "s)", $7F
				DEFM	"activates", $B3, $BA, " l", $CF, "e when appropriate condi", $CD, "s", $7F
				DEFM	"become true (e.g. PC becomes equal", $DF, $FD, " ", $C2, " b.po", $CF, "t).", $7F
				DEFM	1, "2JN", $7F
				DEFM	$81, ".BI", $81, "  [<nn>] Break at ", $CF, "struc", $CD, " opcode <nn>.", $7F
				DEFM	"     Flag OFF, if no ", $94, " opcodes ", $EF, "ied. Opcodes ", $DC, $7F
				DEFM	"     ent", $FE, $DA, "as ", $94, " str", $CE, ", eg. E721 = RST 20h,[OS_BYE].", 0

.inf_rtmflags4_help	DEFM	1, "2JN", 12
				DEFM	$81, ".BIL", $81, "       L", $D4, "t ", $CF, "struc", $CD, " opcode str", $CE, ".", $7F
				DEFM	$81, ".BO", $81, "  ", $E5, " Break at OZ call ", $FE, "ror (return", $CE, " Fc = 1).", $7F
				DEFM	$81, ".B", $81, "   ", $E6, "  Toggle breakpo", $CF, "t ", $C2, ". ", $A5, " maximum 8.", $7F
				DEFM	$81, ".BL", $81, "        L", $D4, "t ", $A6, "d breakpo", $CF, "t ", $C2, "es.", $7F
				DEFM	$81, ".BD", $81, "  ", $E5, " ", $B1, " ", $EA, "s, d", $D4, "assemble, ", $A2, "n cont", $CF, "ue", $7F
				DEFM	"           ", $EE, ". Th", $D4, " affects all break features.", $7F
				DEFM	"           Execu", $CD, " ", $F8, " ", $A2, "n only", $F1, "s", $DE, "pped", $D3, 1, "B.K", 1, "B .", 0

.inf_z80dz_help	DEFM	1, "2JN", 12
				DEFM	$81, ".D", $81, " [", $E6, " [<b>]]", $7F
				DEFM	1, "2JC"
				DEFM	"D", $D4, "assemble from ", $E1, " PC or from ", $C2, " ", $E6, $7F
				DEFM	$CF, " logical ", $C2, " space.", $7F
				DEFM	"Ext", $FE, "nal ", $BC, "s may", $F1, "d", $D4, "assembl", $DA, $DE, "o by ", $EF, "y", $CE, " ", $FD, $7F
				DEFM	"absolute ", $BC, " numb", $FE, ". Fur", $A2, "r, ", $E6, " may", $F1, "set", $DF, $A2, $7F
				DEFM	$C2, " ", $F0, "fy", $CE, $B3, "segment ", $CF, $DE, " which", $B3, $BC, " ", $D4, "", $7F
				DEFM	"orig", $CF, "ally bound. Use ", $83, $DF, "allow 16 l", $CF, "es d", $D4, "assembly.", 0

.inf_memcmds1_help	DEFM	1, "2JN", 12
				DEFM	$C1, " ", $F6, "s ", $F0, "cal", $DF, "d", $D4, "assembly func", $CD, "ality.", $7F
				DEFM	"Use ", $83, $DF, "swap between ", $94, ", ", $9D, " ", $F3, ".", $7F
				DEFM	$81, ".MV", $81, " [", $E6, " [<b>]]  ", $9E, " ", $AA, " (local ", $AA, " or ext. ", $BC, ").", $7F
				DEFM	$81, ".ME", $81, " [", $E6, " [<b>]]  ", $A7, " ", $AA, ".", $7F
				DEFM	$81, ".VA", $81, " [", $E6, " [<b>]] ", $9E, " ", $C2, " words at ", $E6, " or ", $F4, " (SP).", $7F
				DEFM	$7F, $81, ".ML", $81, $E7, " Load Z80 ", $B5, "s at ", $F4, " 2000h, or ", $E6, ".", $7F
				DEFM	$81, ".MR", $81, $EB, "available cont", $CF, "ous ", $AA, " ", $AC, " ", $CF, " ", $E9, ".", 0

.inf_winman_help	DEFM	1, "2JN", 12
				DEFM	$7F, $81, ".V", $81, "       ", $9E, " ", $E1, " ", $C9, " ", $F3, "s.", $7F
				DEFM	$81, ".W", $81, $E8, " Set ", $E9, " ", $F3, " ID (6", $D5, $F4, ").", $7F
				DEFM	$81, ".WS", $81, "     ", $EB, $E1, " ", $C9, ", ", $E9, " ", $F3, " ID.", 0

.inf_misc_help		DEFM	1, "2JN", 12
				DEFM	$81, ".I", $81, "        ", $EB, $E9, " RTM ", $DC, "a", $D1, "v", $FE, "sion numb", $FE, ".", $7F
				DEFM	$81, ".NMA", $81, " <str> ", $A5, " ", $E9, " ", $C9, " name (au", $DE, "matically", $7F
				DEFM	"           ", $A6, "d by ", $81, ".ML", $81, ").", $7F
				DEFM	$81, ".KILL", $81, "      ", $E9, " ", $C9, " suicide, return", $DF, $8C, ".", 0

.inf_clilog_help	DEFM	12
				DEFM	"To enh", $FD, "ce debugg", $CE, ", a CLI screen-", $DE, "-", $CC, "-copy facility", $7F
				DEFM	"allows up", $DF, "256 diff", $FE, "ent log files", $DF, "be created.", $7F
				DEFM	"Press", $CE, " ", $81, $87, "-", $81, " ", $DE, "ggles", $B3, "CLI", $DF, "create files ", '"', "/log.0", '"', " -", $7F
				DEFM	'"', "/log.255", '"', " ", $CF, $B3, $E1, " RAM device. S", $CF, "ce ", $E9, $7F
				DEFM	"m", $FD, "ages", $B3, "CLI facility, it", $D5, "import", $FD, "t", $DF, $DE, "ggle", $B3, "CLI", $7F
				DEFM	$D2, " ", $81, $87, "-", $81, " only ", $CF, " ", $E9, ". St", $D0, "ard CLI ", $81, 1, SD_SQUA, "+S", $81, " screen", $7F
				DEFM	"copy may still", $F1, "used, but", $D5, "redund", $FD, "t.", 0

.inf_keyboard_help	DEFM	12
				DEFM	$E9, " uses st", $D0, "ard GN_SIP, OS_IN", $DF, "process ", $CF, "put.", $7F
				DEFM	"Th", $D4, " allows ", $C9, " switch", $CE, " while ", $E9, " has", $7F
				DEFM	"control. Howev", $FE, ", kill", $CE, " ", $E9, " must ", $F2, $F1, "taken", $7F
				DEFM	"lightly, s", $CF, "ce", $B3, "testcode could have open", $DA, "OZ resources.", $7F
				DEFM	$7F
				DEFM	$E9, " has two ", $F3, "s: use ", $83, $DF, $DE, "ggle between ", $F3, "s.", $7F
				DEFM	$8B, " resets ", $E1, " ", $BA, " l", $CF, "e. ", $88, " activates ", $BA, ".", 0

.Z80dbg_MTH_END
