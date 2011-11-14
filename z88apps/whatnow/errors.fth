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


