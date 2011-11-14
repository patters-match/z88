\ wn-objects
CR .( WhatNow? - GAC Objects)

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

