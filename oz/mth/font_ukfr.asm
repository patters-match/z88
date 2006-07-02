; -----------------------------------------------------------------------------
; Bank 7 @ S2           ROM offset $1c000
;
; $Id$
; -----------------------------------------------------------------------------

; UK/FR LORES1 / HIRES1 font bitmap, with integrated system Token Table

; Token table, integrated into bits 7,6 of the lores1 font bitmap:
;
; .token_base
;         defb $80 ; recursive token boundary
;         defb $80 ; number of tokens
;         defw token80-token_base
;         defw token81-token_base
;         defw token82-token_base
;         defw token83-token_base
;         defw token84-token_base
;         defw token85-token_base
;         defw token86-token_base
;         defw token87-token_base
;         defw token88-token_base
;         defw token89-token_base
;         defw token8A-token_base
;         defw token8B-token_base
;         defw token8C-token_base
;         defw token8D-token_base
;         defw token8E-token_base
;         defw token8F-token_base
;         defw token90-token_base
;         defw token91-token_base
;         defw token92-token_base
;         defw token93-token_base
;         defw token94-token_base
;         defw token95-token_base
;         defw token96-token_base
;         defw token97-token_base
;         defw token98-token_base
;         defw token99-token_base
;         defw token9A-token_base
;         defw token9B-token_base
;         defw token9C-token_base
;         defw token9D-token_base
;         defw token9E-token_base
;         defw token9F-token_base
;         defw tokenA0-token_base
;         defw tokenA1-token_base
;         defw tokenA2-token_base
;         defw tokenA3-token_base
;         defw tokenA4-token_base
;         defw tokenA5-token_base
;         defw tokenA6-token_base
;         defw tokenA7-token_base
;         defw tokenA8-token_base
;         defw tokenA9-token_base
;         defw tokenAA-token_base
;         defw tokenAB-token_base
;         defw tokenAC-token_base
;         defw tokenAD-token_base
;         defw tokenAE-token_base
;         defw tokenAF-token_base
;         defw tokenB0-token_base
;         defw tokenB1-token_base
;         defw tokenB2-token_base
;         defw tokenB3-token_base
;         defw tokenB4-token_base
;         defw tokenB5-token_base
;         defw tokenB6-token_base
;         defw tokenB7-token_base
;         defw tokenB8-token_base
;         defw tokenB9-token_base
;         defw tokenBA-token_base
;         defw tokenBB-token_base
;         defw tokenBC-token_base
;         defw tokenBD-token_base
;         defw tokenBE-token_base
;         defw tokenBF-token_base
;         defw tokenC0-token_base
;         defw tokenC1-token_base
;         defw tokenC2-token_base
;         defw tokenC3-token_base
;         defw tokenC4-token_base
;         defw tokenC5-token_base
;         defw tokenC6-token_base
;         defw tokenC7-token_base
;         defw tokenC8-token_base
;         defw tokenC9-token_base
;         defw tokenCA-token_base
;         defw tokenCB-token_base
;         defw tokenCC-token_base
;         defw tokenCD-token_base
;         defw tokenCE-token_base
;         defw tokenCF-token_base
;         defw tokenD0-token_base
;         defw tokenD1-token_base
;         defw tokenD2-token_base
;         defw tokenD3-token_base
;         defw tokenD4-token_base
;         defw tokenD5-token_base
;         defw tokenD6-token_base
;         defw tokenD7-token_base
;         defw tokenD8-token_base
;         defw tokenD9-token_base
;         defw tokenDA-token_base
;         defw tokenDB-token_base
;         defw tokenDC-token_base
;         defw tokenDD-token_base
;         defw tokenDE-token_base
;         defw tokenDF-token_base
;         defw tokenE0-token_base
;         defw tokenE1-token_base
;         defw tokenE2-token_base
;         defw tokenE3-token_base
;         defw tokenE4-token_base
;         defw tokenE5-token_base
;         defw tokenE6-token_base
;         defw tokenE7-token_base
;         defw tokenE8-token_base
;         defw tokenE9-token_base
;         defw tokenEA-token_base
;         defw tokenEB-token_base
;         defw tokenEC-token_base
;         defw tokenED-token_base
;         defw tokenEE-token_base
;         defw tokenEF-token_base
;         defw tokenF0-token_base
;         defw tokenF1-token_base
;         defw tokenF2-token_base
;         defw tokenF3-token_base
;         defw tokenF4-token_base
;         defw tokenF5-token_base
;         defw tokenF6-token_base
;         defw tokenF7-token_base
;         defw tokenF8-token_base
;         defw tokenF9-token_base
;         defw tokenFA-token_base
;         defw tokenFB-token_base
;         defw tokenFC-token_base
;         defw tokenFD-token_base
;         defw tokenFE-token_base
;         defw tokenFF-token_base
;         defw end_tokens-token_base
; .token80
;         defm $01, "T"
; .token81
;         defm "Cursor "
; .token82
;         defm "e "
; .token83
;         defm " returns "
; .token84
;         defm "t "
; .token85
;         defm "in"
; .token86
;         defm "er"
; .token87
;         defm "tion"
; .token88
;         defm "th"
; .token89
;         defm "of "
; .token8A
;         defm "olumn"
; .token8B
;         defm "le"
; .token8C
;         defm "ar"
; .token8D
;         defm "re"
; .token8E
;         defm "s "
; .token8F
;         defm "or"
; .token90
;         defm "ig"
; .token91
;         defm "at"
; .token92
;         defm $88, $82
; .token93
;         defm "an"
; .token94
;         defm $8E, "Limited 1987,88", $7F, "Copyr", $90, "h", $84, "(C) "
; .token95
;         defm "al"
; .token96
;         defm "De", $8B, "t", $82
; .token97
;         defm "Nex", $84
; .token98
;         defm "P", $8D, "viou", $8E
; .token99
;         defm "h", $8C, "act", $86
; .token9A
;         defm ".", $7F
; .token9B
;         defm "Ins", $86
; .token9C
;         defm "Func", $87
; .token9D
;         defm "ow"
; .token9E
;         defm "to"
; .token9F
;         defm "radi", $93, "s"
; .tokenA0
;         defm "list"
; .tokenA1
;         defm "numb", $86, " "
; .tokenA2
;         defm "en"
; .tokenA3
;         defm $85, " "
; .tokenA4
;         defm ", "
; .tokenA5
;         defm "lo"
; .tokenA6
;         defm "Fi"
; .tokenA7
;         defm $81, "R", $90, "ht"
; .tokenA8
;         defm $81, "Left"
; .tokenA9
;         defm "L", $85, "e"
; .tokenAA
;         defm ": "
; .tokenAB
;         defm "Co"
; .tokenAC
;         defm "D", $9D, "n"
; .tokenAD
;         defm "Activ", $82, "Day"
; .tokenAE
;         defm ")", $83, $92
; .tokenAF
;         defm "te"
; .tokenB0
;         defm '"', $9A
; .tokenB1
;         defm "ESCAPE"
; .tokenB2
;         defm "d "
; .tokenB3
;         defm "v", $95, "u"
; .tokenB4
;         defm "ch"
; .tokenB5
;         defm "C", $8A
; .tokenB6
;         defm "Di", $8D, "ct", $8F, "y"
; .tokenB7
;         defm " i", $8E
; .tokenB8
;         defm "Logic", $95, " "
; .tokenB9
;         defm "Up"
; .tokenBA
;         defm $A6, $8B
; .tokenBB
;         defm $9E, " "
; .tokenBC
;         defm "on"
; .tokenBD
;         defm "Sav"
; .tokenBE
;         defm $82, "Posi", $87
; .tokenBF
;         defm "Op"
; .tokenC0
;         defm $85, "g "
; .tokenC1
;         defm "(n"
; .tokenC2
;         defm $89, '"', "n"
; .tokenC3
;         defm $91, "e"
; .tokenC4
;         defm $AB, "l", $9E, "n Softw", $8C, $82, "Limi", $AF
; .tokenC5
;         defm "B", $A5, "ck"
; .tokenC6
;         defm "ur"
; .tokenC7
;         defm "e", $8B
; .tokenC8
;         defm "Re"
; .tokenC9
;         defm "ce"
; .tokenCA
;         defm "s", $84
; .tokenCB
;         defm $9B, $84
; .tokenCC
;         defm $90, "h"
; .tokenCD
;         defm "cos", $85, "e", $A4, "s", $85, $82, $8F, " t", $93, "g", $A2, $84
; .tokenCE
;         defm ". "
; .tokenCF
;         defm "s", $A5, "t", $8E, $A3, '"', $A0, $B0
; .tokenD0
;         defm " ", $A1, $A3, "whi", $B4, " i", $84, "i", $8E, "e", $B3, $C3, "d"
; .tokenD1
;         defm "Al", $90, "n"
; .tokenD2
;         defm "ENTER"
; .tokenD3
;         defm "W", $8F, "d"
; .tokenD4
;         defm "Sc", $8D, $A2, " "
; .tokenD5
;         defm "qu", $95, " ", $9E
; .tokenD6
;         defm "y "
; .tokenD7
;         defm "m "
; .tokenD8
;         defm $AB, "mm", $93, "ds"
; .tokenD9
;         defm "pl"
; .tokenDA
;         defm $81, $B9
; .tokenDB
;         defm $81, $AC
; .tokenDC
;         defm "C", $C6, "s", $8F
; .tokenDD
;         defm "M", $8C
; .tokenDE
;         defm $AB, "py"
; .tokenDF
;         defm "En", $B2, $89
; .tokenE0
;         defm "Rubout"
; .tokenE1
;         defm "Load"
; .tokenE2
;         defm "ra"
; .tokenE3
;         defm "S", $C7, "c", $84
; .tokenE4
;         defm "de"
; .tokenE5
;         defm "(", $A0, ")"
; .tokenE6
;         defm $B3, $82
; .tokenE7
;         defm "r", $93, "ge"
; .tokenE8
;         defm "Ex"
; .tokenE9
;         defm "C", $99
; .tokenEA
;         defm $9B, "t/Ov", $86, "type"
; .tokenEB
;         defm "se"
; .tokenEC
;         defm $BF, $87
; .tokenED
;         defm "am"
; .tokenEE
;         defm "EPROM"
; .tokenEF
;         defm $86, " "
; .tokenF0
;         defm $7F, $8D, "t", $C6, "n"
; .tokenF1
;         defm $E4, "g", $8D, "es"
; .tokenF2
;         defm '"', " c", $BC, "v", $86, $AF, $B2, $85, $BB
; .tokenF3
;         defm $E5, $B7, "i", $AF, $D7, "wi", $88, " m"
; .tokenF4
;         defm $A3, '"'
; .tokenF5
;         defm "d", $C3
; .tokenF6
;         defm $BF, $86, $91, $8F, "s"
; .tokenF7
;         defm "M", $91, $B4
; .tokenF8
;         defm $A6, "r", $CA
; .tokenF9
;         defm "(", $9F, ")"
; .tokenFA
;         defm "S", $A5, "t"
; .tokenFB
;         defm "ay"
; .tokenFC
;         defm "it"
; .tokenFD
;         defm $BA, "s"
; .tokenFE
;         defm "Pr", $85, "t"
; .tokenFF
;         defm "Swap Ca", $EB
; .end_tokens


; Char entry $0000 (offset $0000)
;
;
;
;
;
;
;
;
defb @10000000
defb @00000000
defb @00000000
defb @00000000
defb @10000000
defb @00000000
defb @00000000
defb @00000000


; Char entry $0001 (offset $0008)
;
;      #
;      ##
;   ######
;      ##
;      #
;
;
defb @00000000
defb @00000100
defb @01000110
defb @00111111
defb @00000110
defb @00000100
defb @00000000
defb @01000000


; Char entry $0002 (offset $0010)
;
;      #
;      #
;      #
;    #####
;     ###
;      #
;
defb @00000000
defb @00000100
defb @01000100
defb @10000100
defb @00011111
defb @00001110
defb @00000100
defb @01000000


; Char entry $0003 (offset $0018)
;
;
;
;      ###
;      #
;      #
;      #
;      #
defb @00000000
defb @00000000
defb @11000000
defb @01000111
defb @00000100
defb @00000100
defb @00000100
defb @01000100


; Char entry $0004 (offset $0020)
;
;     #
;    ##
;   ######
;    ##
;     #
;
;
defb @00000000
defb @00001000
defb @11011000
defb @11111111
defb @00011000
defb @00001000
defb @00000000
defb @01000000


; Char entry $0005 (offset $0028)
;
;
;
;   ######
;
;
;
;
defb @00000000
defb @01000000
defb @10000000
defb @00111111
defb @00000000
defb @00000000
defb @00000000
defb @01000000


; Char entry $0006 (offset $0030)
;
;
;
;   ####
;      #
;      #
;      #
;      #
defb @00000000
defb @01000000
defb @10000000
defb @10111100
defb @00000100
defb @00000100
defb @00000100
defb @01000100


; Char entry $0007 (offset $0038)
;
;
;
;   ######
;      #
;      #
;      #
;      #
defb @00000000
defb @01000000
defb @11000000
defb @00111111
defb @00000100
defb @00000100
defb @00000100
defb @01000100


; Char entry $0008 (offset $0040)
;
;      #
;     ###
;    #####
;      #
;      #
;      #
;
defb @00000000
defb @01000100
defb @11001110
defb @10011111
defb @00000100
defb @00000100
defb @00000100
defb @01000000


; Char entry $0009 (offset $0048)
;      #
;      #
;      #
;      ###
;
;
;
;
defb @00000100
defb @10000100
defb @00000100
defb @10000111
defb @00000000
defb @00000000
defb @00000000
defb @01000000


; Char entry $000A (offset $0050)
;      #
;      #
;      #
;      #
;      #
;      #
;      #
;      #
defb @00000100
defb @10000100
defb @01000100
defb @00000100
defb @00000100
defb @00000100
defb @00000100
defb @01000100


; Char entry $000B (offset $0058)
;      #
;      #
;      #
;      ###
;      #
;      #
;      #
;      #
defb @00000100
defb @10000100
defb @01000100
defb @11000111
defb @00000100
defb @00000100
defb @00000100
defb @01000100


; Char entry $000C (offset $0060)
;      #
;      #
;      #
;   ####
;
;
;
;
defb @00000100
defb @10000100
defb @11000100
defb @00111100
defb @00000000
defb @00000000
defb @00000000
defb @01000000


; Char entry $000D (offset $0068)
;      #
;      #
;      #
;   ######
;
;
;
;
defb @00000100
defb @10000100
defb @11000100
defb @10111111
defb @00000000
defb @00000000
defb @00000000
defb @01000000


; Char entry $000E (offset $0070)
;      #
;      #
;      #
;   ####
;      #
;      #
;      #
;      #
defb @00000100
defb @11000100
defb @00000100
defb @00111100
defb @00000100
defb @00000100
defb @00000100
defb @01000100


; Char entry $000F (offset $0078)
;      #
;      #
;      #
;   ######
;      #
;      #
;      #
;      #
defb @00000100
defb @11000100
defb @00000100
defb @10111111
defb @00000100
defb @00000100
defb @00000100
defb @01000100


; Char entry $0010 (offset $0080)
;
;      #
;     # #
;    #   #
;     # #
;      #
;
;
defb @00000000
defb @11000100
defb @01001010
defb @00010001
defb @00001010
defb @00000100
defb @00000000
defb @01000000


; Char entry $0011 (offset $0088)
;
;    #####
;    #   #
;    #   #
;    #   #
;    #####
;
;
defb @00000000
defb @11011111
defb @01010001
defb @10010001
defb @00010001
defb @00011111
defb @00000000
defb @01000000


; Char entry $0012 (offset $0090)
;      ##
;     ###
;    ####
;   #####
;    ####
;     ###
;      ##
;
defb @00000110
defb @11001110
defb @10011110
defb @00111110
defb @00011110
defb @00001110
defb @00000110
defb @01000000


; Char entry $0013 (offset $0098)
;    ##
;    ###
;    ####
;    #####
;    ####
;    ###
;    ##
;
defb @00011000
defb @11011100
defb @10011110
defb @10011111
defb @00011110
defb @00011100
defb @00011000
defb @01000000


; Char entry $0014 (offset $00A0)
;
;        #
;       #
;      #
;       #
;        #
;
;
defb @00000000
defb @11000001
defb @11000010
defb @00000100
defb @00000010
defb @00000001
defb @00000000
defb @01000000


; Char entry $0015 (offset $00A8)
;   #
;   #
;   ####
;      #
;   ####
;   #
;   #
;
defb @00100000
defb @11100000
defb @11111100
defb @10000100
defb @00111100
defb @00100000
defb @00100000
defb @01000000


; Char entry $0016 (offset $00B0)
;
;
;      ###
;      #
;      ###
;
;
;
defb @01000000
defb @01000000
defb @10000111
defb @11000100
defb @00000111
defb @00000000
defb @00000000
defb @01000000


