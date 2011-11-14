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

\ wn-data
CR .( WhatNow? - Data)

0  VALUE verb
0  VALUE adve
0  VALUE no1
0  VALUE no2
0  VALUE lastnoun
0  VALUE newnoun
0  VALUE noinput?
0  VALUE room
0  VALUE room-a
0  VALUE room-l
0  VALUE stkbal
0  VALUE valid?
0  VALUE ptrwidth
0  VALUE linelen
0  VALUE strdone?
0  VALUE ingame?
0  VALUE atprompt?
0  VALUE dialog?
0  VALUE pause?
0  VALUE pics?
0  VALUE drawn?
0  VALUE showing
0  VALUE drawaddr
0  VALUE ink
0  VALUE hmin
0  VALUE gotudgs?
0  VALUE errordata
0  VALUE errortype
0  VALUE errornum
0  VALUE trap?
0  VALUE snapid
0  VALUE ext#
0  VALUE zx?

DEFER (redraw)
DEFER xferdata
DEFER balanced?
DEFER dopic

CREATE gac-data gacsize CELL+ ALLOT
CREATE oneline maxlen 1+ CHARS ALLOT
CREATE udgbuf maxudgs ALLOT
CREATE counters 128 ALLOT
CREATE markers 32 ALLOT
CREATE ptrs #ptrs CELLS ALLOT

VARIABLE bufline
VARIABLE buftop
VARIABLE bufshown
VARIABLE bufadd
VARIABLE bufpos
VARIABLE linest
VARIABLE stre
VARIABLE #words
VARIABLE procptr
VARIABLE nopause
VARIABLE wtitle
