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

     module text_constants

     xdef scoretxt
     xdef linestxt
     xdef rotatetxt
     xdef rotateleft_spr
     xdef rotateright_spr
     xdef speedtxt
     xdef blockstxt
     xdef nextblocktxt


.rotateleft_spr     defb end_rotateleft_spr - rotateleft_spr
                    defb 2,11
.end_rotateleft_spr defb @00000100,@00000000
                    defb @00001100,@00000000
                    defb @00011111,@10000000
                    defb @00001100,@01000000
                    defb @00000100,@00100000
                    defb @01000000,@00100000
                    defb @01000000,@00100000
                    defb @01000000,@00100000
                    defb @01000000,@00100000
                    defb @00100000,@01000000
                    defb @00011111,@10000000


.rotateright_spr    defb end_rotateright_spr - rotateright_spr
                    defb 2,11
.end_rotateright_spr defb @00011111,@10000000
                    defb @00100000,@01000000
                    defb @01000000,@00100000
                    defb @01000000,@00100000
                    defb @01000000,@00100000
                    defb @01000000,@00100000
                    defb @00000100,@00100000
                    defb @00001100,@01000000
                    defb @00011111,@10000000
                    defb @00001100,@00000000
                    defb @00000100,@00000000


; "SCORE"
.scoretxt           defb end_scoretxt-scoretxt
                    defb 2,24
.end_scoretxt       defb @00110001,@11100000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @00111100,@01100000
                    defb 0,0
                    defb @00111111,@11100000
                    defb @01000000,@00010000
                    defb @01000000,@00010000
                    defb @00100000,@01100000
                    defb 0,0
                    defb @00111111,@11100000
                    defb @01000000,@00010000
                    defb @01000000,@00010000
                    defb @00111111,@11100000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @00000010,@00010000
                    defb @00000110,@00010000
                    defb @01111001,@11100000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000000,@00010000

; "LINES"
.linestxt           defb end_linestxt-linestxt
                    defb 2,24
.end_linestxt       defb @01111111,@11110000
                    defb @01000000,@00000000
                    defb @01000000,@00000000
                    defb @01000000,@00000000
                    defb 0,0
                    defb @01000000,@00010000
                    defb @01111111,@11110000
                    defb @01000000,@00010000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @00000000,@11000000
                    defb @00000011,@00000000
                    defb @00001100,@00000000
                    defb @01111111,@11110000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000000,@00010000
                    defb 0,0
                    defb @00110001,@11100000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @00111100,@01100000

; "ROTATE"
.rotatetxt          defb end_rotatetxt-rotatetxt
                    defb 2,31
.end_rotatetxt      defb @01111111,@11110000
                    defb @00000010,@00010000
                    defb @00000110,@00010000
                    defb @01111001,@11100000
                    defb 0,0
                    defb @00111111,@11100000
                    defb @01000000,@00010000
                    defb @01000000,@00010000
                    defb @00111111,@11100000
                    defb 0,0
                    defb @00000000,@00010000
                    defb @00000000,@00010000
                    defb @01111111,@11110000
                    defb @00000000,@00010000
                    defb @00000000,@00010000
                    defb 0,0
                    defb @01111111,@11100000
                    defb @00000100,@00010000
                    defb @00000100,@00010000
                    defb @01111111,@11100000
                    defb 0,0
                    defb @00000000,@00010000
                    defb @00000000,@00010000
                    defb @01111111,@11110000
                    defb @00000000,@00010000
                    defb @00000000,@00010000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000000,@00010000

;"SPEED"
.speedtxt           defb end_speedtxt-speedtxt
                    defb 2,24
.end_speedtxt       defb @00110001,@11100000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @00111100,@01100000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @00000010,@00010000
                    defb @00000010,@00010000
                    defb @00000001,@11100000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000000,@00010000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @01000000,@00010000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @01000000,@00010000
                    defb @01000000,@00010000
                    defb @00111111,@11100000

;"BLOCKS"
.blockstxt          defb end_blockstxt-blockstxt
                    defb 2,30
.end_blockstxt      defb @01111111,@11110000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @00111101,@11100000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @01000000,@00000000
                    defb @01000000,@00000000
                    defb @01000000,@00000000
                    defb 0,0
                    defb @00111111,@11100000
                    defb @01000000,@00010000
                    defb @01000000,@00010000
                    defb @00111111,@11100000
                    defb 0,0
                    defb @00111111,@11100000
                    defb @01000000,@00010000
                    defb @01000000,@00010000
                    defb @00100000,@01100000
                    defb 0,0
                    defb @01111111,@11110000
                    defb @00000010,@00000000
                    defb @00000101,@00000000
                    defb @00011000,@11000000
                    defb @01100000,@00110000
                    defb 0,0
                    defb @00110001,@11100000
                    defb @01000010,@00010000
                    defb @01000010,@00010000
                    defb @00111100,@01100000



;"NEXT BLOCK"
.nextblocktxt       defb end_nextblocktxt-nextblocktxt
                    defb 4,25
.end_nextblocktxt   defb @01111111,@11110000, @11111111,@11100000
                    defb @01000010,@00010000, @00000001,@10000000
                    defb @01000010,@00010000, @00000110,@00000000
                    defb @00111101,@11100000, @00011000,@00000000
                    defb 0        ,0        , @11111111,@11100000
                    defb @01111111,@11110000, 0        ,0
                    defb @01000000,@00000000, @11111111,@11100000
                    defb @01000000,@00000000, @10000100,@00100000
                    defb @01000000,@00000000, @10000100,@00100000
                    defb 0        ,0        , @10000000,@00100000
                    defb @00111111,@11100000, 0        ,0
                    defb @01000000,@00010000, @11100000,@11100000
                    defb @01000000,@00010000, @00011011,@00000000
                    defb @00111111,@11100000, @00000100,@00000000
                    defb 0        ,0        , @00011011,@00000000
                    defb @00111111,@11100000, @11100000,@11100000
                    defb @01000000,@00010000, 0        ,0
                    defb @01000000,@00010000, @00000000,@00100000
                    defb @00100000,@01100000, @00000000,@00100000
                    defb 0        ,0        , @11111111,@11100000
                    defb @01111111,@11110000, @00000000,@00100000
                    defb @00000010,@00000000, @00000000,@00100000
                    defb @00000101,@00000000, 0        ,0
                    defb @00011000,@11000000, 0        ,0
                    defb @01100000,@00110000, 0        ,0

