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

