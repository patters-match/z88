\ *************************************************************************************
\
\ Canvas (c) Garry Lancaster, 2001-2002
\
\ Canvas is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ Canvas is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with Canvas;
\ see the file COPYING. If not, write to the Free Software Foundation, Inc.,
\ 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\ *************************************************************************************

CR .( Loading Canvas...)

ROM2 NS
S" arttools.fth" INCLUDED

\ Data

RAM HERE \ used up by init

0 VALUE dialog?
0 VALUE brush
0 VALUE dspray
0 VALUE rspray
DEFER drawpen
CREATE images 2048 3 * ALLOT  \ 0=temp, 1=undo, 2=RAMSave/Load
CREATE lastxy 2 CELLS ALLOT

HERE ROM2 \ used up by init

\ Misc

: wins    CINIT 6 0 39 8 0" Canvas" 1 OPENPOPUP  [CHAR] C ECLR  2 OPENMAP ;

\ Hints

: .xy ( x y -- )
   SWAP 4 .R ."  ," 4 .R ."  )" CR ;

: status
   0 3 AT-XY ." Pos  = (" GPOS? .xy  ." Last = (" lastxy 2@ .xy
   ." Mode = " GMODE C@ 
   CASE 0 OF ." Set" ENDOF 1 OF ." Reset" ENDOF 2 OF ." Invert" ENDOF ENDCASE ;

: xhelp ( a1 u1 a2 u2 -- )
   PAGE ." (c) Garry Lancaster, 2002" CR
   ." Move with QAOP" 2SWAP TYPE CR TYPE ;

: drawhelp  S" , SPACE accelerates" S" " xhelp status ;
: freehelp  S" , SPACE draws" S" Press ENTER to finish" xhelp status ;
: selhelp   S" " S" Press ENTER to select" xhelp ;

\ Saved images

: isave ( n -- )  2048 * images + getmap ;
: iload ( n -- )  2048 * images + putmap ;

\ Drawing

: setmode ( u -- )  GMODE C! status ;
: cmode ( -- u x y )  GMODE C@ 2 GMODE C! GPOS? ;
: dmode ( u x y -- )  GMOVE GMODE C! ;

: span@ ( -- w h )
   lastxy 2@ GPOS? ROT - SWAP ROT - SWAP lastxy 2@ GMOVE ; 

: cross ( x y u -- )
   >R 2DUP R@ - GPIXEL 0 R@ 2* GLINE
   SWAP R@ - SWAP GPIXEL R> 2* 0 GLINE ;

: cursors
   cmode 2DUP 4 cross lastxy 2@ 2 cross dmode ;

: C[  cursors ;
: ]C  cursors status ;

: clean
   0 GMODE C! GPAGE 1 isave 128 32 2DUP GMOVE lastxy 2! ]C drawhelp ;

: (move) ( +x +y -- )
   GPOS? ROT + 0 MAX 63 MIN
   SWAP ROT + 0 MAX 255 MIN SWAP GMOVE ;