; Char entry $0017 (offset $00B8)
;   #
;   ##
;   # #
;      #
;   # #
;   ##
;   #
;
defb @01100000
defb @01110000
defb @11101000
defb @01000100
defb @00101000
defb @00110000
defb @00100000
defb @01000000


; Char entry $0018 (offset $00C0)
;     #
;      #
;    #  #
;    #  #
;    #  #
;    #  #
;     ###
;
defb @01001000
defb @10000100
defb @00010010
defb @10010010
defb @00010010
defb @00010010
defb @00001110
defb @01000000


; Char entry $0019 (offset $00C8)
;     ##
;    #  #
;     ##
;       #
;     ###
;    #  #
;     ###
;
defb @01001100
defb @10010010
defb @01001100
defb @10000010
defb @00001110
defb @00010010
defb @00001110
defb @01000000


; Char entry $001A (offset $00D0)
;     ##
;    #  #
;     ##
;    #  #
;    ####
;    #
;     ##
;
defb @01001100
defb @10010010
defb @11001100
defb @01010010
defb @00011110
defb @00010000
defb @00001100
defb @01000000


; Char entry $001B (offset $00D8)
;      #
;       #
;     ##
;       #
;     ###
;    #  #
;     ###
;
defb @01000100
defb @11000010
defb @00001100
defb @11000010
defb @00001110
defb @00010010
defb @00001110
defb @01000000


; Char entry $001C (offset $00E0)
;      #
;       #
;     ##
;    #  #
;    ####
;    #
;     ##
;
defb @01000100
defb @11000010
defb @01001100
defb @01010010
defb @00011110
defb @00010000
defb @00001100
defb @01000000


; Char entry $001D (offset $00E8)
;     #
;    #
;     ##
;    #  #
;    ####
;    #
;     ##
;
defb @01001000
defb @11010000
defb @10001100
defb @01010010
defb @00011110
defb @00010000
defb @00001100
defb @01000000


; Char entry $001E (offset $00F0)
;
;
;     ###
;    #
;    #
;     ###
;      #
;     ##
defb @01000000
defb @11000000
defb @11001110
defb @10010000
defb @00010000
defb @00001110
defb @00000100
defb @01001100


; Char entry $001F (offset $00F8)
;      ##
;     #  #
;     #
;    ###
;     #
;     #
;    #####
;
defb @10000110
defb @00001001
defb @00001000
defb @00011100
defb @00001000
defb @00001000
defb @00011111
defb @01000000


; Char entry $0020 (offset $0100)
;     ###
;    #   #
;   ####
;    #
;   ####
;    #   #
;     ###
;
defb @10001110
defb @00010001
defb @00111100
defb @10010000
defb @00111100
defb @00010001
defb @00001110
defb @01000000


; Char entry $0021 (offset $0108)
;      #
;      #
;      #
;      #
;
;
;      #
;
defb @10000100
defb @00000100
defb @10000100
defb @00000100
defb @00000000
defb @00000000
defb @00000100
defb @01000000


; Char entry $0022 (offset $0110)
;     # #
;     # #
;     # #
;
;
;
;
;
defb @10001010
defb @00001010
defb @11001010
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @01000000


; Char entry $0023 (offset $0118)
;     # #
;     # #
;    #####
;     # #
;    #####
;     # #
;     # #
;
defb @10001010
defb @01001010
defb @00011111
defb @10001010
defb @00011111
defb @00001010
defb @00001010
defb @01000000


; Char entry $0024 (offset $0120)
;      #
;     ####
;    # #
;     ###
;      # #
;    ####
;      #
;
defb @10000100
defb @01001111
defb @01010100
defb @00001110
defb @00000101
defb @00011110
defb @00000100
defb @01000000


; Char entry $0025 (offset $0128)
;    ##
;    ##  #
;       #
;      #
;     #
;    #  ##
;       ##
;
defb @10011000
defb @01011001
defb @01000010
defb @10000100
defb @00001000
defb @00010011
defb @00000011
defb @01000000


; Char entry $0026 (offset $0130)
;      #
;     # #
;     # #
;     ##
;    # # #
;    #  #
;     ## #
;
defb @10000100
defb @01001010
defb @10001010
defb @00001100
defb @00010101
defb @00010010
defb @00001101
defb @01000000


; Char entry $0027 (offset $0138)
;       #
;      #
;     #
;
;
;
;
;
defb @10000010
defb @01000100
defb @10001000
defb @10000000
defb @00000000
defb @00000000
defb @00000000
defb @01000000


; Char entry $0028 (offset $0140)
;       #
;      #
;     #
;     #
;     #
;      #
;       #
;
defb @10000010
defb @01000100
defb @11001000
defb @00001000
defb @00001000
defb @00000100
defb @00000010
defb @01000000


; Char entry $0029 (offset $0148)
;    #
;     #
;      #
;      #
;      #
;     #
;    #
;
defb @10010000
defb @10001000
defb @00000100
defb @01000100
defb @00000100
defb @00001000
defb @00010000
defb @01000000


; Char entry $002A (offset $0150)
;
;      #
;    # # #
;     ###
;    # # #
;      #
;
;
defb @10000000
defb @10000100
defb @01010101
defb @10001110
defb @00010101
defb @00000100
defb @00000000
defb @01000000


; Char entry $002B (offset $0158)
;
;      #
;      #
;    #####
;      #
;      #
;
;
defb @10000000
defb @10000100
defb @10000100
defb @01011111
defb @00000100
defb @00000100
defb @00000000
defb @01000000


; Char entry $002C (offset $0160)
;
;
;
;
;
;      #
;      #
;     #
defb @10000000
defb @10000000
defb @10000000
defb @11000000
defb @00000000
defb @00000100
defb @00000100
defb @01001000


; Char entry $002D (offset $0168)
;
;
;
;    #####
;
;
;
;
defb @10000000
defb @10000000
defb @11000000
defb @01011111
defb @00000000
defb @00000000
defb @00000000
defb @01000000


; Char entry $002E (offset $0170)
;
;
;
;
;
;      #
;      #
;
defb @10000000
defb @11000000
defb @00000000
defb @00000000
defb @00000000
defb @00000100
defb @00000100
defb @01000000


; Char entry $002F (offset $0178)
;
;        #
;       #
;      #
;     #
;    #
;
;
defb @10000000
defb @11000001
defb @10000010
defb @01000100
defb @00001000
defb @00010000
defb @00000000
defb @01000000


; Char entry $0030 (offset $0180)
;     ###
;    #   #
;    #  ##
;    # # #
;    ##  #
;    #   #
;     ###
;
defb @10001110
defb @11010001
defb @11010011
defb @00010101
defb @00011001
defb @00010001
defb @00001110
defb @01000000


; Char entry $0031 (offset $0188)
;      #
;     ##
;      #
;      #
;      #
;      #
;      #
;
defb @10000100
defb @11001100
defb @11000100
defb @10000100
defb @00000100
defb @00000100
defb @00000100
defb @01000000


; Char entry $0032 (offset $0190)
;     ###
;    #   #
;        #
;       #
;      #
;     #
;    #####
;
defb @11001110
defb @00010001
defb @00000001
defb @00000010
defb @00000100
defb @00001000
defb @00011111
defb @01000000


; Char entry $0033 (offset $0198)
;    #####
;       #
;      #
;       #
;        #
;    #   #
;     ###
;
defb @11011111
defb @00000010
defb @01000100
defb @10000010
defb @00000001
defb @00010001
defb @00001110
defb @01000000


; Char entry $0034 (offset $01A0)
;       #
;      ##
;     # #
;    #  #
;    #####
;       #
;       #
;
defb @11000010
defb @00000110
defb @10001010
defb @00010010
defb @00011111
defb @00000010
defb @00000010
defb @01000000


; Char entry $0035 (offset $01A8)
;    #####
;    #
;    ####
;        #
;        #
;    #   #
;     ###
;
defb @11011111
defb @00010000
defb @10011110
defb @11000001
defb @00000001
defb @00010001
defb @00001110
defb @01000000


; Char entry $0036 (offset $01B0)
;      ##
;     #
;    #
;    ####
;    #   #
;    #   #
;     ###
;
defb @11000110
defb @00001000
defb @11010000
defb @01011110
defb @00010001
defb @00010001
defb @00001110
defb @01000000


; Char entry $0037 (offset $01B8)
;    #####
;        #
;       #
;      #
;     #
;     #
;     #
;
defb @11011111
defb @00000001
defb @11000010
defb @11000100
defb @00001000
defb @00001000
defb @00001000
defb @01000000


; Char entry $0038 (offset $01C0)
;     ###
;    #   #
;    #   #
;     ###
;    #   #
;    #   #
;     ###
;
defb @11001110
defb @01010001
defb @01010001
defb @10001110
defb @00010001
defb @00010001
defb @00001110
defb @01000000


; Char entry $0039 (offset $01C8)
;     ###
;    #   #
;    #   #
;     ####
;        #
;       #
;     ##
;
defb @11001110
defb @01010001
defb @10010001
defb @01001111
defb @00000001
defb @00000010
defb @00001100
defb @01000000


; Char entry $003A (offset $01D0)
;
;
;      #
;      #
;
;      #
;      #
;
defb @11000000
defb @10000000
defb @00000100
defb @00000100
defb @00000000
defb @00000100
defb @00000100
defb @01000000


; Char entry $003B (offset $01D8)
;
;
;      #
;      #
;
;      #
;      #
;     #
defb @11000000
defb @10000000
defb @00000100
defb @10000100
defb @00000000
defb @00000100
defb @00000100
defb @01001000


; Char entry $003C (offset $01E0)
;       #
;      #
;     #
;    #
;     #
;      #
;       #
;
defb @11000010
defb @10000100
defb @01001000
defb @00010000
defb @00001000
defb @00000100
defb @00000010
defb @01000000


; Char entry $003D (offset $01E8)
;
;
;    #####
;
;    #####
;
;
;
defb @11000000
defb @10000000
defb @01011111
defb @10000000
defb @00011111
defb @00000000
defb @00000000
defb @01000000


; Char entry $003E (offset $01F0)
;     #
;      #
;       #
;        #
;       #
;      #
;     #
;
defb @11001000
defb @10000100
defb @10000010
defb @00000001
defb @00000010
defb @00000100
defb @00001000
defb @01000000


; Char entry $003F (offset $01F8)
;     ###
;    #   #
;       #
;      #
;      #
;
;      #
;
defb @11001110
defb @10010001
defb @10000010
defb @11000100
defb @00000100
defb @00000000
defb @00000100
defb @01000000


; Char entry $0040 (offset $0200)
;     ###
;    #   #
;    # ###
;    # # #
;    # ###
;    #
;     ###
;
defb @11001110
defb @11010001
defb @00010111
defb @01010101
defb @00010111
defb @00010000
defb @00001110
defb @01000000


; Char entry $0041 (offset $0208)
;     ###
;    #   #
;    #   #
;    #####
;    #   #
;    #   #
;    #   #
;
defb @11001110
defb @11010001
defb @00010001
defb @11011111
defb @00010001
defb @00010001
defb @00010001
defb @01000000


; Char entry $0042 (offset $0210)
;    ####
;    #   #
;    #   #
;    ####
;    #   #
;    #   #
;    ####
;
defb @11011110
defb @11010001
defb @01010001
defb @10011110
defb @00010001
defb @00010001
defb @00011110
defb @01000000


; Char entry $0043 (offset $0218)
;     ###
;    #   #
;    #
;    #
;    #
;    #   #
;     ###
;
defb @11001110
defb @11010001
defb @10010000
defb @00010000
defb @00010000
defb @00010001
defb @00001110
defb @01000000


; Char entry $0044 (offset $0220)
;    ###
;    #  #
;    #   #
;    #   #
;    #   #
;    #  #
;    ###
;
defb @11011100
defb @11010010
defb @10010001
defb @11010001
defb @00010001
defb @00010010
defb @00011100
defb @01000000


; Char entry $0045 (offset $0228)
;    #####
;    #
;    #
;    ####
;    #
;    #
;    #####
;
defb @11011111
defb @11010000
defb @11010000
defb @01011110
defb @00010000
defb @00010000
defb @00011111
defb @01000000


; Char entry $0046 (offset $0230)
;    #####
;    #
;    #
;    ####
;    #
;    #
;    #
;
defb @00011111
defb @00010000
defb @11010000
defb @10011110
defb @00010000
defb @00010000
defb @00010000
defb @10000000


; Char entry $0047 (offset $0238)
;     ####
;    #
;    #
;    #  ##
;    #   #
;    #   #
;     ####
;
defb @00001111
defb @01010000
defb @00010000
defb @10010011
defb @00010001
defb @00010001
defb @00001111
defb @10000000


; Char entry $0048 (offset $0240)
;    #   #
;    #   #
;    #   #
;    #####
;    #   #
;    #   #
;    #   #
;
defb @00010001
defb @01010001
defb @01010001
defb @00011111
defb @00010001
defb @00010001
defb @00010001
defb @10000000


; Char entry $0049 (offset $0248)
;     ###
;      #
;      #
;      #
;      #
;      #
;     ###
;
defb @00001110
defb @01000100
defb @01000100
defb @10000100
defb @00000100
defb @00000100
defb @00001110
defb @10000000


; Char entry $004A (offset $0250)
;     ####
;       #
;       #
;       #
;       #
;    #  #
;     ##
;
defb @00001111
defb @01000010
defb @10000010
defb @00000010
defb @00000010
defb @00010010
defb @00001100
defb @10000000


; Char entry $004B (offset $0258)
;    #   #
;    #  #
;    # #
;    ##
;    # #
;    #  #
;    #   #
;
defb @00010001
defb @01010010
defb @10010100
defb @10011000
defb @00010100
defb @00010010
defb @00010001
defb @10000000


; Char entry $004C (offset $0260)
;    #
;    #
;    #
;    #
;    #
;    #
;    #####
;
defb @00010000
defb @01010000
defb @11010000
defb @00010000
defb @00010000
defb @00010000
defb @00011111
defb @10000000


; Char entry $004D (offset $0268)
;    #   #
;    ## ##
;    # # #
;    # # #
;    #   #
;    #   #
;    #   #
;
defb @00010001
defb @01011011
defb @11010101
defb @10010101
defb @00010001
defb @00010001
defb @00010001
defb @10000000


; Char entry $004E (offset $0270)
;    #   #
;    #   #
;    ##  #
;    # # #
;    #  ##
;    #   #
;    #   #
;
defb @00010001
defb @10010001
defb @00011001
defb @00010101
defb @00010011
defb @00010001
defb @00010001
defb @10000000


; Char entry $004F (offset $0278)
;     ###
;    #   #
;    #   #
;    #   #
;    #   #
;    #   #
;     ###
;
defb @00001110
defb @11010001
defb @00010001
defb @00010001
defb @00010001
defb @00010001
defb @00001110
defb @10000000


; Char entry $0050 (offset $0280)
;    ####
;    #   #
;    #   #
;    ####
;    #
;    #
;    #
;
defb @00011110
defb @11010001
defb @00010001
defb @10011110
defb @00010000
defb @00010000
defb @00010000
defb @10000000


; Char entry $0051 (offset $0288)
;     ###
;    #   #
;    #   #
;    #   #
;    # # #
;    #  #
;     ## #
;
defb @00001110
defb @11010001
defb @10010001
defb @10010001
defb @00010101
defb @00010010
defb @00001101
defb @10000000


; Char entry $0052 (offset $0290)
;    ####
;    #   #
;    #   #
;    ####
;    # #
;    #  #
;    #   #
;
defb @01011110
defb @00010001
defb @10010001
defb @10011110
defb @00010100
defb @00010010
defb @00010001
defb @10000000


; Char entry $0053 (offset $0298)
;     ####
;    #
;    #
;     ###
;        #
;        #
;    ####
;
defb @01001111
defb @00010000
defb @11010000
defb @10001110
defb @00000001
defb @00000001
defb @00011110
defb @10000000


; Char entry $0054 (offset $02A0)
;    #####
;      #
;      #
;      #
;      #
;      #
;      #
;
defb @01011111
defb @01000100
defb @00000100
defb @11000100
defb @00000100
defb @00000100
defb @00000100
defb @10000000


; Char entry $0055 (offset $02A8)
;    #   #
;    #   #
;    #   #
;    #   #
;    #   #
;    #   #
;     ###
;
defb @01010001
defb @01010001
defb @01010001
defb @10010001
defb @00010001
defb @00010001
defb @00001110
defb @10000000


; Char entry $0056 (offset $02B0)
;    #   #
;    #   #
;    #   #
;    #   #
;    #   #
;     # #
;      #
;
defb @01010001
defb @01010001
defb @10010001
defb @11010001
defb @00010001
defb @00001010
defb @00000100
defb @10000000


; Char entry $0057 (offset $02B8)
;    #   #
;    #   #
;    #   #
;    # # #
;    # # #
;    # # #
;     # #
;
defb @01010001
defb @10010001
defb @00010001
defb @00010101
defb @00010101
defb @00010101
defb @00001010
defb @10000000


