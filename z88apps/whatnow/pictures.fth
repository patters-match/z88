\ *************************************************************************************
\
\ WhatNow? (c) Garry Lancaster, 2001
\
\ WhatNow? is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ WhatNow? is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with WhatNow?;
\ see the file COPYING. If not, write to the Free Software Foundation, Inc.,
\ 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\ *************************************************************************************

\ wn-pictures
CR .( WhatNow? - Pictures)

: >picture ( n -- [addr] flag )
    gac-pictures
    BEGIN
      2DUP @ =
      IF  NIP 2 CELLS + TRUE EXIT  THEN
      DUP @
    WHILE
      DUP CELL+ @ CHARS +
      zx? 0= IF  2 CELLS +  THEN
    REPEAT
    2DROP FALSE ;

: getxy ( addr -- x y addr' )
    COUNT SWAP
    COUNT hmin - 2/ SWAP ;

: relxy ( x1 y1 x2 y2 -- x1 y1 dx dy )
    2OVER ROT SWAP - ROT ROT - SWAP ;

CREATE colours
  255 C, 255 C, 255 C, 255 C, 255 C, 255 C, 255 C, 255 C,  \ black
  238 C, 187 C, 238 C, 187 C, 238 C, 187 C, 238 C, 187 C,  \ blue
  204 C,  51 C, 204 C,  51 C, 204 C,  51 C, 204 C,  51 C,  \ red
    0 C, 255 C,   0 C, 255 C,   0 C, 255 C,   0 C, 255 C,  \ magenta
  170 C, 170 C, 170 C, 170 C, 170 C, 170 C, 170 C, 170 C,  \ green
   37 C, 146 C,  37 C, 146 C,  37 C, 146 C,  37 C, 146 C,  \ cyan
   17 C,  68 C,  17 C,  68 C,  17 C,  68 C,  17 C,  68 C,  \ yellow
    0 C,   0 C,   0 C,   0 C,   0 C,   0 C,   0 C,   0 C,  \ white

: colourin ( addr col -- addr' )
    SWAP getxy >R
    ROT 8 MOD 3 LSHIFT colours + GPATTERN
    R> ;

: invdraw  TRUE ferror" Bad draw action at: " ;

' CHAR+                                             \ 19
' CHAR+                                             \ 18
' CHAR+                                             \ 17
:NONAME COUNT TO ink ;                              \ 16
' invdraw                                           \ 15
' invdraw                                           \ 14
' invdraw                                           \ 13
' invdraw                                           \ 12
' invdraw                                           \ 11
' invdraw                                           \ 10
:NONAME getxy getxy >R GPIXEL GLINETO R> ;          \ 9
:NONAME getxy getxy >R relxy 2SWAP GPIXEL GBOX R> ; \ 8
:NONAME DUP @ >picture IF  dopic  THEN CELL+ ;      \ 7
:NONAME getxy >R GSHADE R> ;                        \ 6
' CELL+                                             \ 5
:NONAME ink colourin ;                              \ 4
:NONAME getxy getxy >R relxy GELLIPSE R> ;          \ 3
:NONAME getxy >R GPIXEL R> ;                        \ 2
' CHAR+                                             \ 1
' invdraw                                           \ 0         

CREATE zxtab , , , , , , , , , , , , , , , , , , , ,

: inclzx ( addr -- )
    0 SWAP COUNT
    0 ?DO  COUNT DUP 19 > IF  DROP invdraw  THEN
           2* zxtab + @ EXECUTE
           { SWAP 1+ 7 AND SWAP OVER 0= } IF  PAUSE  THEN
       LOOP  2DROP ;

zxtab 2 2* + @                                         \ 11
zxtab 7 2* + @                                         \ 10
:NONAME  COUNT 3 AND >R COUNT 3 AND R> 4 * + TO ink ;  \ 9
zxtab 8 2* + @                                         \ 8
' NOOP                                                 \ 7
' NOOP                                                 \ 6
' NOOP                                                 \ 5
' NOOP                                                 \ 4
zxtab 4 2* + @                                         \ 3
zxtab 3 2* + @                                         \ 2
zxtab 9 2* + @                                         \ 1
' invdraw                                              \ 0

CREATE cpctab , , , , , , , , , , , ,

: inclcpc ( addr -- )
    0 SWAP 4 CELLS +
    BEGIN  COUNT ?DUP
    WHILE  DUP 11 > IF  DROP invdraw  THEN
           2* cpctab + @ EXECUTE
           { SWAP 1+ 7 AND SWAP OVER 0= } IF  PAUSE  THEN
    REPEAT  2DROP ;

: startpic
   drawaddr dopic SINGLE STOP ;

: drawpic ( addr -- )
    TO drawaddr
    zx? IF    0 TO ink  48 TO hmin  [']  inclzx IS dopic
        ELSE  5 TO ink 128 TO hmin  ['] inclcpc IS dopic
        THEN  ['] startpic drawer TASK!  MULTI  drawer WAKE ;

: redraw
    rewins (redraw)
    INACC? C@ IF  2>R 2>R 2>R >R
                  >R 2DUP SWAP TYPE OVER R@ -
                  0 ?DO  8 CEMIT  LOOP R>
                  R> 2R> 2R> 2R>
              THEN ;

: prompt
    atprompt?
    IF  240 .msg gacflush  THEN ;

: pics-off
    FALSE TO pics?
    90 empty-output
    prompt ;

: pics-on
    EXP?
    IF  TRUE TO pics?
        48 empty-output
    ELSE  pics-off
    THEN
    prompt ;

: roompic ( room -- )
    pics?
    IF  >location 1 CELLS - @
	showing OVER =
        IF  DROP
	ELSE  DUP TO showing
              SINGLE drawer SLEEP GPAGE
              ?DUP IF  >picture IF  drawpic  THEN  THEN
        THEN
    ELSE  DROP
    THEN ;
