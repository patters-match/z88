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

\ wn-actions
CR .( WhatNow? - GAC actions)

' balanced?                                       \ END ($3f)
:NONAME  IF  balanced? TRUE TO valid? EXIT  THEN  \ IF ($3e)
   balanced? procptr @
   BEGIN  DUP C@  DUP 63 = OVER 0= OR
     IF  DROP procptr ! EXIT  THEN
     128 AND IF  CHAR+  THEN  CHAR+
   AGAIN ;
' gaclf                                           \   LF ($3d)
:NONAME  stre C! ;                                \ STRE ($3c)
' with                                            \ WITH ($3b)
:NONAME  >object: CELL+ C@ ;                      \ WEIG ($3a)
' conn                                            \ CONN ($39)
' pics-off                                        \ TEXT ($38)
' pics-on                                         \ PICT ($37)
:NONAME  -1 listobjs 0=                           \ LIST ($36)
   IF  S" nothing" 1 gactype  THEN ;
' verb                                            \ VBNO ($35)
' no2                                             \  NO2 ($34)
' no1                                             \  NO1 ($33)
' goto                                            \ GOTO ($32)
:NONAME  adve = 1 AND ;                           \ ADVE ($31)
:NONAME  verb = 1 AND ;                           \ VERB ($30)
:NONAME  DUP no1 = SWAP no2 = OR 1 AND ;          \ NOUN ($2f)
' room                                            \ ROOM ($2e)
:NONAME  exc-exit THROW ;                         \ EXIT ($2d)
:NONAME  244 .msg gacflush Y/N                    \ QUIT ($2c)
   IF  exc-exit THROW  THEN ;
:NONAME  exc-wait THROW ;                         \ WAIT ($2b)
:NONAME  254 .msg gaclf exc-wait THROW ;          \ OKAY ($2a)
:NONAME  serror" OP29: Bad action" ;              \ OP29 ($29)
:NONAME  serror" OP28: Bad action" ;              \ OP28 ($28)
:NONAME  SWAP >object? IF @ = 1 AND ELSE NIP THEN ; \ IN ($27)
:NONAME  >object?                                 \ FIND ($26)
   0= OVER @ 0= OR IF  252 .msg exc-wait THROW  THEN
   @ DUP with = IF  245 .msg exc-wait THROW  THEN
   goto ;
:NONAME  >object?  IF  DUP @  ELSE  0  THEN       \ BRIN ($25)
   0= IF  252 .msg exc-wait THROW  THEN
   DUP @ with = IF  245 .msg exc-wait THROW  THEN 
   room SWAP ! ;
:NONAME  room = 1 AND ;                           \   AT ($24)
:NONAME  turn-a @ ;                               \ TURN ($23)
' -                                               \    - ($22)
' +                                               \    + ($21)
' carr?                                           \ CARR ($20)
:NONAME  DUP carr? SWAP here? OR ;                \ AVAI ($1f)
' here?                                           \ HERE ($1e)
' loadgame                                        \ LOAD ($1d)
' savegame                                        \ SAVE ($1c)
:NONAME  = 1 AND ;                                \    = ($1b)
:NONAME  > 1 AND ;                                \    > ($1a)
:NONAME  < 1 AND ;                                \    < ($19)
' RND                                             \ RAND ($18)
' prin                                            \ PRIN ($17)
' .msg                                            \ MESS ($16)
:NONAME  room desc ;                              \ LOOK ($15)
' desc                                            \ DESC ($14)
:NONAME  cget = 1 AND ;                           \ EQU? ($13)
' cincr                                           \ INCR ($12)
' cdecr                                           \ DECR ($11)
' cget                                            \  CTR ($10)
' cset                                            \ CSET ($0f)
:NONAME  mtest 1 XOR ;                            \ RES? ($0e)
' mtest                                           \ SET? ($0d)
' mreset                                          \ RESE ($0c)
' mset                                            \  SET ($0b)
' .obj                                            \  OBJ ($0a)
:NONAME  SWAP >object: ! ;                        \   TO ($09)
:NONAME  >object: DUP @ ROT                       \ SWAP ($08)
   >object: DUP @ ROT ROT ! SWAP ! ;
:NONAME  DUP carr? 0=                             \ DROP ($07)
   IF  246 .msg exc-wait THROW  THEN >object room SWAP ! ;
:NONAME                                           \ GET ($06)
   DUP carr? IF  245 .msg exc-wait THROW  THEN
   DUP here? 0= IF  247 .msg exc-wait THROW  THEN
   held OVER >object CELL+ C@ + stre C@ < 0=
   IF  248 .msg exc-wait THROW  THEN
   >object with SWAP ! ;
:NONAME  gacflush  0 nopause !                    \ HOLD ($05)
   0 ?DO  20 MS KEY? IF  KEY DROP LEAVE  THEN  LOOP ;
' XOR                                             \  XOR ($04)
:NONAME  0= 1 AND ;                               \  NOT ($03)
' OR                                              \   OR ($02)
' AND                                             \  AND ($01)
:NONAME  balanced? exc-end THROW ;                \  end ($00)

CREATE gac-actions , , , , , , , , , , , , , , , ,
                   , , , , , , , , , , , , , , , ,
                   , , , , , , , , , , , , , , , ,
                   , , , , , , , , , , , , , , , ,
