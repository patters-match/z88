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

