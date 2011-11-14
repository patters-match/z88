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

\ wn-z88
\ WhatNow? for Z88

CR .( Loading WhatNow?...)

ROM2 NS
S" zxscreen.fth" INCLUDED
S" constants.fth" INCLUDED
RAM
S" data.fth" INCLUDED
ROM2
S" data-z88.fth" INCLUDED
RAM
CR .( Space left in RAM region: ) 32512 HERE - .
ROM2
S" errors.fth" INCLUDED
S" dialogs.fth" INCLUDED
S" database.fth" INCLUDED
S" markers.fth" INCLUDED
S" output.fth" INCLUDED
S" messages.fth" INCLUDED
S" objects.fth" INCLUDED
S" pictures.fth" INCLUDED
S" rooms.fth" INCLUDED
S" files.fth" INCLUDED
S" actions.fth" INCLUDED
S" process.fth" INCLUDED
S" parser.fth" INCLUDED
S" game.fth" INCLUDED
S" appl-z88.fth" INCLUDED
RAM NS