; Char entry $0058 (offset $02C0)
;    #   #
;    #   #
;     # #
;      #
;     # #
;    #   #
;    #   #
;
defb @01010001
defb @10010001
defb @00001010
defb @10000100
defb @00001010
defb @00010001
defb @00010001
defb @10000000


; Char entry $0059 (offset $02C8)
;    #   #
;    #   #
;    #   #
;     # #
;      #
;      #
;      #
;
defb @01010001
defb @10010001
defb @01010001
defb @00001010
defb @00000100
defb @00000100
defb @00000100
defb @10000000


; Char entry $005A (offset $02D0)
;    #####
;        #
;       #
;      #
;     #
;    #
;    #####
;
defb @01011111
defb @10000001
defb @10000010
defb @10000100
defb @00001000
defb @00010000
defb @00011111
defb @10000000


; Char entry $005B (offset $02D8)
;     ###
;     #
;     #
;     #
;     #
;     #
;     ###
;
defb @01001110
defb @10001000
defb @11001000
defb @00001000
defb @00001000
defb @00001000
defb @00001110
defb @10000000


; Char entry $005C (offset $02E0)
;
;    #
;     #
;      #
;       #
;        #
;
;
defb @01000000
defb @10010000
defb @11001000
defb @10000100
defb @00000010
defb @00000001
defb @00000000
defb @10000000


; Char entry $005D (offset $02E8)
;    ###
;      #
;      #
;      #
;      #
;      #
;    ###
;
defb @01011100
defb @11000100
defb @00000100
defb @00000100
defb @00000100
defb @00000100
defb @00011100
defb @10000000


; Char entry $005E (offset $02F0)
;      #
;     # #
;    #   #
;
;
;
;
;
defb @01000100
defb @11001010
defb @01010001
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @10000000


; Char entry $005F (offset $02F8)
;
;
;
;
;
;
;   ######
;
defb @01000000
defb @11000000
defb @01000000
defb @10000000
defb @00000000
defb @00000000
defb @00111111
defb @10000000


; Char entry $0060 (offset $0300)
;     #
;      #
;       #
;
;
;
;
;
defb @01001000
defb @11000100
defb @10000010
defb @01000000
defb @00000000
defb @00000000
defb @00000000
defb @10000000


; Char entry $0061 (offset $0308)
;
;
;     ##
;       #
;     ###
;    #  #
;     ###
;
defb @01000000
defb @11000000
defb @11001100
defb @01000010
defb @00001110
defb @00010010
defb @00001110
defb @10000000


; Char entry $0062 (offset $0310)
;    #
;    #
;    ###
;    #  #
;    #  #
;    #  #
;    ###
;
defb @10010000
defb @00010000
defb @00011100
defb @11010010
defb @00010010
defb @00010010
defb @00011100
defb @10000000


; Char entry $0063 (offset $0318)
;
;
;     ###
;    #
;    #
;    #
;     ###
;
defb @10000000
defb @00000000
defb @01001110
defb @11010000
defb @00010000
defb @00010000
defb @00001110
defb @10000000


; Char entry $0064 (offset $0320)
;       #
;       #
;     ###
;    #  #
;    #  #
;    #  #
;     ###
;
defb @10000010
defb @00000010
defb @10001110
defb @01010010
defb @00010010
defb @00010010
defb @00001110
defb @10000000


; Char entry $0065 (offset $0328)
;
;
;     ##
;    #  #
;    ####
;    #
;     ##
;
defb @10000000
defb @00000000
defb @11001100
defb @01010010
defb @00011110
defb @00010000
defb @00001100
defb @10000000


; Char entry $0066 (offset $0330)
;      #
;     # #
;     #
;    ###
;     #
;     #
;     #
;
defb @10000100
defb @00001010
defb @11001000
defb @11011100
defb @00001000
defb @00001000
defb @00001000
defb @10000000


; Char entry $0067 (offset $0338)
;
;
;     ##
;    #  #
;    #  #
;     ###
;       #
;     ##
defb @10000000
defb @01000000
defb @00001100
defb @10010010
defb @00010010
defb @00001110
defb @00000010
defb @10001100


; Char entry $0068 (offset $0340)
;    #
;    #
;    ###
;    #  #
;    #  #
;    #  #
;    #  #
;
defb @10010000
defb @01010000
defb @01011100
defb @00010010
defb @00010010
defb @00010010
defb @00010010
defb @10000000


; Char entry $0069 (offset $0348)
;      #
;
;     ##
;      #
;      #
;      #
;     ###
;
defb @10000100
defb @01000000
defb @10001100
defb @00000100
defb @00000100
defb @00000100
defb @00001110
defb @10000000


; Char entry $006A (offset $0350)
;      #
;
;      #
;      #
;      #
;      #
;    # #
;     #
defb @10000100
defb @01000000
defb @10000100
defb @10000100
defb @00000100
defb @00000100
defb @00010100
defb @10001000


; Char entry $006B (offset $0358)
;    #
;    #
;    # #
;    ##
;    ##
;    # #
;    #  #
;
defb @10010000
defb @01010000
defb @11010100
defb @00011000
defb @00011000
defb @00010100
defb @00010010
defb @10000000


; Char entry $006C (offset $0360)
;     ##
;      #
;      #
;      #
;      #
;      #
;     ###
;
defb @10001100
defb @10000100
defb @01000100
defb @10000100
defb @00000100
defb @00000100
defb @00001110
defb @10000000


; Char entry $006D (offset $0368)
;
;
;     # #
;    # # #
;    # # #
;    #   #
;    #   #
;
defb @10000000
defb @10000000
defb @10001010
defb @00010101
defb @00010101
defb @00010001
defb @00010001
defb @10000000


; Char entry $006E (offset $0370)
;
;
;    ###
;    #  #
;    #  #
;    #  #
;    #  #
;
defb @10000000
defb @10000000
defb @10011100
defb @10010010
defb @00010010
defb @00010010
defb @00010010
defb @10000000


; Char entry $006F (offset $0378)
;
;
;     ##
;    #  #
;    #  #
;    #  #
;     ##
;
defb @10000000
defb @10000000
defb @11001100
defb @00010010
defb @00010010
defb @00010010
defb @00001100
defb @10000000


; Char entry $0070 (offset $0380)
;
;
;    ###
;    #  #
;    #  #
;    ###
;    #
;    #
defb @10000000
defb @11000000
defb @00011100
defb @01010010
defb @00010010
defb @00011100
defb @00010000
defb @10010000


; Char entry $0071 (offset $0388)
;
;
;     ###
;    #  #
;    #  #
;     ###
;       #
;       ##
defb @10000000
defb @11000000
defb @00001110
defb @11010010
defb @00010010
defb @00001110
defb @00000010
defb @10000011


; Char entry $0072 (offset $0390)
;
;
;    # ##
;    ##
;    #
;    #
;    #
;
defb @10000000
defb @11000000
defb @10010110
defb @00011000
defb @00010000
defb @00010000
defb @00010000
defb @10000000


; Char entry $0073 (offset $0398)
;
;
;     ###
;    #
;     ###
;        #
;     ###
;
defb @10000000
defb @11000000
defb @11001110
defb @01010000
defb @00001110
defb @00000001
defb @00001110
defb @10000000


; Char entry $0074 (offset $03A0)
;
;     #
;    ####
;     #
;     #
;     # #
;      #
;
defb @11000000
defb @00001000
defb @01011110
defb @11001000
defb @00001000
defb @00001010
defb @00000100
defb @10000000


; Char entry $0075 (offset $03A8)
;
;
;    #  #
;    #  #
;    #  #
;    #  #
;     ###
;
defb @11000000
defb @01000000
defb @00010010
defb @01010010
defb @00010010
defb @00010010
defb @00001110
defb @10000000


; Char entry $0076 (offset $03B0)
;
;
;    #   #
;    #   #
;    #   #
;     # #
;      #
;
defb @11000000
defb @01000000
defb @00010001
defb @11010001
defb @00010001
defb @00001010
defb @00000100
defb @10000000


; Char entry $0077 (offset $03B8)
;
;
;    #   #
;    #   #
;    # # #
;    # # #
;     # #
;
defb @11000000
defb @01000000
defb @01010001
defb @01010001
defb @00010101
defb @00010101
defb @00001010
defb @10000000


; Char entry $0078 (offset $03C0)
;
;
;    #   #
;     # #
;      #
;     # #
;    #   #
;
defb @11000000
defb @01000000
defb @10010001
defb @10001010
defb @00000100
defb @00001010
defb @00010001
defb @10000000


; Char entry $0079 (offset $03C8)
;
;
;    #  #
;    #  #
;    #  #
;     ###
;       #
;     ##
defb @11000000
defb @01000000
defb @11010010
defb @01010010
defb @00010010
defb @00001110
defb @00000010
defb @10001100


; Char entry $007A (offset $03D0)
;
;
;    #####
;       #
;      #
;     #
;    #####
;
defb @11000000
defb @10000000
defb @00011111
defb @00000010
defb @00000100
defb @00001000
defb @00011111
defb @10000000


; Char entry $007B (offset $03D8)
;       #
;      #
;      #
;     #
;      #
;      #
;       #
;
defb @11000010
defb @10000100
defb @00000100
defb @11001000
defb @00000100
defb @00000100
defb @00000010
defb @10000000


; Char entry $007C (offset $03E0)
;      #
;      #
;      #
;
;      #
;      #
;      #
;
defb @11000100
defb @10000100
defb @01000100
defb @10000000
defb @00000100
defb @00000100
defb @00000100
defb @10000000


; Char entry $007D (offset $03E8)
;    #
;     #
;     #
;      #
;     #
;     #
;    #
;
defb @11010000
defb @10001000
defb @10001000
defb @00000100
defb @00001000
defb @00001000
defb @00010000
defb @10000000


; Char entry $007E (offset $03F0)
;
;     #
;    # # #
;       #
;
;
;
;
defb @11000000
defb @10001000
defb @10010101
defb @10000010
defb @00000000
defb @00000000
defb @00000000
defb @10000000


; Char entry $007F (offset $03F8)
;      ###
;      ###
;      ###
;      ###
;      ###
;      ###
;      ###
;      ###
defb @11000111
defb @10000111
defb @11000111
defb @00000111
defb @00000111
defb @00000111
defb @00000111
defb @10000111


; Char entry $0080 (offset $0400)
;   ######
;   ######
;   ######
;   ######
;   ######
;   ######
;   ######
;   ######
defb @11111111
defb @11111111
defb @00111111
defb @00111111
defb @00111111
defb @00111111
defb @00111111
defb @10111111


; Char entry $0081 (offset $0408)
;
;      #
;      ##
;   ######
;   ######
;      ##
;      #
;
defb @11000000
defb @11000100
defb @10000110
defb @00111111
defb @00111111
defb @00000110
defb @00000100
defb @10000000


; Char entry $0082 (offset $0410)
;
;     ##
;     ##
;     ##
;   ######
;    ####
;     ##
;
defb @00000000
defb @00001100
defb @00001100
defb @01001100
defb @01111111
defb @01011110
defb @01001100
defb @00000000


; Char entry $0083 (offset $0418)
;
;
;
;     ####
;     ####
;     ##
;     ##
;     ##
defb @01000000
defb @00000000
defb @00000000
defb @11001111
defb @01001111
defb @11001100
defb @01001100
defb @01001100


; Char entry $0084 (offset $0420)
;
;     #
;    ##
;   ######
;   ######
;    ##
;     #
;
defb @01000000
defb @11001000
defb @00011000
defb @10111111
defb @01111111
defb @11011000
defb @00001000
defb @11000000


; Char entry $0085 (offset $0428)
;
;
;
;   ######
;   ######
;
;
;
defb @01000000
defb @10000000
defb @11000000
defb @11111111
defb @01111111
defb @11000000
defb @00000000
defb @10000000


; Char entry $0086 (offset $0430)
;
;
;
;   ####
;   ####
;     ##
;     ##
;     ##
defb @00000000
defb @10000000
defb @00000000
defb @00111100
defb @01111100
defb @10001100
defb @01001100
defb @01001100


; Char entry $0087 (offset $0438)
;
;
;
;   ######
;   ######
;     ##
;     ##
;     ##
defb @00000000
defb @10000000
defb @00000000
defb @00111111
defb @00111111
defb @10001100
defb @00001100
defb @00001100


; Char entry $0088 (offset $0440)
;
;     ##
;    ####
;   ######
;     ##
;     ##
;     ##
;
defb @01000000
defb @11001100
defb @00011110
defb @10111111
defb @01001100
defb @10001100
defb @01001100
defb @01000000


; Char entry $0089 (offset $0448)
;     ##
;     ##
;     ##
;     ####
;     ####
;
;
;
defb @01001100
defb @11001100
defb @01001100
defb @00001111
defb @01001111
defb @11000000
defb @01000000
defb @01000000


; Char entry $008A (offset $0450)
;     ##
;     ##
;     ##
;     ##
;     ##
;     ##
;     ##
;     ##
defb @01001100
defb @11001100
defb @00001100
defb @10001100
defb @01001100
defb @10001100
defb @11001100
defb @10001100


; Char entry $008B (offset $0458)
;     ##
;     ##
;     ##
;     ####
;     ####
;     ##
;     ##
;     ##
defb @01001100
defb @11001100
defb @00001100
defb @11001111
defb @00001111
defb @10001100
defb @00001100
defb @00001100


; Char entry $008C (offset $0460)
;     ##
;     ##
;     ##
;   ####
;   ####
;
;
;
defb @01001100
defb @11001100
defb @01001100
defb @00111100
defb @00111100
defb @10000000
defb @00000000
defb @00000000


; Char entry $008D (offset $0468)
;     ##
;     ##
;     ##
;   ######
;   ######
;
;
;
defb @01001100
defb @10001100
defb @10001100
defb @01111111
defb @01111111
defb @10000000
defb @11000000
defb @10000000


; Char entry $008E (offset $0470)
;     ##
;     ##
;     ##
;   ####
;   ####
;     ##
;     ##
;     ##
defb @01001100
defb @10001100
defb @01001100
defb @01111100
defb @01111100
defb @11001100
defb @00001100
defb @10001100


; Char entry $008F (offset $0478)
;     ##
;     ##
;     ##
;   ######
;   ######
;     ##
;     ##
;     ##
defb @01001100
defb @11001100
defb @01001100
defb @00111111
defb @01111111
defb @10001100
defb @10001100
defb @01001100


; Char entry $0090 (offset $0480)
;
;     ##
;    ####
;   ##  ##
;   ##  ##
;    ####
;     ##
;
defb @01000000
defb @10001100
defb @11011110
defb @11110011
defb @01110011
defb @10011110
defb @11001100
defb @10000000


; Char entry $0091 (offset $0488)
;
;   ######
;   ######
;   ##  ##
;   ##  ##
;   ######
;   ######
;
defb @01000000
defb @11111111
defb @01111111
defb @00110011
defb @01110011
defb @10111111
defb @10111111
defb @00000000


; Char entry $0092 (offset $0490)
;
;
;    #####
;    #####
;     ###
;      #
;
;
defb @01000000
defb @10000000
defb @11011111
defb @11011111
defb @01001110
defb @10000100
defb @01000000
defb @10000000


; Char entry $0093 (offset $0498)
;
;
;      #
;     ###
;    #####
;    #####
;
;
defb @00000000
defb @10000000
defb @00000100
defb @00001110
defb @01011111
defb @10011111
defb @11000000
defb @11000000


; Char entry $0094 (offset $04A0)
;        #
;        #
;        #
;      ###
;       #
;        #
;
;
defb @01000001
defb @10000001
defb @11000001
defb @00000111
defb @01000010
defb @11000001
defb @01000000
defb @01000000


; Char entry $0095 (offset $04A8)
;   ##
;    #
;    #
;    ###
;     #
;    #
;   #
;
defb @01110000
defb @10010000
defb @11010000
defb @01011100
defb @01001000
defb @10010000
defb @11100000
defb @10000000


; Char entry $0096 (offset $04B0)
;
;        #
;       #
;      ###
;        #
;        #
;        #
;
defb @01000000
defb @10000001
defb @11000010
defb @00000111
defb @01000001
defb @10000001
defb @01000001
defb @01000000


; Char entry $0097 (offset $04B8)
;   #
;    #
;     #
;    ###
;    #
;    #
;   ##
;
defb @01100000
defb @10010000
defb @00001000
defb @01011100
defb @01010000
defb @11010000
defb @00110000
defb @10000000


; Char entry $0098 (offset $04C0)
;     ##
;    #  #
;     ##
;      #
;      #
;      #
;     ###
;
defb @01001100
defb @11010010
defb @00001100
defb @10000100
defb @01000100
defb @10000100
defb @01001110
defb @01000000


; Char entry $0099 (offset $04C8)
;     ##
;    #  #
;     ##
;    #  #
;    #  #
;    #  #
;     ##
;
defb @01001100
defb @11010010
defb @00001100
defb @11010010
defb @00010010
defb @10010010
defb @00001100
defb @00000000


