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

CR .( Loading WhatNow?...)

ROM2 NS

S" zxscreen.fth" INCLUDED

\ Data

255   CONSTANT it
32767 CONSTANT with
-4096 CONSTANT exc-end
-4097 CONSTANT exc-wait
-4098 CONSTANT exc-exit
-4099 CONSTANT exc-endinp
-4100 CONSTANT exc-esc
-4101 CONSTANT exc-close
-4102 CONSTANT exc-open
-4103 CONSTANT exc-badmem
-2    CONSTANT exc-error
256   CONSTANT #ptrs
90    CONSTANT maxlen
8     CONSTANT buflines
21000 CONSTANT gacsize
20    CONSTANT maxudgs

RAM

0  VALUE verb
0  VALUE adve
0  VALUE no1
0  VALUE no2
0  VALUE lastnoun
0  VALUE newnoun
0  VALUE noinput?
0  VALUE room
0  VALUE room-a
0  VALUE room-l
0  VALUE stkbal
0  VALUE valid?
0  VALUE ptrwidth
0  VALUE linelen
0  VALUE strdone?
0  VALUE ingame?
0  VALUE atprompt?
0  VALUE dialog?
0  VALUE pause?
0  VALUE pics?
0  VALUE drawn?
0  VALUE showing
0  VALUE drawaddr
0  VALUE ink
0  VALUE hmin
0  VALUE gotudgs?
0  VALUE errordata
0  VALUE errortype
0  VALUE errornum
0  VALUE trap?
0  VALUE snapid
0  VALUE ext#
0  VALUE zx?

DEFER (redraw)
DEFER xferdata
DEFER balanced?
DEFER dopic

CREATE gac-data gacsize CELL+ ALLOT
CREATE oneline maxlen 1+ CHARS ALLOT
CREATE udgbuf maxudgs ALLOT
CREATE counters 128 ALLOT
CREATE markers 32 ALLOT
CREATE ptrs #ptrs CELLS ALLOT

VARIABLE bufline
VARIABLE buftop
VARIABLE bufshown
VARIABLE bufadd
VARIABLE bufpos
VARIABLE linest
VARIABLE stre
VARIABLE #words
VARIABLE procptr
VARIABLE nopause
VARIABLE wtitle

ROM2

TASK: drawer

32768 0 POOL gacpool

\ We make an allocation of 1421 bytes first, so we know fixed far addresses
\ Because of problems with FREEing we're currently allocating a fixed amount
\ at startup, and only FREEALLing at application exit...

1421 CONSTANT farsize
1    CONSTANT farhi
2    CONSTANT obj-table  \ pointers to objects (512 bytes)
514  CONSTANT linebufs   \ 8x91 char buffer (728 bytes)
1242 CONSTANT udgdefs    \ UDGs (1+9*maxudgs = 181 bytes)
1423 CONSTANT vocalloc   \ vocabulary (space required varies)

26624 CONSTANT maxfar

RAM CR .( Space left in RAM region: ) 32512 HERE - . ROM2

\ General-purpose words

: Y/N ( -- flag )
    BEGIN
      KEY
      DUP  [CHAR] Y <>     OVER [CHAR] y <> AND
      OVER [CHAR] N <> AND OVER [CHAR] n <> AND
    WHILE
      DROP
    REPEAT
    DUP [CHAR] Y = SWAP [CHAR] y = OR ;


\ Game error generation

: seterror ( -- flag )
    0 TO errortype  trap? ;

: setfdataerr ( code -- true )
    TO errordata  1 TO errortype  TRUE ;

: setprocerr ( -- flag )
    2 TO errortype  trap? ;

: ferror"
    POSTPONE IF  POSTPONE setfdataerr POSTPONE ABORT"
    POSTPONE ELSE POSTPONE DROP POSTPONE THEN ; IMMEDIATE

: procerror"
    POSTPONE IF  POSTPONE setprocerr POSTPONE ABORT"
    POSTPONE THEN ; IMMEDIATE

: serror"
    POSTPONE seterror POSTPONE ABORT" ; IMMEDIATE

\ Database words
  
: turn-a ( -- turnaddr ) 
    counters 126 CHARS + ;

: gacptr ( n "name" -- )
    CREATE CELLS , CELLS ,
    DOES> zx? IF  @  ELSE  CELL+ @  THEN gac-data + @ ;

0 0 gacptr gac-nouns
1 1 gacptr gac-adverbs
2 2 gacptr gac-objects
3 3 gacptr gac-locations
4 4 gacptr gac-high
5 5 gacptr gac-local
6 6 gacptr gac-low
7 7 gacptr gac-messages
9 8 gacptr gac-pictures
10 9 gacptr gac-vocab
11 10 gacptr gac-free
12 23 gacptr gac-start

: gac-verbs
    zx? IF  48  ELSE  256  THEN gac-data + ;

: gac>off ( addr -- offset )
    zx? IF  42271  ELSE  16384  THEN - ;

