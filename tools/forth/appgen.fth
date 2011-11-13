\ *************************************************************************************
\
\ Z88 Forth AppGen Tools (c) Garry Lancaster, 1999-2011
\
\ Z88 Forth AppGen Tools is free software; you can redistribute it and/or modify it under
\ the terms of the GNU General Public License as published by the Free Software Foundation;
\ either version 2, or (at your option) any later version.
\ Z88 Forth AppGen Tools is distributed in the hope that it will be useful, but WITHOUT
\ ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
\ PARTICULAR PURPOSE.
\ See the GNU General Public License for more details.
\ You should have received a copy of the GNU General Public License along with Z88
\ Forth AppGen Tools; see the file COPYING. If not, write to the
\ Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
\
\
\ *************************************************************************************

CR .( Loading Application Generation Tools...)
\ DOR and application creation tools

\ Save the current uservars

S" " DROP
U0 OVER #INIT CMOVE
RAM NS HEX 2500 DP ! DECIMAL
CREATE UVARS #INIT ALLOT
UVARS #INIT CMOVE

\ Links to first/last list entries

VARIABLE COMMAND0  VARIABLE COMMANDN
VARIABLE TOPIC0    VARIABLE TOPICN
VARIABLE HELP0     VARIABLE HELPN
VARIABLE LASTITEM

VARIABLE DORDEF
VARIABLE COLUMN-ENTRY

0 VALUE TOK-A
0 VALUE TOK-U
0 VALUE RECURSIVE

49152 VALUE DOR-TARGET
63    VALUE DOR-BANK
0     VALUE DOR-COMPILED
0     VALUE DOR-SIZE
0     VALUE DOR-START
0     VALUE DOR-TOKENS
0     VALUE CLUINIT

\ Calculate RAM size in pages from bytes

: BYTES ( u1 -- u2 )
    255 + 256 / ;

: BADRAM ( u1 -- u2 )
    DUP IF  32 MAX 160 MIN  THEN ;

\ Modifiers for command/topic attribute bytes

: >ATTR  ( bit addr -- )
    @ 2 CELLS + DUP C@ ROT OR SWAP C! ;

: AN  1 TOPICN >ATTR ;
: INFO  2 TOPICN >ATTR ;
: SAFE  8 COMMANDN >ATTR ;
: HIDE  4 COMMANDN >ATTR ;
: NEW-COLUMN  1 COMMANDN >ATTR  1 COLUMN-ENTRY ! ;

\ Tokenisation

: REPLACE ( a1 u1 a2 u2 c -- a1 u3 )
   ROT TUCK C!
   2DUP + 2SWAP - ROT >R SWAP R@ CHAR+ 2OVER R> ROT - - CMOVE CHAR+ ;
   
: >TOKEN ( c -- a u )
   DOR-TOKENS CHAR+ COUNT ROT 127 - TUCK U< ABORT" Invalid token"
   BEGIN  1- ?DUP  WHILE  SWAP CELL+ SWAP  REPEAT
   DUP @ DOR-TOKENS + SWAP CELL+ @ DOR-TOKENS + OVER - ;