; Char entry $009A (offset $04D0)
;     ##
;    #  #
;
;    #  #
;    #  #
;    #  #
;     ###
;
defb @01001100
defb @10010010
defb @11000000
defb @11010010
defb @01010010
defb @11010010
defb @00001110
defb @10000000


; Char entry $009B (offset $04D8)
;      #
;       #
;     ###
;       ##
;     ####
;    ## ##
;     ####
;
defb @01000100
defb @10000010
defb @10001110
defb @01000011
defb @01001111
defb @10011011
defb @01001111
defb @11000000


; Char entry $009C (offset $04E0)
;      #
;       #
;     ###
;    ## ##
;    #####
;    ##
;     ###
;
defb @01000100
defb @10000010
defb @00001110
defb @01011011
defb @01011111
defb @11011000
defb @01001110
defb @00000000


; Char entry $009D (offset $04E8)
;     #
;    #
;     ###
;    ## ##
;    #####
;    ##
;     ###
;
defb @10001000
defb @00010000
defb @10001110
defb @00011011
defb @10011111
defb @00011000
defb @00001110
defb @10000000


; Char entry $009E (offset $04F0)
;
;
;     ###
;    ##
;    ##
;     ###
;      #
;     ##
defb @01000000
defb @10000000
defb @00001110
defb @01011000
defb @01011000
defb @10001110
defb @11000100
defb @10001100


; Char entry $009F (offset $04F8)
;      ##
;     ## #
;     ##
;    ####
;     ##
;     ##
;    #####
;
defb @10000110
defb @00001101
defb @11001100
defb @10011110
defb @01001100
defb @00001100
defb @11011111
defb @00000000


; Char entry $00A0 (offset $0500)
;
;
;
;
;
;
;    # # #
;
defb @01000000
defb @10000000
defb @10000000
defb @01000000
defb @01000000
defb @10000000
defb @11010101
defb @01000000


; Char entry $00A1 (offset $0508)
;     ##
;     ##
;     ##
;     ##
;
;
;     ##
;
defb @01001100
defb @10001100
defb @10001100
defb @01001100
defb @01000000
defb @11000000
defb @01001100
defb @00000000


; Char entry $00A2 (offset $0510)
;    ## ##
;    ## ##
;    ## ##
;
;
;
;
;
defb @01011011
defb @10011011
defb @01011011
defb @01000000
defb @01000000
defb @10000000
defb @01000000
defb @00000000


; Char entry $00A3 (offset $0518)
;     # #
;    #####
;    #####
;     # #
;    #####
;    #####
;     # #
;
defb @00001010
defb @10011111
defb @00011111
defb @00001010
defb @00011111
defb @11011111
defb @00001010
defb @01000000


; Char entry $00A4 (offset $0520)
;     ##
;    #####
;   # ##
;    ####
;     ## #
;   #####
;     ##
;
defb @00001100
defb @11011111
defb @10101100
defb @01011110
defb @00001101
defb @11111110
defb @10001100
defb @00000000


; Char entry $00A5 (offset $0528)
;   ##
;   ##  ##
;      ##
;     ##
;    ##
;   ##  ##
;       ##
;
defb @00110000
defb @11110011
defb @01000110
defb @11001100
defb @00011000
defb @10110011
defb @11000011
defb @00000000


; Char entry $00A6 (offset $0530)
;    ###
;   ## ##
;   ## ##
;    ##
;   ## # #
;   ##  #
;    ### #
;
defb @00011100
defb @11110110
defb @10110110
defb @00011000
defb @00110101
defb @11110010
defb @10011101
defb @00000000


; Char entry $00A7 (offset $0538)
;      ##
;     ##
;    ##
;
;
;
;
;
defb @01000110
defb @11001100
defb @11011000
defb @11000000
defb @01000000
defb @00000000
defb @00000000
defb @11000000


; Char entry $00A8 (offset $0540)
;      ##
;     ##
;    ##
;    ##
;    ##
;     ##
;      ##
;
defb @01000110
defb @10001100
defb @11011000
defb @11011000
defb @01011000
defb @11001100
defb @00000110
defb @00000000


; Char entry $00A9 (offset $0548)
;    ##
;     ##
;      ##
;      ##
;      ##
;     ##
;    ##
;
defb @01011000
defb @11001100
defb @10000110
defb @01000110
defb @01000110
defb @11001100
defb @00011000
defb @10000000


; Char entry $00AA (offset $0550)
;
;     ##
;   ######
;    ####
;   ######
;     ##
;
;
defb @10000000
defb @01001100
defb @00111111
defb @00011110
defb @01111111
defb @10001100
defb @10000000
defb @00000000


; Char entry $00AB (offset $0558)
;
;     ##
;     ##
;   ######
;   ######
;     ##
;     ##
;
defb @10000000
defb @00001100
defb @01001100
defb @00111111
defb @00111111
defb @10001100
defb @10001100
defb @00000000


; Char entry $00AC (offset $0560)
;
;
;
;
;
;     ##
;     ##
;    ##
defb @01000000
defb @00000000
defb @00000000
defb @11000000
defb @00000000
defb @10001100
defb @10001100
defb @01011000


; Char entry $00AD (offset $0568)
;
;
;
;    #####
;    #####
;
;
;
defb @00000000
defb @10000000
defb @00000000
defb @00011111
defb @01011111
defb @10000000
defb @00000000
defb @01000000


; Char entry $00AE (offset $0570)
;
;
;
;
;
;     ##
;     ##
;
defb @01000000
defb @10000000
defb @11000000
defb @00000000
defb @01000000
defb @00001100
defb @01001100
defb @00000000


; Char entry $00AF (offset $0578)
;
;       ##
;      ##
;     ##
;    ##
;   ##
;
;
defb @01000000
defb @10000011
defb @01000110
defb @01001100
defb @10011000
defb @00110000
defb @10000000
defb @11000000


; Char entry $00B0 (offset $0580)
;     ###
;    ##  #
;    ## ##
;    ### #
;    ##  #
;    ##  #
;     ###
;
defb @01001110
defb @11011001
defb @01011011
defb @00011101
defb @10011001
defb @00011001
defb @00001110
defb @10000000


; Char entry $00B1 (offset $0588)
;     ##
;    ###
;     ##
;     ##
;     ##
;     ##
;     ##
;
defb @01001100
defb @00011100
defb @11001100
defb @10001100
defb @01001100
defb @10001100
defb @01001100
defb @01000000


; Char entry $00B2 (offset $0590)
;     ###
;    ## ##
;       ##
;      ##
;     ##
;    ##
;    #####
;
defb @01001110
defb @11011011
defb @10000011
defb @00000110
defb @10001100
defb @00011000
defb @01011111
defb @00000000


; Char entry $00B3 (offset $0598)
;    #####
;       ##
;      ##
;       ##
;       ##
;    ## ##
;     ###
;
defb @01011111
defb @01000011
defb @00000110
defb @00000011
defb @10000011
defb @00011011
defb @11001110
defb @01000000


; Char entry $00B4 (offset $05A0)
;      ##
;     ###
;    # ##
;   #  ##
;   ######
;      ##
;      ##
;
defb @01000110
defb @11001110
defb @01010110
defb @10100110
defb @01111111
defb @10000110
defb @10000110
defb @01000000


; Char entry $00B5 (offset $05A8)
;    #####
;    ##
;    ####
;       ##
;       ##
;    ## ##
;     ###
;
defb @01011111
defb @10011000
defb @11011110
defb @11000011
defb @01000011
defb @11011011
defb @01001110
defb @01000000


; Char entry $00B6 (offset $05B0)
;      ##
;     ##
;    ##
;    ####
;    ## ##
;    ## ##
;     ###
;
defb @10000110
defb @00001100
defb @11011000
defb @10011110
defb @01011011
defb @10011011
defb @10001110
defb @00000000


; Char entry $00B7 (offset $05B8)
;    #####
;       ##
;       ##
;      ##
;     ##
;     ##
;     ##
;
defb @10011111
defb @00000011
defb @11000011
defb @00000110
defb @01001100
defb @10001100
defb @00001100
defb @01000000


; Char entry $00B8 (offset $05C0)
;     ###
;    ## ##
;    ## ##
;     ###
;    ## ##
;    ## ##
;     ###
;
defb @01001110
defb @10011011
defb @00011011
defb @11001110
defb @01011011
defb @11011011
defb @01001110
defb @00000000


; Char entry $00B9 (offset $05C8)
;     ###
;    ## ##
;    ## ##
;     ####
;       ##
;      ##
;     ##
;
defb @10001110
defb @00011011
defb @01011011
defb @10001111
defb @00000011
defb @10000110
defb @11001100
defb @10000000


; Char entry $00BA (offset $05D0)
;
;
;     ##
;     ##
;
;     ##
;     ##
;
defb @01000000
defb @11000000
defb @11001100
defb @11001100
defb @01000000
defb @00001100
defb @10001100
defb @01000000


; Char entry $00BB (offset $05D8)
;
;
;     ##
;     ##
;
;     ##
;     ##
;    ##
defb @01000000
defb @10000000
defb @11001100
defb @10001100
defb @01000000
defb @11001100
defb @00001100
defb @11011000


; Char entry $00BC (offset $05E0)
;       ##
;      ##
;     ##
;    ##
;     ##
;      ##
;       ##
;
defb @10000011
defb @00000110
defb @01001100
defb @10011000
defb @01001100
defb @00000110
defb @01000011
defb @10000000


; Char entry $00BD (offset $05E8)
;
;    #####
;    #####
;
;    #####
;    #####
;
;
defb @01000000
defb @11011111
defb @01011111
defb @01000000
defb @01011111
defb @10011111
defb @11000000
defb @10000000


; Char entry $00BE (offset $05F0)
;    ##
;     ##
;      ##
;       ##
;      ##
;     ##
;    ##
;
defb @01011000
defb @10001100
defb @00000110
defb @11000011
defb @10000110
defb @00001100
defb @01011000
defb @11000000


; Char entry $00BF (offset $05F8)
;     ###
;    ## ##
;       ##
;      ##
;      ##
;
;      ##
;
defb @01001110
defb @10011011
defb @11000011
defb @11000110
defb @01000110
defb @11000000
defb @01000110
defb @11000000


; Char entry $00C0 (offset $0600)
;    ####
;   ##  ##
;   ## ###
;   ## # #
;   ## ###
;   ##
;    ####
;
defb @01011110
defb @11110011
defb @01110111
defb @00110101
defb @01110111
defb @10110000
defb @11011110
defb @11000000


; Char entry $00C1 (offset $0608)
;     ###
;    ## ##
;    ## ##
;    #####
;    ## ##
;    ## ##
;    ## ##
;
defb @01001110
defb @11011011
defb @00011011
defb @10011111
defb @01011011
defb @10011011
defb @00011011
defb @01000000


; Char entry $00C2 (offset $0610)
;    ####
;    ## ##
;    ## ##
;    ####
;    ## ##
;    ## ##
;    ####
;
defb @01011110
defb @10011011
defb @01011011
defb @00011110
defb @01011011
defb @10011011
defb @10011110
defb @01000000


; Char entry $00C3 (offset $0618)
;     ###
;    ## ##
;    ##
;    ##
;    ##
;    ## ##
;     ###
;
defb @10001110
defb @01011011
defb @00011000
defb @11011000
defb @01011000
defb @11011011
defb @00001110
defb @11000000


; Char entry $00C4 (offset $0620)
;    ###
;    ## #
;    ## ##
;    ## ##
;    ## ##
;    ## #
;    ###
;
defb @01011100
defb @10011010
defb @11011011
defb @00011011
defb @01011011
defb @10011010
defb @10011100
defb @01000000


; Char entry $00C5 (offset $0628)
;    #####
;    ##
;    ##
;    ####
;    ##
;    ##
;    #####
;
defb @01011111
defb @11011000
defb @00011000
defb @11011110
defb @01011000
defb @11011000
defb @01011111
defb @00000000


; Char entry $00C6 (offset $0630)
;    #####
;    ##
;    ##
;    ####
;    ##
;    ##
;    ##
;
defb @01011111
defb @10011000
defb @11011000
defb @10011110
defb @01011000
defb @11011000
defb @01011000
defb @01000000


; Char entry $00C7 (offset $0638)
;     ####
;    ##
;    ##
;    ## ##
;    ##  #
;    ##  #
;     ####
;
defb @01001111
defb @10011000
defb @11011000
defb @01011011
defb @01011001
defb @10011001
defb @00001111
defb @10000000


; Char entry $00C8 (offset $0640)
;    ##  #
;    ##  #
;    ##  #
;    #####
;    ##  #
;    ##  #
;    ##  #
;
defb @10011001
defb @00011001
defb @01011001
defb @10011111
defb @00011001
defb @10011001
defb @00011001
defb @00000000


; Char entry $00C9 (offset $0648)
;     ####
;      ##
;      ##
;      ##
;      ##
;      ##
;     ####
;
defb @01001111
defb @10000110
defb @01000110
defb @01000110
defb @01000110
defb @10000110
defb @11001111
defb @10000000


; Char entry $00CA (offset $0650)
;    #####
;      ##
;      ##
;      ##
;      ##
;    # ##
;     ##
;
defb @10011111
defb @00000110
defb @01000110
defb @01000110
defb @00000110
defb @10010110
defb @00001100
defb @00000000


; Char entry $00CB (offset $0658)
;    ##  #
;    ## #
;    ###
;    ###
;    ###
;    ## #
;    ##  #
;
defb @00011001
defb @10011010
defb @11011100
defb @00011100
defb @00011100
defb @10011010
defb @00011001
defb @00000000


; Char entry $00CC (offset $0660)
;    ##
;    ##
;    ##
;    ##
;    ##
;    ##
;    #####
;
defb @01011000
defb @10011000
defb @11011000
defb @00011000
defb @01011000
defb @10011000
defb @11011111
defb @11000000


; Char entry $00CD (offset $0668)
;    #   #
;    ## ##
;    #####
;    #####
;    # # #
;    # # #
;    #   #
;
defb @01010001
defb @00011011
defb @01011111
defb @10011111
defb @01010101
defb @10010101
defb @10010001
defb @01000000


; Char entry $00CE (offset $0670)
;    #   #
;    ##  #
;    ### #
;    #####
;    ## ##
;    ##  #
;    ##  #
;
defb @10010001
defb @00011001
defb @00011101
defb @01011111
defb @01011011
defb @01011001
defb @00011001
defb @10000000


; Char entry $00CF (offset $0678)
;     ###
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;     ###
;
defb @10001110
defb @01011011
defb @00011011
defb @00011011
defb @01011011
defb @10011011
defb @10001110
defb @00000000


; Char entry $00D0 (offset $0680)
;    ####
;    ## ##
;    ## ##
;    ####
;    ##
;    ##
;    ##
;
defb @01011110
defb @11011011
defb @01011011
defb @00011110
defb @10011000
defb @00011000
defb @00011000
defb @01000000


; Char entry $00D1 (offset $0688)
;     ###
;    ##  #
;    ##  #
;    ##  #
;    ### #
;    ## #
;     ## #
;
defb @01001110
defb @00011001
defb @11011001
defb @00011001
defb @01011101
defb @10011010
defb @01001101
defb @01000000


; Char entry $00D2 (offset $0690)
;    ####
;    ## ##
;    ## ##
;    ####
;    ###
;    ## #
;    ##  #
;
defb @01011110
defb @10011011
defb @01011011
defb @10011110
defb @01011100
defb @11011010
defb @01011001
defb @00000000


; Char entry $00D3 (offset $0698)
;     ###
;    ## ##
;    ##
;     ###
;       ##
;    ## ##
;     ###
;
defb @01001110
defb @00011011
defb @11011000
defb @00001110
defb @10000011
defb @00011011
defb @01001110
defb @01000000


; Char entry $00D4 (offset $06A0)
;   ######
;     ##
;     ##
;     ##
;     ##
;     ##
;     ##
;
defb @01111111
defb @10001100
defb @01001100
defb @01001100
defb @00001100
defb @11001100
defb @10001100
defb @10000000


; Char entry $00D5 (offset $06A8)
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;     ###
;
defb @00011011
defb @10011011
defb @00011011
defb @00011011
defb @01011011
defb @00011011
defb @00001110
defb @11000000


; Char entry $00D6 (offset $06B0)
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;     # #
;      #
;
defb @01011011
defb @10011011
defb @11011011
defb @11011011
defb @01011011
defb @00001010
defb @01000100
defb @00000000


; Char entry $00D7 (offset $06B8)
;    #   #
;    #   #
;    # # #
;    # # #
;    #####
;    #####
;     # #
;
defb @10010001
defb @01010001
defb @11010101
defb @01010101
defb @01011111
defb @10011111
defb @11001010
defb @10000000