: cnvptr ( ptr -- offset )
    CELLS gac-data + DUP @ gac>off TUCK gac-data + SWAP ! ;

: convert-pointers
    zx? IF  10  ELSE  11  THEN
    0 DO  I DUP cnvptr gacsize 1- U> ferror" Bad pointer "  LOOP ;

: convert-words
    0 #words !  0 TO errortype
    gac-vocab gac-free gac>off gac-data + OVER - vocalloc +
    maxfar U> ABORT" Out of memory"
    vocalloc  gac-vocab gac-data - 0 snapid REPOSITION-FILE DROP
    BEGIN  oneline 1 snapid READ-FILE ABORT" Vocab read error"
           0<> oneline C@ AND
    WHILE  oneline COUNT snapid READ-FILE SWAP oneline C@ <> OR
           ABORT" Error reading vocab"
           oneline COUNT 2DUP + 1- DUP C@ 127 AND SWAP C! >LOWER
           DUP oneline >FAR ROT farhi oneline C@ 1+ CMOVEL
           oneline C@ 1+ +  1 #words +!
    REPEAT  DROP ;

: convert-objects
    256 0 DO  0 obj-table I CELLS + farhi !L  LOOP
    gac-objects
    BEGIN  COUNT ?DUP
    WHILE  CELLS obj-table +
           OVER 1 CHARS - SWAP farhi !L
           COUNT CHARS +
    REPEAT
    DROP ;

\ Word access using pointers

: word-ptrs
    #words @ #ptrs 1- + #ptrs / TO ptrwidth
    vocalloc
    #words @ 0 ?DO  I ptrwidth MOD 0=
                    IF  DUP ptrs I ptrwidth / CELLS + !  THEN
                    DUP farhi C@L + 1+
                LOOP
    DROP ;


\ Markers and counters

: >marker ( marker -- addr bit bl bh )
    SPLIT procerror" Bad marker at "
    13 NSPLIT CHARS markers + 16 ROT -
    OVER C@ OVER NSPLIT ;

: marker! ( addr bit bl bh -- )
    ROT NJOIN SWAP C! ;

: mset ( marker -- )
    >marker 1 OR marker! ;

: mreset ( marker -- )
    >marker 65534 AND marker! ;

: mtest ( marker -- flag )
    >marker 2SWAP 2DROP NIP 1 AND ;

: >counter ( counter -- addr n )
    9 NSPLIT procerror" Bad counter at "
    CHARS counters + DUP C@ ;

: cincr ( counter -- )
    >counter DUP 255 <> IF  1+  THEN SWAP C! ;

: cdecr ( counter -- )
    >counter DUP 0<> IF  1-  THEN SWAP C! ;

: cset ( n counter -- )
    >counter DROP C! ;

: cget ( counter -- n )
    >counter NIP ;

\ Output buffering words
\ Note, bufline and buftop should always be taken MOD 8

: >bufline ( n -- L-addr )
    buflines MOD maxlen 1+ CHARS *
    linebufs + ;

: newoutline
    bufline @ >bufline
    DUP bufadd !
    oneline maxlen 1+ ERASE
    oneline >FAR ROT farhi maxlen 1+ CMOVEL
    0 bufpos ! 0 linest ! ;

: flushed
    bufpos @ linest ! ;

: showline ( L-addr -- )
    gotudgs?
    IF  BEGIN
          DUP farhi C@L DUP
        WHILE
          DUP udgbuf udgdefs farhi C@L ROT SCAN
          IF  udgbuf - 64 + UDG DROP
          ELSE  DROP EMIT
          THEN
          CHAR+
        REPEAT
        2DROP
    ELSE  farhi oneline >FAR maxlen 1+ linest @ - 
          CMOVEL oneline 0TYPE
    THEN ;

: gacflush
    bufline @ >bufline linest @ +
    showline
    flushed ;

: nextoutline
    bufshown @ buflines = 
    IF  1 buftop +!
    ELSE  1 bufshown +!
    THEN
    1 bufline +!
    newoutline ;

: gaclf
    gacflush 
    1 nopause +!
    nopause @ 8 = IF  0 nopause !
                      pause? IF  PW  THEN
                  THEN
    CR
    nextoutline ;

: gactype ( c-addr n case -- )
    >R
    DUP DUP linelen 1- > ferror" Word too long: "
    bufpos @ OVER + DUP linelen 1- >
    IF  DROP DUP gaclf  THEN
    bufpos !
    R@ 0= IF  2DUP 1 MIN >UPPER  THEN
    R> 2 = IF  2DUP >UPPER  THEN
    >R >FAR bufadd @ farhi R>
    DUP bufadd +!
    CMOVEL ;

: gacemit ( char -- )
    bufpos @ 0= OVER BL = AND
    IF  DROP EXIT  THEN
    bufpos @ linelen <
    IF  bufadd @ farhi C!L
        1 bufadd +!  1 bufpos +!
    ELSE  gaclf RECURSE
    THEN ;

