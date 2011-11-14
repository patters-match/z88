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

\ wn-appl-z88
CR .( WhatNow? Application)

CREATE splash 2048 CHARS ALLOT

: titlescrn
    PAGE
    0 2 AT-XY [CHAR] C ECLR
    [CHAR] B ESET [CHAR] C EALIGN
    ." WhatNow? v1.12" CR
    ." by Garry Lancaster, 12th August 2001" CR CR CR
    ." << No adventure loaded >>" CR
    [CHAR] B ECLR [CHAR] N EALIGN
    pics? IF  splash zxscreen  THEN ;

: goodbye
    FREEALL BYE ;

: errchk ( flag -- )
    DUP TO trap?
    IF 	['] (bal?) IS balanced?
    ELSE  ['] NOOP IS balanced?
    THEN ;

: whatnow
    6 OS_ESC DROP  0 RAND  gacpool
    maxfar 0 ALLOCATE
    ROT obj-table <> OR SWAP farhi <> OR
    IF  S" No Room" errpopup goodbye  THEN
    gac-data gac-data gacsize + HOLE 2!
    TRUE TO pics?  TRUE TO pause?  FALSE TO atprompt?  FALSE TO dialog?
    TRUE errchk
    BEGIN
      FALSE TO ingame?
      pics? IF  pics-on  ELSE  pics-off  THEN
      titlescrn
      0 0 *NAME
      ['] titlescrn IS (redraw)
      ['] KEY CATCH
      BEGIN
        CASE  0 OF  DROP ['] KEY CATCH FALSE  ENDOF
              exc-close OF  gac-data gac-data gacsize + HOLE 2!
                            TRUE
                        ENDOF
	      exc-open OF  ['] gac-game CATCH FALSE  ENDOF
          DUP TO errornum !error!
          TRUE SWAP
        ENDCASE
      UNTIL
    AGAIN ;

\ Command keys

:NONAME  FALSE errchk ;                      \ 140
:NONAME  TRUE errchk ;                       \ 139
:NONAME  ingame? 0= IF  extract  THEN ;      \ 138
:NONAME  ingame? 0= IF  load-adv  THEN ;     \ 137
:NONAME  ingame? IF  savegame  THEN ;        \ 136
:NONAME  ingame? IF  loadgame  THEN ;        \ 135
:NONAME  FALSE TO pause? ;                   \ 134
:NONAME  TRUE TO pause? ;                    \ 133
:NONAME  ingame? IF  exc-close THROW  THEN ; \ 132
:NONAME  pics-off redraw ;                   \ 131
:NONAME  pics-on redraw ;                    \ 130
:NONAME  ingame? IF  FALSE TO atprompt?
                     exc-exit THROW  THEN ;  \ 129
' goodbye                                    \ 128

CREATE comkeytab , , , , , , , , , , , , ,

: comkeys ( event -- )
    dialog? 
    IF  DROP 7 EMIT
    ELSE  256 - DUP 127 U> OVER 141 U< AND
          IF  128 - 2* comkeytab + @ EXECUTE
          ELSE  DROP  THEN
    THEN ;

' escack  IS (RC_ESC)
' redraw  IS (RC_DRAW)
' whatnow IS (COLD)
' comkeys IS (ACC_EVT)
' comkeys IS (KEY)
' goodbye IS (RC_QUIT)
