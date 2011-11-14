\ wn-errors
CR .( WhatNow? - Game error generation)

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


