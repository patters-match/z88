\ wn-database
CR .( WhatNow? - GAC database handling)
  
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

: word-ptrs
    #words @ #ptrs 1- + #ptrs / TO ptrwidth
    vocalloc
    #words @ 0 ?DO  I ptrwidth MOD 0=
                    IF  DUP ptrs I ptrwidth / CELLS + !  THEN
                    DUP farhi C@L + 1+
                LOOP
    DROP ;

: >word ( wordno -- L-addr n )
    DUP DUP 1+ #words @ U> ferror" Bad word number: "
    ptrwidth /MOD CELLS ptrs + @
    SWAP 0 ?DO  DUP farhi C@L 1+ +  LOOP
    DUP 1+ SWAP farhi C@L ;

: >location ( locno -- c-addr )
    >R gac-locations
    BEGIN
      DUP @ R@ OVER 0= ferror" Location not found: "
      R@ = IF  R> DROP 3 CELLS + EXIT  THEN
      CELL+ DUP @ CHARS + CELL+
    AGAIN ;

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

: convert-gac
    S" Validating..." flashy
    gac-data @ 41723 U> TO zx?
    convert-pointers
    gac-vocab gac-data gacsize + U> ferror" Game too big"
    convert-words word-ptrs convert-objects
    gac-verbs gac-nouns convert-vocab
    gac-nouns gac-adverbs convert-vocab
    gac-adverbs gac-objects convert-vocab ;

