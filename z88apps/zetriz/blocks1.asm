; *************************************************************************************
; ZetriZ
; (C) Gunther Strube (gbs@users.sf.net) 1995-2006
;
; ZetriZ is free software; you can redistribute it and/or modify it under the terms of the
; GNU General Public License as published by the Free Software Foundation;
; either version 2, or (at your option) any later version.
; ZetriZ is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
; You should have received a copy of the GNU General Public License along with ZetriZ;
; see the file COPYING. If not, write to the
; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
;
; $Id$
;
; *************************************************************************************

module zetriz_blocks1

xref block1_r, block2_r, block7_r, block3_r, block4_r, block5_r, block6_r, block1a_r
xref block2a_r, block7a_r, block3a_r, block4a_r, block6a_r, block1b_r, block2b_r
xref block7b_r, block1c_r, block2c_r, block7c_r, block8_r, block9_r, block10_r, block11_r
xref block12_r, block13_r, block14_r, block15_r, block16_r, block17_r, block18_r
xref block19_r, block20_r, block8a_r, block9a_r, block10a_r, block11a_r, block12a_r
xref block13a_r, block14a_r, block15a_r, block16a_r, block17a_r, block18a_r, block19a_r
xref block20a_r, block8b_r, block10b_r, block11b_r, block12b_r, block13b_r, block14b_r
xref block16b_r, block17b_r, block18b_r, block19b_r, block20b_r, block8c_r, block10c_r
xref block11c_r, block12c_r, block13c_r, block14c_r, block16c_r, block17c_r, block18c_r
xref block19c_r, block20c_r, block21_r, block21a_r

xdef blocks, block0

;
; array of pointers to tetris blocks
;
; standard blocks from 0 - 18, extended blocks from 19 - 68
;
.blocks             defw block1,   0    ;block1_r      0
                    defw block2,   0    ;block2_r      1
                    defw block7,   0    ;block7_r      2
                    defw block3,   0    ;block3_r      3
                    defw block4,   0    ;block4_r      4
                    defw block5,   0    ;block5_r      5
                    defw block6,   0    ;block6_r      6
                    defw block1a,  0    ;block1a_r     7
                    defw block2a,  0    ;block2a_r     8
                    defw block7a,  0    ;block7a_r     9
                    defw block3a,  0    ;block3a_r     10
                    defw block4a,  0    ;block4a_r     11
                    defw block6a,  0    ;block6a_r     12
                    defw block1b,  0    ;block1b_r     13
                    defw block2b,  0    ;block2b_r     14

                    defw block7b,  0    ;block7b_r     15
                    defw block1c,  0    ;block1c_r     16
                    defw block2c,  0    ;block2c_r     17
                    defw block7c,  0    ;block7c_r     18

                    defw block8,   0    ;block8_r      19
                    defw block9,   0    ;block9_r      20
                    defw block10,  0    ;block10_r     21
                    defw block11,  0    ;block11_r     22
                    defw block12,  0    ;block12_r     23
                    defw block13,  0    ;block13_r     24
                    defw block14,  0    ;block14_r     25
                    defw block15,  0    ;block15_r     26
                    defw block16,  0    ;block16_r     27
                    defw block17,  0    ;block17_r     28
                    defw block18,  0    ;block18_r     29
                    defw block19,  0    ;block19_r     30
                    defw block20,  0    ;block20_r     31
                    defw block8a,  0    ;block8a_r     32
                    defw block9a,  0    ;block9a_r     33
                    defw block10a, 0    ;block10a_r    34
                    defw block11a, 0    ;block11a_r    35
                    defw block12a, 0    ;block12a_r    36
                    defw block13a, 0    ;block13a_r    37
                    defw block14a, 0    ;block14a_r    38
                    defw block15a, 0    ;block15a_r    39
                    defw block16a, 0    ;block16a_r    40
                    defw block17a, 0    ;block17a_r    41
                    defw block18a, 0    ;block18a_r    42
                    defw block19a, 0    ;block19a_r    43
                    defw block20a, 0    ;block20a_r    44
                    defw block8b,  0    ;block8b_r     45
                    defw block21,  0    ;block21_r     46
                    defw block21a, 0    ;block21a_r    47
                    defw block10b, 0    ;block10b_r    48
                    defw block11b, 0    ;block11b_r    49
                    defw block12b, 0    ;block12b_r    50
                    defw block13b, 0    ;block13b_r    51
                    defw block14b, 0    ;block14b_r    52
                    defw block16b, 0    ;block16b_r    53
                    defw block17b, 0    ;block17b_r    54
                    defw block18b, 0    ;block18b_r    55
                    defw block19b, 0    ;block19b_r    56
                    defw block20b, 0    ;block20b_r    57
                    defw block8c,  0    ;block8c_r     58
                    defw block10c, 0    ;block10c_r    59
                    defw block11c, 0    ;block11c_r    60
                    defw block12c, 0    ;block12c_r    61
                    defw block13c, 0    ;block13c_r    62
                    defw block14c, 0    ;block14c_r    63
                    defw block16c, 0    ;block16c_r    64
                    defw block17c, 0    ;block17c_r    65
                    defw block18c, 0    ;block18c_r    66
                    defw block19c, 0    ;block19c_r    67
                    defw block20c, 0    ;block20c_r    68



