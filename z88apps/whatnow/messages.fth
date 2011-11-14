\ wn-messages
CR .( WhatNow? - GAC message generation)

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
