\ wn-process
CR .( WhatNow? - GAC process tables)

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

