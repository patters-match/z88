\ wn-output
CR .( WhatNow? - Output buffering)

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


