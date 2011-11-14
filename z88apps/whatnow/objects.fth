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