; Char entry $00D8 (offset $06C0)
;    ## ##
;    ## ##
;     # #
;      #
;     # #
;    ## ##
;    ## ##
;
defb @01011011
defb @00011011
defb @00001010
defb @01000100
defb @01001010
defb @10011011
defb @00011011
defb @11000000


; Char entry $00D9 (offset $06C8)
;    ## ##
;    ## ##
;    ## ##
;     # #
;      #
;      #
;      #
;
defb @01011011
defb @11011011
defb @01011011
defb @00001010
defb @01000100
defb @10000100
defb @10000100
defb @01000000


; Char entry $00DA (offset $06D0)
;    #####
;       ##
;      ##
;     ##
;    ##
;    ##
;    #####
;
defb @01011111
defb @11000011
defb @01000110
defb @10001100
defb @10011000
defb @00011000
defb @00011111
defb @10000000


; Char entry $00DB (offset $06D8)
;    ####
;    ##
;    ##
;    ##
;    ##
;    ##
;    ####
;
defb @01011110
defb @00011000
defb @01011000
defb @00011000
defb @01011000
defb @10011000
defb @00011110
defb @01000000


; Char entry $00DC (offset $06E0)
;
;   ##
;    ##
;     ##
;      ##
;       ##
;
;
defb @01000000
defb @11110000
defb @10011000
defb @01001100
defb @00000110
defb @10000011
defb @10000000
defb @01000000


; Char entry $00DD (offset $06E8)
;    ####
;      ##
;      ##
;      ##
;      ##
;      ##
;    ####
;
defb @10011110
defb @00000110
defb @00000110
defb @11000110
defb @10000110
defb @01000110
defb @00011110
defb @10000000


; Char entry $00DE (offset $06F0)
;     ##
;    ####
;   ##  ##
;
;
;
;
;
defb @01001100
defb @11011110
defb @01110011
defb @00000000
defb @01000000
defb @10000000
defb @01000000
defb @01000000


; Char entry $00DF (offset $06F8)
;
;
;
;
;
;   ######
;   ######
;
defb @00000000
defb @10000000
defb @00000000
defb @10000000
defb @10000000
defb @01111111
defb @10111111
defb @10000000


; Char entry $00E0 (offset $0700)
;    ##
;     ##
;      ##
;
;
;
;
;
defb @01011000
defb @00001100
defb @01000110
defb @01000000
defb @01000000
defb @01000000
defb @00000000
defb @11000000


; Char entry $00E1 (offset $0708)
;
;
;     ###
;       ##
;     ####
;    ## ##
;     ####
;
defb @01000000
defb @00000000
defb @00001110
defb @11000011
defb @01001111
defb @00011011
defb @00001111
defb @01000000


; Char entry $00E2 (offset $0710)
;    ##
;    ##
;    ####
;    ## ##
;    ## ##
;    ## ##
;    ####
;
defb @01011000
defb @01011000
defb @00011110
defb @00011011
defb @01011011
defb @00011011
defb @01011110
defb @01000000


; Char entry $00E3 (offset $0718)
;
;
;     ###
;    ##
;    ##
;    ##
;     ###
;
defb @01000000
defb @10000000
defb @01001110
defb @00011000
defb @00011000
defb @10011000
defb @00001110
defb @00000000


; Char entry $00E4 (offset $0720)
;       ##
;       ##
;     ####
;    ## ##
;    ## ##
;    ## ##
;     ####
;
defb @01000011
defb @11000011
defb @01001111
defb @10011011
defb @10011011
defb @01011011
defb @01001111
defb @01000000


; Char entry $00E5 (offset $0728)
;
;
;     ###
;    ## ##
;    #####
;    ##
;     ###
;
defb @01000000
defb @11000000
defb @01001110
defb @01011011
defb @01011111
defb @10011000
defb @00001110
defb @11000000


; Char entry $00E6 (offset $0730)
;      ##
;     ## #
;     ##
;    ####
;     ##
;     ##
;     ##
;
defb @01000110
defb @10001101
defb @10001100
defb @00011110
defb @01001100
defb @00001100
defb @00001100
defb @11000000


; Char entry $00E7 (offset $0738)
;
;
;     ###
;    ## ##
;    ## ##
;     ####
;       ##
;     ###
defb @10000000
defb @00000000
defb @10001110
defb @10011011
defb @01011011
defb @00001111
defb @01000011
defb @00001110


; Char entry $00E8 (offset $0740)
;    ##
;    ##
;    ####
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;
defb @01011000
defb @10011000
defb @10011110
defb @01011011
defb @10011011
defb @00011011
defb @11011011
defb @01000000


; Char entry $00E9 (offset $0748)
;      ##
;
;     ###
;      ##
;      ##
;      ##
;     ####
;
defb @01000110
defb @10000000
defb @00001110
defb @11000110
defb @01000110
defb @11000110
defb @01001111
defb @00000000


; Char entry $00EA (offset $0750)
;      ##
;
;      ##
;      ##
;      ##
;      ##
;    # ##
;     ##
defb @10000110
defb @00000000
defb @11000110
defb @11000110
defb @01000110
defb @11000110
defb @10010110
defb @01001100


; Char entry $00EB (offset $0758)
;    ##
;    ##
;    ## ##
;    ####
;    ####
;    ## ##
;    ##  #
;
defb @00011000
defb @10011000
defb @00011011
defb @00011110
defb @01011110
defb @10011011
defb @10011001
defb @01000000


; Char entry $00EC (offset $0760)
;    ###
;     ##
;     ##
;     ##
;     ##
;     ##
;    ####
;
defb @10011100
defb @00001100
defb @11001100
defb @10001100
defb @01001100
defb @00001100
defb @11011110
defb @00000000


; Char entry $00ED (offset $0768)
;
;
;     # #
;    #####
;    #####
;    # # #
;    # # #
;
defb @01000000
defb @10000000
defb @11001010
defb @11011111
defb @01011111
defb @10010101
defb @01010101
defb @11000000


; Char entry $00EE (offset $0770)
;
;
;    ####
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;
defb @01000000
defb @10000000
defb @10011110
defb @01011011
defb @01011011
defb @10011011
defb @00011011
defb @11000000


; Char entry $00EF (offset $0778)
;
;
;     ###
;    ## ##
;    ## ##
;    ## ##
;     ###
;
defb @10000000
defb @01000000
defb @01001110
defb @01011011
defb @00011011
defb @10011011
defb @00001110
defb @00000000


; Char entry $00F0 (offset $0780)
;
;
;    ####
;    ## ##
;    ## ##
;    ####
;    ##
;    ##
defb @01000000
defb @01000000
defb @01011110
defb @01011011
defb @01011011
defb @11011110
defb @00011000
defb @00011000


; Char entry $00F1 (offset $0788)
;
;
;    ####
;   ## ##
;   ## ##
;    ####
;      ##
;      ###
defb @10000000
defb @10000000
defb @01011110
defb @10110110
defb @10110110
defb @00011110
defb @10000110
defb @11000111


; Char entry $00F2 (offset $0790)
;
;
;    ## ##
;    ###
;    ##
;    ##
;    ##
;
defb @10000000
defb @01000000
defb @11011011
defb @10011100
defb @00011000
defb @10011000
defb @00011000
defb @00000000


; Char entry $00F3 (offset $0798)
;
;
;     ####
;    ##
;     ###
;       ##
;    ####
;
defb @01000000
defb @10000000
defb @11001111
defb @11011000
defb @01001110
defb @10000011
defb @11011110
defb @10000000


; Char entry $00F4 (offset $07A0)
;
;     ##
;    #####
;     ##
;     ##
;     ## #
;      ##
;
defb @01000000
defb @01001100
defb @00011111
defb @11001100
defb @01001100
defb @10001101
defb @00000110
defb @01000000


; Char entry $00F5 (offset $07A8)
;
;
;    ## ##
;    ## ##
;    ## ##
;    ## ##
;     ####
;
defb @01000000
defb @11000000
defb @01011011
defb @10011011
defb @10011011
defb @00011011
defb @00001111
defb @10000000


; Char entry $00F6 (offset $07B0)
;
;
;    ## ##
;    ## ##
;    ## ##
;     # #
;      #
;
defb @01000000
defb @01000000
defb @00011011
defb @00011011
defb @01011011
defb @10001010
defb @11000100
defb @11000000


; Char entry $00F7 (offset $07B8)
;
;
;    # # #
;    # # #
;    #####
;    #####
;     # #
;
defb @01000000
defb @11000000
defb @00010101
defb @11010101
defb @01011111
defb @10011111
defb @10001010
defb @01000000


; Char entry $00F8 (offset $07C0)
;
;
;    ## ##
;     # #
;      #
;     # #
;    ## ##
;
defb @10000000
defb @00000000
defb @01011011
defb @11001010
defb @01000100
defb @00001010
defb @11011011
defb @11000000


; Char entry $00F9 (offset $07C8)
;
;
;    ## ##
;    ## ##
;    ## ##
;     ####
;       ##
;     ###
defb @01000000
defb @11000000
defb @00011011
defb @00011011
defb @10011011
defb @00001111
defb @01000011
defb @01001110


; Char entry $00FA (offset $07D0)
;
;
;    #####
;      ##
;     ##
;    ##
;    #####
;
defb @01000000
defb @10000000
defb @01011111
defb @11000110
defb @00001100
defb @10011000
defb @00011111
defb @00000000


; Char entry $00FB (offset $07D8)
;      ##
;     ##
;     ##
;    ##
;     ##
;     ##
;      ##
;
defb @00000110
defb @10001100
defb @10001100
defb @00011000
defb @01001100
defb @10001100
defb @11000110
defb @10000000


; Char entry $00FC (offset $07E0)
;     ##
;     ##
;     ##
;
;     ##
;     ##
;     ##
;
defb @10001100
defb @00001100
defb @10001100
defb @01000000
defb @00001100
defb @10001100
defb @00001100
defb @10000000


; Char entry $00FD (offset $07E8)
;    ##
;     ##
;     ##
;      ##
;     ##
;     ##
;    ##
;
defb @01011000
defb @10001100
defb @11001100
defb @10000110
defb @10001100
defb @01001100
defb @00011000
defb @01000000


; Char entry $00FE (offset $07F0)
;
;    ##
;   # ## #
;      ##
;
;
;
;
defb @01000000
defb @10011000
defb @01101101
defb @01000110
defb @10000000
defb @10000000
defb @10000000
defb @11000000


; Char entry $00FF (offset $07F8)
;   ####
;   ####
;   ####
;   ####
;   ####
;   ####
;   ####
;   ####
defb @01111100
defb @10111100
defb @11111100
defb @00111100
defb @10111100
defb @01111100
defb @11111100
defb @10111100


; Char entry $0100 (offset $0800)
;   ######
;   ## #
;   # ## #
;   #  #
;   ## # #
;   # ## #
;   ######
;
defb @01111111
defb @10110100
defb @11101101
defb @10100100
defb @00110101
defb @10101101
defb @00111111
defb @00000000


; Char entry $0101 (offset $0808)
;   ######
;   ### ##
;    # # #
;   ##   #
;   ## # #
;   ## # #
;   ######
;
defb @01111111
defb @01111011
defb @00010101
defb @11110001
defb @01110101
defb @10110101
defb @11111111
defb @11000000


; Char entry $0102 (offset $0810)
;   ######
;   # #  #
;    ## ##
;    ##  #
;    ## ##
;   # #  #
;   ######
;
defb @01111111
defb @10101001
defb @01011011
defb @10011001
defb @01011011
defb @11101001
defb @01111111
defb @00000000


; Char entry $0103 (offset $0818)
;   ######
;   #  #
;   # ## #
;   #  # #
;   # ## #
;   #  # #
;   ######
;
defb @01111111
defb @11100100
defb @01101101
defb @11100101
defb @10101101
defb @00100101
defb @11111111
defb @00000000


; Char entry $0104 (offset $0820)
;   ######
;   #   #
;    # ##
;    # ##
;    # ##
;    # ##
;   ######
;
defb @10111111
defb @00100010
defb @00010110
defb @10010110
defb @01010110
defb @00010110
defb @11111111
defb @00000000


; Char entry $0105 (offset $0828)
;   ######
;    #  ##
;   ## # #
;    #  ##
;   ## # #
;    # # #
;   ######
;
defb @01111111
defb @10010011
defb @10110101
defb @01010011
defb @01110101
defb @10010101
defb @11111111
defb @01000000


; Char entry $0106 (offset $0830)
;   ######
;   ##
;   #### #
;   #### #
;   #### #
;   #### #
;   ######
;
defb @01111111
defb @10110000
defb @10111101
defb @01111101
defb @10111101
defb @10111101
defb @11111111
defb @11000000


; Char entry $0107 (offset $0838)
;   ######
;    #  ##
;   # ## #
;   #    #
;   # ## #
;   # ## #
;   ######
;
defb @01111111
defb @00010011
defb @00101101
defb @10100001
defb @10101101
defb @10101101
defb @01111111
defb @01000000


; Char entry $0108 (offset $0840)
;   ######
;      ###
;    ## ##
;      ###
;    ## ##
;      ###
;   ######
;
defb @01111111
defb @10000111
defb @00011011
defb @11000111
defb @01011011
defb @10000111
defb @10111111
defb @11000000


; Char entry $0109 (offset $0848)
;   ######
;   ######
;   #####
;   #### #
;   #####
;   ######
;   ######
;
defb @01111111
defb @11111111
defb @01111110
defb @01111101
defb @01111110
defb @11111111
defb @00111111
defb @10000000


; Char entry $010A (offset $0850)
;   ######
;
;   ## # #
;   ### ##
;   ## # #
;
;   ######
;
defb @01111111
defb @10000000
defb @01110101
defb @01111011
defb @10110101
defb @00000000
defb @10111111
defb @11000000


; Char entry $010B (offset $0858)
;   ######
;    #####
;    #####
;    #####
;    #####
;    #####
;   ######
;
defb @01111111
defb @01011111
defb @00011111
defb @10011111
defb @01011111
defb @10011111
defb @01111111
defb @01000000


; Char entry $010C (offset $0860)
;   ######
;   ##
;   ## ###
;   ##   #
;   ## ###
;   ##
;   ######
;
defb @01111111
defb @10110000
defb @00110111
defb @11110001
defb @01110111
defb @10110000
defb @01111111
defb @01000000


; Char entry $010D (offset $0868)
;   ######
;   ##   #
;   # ####
;   ##   #
;   #### #
;   #   ##
;   ######
;
defb @01111111
defb @11110001
defb @00101111
defb @11110001
defb @10111101
defb @00100011
defb @01111111
defb @00000000


; Char entry $010E (offset $0870)
;   ######
;   #   ##
;    #####
;    #####
;    #####
;   #   ##
;   ######
;
defb @10111111
defb @01100011
defb @10011111
defb @11011111
defb @10011111
defb @00100011
defb @01111111
defb @00000000


; Char entry $010F (offset $0878)
;   ######
;   # #  #
;   # # #
;   # # #
;   # # #
;   # # #
;   ######
;
defb @10111111
defb @01101001
defb @00101010
defb @00101010
defb @01101010
defb @10101010
defb @10111111
defb @00000000


; Char entry $0110 (offset $0880)
;   ######
;   #  ##
;   # # #
;   # # #
;   # # #
;   #  ##
;   ######
;
defb @01111111
defb @10100110
defb @00101010
defb @11101010
defb @01101010
defb @10100110
defb @11111111
defb @11000000


; Char entry $0111 (offset $0888)
;   ######
;    # # #
;   ## # #
;    ## ##
;   ## # #
;    # # #
;   ######
;
defb @01111111
defb @11010101
defb @00110101
defb @11011011
defb @10110101
defb @00010101
defb @01111111
defb @01000000


; Char entry $0112 (offset $0890)
;   ######
;   ## # #
;   # # #
;   # # #
;   # ###
;   # ###
;   ######
;
defb @01111111
defb @10110101
defb @01101010
defb @01101010
defb @10101110
defb @10101110
defb @01111111
defb @00000000


; Char entry $0113 (offset $0898)
;   ######
;   #  #
;   # ## #
;   #  # #
;   # ## #
;   #  # #
;   ######
;
defb @01111111
defb @11100100
defb @00101101
defb @11100101
defb @10101101
defb @00100101
defb @01111111
defb @01000000


; Char entry $0114 (offset $08A0)
;   ######
;   ## # #
;    # # #
;    # # #
;    # # #
;    ## ##
;   ######
;
defb @10111111
defb @00110101
defb @00010101
defb @10010101
defb @10010101
defb @00011011
defb @11111111
defb @11000000


; Char entry $0115 (offset $08A8)
;   ######
;   ## # #
;   ## # #
;   ##   #
;   ## # #
;   ## # #
;   ######
;
defb @00111111
defb @10110101
defb @00110101
defb @00110001
defb @01110101
defb @11110101
defb @01111111
defb @00000000


; Char entry $0116 (offset $08B0)
;   ######
;      # #
;    ### #
;     ## #
;    ### #
;      #
;   ######
;
defb @10111111
defb @01000101
defb @00011101
defb @11001101
defb @01011101
defb @10000100
defb @01111111
defb @11000000