;
; #
;
.block0             defb end_datablock0-block0
                    defb 1,6                 ; 1 byte width, 6 pixel rows
                    defw block0                                                 ; pointer to next left rotated block
                    defw block0                                                 ; pointer to next right rotated block

                    defb 1,1                                                    ; heigth (rows), width (columns)
                    defb 1
.end_datablock0
                    defb @11111100
                    defb @10000100
                    defb @10110100
                    defb @10110100
                    defb @10000100
                    defb @11111100


;
;  #
; ###
;
.block1             defb end_datablock1-block1
                    defb 3,12
                    defw block1a                                                ; next left
                    defw block1c                                                ; next right

                    defb 2,3
                    defb 0,1,0
                    defb 1,1,1
.end_datablock1
                    defb @00000011,@11110000,@00000000
                    defb @00000010,@00010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @11111110,@11011111,@11000000
                    defb @10000000,@11000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000

;  #
; ##
;  #
.block1a            defb end_datablock1a-block1a
                    defb 2,18
                    defw block1b
                    defw block1

                    defb 3,2
                    defb 0,1
                    defb 1,1
                    defb 0,1
.end_datablock1a
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000


;
; ###
;  #
;
.block1b            defb end_datablock1b-block1b
                    defb 3,12
                    defw block1c
                    defw block1a

                    defb 2,3
                    defb 1,1,1
                    defb 0,1,0
.end_datablock1b
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@11000000,@01000000
                    defb @11111110,@11011111,@11000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@00010000,@00000000
                    defb @00000011,@11110000,@00000000

; #
; ##
; #
.block1c            defb end_datablock1c-block1c
                    defb 2,18
                    defw block1
                    defw block1b

                    defb 3,2
                    defb 1,0
                    defb 1,1
                    defb 1,0
.end_datablock1c
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


; #
; ###
;
.block2             defb end_datablock2-block2
                    defb 3,12
                    defw block2a
                    defw block2c

                    defb 2,3
                    defb 1,0,0
                    defb 1,1,1
.end_datablock2
                    defb @11111100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110111,@11111111,@11000000
                    defb @10110000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000

;  #
;  #
; ##
.block2a            defb end_datablock2a-block2a
                    defb 2,18
                    defw block2b
                    defw block2

                    defb 3,2
                    defb 0,1
                    defb 0,1
                    defb 1,1
.end_datablock2a
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


; ###
;   #
.block2b            defb end_datablock2b-block2b
                    defb 3,12
                    defw block2c
                    defw block2a

                    defb 2,3
                    defb 1,1,1
                    defb 0,0,1
.end_datablock2b
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001111,@11000000

; ##
; #
; #
.block2c            defb end_datablock2c-block2c
                    defb 2,18
                    defw block2
                    defw block2b

                    defb 3,2
                    defb 1,1
                    defb 1,0
                    defb 1,0
.end_datablock2c
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


;
; ##
;  ##
;
.block3             defb end_datablock3-block3
                    defb 3,12
                    defw block3a
                    defw block3a

                    defb 2,3
                    defb 1,1,0
                    defb 0,1,1
