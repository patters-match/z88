\ wn-rooms
CR .( WhatNow? - GAC locations)

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