: inp>out ( c-addr n -- )
    0 ?DO  bufpos @ linelen < 0=
           IF  nextoutline  THEN
           DUP C@ bufadd @ farhi C!L
           1 bufadd +!  1 bufpos +!
           CHAR+
      LOOP DROP
    flushed ;

: prin ( u -- )
    <# 0 #S #> 1 gactype ;

: mixedwin
    1 0 49 8 1 OPENWINDOW  2 OPENMAP  4 GMODE C! ;

: rewins
    0 TO showing  SINGLE drawer SLEEP
    pics? IF  mixedwin  ELSE  CINIT  THEN ;    

: empty-output ( linelen -- )
    rewins
    maxlen MIN TO linelen
    0 bufline ! 0 buftop ! 0 bufshown !
    ingame? IF  newoutline  THEN
    0 nopause ! ;

: buffershow
    bufshown @ DUP buflines = 1 AND
    ?DO  I buftop @ + >bufline
         showline CR
    LOOP
    buftop @ bufshown @ + >bufline
    showline ;


\ Vocabulary and message stuff

: >word ( wordno -- L-addr n )
    DUP DUP 1+ #words @ U> ferror" Bad word number: "
    ptrwidth /MOD CELLS ptrs + @
    SWAP 0 ?DO  DUP farhi C@L 1+ +  LOOP
    DUP 1+ SWAP farhi C@L ;

: convert-vocab	( c-addr c-addrmax -- )
    >R
    BEGIN
      DUP DUP R@ U> ferror" Bad vocab address "
      COUNT
    WHILE
      DUP @ 32767 AND >word
      DROP 1- OVER !
      CELL+
    REPEAT
    1+ DUP R> <> ferror" Bad vocab address " ;

: flashy ( c-addr n -- )
    PAGE CR
    [CHAR] C EALIGN
    [CHAR] R ESET [CHAR] F ESET
    [CHAR] C ECLR
    SPACE TYPE SPACE CR
    [CHAR] R ECLR [CHAR] F ECLR
    [CHAR] N EALIGN ;

: convert-gac
    S" Validating..." flashy
    gac-data @ 41723 U> TO zx?
    convert-pointers
    gac-vocab gac-data gacsize + U> ferror" Game too big"
    convert-words word-ptrs convert-objects
    gac-verbs gac-nouns convert-vocab
    gac-nouns gac-adverbs convert-vocab
    gac-adverbs gac-objects convert-vocab ;

CREATE nullstr  HEX C001 , DECIMAL 

: >msg ( msgno -- c-addr )
    >R gac-messages
    BEGIN
      COUNT DUP 0= IF  trap?
                       IF  R@ TRUE ferror" Message not found: "
                       ELSE  2DROP R> DROP nullstr EXIT
                       THEN
                   THEN
      R@ = IF  CHAR+ R> DROP EXIT  THEN
      COUNT CHARS +
    AGAIN ;

: >location ( locno -- c-addr )
    >R gac-locations
    BEGIN
      DUP @ R@ OVER 0= ferror" Location not found: "
      R@ = IF  R> DROP 3 CELLS + EXIT  THEN
      CELL+ DUP @ CHARS + CELL+
    AGAIN ;

