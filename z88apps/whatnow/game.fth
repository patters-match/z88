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

\ wn-game
CR .( WhatNow? - GAC game player)

: initialise
    0 TO lastnoun
    TRUE TO noinput?
    FALSE TO drawn?
    markers 32 ERASE
    counters 128 ERASE
    null-input
    1 mset
    250 stre C!
    256 0 DO  obj-table I CELLS + farhi @L
              ?DUP IF  DUP CELL+ CHAR+ @ SWAP !  THEN
          LOOP
    linelen empty-output [CHAR] C ESET
    gac-start goto ;

: more-input
    gaclf
    noinput?
    IF  TRUE TO atprompt?
	prompt
        0 nopause !
        REFILL DROP 0 >IN !
        SOURCE inp>out gaclf
        SOURCE >LOWER
        FALSE TO atprompt?
    THEN
    TRUE TO noinput? ;

: getcommand
    more-input 
    ['] parse-input CATCH 
    DUP exc-endinp <> IF  THROW  ELSE  DROP  THEN
    SOURCE NIP >IN @ U> 0= TO noinput?
    replace-it ;

: do-turn
    getcommand
    FALSE TO valid?
    verb conn ?DUP IF  goto exc-wait THROW  THEN
    room-l ?DUP IF  process  THEN
    gac-low process
    SOURCE NIP 0= valid? OR IF  EXIT  THEN
    verb 0= IF  242 .msg  ELSE  241 .msg  THEN ;

: play-gac
    initialise
    BEGIN
      gac-high ['] process CATCH ?DUP
      IF  NIP DUP exc-wait <> IF  THROW  ELSE  DROP  THEN  THEN
      1 turn-a +!  ['] do-turn CATCH
      DUP exc-wait <> IF  THROW  ELSE  DROP  THEN
    AGAIN ;

: redraw-game
    gotudgs? IF  defudgs  THEN
    buffershow  drawn? IF  room roompic  THEN ; 

: gac-game
    ['] redraw-game IS (redraw)
    TRUE TO ingame?
    BEGIN
      ['] play-gac CATCH
      DUP exc-exit <> IF  THROW  ELSE  DROP  THEN
      gaclf
      3 mtest 0=
      IF  249 .msg 0 cget prin 250 .msg turn-a @ prin 255 .msg gaclf  THEN
      243 .msg gacflush KEY DROP 
    AGAIN ;

