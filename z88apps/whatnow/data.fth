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