: conns>desc ( c-addr -- c-addr' )
    BEGIN  DUP C@  WHILE  CHAR+ CELL+  REPEAT
    CHAR+ ;

: >local ( -- addr|0 )
    gac-local
    BEGIN
      DUP @ DUP
    WHILE
      room = IF  CELL+ EXIT  THEN
      CELL+ BEGIN  DUP C@ DUP
            WHILE  128 AND IF  CHAR+  THEN
                   CHAR+
            REPEAT
      DROP CHAR+
    REPEAT
    NIP ;

: >object ( objno -- c-addr|0 )
    SPLIT  IF  DROP 0
           ELSE  CELLS obj-table + farhi @L
           THEN ;

: >object? ( objno -- c-addr flag )
    >object DUP ;

CREATE nullobj  0 , 1 C, 0 , HEX C001 , DECIMAL

: >object: ( objno -- c-addr )
    DUP >object DUP 0=
    IF  trap?
	IF  DROP TRUE ferror" Object not found: "
        ELSE  2DROP nullobj
        THEN
    ELSE  NIP
    THEN ;

: objloc>desc ( c-addr -- c-addr' )
    CELL+ CHAR+ CELL+ ;

: carr? ( obj -- flag )
    >object? IF  @ with = 1 AND  THEN ;

: here? ( obj -- flag )
    >object? IF  @ room = 1 AND  THEN ;

: held ( --weight )
    0
    256 0 DO  I carr?
              IF  I >object CELL+ C@ +  THEN
          LOOP ;

CREATE punctab
  0 C, BL C,
  CHAR . C, CHAR , C,
  CHAR - C, CHAR ! C,
  CHAR ? C, CHAR : C,

: punc ( n -- char )
    punctab + C@
    DUP 0= TO strdone? ;

: .punc ( char -- )
    ?DUP IF  gacemit  THEN ;

: .stritem ( u -- )
    5 NSPLIT 13 NSPLIT   \ u -- bits10to0 bits13to11 bits15to14
    DUP 3 = IF  DROP punc SWAP 255 AND OVER BL = OVER 7 > AND
                IF  gaclf 2DROP
                ELSE  0 ?DO  DUP .punc  LOOP  DROP  THEN
            ELSE  ROT >word >R farhi PAD >FAR R@ CMOVEL
                  PAD R> ROT gactype punc .punc
            THEN ;

: .str ( c-addr -- )
    FALSE TO strdone?
    BEGIN  DUP @ .stritem CELL+
    strdone? UNTIL
    DROP ;

: .msg ( msgno -- )
    >msg .str ;

: .obj ( obj -- )
    >object: objloc>desc .str ;

: listobjs ( room -1|msg -- flag )
    256 0 DO  OVER obj-table I CELLS + farhi @L ?DUP
              IF  @ =
                  IF  DUP IF  DUP 0>
                              IF  .msg  ELSE  DROP  THEN
                              0
                          ELSE  [CHAR] , gacemit
                          THEN
                      I .obj
                  THEN
              ELSE  DROP
              THEN
          LOOP
    NIP 0= ;


\ Pictures

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

: desc ( room -- )
    1 mtest 2 mtest OR
    IF	0 mreset
	TRUE TO drawn?
        DUP roompic
	DUP >location conns>desc .str
        253 listobjs DROP
    ELSE  251 .msg
	  SINGLE drawer SLEEP GPAGE
	  FALSE TO drawn?
          0 TO showing
    THEN ;

: goto ( room -- )
    DUP >location TO room-a
    DUP TO room
    >local TO room-l
    desc ;

: conn ( verb -- room|0 )
    >R room-a
    BEGIN  COUNT ?DUP
    WHILE  R@ =
           IF  @ R> DROP EXIT  THEN 
           CELL+
    REPEAT
    R> 2DROP 0 ;


\ Popup dialogs

: greywins
    SINGLE drawer SLEEP pics? IF  2 WINDOW GREY  THEN
    1 WINDOW GREY ;

: reswin ( c-addr -- )
    greywins
    >R 30 1 30 7 R> 3 OPENPOPUP
    [CHAR] C ECLR [CHAR] C EALIGN
    CR ;

: reswait
    CR CR
    [CHAR] F ESET [CHAR] B ESET
    ." Press "
    [ HEX ] E4 [ DECIMAL ] XCHAR 
    ."  to resume"
    [CHAR] F ECLR [CHAR] B ECLR
    [CHAR] N EALIGN ;

: dialog ( xt -- )
    ['] (redraw) >BODY @ >R
    IS (redraw)
    TRUE TO dialog?
    (redraw)
    BEGIN  KEY 27 =  UNTIL
    FALSE TO dialog?
    R> IS (redraw) ;

: disperr
    errornum
    CASE  0 OF ENDOF
          exc-error OF  0" ERROR!" reswin
                        ABORT"S 2@ SWAP TYPE
                        errortype
                        CASE 0 OF  ENDOF
                             1 OF  errordata U.  ENDOF
                             2 OF  procptr @ 1- gac-data - U.  ENDOF
                        ENDCASE
                        reswait
                    ENDOF
      0" ERROR!" reswin ." Unexpected error " DUP .
      reswait
    ENDCASE ;

: !error!
    ['] disperr dialog ;

: errpopup ( c-addr u -- )
    0 TO errortype
    exc-error TO errornum
    SWAP ABORT"S 2!
    !error! ;

: fnamebox
    greywins
    30 2 30 5 wtitle @ 3 OPENPOPUP
    CR SPACE ;

: resultbox
    0" Information" reswin
    CR ABORT"S 2@ SWAP TYPE errortype U.
    reswait ;
 
: respopup ( c-addr u x -- )
    TO errortype
    SWAP ABORT"S 2!
    ['] resultbox dialog ;

: escack
    1 OS_ESC DROP  0 INACC? C!
    exc-esc THROW ;

: usemail ( m l a p -- m l' a p' )
    0" NAME" CHECKMAIL
    IF  1- 2>R 0 ?DO  8 EMIT  LOOP
        OVER SPACES
        SWAP   0 ?DO  8 EMIT  LOOP
        OVER 2R> ROT UMIN 2DUP TYPE >R
        OVER R@ CMOVE R> TUCK
    THEN ;

: getfname ( c-addr1 -- [c-addr2 n] flag )
    wtitle !
    TRUE TO dialog?
    ['] (redraw) >BODY @ >R
    ['] fnamebox IS (redraw)  ['] usemail IS (ACC_MAIL)
    fnamebox
    5 OS_ESC DROP
    PAD 80 ['] ACCEPT CATCH
    6 OS_ESC DROP
    R> IS (redraw)  ['] NOOP IS (ACC_MAIL)
    FALSE TO dialog?  
    IF  2DROP FALSE
    ELSE  PAD SWAP TRUE
    THEN ;   
  
: load/save ( fileid -- flag )
    >R
    markers 32 R@ xferdata
    counters 128 R@ xferdata OR
    ['] room >BODY 2 R@ xferdata OR
    stre 2 R@ xferdata OR
    R>
    256 0 DO  I SWAP >R
              >object? 0= IF  DROP PAD  THEN
              2 R@ xferdata OR
              R>
          LOOP
    DROP ;

: savegame
    0" Save game position" getfname
    IF  S" Saving..." flashy
        ['] WRITE-FILE IS xferdata
        R/W CREATE-FILE ?DUP 0=
        IF  DUP load/save SWAP CLOSE-FILE OR
        ELSE  NIP
        THEN
        IF  S" Save error" errpopup  THEN
    THEN
    redraw ;

: readdata ( addr n fileid -- flag )
    OVER >R
    READ-FILE
    SWAP R> <> OR ;

: loading ( c-addr n -- fileid flag )
    S" Loading..." flashy
    R/O OPEN-FILE 0= ;

: notfound ( x -- )
    DROP S" File not found" errpopup
    redraw ;

: loadgame
    0" Load game position" getfname
    IF  ['] readdata IS xferdata
        loading
        IF  DUP load/save SWAP CLOSE-FILE OR
            IF  S" Load error" errpopup
                redraw exc-exit THROW
            THEN
            linelen empty-output
            room goto
            exc-wait THROW
        ELSE  notfound
        THEN
    ELSE  redraw
    THEN ;

: 0>S ( c-addr -- c-addr u )
    DUP 256 0 SCAN NIP 256 SWAP - ;

: >ext ( -- c-addr )
    0PAD 0>S
    2DUP [CHAR] . SCAN NIP
    IF  BEGIN
          2DUP [CHAR] . SCAN ?DUP
        WHILE
          1- SWAP CHAR+ SWAP 2SWAP 2DROP
        REPEAT  2DROP 1-
    ELSE  +
    THEN ;

: append ( c-addr1 c-addr2 u -- c-addr3 )
    >R OVER R@ CMOVE R> + ;

: nameit
    0PAD 0>S
    BEGIN  2DUP [CHAR] / SCAN ?DUP
    WHILE  1- SWAP CHAR+ SWAP 2SWAP 2DROP
    REPEAT
    DROP 2DUP [CHAR] . SCAN NIP - *NAME ; 

: erasegac
    gac-data gacsize CELL+ ERASE ;

: defudgs
    udgdefs farhi C@L
    udgdefs OVER 1+ CHARS +
    SWAP 0 ?DO  DUP farhi udgbuf >FAR 8 CMOVEL
                udgbuf I 64 + DEFUDG
                8 CHARS +
           LOOP
    DROP
    udgdefs 1+ farhi udgbuf >FAR maxudgs CMOVEL ;

: getudgs
    FALSE TO gotudgs?
    >ext S" .udg" append 0 SWAP C!
    0PAD 0>S R/O OPEN-FILE
    IF  DROP
    ELSE  DUP gac-data maxudgs 9 * 1+ ROT READ-FILE 0=
          SWAP gac-data C@ 9 * 1+ = AND
          IF  TRUE TO gotudgs?
              gac-data >FAR udgdefs farhi maxudgs 9 * 1+ CMOVEL
              defudgs
          THEN
          CLOSE-FILE DROP
    THEN ;

: load-adv
    0" Load GAC datafile" getfname
    IF  0 0 *NAME loading
        IF  TO snapid
            getudgs erasegac 0 0 HOLE 2!
            gac-data gacsize snapid READ-FILE 2DROP
            ['] convert-gac CATCH snapid CLOSE-FILE DROP THROW
            nameit exc-open THROW
        ELSE  notfound
        THEN
    ELSE  redraw
    THEN ;

: writeerr ( ior fileid|0 -- )
    SWAP
    IF  snapid CLOSE-FILE DROP
        ?DUP IF  CLOSE-FILE DROP  THEN
        0 TO errortype
        ABORT" Error writing file"
    ELSE  DROP  THEN ;

: creategac ( -- fileid )
    >ext S" .gac" append
    ext# 1 > IF  ext# [CHAR] 0 + OVER 1- C!  THEN
    0 SWAP C!
    0PAD 0>S R/W CREATE-FILE 0 writeerr ;

: readgac ( Dpos offset -- Dpos )
    0 2OVER D+ snapid REPOSITION-FILE DROP
    erasegac
    gac-data gacsize snapid READ-FILE 2DROP ;

: size? ( gacstart gacend -- gacsize flag )
    >R >R gac-free R@ -
    gac-free R> 26 + U< gac-free R> U> OR 0= ;

: writegac ( Dpos size offset -- Dpos' )
    SWAP >R M+ 2DUP snapid REPOSITION-FILE DROP
    R@ M+ R>
    ext# 1+ TO ext# creategac >R
    BEGIN  gac-data OVER gacsize UMIN
           2DUP snapid READ-FILE NIP R@ writeerr
           TUCK R@ WRITE-FILE R@ writeerr
           - ?DUP 0=
    UNTIL
    R> CLOSE-FILE 0 writeerr ;

: extgac ( Dpos addr u -- Dpos' )
    S" Extracting..." flashy
    DROP gac-data - M+
    826 readgac 
    TRUE TO zx? 42271 65535 size?
    IF  826 writegac
    ELSE  DROP
	  7924 readgac
	  FALSE TO zx? 16384 41723 size?
          IF  7924 writegac
          ELSE  DROP
                8 M+
          THEN
    THEN
    S" Searching..." flashy ;

: extract
    0" Extract GAC datafile" getfname
    IF  R/O OPEN-FILE 0=
	IF  TO snapid  0 TO ext#
            0 0
            S" Searching..." flashy
	    BEGIN
              erasegac
              2DUP snapid REPOSITION-FILE DROP
              gac-data gacsize snapid READ-FILE DROP
            WHILE
              gac-data gacsize punctab 8 SEARCH
              IF  extgac  ELSE  2DROP gacsize 8 - M+  THEN
            REPEAT
            2DROP
	    snapid CLOSE-FILE DROP
            S" GACs extracted: " ext# respopup
            redraw         
        ELSE  notfound
        THEN
    ELSE  redraw
    THEN ;

\ Process table stuff

' balanced?                                       \ END ($3f)
:NONAME  IF  balanced? TRUE TO valid? EXIT  THEN  \ IF ($3e)
   balanced? procptr @
   BEGIN  DUP C@  DUP 63 = OVER 0= OR
     IF  DROP procptr ! EXIT  THEN
     128 AND IF  CHAR+  THEN  CHAR+
   AGAIN ;
' gaclf                                           \   LF ($3d)
:NONAME  stre C! ;                                \ STRE ($3c)
' with                                            \ WITH ($3b)
:NONAME  >object: CELL+ C@ ;                      \ WEIG ($3a)
' conn                                            \ CONN ($39)
' pics-off                                        \ TEXT ($38)
' pics-on                                         \ PICT ($37)
:NONAME  -1 listobjs 0=                           \ LIST ($36)
   IF  S" nothing" 1 gactype  THEN ;
' verb                                            \ VBNO ($35)
' no2                                             \  NO2 ($34)
' no1                                             \  NO1 ($33)
' goto                                            \ GOTO ($32)
:NONAME  adve = 1 AND ;                           \ ADVE ($31)
:NONAME  verb = 1 AND ;                           \ VERB ($30)
:NONAME  DUP no1 = SWAP no2 = OR 1 AND ;          \ NOUN ($2f)
' room                                            \ ROOM ($2e)
:NONAME  exc-exit THROW ;                         \ EXIT ($2d)
:NONAME  244 .msg gacflush Y/N                    \ QUIT ($2c)
   IF  exc-exit THROW  THEN ;
:NONAME  exc-wait THROW ;                         \ WAIT ($2b)
:NONAME  254 .msg gaclf exc-wait THROW ;          \ OKAY ($2a)
:NONAME  serror" OP29: Bad action" ;              \ OP29 ($29)
:NONAME  serror" OP28: Bad action" ;              \ OP28 ($28)
:NONAME  SWAP >object? IF @ = 1 AND ELSE NIP THEN ; \ IN ($27)
:NONAME  >object?                                 \ FIND ($26)
   0= OVER @ 0= OR IF  252 .msg exc-wait THROW  THEN
   @ DUP with = IF  245 .msg exc-wait THROW  THEN
   goto ;
:NONAME  >object?  IF  DUP @  ELSE  0  THEN       \ BRIN ($25)
   0= IF  252 .msg exc-wait THROW  THEN
   DUP @ with = IF  245 .msg exc-wait THROW  THEN 
   room SWAP ! ;
:NONAME  room = 1 AND ;                           \   AT ($24)
:NONAME  turn-a @ ;                               \ TURN ($23)
' -                                               \    - ($22)
' +                                               \    + ($21)
' carr?                                           \ CARR ($20)
:NONAME  DUP carr? SWAP here? OR ;                \ AVAI ($1f)
' here?                                           \ HERE ($1e)
' loadgame                                        \ LOAD ($1d)
' savegame                                        \ SAVE ($1c)
:NONAME  = 1 AND ;                                \    = ($1b)
:NONAME  > 1 AND ;                                \    > ($1a)
:NONAME  < 1 AND ;                                \    < ($19)
' RND                                             \ RAND ($18)
' prin                                            \ PRIN ($17)
' .msg                                            \ MESS ($16)
:NONAME  room desc ;                              \ LOOK ($15)
' desc                                            \ DESC ($14)
:NONAME  cget = 1 AND ;                           \ EQU? ($13)
' cincr                                           \ INCR ($12)
' cdecr                                           \ DECR ($11)
' cget                                            \  CTR ($10)
' cset                                            \ CSET ($0f)
:NONAME  mtest 1 XOR ;                            \ RES? ($0e)
' mtest                                           \ SET? ($0d)
' mreset                                          \ RESE ($0c)
' mset                                            \  SET ($0b)
' .obj                                            \  OBJ ($0a)
:NONAME  SWAP >object: ! ;                        \   TO ($09)
:NONAME  >object: DUP @ ROT                       \ SWAP ($08)
   >object: DUP @ ROT ROT ! SWAP ! ;
:NONAME  DUP carr? 0=                             \ DROP ($07)
   IF  246 .msg exc-wait THROW  THEN >object room SWAP ! ;
:NONAME                                           \ GET ($06)
   DUP carr? IF  245 .msg exc-wait THROW  THEN
   DUP here? 0= IF  247 .msg exc-wait THROW  THEN
   held OVER >object CELL+ C@ + stre C@ < 0=
   IF  248 .msg exc-wait THROW  THEN
   >object with SWAP ! ;
:NONAME  gacflush  0 nopause !                    \ HOLD ($05)
   0 ?DO  20 MS KEY? IF  KEY DROP LEAVE  THEN  LOOP ;
' XOR                                             \  XOR ($04)
:NONAME  0= 1 AND ;                               \  NOT ($03)
' OR                                              \   OR ($02)
' AND                                             \  AND ($01)
:NONAME  balanced? exc-end THROW ;                \  end ($00)

CREATE gac-actions , , , , , , , , , , , , , , , ,
                   , , , , , , , , , , , , , , , ,
                   , , , , , , , , , , , , , , , ,
                   , , , , , , , , , , , , , , , ,

: procloop
    BEGIN
      procptr @ C@
      1 procptr +!
      DUP 128 AND
      IF  128 XOR 8 LSHIFT
	  procptr @ C@ +
	  1 procptr +!
      ELSE  63 AND CELLS gac-actions +
            @ EXECUTE
      THEN
    AGAIN ;

: process ( addr -- )
    procptr !
    DEPTH TO stkbal
    ['] procloop CATCH
    DUP exc-end <> IF  THROW  ELSE  DROP  THEN ;

: (bal?) ( i*x -- i*x )
    DEPTH stkbal <> procerror" Stack imbalance at " ;

\ Parser

: word? ( c-addr u addr -- c-addr u false | n true )
  { BEGIN
      COUNT ?DUP
    WHILE
      >R DUP @ DUP 1+ farhi ROT farhi C@L >R PAD >FAR R@ CMOVEL
      R> 2OVER ROT PAD SWAP
      ROT 2>R R@ } S= 2R> < { OR
      IF  CELL+ R> DROP
      ELSE  2DROP DROP R> TRUE } EXIT {
      THEN
    REPEAT
    DROP FALSE ;      

: parseword ( c-addr n -- )
    2DUP S" and" COMPARE 0= >R
    2DUP S" then" COMPARE 0= R> OR IF  exc-endinp THROW  THEN
    verb 0=
    IF  gac-verbs word?
        IF  TO verb EXIT  THEN
    THEN
    adve 0=
    IF  gac-adverbs word?
        IF  TO adve EXIT  THEN
    THEN
    no1 0= no2 0= OR
    IF  gac-nouns word?
        IF  no1 0=
            IF  TO no1  ELSE  TO no2  THEN
            EXIT
        THEN
    THEN
    2DROP ;

: null-input
    0 TO verb  0 TO adve
    0 TO no1   0 TO no2 ;

: replace-it
    lastnoun TO newnoun
    no1 it = IF  lastnoun TO no1  
             ELSE  no1 IF  no1 TO newnoun  THEN
             THEN
    no2 it = IF  lastnoun TO no2
             ELSE  no2 IF  no2 TO newnoun  THEN
             THEN
    newnoun TO lastnoun ;

: punc? ( c-addr n -- c-addr n )
    2DUP 2>R
    2R@ [CHAR] . SCAN NIP
    2R@ [CHAR] , SCAN NIP MAX
    2R@ [CHAR] ! SCAN NIP MAX
    2R@ [CHAR] ? SCAN NIP MAX
    2R@ [CHAR] : SCAN NIP MAX
    2R> [CHAR] ; SCAN NIP MAX
    ?DUP IF >IN @ OVER SOURCE NIP >IN @ = IF  1-  THEN
             - >IN !
             - ?DUP IF  parseword  ELSE  DROP  THEN
             exc-endinp THROW
         THEN ;

: parse-input
    null-input
    BEGIN  BL WORD COUNT ?DUP  WHILE  punc? parseword  REPEAT
    DROP ;

\ Main loop

: initialise
    0 TO lastnoun
    TRUE TO noinput?
    FALSE TO drawn?
    markers 32 ERASE
    counters 128 ERASE
    null-input
    1 mset
    250 stre C!
    256 0 DO  obj-table I CELLS + farhi @L
              ?DUP IF  DUP CELL+ CHAR+ @ SWAP !  THEN
          LOOP
    linelen empty-output [CHAR] C ESET
    gac-start goto ;

: more-input
    gaclf
    noinput?
    IF  TRUE TO atprompt?
	prompt
        0 nopause !
        REFILL DROP 0 >IN !
        SOURCE inp>out gaclf
        SOURCE >LOWER
        FALSE TO atprompt?
    THEN
    TRUE TO noinput? ;

: getcommand
    more-input 
    ['] parse-input CATCH 
    DUP exc-endinp <> IF  THROW  ELSE  DROP  THEN
    SOURCE NIP >IN @ U> 0= TO noinput?
    replace-it ;

: do-turn
    getcommand
    FALSE TO valid?
    verb conn ?DUP IF  goto exc-wait THROW  THEN
    room-l ?DUP IF  process  THEN
    gac-low process
    SOURCE NIP 0= valid? OR IF  EXIT  THEN
    verb 0= IF  242 .msg  ELSE  241 .msg  THEN ;

: play-gac
    initialise
    BEGIN
      gac-high ['] process CATCH ?DUP
      IF  NIP DUP exc-wait <> IF  THROW  ELSE  DROP  THEN  THEN
      1 turn-a +!  ['] do-turn CATCH
      DUP exc-wait <> IF  THROW  ELSE  DROP  THEN
    AGAIN ;

: redraw-game
    gotudgs? IF  defudgs  THEN
    buffershow  drawn? IF  room roompic  THEN ; 

: gac-game
    ['] redraw-game IS (redraw)
    TRUE TO ingame?
    BEGIN
      ['] play-gac CATCH
      DUP exc-exit <> IF  THROW  ELSE  DROP  THEN
      gaclf
      3 mtest 0=
      IF  249 .msg 0 cget prin 250 .msg turn-a @ prin 255 .msg gaclf  THEN
      243 .msg gacflush KEY DROP 
    AGAIN ;

CREATE splash 2048 CHARS ALLOT

: titlescrn
    PAGE
    0 2 AT-XY [CHAR] C ECLR
    [CHAR] B ESET [CHAR] C EALIGN
    ." WhatNow? v1.12" CR
    ." by Garry Lancaster, 12th August 2001" CR CR CR
    ." << No adventure loaded >>" CR
    [CHAR] B ECLR [CHAR] N EALIGN
    pics? IF  splash zxscreen  THEN ;

: goodbye
    FREEALL BYE ;

: errchk ( flag -- )
    DUP TO trap?
    IF 	['] (bal?) IS balanced?
    ELSE  ['] NOOP IS balanced?
    THEN ;

: whatnow
    6 OS_ESC DROP  0 RAND  gacpool
    maxfar 0 ALLOCATE
    ROT obj-table <> OR SWAP farhi <> OR
    IF  S" No Room" errpopup goodbye  THEN
    gac-data gac-data gacsize + HOLE 2!
    TRUE TO pics?  TRUE TO pause?  FALSE TO atprompt?  FALSE TO dialog?
    TRUE errchk
    BEGIN
      FALSE TO ingame?
      pics? IF  pics-on  ELSE  pics-off  THEN
      titlescrn
      0 0 *NAME
      ['] titlescrn IS (redraw)
      ['] KEY CATCH
      BEGIN
        CASE  0 OF  DROP ['] KEY CATCH FALSE  ENDOF
              exc-close OF  gac-data gac-data gacsize + HOLE 2!
                            TRUE
                        ENDOF
	      exc-open OF  ['] gac-game CATCH FALSE  ENDOF
          DUP TO errornum !error!
          TRUE SWAP
        ENDCASE
      UNTIL
    AGAIN ;

\ Command keys

:NONAME  FALSE errchk ;                      \ 140
:NONAME  TRUE errchk ;                       \ 139
:NONAME  ingame? 0= IF  extract  THEN ;      \ 138
:NONAME  ingame? 0= IF  load-adv  THEN ;     \ 137
:NONAME  ingame? IF  savegame  THEN ;        \ 136
:NONAME  ingame? IF  loadgame  THEN ;        \ 135
:NONAME  FALSE TO pause? ;                   \ 134
:NONAME  TRUE TO pause? ;                    \ 133
:NONAME  ingame? IF  exc-close THROW  THEN ; \ 132
:NONAME  pics-off redraw ;                   \ 131
:NONAME  pics-on redraw ;                    \ 130
:NONAME  ingame? IF  FALSE TO atprompt?
                     exc-exit THROW  THEN ;  \ 129
' goodbye                                    \ 128

CREATE comkeytab , , , , , , , , , , , , ,

: comkeys ( event -- )
    dialog? 
    IF  DROP 7 EMIT
    ELSE  256 - DUP 127 U> OVER 141 U< AND
          IF  128 - 2* comkeytab + @ EXECUTE
          ELSE  DROP  THEN
    THEN ;

' escack  IS (RC_ESC)
' redraw  IS (RC_DRAW)
' whatnow IS (COLD)
' comkeys IS (ACC_EVT)
' comkeys IS (KEY)
' goodbye IS (RC_QUIT)

RAM NS
