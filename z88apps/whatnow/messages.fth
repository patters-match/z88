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