; Char entry $0117 (offset $08B8)
;   ######
;   ##  ##
;   ## # #
;   ##  ##
;   ## ###
;    # ###
;   ######
;
defb @10111111
defb @10110011
defb @00110101
defb @10110011
defb @10110111
defb @00010111
defb @01111111
defb @00000000


; Char entry $0118 (offset $08C0)
;     # #
;
;     ##
;      #
;      #
;      #
;     ###
;
defb @00001010
defb @10000000
defb @11001100
defb @10000100
defb @00000100
defb @10000100
defb @00001110
defb @00000000


; Char entry $0119 (offset $08C8)
;     ###
;    #
;    ####
;    #  #
;    ####
;       #
;    ###
;
defb @01001110
defb @11010000
defb @00011110
defb @11010010
defb @10011110
defb @10000010
defb @01011100
defb @01000000


; Char entry $011A (offset $08D0)
;     #
;    # #
;     #
;
;
;
;
;
defb @01001000
defb @11010100
defb @01001000
defb @00000000
defb @10000000
defb @00000000
defb @11000000
defb @10000000


; Char entry $011B (offset $08D8)
;      #
;       #
;     ##
;    #  #
;    #  #
;     ####
;
;
defb @10000100
defb @10000010
defb @00001100
defb @11010010
defb @00010010
defb @10001111
defb @00000000
defb @10000000


; Char entry $011C (offset $08E0)
;      #
;       #
;     ##
;    ####
;    #
;     ##
;
;
defb @10000100
defb @10000010
defb @00001100
defb @00011110
defb @10010000
defb @11001100
defb @00000000
defb @00000000


; Char entry $011D (offset $08E8)
;     #
;    #
;     ##
;    ####
;    #
;     ##
;
;
defb @00001000
defb @10010000
defb @00001100
defb @00011110
defb @10010000
defb @10001100
defb @00000000
defb @01000000


; Char entry $011E (offset $08F0)
;
;
;     ###
;    #
;     ###
;      #
;     ##
;
defb @10000000
defb @10000000
defb @00001110
defb @11010000
defb @01001110
defb @11000100
defb @01001100
defb @11000000


; Char entry $011F (offset $08F8)
;
;      ###
;     #
;     ###
;     #
;    #####
;
;
defb @01000000
defb @10000111
defb @10001000
defb @00001110
defb @01001000
defb @10011111
defb @10000000
defb @01000000


; Char entry $0120 (offset $0900)
;
;
;
;
;
;
;
;
defb @10000000
defb @11000000
defb @01000000
defb @00000000
defb @00000000
defb @10000000
defb @00000000
defb @00000000


; Char entry $0121 (offset $0908)
;
;      #
;      #
;      #
;
;      #
;
;
defb @01000000
defb @10000100
defb @10000100
defb @01000100
defb @10000000
defb @00000100
defb @01000000
defb @00000000


; Char entry $0122 (offset $0910)
;
;     # #
;     # #
;
;
;
;
;
defb @01000000
defb @10001010
defb @10001010
defb @01000000
defb @10000000
defb @00000000
defb @11000000
defb @10000000


; Char entry $0123 (offset $0918)
;
;     # #
;    #####
;     # #
;    #####
;     # #
;
;
defb @01000000
defb @10001010
defb @01011111
defb @01001010
defb @10011111
defb @11001010
defb @00000000
defb @11000000


; Char entry $0124 (offset $0920)
;
;     ####
;    # #
;     ###
;      # #
;    ####
;
;
defb @11000000
defb @00001111
defb @00010100
defb @11001110
defb @01000101
defb @10011110
defb @01000000
defb @00000000


; Char entry $0125 (offset $0928)
;
;    #   #
;       #
;      #
;     #
;    #   #
;
;
defb @01000000
defb @00010001
defb @00000010
defb @01000100
defb @01001000
defb @10010001
defb @11000000
defb @00000000


; Char entry $0126 (offset $0930)
;
;     ##
;    #  #
;     ##
;    #  #
;     ## #
;
;
defb @10000000
defb @01001100
defb @00010010
defb @00001100
defb @01010010
defb @10001101
defb @11000000
defb @10000000


; Char entry $0127 (offset $0938)
;
;      #
;     #
;
;
;
;
;
defb @01000000
defb @00000100
defb @01001000
defb @01000000
defb @01000000
defb @00000000
defb @11000000
defb @10000000


; Char entry $0128 (offset $0940)
;
;      #
;     #
;     #
;     #
;      #
;
;
defb @01000000
defb @01000100
defb @01001000
defb @00001000
defb @01001000
defb @00000100
defb @01000000
defb @01000000


; Char entry $0129 (offset $0948)
;
;     #
;      #
;      #
;      #
;     #
;
;
defb @01000000
defb @01001000
defb @00000100
defb @10000100
defb @01000100
defb @01001000
defb @01000000
defb @11000000


; Char entry $012A (offset $0950)
;
;
;     # #
;      #
;     # #
;
;
;
defb @10000000
defb @00000000
defb @11001010
defb @11000100
defb @01001010
defb @10000000
defb @01000000
defb @00000000


; Char entry $012B (offset $0958)
;
;
;      #
;     ###
;      #
;
;
;
defb @01000000
defb @01000000
defb @00000100
defb @11001110
defb @01000100
defb @10000000
defb @00000000
defb @11000000


; Char entry $012C (offset $0960)
;
;
;
;
;      #
;     #
;
;
defb @10000000
defb @00000000
defb @11000000
defb @01000000
defb @10000100
defb @10001000
defb @00000000
defb @10000000


; Char entry $012D (offset $0968)
;
;
;
;     ###
;
;
;
;
defb @00000000
defb @10000000
defb @00000000
defb @00001110
defb @01000000
defb @11000000
defb @00000000
defb @01000000


; Char entry $012E (offset $0970)
;
;
;
;
;      #
;      #
;
;
defb @01000000
defb @11000000
defb @01000000
defb @01000000
defb @10000100
defb @01000100
defb @01000000
defb @01000000


; Char entry $012F (offset $0978)
;
;
;       #
;      #
;     #
;
;
;
defb @00000000
defb @10000000
defb @00000010
defb @00000100
defb @10001000
defb @01000000
defb @11000000
defb @10000000


; Char entry $0130 (offset $0980)
;
;     ###
;    #  ##
;    # # #
;    ##  #
;     ###
;
;
defb @01000000
defb @11001110
defb @10010011
defb @01010101
defb @00011001
defb @10001110
defb @00000000
defb @00000000


; Char entry $0131 (offset $0988)
;
;      #
;     ##
;      #
;      #
;      #
;
;
defb @01000000
defb @10000100
defb @11001100
defb @01000100
defb @00000100
defb @10000100
defb @00000000
defb @00000000


; Char entry $0132 (offset $0990)
;
;     ###
;    #   #
;      ##
;     #
;    #####
;
;
defb @10000000
defb @10001110
defb @10010001
defb @11000110
defb @01001000
defb @10011111
defb @11000000
defb @01000000


; Char entry $0133 (offset $0998)
;
;    ####
;        #
;      ##
;        #
;    ####
;
;
defb @01000000
defb @10011110
defb @11000001
defb @01000110
defb @10000001
defb @01011110
defb @00000000
defb @11000000


; Char entry $0134 (offset $09A0)
;
;    #
;    #
;    # #
;    #####
;      #
;
;
defb @01000000
defb @10010000
defb @01010000
defb @00010100
defb @01011111
defb @11000100
defb @00000000
defb @11000000


; Char entry $0135 (offset $09A8)
;
;    #####
;    #
;    ####
;        #
;    ####
;
;
defb @01000000
defb @11011111
defb @00010000
defb @00011110
defb @01000001
defb @10011110
defb @11000000
defb @00000000


; Char entry $0136 (offset $09B0)
;
;     ###
;    #
;    ####
;    #   #
;     ###
;
;
defb @10000000
defb @00001110
defb @00010000
defb @01011110
defb @10010001
defb @11001110
defb @10000000
defb @01000000


; Char entry $0137 (offset $09B8)
;
;    #####
;        #
;       #
;      #
;      #
;
;
defb @10000000
defb @00011111
defb @00000001
defb @01000010
defb @10000100
defb @10000100
defb @11000000
defb @00000000


; Char entry $0138 (offset $09C0)
;
;     ###
;    #   #
;     ###
;    #   #
;     ###
;
;
defb @01000000
defb @00001110
defb @00010001
defb @11001110
defb @11010001
defb @00001110
defb @01000000
defb @10000000


; Char entry $0139 (offset $09C8)
;
;     ###
;    #   #
;     ####
;        #
;     ###
;
;
defb @01000000
defb @11001110
defb @00010001
defb @11001111
defb @10000001
defb @00001110
defb @11000000
defb @11000000


; Char entry $013A (offset $09D0)
;
;
;      #
;
;      #
;
;
;
defb @01000000
defb @00000000
defb @11000100
defb @01000000
defb @10000100
defb @00000000
defb @11000000
defb @00000000


; Char entry $013B (offset $09D8)
;
;
;      #
;
;      #
;     #
;
;
defb @10000000
defb @10000000
defb @10000100
defb @11000000
defb @01000100
defb @11001000
defb @00000000
defb @00000000


; Char entry $013C (offset $09E0)
;
;       #
;      #
;     #
;      #
;       #
;
;
defb @01000000
defb @11000010
defb @10000100
defb @01001000
defb @01000100
defb @00000010
defb @01000000
defb @01000000


; Char entry $013D (offset $09E8)
;
;
;     ###
;
;     ###
;
;
;
defb @01000000
defb @10000000
defb @11001110
defb @10000000
defb @10001110
defb @11000000
defb @00000000
defb @10000000


; Char entry $013E (offset $09F0)
;
;    #
;     #
;      #
;     #
;    #
;
;
defb @10000000
defb @00010000
defb @10001000
defb @01000100
defb @01001000
defb @01010000
defb @00000000
defb @10000000


; Char entry $013F (offset $09F8)
;
;    ####
;        #
;      ##
;
;      #
;
;
defb @01000000
defb @11011110
defb @01000001
defb @01000110
defb @01000000
defb @10000100
defb @00000000
defb @10000000


; Char entry $0140 (offset $0A00)
;
;     ###
;    # # #
;    # ###
;    #
;     ####
;
;
defb @01000000
defb @10001110
defb @11010101
defb @11010111
defb @01010000
defb @11001111
defb @01000000
defb @01000000


; Char entry $0141 (offset $0A08)
;
;     ###
;    #   #
;    #####
;    #   #
;    #   #
;
;
defb @01000000
defb @11001110
defb @01010001
defb @00011111
defb @01010001
defb @00010001
defb @11000000
defb @00000000


; Char entry $0142 (offset $0A10)
;
;    ####
;    #   #
;    ####
;    #   #
;    ####
;
;
defb @01000000
defb @10011110
defb @11010001
defb @11011110
defb @01010001
defb @10011110
defb @00000000
defb @01000000


; Char entry $0143 (offset $0A18)
;
;     ####
;    #
;    #
;    #
;     ####
;
;
defb @01000000
defb @10001111
defb @01010000
defb @00010000
defb @01010000
defb @11001111
defb @00000000
defb @10000000


; Char entry $0144 (offset $0A20)
;
;    ####
;    #   #
;    #   #
;    #   #
;    ####
;
;
defb @01000000
defb @10011110
defb @00010001
defb @01010001
defb @01010001
defb @01011110
defb @00000000
defb @11000000


; Char entry $0145 (offset $0A28)
;
;    #####
;    #
;    ####
;    #
;    #####
;
;
defb @11000000
defb @00011111
defb @01010000
defb @11011110
defb @01010000
defb @10011111
defb @00000000
defb @11000000


; Char entry $0146 (offset $0A30)
;
;    #####
;    #
;    ####
;    #
;    #
;
;
defb @10000000
defb @00011111
defb @01010000
defb @00011110
defb @01010000
defb @10010000
defb @01000000
defb @00000000


; Char entry $0147 (offset $0A38)
;
;     ####
;    #
;    #  ##
;    #   #
;     ####
;
;
defb @01000000
defb @10001111
defb @01010000
defb @01010011
defb @00010001
defb @10001111
defb @10000000
defb @00000000


; Char entry $0148 (offset $0A40)
;
;    #   #
;    #   #
;    #####
;    #   #
;    #   #
;
;
defb @10000000
defb @10010001
defb @00010001
defb @00011111
defb @00010001
defb @10010001
defb @10000000
defb @01000000


; Char entry $0149 (offset $0A48)
;
;     ###
;      #
;      #
;      #
;     ###
;
;
defb @10000000
defb @11001110
defb @00000100
defb @11000100
defb @10000100
defb @00001110
defb @00000000
defb @10000000


; Char entry $014A (offset $0A50)
;
;     ####
;       #
;       #
;    #  #
;     ##
;
;
defb @01000000
defb @11001111
defb @00000010
defb @10000010
defb @10010010
defb @01001100
defb @00000000
defb @11000000


; Char entry $014B (offset $0A58)
;
;    #   #
;    #  #
;    ###
;    #  #
;    #   #
;
;
defb @01000000
defb @10010001
defb @01010010
defb @11011100
defb @01010010
defb @10010001
defb @01000000
defb @01000000


; Char entry $014C (offset $0A60)
;
;    #
;    #
;    #
;    #
;    #####
;
;
defb @01000000
defb @00010000
defb @01010000
defb @01010000
defb @01010000
defb @11011111
defb @10000000
defb @00000000


; Char entry $014D (offset $0A68)
;
;    #   #
;    ## ##
;    # # #
;    #   #
;    #   #
;
;
defb @01000000
defb @00010001
defb @00011011
defb @11010101
defb @10010001
defb @01010001
defb @10000000
defb @01000000


; Char entry $014E (offset $0A70)
;
;    #   #
;    ##  #
;    # # #
;    #  ##
;    #   #
;
;
defb @10000000
defb @01010001
defb @10011001
defb @11010101
defb @01010011
defb @11010001
defb @01000000
defb @00000000


; Char entry $014F (offset $0A78)
;
;     ###
;    #   #
;    #   #
;    #   #
;     ###
;
;
defb @00000000
defb @10001110
defb @11010001
defb @11010001
defb @01010001
defb @00001110
defb @11000000
defb @11000000


; Char entry $0150 (offset $0A80)
;
;    ####
;    #   #
;    ####
;    #
;    #
;
;
defb @01000000
defb @11011110
defb @01010001
defb @10011110
defb @10010000
defb @00010000
defb @01000000
defb @10000000


; Char entry $0151 (offset $0A88)
;
;     ###
;    #   #
;    # # #
;    #  #
;     ## #
;
;
defb @01000000
defb @11001110
defb @01010001
defb @00010101
defb @01010010
defb @11001101
defb @10000000
defb @01000000


; Char entry $0152 (offset $0A90)
;
;    ####
;    #   #
;    ####
;    #  #
;    #   #
;
;
defb @01000000
defb @11011110
defb @00010001
defb @00011110
defb @01010010
defb @10010001
defb @01000000
defb @01000000


; Char entry $0153 (offset $0A98)
;
;     ####
;    #
;     ###
;        #
;    ####
;
;
defb @01000000
defb @11001111
defb @00010000
defb @11001110
defb @01000001
defb @10011110
defb @01000000
defb @01000000


; Char entry $0154 (offset $0AA0)
;
;    #####
;      #
;      #
;      #
;      #
;
;
defb @10000000
defb @11011111
defb @11000100
defb @11000100
defb @10000100
defb @00000100
defb @01000000
defb @11000000


; Char entry $0155 (offset $0AA8)
;
;    #   #
;    #   #
;    #   #
;    #   #
;     ###
;
;
defb @01000000
defb @10010001
defb @00010001
defb @01010001
defb @01010001
defb @10001110
defb @11000000
defb @01000000


; Char entry $0156 (offset $0AB0)
;
;    #   #
;    #   #
;    #   #
;     # #
;      #
;
;
defb @01000000
defb @00010001
defb @01010001
defb @01010001
defb @01001010
defb @01000100
defb @00000000
defb @00000000


; Char entry $0157 (offset $0AB8)
;
;    #   #
;    #   #
;    # # #
;    # # #
;     # #
;
;
defb @01000000
defb @01010001
defb @00010001
defb @10010101
defb @01010101
defb @00001010
defb @11000000
defb @11000000


; Char entry $0158 (offset $0AC0)
;
;    #   #
;     # #
;      #
;     # #
;    #   #
;
;
defb @01000000
defb @00010001
defb @11001010
defb @01000100
defb @10001010
defb @00010001
defb @01000000
defb @10000000


; Char entry $0159 (offset $0AC8)
;
;    #   #
;     # #
;      #
;      #
;      #
;
;
defb @00000000
defb @10010001
defb @00001010
defb @00000100
defb @01000100
defb @11000100
defb @11000000
defb @11000000


