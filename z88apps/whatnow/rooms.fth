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

