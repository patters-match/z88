\ *************************************************************************************
\
\ Puzzle Of The Pyramid (c) Garry Lancaster, 1998-1999
\
\ Puzzle Of The Pyramid is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ Puzzle Of The Pyramid is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with Puzzle
\ Of The Pyramid; see the file COPYING. If not, write to the
\ Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\
\ *************************************************************************************

\ Puzzle Of The Pyramid, an example Forth source file
\ by Garry Lancaster 1988 (MMS-Forth version), 1999 (ANS Forth version)

\ The game is started with GAME

\ This is an ANS Forth program requiring:
\ 1.  .( :NONAME FALSE TRUE NIP PARSE REFILL TO VALUE from the core
\     extensions word set
\ 2.  the search-order word set
\ 3.  ONLY ALSO FORTH from the search-order extensions word set
\ 4.  CMOVE from the string wordset
\ 5.  PAGE from the facility wordset

\ Text is formatted to fit within a 64 character-wide display.

\ If your Forth system includes the non-standard word VOCABULARY, you
\ may comment out the definition included here.


CR .( Loading PUZZLE OF THE PYRAMID...)


\ Vocabularies

: VOCABULARY ( "name" -- )
    WORDLIST CREATE ,
    DOES>  @ >R GET-ORDER NIP R> SWAP SET-ORDER ;

VOCABULARY DIRECTIONS
VOCABULARY VERBS
VOCABULARY NOUNS
ONLY FORTH ALSO VERBS ALSO NOUNS ALSO DIRECTIONS ALSO

FORTH DEFINITIONS


\ Constants

9   CONSTANT #locations    \ 0=no exit, so locations numbered 1-9
8   CONSTANT #objects      \ 255=held, objects numbered 0-7
200 CONSTANT max-weight
255 CONSTANT possessed


\ Variables

VARIABLE held
VARIABLE place
VARIABLE game-over


\ Tables

CREATE travel-table #locations 8 CHARS * ALLOT
CREATE desc-table   #locations   CELLS   ALLOT
CREATE obj-weights  #objects     CHARS   ALLOT
CREATE obj-inits    #objects     CHARS   ALLOT
CREATE obj-locs     #objects     CHARS   ALLOT
CREATE obj-descs    #objects     CELLS   ALLOT


\ Useful general words

: STRING,  ( c-addr n -- )
    DUP C, HERE SWAP DUP CHARS ALLOT CMOVE ;

\ Defining words for objects

0 VALUE objctr

: OBJECT  ( loc wt "name" -- )
    CREATE
      objctr C,
      obj-weights objctr CHARS + C!
      obj-inits   objctr CHARS + C!
      HERE obj-descs objctr CELLS + !
      [CHAR] " PARSE STRING,
      objctr 1+ TO objctr
    DOES> ( -- object )
          C@ ;


\ Nouns/objects

NOUNS DEFINITIONS

9 0   OBJECT DOOR a very solid-looking thick door"
8 0   OBJECT WATER a pool of refreshing water"
6 60  OBJECT DRUM a battered old drum"
5 60  OBJECT BUGLE a slightly rusted bugle"
5 60  OBJECT GUN a small gun"
4 120 OBJECT BRANCH a long, strong branch"
3 50  OBJECT KEY a bronze key"
1 120 OBJECT ROPE a thick rope"

FORTH DEFINITIONS


\ Basic checking words

: place?  ( location -- flag )
    place @ = ;

: got?  ( object -- flag )
    CHARS obj-locs + C@ possessed = ;

: here?  ( object -- flag )
    CHARS obj-locs + C@ place? ;

: weight? ( object -- n )
    CHARS obj-weights + C@ ;

: exit? ( direction -- location | 0 )
    place @ 1- 8 CHARS * travel-table +
    SWAP CHARS + C@ ;  

: findword ( "ccc<space>" -- xt true | c-addr false )
    BL WORD FIND FORTH ;

: direction? ( "ccc<space>" -- xt true | c-addr false )
    ONLY DIRECTIONS findword ;

: verb? ( "ccc<space>" -- xt true | c-addr false )
    ONLY VERBS ALSO DIRECTIONS findword ;

: noun? ( "ccc<space>" -- xt true | c-addr false )
    ONLY NOUNS findword ;

: word? ( noun "ccc<space>" -- flag )
    noun? IF  EXECUTE =  ELSE  2DROP FALSE  THEN ;

: anynoun? ( c-addr u "ccc<space>" -- n true | false )
    noun? IF  EXECUTE TRUE 2SWAP 2DROP
          ELSE  ROT ROT TYPE COUNT TYPE FALSE
          THEN ;


\ Actions

: .object  ( object -- )
    CELLS obj-descs + @ COUNT TYPE ;

: .objects ( location -- n )
    0 
    #objects 0 DO  OVER I CHARS obj-locs + C@ =
                   IF  CR ."  - " I .object 1+  THEN
               LOOP
    NIP ;

: .location ( location -- )
    1- CELLS desc-table + @
    BEGIN  COUNT ?DUP  WHILE  2DUP TYPE CR CHARS +  REPEAT DROP ;

: describe ( -- )
    place @ DUP .location
    ." I can see " .objects 0= IF  ." nothing else of interest."  THEN ;

: travel ( direction -- )
    exit? ?DUP IF  place ! describe
               ELSE  ." I can't go that way"
               THEN ;

: put ( object location -- )
    SWAP CHARS obj-locs + C! ;

: okay ( -- )
    ." Okay..." ;


\ Verbs

DIRECTIONS DEFINITIONS

: NORTH      0 travel ;      : N   0 travel ;
: SOUTH      1 travel ;      : S   1 travel ;
: EAST       2 travel ;      : E   2 travel ;
: WEST       3 travel ;      : W   3 travel ;
: NORTHEAST  4 travel ;      : NE  4 travel ;
: NORTHWEST  5 travel ;      : NW  5 travel ;
: SOUTHEAST  6 travel ;      : SE  6 travel ;
: SOUTHWEST  7 travel ;      : SW  7 travel ;

VERBS DEFINITIONS

: REDESCRIBE  describe ;
: R           describe ;
: LOOK        describe ;
: L           describe ;

: GO
    direction? IF  EXECUTE  ELSE  ." Go where?" DROP  THEN ; 

: INVENTORY
    ." I have with me: " possessed .objects
    0= IF  ." nothing at all."  THEN ;              : I  INVENTORY ;

: GET
    S" I can't see any " anynoun?
    IF  DUP here?
        IF  DUP weight? held @ OVER + max-weight >
            IF  ." That's too heavy to carry at the moment." 2DROP
            ELSE  held +! possessed put okay
            THEN
        ELSE ." I can't see " .object
        THEN
    THEN ;                                          : TAKE  GET ;

: DROP
    S" I haven't got any " anynoun?
    IF  DUP got?
        IF  DUP weight? NEGATE held +! place @ put okay
        ELSE  ." I don't have " .object
        THEN
    THEN ;                                          : PUT  DROP ;

: HELP
    ." You're supposed to be helping me!" ;         : HINT  HELP ;

: EXAMINE
    ." Why don't you pay more attention!" ;

: BREAK
    ." Don't be such a vandal!" ;                   : SMASH  BREAK ;

: THROW  BREAK ;

: USE
    ." Please be more specific." ;                  : PLAY  USE ;

: SWIM
    8 place? IF  ." There's not that much water!"
             ELSE  ." What in?"
             THEN ;                                 : DIVE  SWIM ;

: TIE
    ROPE word?
    IF  ROPE got?
        IF  ." The rope is so stiff I can't bend it all..."
        ELSE ." I don't have a rope."
        THEN
    ELSE  ." I can't tie that!"
    THEN ;

: DRINK
    WATER word?
    IF  8 place?
        IF  ." Ok...but it tastes revolting!"
        ELSE  ." I don't see any water here."
        THEN
    ELSE  ." I can't drink that!"
    THEN ;

: UNLOCK
    DOOR word?
    IF  9 place?
        IF  KEY got?
            IF  ." The key doesn't fit the lock..."
            ELSE  ." I haven't got a key."
            THEN
        ELSE  ." I don't see any door here."
        THEN
    ELSE  ." I can't unlock that!"
    THEN ;

: BEAT
    DRUM word?
    IF  DRUM got?
        IF  ." You make a terrible din."
        ELSE  ." I haven't got a drum."
        THEN
    ELSE  ." I can't beat that!"
    THEN ;                                          : HIT  BEAT ;

: BLOW
    BUGLE word?
    IF  BUGLE got?
        IF  9 place?
            IF    ." You sound the bugle and the door swings open, revealing"
               CR ." the fabulous treasure of Toot'N'Come-In."
               CR ." Well done! You have completed this adventure." CR
               TRUE game-over !
            ELSE  ." You sound the bugle"
                  5 place?  IF ."  to the distress of the natives"  THEN
                  ." ."
            THEN
        ELSE ." I haven't got a bugle."
        THEN
    ELSE  ." I can't blow that!"
    THEN ;                                          : SOUND  BLOW ; 

: QUIT
    TRUE game-over ! ;


\ Checks

FORTH DEFINITIONS

VARIABLE quicksand
VARIABLE snakes
VARIABLE forest

CREATE checklist  0 ,     \ Linked list of checks

: addcheck ( xt -- )
    HERE SWAP ,
    checklist @ ,
    checklist ! ;

:NONAME
   GUN got?
   IF  CR ." As you take the gun, a suspicious native hurls a spear into" CR
       ." your heart..." CR
       TRUE game-over !
   THEN ; addcheck

:NONAME
   3 place?
   IF  1 quicksand +!  quicksand @ 3 =
       IF  CR ." The quicksand sucks you down, and you suffocate." CR
           TRUE game-over !
       THEN
   ELSE  0 quicksand !
   THEN ; addcheck

:NONAME
   6 place?
   IF  1 snakes +!  snakes @ 3 =
       IF  CR ." You have been bitten to death by the snakes!" CR
           TRUE game-over !
       THEN
   ELSE  0 snakes !
   THEN ; addcheck

:NONAME
   2 place?
   IF  1 forest +!  forest @ 2 =
       IF  CR ." Suddenly a pack of coyotes bursts through the trees..." CR
           ." There is no escape for you..." CR
           TRUE game-over !
       THEN
   ELSE  0 forest !
   THEN ; addcheck

: make-checks
    checklist
    BEGIN  @ ?DUP
    WHILE  DUP @ EXECUTE CELL+
    REPEAT ;


\ Parser and main loop

ONLY FORTH ALSO
FORTH DEFINITIONS

: initialise
    obj-inits obj-locs #objects CHARS CMOVE
    0 held !
    1 place !
    FALSE game-over ! ;

: parser
    BEGIN
      CR ." What now? " REFILL DROP 0 >IN ! CR
      verb? IF  EXECUTE  
            ELSE  ." I don't know how to " COUNT TYPE
            THEN
      make-checks game-over @
    UNTIL ;

: Y/N ( -- flag )
    BEGIN
      KEY
      DUP  [CHAR] Y <>     OVER [CHAR] y <> AND
      OVER [CHAR] N <> AND OVER [CHAR] n <> AND
    WHILE
      DROP
    REPEAT
    DUP [CHAR] Y = SWAP [CHAR] y = OR ;
         
: GAME
    BEGIN
      initialise 
      PAGE describe
      parser
      ." Another go (Y/N)? " Y/N 0=
    UNTIL ;


\ Defining words for locations

0 VALUE locctr

: MORELOC>  ( "ccc<~>" -- )
    [CHAR] ~ PARSE STRING, ;

: ENDLOC>  ( -- )
    0 C, ;

: LOCATION  ( n s e w ne nw se sw "ccc<~>" -- )
    0 7 DO  travel-table locctr 8 CHARS * +
            I CHARS + C!
    -1 +LOOP
    HERE desc-table locctr CELLS + !
    locctr 1+ TO locctr
    MORELOC> ;


\ The location definitions

0 0 0 2 0 4 0 0 
LOCATION You have arrived at base camp and have rested to build up your~
MORELOC> strength. Paths lead west and northwest.~
ENDLOC>

0 0 1 0 0 0 0 0
LOCATION You are in a dense forest area. The only exit is east along a~
MORELOC> narrow path. From somewhere nearby you can hear the cry of~
MORELOC> hungry coyotes...~
ENDLOC>

0 0 0 0 4 5 0 0
LOCATION This part of the forest is full of quicksand, so be careful not~
MORELOC> to stay too long... Exits are northwest and northeast.~
ENDLOC>

0 0 0 0 0 0 1 3
LOCATION You are in a clearing, where the natives have been cutting down~
MORELOC> trees to build their huts. Paths lead southeast and southwest.~
ENDLOC>

8 0 0 0 6 0 3 0
LOCATION This is a native village settlement, with paths leading off in~
MORELOC> three directions: north, southeast and northeast. You can sense
MORELOC> distrust of you amongst the inhabitants.~
ENDLOC>

0 0 0 7 0 0 0 5
LOCATION You are in a pit filled with venomous snakes! Escape routes~
MORELOC> are west and southwest.~
ENDLOC>

9 0 6 0 0 0 0 0
LOCATION You are on a high mountain pass. To the north is a huge pyramid,~
MORELOC> whilst to the east is a dark pit.~
ENDLOC>

0 5 0 0 0 0 0 0
LOCATION You have reached an oasis. There are palm trees and water here,~
MORELOC> but only one exit, to the south.~
ENDLOC>

0 7 0 0 0 0 0 0
LOCATION You are at the entrance to a magnificent pyramid. Unfortunately,~
MORELOC> the thick door appears to be locked... A steep path rises to the~
MORELOC> south.~
ENDLOC>