; Char entry $015A (offset $0AD0)
;
;    #####
;       #
;      #
;     #
;    #####
;
;
defb @10000000
defb @00011111
defb @11000010
defb @01000100
defb @01001000
defb @11011111
defb @01000000
defb @00000000


; Char entry $015B (offset $0AD8)
;
;     ##
;     #
;     #
;     #
;     ##
;
;
defb @11000000
defb @00001100
defb @01001000
defb @10001000
defb @01001000
defb @10001100
defb @11000000
defb @10000000


; Char entry $015C (offset $0AE0)
;
;
;     #
;      #
;       #
;
;
;
defb @11000000
defb @10000000
defb @01001000
defb @00000100
defb @01000010
defb @10000000
defb @01000000
defb @11000000


; Char entry $015D (offset $0AE8)
;
;     ##
;      #
;      #
;      #
;     ##
;
;
defb @10000000
defb @00001100
defb @11000100
defb @01000100
defb @01000100
defb @10001100
defb @01000000
defb @01000000


; Char entry $015E (offset $0AF0)
;
;      #
;     # #
;
;
;
;
;
defb @01000000
defb @11000100
defb @00001010
defb @11000000
defb @00000000
defb @10000000
defb @00000000
defb @10000000


; Char entry $015F (offset $0AF8)
;
;
;
;
;
;    #####
;
;
defb @00000000
defb @10000000
defb @00000000
defb @00000000
defb @01000000
defb @10011111
defb @00000000
defb @11000000


; Char entry $0160 (offset $0B00)
;
;     #
;      #
;
;
;
;
;
defb @10000000
defb @11001000
defb @11000100
defb @00000000
defb @01000000
defb @11000000
defb @01000000
defb @10000000


; Char entry $0161 (offset $0B08)
;
;
;     ###
;    #  #
;    #  #
;     ####
;
;
defb @10000000
defb @00000000
defb @01001110
defb @10010010
defb @10010010
defb @10001111
defb @11000000
defb @11000000


; Char entry $0162 (offset $0B10)
;
;    #
;    #
;    ###
;    #  #
;    ###
;
;
defb @10000000
defb @11010000
defb @00010000
defb @10011100
defb @10010010
defb @00011100
defb @01000000
defb @01000000


; Char entry $0163 (offset $0B18)
;
;
;     ###
;    #
;    #
;     ###
;
;
defb @10000000
defb @11000000
defb @10001110
defb @11010000
defb @11010000
defb @10001110
defb @01000000
defb @01000000


; Char entry $0164 (offset $0B20)
;
;       #
;       #
;     ###
;    #  #
;     ###
;
;
defb @10000000
defb @11000010
defb @01000010
defb @11001110
defb @01010010
defb @10001110
defb @10000000
defb @01000000


; Char entry $0165 (offset $0B28)
;
;
;     ##
;    ####
;    #
;     ##
;
;
defb @10000000
defb @10000000
defb @11001100
defb @11011110
defb @11010000
defb @01001100
defb @01000000
defb @11000000


; Char entry $0166 (offset $0B30)
;
;      ##
;     #
;    ####
;     #
;     #
;
;
defb @01000000
defb @11000110
defb @01001000
defb @11011110
defb @01001000
defb @10001000
defb @10000000
defb @01000000


; Char entry $0167 (offset $0B38)
;
;
;     ###
;    #  #
;     ###
;       #
;     ##
;
defb @10000000
defb @00000000
defb @10001110
defb @00010010
defb @00001110
defb @10000010
defb @00001100
defb @00000000


; Char entry $0168 (offset $0B40)
;
;    #
;    #
;    ###
;    #  #
;    #  #
;
;
defb @01000000
defb @10010000
defb @11010000
defb @01011100
defb @10010010
defb @10010010
defb @00000000
defb @11000000


; Char entry $0169 (offset $0B48)
;
;      #
;
;      #
;      #
;      #
;
;
defb @00000000
defb @10000100
defb @00000000
defb @10000100
defb @01000100
defb @10000100
defb @01000000
defb @00000000


; Char entry $016A (offset $0B50)
;
;       #
;
;       #
;       #
;     # #
;      #
;
defb @11000000
defb @00000010
defb @00000000
defb @11000010
defb @10000010
defb @11001010
defb @11000100
defb @11000000


; Char entry $016B (offset $0B58)
;
;    #
;    #  #
;    ###
;    # #
;    #  #
;
;
defb @10000000
defb @00010000
defb @01010010
defb @10011100
defb @10010100
defb @01010010
defb @00000000
defb @01000000


; Char entry $016C (offset $0B60)
;
;      #
;      #
;      #
;      #
;      #
;
;
defb @10000000
defb @00000100
defb @11000100
defb @11000100
defb @01000100
defb @11000100
defb @00000000
defb @11000000


; Char entry $016D (offset $0B68)
;
;
;     # #
;    # # #
;    # # #
;    #   #
;
;
defb @01000000
defb @00000000
defb @11001010
defb @01010101
defb @10010101
defb @01010001
defb @00000000
defb @01000000


; Char entry $016E (offset $0B70)
;
;
;    ###
;    #  #
;    #  #
;    #  #
;
;
defb @10000000
defb @11000000
defb @01011100
defb @00010010
defb @10010010
defb @10010010
defb @01000000
defb @10000000


; Char entry $016F (offset $0B78)
;
;
;     ##
;    #  #
;    #  #
;     ##
;
;
defb @01000000
defb @11000000
defb @00001100
defb @10010010
defb @11010010
defb @00001100
defb @10000000
defb @10000000


; Char entry $0170 (offset $0B80)
;
;
;    ###
;    #  #
;    ###
;    #
;    #
;
defb @00000000
defb @10000000
defb @10011100
defb @00010010
defb @10011100
defb @01010000
defb @11010000
defb @11000000


; Char entry $0171 (offset $0B88)
;
;
;     ###
;    #  #
;     ###
;       #
;       ##
;
defb @00000000
defb @10000000
defb @10001110
defb @01010010
defb @01001110
defb @01000010
defb @00000011
defb @11000000


; Char entry $0172 (offset $0B90)
;
;
;    ###
;    #  #
;    #
;    #
;
;
defb @10000000
defb @10000000
defb @01011100
defb @01010010
defb @01010000
defb @11010000
defb @01000000
defb @00000000


; Char entry $0173 (offset $0B98)
;
;
;     ###
;    ##
;      ##
;    ###
;
;
defb @01000000
defb @10000000
defb @00001110
defb @01011000
defb @01000110
defb @11011100
defb @10000000
defb @01000000


; Char entry $0174 (offset $0BA0)
;
;     #
;    ####
;     #
;     # #
;      #
;
;
defb @01000000
defb @10001000
defb @10011110
defb @01001000
defb @01001010
defb @11000100
defb @01000000
defb @00000000


; Char entry $0175 (offset $0BA8)
;
;
;    #  #
;    #  #
;    #  #
;     ###
;
;
defb @10000000
defb @11000000
defb @10010010
defb @10010010
defb @01010010
defb @11001110
defb @00000000
defb @11000000


; Char entry $0176 (offset $0BB0)
;
;
;    #   #
;    #   #
;     # #
;      #
;
;
defb @01000000
defb @01000000
defb @00010001
defb @00010001
defb @01001010
defb @11000100
defb @00000000
defb @10000000


; Char entry $0177 (offset $0BB8)
;
;
;    #   #
;    #   #
;    # # #
;     # #
;
;
defb @10000000
defb @00000000
defb @01010001
defb @01010001
defb @01010101
defb @11001010
defb @01000000
defb @00000000


; Char entry $0178 (offset $0BC0)
;
;
;    #  #
;     ##
;     ##
;    #  #
;
;
defb @01000000
defb @01000000
defb @00010010
defb @11001100
defb @01001100
defb @11010010
defb @01000000
defb @11000000


; Char entry $0179 (offset $0BC8)
;
;
;    #  #
;    #  #
;     ###
;       #
;     ##
;
defb @01000000
defb @10000000
defb @00010010
defb @01010010
defb @01001110
defb @11000010
defb @00001100
defb @00000000


; Char entry $017A (offset $0BD0)
;
;
;    ####
;      #
;     #
;    ####
;
;
defb @00000000
defb @10000000
defb @00011110
defb @00000100
defb @01001000
defb @00011110
defb @00000000
defb @11000000


; Char entry $017B (offset $0BD8)
;
;      ##
;      #
;     #
;      #
;      ##
;
;
defb @01000000
defb @10000110
defb @00000100
defb @01001000
defb @11000100
defb @10000110
defb @10000000
defb @11000000


; Char entry $017C (offset $0BE0)
;
;      #
;      #
;
;      #
;      #
;
;
defb @01000000
defb @01000100
defb @00000100
defb @00000000
defb @00000100
defb @00000100
defb @00000000
defb @01000000


; Char entry $017D (offset $0BE8)
;
;    ##
;     #
;      #
;     #
;    ##
;
;
defb @01000000
defb @01011000
defb @10001000
defb @01000100
defb @11001000
defb @11011000
defb @11000000
defb @11000000


; Char entry $017E (offset $0BF0)
;
;      # #
;     # #
;
;
;
;
;
defb @11000000
defb @11000101
defb @11001010
defb @11000000
defb @11000000
defb @11000000
defb @11000000
defb @11000000


; Char entry $017F (offset $0BF8)
;
;    #####
;    #####
;    #####
;    #####
;    #####
;
;
defb @11000000
defb @11011111
defb @11011111
defb @11011111
defb @11011111
defb @11011111
defb @11000000
defb @11000000


; Char entry $0180 (offset $0C00)
;   #####
;  #######
;  ##   ##
;  ##   ##
;  ##   ##
;  #######
;   #####
;
defb @00111110
defb @01111111
defb @01100011
defb @01100011
defb @01100011
defb @01111111
defb @00111110
defb @00000000


; Char entry $0181 (offset $0C08)
;  #######
;  #######
;     ###
;    ###
;   ###
;  #######
;  #######
;
defb @01111111
defb @01111111
defb @00001110
defb @00011100
defb @00111000
defb @01111111
defb @01111111
defb @00000000


; Char entry $0182 (offset $0C10)
;  #   ###
;  #   # #
;  ### ###
;
;    ### #
;    # # #
;    ### #
;
defb @01000111
defb @01000101
defb @01110111
defb @00000000
defb @00011101
defb @00010101
defb @00011101
defb @00000000


; Char entry $0183 (offset $0C18)
;  ### # #
;  #   ##
;  ### # #
;
;  # ###
;  #  #
; ##  #
;
defb @01110101
defb @01000110
defb @01110101
defb @00000000
defb @01011100
defb @01001000
defb @11001000
defb @00000000


; Char entry $0184 (offset $0C20)
;
;   ## ###
;  #   # #
;  #   ###
;  #   # #
;   ## # #
;
;
defb @00000000
defb @00110111
defb @01000101
defb @01000111
defb @01000101
defb @00110101
defb @00000000
defb @00000000


; Char entry $0185 (offset $0C28)
;
;  ### ###
;  # # #
;  ### ###
;  #     #
;  #   ###
;
;
defb @00000000
defb @01110111
defb @01010100
defb @01110111
defb @01000001
defb @01000111
defb @00000000
defb @00000000


; Char entry $0186 (offset $0C30)
;
;   ##  ##
;  #   # #
;  #   # #
;  #   # #
;   ##  ##
;
;
defb @00000000
defb @00110011
defb @01000101
defb @01000101
defb @01000101
defb @00110011
defb @00000000
defb @00000000


; Char entry $0187 (offset $0C38)
;
;  ##   ##
;  # # #
;  # # ###
;  # #   #
;  ##  ##
;  #
;  #
defb @00000000
defb @01100011
defb @01010100
defb @01010111
defb @01010001
defb @01100110
defb @01000000
defb @01000000


; Char entry $0188 (offset $0C40)
;
;    ### #
;   #    #
;   #    #
;   #    #
;   #    #
;    ### #
;
defb @00000000
defb @00011101
defb @00100001
defb @00100001
defb @00100001
defb @00100001
defb @00011101
defb @00000000


; Char entry $0189 (offset $0C48)
;
;     ###
;      #
;      #
;      #
;      #
; ### ###
;
defb @00000000
defb @00001110
defb @00000100
defb @00000100
defb @00000100
defb @00000100
defb @11101110
defb @00000000


; Char entry $018A (offset $0C50)
;  #######
;  #   ##
;  # ### #
;  #   #
;  # ### #
;  # ### #
;  #######
;
defb @01111111
defb @01000110
defb @01011101
defb @01000100
defb @01011101
defb @01011101
defb @01111111
defb @00000000


; Char entry $018B (offset $0C58)
; ########
; ## # ###
;  # # ###
;  # # ###
;  # # ###
;  # #   #
; ########
;
defb @11111111
defb @11010111
defb @01010111
defb @01010111
defb @01010111
defb @01010001
defb @11111111
defb @00000000


; Char entry $018C (offset $0C60)
; ########
; #  ### #
; # # # #
; #  ##
; # # # #
; #  ## #
; ########
;
defb @11111111
defb @10011101
defb @10101010
defb @10011000
defb @10101010
defb @10011010
defb @11111111
defb @00000000


; Char entry $018D (offset $0C68)
; ######
; #   ##
; ## #####
; ## #####
; ## #####
; ## ###
; ######
;
defb @11111100
defb @10001100
defb @11011111
defb @11011111
defb @11011111
defb @11011100
defb @11111100
defb @00000000


; Char entry $018E (offset $0C70)
; ########
; # ##   #
; # ## # #
; # ## # #
; # ## # #
; #  #   #
; ########
;
defb @11111111
defb @10110001
defb @10110101
defb @10110101
defb @10110101
defb @10010001
defb @11111111
defb @00000000


; Char entry $018F (offset $0C78)
; ######
;  ### #
;  ### ###
;  # # ###
;  # # ###
; # # ##
; ######
;
defb @11111100
defb @01110100
defb @01110111
defb @01010111
defb @01010111
defb @10101100
defb @11111100
defb @00000000


; Char entry $0190 (offset $0C80)
;
;     #
;    ###
;   ## ##
;  ##   ##
;   ## ##
;    ###
;     #
defb @00000000
defb @00001000
defb @00011100
defb @00110110
defb @01100011
defb @00110110
defb @00011100
defb @00001000


; Char entry $0191 (offset $0C88)
;
;  #######
;  #######
;  ##   ##
;  ##   ##
;  ##   ##
;  #######
;  #######
defb @00000000
defb @01111111
defb @01111111
defb @01100011
defb @01100011
defb @01100011
defb @01111111
defb @01111111


; Char entry $0192 (offset $0C90)
; #      #
;  #    ##
;   #   ##
;       ##
;      ###
;   # ####
;  #  ####
; #      #
defb @10000001
defb @01000011
defb @00100011
defb @00000011
defb @00000111
defb @00101111
defb @01001111
defb @10000001


; Char entry $0193 (offset $0C98)
; #      #
; ##    #
; ##   #
; ##
; ###
; #### #
; ####  #
; #      #
defb @10000001
defb @11000010
defb @11000100
defb @11000000
defb @11100000
defb @11110100
defb @11110010
defb @10000001


; Char entry $0194 (offset $0CA0)
;
;  ##  #
; #   # #
; #   ###
; #   # #
;  ## # #
;
; ########
defb @00000000
defb @01100100
defb @10001010
defb @10001110
defb @10001010
defb @01101010
defb @00000000
defb @11111111


; Char entry $0195 (offset $0CA8)
;
; ##  ##
; # # # #
; ##  # #
; # # # #
; # # ##
;
; #######
defb @00000000
defb @11001100
defb @10101010
defb @11001010
defb @10101010
defb @10101100
defb @00000000
defb @11111110


; Char entry $0196 (offset $0CB0)
;
; # ##  ##
; # # # #
; # # # #
; # # # #
; # # # ##
;
; ########
defb @00000000
defb @10110011
defb @10101010
defb @10101010
defb @10101010
defb @10101011
defb @00000000
defb @11111111


; Char entry $0197 (offset $0CB8)
;
;   ## # #
; # #  # #
; # ##  #
; # #  # #
;   ## # #
;
; ########
defb @00000000
defb @00110101
defb @10100101
defb @10110010
defb @10100101
defb @00110101
defb @00000000
defb @11111111


; Char entry $0198 (offset $0CC0)
;
;
;
;       ##
;     ###
;      #
;      ###
;
defb @00000000
defb @00000000
defb @00000000
defb @00000011
defb @00001110
defb @00000100
defb @00000111
defb @00000000


; Char entry $0199 (offset $0CC8)
;
;     ##
;   ##  ##
;
;
;
;   ######
;
defb @00000000
defb @00001100
defb @00110011
defb @00000000
defb @00000000
defb @00000000
defb @00111111
defb @00000000


; Char entry $019A (offset $0CD0)
;
;
;
;   ##
;    ###
;     #
;   ###
;
defb @00000000
defb @00000000
defb @00000000
defb @00110000
defb @00011100
defb @00001000
defb @00111000
defb @00000000