.end_datablock3
                    defb @11111111,@11110000,@00000000
                    defb @10000000,@00010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10000000,@11010000,@00000000
                    defb @11111110,@11010000,@00000000
                    defb @00000010,@11011111,@11000000
                    defb @00000010,@11000000,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@00000000,@01000000
                    defb @00000011,@11111111,@11000000


;  #
; ##
; #
.block3a            defb end_datablock3a-block3a
                    defb 2,18
                    defw block3
                    defw block3

                    defb 3,2
                    defb 0,1
                    defb 1,1
                    defb 1,0
.end_datablock3a
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


;
;  ##
; ##
;
.block4             defb end_datablock4-block4
                    defb 3,12
                    defw block4a
                    defw block4a

                    defb 2,3
                    defb 0,1,1
                    defb 1,1,0
.end_datablock4
                    defb @00000011,@11111111,@11000000
                    defb @00000010,@00000000,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11000000,@01000000
                    defb @00000010,@11011111,@11000000
                    defb @11111110,@11010000,@00000000
                    defb @10000000,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10000000,@00010000,@00000000
                    defb @11111111,@11110000,@00000000


; #
; ##
;  #
.block4a            defb end_datablock4a-block4a
                    defb 2,18
                    defw block4
                    defw block4

                    defb 3,2
                    defb 1,0
                    defb 1,1
                    defb 0,1
.end_datablock4a
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000


; ##
; ##
.block5             defb end_datablock5-block5
                    defb 2,12
                    defw block5
                    defw block5

                    defb 2,2
                    defb 1,1
                    defb 1,1
.end_datablock5
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


; ####
;
.block6             defb end_datablock6-block6
                    defb 3,6
                    defw block6a
                    defw block6a

                    defb 1,4
                    defb 1,1,1,1
.end_datablock6
                    defb @11111111,@11111111,@11111111
                    defb @10000000,@00000000,@00000001
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10000000,@00000000,@00000001
                    defb @11111111,@11111111,@11111111


; #
; #
; #
; #
;
.block6a            defb end_datablock6a-block6a
                    defb 1,24
                    defw block6
                    defw block6

                    defb 4,1
                    defb 1
                    defb 1
                    defb 1
                    defb 1
.end_datablock6a
                    defb @11111100
                    defb @10000100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10000100
                    defb @11111100


;   #
; ###
;
.block7             defb end_datablock7-block7
                    defb 3,12
                    defw block7a
                    defw block7c

                    defb 2,3
                    defb 0,0,1
                    defb 1,1,1
.end_datablock7
                    defb @00000000,@00001111,@11000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000


; ##
;  #
;  #
.block7a            defb end_datablock7a-block7a
                    defb 2,18
                    defw block7b
                    defw block7

                    defb 3,2
                    defb 1,1
                    defb 0,1
                    defb 0,1
.end_datablock7a
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000


; ###
; #
.block7b            defb end_datablock7b-block7b
                    defb 3,12
                    defw block7c
                    defw block7a

                    defb 2,3
                    defb 1,1,1
                    defb 1,0,0
.end_datablock7b
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10110000,@00000000,@01000000
                    defb @10110111,@11111111,@11000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @11111100,@00000000,@00000000


; #
; #
; ##
.block7c            defb end_datablock7c-block7c
                    defb 2,18
                    defw block7
                    defw block7b

                    defb 3,2
                    defb 1,0
                    defb 1,0
                    defb 1,1
.end_datablock7c
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


; ###
; #
; #
.block8             defb end_datablock8-block8
                    defb 3,18
                    defw block8a
                    defw block8

                    defb 3,3
                    defb 1,1,1
                    defb 1,0,0
                    defb 1,0,0
.end_datablock8
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10110000,@00000000,@01000000
                    defb @10110111,@11111111,@11000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @11111100,@00000000,@00000000


; #
; #
; ###
;
.block8a            defb end_datablock8a-block8a
                    defb 3,18
                    defw block8b
                    defw block8c

                    defb 3,3
                    defb 1,0,0
                    defb 1,0,0
                    defb 1,1,1
.end_datablock8a
                    defb @11111100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110111,@11111111,@11000000
                    defb @10110000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000


