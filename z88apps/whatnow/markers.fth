\ wn-markers
CR .( WhatNow? - Markers and counters)

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