; Char entry $019B (offset $0CD8)
;    #
;     #
;      #
;
;
;      # #
;     #  #
;    #
defb @00010000
defb @00001000
defb @00000100
defb @00000000
defb @00000000
defb @00000101
defb @00001001
defb @00010000


; Char entry $019C (offset $0CE0)
;     ##
;    ####
;    ####
;    ####
;   ######
;   ######
;   ######
;     ##
defb @00001100
defb @00011110
defb @00011110
defb @00011110
defb @00111111
defb @00111111
defb @00111111
defb @00001100


; Char entry $019D (offset $0CE8)
;       #
;      #
;     #
;
;
;   # #
;   #  #
;       #
defb @00000010
defb @00000100
defb @00001000
defb @00000000
defb @00000000
defb @00101000
defb @00100100
defb @00000010


; Char entry $019E (offset $0CF0)
;
;  ##  ##
;  ##  ##
;
;
;
;
;
defb @00000000
defb @01100110
defb @01100110
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000


; Char entry $019F (offset $0CF8)
;
;    ###
;   ## ##
;   ##
;  #####
;   ##
;  ######
;
defb @00000000
defb @00011100
defb @00110110
defb @00110000
defb @01111100
defb @00110000
defb @01111110
defb @00000000


; Char entry $01A0 (offset $0D00)
;
;
;
;
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000


; Char entry $01A1 (offset $0D08)
;
;    ##
;    ##
;    ##
;    ##
;
;    ##
;
defb @00000000
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00000000
defb @00011000
defb @00000000


; Char entry $01A2 (offset $0D10)
;
;  ##  ##
;  ##  ##
;
;
;
;
;
defb @00000000
defb @01100110
defb @01100110
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000


; Char entry $01A3 (offset $0D18)
;
;   ## ##
;  #######
;   ## ##
;  #######
;   ## ##
;   ## ##
;
defb @00000000
defb @00110110
defb @01111111
defb @00110110
defb @01111111
defb @00110110
defb @00110110
defb @00000000


; Char entry $01A4 (offset $0D20)
;
;   #####
;  ## # ##
;   ###
;     ###
;  ## # ##
;   #####
;
defb @00000000
defb @00111110
defb @01101011
defb @00111000
defb @00001110
defb @01101011
defb @00111110
defb @00000000


; Char entry $01A5 (offset $0D28)
;
;  ##   #
;  ##  #
;     #
;    #
;   #  ##
;  #   ##
;
defb @00000000
defb @01100010
defb @01100100
defb @00001000
defb @00010000
defb @00100110
defb @01000110
defb @00000000


; Char entry $01A6 (offset $0D30)
;
;   ####
;  ##  ##
;   ####
;  ##  # #
;  ##  ##
;   #### #
;
defb @00000000
defb @00111100
defb @01100110
defb @00111100
defb @01100101
defb @01100110
defb @00111101
defb @00000000


; Char entry $01A7 (offset $0D38)
;
;      ##
;     ##
;    ##
;
;
;
;
defb @00000000
defb @00000110
defb @00001100
defb @00011000
defb @00000000
defb @00000000
defb @00000000
defb @00000000


; Char entry $01A8 (offset $0D40)
;
;     ##
;    ##
;    ##
;    ##
;    ##
;     ##
;
defb @00000000
defb @00001100
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00001100
defb @00000000


; Char entry $01A9 (offset $0D48)
;
;   ##
;    ##
;    ##
;    ##
;    ##
;   ##
;
defb @00000000
defb @00110000
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00110000
defb @00000000


; Char entry $01AA (offset $0D50)
;
;    ##
;  ######
;   ####
;  ######
;    ##
;
;
defb @00000000
defb @00011000
defb @01111110
defb @00111100
defb @01111110
defb @00011000
defb @00000000
defb @00000000


; Char entry $01AB (offset $0D58)
;
;    ##
;    ##
;  ######
;    ##
;    ##
;
;
defb @00000000
defb @00011000
defb @00011000
defb @01111110
defb @00011000
defb @00011000
defb @00000000
defb @00000000


; Char entry $01AC (offset $0D60)
;
;
;
;
;
;    ##
;   ##
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00011000
defb @00110000
defb @00000000


; Char entry $01AD (offset $0D68)
;
;
;
;  ######
;
;
;
;
defb @00000000
defb @00000000
defb @00000000
defb @01111110
defb @00000000
defb @00000000
defb @00000000
defb @00000000


; Char entry $01AE (offset $0D70)
;
;
;
;
;
;    ##
;    ##
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00011000
defb @00011000
defb @00000000


; Char entry $01AF (offset $0D78)
;
;      ##
;     ##
;    ##
;   ##
;  ##
;
;
defb @00000000
defb @00000110
defb @00001100
defb @00011000
defb @00110000
defb @01100000
defb @00000000
defb @00000000


; Char entry $01B0 (offset $0D80)
;
;   #####
;  ##   ##
;  ## ####
;  #### ##
;  ##   ##
;   #####
;
defb @00000000
defb @00111110
defb @01100011
defb @01101111
defb @01111011
defb @01100011
defb @00111110
defb @00000000


; Char entry $01B1 (offset $0D88)
;
;    ##
;   ###
;    ##
;    ##
;    ##
;    ##
;
defb @00000000
defb @00011000
defb @00111000
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00000000


; Char entry $01B2 (offset $0D90)
;
;   ####
;  ##  ##
;     ##
;    ##
;   ##
;  ######
;
defb @00000000
defb @00111100
defb @01100110
defb @00001100
defb @00011000
defb @00110000
defb @01111110
defb @00000000


; Char entry $01B3 (offset $0D98)
;
;  ######
;      ##
;    ###
;      ##
;  ##  ##
;   ####
;
defb @00000000
defb @01111110
defb @00000110
defb @00011100
defb @00000110
defb @01100110
defb @00111100
defb @00000000


; Char entry $01B4 (offset $0DA0)
;
;     ##
;    ###
;   # ##
;  #  ##
;  ######
;     ##
;
defb @00000000
defb @00001100
defb @00011100
defb @00101100
defb @01001100
defb @01111110
defb @00001100
defb @00000000


; Char entry $01B5 (offset $0DA8)
;
;  ######
;  ##
;  #####
;      ##
;      ##
;  #####
;
defb @00000000
defb @01111110
defb @01100000
defb @01111100
defb @00000110
defb @00000110
defb @01111100
defb @00000000


; Char entry $01B6 (offset $0DB0)
;
;   ####
;  ##
;  #####
;  ##  ##
;  ##  ##
;   ####
;
defb @00000000
defb @00111100
defb @01100000
defb @01111100
defb @01100110
defb @01100110
defb @00111100
defb @00000000


; Char entry $01B7 (offset $0DB8)
;
;  ######
;      ##
;     ##
;    ##
;   ##
;  ##
;
defb @00000000
defb @01111110
defb @00000110
defb @00001100
defb @00011000
defb @00110000
defb @01100000
defb @00000000


; Char entry $01B8 (offset $0DC0)
;
;   ####
;  ##  ##
;   ####
;  ##  ##
;  ##  ##
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @00111100
defb @01100110
defb @01100110
defb @00111100
defb @00000000


; Char entry $01B9 (offset $0DC8)
;
;   ####
;  ##  ##
;   #####
;      ##
;      ##
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @00111110
defb @00000110
defb @00000110
defb @00111100
defb @00000000


; Char entry $01BA (offset $0DD0)
;
;
;    ##
;    ##
;
;    ##
;    ##
;
defb @00000000
defb @00000000
defb @00011000
defb @00011000
defb @00000000
defb @00011000
defb @00011000
defb @00000000


; Char entry $01BB (offset $0DD8)
;
;
;    ##
;    ##
;
;    ##
;   ##
;
defb @00000000
defb @00000000
defb @00011000
defb @00011000
defb @00000000
defb @00011000
defb @00110000
defb @00000000


; Char entry $01BC (offset $0DE0)
;
;     ##
;    ##
;   ##
;    ##
;     ##
;
;
defb @00000000
defb @00001100
defb @00011000
defb @00110000
defb @00011000
defb @00001100
defb @00000000
defb @00000000


; Char entry $01BD (offset $0DE8)
;
;
;   ####
;
;   ####
;
;
;
defb @00000000
defb @00000000
defb @00111100
defb @00000000
defb @00111100
defb @00000000
defb @00000000
defb @00000000


; Char entry $01BE (offset $0DF0)
;
;   ##
;    ##
;     ##
;    ##
;   ##
;
;
defb @00000000
defb @00110000
defb @00011000
defb @00001100
defb @00011000
defb @00110000
defb @00000000
defb @00000000


; Char entry $01BF (offset $0DF8)
;
;   ####
;  ##  ##
;     ##
;    ##
;
;    ##
;
defb @00000000
defb @00111100
defb @01100110
defb @00001100
defb @00011000
defb @00000000
defb @00011000
defb @00000000


; Char entry $01C0 (offset $0E00)
;
;   ######
;  ##   ##
;  ## ####
;  ## ###
;  ##
;   #####
;
defb @00000000
defb @00111111
defb @01100011
defb @01101111
defb @01101110
defb @01100000
defb @00111110
defb @00000000


; Char entry $01C1 (offset $0E08)
;
;   ####
;  ##  ##
;  ##  ##
;  ######
;  ##  ##
;  ##  ##
;
defb @00000000
defb @00111100
defb @01100110
defb @01100110
defb @01111110
defb @01100110
defb @01100110
defb @00000000


; Char entry $01C2 (offset $0E10)
;
;  #####
;  ##  ##
;  #####
;  ##  ##
;  ##  ##
;  #####
;
defb @00000000
defb @01111100
defb @01100110
defb @01111100
defb @01100110
defb @01100110
defb @01111100
defb @00000000


; Char entry $01C3 (offset $0E18)
;
;   ####
;  ##  ##
;  ##
;  ##
;  ##  ##
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @01100000
defb @01100000
defb @01100110
defb @00111100
defb @00000000


; Char entry $01C4 (offset $0E20)
;
;  #####
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;  #####
;
defb @00000000
defb @01111100
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @01111100
defb @00000000


; Char entry $01C5 (offset $0E28)
;
;  ######
;  ##
;  #####
;  ##
;  ##
;  ######
;
defb @00000000
defb @01111110
defb @01100000
defb @01111100
defb @01100000
defb @01100000
defb @01111110
defb @00000000


; Char entry $01C6 (offset $0E30)
;
;  ######
;  ##
;  #####
;  ##
;  ##
;  ##
;
defb @00000000
defb @01111110
defb @01100000
defb @01111100
defb @01100000
defb @01100000
defb @01100000
defb @00000000


; Char entry $01C7 (offset $0E38)
;
;   ####
;  ##  ##
;  ##
;  ## ###
;  ##   #
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @01100000
defb @01101110
defb @01100010
defb @00111100
defb @00000000


; Char entry $01C8 (offset $0E40)
;
;  ##  ##
;  ##  ##
;  ######
;  ##  ##
;  ##  ##
;  ##  ##
;
defb @00000000
defb @01100110
defb @01100110
defb @01111110
defb @01100110
defb @01100110
defb @01100110
defb @00000000


; Char entry $01C9 (offset $0E48)
;
;   ####
;    ##
;    ##
;    ##
;    ##
;   ####
;
defb @00000000
defb @00111100
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00111100
defb @00000000


; Char entry $01CA (offset $0E50)
;
;   #####
;     ##
;     ##
;     ##
;  ## ##
;   ###
;
defb @00000000
defb @00111110
defb @00001100
defb @00001100
defb @00001100
defb @01101100
defb @00111000
defb @00000000


; Char entry $01CB (offset $0E58)
;
;  ##  ##
;  ## ##
;  ####
;  ####
;  ## ##
;  ##  ##
;
defb @00000000
defb @01100110
defb @01101100
defb @01111000
defb @01111000
defb @01101100
defb @01100110
defb @00000000


; Char entry $01CC (offset $0E60)
;
;  ##
;  ##
;  ##
;  ##
;  ##
;  ######
;
defb @00000000
defb @01100000
defb @01100000
defb @01100000
defb @01100000
defb @01100000
defb @01111110
defb @00000000


; Char entry $01CD (offset $0E68)
;
;  ##   ##
;  ### ###
;  ## # ##
;  ## # ##
;  ##   ##
;  ##   ##
;
defb @00000000
defb @01100011
defb @01110111
defb @01101011
defb @01101011
defb @01100011
defb @01100011
defb @00000000


; Char entry $01CE (offset $0E70)
;
;  ##  ##
;  ##  ##
;  ### ##
;  ## ###
;  ##  ##
;  ##  ##
;
defb @00000000
defb @01100110
defb @01100110
defb @01110110
defb @01101110
defb @01100110
defb @01100110
defb @00000000


; Char entry $01CF (offset $0E78)
;
;   ####
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;   ####
;
defb @00000000
defb @00111100
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @00111100
defb @00000000


; Char entry $01D0 (offset $0E80)
;
;  #####
;  ##  ##
;  #####
;  ##
;  ##
;  ##
;
defb @00000000
defb @01111100
defb @01100110
defb @01111100
defb @01100000
defb @01100000
defb @01100000
defb @00000000


; Char entry $01D1 (offset $0E88)
;
;   #####
;  ##   ##
;  ##   ##
;  ## # ##
;  ##  #
;   ### ##
;
defb @00000000
defb @00111110
defb @01100011
defb @01100011
defb @01101011
defb @01100100
defb @00111011
defb @00000000


; Char entry $01D2 (offset $0E90)
;
;  #####
;  ##  ##
;  #####
;  ####
;  ## ##
;  ##  ##
;
defb @00000000
defb @01111100
defb @01100110
defb @01111100
defb @01111000
defb @01101100
defb @01100110
defb @00000000


; Char entry $01D3 (offset $0E98)
;
;   #####
;  ##   ##
;   ###
;     ###
;  ##   ##
;   #####
;
defb @00000000
defb @00111110
defb @01100011
defb @00111000
defb @00001110
defb @01100011
defb @00111110
defb @00000000


; Char entry $01D4 (offset $0EA0)
;
;  ######
;    ##
;    ##
;    ##
;    ##
;    ##
;
defb @00000000
defb @01111110
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00011000
defb @00000000


; Char entry $01D5 (offset $0EA8)
;
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;   ####
;
defb @00000000
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @00111100
defb @00000000


; Char entry $01D6 (offset $0EB0)
;
;  ##  ##
;  ##  ##
;  ##  ##
;  ##  ##
;   #  #
;    ##
;
defb @00000000
defb @01100110
defb @01100110
defb @01100110
defb @01100110
defb @00100100
defb @00011000
defb @00000000


; Char entry $01D7 (offset $0EB8)
;
;  ##   ##
;  ##   ##
;  ## # ##
;  ## # ##
;  ### ###
;  ##   ##
;
defb @00000000
defb @01100011
defb @01100011
defb @01101011
defb @01101011
defb @01110111
defb @01100011
defb @00000000


; Char entry $01D8 (offset $0EC0)
;
;  ##   ##
;   ## ##
;    ###
;    ###
;   ## ##
;  ##   ##
;
defb @00000000
defb @01100011
defb @00110110
defb @00011100
defb @00011100
defb @00110110
defb @01100011
defb @00000000


; Char entry $01D9 (offset $0EC8)
;
;  ##  ##
;  ##  ##
;   ####
;    ##
;    ##
;    ##
;
defb @00000000
defb @01100110
defb @01100110
defb @00111100
defb @00011000
defb @00011000
defb @00011000
defb @00000000


; Char entry $01DA (offset $0ED0)
;
;  ######
;      ##
;     ##
;    ##
;   ##
;  ######
;
defb @00000000
defb @01111110
defb @00000110
defb @00001100
defb @00011000
defb @00110000
defb @01111110
defb @00000000


; Char entry $01DB (offset $0ED8)
;
;   ####
;   ##
;   ##
;   ##
;   ##
;   ####
;
defb @00000000
defb @00111100
defb @00110000
defb @00110000
defb @00110000
defb @00110000
defb @00111100
defb @00000000


; Char entry $01DC (offset $0EE0)
;
;  ##
;   ##
;    ##
;     ##
;      ##
;
;
defb @00000000
defb @01100000
defb @00110000
defb @00011000
defb @00001100
defb @00000110
defb @00000000
defb @00000000


; Char entry $01DD (offset $0EE8)
;
;   ####
;     ##
;     ##
;     ##
;     ##
;   ####
;
defb @00000000
defb @00111100
defb @00001100
defb @00001100
defb @00001100
defb @00001100
defb @00111100
defb @00000000


; Char entry $01DE (offset $0EF0)
;
;   ####
;  ##  ##
;
;
;
;
;
defb @00000000
defb @00111100
defb @01100110
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000


; Char entry $01DF (offset $0EF8)
;
;
;
;
;
;  ######
;  ######
;
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @00000000
defb @01111110
defb @01111110
defb @00000000