: move ( +x +y -- )  C[ (move) ]C ;
: draw[ ( -- x y )   C[ 1 isave GPOS? ;

: last!   GPOS? lastxy 2! ;
: dot     draw[ GPIXEL last! ]C ;
: line    draw[ lastxy 2@ GMOVE GLINETO last! ]C ;
: box     draw[ span@ GBOX GMOVE last! ]C ;
: circle  draw[ lastxy 2@ span@ MAX GCIRCLE GMOVE last! ]C ;
: ellipse draw[ lastxy 2@ span@ GELLIPSE GMOVE last! ]C ;
: fill    draw[ GFILL ]C ;
: shade   draw[ GSHADE ]C ;
: join    C[ last! ]C ;

\ Pens, brushes and sprays

: rndxy ( x -- x' )
   rspray RND 2 RND IF NEGATE THEN + ;

: drawspray ( x y -- )
   dspray FOR  OVER rndxy OVER rndxy GPIXEL  STEP GMOVE ;

: drawbrush ( x y -- )
 { 2DUP brush OVER 4 + 2SWAP 4 - >R 4 -
   BEGIN  >R OVER C@ R> TUCK SWAP
     BEGIN  2* SPLIT IF  OVER R@ } GPIXEL { THEN SWAP 1+ SWAP ?DUP 0=  UNTIL
     DROP ROT 1+ ROT ROT OVER R> 1+ DUP >R =
   UNTIL  R> 2DROP 2DROP GMOVE ;

\ Standard pens ( x y -- )

( 00) :NONAME GPIXEL ;
( 01) :NONAME 2DUP 1+ GPIXEL OVER 1+ OVER GPIXEL OVER 1+ OVER 1+ GPIXEL GPIXEL ;
( 02) : p2    OVER 1+ OVER GPIXEL GPIXEL ;  ' p2
( 03) : p3    OVER 1- OVER GPIXEL p2 ;  ' p3
( 04) : p4    OVER 2 + OVER GPIXEL p3 ; :NONAME 2DUP 1+ p4 p4 ;
( 05) : p5    2DUP 1+ GPIXEL GPIXEL ;  ' p5
( 06) : p6    2DUP 1- GPIXEL p5 ;  ' p6
( 07) : p7    2DUP 2 + GPIXEL p6 ; :NONAME OVER 1+ OVER p7 p7 ;
( 08) : p8    OVER 1- OVER 1+ GPIXEL GPIXEL ;  ' p8
( 09) : p9    OVER 2 - OVER 2 + GPIXEL p8 ;  ' p9
( 10) : pA    OVER 3 - OVER 3 + GPIXEL p9 ;  ' pA
( 11) :NONAME OVER 1+ OVER pA pA ;
( 12) : pC    OVER 1+ OVER 1+ GPIXEL GPIXEL ;  ' pC
( 13) : pD    OVER 2 + OVER 2 + GPIXEL pC ;  ' pD
( 14) : pE    OVER 3 + OVER 3 + GPIXEL pD ;  ' pE
( 15) :NONAME OVER 1+ OVER pE pE ;

CREATE pens  ' drawspray , ' drawbrush ,
             , , , , , , , , , , , , , , , ,

: setpen   ( n -- )  17 SWAP - 2* pens + @ IS drawpen ;
: setspray ( n -- )  DUP 2 + TO rspray 2/ 1+ TO dspray  17 setpen ;
: setbrush ( n -- )  8 * brushes + TO brush  16 setpen ;

\ Freehand drawing

HEX
CODE OS_PUR   E7 C, 33 C,  NEXT

: kp? ( bit port -- flag )  PC@ AND 0= ;

: freemove ( -- l/r u/d )
   1 FBB2 kp? 1 EFB2 kp? -  8 DFB2 kp? 10 DFB2 kp? - ;

: magnify ( l/r u/d -- l'/r' u'/d' )
   40 DFB2 kp? IF  SWAP 8 * SWAP 8 *  THEN ;

: dopen
   40 DFB2 kp? IF  GPOS? drawpen  THEN ;

: freehand
   freehelp C[ 1 isave ]C
   BEGIN  freemove C[ (move) dopen ]C 40 FEB2 kp?  UNTIL OS_PUR drawhelp ;
DECIMAL

\ Tool selection

: sampxy ( n -- x y )
   8 /MOD 32 * SWAP 32 * 16 + 48 ROT - ;

: sampbox ( n size -- )
   >R sampxy R@ - SWAP R@ - SWAP GMOVE R> 2* DUP GBOX ;
   
: sample ( xt n=0..7 -- )
   TUCK 8 sampbox >R DUP sampxy ROT R> EXECUTE ;

: scursor ( n=0..7 -- )
   10 sampbox ;

: sampkey ( max n -- max n' flag )
   KEY 13 = IF  TRUE EXIT  THEN freemove -8 * + + 0 MAX OVER 1- MIN FALSE ;

: choice ( xt n -- n )
   GPAGE 0 GMODE C! DUP FOR  2DUP R@ - sample  STEP  NIP 2 GMODE C! ;

: choose ( max -- n )
   0 BEGIN  DUP >R DUP scursor sampkey R> scursor  UNTIL NIP ;

: select ( xt n=1..8 -- u )
   selhelp TRUE TO dialog?  C[ 0 isave 2>R cmode 2R> choice
   choose >R dmode R> 0 iload ]C  FALSE TO dialog? ;

\ Tool use

: dopat  8 * patterns + GPATTERN ;
: selpat  ['] dopat 8 select draw[ ROT dopat ]C drawhelp ;

:NONAME  setpen drawpen ;
: selpen  LITERAL 16 select setpen freehand ;

:NONAME  setbrush drawbrush ;
: selbrush  LITERAL 2 select setbrush freehand ;

:NONAME  setspray 2DUP drawspray drawspray ;
: selspray  LITERAL 8 select setspray freehand ;

\ Save/load

: getfname ( f -- a n )
   ." Filename: " [CHAR] C ESET TRUE TO dialog? 0 isave
   getfname [CHAR] C ECLR FALSE TO dialog? 0 iload ;

: ferr ( f a n -- )
   ROT IF  CR TYPE ."  error" 7 EMIT 2000 MS  ELSE  2DROP  THEN  drawhelp ;

: fsave
   PAGE FALSE getfname R/W CREATE-FILE ?DUP 0=
   IF  DUP images 2048 ROT WRITE-FILE OVER CLOSE-FILE OR  THEN
   NIP S" Save" ferr ;

: (fload) ( offset -- f )
   >R TRUE getfname R/O OPEN-FILE ?DUP 0=
   IF  DUP R@ S>D ROT REPOSITION-FILE
       OVER images 2048 ROT READ-FILE SWAP 2048 <> OR OR
       OVER CLOSE-FILE OR
   THEN
   NIP DUP S" Load" ferr R> DROP ;

: fload
   PAGE 0 (fload)  0= IF  C[ 0 iload ]C  THEN ;

: fimport
   PAGE ." Third 1-3? " TRUE TO dialog?
   BEGIN  KEY [CHAR] 0 - DUP 1 < OVER 3 > OR  WHILE  DROP  REPEAT
   DUP . CR 1- 2048 * (fload)
   0= IF  C[ images zxscreen ]C  THEN ;

\ Top-level

' selspray \ 152
' selbrush \ 151
' selpen  \ 150
' selpat  \ 149
' shade   \ 148
' fill    \ 147
:NONAME  2 setmode ; \ 146
:NONAME  1 setmode ; \ 145
:NONAME  0 setmode ; \ 144
' clean   \ 143
' ellipse \ 142
' circle  \ 141
' box     \ 140
' line    \ 139
' dot     \ 138
' join    \ 137
' BYE     \ 136
:NONAME  C[ 1 iload ]C ; \ 135=undo
:NONAME  C[ 2 iload ]C ; \ 134=RAMLoad
:NONAME  C[ 2 isave ]C ; \ 133=RAMSave
' fsave   \ 132=save
' fload   \ 131=load
' fimport \ 130=import

CREATE comkeytab , , , , , , , , , , , , , , , , , , , , , , ,

: beep ( event -- )
   7 EMIT DROP ;

: comkeys ( x -- )
   dialog? IF  beep EXIT  THEN
   256 - DUP 129 U> OVER 153 U< AND
   IF  130 - 2* comkeytab + @ EXECUTE  ELSE  DROP  THEN ;

( a1 a2 -- ) : init
   [ OVER ] LITERAL [ SWAP - ] LITERAL ERASE wins ;

: canvas
   init clean BEGIN  KEY freemove magnify move 27 = UNTIL QUIT ;

' BYE     IS (RC_QUIT)
' wins    IS (RC_DRAW)
' comkeys IS (KEY)
' comkeys IS (ACC_EVT)
' canvas  IS (COLD)

RAM NS