;   #
;   #
; ###
;
.block8b            defb end_datablock8b-block8b
                    defb 3,18
                    defw block8c
                    defw block8a

                    defb 3,3
                    defb 0,0,1
                    defb 0,0,1
                    defb 1,1,1
.end_datablock8b
                    defb @00000000,@00001111,@11000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000


; ###
;   #
;   #
.block8c            defb end_datablock8c-block8c
                    defb 3,18
                    defw block8
                    defw block8b

                    defb 3,3
                    defb 1,1,1
                    defb 0,0,1
                    defb 0,0,1
.end_datablock8c
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001111,@11000000


; Extended blocks (20 - :

;   #
; ###
; #
.block9             defb end_datablock9-block9
                    defb 3,18
                    defw block9a
                    defw block9a

                    defb 3,3
                    defb 0,0,1
                    defb 1,1,1
                    defb 1,0,0
.end_datablock9

                    defb @00000000,@00001111,@11000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10110000,@00000000,@01000000
                    defb @10110111,@11111111,@11000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @11111100,@00000000,@00000000


; ##
;  #
;  ##
.block9a            defb end_datablock9a-block9a
                    defb 3,18
                    defw block9
                    defw block9

                    defb 3,3
                    defb 1,1,0
                    defb 0,1,0
                    defb 0,1,1
.end_datablock9a
                    defb @11111111,@11110000,@00000000
                    defb @10000000,@00010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10000000,@11010000,@00000000
                    defb @11111110,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11011111,@11000000
                    defb @00000010,@11000000,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@00000000,@01000000
                    defb @00000011,@11111111,@11000000


;  #
; ##
;  #
;  #
;
.block10            defb end_datablock10-block10
                    defb 2,24
                    defw block10a
                    defw block10c

                    defb 4,2
                    defb 0,1
                    defb 1,1
                    defb 0,1
                    defb 0,1
.end_datablock10
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000



; ####
;  #
.block10a           defb end_datablock10a-block10a
                    defb 3,12
                    defw block10b
                    defw block10

                    defb 2,4
                    defb 1,1,1,1
                    defb 0,1,0,0
.end_datablock10a
                    defb @11111111,@11111111,@11111111
                    defb @10000000,@00000000,@00000001
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10000000,@11000000,@00000001
                    defb @11111110,@11011111,@11111111
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@00010000,@00000000
                    defb @00000011,@11110000,@00000000


; #
; #
; ##
; #
;
.block10b           defb end_datablock10b-block10b
                    defb 2,24
                    defw block10c
                    defw block10a

                    defb 4,2
                    defb 1,0
                    defb 1,0
                    defb 1,1
                    defb 1,0
.end_datablock10b
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


;   #
; ####
.block10c           defb end_datablock10c-block10c
                    defb 3,12
                    defw block10
                    defw block10b

                    defb 2,4
                    defb 0,0,1,0
                    defb 1,1,1,1

.end_datablock10c
                    defb @00000000,@00001111,@11000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @11111111,@11111011,@01111111
                    defb @10000000,@00000011,@00000001
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10000000,@00000000,@00000001
                    defb @11111111,@11111111,@11111111


; ##
;  #
;  #
;  #
;
.block11            defb end_datablock11-block11
                    defb 2,24
                    defw block11a
                    defw block11c

                    defb 4,2
                    defb 1,1
                    defb 0,1
                    defb 0,1
                    defb 0,1
.end_datablock11
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000



; ####
; #
.block11a           defb end_datablock11a-block11a
                    defb 3,12
                    defw block11b
                    defw block11

                    defb 2,4
                    defb 1,1,1,1
                    defb 1,0,0,0
.end_datablock11a
                    defb @11111111,@11111111,@11111111
                    defb @10000000,@00000000,@00000001
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10110000,@00000000,@00000001
                    defb @10110111,@11111111,@11111111
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @11111100,@00000000,@00000000


; #
; #
; #
; ##
;
.block11b           defb end_datablock11b-block11b
                    defb 2,24
                    defw block11c
                    defw block11a

                    defb 4,2
                    defb 1,0
                    defb 1,0
                    defb 1,0
                    defb 1,1
.end_datablock11b
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


; #
; ####
.block11c           defb end_datablock11c-block11c
                    defb 3,12
                    defw block11
                    defw block11b

                    defb 2,4
                    defb 0,0,0,1
                    defb 1,1,1,1

.end_datablock11c
                    defb @00000000,@00000000,@00111111
                    defb @00000000,@00000000,@00100001
                    defb @00000000,@00000000,@00101101
                    defb @00000000,@00000000,@00101101
                    defb @00000000,@00000000,@00101101
                    defb @00000000,@00000000,@00101101
                    defb @11111111,@11111111,@11101101
                    defb @10000000,@00000000,@00001101
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10000000,@00000000,@00000001
                    defb @11111111,@11111111,@11111111


; ###
;  #
;  #
.block12            defb end_datablock12-block12
                    defb 3,18
                    defw block12a
                    defw block12c

                    defb 3,3
                    defb 1,1,1
                    defb 0,1,0
                    defb 0,1,0
.end_datablock12
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@11000000,@01000000
                    defb @11111110,@11011111,@11000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@00010000,@00000000
                    defb @00000011,@11110000,@00000000


; #
; ###
; #
.block12a           defb end_datablock12a-block12a
                    defb 3,18
                    defw block12b
                    defw block12

                    defb 3,3
                    defb 1,0,0
                    defb 1,1,1
                    defb 1,0,0
.end_datablock12a
                    defb @11111100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110111,@11111111,@11000000
                    defb @10110000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10110000,@00000000,@01000000
                    defb @10110111,@11111111,@11000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @11111100,@00000000,@00000000


;  #
;  #
; ###
.block12b           defb end_datablock12b-block12b
                    defb 3,18
                    defw block12c
                    defw block12a

                    defb 3,3
                    defb 0,1,0
                    defb 0,1,0
                    defb 1,1,1
.end_datablock12b
                    defb @00000011,@11110000,@00000000
                    defb @00000010,@00010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @11111110,@11011111,@11000000
                    defb @10000000,@11000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000


;   #
; ###
;   #
;
.block12c           defb end_datablock12c-block12c
                    defb 3,18
                    defw block12
                    defw block12b

                    defb 3,3
                    defb 0,0,1
                    defb 1,1,1
                    defb 0,0,1
.end_datablock12c
                    defb @00000000,@00001111,@11000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001111,@11000000


; ###
; # #
;
.block13            defb end_datablock13-block13
                    defb 3,12
                    defw block13a
                    defw block13c

                    defb 2,3
                    defb 1,1,1
                    defb 1,0,1
.end_datablock13
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10110000,@00000011,@01000000
                    defb @10110111,@11111011,@01000000
                    defb @10110100,@00001011,@01000000
                    defb @10110100,@00001011,@01000000
                    defb @10110100,@00001011,@01000000
                    defb @10110100,@00001011,@01000000
                    defb @10000100,@00001000,@01000000
                    defb @11111100,@00001111,@11000000


; ##
; #
; ##
;
.block13a           defb end_datablock13a-block13a
                    defb 2,18
                    defw block13b
                    defw block13

                    defb 3,2
                    defb 1,1
                    defb 1,0
                    defb 1,1
.end_datablock13a
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


; # #
; ###
;
.block13b           defb end_datablock13b-block13b
                    defb 3,12
                    defw block13c
                    defw block13a

                    defb 2,3
                    defb 1,0,1
                    defb 1,1,1
.end_datablock13b
                    defb @11111100,@00001111,@11000000
                    defb @10000100,@00001000,@01000000
                    defb @10110100,@00001011,@01000000
                    defb @10110100,@00001011,@01000000
                    defb @10110100,@00001011,@01000000
                    defb @10110100,@00001011,@01000000
                    defb @10110111,@11111011,@01000000
                    defb @10110000,@00000011,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000


; ##
;  #
; ##
.block13c           defb end_datablock13c-block13c
                    defb 2,18
                    defw block13
                    defw block13b

                    defb 3,2
                    defb 1,1
                    defb 0,1
                    defb 1,1
.end_datablock13c
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


; #
; ##
;  #
;  #
.block14            defb end_datablock14-block14
                    defb 2,24
                    defw block14a
                    defw block14c

                    defb 4,2
                    defb 1,0
                    defb 1,1
                    defb 0,1
                    defb 0,1
.end_datablock14
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000


;
;  ###
; ##
;
.block14a           defb end_datablock14a-block14a
                    defb 3,12
                    defw block14b
                    defw block14

                    defb 2,4
                    defb 0,1,1,1
                    defb 1,1,0,0
.end_datablock14a
                    defb @00000011,@11111111,@11111111
                    defb @00000010,@00000000,@00000001
                    defb @00000010,@11111111,@11111101
                    defb @00000010,@11111111,@11111101
                    defb @00000010,@11000000,@00000001
                    defb @00000010,@11011111,@11111111
                    defb @11111110,@11010000,@00000000
                    defb @10000000,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10000000,@00010000,@00000000
                    defb @11111111,@11110000,@00000000


; #
; #
; ##
;  #
.block14b           defb end_datablock14b-block14b
                    defb 2,24
                    defw block14c
                    defw block14a

                    defb 4,2
                    defb 1,0
                    defb 1,0
                    defb 1,1
                    defb 0,1
.end_datablock14b
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000


;   ##
; ###
;
.block14c           defb end_datablock14c-block14c
                    defb 3,12
                    defw block14
                    defw block14b

                    defb 2,4
                    defb 0,0,1,1
                    defb 1,1,1,0
.end_datablock14c
                    defb @00000000,@00001111,@11111111
                    defb @00000000,@00001000,@00000001
                    defb @00000000,@00001011,@11111101
                    defb @00000000,@00001011,@11111101
                    defb @00000000,@00001011,@00000001
                    defb @00000000,@00001011,@01111111
                    defb @11111111,@11111011,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000


; #
; ###
;   #
;
.block15            defb end_datablock15-block15
                    defb 3,18
                    defw block15a
                    defw block15a

                    defb 3,3
                    defb 1,0,0
                    defb 1,1,1
                    defb 0,0,1
.end_datablock15
                    defb @11111100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110111,@11111111,@11000000
                    defb @10110000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001111,@11000000


;  ##
;  #
; ##
;
.block15a           defb end_datablock15a-block15a
                    defb 3,18
                    defw block15
                    defw block15

                    defb 3,3
                    defb 0,1,1
                    defb 0,1,0
                    defb 1,1,0
.end_datablock15a
                    defb @00000011,@11111111,@11000000
                    defb @00000010,@00000000,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11000000,@01000000
                    defb @00000010,@11011111,@11000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @11111110,@11010000,@00000000
                    defb @10000000,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10000000,@00010000,@00000000
                    defb @11111111,@11110000,@00000000


; #
; ####
;
.block16            defb end_datablock16-block16
                    defb 3,12
                    defw block16a
                    defw block16c

                    defb 2,4
                    defb 1,0,0,0
                    defb 1,1,1,1
.end_datablock16
                    defb @11111100,@00000000,@00000000
                    defb @10000100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110100,@00000000,@00000000
                    defb @10110111,@11111111,@11111111
                    defb @10110000,@00000000,@00000001
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10000000,@00000000,@00000001
                    defb @11111111,@11111111,@11111111

;  #
;  #
;  #
; ##
.block16a           defb end_datablock16a-block16a
                    defb 2,24
                    defw block16b
                    defw block16

                    defb 4,2
                    defb 0,1
                    defb 0,1
                    defb 0,1
                    defb 1,1
.end_datablock16a
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


; ####
;    #
.block16b           defb end_datablock16b-block16b
                    defb 3,12
                    defw block16c
                    defw block16a

                    defb 2,4
                    defb 1,1,1,1
                    defb 0,0,0,1
.end_datablock16b
                    defb @11111111,@11111111,@11111111
                    defb @10000000,@00000000,@00000001
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10000000,@00000000,@00001101
                    defb @11111111,@11111111,@11101101
                    defb @00000000,@00000000,@00101101
                    defb @00000000,@00000000,@00101101
                    defb @00000000,@00000000,@00101101
                    defb @00000000,@00000000,@00101101
                    defb @00000000,@00000000,@00100001
                    defb @00000000,@00000000,@00111111

; ##
; #
; #
; #
.block16c           defb end_datablock16c-block16c
                    defb 2,24
                    defw block16
                    defw block16b

                    defb 4,2
                    defb 1,1
                    defb 1,0
                    defb 1,0
                    defb 1,0
.end_datablock16c
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


; ##
; ###
;
.block17            defb end_datablock17-block17
                    defb 3,12
                    defw block17a
                    defw block17c

                    defb 2,3
                    defb 1,1,0
                    defb 1,1,1
.end_datablock17
                    defb @11111111,@11110000,@00000000
                    defb @10000000,@00010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10110000,@11010000,@00000000
                    defb @10110000,@11010000,@00000000
                    defb @10110000,@11011111,@11000000
                    defb @10110000,@11000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000

;  #
; ##
; ##
;
.block17a           defb end_datablock17a-block17a
                    defb 2,18
                    defw block17b
                    defw block17

                    defb 3,2
                    defb 0,1
                    defb 1,1
                    defb 1,1
.end_datablock17a
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


; ###
;  ##
.block17b           defb end_datablock17b-block17b
                    defb 3,12
                    defw block17c
                    defw block17a

                    defb 2,3
                    defb 1,1,1
                    defb 0,1,1
.end_datablock17b
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@11000011,@01000000
                    defb @11111110,@11000011,@01000000
                    defb @00000010,@11000011,@01000000
                    defb @00000010,@11000011,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@00000000,@01000000
                    defb @00000011,@11111111,@11000000

; ##
; ##
; #
.block17c           defb end_datablock17c-block17c
                    defb 2,18
                    defw block17
                    defw block17b

                    defb 3,2
                    defb 1,1
                    defb 1,1
                    defb 1,0
.end_datablock17c
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


; ###
; ##
;
.block18            defb end_datablock18-block18
                    defb 3,12
                    defw block18a
                    defw block18c

                    defb 2,3
                    defb 1,1,1
                    defb 1,1,0
.end_datablock18
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10110000,@11000000,@01000000
                    defb @10110000,@11011111,@11000000
                    defb @10110000,@11010000,@00000000
                    defb @10110000,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10000000,@00010000,@00000000
                    defb @11111111,@11110000,@00000000

; #
; ##
; ##
;
.block18a           defb end_datablock18a-block18a
                    defb 2,18
                    defw block18b
                    defw block18

                    defb 3,2
                    defb 1,0
                    defb 1,1
                    defb 1,1
.end_datablock18a
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@00010000
                    defb @11111111,@11110000


;  ##
; ###
.block18b           defb end_datablock18b-block18b
                    defb 3,12
                    defw block18c
                    defw block18a

                    defb 2,3
                    defb 0,1,1
                    defb 1,1,1
.end_datablock18b
                    defb @00000011,@11111111,@11000000
                    defb @00000010,@00000000,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11111111,@01000000
                    defb @00000010,@11000011,@01000000
                    defb @00000010,@11000011,@01000000
                    defb @11111110,@11000011,@01000000
                    defb @10000000,@11000011,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000000,@01000000
                    defb @11111111,@11111111,@11000000


; ##
; ##
;  #
.block18c           defb end_datablock18c-block18c
                    defb 2,18
                    defw block18
                    defw block18b

                    defb 3,2
                    defb 1,1
                    defb 1,1
                    defb 0,1
.end_datablock18c
                    defb @11111111,@11110000
                    defb @10000000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10110000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000


; #
; ####
;
.block19            defb end_datablock19-block19
                    defb 3,12
                    defw block19a
                    defw block19c

                    defb 2,4
                    defb 0,1,0,0
                    defb 1,1,1,1
.end_datablock19
                    defb @00000011,@11110000,@00000000
                    defb @00000010,@00010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @00000010,@11010000,@00000000
                    defb @11111110,@11011111,@11111111
                    defb @10000000,@11000000,@00000001
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10000000,@00000000,@00000001
                    defb @11111111,@11111111,@11111111

;  #
;  #
; ##
;  #
.block19a           defb end_datablock19a-block19a
                    defb 2,24
                    defw block19b
                    defw block19

                    defb 4,2
                    defb 0,1
                    defb 0,1
                    defb 1,1
                    defb 0,1
.end_datablock19a
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10000000,@11010000
                    defb @11111110,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@00010000
                    defb @00000011,@11110000


; ####
;   #
.block19b           defb end_datablock19b-block19b
                    defb 3,12
                    defw block19c
                    defw block19a

                    defb 2,4
                    defb 1,1,1,1
                    defb 0,0,1,0
.end_datablock19b
                    defb @11111111,@11111111,@11111111
                    defb @10000000,@00000000,@00000001
                    defb @10111111,@11111111,@11111101
                    defb @10111111,@11111111,@11111101
                    defb @10000000,@00000011,@00000001
                    defb @11111111,@11111011,@01111111
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001011,@01000000
                    defb @00000000,@00001000,@01000000
                    defb @00000000,@00001111,@11000000

; #
; ##
; #
; #
.block19c           defb end_datablock19c-block19c
                    defb 2,24
                    defw block19
                    defw block19b

                    defb 4,2
                    defb 1,0
                    defb 1,1
                    defb 1,0
                    defb 1,0
.end_datablock19c
                    defb @11111100,@00000000
                    defb @10000100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110111,@11110000
                    defb @10110000,@00010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


; ##
;  ###
;
.block20            defb end_datablock20-block20
                    defb 3,12
                    defw block20a
                    defw block20c

                    defb 2,4
                    defb 1,1,0,0
                    defb 0,1,1,1
.end_datablock20
                    defb @11111111,@11110000,@00000000
                    defb @10000000,@00010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10111111,@11010000,@00000000
                    defb @10000000,@11010000,@00000000
                    defb @11111110,@11010000,@00000000
                    defb @00000010,@11011111,@11111111
                    defb @00000010,@11000000,@00000001
                    defb @00000010,@11111111,@11111101
                    defb @00000010,@11111111,@11111101
                    defb @00000010,@00000000,@00000001
                    defb @00000011,@11111111,@11111111

;  #
;  #
; ##
; #
;
.block20a           defb end_datablock20a-block20a
                    defb 2,24
                    defw block20b
                    defw block20

                    defb 4,2
                    defb 0,1
                    defb 0,1
                    defb 1,1
                    defb 1,0
.end_datablock20a
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


; ###
;   ##
.block20b           defb end_datablock20b-block20b
                    defb 3,12
                    defw block20c
                    defw block20a

                    defb 2,4
                    defb 1,1,1,0
                    defb 0,0,1,1
.end_datablock20b
                    defb @11111111,@11111111,@11000000
                    defb @10000000,@00000000,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10111111,@11111111,@01000000
                    defb @10000000,@00000011,@01000000
                    defb @11111111,@11111011,@01000000
                    defb @00000000,@00001011,@01111111
                    defb @00000000,@00001011,@00000001
                    defb @00000000,@00001011,@11111101
                    defb @00000000,@00001011,@11111101
                    defb @00000000,@00001000,@00000001
                    defb @00000000,@00001111,@11111111

;  #
; ##
; #
; #
.block20c           defb end_datablock20c-block20c
                    defb 2,24
                    defw block20
                    defw block20b

                    defb 4,2
                    defb 0,1
                    defb 1,1
                    defb 1,0
                    defb 1,0
.end_datablock20c
                    defb @00000011,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @00000010,@11010000
                    defb @11111110,@11010000
                    defb @10000000,@11010000
                    defb @10111111,@11010000
                    defb @10111111,@11010000
                    defb @10110000,@00010000
                    defb @10110111,@11110000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10110100,@00000000
                    defb @10000100,@00000000
                    defb @11111100,@00000000


; #####
;
.block21            defb end_datablock21-block21
                    defb 4,6
                    defw block21a
                    defw block21a

                    defb 1,5
                    defb 1,1,1,1,1
.end_datablock21
                    defb @11111111,@11111111,@11111111,@11111100
                    defb @10000000,@00000000,@00000000,@00000100
                    defb @10111111,@11111111,@11111111,@11110100
                    defb @10111111,@11111111,@11111111,@11110100
                    defb @10000000,@00000000,@00000000,@00000100
                    defb @11111111,@11111111,@11111111,@11111100

; #
; #
; #
; #
; #
;
.block21a           defb end_datablock21a-block21a
                    defb 1,30
                    defw block21
                    defw block21

                    defb 5,1
                    defb 1
                    defb 1
                    defb 1
                    defb 1
                    defb 1
.end_datablock21a
                    defb @11111100
                    defb @10000100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10110100
                    defb @10000100
                    defb @11111100
