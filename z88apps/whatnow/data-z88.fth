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

\ wn-data-z88
CR .( WhatNow? - Z88-specific data)

TASK: drawer

32768 0 POOL gacpool

\ We make an allocation of 1421 bytes first, so we know fixed far addresses
\ Because of problems with FREEing we're currently allocating a fixed amount
\ at startup, and only FREEALLing at application exit...

1421 CONSTANT farsize
1    CONSTANT farhi
2    CONSTANT obj-table  \ pointers to objects (512 bytes)
514  CONSTANT linebufs   \ 8x91 char buffer (728 bytes)
1242 CONSTANT udgdefs    \ UDGs (1+9*maxudgs = 181 bytes)
1423 CONSTANT vocalloc   \ vocabulary (space required varies)

26624 CONSTANT maxfar
