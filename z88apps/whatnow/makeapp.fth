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

\ Makefile for WhatNow?

S" wn-z88.fth" INCLUDED
S" whatnow.scr" R/O OPEN-FILE THROW
DUP splash 2048 ROT READ-FILE THROW DROP
CLOSE-FILE THROW

CR .( Appgen...)
S" :*//appgen.fth" INCLUDED
S" whatnow.dor" INCLUDED

S" whatnow-std" STANDALONE
S" whatnow-cli" CLIENT

CR .( WhatNow? successfully generated)
