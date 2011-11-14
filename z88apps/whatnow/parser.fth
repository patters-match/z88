\ wn-parser
CR .( WhatNow? - Parser)

: word? ( c-addr u addr -- c-addr u false | n true )
  { BEGIN
      COUNT ?DUP
    WHILE
      >R DUP @ DUP 1+ farhi ROT farhi } C@L
      { >R PAD >FAR R@ } CMOVEL {
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