: DOTOKEN ( a u c -- a u' )
   DUP >R >TOKEN TO TOK-U TO TOK-A
   BEGIN  2DUP TOK-A TOK-U SEARCH  WHILE  DROP TOK-U R@ REPLACE  REPEAT
   2DROP R> DROP ;

: TOKENIZE ( a u 0|1 -- a u' )
   DOR-TOKENS ?DUP IF  + C@ 128 + 128 ?DO  I DOTOKEN  LOOP  ELSE  DROP  THEN ;

\ Token table creation

: TOKENS
   HERE TO DOR-TOKENS FALSE TO RECURSIVE 0 C, 0 C, ;

: END-TOKENS
   DOR-TOKENS 0= ABORT" No token table"
   1 CELLS ALLOT HERE DOR-TOKENS - DOR-TOKENS CELL+ DOR-TOKENS CHAR+ C@ ?DUP
   IF  FOR  DUP @ CELL+ OVER ! CELL+  STEP
       DUP HERE OVER - OVER CELL+ SWAP CMOVE>
   THEN
   RECURSIVE IF  2DUP 1 CELLS - @ TUCK - >R DOR-TOKENS + R@ 0 TOKENIZE NIP
                 R> - CHARS DUP ALLOT ROT + SWAP
             THEN  ! ;

: TOKEN:
   END-TOKENS DOR-TOKENS CHAR+ C@ 1+ DOR-TOKENS CHAR+ C!
   RECURSIVE 0= IF  DOR-TOKENS C@ 1+ DOR-TOKENS C!  THEN ;

: TOKEN-TEXT ( char -- )
   WORD COUNT HERE OVER ALLOT SWAP CMOVE ;

: TOKEN-TEXT[   [CHAR] ] TOKEN-TEXT ;
: TOKEN-TEXT{   [CHAR] } TOKEN-TEXT ;
: TOKEN-CHAR ( char -- )  C, ;
: TOKEN[  TOKEN: TOKEN-TEXT[ ;
: TOKEN{  TOKEN: TOKEN-TEXT{ ;

\ Initial item creation

: STRING! ( c-addr n -- )
    HERE SWAP DUP ALLOT CMOVE ;

: TOK-STRING! ( c-addr n -- )
    TUCK HERE SWAP CMOVE HERE SWAP 1 TOKENIZE ALLOT DROP ;

: 0STRING! ( c-addr n -- )
    STRING! 0 C, ;

: STRING, ( c-addr n -- )
    DUP C, STRING! ;

: LINK-FROM ( addr0 addrn -- )
    DUP @ ?DUP                  \  get last item address
    IF  HERE SWAP !             \  link any last item
    ELSE  OVER HERE SWAP !      \  else set as first item
    THEN
    HERE SWAP !                 \  set new entry as last
    0 , DROP ;                  \  links to nothing

: SETLAST                       \ Set next item as last
    HERE LASTITEM ! ;

: NEW-TOPIC ( c "ccc<char>" --)
    COMMANDN @ ?DUP             \ set last cmd=last in topic
    IF  2 CELLS + CHAR+ 1 SWAP C!  THEN
    SETLAST
    TOPIC0 TOPICN LINK-FROM     \  link in
    0 , 0 C,                    \  no help/attrib
    PARSE STRING,               \  add name
    0 COLUMN-ENTRY ! ;          \  no commands yet

: NEW-COMMAND ( c-addr n char1 char2 "ccc<char2>" -- )
    SETLAST
    >R COMMAND0 COMMANDN LINK-FROM \  link in
    0 , 0 C, 0 C,               \  no help, attrib 0, not last
    C,                          \  command code
    STRING,                     \  keyboard sequence
    R> PARSE STRING,            \  add name
    1 COLUMN-ENTRY +! 
    COLUMN-ENTRY @ 9 = IF  NEW-COLUMN  THEN ;

: NEW-DOR ( letter char "ccc<char>" -- )
    0 TOPICN ! 0 TOPIC0 !       \ initialise linked lists
    0 COMMANDN ! 0 COMMAND0 !
    0 HELPN ! 0 HELP0 !
    SETLAST
    HERE DORDEF !               \ start of DOR definition
    SWAP C,                     \ application letter
    0 C, 0 ,                    \ filler, pointer to help page
    PARSE STRING, ;             \ add name

\ Help text compilation

: START-HELP
    LASTITEM @                  \ test if need to start page
    IF  HERE LASTITEM @ CELL+ ! \ set link from last item
        HELP0 HELPN LINK-FROM   \ link in
        0 ,                     \ no text so far
        0 LASTITEM !            \ signal help page started
    THEN ;

: ADD-HELP ( c-addr n -- )
    START-HELP
    DUP HELPN @ CELL+ +!        \ add length of text to page
    STRING! ;                   \ store at end of page

: HELP-CHAR ( char -- )
    START-HELP
    1 HELPN @ CELL+ +!          \ increment length of text
    C, ;                        \ compile the character

: N/L
    127 HELP-CHAR ;             \ a help-page eol character

\ DOR Compilation

: TARGET@
    HERE DOR-COMPILED - DOR-TARGET + ;

: ,TOKENS ( -- targbank targaddr )
    DOR-TOKENS DUP IF  DOR-BANK SWAP  ELSE  DUP  THEN ;

: ,1HELP ( entryaddr -- )
    CELL+ DUP CELL+ SWAP @ TOK-STRING! 0 C, ; \ move to compiled entry

: ,HELP ( -- targbank targadd )
    TARGET@ >R                  \ get target address
    DORDEF @ CELL+ @ 0= IF  0 C,  THEN \ blank app h.p.
    HELP0 @
    BEGIN  ?DUP
    WHILE  TARGET@ OVER ,1HELP  \ compile the entry
           R@ - OVER @ SWAP ROT ! \ store offset, get next
    REPEAT
    DOR-BANK R> ;               \ leave target bank and addr
           
: ,HELP&ATTR ( helpaddr targaddr -- )
    OVER @ ?DUP
    IF  @ >< DUP 224 AND IF  0 C,  THEN \ add null-term
        , SWAP CELL+ C@ 16 OR   \ compile help, modify attr
    ELSE  SWAP CELL+ C@         \ get attribute
    THEN
    C,                          \ compile attribute
    HERE 1+ OVER -              \ calculate length
    DUP C, SWAP C! ;            \ set at start and end

: ,1COMMAND ( entryaddr -- )
    CELL+ HERE 1 ALLOT          \ reserve space for length
    OVER 2 CELLS +
    DUP C@ C,                   \ command code
    CHAR+ COUNT 2DUP 0STRING!   \ keyboard sequence
    CHARS + COUNT TOK-STRING!   \ command name (null optional)
    ,HELP&ATTR ;                \ finish off entry

: ,COMMANDS ( -- targbank targadd )
    COMMAND0 @ ?DUP
    IF  DOR-BANK TARGET@ ROT    \ get target address and bank
        0 C,                    \ start marker
        BEGIN  ?DUP
        WHILE  DUP ,1COMMAND    \ compile the entry
               DUP 2 CELLS + CHAR+ C@
               IF  1 C,  THEN   \ compile end of topic marker
               @                \ get next entry in list
        REPEAT
        0 C,
    ELSE 0 0                    \ no commands
    THEN ;

: ,1TOPIC ( entryaddr -- )
    CELL+ HERE 1 ALLOT          \ reserve space for length
    OVER CELL+ CHAR+
    COUNT TOK-STRING!           \ topic name
    ,HELP&ATTR ;                \ finish off entry
    
: ,TOPICS ( -- targbank targadd )
    TOPIC0 @ ?DUP
    IF  DOR-BANK TARGET@ ROT    \ get target address and bank
        0 C,                    \ start marker
        BEGIN  ?DUP
        WHILE  DUP ,1TOPIC      \ compile the entry
               @                \ get next entry in list
        REPEAT 
        0 C,
    ELSE 0 0                    \ no topics
    THEN ;

0 VALUE RAM-SIZE                \ default bad-app size
HEX
C004 @                          \ address of CF's DOR
DUP 13 + @ VALUE UNSAFE-SIZE    \ CamelForth unsafe size
DUP 15 + @ VALUE SAFE-SIZE      \ CamelForth safe size
17 + @ VALUE ENTRY              \ CamelForth entry point
DECIMAL
0  VALUE SEG0                   \ segment bindings
63 VALUE SEG1
63 VALUE SEG2
63 VALUE SEG3
34 VALUE APPTYPE                \ bad app, preserve screen
1  VALUE CAPSMODE               \ caps on
HEX FFF8 @ VALUE CARDID DECIMAL

1 VALUE GOOD                    \ application types
2 VALUE BAD
4 VALUE UGLY
8 VALUE POPDOWN
16 VALUE SINGLE
32 VALUE SCREEN

0 VALUE CAPS-OFF
1 VALUE CAPS-ON
3 VALUE CAPS-INV

CREATE DEFAULT-DOR
  0 , 0 C,                      \ link to parent
  0 , 0 C,                      \ link to brother
  0 , 0 C,                      \ link to son
  HEX 83 C, DECIMAL             \ DOR type
  0 C,                          \ DOR length (to be patched)
  CHAR @ C,                     \ Key to info section
  18 C,                         \ Info section length
  0 ,

: ,POINTER ( bank addr | 0 0 -- ) 
    2DUP OR
    IF  , C,                    \  compile non-null pointer
    ELSE  2DROP DOR-START , DOR-BANK C, \ pointer to 3 nulls
    THEN ;
          
: ,DOR ( tokb toka hlpb hlpa cmdb cmda topb topa --  )
    HERE >R
    TARGET@ TO DOR-START        \ save target address
    DEFAULT-DOR 15 STRING!      \ install default DOR start
    DORDEF @ C@ C,              \ application key
    RAM-SIZE BADRAM C, 0 ,      \ bad app size
    UNSAFE-SIZE , SAFE-SIZE ,   \ unsafe/safe ws sizes
    ENTRY ,                     \ entry point
    SEG0 C, SEG1 C, SEG2 C, SEG3 C, \ segment bindings
    APPTYPE C, CAPSMODE C,      \ app type, caps mode
    [CHAR] H C, 12 C,           \ start of help section
    ,POINTER ,POINTER ,POINTER ,POINTER \ tpcs/cmds/hlp/toks
    [CHAR] N C,                 \ start of name section
    DORDEF @ 2 CELLS + COUNT
    DUP 1+ C,                   \ length of name+null
    0STRING!                    \ store name+null
    255 C,                      \ DOR terminator
    R> 11 + HERE OVER -
    SWAP 1- C! ;                \ patch in DOR length
    

: ,ALL
    DOR-COMPILED 0=
    IF  HERE TO DOR-COMPILED
        ,TOKENS
        ,HELP
        ,COMMANDS
        ,TOPICS
	TARGET@ TO CLUINIT  0 ,	\ where client apps UINIT pointer will go
        ,DOR
        HERE DOR-COMPILED - TO DOR-SIZE
    THEN ;

\ DOR Creation high-level words

: TOPIC{  [CHAR] } NEW-TOPIC ;
: TOPIC[  [CHAR] ] NEW-TOPIC ;
: COMMAND{  [CHAR] } NEW-COMMAND ;
: COMMAND[  [CHAR] ] NEW-COMMAND ;
: SEQ{  [CHAR] } PARSE ;
: SEQ[  [CHAR] ] PARSE ;
: HELP-TEXT{  [CHAR] } PARSE ADD-HELP ;
: HELP-TEXT[  [CHAR] ] PARSE ADD-HELP ;
: HELP{  HELP-TEXT{ N/L ;
: HELP[  HELP-TEXT[ N/L ;
: APPLICATION{  [CHAR] } NEW-DOR ;
: APPLICATION[  [CHAR] ] NEW-DOR ;
: INFO{  0 0 0 COMMAND{ INFO ;
: INFO[  0 0 0 COMMAND[ INFO ;  

\ Special command sequences

: XSEQ ( char "name" -- )
    CREATE C,
    DOES> ( c-addr -- c-addr n )
          1 ;

HEX
E0 XSEQ MU_SPC
E1 XSEQ MU_ENT
E2 XSEQ MU_TAB
E3 XSEQ MU_DEL

1B XSEQ IN_ESC
FC XSEQ IN_LFT
FD XSEQ IN_RGT
FE XSEQ IN_DWN
FF XSEQ IN_UP

D1 XSEQ IN_SENT
D2 XSEQ IN_STAB
D3 XSEQ IN_SDEL
F8 XSEQ IN_SLFT
F9 XSEQ IN_SRGT
FA XSEQ IN_SDWN
FB XSEQ IN_SUP

C1 XSEQ IN_DENT
C2 XSEQ IN_DTAB
C3 XSEQ IN_DDEL
F4 XSEQ IN_DLFT
F5 XSEQ IN_DRGT
F6 XSEQ IN_DDWN
F7 XSEQ IN_DUP

B1 XSEQ IN_AENT
B2 XSEQ IN_ATAB
B3 XSEQ IN_ADEL
F0 XSEQ IN_ALFT
F1 XSEQ IN_ARGT
F2 XSEQ IN_ADWN
F3 XSEQ IN_AUP
DECIMAL

\ DOR Save tools

: CRBANK ( c-addr n -- fileid )
    DUP >R 
    PAD COUNT + SWAP CMOVE
    PAD COUNT R> + W/O CREATE-FILE THROW ;

: SAVEBYTES ( fileid addr u -- fileid )
    ROT DUP >R WRITE-FILE THROW R> ;

: SAVEMEM ( fileid addr u -- )
    SAVEBYTES CLOSE-FILE THROW ;

: SAVE-DOR ( c-addr n -- )
    ,ALL
    W/O CREATE-FILE THROW
    DOR-COMPILED DOR-SIZE SAVEMEM
    CR ." DOR successfully saved."
    ."  Load address=" DOR-TARGET U.
    ."  (bank " DOR-BANK .
    ." ), load size=" DOR-SIZE U.
    ." , DOR start=" DOR-START U. ;

: ,"  ( c-addr n -- )
    HERE OVER ALLOT SWAP CMOVE ;

HERE                            \ failmsg
1 C,  S" 7#1! " ,"  32 92 + C, 32 8 + C, 128 C,
1 C,  S" 2C1" ,"
1 C,  S" 3@,#" ,"
1 C,  S" 3+BR" ,"
S"  This application requires Installer v2.00+ and CamelForth"
,"
HEX
C002 @ 0 <# # # CHAR . HOLD # CHAR v HOLD BL HOLD #> ,"
BL C, 7 C, 0 C, 

HERE
\ ( S: failmsg,entry)
  CF C, 0000 ,                  \ call_pkg(pkg_ayt)
  38 C, 24 C,                   \ jr c,fail
  CF C, 021E ,                  \ call_pkg(fth_ayt)
  38 C, 1F C,                   \ jr c,fail
  CF C, 001E ,                  \ call_pkg(fth_inf)
  21 C, C002 @ ,                \ ld hl,ourversion
  A7 C,                         \ and a
  ED C, 52 C,                   \ sbc hl,de
  20 C, 14 C,                   \ jr nz,fail
  CF C, 0A1E ,                  \ call_pkg(fth_in)
  38 C, E6 C,                   \ jr c,entrycode
  2A C, 028C ,			\ ld hl,(dorpointer)
  CB C, FC C,			\ set 7,h
  CB C, B4 C,			\ res 6,h
  2B C,				\ dec hl
  56 C,				\ ld d,(hl)
  2B C,				\ dec hl
  5E C,				\ ld e,(hl)
  EB C,				\ ex de,hl
  C3 C, C000 @ ,                \ jp rejoincfentry
\ fail:
  21 C, HERE 0000 ,             \ ld hl,failmsg
\ (S: failmsg,entry,clitext)
  E7 C, 3A09 ,                  \ call_oz(gn_sop)
  E7 C, 2A C,                   \ call_oz(os_in)
  AF C,                         \ xor a
  E7 C, 21 C,                   \ call_oz(os_bye)

HERE VALUE CODEEND
VALUE CLITEXT
OVER - VALUE CLIENTRY
VALUE CODEST

0 VALUE BIG?
0 VALUE XTRA
DEFER RPTR

: CHKSPACE ( u-addr -- )
    XTRA + DOR-SIZE + BFFF U>
    ABORT" Overflow into seg3!" ;

: INSTDOR ( -- )
    3F TO SEG3
    FFE0 TO ENTRY
    RPTR HERE 8000 U< ABORT" DOR must be in seg 2!"
    RPTR HERE TO DOR-TARGET RAM
    ,ALL
    RPTR HERE DUP CHKSPACE
    DOR-SIZE ALLOT RAM
    DOR-COMPILED SWAP DOR-SIZE CMOVE ;

: STANDALONE ( c-addr n -- )
    RPTR HERE >R
    0 TO XTRA
    3E TO SEG2
    BIG? IF  3D TO SEG1  THEN
    3E TO DOR-BANK
    INSTDOR
    TUCK PAD 1+ SWAP CMOVE PAD C! \ convert to counted at PAD
    BIG? IF  S" .ap2" CRBANK  THEN
    S" .ap1" CRBANK S" .ap0" CRBANK \ open files
    C000 UINIT OVER - SAVEBYTES   \ save pre-user vars
    UVARS #INIT SAVEBYTES         \ save app's uservars
    UINIT #INIT + FFC0 OVER - SAVEBYTES \ save to card hdr
    FFC0 PAD 40 CMOVE             \ copy header to PAD
    DOR-START PAD 6 + ! DOR-BANK PAD 8 + C! \ patch DOR addr
    CARDID PAD 38 + !             \ set card ID
    BIG? IF  3  ELSE  2  THEN PAD 3C + C! \ set card size
    PAD 40 SAVEMEM                \ save card header
    8000 4000 SAVEMEM             \ save other files
    BIG? IF  4000 4000 SAVEMEM  THEN
    R> RPTR HERE - ALLOT RAM
    CR ." Standalone app successfully created" ;

: CLIENT-CODE ( --addr )
    RPTR HERE CODEEND CODEST - ALLOT RAM
    DUP CLITEXT !
    CODEST OVER CODEEND CODEST - CMOVE ;

: CLIENT-DOR
    #INIT 40 + TO XTRA
    3F TO SEG2
    BIG? IF  3E TO SEG1  THEN
    3F TO DOR-BANK
    INSTDOR
    RPTR HERE #INIT ALLOT RAM     \ allot space
    DUP CLUINIT !                 \ patch address of uservars
    UVARS SWAP #INIT CMOVE ;      \ insert initial uservars

: CLIENT ( c-addr n -- )
    RPTR HERE >R
    FFC0 BFC0 40 CMOVE		  \ copy CF card header
    CLIENT-DOR
    CLIENT-CODE CLIENTRY + BFE1 ! \ patch entry point
    TUCK PAD 1+ SWAP CMOVE PAD C! \ convert to counted at PAD
    BIG? IF  S" .ap1" CRBANK  THEN
    S" .ap0" CRBANK                \ open files
    DOR-START BFC6 ! DOR-BANK BFC8 C! \ patch front DOR
    CARDID BFF8 !                 \ set card ID
    BIG? IF  2  ELSE  1  THEN BFFC C! \ set cardsize 
    8000 4000 SAVEMEM
    BIG? IF  4000 4000 SAVEMEM  THEN
    R> RPTR HERE - ALLOT RAM
    CR ." Client app successfully created" ;

: SMALL
    ['] ROM2 IS RPTR
    FALSE TO BIG? ;

: BIG
    ['] ROM1 IS RPTR
    TRUE TO BIG? ;

SMALL

DECIMAL
                     
